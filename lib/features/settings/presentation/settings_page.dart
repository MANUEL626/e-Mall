import 'package:flutter/material.dart';

import '../../../core/auth/sign_out_ui.dart';
import '../../../l10n/app_localizations.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static const _muted = Color(0xFF7D6A62);
  static const _surface = Color(0xFFFFF9F5);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: _surface,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _ProfileHeader(),
            const SizedBox(height: 32),
            _SectionTitle(label: 'Profile information'),
            const SizedBox(height: 14),
            _FieldCard(
              title: 'USERNAME',
              child: const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.alternate_email, color: _muted),
                  border: InputBorder.none,
                  hintText: 'emall_amara',
                  hintStyle: TextStyle(color: Color(0xFFB8A89E)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldCard(
              title: 'DISPLAY NAME',
              child: const TextField(
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.edit_outlined, color: _muted),
                  border: InputBorder.none,
                  hintText: 'Amara Okafor',
                  hintStyle: TextStyle(color: Color(0xFFB8A89E)),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 16),
            _FieldCard(
              title: 'BIO',
              child: const TextField(
                maxLines: 3,
                decoration: InputDecoration(
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Icon(Icons.description_outlined, color: _muted),
                  ),
                  alignLabelWithHint: true,
                  border: InputBorder.none,
                  hintText: 'Curating the finest contemporary African crafts for the modern world.',
                  hintStyle: TextStyle(color: Color(0xFFB8A89E), height: 1.4),
                  contentPadding: EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 36),
            _SectionTitle(label: 'App settings'),
            const SizedBox(height: 14),
            _SettingsGroupCard(
              children: [
                _MenuTile(
                  title: 'Notifications',
                  subtitle: 'Push, Email, and SMS alerts',
                  icon: Icons.notifications_none_outlined,
                ),
                const Divider(height: 1, indent: 0),
                _MenuTile(
                  title: 'Privacy & Security',
                  subtitle: 'Password, 2FA, and data privacy',
                  icon: Icons.lock_outline_rounded,
                ),
                const Divider(height: 1, indent: 0),
                _MenuTile(
                  title: 'Payment Methods',
                  subtitle: 'Manage cards and digital wallets',
                  icon: Icons.payment_outlined,
                ),
              ],
            ),
            const SizedBox(height: 36),
            _SectionTitle(label: 'Legal & account'),
            const SizedBox(height: 14),
            _SettingsGroupCard(
              children: [
                _MenuTile(
                  title: 'Privacy Policy',
                  subtitle: 'Read our user privacy terms',
                  icon: Icons.verified_user_outlined,
                ),
                const Divider(height: 1, indent: 0),
                _MenuTile(
                  title: l10n.signOutMenuTitle,
                  subtitle: l10n.signOutMenuSubtitle,
                  icon: Icons.logout_outlined,
                  isDestructive: true,
                  onTap: () => presentSignOutFlow(context),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: Text(
                'e-Mall · v1.0.0',
                style: TextStyle(
                  color: _muted.withValues(alpha: 0.85),
                  fontSize: 12,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE8D5C8), width: 2),
          ),
          child: const CircleAvatar(
            radius: 44,
            backgroundColor: Color(0xFFF1DACB),
            child: Icon(Icons.person, size: 42, color: Color(0xFF6A4A35)),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Amara Okafor',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Color(0xFF3F2413),
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          '@emall_amara',
          style: TextStyle(
            fontSize: 15,
            color: Color(0xFF7D6A62),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.2,
        color: Color(0xFF8B7355),
      ),
    );
  }
}

class _SettingsGroupCard extends StatelessWidget {
  const _SettingsGroupCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(children: children),
    );
  }
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3E5DB),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 0.8,
              color: Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isDestructive = false,
    this.onTap,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isDestructive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final destructiveColor = const Color(0xFF9A2F20);
    final iconColor = isDestructive ? destructiveColor : const Color(0xFF4E2D1D);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFF1DACB),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: isDestructive ? destructiveColor : const Color(0xFF3F2413),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.35,
                        color: const Color(0xFF7D6A62),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: isDestructive ? destructiveColor.withValues(alpha: 0.6) : const Color(0xFFC4B5A8),
                  size: 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
