-- =====================================================================
-- zollo · migration 1 of 2 · hardening the current schema
-- ---------------------------------------------------------------------
-- What it does (no table is dropped, existing data is kept):
--   1. updated_at triggers on every table that has the column
--   2. profiles row created automatically for every new auth user
--      (+ backfill for existing users, + keeps name/phone in sync with
--      the auth metadata the app writes today)
--   3. money columns become numeric(12,2)
--   4. cleans duplicates, adds the unique constraints the app's
--      upserts need (wishlist, reviews, cart)
--   5. addresses: adds label, removes the duplicate columns,
--      one default address per user
--   6. orders: idempotency key, discount, structured address snapshot,
--      user can be deleted without losing order records
--   7. foreign keys get proper ON DELETE rules
--   8. order_status_history + trigger
--   9. products.rating / rating_count kept up to date from reviews
--  10. indexes on every foreign key and common filters
--  11. Row Level Security on every table
--
-- Run it in the Supabase SQL editor, or save it under supabase/migrations
-- and run `supabase db push`. It is written to be re-runnable.
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. updated_at helper
-- ---------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

do $$
declare t text;
begin
  foreach t in array array['profiles','products','cart_items','addresses','orders',
                           'product_reviews','shipments','shipment_locations']
  loop
    execute format('drop trigger if exists set_updated_at on public.%I', t);
    execute format('create trigger set_updated_at before update on public.%I
                    for each row execute function public.set_updated_at()', t);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 2. profiles: auto-create, backfill, sync with auth metadata
-- ---------------------------------------------------------------------
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (new.id,
          new.raw_user_meta_data ->> 'full_name',
          new.raw_user_meta_data ->> 'phone')
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- The app's Edit Profile screen writes full_name/phone into auth metadata.
-- Mirror those changes into profiles so the two never drift apart.
create or replace function public.handle_user_metadata_update()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
     set full_name = coalesce(new.raw_user_meta_data ->> 'full_name', full_name),
         phone     = coalesce(new.raw_user_meta_data ->> 'phone', phone)
   where id = new.id;
  return new;
end;
$$;

drop trigger if exists on_auth_user_metadata_updated on auth.users;
create trigger on_auth_user_metadata_updated
  after update of raw_user_meta_data on auth.users
  for each row execute function public.handle_user_metadata_update();

insert into public.profiles (id, full_name, phone)
select u.id, u.raw_user_meta_data ->> 'full_name', u.raw_user_meta_data ->> 'phone'
from auth.users u
on conflict (id) do nothing;

-- is_admin(): used by admin policies below
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1 from public.profiles
    where id = (select auth.uid()) and role = 'admin'
  );
$$;

-- ---------------------------------------------------------------------
-- 3. money columns -> numeric(12,2)
-- (order_items.line_total is a generated column, so it is rebuilt)
-- ---------------------------------------------------------------------
do $$
declare r record;
begin
  -- skip when already converted, so the file can be re-run
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'order_items'
               and column_name = 'unit_price'
               and (numeric_precision is distinct from 12 or numeric_scale is distinct from 2)) then
    alter table public.order_items drop column if exists line_total;
    alter table public.order_items alter column unit_price type numeric(12,2);
    alter table public.order_items
      add column line_total numeric(12,2) generated always as (unit_price * quantity) stored;
  end if;

  for r in select * from (values
    ('products', 'price'), ('orders', 'subtotal'), ('orders', 'shipping_fee'), ('orders', 'total_amount')
  ) as v(tbl, col)
  loop
    if exists (select 1 from information_schema.columns
               where table_schema = 'public' and table_name = r.tbl and column_name = r.col
                 and (numeric_precision is distinct from 12 or numeric_scale is distinct from 2)) then
      execute format('alter table public.%I alter column %I type numeric(12,2)', r.tbl, r.col);
    end if;
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 4. duplicates out, unique constraints in
-- ---------------------------------------------------------------------
-- wishlist: no nulls, one row per user + product
delete from public.wishlist where user_id is null or product_id is null;
delete from public.wishlist a
 using public.wishlist b
 where a.user_id = b.user_id and a.product_id = b.product_id and a.id > b.id;
alter table public.wishlist
  alter column user_id set not null,
  alter column product_id set not null;
create unique index if not exists wishlist_user_product_key
  on public.wishlist (user_id, product_id);

-- product_reviews: keep each user's newest review per product
delete from public.product_reviews a
 using public.product_reviews b
 where a.product_id = b.product_id and a.user_id = b.user_id
   and (a.updated_at, a.id) < (b.updated_at, b.id);
create unique index if not exists product_reviews_product_user_key
  on public.product_reviews (product_id, user_id);

-- cart_items: merge duplicate rows (quantities added together).
-- Skipped once migration 2 has added variants (the key is then user + variant).
do $$
begin
  if not exists (select 1 from information_schema.columns
                 where table_schema = 'public' and table_name = 'cart_items'
                   and column_name = 'variant_id') then
    with merged as (
      select user_id, product_id, sum(quantity)::int as qty, min(id::text)::uuid as keep_id
      from public.cart_items
      group by user_id, product_id
      having count(*) > 1
    )
    update public.cart_items c
       set quantity = m.qty
      from merged m
     where c.id = m.keep_id;
    delete from public.cart_items a
     using public.cart_items b
     where a.user_id = b.user_id and a.product_id = b.product_id and a.id::text > b.id::text;
    create unique index if not exists cart_items_user_product_key
      on public.cart_items (user_id, product_id);
  end if;
end $$;

-- ---------------------------------------------------------------------
-- 5. addresses
-- ---------------------------------------------------------------------
alter table public.addresses add column if not exists label text not null default 'home';
alter table public.addresses drop constraint if exists addresses_label_check;
alter table public.addresses
  add constraint addresses_label_check check (lower(label) in ('home', 'office', 'other'));

-- full_name / full_address duplicated recipient_name / address_line
do $$
begin
  if exists (select 1 from information_schema.columns
             where table_schema = 'public' and table_name = 'addresses' and column_name = 'full_address') then
    update public.addresses
       set address_line = coalesce(nullif(address_line, ''), full_address, address_line);
  end if;
end $$;
alter table public.addresses drop column if exists full_name;
alter table public.addresses drop column if exists full_address;

-- only one default address per user (keep the newest default)
update public.addresses a
   set is_default = false
 where a.is_default
   and exists (select 1 from public.addresses b
               where b.user_id = a.user_id and b.is_default
                 and (b.created_at, b.id) > (a.created_at, a.id));
create unique index if not exists addresses_one_default_per_user
  on public.addresses (user_id) where is_default;

-- atomic "make this my default" for the app
create or replace function public.set_default_address(p_address_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare v_uid uuid := (select auth.uid());
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;
  if not exists (select 1 from public.addresses where id = p_address_id and user_id = v_uid) then
    raise exception 'ADDRESS_NOT_FOUND' using errcode = 'P0001';
  end if;
  update public.addresses set is_default = false where user_id = v_uid and is_default;
  update public.addresses set is_default = true  where id = p_address_id;
end;
$$;

-- ---------------------------------------------------------------------
-- 6. orders
-- ---------------------------------------------------------------------
alter table public.orders add column if not exists idempotency_key text;
alter table public.orders add column if not exists discount_amount numeric(12,2) not null default 0
  check (discount_amount >= 0);
alter table public.orders add column if not exists address_snapshot jsonb;
alter table public.orders add column if not exists cancel_reason text;
create unique index if not exists orders_user_idempotency_key
  on public.orders (user_id, idempotency_key) where idempotency_key is not null;

-- a deleted account keeps its orders for accounting, but anonymised
alter table public.orders alter column user_id drop not null;

-- ---------------------------------------------------------------------
-- 7. foreign keys with ON DELETE rules
-- ---------------------------------------------------------------------
-- product_reviews.user_id pointed at auth.users; point it at profiles
-- like every other table, so reviews can be joined to the reviewer.
do $$
declare r record;
begin
  for r in select * from (values
    ('profiles',          'profiles_id_fkey',                'id',          'auth.users(id)',         'cascade'),
    ('wishlist',          'wishlist_user_id_fkey',           'user_id',     'public.profiles(id)',    'cascade'),
    ('wishlist',          'wishlist_product_id_fkey',        'product_id',  'public.products(id)',    'cascade'),
    ('cart_items',        'cart_items_user_id_fkey',         'user_id',     'public.profiles(id)',    'cascade'),
    ('cart_items',        'cart_items_product_id_fkey',      'product_id',  'public.products(id)',    'cascade'),
    ('addresses',         'addresses_user_id_fkey',          'user_id',     'public.profiles(id)',    'cascade'),
    ('products',          'products_category_id_fkey',       'category_id', 'public.categories(id)',  'set null'),
    ('products',          'products_seller_id_fkey',         'seller_id',   'public.profiles(id)',    'set null'),
    ('orders',            'orders_user_id_fkey',             'user_id',     'public.profiles(id)',    'set null'),
    ('orders',            'orders_address_id_fkey',          'address_id',  'public.addresses(id)',   'set null'),
    ('order_items',       'order_items_order_id_fkey',       'order_id',    'public.orders(id)',      'cascade'),
    ('order_items',       'order_items_product_id_fkey',     'product_id',  'public.products(id)',    'set null'),
    ('product_reviews',   'product_reviews_product_id_fkey', 'product_id',  'public.products(id)',    'cascade'),
    ('product_reviews',   'product_reviews_user_id_fkey',    'user_id',     'public.profiles(id)',    'cascade'),
    ('shipments',         'shipments_order_id_fkey',         'order_id',    'public.orders(id)',      'cascade'),
    ('shipments',         'shipments_courier_id_fkey',       'courier_id',  'public.profiles(id)',    'set null'),
    ('tracking_events',   'tracking_events_shipment_id_fkey','shipment_id', 'public.shipments(id)',   'cascade'),
    ('shipment_locations','shipment_locations_shipment_id_fkey','shipment_id','public.shipments(id)', 'cascade')
  ) as v(tbl, con, col, ref, action)
  loop
    execute format('alter table public.%I drop constraint if exists %I', r.tbl, r.con);
    execute format('alter table public.%I add constraint %I foreign key (%I) references %s on delete %s',
                   r.tbl, r.con, r.col, r.ref, r.action);
  end loop;
end $$;

-- ---------------------------------------------------------------------
-- 8. order status history
-- ---------------------------------------------------------------------
create table if not exists public.order_status_history (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  from_status text,
  to_status   text not null,
  changed_by  uuid,
  note        text,
  created_at  timestamptz not null default now()
);

create or replace function public.log_order_status()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    insert into public.order_status_history (order_id, from_status, to_status, changed_by)
    values (new.id, null, new.status, (select auth.uid()));
  elsif new.status is distinct from old.status then
    insert into public.order_status_history (order_id, from_status, to_status, changed_by)
    values (new.id, old.status, new.status, (select auth.uid()));
  end if;
  return new;
end;
$$;

drop trigger if exists log_order_status on public.orders;
create trigger log_order_status
  after insert or update of status on public.orders
  for each row execute function public.log_order_status();

-- ---------------------------------------------------------------------
-- 9. product rating summary (the app already reads products.rating)
-- ---------------------------------------------------------------------
alter table public.products add column if not exists rating numeric(3,2) not null default 0;
alter table public.products add column if not exists rating_count integer not null default 0;

create or replace function public.refresh_product_rating()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_product uuid := coalesce(new.product_id, old.product_id);
begin
  update public.products p
     set rating       = coalesce((select round(avg(r.rating)::numeric, 2)
                                  from public.product_reviews r where r.product_id = v_product), 0),
         rating_count = (select count(*) from public.product_reviews r where r.product_id = v_product)
   where p.id = v_product;
  return null;
end;
$$;

drop trigger if exists refresh_product_rating on public.product_reviews;
create trigger refresh_product_rating
  after insert or update or delete on public.product_reviews
  for each row execute function public.refresh_product_rating();

update public.products p
   set rating       = coalesce(s.avg_rating, 0),
       rating_count = coalesce(s.cnt, 0)
  from (select product_id, round(avg(rating)::numeric, 2) as avg_rating, count(*) as cnt
        from public.product_reviews group by product_id) s
 where s.product_id = p.id;

-- ---------------------------------------------------------------------
-- 10. indexes
-- ---------------------------------------------------------------------
create index if not exists products_category_idx        on public.products (category_id);
create index if not exists products_seller_idx          on public.products (seller_id);
create index if not exists products_active_created_idx  on public.products (is_active, created_at desc);
create index if not exists wishlist_product_idx         on public.wishlist (product_id);
create index if not exists cart_items_product_idx       on public.cart_items (product_id);
create index if not exists addresses_user_idx           on public.addresses (user_id);
create index if not exists orders_user_created_idx      on public.orders (user_id, created_at desc);
create index if not exists orders_address_idx           on public.orders (address_id);
create index if not exists orders_status_idx            on public.orders (status);
create index if not exists order_items_order_idx        on public.order_items (order_id);
create index if not exists order_items_product_idx      on public.order_items (product_id);
create index if not exists product_reviews_user_idx     on public.product_reviews (user_id);
create index if not exists product_reviews_product_created_idx
                                                        on public.product_reviews (product_id, created_at desc);
create index if not exists shipments_order_idx          on public.shipments (order_id);
create index if not exists shipments_courier_idx        on public.shipments (courier_id);
create index if not exists tracking_events_shipment_idx on public.tracking_events (shipment_id, occurred_at);
create index if not exists order_status_history_order_idx
                                                        on public.order_status_history (order_id, created_at);

-- ---------------------------------------------------------------------
-- 11. Row Level Security
-- ---------------------------------------------------------------------
do $$
declare t text;
begin
  foreach t in array array['profiles','categories','products','wishlist','cart_items',
                           'addresses','orders','order_items','product_reviews','shipments',
                           'tracking_events','shipment_locations','order_status_history']
  loop
    execute format('alter table public.%I enable row level security', t);
  end loop;
end $$;

-- drop the policies this file manages, so it can be re-run safely
do $$
declare p record;
begin
  for p in select policyname, tablename from pg_policies
           where schemaname = 'public' and policyname like 'zollo_%'
  loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- profiles: see and edit your own row; role can never be changed by the user
create policy zollo_profiles_select_own on public.profiles
  for select to authenticated using (id = (select auth.uid()) or public.is_admin());
create policy zollo_profiles_update_own on public.profiles
  for update to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));
revoke update on public.profiles from anon, authenticated;
grant update (full_name, phone) on public.profiles to authenticated;

-- catalog: everyone reads active rows, admins manage, sellers manage their own products
create policy zollo_categories_read on public.categories
  for select to anon, authenticated using (is_active or public.is_admin());
create policy zollo_categories_admin on public.categories
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create policy zollo_products_read on public.products
  for select to anon, authenticated
  using (is_active or seller_id = (select auth.uid()) or public.is_admin());
create policy zollo_products_seller_insert on public.products
  for insert to authenticated
  with check (seller_id = (select auth.uid())
              and exists (select 1 from public.profiles
                          where id = (select auth.uid()) and role in ('seller', 'admin')));
create policy zollo_products_seller_update on public.products
  for update to authenticated
  using (seller_id = (select auth.uid()) or public.is_admin())
  with check (seller_id = (select auth.uid()) or public.is_admin());
create policy zollo_products_admin_delete on public.products
  for delete to authenticated using (public.is_admin());

-- personal tables: only your own rows
create policy zollo_wishlist_own on public.wishlist
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy zollo_cart_items_own on public.cart_items
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy zollo_addresses_own on public.addresses
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- orders: buyers read their own; admins read and update all
create policy zollo_orders_select on public.orders
  for select to authenticated using (user_id = (select auth.uid()) or public.is_admin());
create policy zollo_orders_admin_update on public.orders
  for update to authenticated using (public.is_admin()) with check (public.is_admin());

-- TEMPORARY: the current app inserts orders and order_items directly.
-- Keep these two policies until the app calls place_order() (migration 2),
-- then drop them with the LOCKDOWN block at the end of migration 2.
create policy zollo_orders_insert_own_temp on public.orders
  for insert to authenticated
  with check (user_id = (select auth.uid()) and status = 'pending' and payment_status = 'pending');
create policy zollo_order_items_insert_own_temp on public.order_items
  for insert to authenticated
  with check (exists (select 1 from public.orders o
                      where o.id = order_id and o.user_id = (select auth.uid()) and o.status = 'pending'));

create policy zollo_order_items_select on public.order_items
  for select to authenticated
  using (exists (select 1 from public.orders o
                 where o.id = order_id and (o.user_id = (select auth.uid()) or public.is_admin())));

create policy zollo_order_status_history_select on public.order_status_history
  for select to authenticated
  using (exists (select 1 from public.orders o
                 where o.id = order_id and (o.user_id = (select auth.uid()) or public.is_admin())));

-- reviews: public to read; write only for a product you received
create policy zollo_reviews_read on public.product_reviews
  for select to anon, authenticated using (true);
create policy zollo_reviews_insert on public.product_reviews
  for insert to authenticated
  with check (user_id = (select auth.uid())
              and exists (select 1 from public.order_items oi
                          join public.orders o on o.id = oi.order_id
                          where o.user_id = (select auth.uid())
                            and o.status = 'delivered'
                            and oi.product_id = product_reviews.product_id));
create policy zollo_reviews_update_own on public.product_reviews
  for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy zollo_reviews_delete_own on public.product_reviews
  for delete to authenticated using (user_id = (select auth.uid()) or public.is_admin());

-- shipments: the buyer of the order, the assigned courier, and admins
create policy zollo_shipments_select on public.shipments
  for select to authenticated
  using (courier_id = (select auth.uid()) or public.is_admin()
         or exists (select 1 from public.orders o
                    where o.id = order_id and o.user_id = (select auth.uid())));
create policy zollo_shipments_courier_update on public.shipments
  for update to authenticated
  using (courier_id = (select auth.uid()) or public.is_admin())
  with check (courier_id = (select auth.uid()) or public.is_admin());
create policy zollo_shipments_admin_insert on public.shipments
  for insert to authenticated with check (public.is_admin());

create policy zollo_tracking_events_select on public.tracking_events
  for select to authenticated
  using (exists (select 1 from public.shipments s
                 join public.orders o on o.id = s.order_id
                 where s.id = shipment_id
                   and (o.user_id = (select auth.uid()) or s.courier_id = (select auth.uid())
                        or public.is_admin())));
create policy zollo_tracking_events_courier_insert on public.tracking_events
  for insert to authenticated
  with check (exists (select 1 from public.shipments s
                      where s.id = shipment_id
                        and (s.courier_id = (select auth.uid()) or public.is_admin())));

create policy zollo_shipment_locations_select on public.shipment_locations
  for select to authenticated
  using (exists (select 1 from public.shipments s
                 join public.orders o on o.id = s.order_id
                 where s.id = shipment_id
                   and (o.user_id = (select auth.uid()) or s.courier_id = (select auth.uid())
                        or public.is_admin())));
create policy zollo_shipment_locations_courier_write on public.shipment_locations
  for all to authenticated
  using (exists (select 1 from public.shipments s
                 where s.id = shipment_id and s.courier_id = (select auth.uid())))
  with check (exists (select 1 from public.shipments s
                      where s.id = shipment_id and s.courier_id = (select auth.uid())));

-- service-only helpers are never callable by app users
revoke execute on function public.handle_new_user() from public, anon, authenticated;
revoke execute on function public.handle_user_metadata_update() from public, anon, authenticated;
revoke execute on function public.log_order_status() from public, anon, authenticated;
revoke execute on function public.refresh_product_rating() from public, anon, authenticated;
grant execute on function public.set_default_address(uuid) to authenticated;
grant execute on function public.is_admin() to anon, authenticated;

commit;
