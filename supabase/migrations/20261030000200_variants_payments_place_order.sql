-- =====================================================================
-- zollo · migration 2 of 2 · catalog variants, stock, payments, place_order()
-- ---------------------------------------------------------------------
-- Needs migration 1. What it adds:
--   1. app_config (delivery fee, minimum app version)
--   2. categories: parent_id, slug, sort_order
--   3. products: compare_at_price, brand, slug
--   4. product_variants (price + stock per size / colour) and
--      product_images; every existing product gets one default variant
--      and its image_url copied over
--   5. products.price / stock_quantity stay in sync with the variants,
--      so the current app keeps working unchanged
--   6. cart_items and order_items learn about variants
--   7. stock_reservations + inventory_movements
--   8. payments
--   9. place_order(), cancel_order(), expire_unpaid_orders()
--  10. stock is committed or released automatically when an order's
--      status changes
-- =====================================================================

begin;

-- ---------------------------------------------------------------------
-- 1. app_config
-- ---------------------------------------------------------------------
create table if not exists public.app_config (
  key        text primary key,
  value      jsonb not null,
  updated_at timestamptz not null default now()
);
insert into public.app_config (key, value) values
  ('delivery_fee',            '60'::jsonb),
  ('min_app_version',         '"1.0.0"'::jsonb),
  ('online_payment_minutes',  '15'::jsonb)
on conflict (key) do nothing;

alter table public.app_config enable row level security;
drop policy if exists zollo_app_config_read on public.app_config;
create policy zollo_app_config_read on public.app_config
  for select to anon, authenticated using (true);
drop policy if exists zollo_app_config_admin on public.app_config;
create policy zollo_app_config_admin on public.app_config
  for all to authenticated using (public.is_admin()) with check (public.is_admin());

create or replace function public.config_numeric(p_key text, p_default numeric)
returns numeric
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce((select (value #>> '{}')::numeric from public.app_config where key = p_key),
                  p_default);
$$;

-- ---------------------------------------------------------------------
-- 2. categories: hierarchy and ordering
-- ---------------------------------------------------------------------
alter table public.categories add column if not exists parent_id uuid
  references public.categories(id) on delete set null;
alter table public.categories add column if not exists slug text;
alter table public.categories add column if not exists sort_order integer not null default 0;
update public.categories
   set slug = trim(both '-' from regexp_replace(lower(name), '[^a-z0-9]+', '-', 'g'))
 where slug is null;
create unique index if not exists categories_slug_key on public.categories (slug);
create index if not exists categories_parent_idx on public.categories (parent_id, sort_order);

-- ---------------------------------------------------------------------
-- 3. products: extra catalog fields
-- ---------------------------------------------------------------------
alter table public.products add column if not exists compare_at_price numeric(12,2)
  check (compare_at_price is null or compare_at_price >= 0);
alter table public.products add column if not exists brand text;
alter table public.products add column if not exists slug text;

-- ---------------------------------------------------------------------
-- 4. product_variants and product_images
-- ---------------------------------------------------------------------
create table if not exists public.product_variants (
  id               uuid primary key default gen_random_uuid(),
  product_id       uuid not null references public.products(id) on delete cascade,
  sku              text unique,
  attributes       jsonb not null default '{}'::jsonb,   -- e.g. {"colour":"Black","size":"L"}
  price            numeric(12,2) not null check (price >= 0),
  compare_at_price numeric(12,2) check (compare_at_price is null or compare_at_price >= price),
  stock_on_hand    integer not null default 0 check (stock_on_hand >= 0),
  stock_reserved   integer not null default 0 check (stock_reserved >= 0),
  is_default       boolean not null default false,
  is_active        boolean not null default true,
  created_at       timestamptz not null default now(),
  updated_at       timestamptz not null default now(),
  constraint product_variants_reserved_le_on_hand check (stock_reserved <= stock_on_hand)
);
create unique index if not exists product_variants_one_default
  on public.product_variants (product_id) where is_default;
create index if not exists product_variants_product_idx on public.product_variants (product_id);

drop trigger if exists set_updated_at on public.product_variants;
create trigger set_updated_at before update on public.product_variants
  for each row execute function public.set_updated_at();

-- one default variant for every existing product
insert into public.product_variants (product_id, price, stock_on_hand, is_default)
select p.id, p.price, p.stock_quantity, true
from public.products p
where not exists (select 1 from public.product_variants v where v.product_id = p.id);

create table if not exists public.product_images (
  id         uuid primary key default gen_random_uuid(),
  product_id uuid not null references public.products(id) on delete cascade,
  path       text not null,        -- Storage path or full URL
  sort_order integer not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists product_images_product_idx on public.product_images (product_id, sort_order);

insert into public.product_images (product_id, path, sort_order)
select p.id, p.image_url, 0
from public.products p
where p.image_url is not null and p.image_url <> ''
  and not exists (select 1 from public.product_images i where i.product_id = p.id);

-- ---------------------------------------------------------------------
-- 5. keep products.price / stock_quantity in sync (the app reads them)
--    price          = cheapest active variant
--    stock_quantity = sum of available stock (on hand - reserved)
-- ---------------------------------------------------------------------
create or replace function public.sync_product_from_variants()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare v_product uuid := coalesce(new.product_id, old.product_id);
begin
  update public.products p
     set price            = coalesce(s.min_price, p.price),
         compare_at_price = s.default_compare,
         stock_quantity   = coalesce(s.available, 0)
    from (select min(v.price) filter (where v.is_active)                                as min_price,
                 max(v.compare_at_price) filter (where v.is_default)                    as default_compare,
                 sum(v.stock_on_hand - v.stock_reserved) filter (where v.is_active)::int as available
          from public.product_variants v
          where v.product_id = v_product) s
   where p.id = v_product;
  return null;
end;
$$;

drop trigger if exists sync_product_from_variants on public.product_variants;
create trigger sync_product_from_variants
  after insert or update or delete on public.product_variants
  for each row execute function public.sync_product_from_variants();

-- A new product gets its default variant automatically.
-- Editing price / stock_quantity directly on a single-variant product
-- (for example in the Supabase table editor) updates that variant too.
create or replace function public.products_to_default_variant()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if pg_trigger_depth() > 1 then
    return null;   -- this change came from sync_product_from_variants
  end if;

  if tg_op = 'INSERT' then
    insert into public.product_variants (product_id, price, stock_on_hand, is_default)
    values (new.id, new.price, new.stock_quantity, true);
  elsif (new.price is distinct from old.price or new.stock_quantity is distinct from old.stock_quantity)
        and (select count(*) from public.product_variants where product_id = new.id) = 1 then
    update public.product_variants
       set price         = new.price,
           stock_on_hand = new.stock_quantity + stock_reserved
     where product_id = new.id;
  end if;
  return null;
end;
$$;

drop trigger if exists products_to_default_variant on public.products;
create trigger products_to_default_variant
  after insert or update of price, stock_quantity on public.products
  for each row execute function public.products_to_default_variant();

-- ---------------------------------------------------------------------
-- 6. cart_items and order_items know about variants
-- ---------------------------------------------------------------------
alter table public.cart_items add column if not exists variant_id uuid
  references public.product_variants(id) on delete cascade;
update public.cart_items c
   set variant_id = v.id
  from public.product_variants v
 where c.variant_id is null and v.product_id = c.product_id and v.is_default;
alter table public.cart_items alter column variant_id set not null;
drop index if exists public.cart_items_user_product_key;
create unique index if not exists cart_items_user_variant_key on public.cart_items (user_id, variant_id);
create index if not exists cart_items_variant_idx on public.cart_items (variant_id);

alter table public.order_items add column if not exists variant_id uuid
  references public.product_variants(id) on delete set null;
alter table public.order_items add column if not exists image_snapshot text;
alter table public.order_items add column if not exists variant_snapshot jsonb;
create index if not exists order_items_variant_idx on public.order_items (variant_id);

-- ---------------------------------------------------------------------
-- 7. stock reservations and the inventory ledger
-- ---------------------------------------------------------------------
create table if not exists public.stock_reservations (
  id          uuid primary key default gen_random_uuid(),
  order_id    uuid not null references public.orders(id) on delete cascade,
  variant_id  uuid not null references public.product_variants(id) on delete cascade,
  quantity    integer not null check (quantity > 0),
  status      text not null default 'reserved' check (status in ('reserved', 'committed', 'released')),
  expires_at  timestamptz,          -- null = held until the order is confirmed or cancelled
  created_at  timestamptz not null default now(),
  updated_at  timestamptz not null default now()
);
create index if not exists stock_reservations_order_idx on public.stock_reservations (order_id);
create index if not exists stock_reservations_open_idx
  on public.stock_reservations (expires_at) where status = 'reserved';

drop trigger if exists set_updated_at on public.stock_reservations;
create trigger set_updated_at before update on public.stock_reservations
  for each row execute function public.set_updated_at();

create table if not exists public.inventory_movements (
  id         bigint generated always as identity primary key,
  variant_id uuid not null references public.product_variants(id) on delete cascade,
  change     integer not null,       -- + adds stock on hand, - removes it; reservations log 0
  reason     text not null check (reason in ('reserved', 'released', 'sold', 'restock',
                                             'adjustment', 'returned')),
  quantity   integer not null,
  order_id   uuid references public.orders(id) on delete set null,
  created_by uuid,
  created_at timestamptz not null default now()
);
create index if not exists inventory_movements_variant_idx on public.inventory_movements (variant_id, created_at);

-- ---------------------------------------------------------------------
-- 8. payments
-- ---------------------------------------------------------------------
create table if not exists public.payments (
  id             uuid primary key default gen_random_uuid(),
  order_id       uuid not null references public.orders(id) on delete cascade,
  method         text not null check (method in ('cash_on_delivery', 'bkash', 'nagad', 'card')),
  gateway_trx_id text unique,
  amount         numeric(12,2) not null check (amount >= 0),
  status         text not null default 'initiated'
                 check (status in ('initiated', 'pending', 'paid', 'failed', 'cancelled', 'refunded')),
  raw_response   jsonb,
  paid_at        timestamptz,
  created_at     timestamptz not null default now(),
  updated_at     timestamptz not null default now()
);
create index if not exists payments_order_idx on public.payments (order_id);

drop trigger if exists set_updated_at on public.payments;
create trigger set_updated_at before update on public.payments
  for each row execute function public.set_updated_at();

-- ---------------------------------------------------------------------
-- RLS for the new tables
-- ---------------------------------------------------------------------
alter table public.product_variants    enable row level security;
alter table public.product_images      enable row level security;
alter table public.stock_reservations  enable row level security;
alter table public.inventory_movements enable row level security;
alter table public.payments            enable row level security;

drop policy if exists zollo_variants_read on public.product_variants;
create policy zollo_variants_read on public.product_variants
  for select to anon, authenticated
  using (exists (select 1 from public.products p where p.id = product_id
                 and (p.is_active or p.seller_id = (select auth.uid()) or public.is_admin())));
drop policy if exists zollo_variants_manage on public.product_variants;
create policy zollo_variants_manage on public.product_variants
  for all to authenticated
  using (exists (select 1 from public.products p where p.id = product_id
                 and (p.seller_id = (select auth.uid()) or public.is_admin())))
  with check (exists (select 1 from public.products p where p.id = product_id
                      and (p.seller_id = (select auth.uid()) or public.is_admin())));

drop policy if exists zollo_images_read on public.product_images;
create policy zollo_images_read on public.product_images
  for select to anon, authenticated using (true);
drop policy if exists zollo_images_manage on public.product_images;
create policy zollo_images_manage on public.product_images
  for all to authenticated
  using (exists (select 1 from public.products p where p.id = product_id
                 and (p.seller_id = (select auth.uid()) or public.is_admin())))
  with check (exists (select 1 from public.products p where p.id = product_id
                      and (p.seller_id = (select auth.uid()) or public.is_admin())));

drop policy if exists zollo_payments_select on public.payments;
create policy zollo_payments_select on public.payments
  for select to authenticated
  using (exists (select 1 from public.orders o where o.id = order_id
                 and (o.user_id = (select auth.uid()) or public.is_admin())));
-- stock_reservations and inventory_movements: no policies on purpose.
-- Only the functions below (security definer) and the service role touch them.
drop policy if exists zollo_inventory_admin_read on public.inventory_movements;
create policy zollo_inventory_admin_read on public.inventory_movements
  for select to authenticated using (public.is_admin());

-- ---------------------------------------------------------------------
-- 9a. place_order()
--   p_items: [{"variant_id": "...", "quantity": 2}]
--            or, while the app still uses product ids:
--            [{"product_id": "...", "quantity": 2}]  (uses the default variant)
--   Returns the new orders row. Calling it again with the same
--   p_idempotency_key returns the same order instead of a duplicate.
--   Errors (PostgrestException.message): NOT_AUTHENTICATED, EMPTY_CART,
--   INVALID_QUANTITY, ADDRESS_NOT_FOUND, INVALID_PAYMENT_METHOD,
--   PRODUCT_UNAVAILABLE, OUT_OF_STOCK (details = variant id)
-- ---------------------------------------------------------------------
create or replace function public.place_order(
  p_items           jsonb,
  p_address_id      uuid,
  p_payment_method  text default 'cash_on_delivery',
  p_idempotency_key text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid       uuid := (select auth.uid());
  v_existing  public.orders;
  v_order     public.orders;
  v_address   public.addresses;
  v_item      jsonb;
  v_variant   public.product_variants;
  v_product   public.products;
  v_qty       integer;
  v_subtotal  numeric(12,2) := 0;
  v_fee       numeric(12,2) := public.config_numeric('delivery_fee', 60);
  v_expires   timestamptz;
  v_lines     jsonb := '[]'::jsonb;
  v_line      jsonb;
begin
  if v_uid is null then
    raise exception 'NOT_AUTHENTICATED' using errcode = 'P0001';
  end if;

  if p_idempotency_key is not null then
    select * into v_existing from public.orders
     where user_id = v_uid and idempotency_key = p_idempotency_key;
    if found then
      return v_existing;
    end if;
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'EMPTY_CART' using errcode = 'P0001';
  end if;

  if p_payment_method not in ('cash_on_delivery', 'bkash', 'nagad', 'card') then
    raise exception 'INVALID_PAYMENT_METHOD' using errcode = 'P0001';
  end if;

  select * into v_address from public.addresses where id = p_address_id and user_id = v_uid;
  if not found then
    raise exception 'ADDRESS_NOT_FOUND' using errcode = 'P0001';
  end if;

  -- Lock every variant in a fixed order so two checkouts can't deadlock,
  -- then check stock and price from the database, never from the app.
  for v_item in
    select e.item
    from jsonb_array_elements(p_items) as e(item)
    order by coalesce(e.item ->> 'variant_id', e.item ->> 'product_id')
  loop
    v_qty := coalesce((v_item ->> 'quantity')::integer, 0);
    if v_qty <= 0 or v_qty > 99 then
      raise exception 'INVALID_QUANTITY' using errcode = 'P0001';
    end if;

    if v_item ? 'variant_id' then
      select * into v_variant from public.product_variants
       where id = (v_item ->> 'variant_id')::uuid
       for update;
    else
      select * into v_variant from public.product_variants
       where product_id = (v_item ->> 'product_id')::uuid and is_default
       for update;
    end if;
    if not found or not v_variant.is_active then
      raise exception 'PRODUCT_UNAVAILABLE' using errcode = 'P0001',
        detail = coalesce(v_item ->> 'variant_id', v_item ->> 'product_id');
    end if;

    select * into v_product from public.products where id = v_variant.product_id;
    if not v_product.is_active then
      raise exception 'PRODUCT_UNAVAILABLE' using errcode = 'P0001', detail = v_variant.id::text;
    end if;

    if v_variant.stock_on_hand - v_variant.stock_reserved < v_qty then
      raise exception 'OUT_OF_STOCK' using errcode = 'P0001', detail = v_variant.id::text;
    end if;

    v_subtotal := v_subtotal + v_variant.price * v_qty;
    v_lines := v_lines || jsonb_build_object(
      'variant_id',   v_variant.id,
      'product_id',   v_product.id,
      'product_name', v_product.name,
      'unit_price',   v_variant.price,
      'quantity',     v_qty,
      'image',        v_product.image_url,
      'attributes',   v_variant.attributes);
  end loop;

  -- online payments hold stock for a short time; cash on delivery holds it
  -- until the order is confirmed or cancelled
  if p_payment_method <> 'cash_on_delivery' then
    v_expires := now() + make_interval(mins => public.config_numeric('online_payment_minutes', 15)::int);
  end if;

  insert into public.orders (
    user_id, address_id, payment_method, subtotal, shipping_fee, total_amount,
    shipping_name, shipping_phone, shipping_address, address_snapshot, idempotency_key)
  values (
    v_uid, v_address.id, p_payment_method, v_subtotal, v_fee, v_subtotal + v_fee,
    v_address.recipient_name, v_address.phone,
    concat_ws(', ', v_address.address_line, v_address.area, v_address.district,
              v_address.division, v_address.postal_code),
    to_jsonb(v_address) - 'user_id' - 'created_at' - 'updated_at',
    p_idempotency_key)
  returning * into v_order;

  for v_line in select * from jsonb_array_elements(v_lines)
  loop
    insert into public.order_items (
      order_id, product_id, variant_id, product_name, unit_price, quantity,
      image_snapshot, variant_snapshot)
    values (
      v_order.id, (v_line ->> 'product_id')::uuid, (v_line ->> 'variant_id')::uuid,
      v_line ->> 'product_name', (v_line ->> 'unit_price')::numeric, (v_line ->> 'quantity')::int,
      v_line ->> 'image', v_line -> 'attributes');

    update public.product_variants
       set stock_reserved = stock_reserved + (v_line ->> 'quantity')::int
     where id = (v_line ->> 'variant_id')::uuid;

    insert into public.stock_reservations (order_id, variant_id, quantity, expires_at)
    values (v_order.id, (v_line ->> 'variant_id')::uuid, (v_line ->> 'quantity')::int, v_expires);

    insert into public.inventory_movements (variant_id, change, reason, quantity, order_id, created_by)
    values ((v_line ->> 'variant_id')::uuid, 0, 'reserved', (v_line ->> 'quantity')::int, v_order.id, v_uid);
  end loop;

  insert into public.payments (order_id, method, amount, status)
  values (v_order.id, p_payment_method, v_order.total_amount,
          case when p_payment_method = 'cash_on_delivery' then 'pending' else 'initiated' end);

  -- the ordered variants leave the cart
  delete from public.cart_items c
   where c.user_id = v_uid
     and c.variant_id in (select (l ->> 'variant_id')::uuid from jsonb_array_elements(v_lines) l);

  return v_order;
end;
$$;

-- ---------------------------------------------------------------------
-- 9b. cancel_order(): the buyer can cancel while the order is pending
-- ---------------------------------------------------------------------
create or replace function public.cancel_order(p_order_id uuid, p_reason text default null)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid   uuid := (select auth.uid());
  v_order public.orders;
begin
  select * into v_order from public.orders where id = p_order_id for update;
  if not found or (v_order.user_id is distinct from v_uid and not public.is_admin()) then
    raise exception 'ORDER_NOT_FOUND' using errcode = 'P0001';
  end if;
  if v_order.status <> 'pending' and not public.is_admin() then
    raise exception 'ORDER_NOT_CANCELLABLE' using errcode = 'P0001';
  end if;
  update public.orders
     set status = 'cancelled', cancel_reason = p_reason
   where id = p_order_id
  returning * into v_order;
  return v_order;
end;
$$;

-- ---------------------------------------------------------------------
-- 10. stock follows the order status
--   pending   -> confirmed            : reservation becomes a sale
--   pending   -> cancelled            : reservation released
--   confirmed / processing -> cancelled: sold stock put back on hand
-- ---------------------------------------------------------------------
create or replace function public.apply_order_stock()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare r record;
begin
  if new.status = old.status then
    return new;
  end if;

  if new.status in ('confirmed', 'processing', 'shipped', 'delivered') then
    for r in select * from public.stock_reservations
             where order_id = new.id and status = 'reserved' for update
    loop
      update public.product_variants
         set stock_reserved = stock_reserved - r.quantity,
             stock_on_hand  = stock_on_hand  - r.quantity
       where id = r.variant_id;
      update public.stock_reservations set status = 'committed' where id = r.id;
      insert into public.inventory_movements (variant_id, change, reason, quantity, order_id)
      values (r.variant_id, -r.quantity, 'sold', r.quantity, new.id);
    end loop;

  elsif new.status = 'cancelled' then
    for r in select * from public.stock_reservations
             where order_id = new.id and status in ('reserved', 'committed') for update
    loop
      if r.status = 'reserved' then
        update public.product_variants
           set stock_reserved = stock_reserved - r.quantity
         where id = r.variant_id;
        insert into public.inventory_movements (variant_id, change, reason, quantity, order_id)
        values (r.variant_id, 0, 'released', r.quantity, new.id);
      else
        update public.product_variants
           set stock_on_hand = stock_on_hand + r.quantity
         where id = r.variant_id;
        insert into public.inventory_movements (variant_id, change, reason, quantity, order_id)
        values (r.variant_id, r.quantity, 'returned', r.quantity, new.id);
      end if;
      update public.stock_reservations set status = 'released' where id = r.id;
    end loop;
    update public.payments set status = 'cancelled'
     where order_id = new.id and status in ('initiated', 'pending');
  end if;

  -- cash on delivery is paid when the rider hands the parcel over
  if new.status = 'delivered' and new.payment_method = 'cash_on_delivery' then
    update public.payments set status = 'paid', paid_at = now()
     where order_id = new.id and status = 'pending';
    update public.orders set payment_status = 'paid'
     where id = new.id and payment_status = 'pending';
  end if;

  return new;
end;
$$;

drop trigger if exists apply_order_stock on public.orders;
create trigger apply_order_stock
  after update of status on public.orders
  for each row execute function public.apply_order_stock();

-- ---------------------------------------------------------------------
-- 9c. expire_unpaid_orders(): run every minute with pg_cron (see bottom)
-- ---------------------------------------------------------------------
create or replace function public.expire_unpaid_orders()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare v_count integer;
begin
  with expired as (
    select distinct r.order_id
    from public.stock_reservations r
    join public.orders o on o.id = r.order_id
    where r.status = 'reserved' and r.expires_at < now()
      and o.status = 'pending' and o.payment_status <> 'paid'
  )
  update public.orders o
     set status = 'cancelled', cancel_reason = 'payment_timeout'
    from expired e
   where o.id = e.order_id;
  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- ---------------------------------------------------------------------
-- function permissions
-- ---------------------------------------------------------------------
revoke execute on function public.place_order(jsonb, uuid, text, text) from public, anon;
grant  execute on function public.place_order(jsonb, uuid, text, text) to authenticated;
revoke execute on function public.cancel_order(uuid, text) from public, anon;
grant  execute on function public.cancel_order(uuid, text) to authenticated;
revoke execute on function public.expire_unpaid_orders() from public, anon, authenticated;
revoke execute on function public.apply_order_stock() from public, anon, authenticated;
revoke execute on function public.sync_product_from_variants() from public, anon, authenticated;
revoke execute on function public.products_to_default_variant() from public, anon, authenticated;
revoke execute on function public.config_numeric(text, numeric) from public, anon, authenticated;

commit;

-- =====================================================================
-- AFTER THIS MIGRATION, DO THESE BY HAND
-- =====================================================================
-- A. Schedule the expiry job (Database > Extensions > enable pg_cron first):
--      select cron.schedule('expire-unpaid-orders', '* * * * *',
--                           $$select public.expire_unpaid_orders()$$);
--
-- B. LOCKDOWN — run only after the app calls place_order() instead of
--    inserting into orders / order_items itself:
--      drop policy if exists zollo_orders_insert_own_temp on public.orders;
--      drop policy if exists zollo_order_items_insert_own_temp on public.order_items;
--
-- C. Edit prices and stock in product_variants from now on.
--    products.price and products.stock_quantity are kept in sync automatically.
-- =====================================================================
