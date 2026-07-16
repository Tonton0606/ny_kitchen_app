import 'package:flutter/material.dart';


class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Account Settings',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
                Text('Manage your profile and preferences',
                  style: TextStyle(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                 CircleAvatar(
                  radius: 50,
                  backgroundColor: cs.primary,
                  child: Icon(Icons.person, size: 50, color: cs.onPrimary),
                ),
                const SizedBox(height: 16),
                Text(
                  'John Doe',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                 Text(
                   'Cashier',
                   textAlign: TextAlign.center,
                   style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: cs.onSurfaceVariant),
                 ),
                const SizedBox(height: 32),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.person_outline,
                  title: 'Edit Profile',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.lock_outline,
                  title: 'Change Password',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.print_outlined,
                  title: 'Printer Settings',
                  onTap: () {},
                ),
                _buildSettingsTile(
                  context: context,
                  icon: Icons.help_outline,
                  title: 'Help & Support',
                  onTap: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required BuildContext context,
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final cs = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        side: BorderSide(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ListTile(
        leading: Icon(icon, color: cs.onSurface),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
        trailing: Icon(Icons.chevron_right, color: cs.onSurfaceVariant),
        onTap: onTap,
      ),
    );
  }
}
