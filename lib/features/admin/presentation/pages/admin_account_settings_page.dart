import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/utils/security_utils.dart';
import '../../../shared/widgets/app_privacy_dialog.dart';

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
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(50),
                      ],
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
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                        LengthLimitingTextInputFormatter(25),
                      ],
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
                        return Column(
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
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.security_outlined,
                title: 'Security & Password',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.lock_reset, color: AppColors.darkCharcoal, size: 24),
                      ),
                      title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.darkCharcoal)),
                      subtitle: const Text('Update administrative password with verification', style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
                      trailing: ElevatedButton(
                        onPressed: () => _showChangePasswordDialog(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: AppColors.darkCharcoal,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        child: const Text('Change', style: TextStyle(fontWeight: FontWeight.bold)),
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
                      onTap: () => AppPrivacyDialog.show(context),
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
                        child: const Icon(Icons.privacy_tip_outlined, color: AppColors.darkCharcoal, size: 24),
                      ),
                      title: const Text('Data Privacy & Retention Policy', style: TextStyle(fontWeight: FontWeight.w500, color: AppColors.darkCharcoal)),
                      subtitle: const Text('Republic Act No. 10173 (Data Privacy Act of 2012) compliance', style: TextStyle(color: AppColors.mutedText)),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
                      onTap: () => AppPrivacyDialog.show(context),
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
    return Material(
      color: AppColors.surfaceWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        side: const BorderSide(color: AppColors.softBorder),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: AppColors.darkCharcoal, size: 20),
                const SizedBox(width: 10),
                Text(title, style: AppTypography.heading),
              ],
            ),
            child,
          ],
        ),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.goldenYellow,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: AppColors.darkCharcoal,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Text(
                'Change Password',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: currentPasswordController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(64),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Current Master Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscureCurrent = !obscureCurrent),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: obscureCurrent,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: newPasswordController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(64),
                  ],
                  decoration: InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: const Icon(Icons.lock_reset_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(obscureNew ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscureNew = !obscureNew),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: obscureNew,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmPasswordController,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(64),
                  ],
                  decoration: InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  obscureText: obscureConfirm,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text(
                'Cancel',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
              ),
            ),
            ElevatedButton(
              onPressed: () async {
                final currentPass = currentPasswordController.text.trim();
                final newPass = newPasswordController.text.trim();
                final confirmPass = confirmPasswordController.text.trim();

                if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please fill all required password fields')),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('New passwords do not match')),
                  );
                  return;
                }
                final policyError = SecurityUtils.validatePassword(newPass);
                if (policyError != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(policyError)),
                  );
                  return;
                }

                final userId = SessionManager().userId;
                if (userId != null) {
                  final repo = UserRepository();
                  try {
                    await repo.changePasswordWithVerification(userId, currentPass, newPass);
                    if (!context.mounted) return;
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Password updated successfully')),
                    );
                  } catch (e) {
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to update password: $e')),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldenYellow,
                foregroundColor: Colors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text(
                'Save',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
