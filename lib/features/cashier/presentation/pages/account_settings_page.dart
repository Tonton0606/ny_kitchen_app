import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/session/session_manager.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/utils/security_utils.dart';
import '../../../../core/services/sync_service.dart';
import 'cashier_activity_logs_page.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  final UserRepository _userRepo = UserRepository();

  @override
  Widget build(BuildContext context) {
    final user = SessionManager().currentUser;
    final fullName = user?['full_name'] ?? 'Unknown User';
    final role = user?['role'] == 'admin' ? 'Admin' : 'Cashier';

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
                    const CircleAvatar(
                      radius: 44,
                      backgroundColor: AppColors.goldenYellow,
                      child: Icon(Icons.person, size: 44, color: Colors.white),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      fullName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.darkCharcoal,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.mutedText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildTile(
                icon: Icons.person_outline,
                title: 'Edit Profile',
                onTap: () => _showEditProfileDialog(context),
              ),
              _buildTile(
                icon: Icons.history,
                title: 'My Activity Logs',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const CashierActivityLogsPage(),
                    ),
                  );
                },
              ),
              _buildTile(
                icon: Icons.lock_outline,
                title: 'Change Password',
                onTap: () => _showChangePasswordDialog(context),
              ),
              // Cloud Syncing Preference Section for Cashier
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: AppColors.surfaceWhite,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
                    side: const BorderSide(color: AppColors.softBorder),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.cloud_sync_outlined, color: AppColors.darkCharcoal, size: 20),
                            SizedBox(width: 10),
                            Text(
                              'Cloud Syncing',
                              style: AppTypography.heading,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ValueListenableBuilder<String>(
                          valueListenable: SyncService.syncModeNotifier,
                          builder: (context, currentMode, _) {
                            return Column(
                              children: [
                                RadioListTile<String>(
                                  title: const Text(
                                    'Manual Cloud Sync',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.darkCharcoal),
                                  ),
                                  subtitle: const Text(
                                    'Displays the "Cloud Sync" button at the top. Syncs on demand.',
                                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
                                  ),
                                  value: 'manual',
                                  groupValue: currentMode,
                                  activeColor: AppColors.goldenYellow,
                                  contentPadding: EdgeInsets.zero,
                                  onChanged: (val) {
                                    if (val != null) SyncService().setSyncMode(val);
                                  },
                                ),
                                const Divider(height: 12, color: AppColors.softBorder),
                                RadioListTile<String>(
                                  title: const Text(
                                    'Automatic Cloud Sync',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.darkCharcoal),
                                  ),
                                  subtitle: const Text(
                                    'Automatically synchronizes transactions and menu across all devices.',
                                    style: TextStyle(color: AppColors.mutedText, fontSize: 12),
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
                ),
              ),
              _buildTile(
                icon: Icons.print_outlined,
                title: 'Printer Settings',
                onTap: () => _showPrinterSettingsDialog(context),
              ),
              _buildTile(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () => _showHelpSupportDialog(context),
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
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.softBorder),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListTile(
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.darkCharcoal, size: 24),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.darkCharcoal,
            ),
          ),
          trailing: const Icon(Icons.chevron_right, color: AppColors.mutedText),
          onTap: onTap,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 4,
          ),
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
                    labelText: 'Current Password',
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
                      const SnackBar(content: Text('Password changed successfully')),
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

  void _showEditProfileDialog(BuildContext context) {
    final currentName = SessionManager().fullName ?? '';
    final nameController = TextEditingController(text: currentName);
    final username = SessionManager().currentUser?['username'] as String? ?? '';
    final userId = SessionManager().userId;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Row(
          children: [
            Icon(Icons.person_outline, color: AppColors.darkCharcoal, size: 22),
            SizedBox(width: 10),
            Text('Edit Profile', style: AppTypography.heading),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Username', style: AppTypography.label),
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.softBorder),
              ),
              child: Text('@$username', style: AppTypography.bodyMuted),
            ),
            const SizedBox(height: 16),
            const Text('Full Name', style: AppTypography.label),
            const SizedBox(height: 6),
            TextField(
              controller: nameController,
              inputFormatters: [LengthLimitingTextInputFormatter(50)],
              decoration: InputDecoration(
                hintText: 'Enter your full name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: AppColors.softBorder),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel', style: AppTypography.buttonSmall),
          ),
          ElevatedButton(
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isEmpty || userId == null) return;
              try {
                await _userRepo.updateUser(userId, {'full_name': newName});
                final current = SessionManager().currentUser;
                if (current != null) {
                  final updated = Map<String, dynamic>.from(current);
                  updated['full_name'] = newName;
                  SessionManager().setSession(updated);
                }
                if (!context.mounted) return;
                Navigator.pop(ctx);
                setState(() {});
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile updated successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to update profile: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: AppColors.darkCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showPrinterSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Row(
          children: [
            Icon(Icons.print_outlined, color: AppColors.darkCharcoal, size: 22),
            SizedBox(width: 10),
            Text('Receipt Printer Configuration', style: AppTypography.heading),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF2563EB), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Ready: System Standard Thermal Printer (80mm / 58mm POS ESC/POS)',
                      style: TextStyle(fontSize: 12, color: Color(0xFF1E40AF), fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            const Text('Paper Size: 80mm Standard POS Roll', style: AppTypography.body),
            const SizedBox(height: 6),
            const Text('Printing Engine: Direct Windows / Android Print Spooler', style: AppTypography.bodyMuted),
            const SizedBox(height: 6),
            const Text('Auto-Cut: Enabled after receipt print', style: AppTypography.bodyMuted),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close', style: AppTypography.buttonSmall),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Test print sent to system receipt spooler.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: AppColors.darkCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Test Print', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showHelpSupportDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
        contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: AppColors.darkCharcoal, size: 22),
            SizedBox(width: 10),
            Text('POS Operations & Support Guide', style: AppTypography.heading),
          ],
        ),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quick Operations Guide', style: AppTypography.label),
              const SizedBox(height: 8),
              _buildHelpRow(
                'Clear Cart',
                'Empties order items before payment is tendered.',
              ),
              _buildHelpRow(
                'Void Order',
                'Cancels a preparing order before it leaves the kitchen (Transaction History).',
              ),
              _buildHelpRow(
                'Refund Order',
                'Returns cash for served orders with a recorded complaint or return reason.',
              ),
              _buildHelpRow(
                'Offline Mode',
                'The system operates offline using local SQLite. Changes automatically sync when network is restored.',
              ),
              const Divider(height: 20, color: AppColors.softBorder),
              const Text('System Information', style: AppTypography.label),
              const SizedBox(height: 6),
              const Text('App: Nanay\'s Kitchen POS v1.0.0 (Secure Edition)', style: AppTypography.caption),
              const Text('Architecture: Offline-First SQLite + Cloud Sync', style: AppTypography.caption),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: AppColors.darkCharcoal,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Got it', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRow(String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: const EdgeInsets.only(top: 6, right: 8),
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.darkCharcoal,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12, color: AppColors.darkCharcoal),
                children: [
                  TextSpan(text: '$title: ', style: const TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: description, style: const TextStyle(color: AppColors.mutedText)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
