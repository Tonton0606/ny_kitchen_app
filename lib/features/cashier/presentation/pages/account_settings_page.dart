import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

class AccountSettingsPage extends StatelessWidget {
  const AccountSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Account Settings',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Manage your profile and preferences',
                    style: TextStyle(color: AppColors.mutedText, fontSize: 15),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            children: [
              Center(
                child: Column(
                  children: [
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.goldenYellow,
                      child: Icon(Icons.person, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'John Doe',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cashier',
                      style: TextStyle(fontSize: 15, color: AppColors.mutedText),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.print_outlined,
                title: 'Printer Settings',
                onTap: () {},
              ),
              _buildTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        tileColor: Colors.white,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.goldenYellow.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColors.goldenYellow, size: 24),
        ),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.darkCharcoal)),
        trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.softBorder),
        ),
      ),
    );
  }
}
