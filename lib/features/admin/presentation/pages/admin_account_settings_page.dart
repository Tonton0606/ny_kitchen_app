import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/services/sync_service.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../shared/widgets/app_privacy_dialog.dart';
import '../../../shared/widgets/app_text_field.dart';
import '../../../shared/widgets/change_password_dialog.dart';

class AdminAccountSettingsPage extends StatefulWidget {
  const AdminAccountSettingsPage({super.key});

  @override
  State<AdminAccountSettingsPage> createState() => _AdminAccountSettingsPageState();
}

class _AdminAccountSettingsPageState extends State<AdminAccountSettingsPage> {
  final UserRepository _userRepo = UserRepository();
  final TextEditingController _fullNameController = TextEditingController();
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    final user = SessionManager().currentUser;
    _fullNameController.text = user?['full_name'] ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    final newName = _fullNameController.text.trim();
    final userId = SessionManager().userId;

    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Full name cannot be empty.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (userId == null) return;

    setState(() => _isSavingProfile = true);

    try {
      await _userRepo.updateUser(userId, {'full_name': newName});
      final current = SessionManager().currentUser;
      if (current != null) {
        final updated = Map<String, dynamic>.from(current);
        updated['full_name'] = newName;
        SessionManager().setSession(updated);
      }

      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

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
            padding: const EdgeInsets.all(AppDesignTokens.space24),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.goldenYellow,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Center(
                        child: Text(
                          initial,
                          style: const TextStyle(
                            fontFamily: AppTypography.displayFontFamily,
                            fontSize: 36,
                            color: AppColors.darkCharcoal,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.space12),
                    Text(
                      fullName,
                      style: AppTypography.headingLarge,
                    ),
                    const SizedBox(height: AppDesignTokens.space4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDesignTokens.space12,
                        vertical: AppDesignTokens.space4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.darkCharcoal,
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                      ),
                      child: const Text(
                        'Administrator',
                        style: TextStyle(
                          fontFamily: AppTypography.displayFontFamily,
                          color: AppColors.goldenYellow,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.space24),
              _buildSection(
                icon: Icons.person_outline,
                title: 'Profile Details',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: AppDesignTokens.space16),
                    // Username is immutable / system identifier
                    const Text('Username', style: AppTypography.label),
                    const SizedBox(height: 6),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.pageBackground,
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        border: Border.all(color: AppColors.softBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.account_circle_outlined, size: 20, color: AppColors.mutedBrown),
                          const SizedBox(width: AppDesignTokens.space12),
                          Text('@$username', style: AppTypography.bodyMuted),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppDesignTokens.space16),
                    AppTextField(
                      controller: _fullNameController,
                      label: 'Full Name',
                      hint: 'Enter your full name',
                      prefixIcon: const Icon(Icons.badge_outlined, size: 20, color: AppColors.mutedBrown),
                      inputFormatters: [LengthLimitingTextInputFormatter(50)],
                    ),
                    const SizedBox(height: AppDesignTokens.space16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton.icon(
                        onPressed: _isSavingProfile ? null : _handleSaveProfile,
                        icon: _isSavingProfile
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCharcoal),
                                ),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: const Text('Save Profile', style: AppTypography.button),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: AppColors.darkCharcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                        padding: const EdgeInsets.all(AppDesignTokens.space8),
                        decoration: BoxDecoration(
                          color: AppColors.pageBackground,
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        ),
                        child: const Icon(Icons.lock_reset, color: AppColors.darkCharcoal, size: 22),
                      ),
                      title: const Text('Change Password', style: AppTypography.heading),
                      subtitle: const Text('Update administrative password with verification', style: AppTypography.bodyMuted),
                      trailing: ElevatedButton(
                        onPressed: () => ChangePasswordDialog.show(context, isAdmin: true),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: AppColors.darkCharcoal,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        child: const Text('Change', style: AppTypography.button),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _buildSection(
                icon: Icons.info_outline,
                title: 'Application Information',
                child: Column(
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
}

