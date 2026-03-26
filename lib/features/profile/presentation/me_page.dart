import 'package:flutter/material.dart';

import '../../account/presentation/account_page.dart';
import '../../settings/presentation/settings_page.dart';

class MePage extends StatelessWidget {
  const MePage({
    super.key,
    required this.onOpenWishlist,
    required this.onOpenCart,
  });

  final VoidCallback onOpenWishlist;
  final VoidCallback onOpenCart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('e-Mall', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
                  },
                  icon: const Icon(Icons.tune),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Color(0xFFF1DACB),
                  child: Icon(Icons.person, size: 30, color: Color(0xFF6A4A35)),
                ),
                SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amara Okafor', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
                    SizedBox(height: 4),
                    Text('Nigeria'),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _StatItem(label: 'Orders', value: '12'),
                _StatItem(label: 'Wishlist', value: '24'),
                _StatItem(label: 'Points', value: '2.4k'),
              ],
            ),
            const SizedBox(height: 18),
            _OptionTile(
              title: 'My Account',
              subtitle: 'Wallet, payments, and billing',
              icon: Icons.account_balance_wallet_outlined,
              onTap: () {
                Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountPage()));
              },
            ),
            _OptionTile(
              title: 'My Wishlist',
              subtitle: 'Curated artisan favorites',
              icon: Icons.favorite_outline,
              onTap: onOpenWishlist,
            ),
            _OptionTile(
              title: 'My Cart',
              subtitle: 'Items ready for checkout',
              icon: Icons.shopping_bag_outlined,
              onTap: onOpenCart,
            ),
            _OptionTile(
              title: 'Order History',
              subtitle: 'Track and review past purchases',
              icon: Icons.history,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF3F2413),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: Color(0xFF6A4A35))),
      ],
    );
  }
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
