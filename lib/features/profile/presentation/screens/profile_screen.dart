import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../auth/domain/providers/auth_provider.dart';
import '../../../wishlist/presentation/providers/wishlist_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color primaryTeal = Color(0xFF006B54);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider) ?? Supabase.instance.client.auth.currentUser;

    final fullName = (user?.userMetadata?['full_name'] as String?) ??
        (user?.userMetadata?['name'] as String?) ??
        (user?.email != null && user!.email!.contains('@')
            ? user.email!.split('@').first
            : 'User Name');

    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'U';

    final phoneOrEmail = (user?.phone != null && user!.phone!.isNotEmpty)
        ? user.phone!
        : (user?.userMetadata?['phone'] as String?) ?? user?.email ?? '+880 1XXX-XXXXXX';

    final wishlistState = ref.watch(wishlistProvider);
    final wishlistCount = wishlistState.value?.length ?? 0;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F0),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Header Section
              InkWell(
                onTap: () => context.push('/edit-profile'),
                child: Container(
                  color: primaryTeal,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Row(
                    children: [
                      // Avatar Circle
                      Container(
                        width: 60,
                        height: 60,
                        decoration: const BoxDecoration(
                          color: Color(0xFFD4ECE6),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            initial,
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                              color: primaryTeal,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // User Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              fullName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              phoneOrEmail,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.8),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Edit Button
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'Edit',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // My Orders Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      // Orders Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'My orders',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          InkWell(
                            onTap: () => context.push('/order-history'),
                            child: const Text(
                              'View all',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryTeal,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Order Actions Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildOrderAction(
                            icon: Icons.account_balance_wallet_outlined,
                            label: 'To pay',
                            onTap: () => context.push('/order-history'),
                          ),
                          _buildOrderAction(
                            icon: Icons.inventory_2_outlined,
                            label: 'To ship',
                            onTap: () => context.push('/order-history'),
                          ),
                          _buildOrderAction(
                            icon: Icons.local_shipping_outlined,
                            label: 'To receive',
                            onTap: () => context.push('/order-history'),
                          ),
                          _buildOrderAction(
                            icon: Icons.star_outline_rounded,
                            label: 'To review',
                            onTap: () => context.push('/order-history'),
                          ),
                          _buildOrderAction(
                            icon: Icons.assignment_return_outlined,
                            label: 'Returns',
                            onTap: () => context.push('/order-history'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Menu Options Card
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        title: 'Wishlist',
                        subtitle: '$wishlistCount items',
                        onTap: () => context.push('/wishlist'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'My vouchers',
                        subtitle: '2 available',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Address book',
                        onTap: () => context.push('/addresses'),
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Messages',
                        subtitle: '1 new',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Notifications',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Help center',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Settings',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Sell on zollo',
                        onTap: () {},
                      ),
                      const Divider(height: 1, indent: 16, endIndent: 16),
                      _buildMenuItem(
                        title: 'Logout',
                        titleColor: Colors.red,
                        onTap: () async {
                          await ref.read(authControllerProvider.notifier).signOut();
                          if (!context.mounted) return;
                          context.go('/login');
                        },
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOrderAction({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Column(
          children: [
            Icon(icon, color: primaryTeal, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required String title,
    String? subtitle,
    Color titleColor = Colors.black87,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: titleColor,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (subtitle != null) ...[
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(width: 4),
          ],
          Icon(
            Icons.chevron_right,
            color: Colors.grey.shade400,
            size: 20,
          ),
        ],
      ),
    );
  }
}
