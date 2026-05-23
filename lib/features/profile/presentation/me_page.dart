import 'package:flutter/material.dart';

import '../../../services/users/users_service.dart';
import '../../../l10n/app_localizations.dart';
import '../../account/presentation/account_page.dart';
import '../../orders/presentation/customer_orders_page.dart';
import '../../settings/presentation/settings_page.dart';

class MePage extends StatelessWidget {
  const MePage({
    super.key,
    required this.onOpenWishlist,
    required this.onOpenCart,
  });

  final VoidCallback onOpenWishlist;
  final VoidCallback onOpenCart;

  static bool _hasNetworkImage(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    final u = Uri.tryParse(url);
    return u != null && (u.isScheme('http') || u.isScheme('https'));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SafeArea(
      child: ListenableBuilder(
        listenable: CustomerProfileStore.instance,
        builder: (context, _) {
          final p = CustomerProfileStore.instance.profile;
          final name = p?.displayName ?? l10n.meProfileFallback;
          final subtitle = p?.mail?.trim().isNotEmpty == true
              ? p!.mail!
              : l10n.meCompleteProfile;
          final photoUrl = p?.profilePicture;
          final showAvatar = _hasNetworkImage(photoUrl);

          return SingleChildScrollView(
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
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFF1DACB),
                      backgroundImage: showAvatar ? NetworkImage(photoUrl!) : null,
                      child: showAvatar
                          ? null
                          : const Icon(Icons.person, size: 30, color: Color(0xFF6A4A35)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: const TextStyle(color: Color(0xFF6A4A35)),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _StatItem(label: l10n.meOrdersStat, value: '12'),
                    _StatItem(label: l10n.meWishlistStat, value: '24'),
                    _StatItem(label: l10n.mePointsStat, value: '2.4k'),
                  ],
                ),
                const SizedBox(height: 18),
                _OptionTile(
                  title: l10n.meAccountTitle,
                  subtitle: l10n.meAccountSubtitle,
                  icon: Icons.account_balance_wallet_outlined,
                  onTap: () {
                    Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AccountPage()));
                  },
                ),
                _OptionTile(
                  title: l10n.meWishlistTitle,
                  subtitle: l10n.meWishlistSubtitle,
                  icon: Icons.favorite_outline,
                  onTap: onOpenWishlist,
                ),
                _OptionTile(
                  title: l10n.meCartTitle,
                  subtitle: l10n.meCartSubtitle,
                  icon: Icons.shopping_bag_outlined,
                  onTap: onOpenCart,
                ),
                _OptionTile(
                  title: l10n.meOrderHistoryTitle,
                  subtitle: l10n.meOrderHistorySubtitle,
                  icon: Icons.history,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(builder: (_) => const CustomerOrdersPage()),
                    );
                  },
                ),
              ],
            ),
          );
        },
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
    this.titleColor,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? titleColor;

  @override
  Widget build(BuildContext context) {
    final tc = titleColor ?? const Color(0xFF3F2413);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: titleColor ?? const Color(0xFF3F2413)),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: tc)),
        subtitle: Text(subtitle),
        trailing: Icon(Icons.chevron_right, color: titleColor?.withValues(alpha: 0.65)),
      ),
    );
  }
}
