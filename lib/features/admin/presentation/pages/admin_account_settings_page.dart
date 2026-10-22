import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/services/sync_service.dart';

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
                            color: AppColors.goldenYellow,
                            borderRadius: BorderRadius.circular(44),
                          ),
                          child: Center(
                            child: Text(
                              initial,
                              style: const TextStyle(fontSize: 44, color: AppColors.darkCharcoal, fontWeight: FontWeight.bold),
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
                        color: AppColors.darkCharcoal,
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
              _buildSection(
                icon: Icons.cloud_sync_outlined,
                title: 'Cloud Synchronization',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ValueListenableBuilder<String>(
                      valueListenable: SyncService.syncModeNotifier,
                      builder: (context, currentMode, _) {
                        return Material(
                          color: Colors.transparent,
                          child: Column(
                            children: [
                              RadioListTile<String>(
                                title: const Text(
                                  'Manual Cloud Sync',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkCharcoal),
                                ),
                                subtitle: const Text(
                                  'Shows a single "Cloud Sync" button in the top bar. Syncs transactions and menu on demand.',
                                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                                ),
                                value: 'manual',
                                groupValue: currentMode,
                                activeColor: AppColors.goldenYellow,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) {
                                  if (val != null) SyncService().setSyncMode(val);
                                },
                              ),
                              const Divider(height: 16, color: AppColors.softBorder),
                              RadioListTile<String>(
                                title: const Text(
                                  'Automatic Cloud Sync',
                                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.darkCharcoal),
                                ),
                                subtitle: const Text(
                                  'Continuously synchronizes sales transactions and menu changes automatically across all connected devices in the background.',
                                  style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                                ),
                                value: 'automatic',
                                groupValue: currentMode,
                                activeColor: AppColors.goldenYellow,
                                contentPadding: EdgeInsets.zero,
                                onChanged: (val) {
                                  if (val != null) SyncService().setSyncMode(val);
                                },
                              ),
                            ],
                          ),
                        );
                      },
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
                          color: AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.info_outline, color: AppColors.darkCharcoal, size: 24),
                      ),
                      title: const Text('About Application', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.darkCharcoal)),
                      subtitle: const Text('N.Y Kitchen Secure Order and Sales Management System', style: TextStyle(color: AppColors.mutedText)),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text('v1.0.0', style: TextStyle(color: AppColors.darkCharcoal, fontWeight: FontWeight.bold, fontSize: 13)),
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
                  color: AppColors.goldenYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: AppColors.darkCharcoal, size: 24),
              ),
              const SizedBox(width: 12),
              Text(title, style: AppTypography.sectionTitle),
            ],
          ),
          child,
        ],
      ),
    );
  }
}
