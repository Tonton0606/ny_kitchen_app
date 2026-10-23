import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';
import '../../../core/session/session_manager.dart';
import '../../../core/database/repositories/user_repository.dart';
import '../../../core/utils/security_utils.dart';
import '../../../core/utils/security_exception.dart';
import 'app_text_field.dart';

/// Clean, standardized Change Password Dialog conforming strictly to UI_PRINCIPLES.md:
/// - Surface: AppColors.surfaceWhite with 1px AppColors.softBorder and radius12.
/// - Typography: Space Grotesk heading & button, Inter body/labels.
/// - Strict adherence to validation: current password verification, matching confirm,
///   and PBKDF2-compliant password policy (min 8 chars, letters, and numbers).
class ChangePasswordDialog extends StatefulWidget {
  final bool isAdmin;

  const ChangePasswordDialog({
    super.key,
    this.isAdmin = false,
  });

  static Future<bool?> show(BuildContext context, {bool isAdmin = false}) {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => ChangePasswordDialog(isAdmin: isAdmin),
    );
  }

  @override
  State<ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    setState(() => _errorMessage = null);

    final currentPass = _currentPasswordController.text.trim();
    final newPass = _newPasswordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    if (currentPass.isEmpty || newPass.isEmpty || confirmPass.isEmpty) {
      setState(() => _errorMessage = 'Please fill all required password fields.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }

    final policyError = SecurityUtils.validatePassword(newPass);
    if (policyError != null) {
      setState(() => _errorMessage = policyError);
      return;
    }

    final userId = SessionManager().userId;
    if (userId == null) {
      setState(() => _errorMessage = 'No active user session found.');
      return;
    }

    setState(() => _isLoading = true);
    final repo = UserRepository();

    try {
      await repo.changePasswordWithVerification(userId, currentPass, newPass);
      if (!mounted) return;
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        if (e is SecurityException) {
          _errorMessage = e.code == 'INVALID_CURRENT_PASSWORD'
              ? 'Current password is incorrect. Please try again.'
              : e.message;
        } else {
          _errorMessage = e
              .toString()
              .replaceFirst('SecurityException: ', '')
              .replaceFirst('Exception: ', '');
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        side: const BorderSide(color: AppColors.softBorder, width: 1.0),
      ),
      titlePadding: const EdgeInsets.fromLTRB(
        AppDesignTokens.space24,
        AppDesignTokens.space24,
        AppDesignTokens.space24,
        0,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        AppDesignTokens.space24,
        AppDesignTokens.space16,
        AppDesignTokens.space24,
        AppDesignTokens.space16,
      ),
      actionsPadding: const EdgeInsets.fromLTRB(
        AppDesignTokens.space24,
        0,
        AppDesignTokens.space24,
        AppDesignTokens.space16,
      ),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignTokens.space8),
            decoration: BoxDecoration(
              color: AppColors.goldenYellow,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            child: const Icon(
              Icons.lock_reset,
              color: AppColors.darkCharcoal,
              size: 22,
            ),
          ),
          const SizedBox(width: AppDesignTokens.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Change Password',
                  style: AppTypography.headingLarge,
                ),
                SizedBox(height: 2),
                Text(
                  'Must be at least 8 characters with letters and numbers',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppDesignTokens.space12,
                    vertical: AppDesignTokens.space8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.brandRed.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                    border: Border.all(
                      color: AppColors.brandRed.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.brandRed, size: 18),
                      const SizedBox(width: AppDesignTokens.space8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontFamily: AppTypography.bodyFontFamily,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.brandRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppDesignTokens.space16),
              ],
              AppTextField(
                controller: _currentPasswordController,
                label: widget.isAdmin ? 'Current Master Password' : 'Current Password',
                hint: 'Enter your existing password',
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.mutedBrown),
                inputFormatters: [LengthLimitingTextInputFormatter(64)],
              ),
              const SizedBox(height: AppDesignTokens.space16),
              AppTextField(
                controller: _newPasswordController,
                label: 'New Password',
                hint: 'Minimum 8 alphanumeric characters',
                isPassword: true,
                prefixIcon: const Icon(Icons.lock_reset_outlined, size: 20, color: AppColors.mutedBrown),
                inputFormatters: [LengthLimitingTextInputFormatter(64)],
              ),
              const SizedBox(height: AppDesignTokens.space16),
              AppTextField(
                controller: _confirmPasswordController,
                label: 'Confirm New Password',
                hint: 'Re-enter your new password',
                isPassword: true,
                prefixIcon: const Icon(Icons.check_circle_outline, size: 20, color: AppColors.mutedBrown),
                inputFormatters: [LengthLimitingTextInputFormatter(64)],
              ),
            ],
          ),
        ),
      ),
      actions: [
        OutlinedButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(false),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.softBorder),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text(
            'Cancel',
            style: AppTypography.button.copyWith(color: AppColors.darkCharcoal),
          ),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldenYellow,
            foregroundColor: AppColors.darkCharcoal,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: _isLoading
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.darkCharcoal),
                  ),
                )
              : const Text(
                  'Update Password',
                  style: AppTypography.button,
                ),
        ),
      ],
    );
  }
}
