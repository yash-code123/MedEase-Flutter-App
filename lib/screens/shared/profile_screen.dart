import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/theme.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';

/// Shared profile screen for all three roles — shows identity, role badge,
/// and sign-out. Kept role-agnostic so it can live in any bottom nav.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final roleColor = MedEaseTheme.roleColor(user?.role ?? 'patient');

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: roleColor.withValues(alpha: 0.15),
                  child: Text(
                    (user?.username.isNotEmpty == true ? user!.username[0] : '?').toUpperCase(),
                    style: TextStyle(fontSize: 28, color: roleColor, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 12),
                Text(user?.username ?? '', style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    (user?.role ?? '').toUpperCase(),
                    style: TextStyle(color: roleColor, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined, color: MedEaseColors.primary),
                  title: const Text('Reference ID'),
                  subtitle: Text(user?.refId ?? '—'),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.info_outline, color: MedEaseColors.primary),
                  title: const Text('About MedEase'),
                  subtitle: const Text('Same backend & database as the MedEase website'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: const Icon(Icons.logout_rounded),
              label: const Text('Sign out'),
              style: OutlinedButton.styleFrom(foregroundColor: MedEaseColors.danger, side: const BorderSide(color: MedEaseColors.danger)),
              onPressed: () async {
                await context.read<AuthProvider>().logout();
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false,
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
