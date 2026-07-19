import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/session/session_manager.dart';

class AdminAccountSettingsPage extends StatefulWidget {
  const AdminAccountSettingsPage({super.key});

  @override
  State<AdminAccountSettingsPage> createState() => _AdminAccountSettingsPageState();
}

class _AdminAccountSettingsPageState extends State<AdminAccountSettingsPage> {
  bool _darkTheme = false;

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final fullName = user?['full_name'] ?? 'Admin User';
    final username = user?['username'] ?? 'admin';
    final initial = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'A';

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
                    'Manage administrator profile and preferences',
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
                    Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            color: AppColors.goldenYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(44),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(fontSize: 44, color: AppColors.goldenYellow, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.goldenYellow,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.goldenYellow.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Administrator',
                        style: TextStyle(color: AppColors.goldenYellow, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildSection(
                icon: Icons.person_outline,
                title: 'Profile Details',
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.person_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: TextEditingController(text: fullName),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      decoration: InputDecoration(
                        labelText: 'Username',
                        labelStyle: const TextStyle(fontWeight: FontWeight.w500),
                        prefixIcon: const Icon(Icons.account_circle_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.white,
                      ),
                      controller: TextEditingController(text: username),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Settings saved successfully'), behavior: SnackBarBehavior.floating),
                          );
                        },
                        icon: const Icon(Icons.save_outlined, size: 20),
                        label: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: Colors.black,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.palette_outlined,
                title: 'Application Preferences',
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Dark Theme', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.darkCharcoal)),
                      subtitle: const Text('Enable dark mode for the application interface', style: TextStyle(color: AppColors.mutedText)),
                      value: _darkTheme,
                      onChanged: (val) => setState(() => _darkTheme = val),
                      activeTrackColor: AppColors.goldenYellow.withValues(alpha: 0.5),
                      activeThumbColor: AppColors.goldenYellow,
                      secondary: Icon(
                        _darkTheme ? Icons.dark_mode : Icons.light_mode,
                        color: _darkTheme ? AppColors.goldenYellow : AppColors.mutedText,
                      ),
                      contentPadding: EdgeInsets.zero,
                    ),
                    const Divider(height: 24, color: AppColors.softBorder),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.goldenYellow, size: 24),
                      ),
                      title: const Text('About Application', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.darkCharcoal)),
                      subtitle: const Text('N.Y Kitchen Secure Order and Sales Management System', style: TextStyle(color: AppColors.mutedText)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('v1.0.0', style: TextStyle(color: AppColors.goldenYellow, fontWeight: FontWeight.bold, fontSize: 13)),
                      ),
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSection({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldenYellow.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.goldenYellow, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
