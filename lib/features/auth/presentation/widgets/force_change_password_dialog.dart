import 'package:flutter/material.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/utils/security_utils.dart';

class ForceChangePasswordDialog extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;
  final Future<bool> Function(int userId, String newPassword)? onSavePassword;

  const ForceChangePasswordDialog({
    super.key,
    required this.user,
    required this.onSuccess,
    required this.onCancel,
    this.onSavePassword,
  });

  @override
  State<ForceChangePasswordDialog> createState() => _ForceChangePasswordDialogState();
}

class _ForceChangePasswordDialogState extends State<ForceChangePasswordDialog> {
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userRepo = UserRepository();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill out both password fields');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'Passwords do not match');
      return;
    }

    if (!SecurityUtils.isPasswordValid(newPassword)) {
      setState(() => _errorMessage = SecurityUtils.passwordPolicyMessage);
      return;
    }

    // Ensure they don't reuse known default passwords
    final username = (widget.user['username'] as String?)?.toLowerCase() ?? '';
    if (newPassword == 'admin123' ||
        newPassword == 'cashier123' ||
        newPassword.toLowerCase() == '${username}123') {
      setState(() => _errorMessage = 'Cannot reuse default or trivial credentials');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      final userId = widget.user['id'] as int;
      final success = widget.onSavePassword != null
          ? await widget.onSavePassword!(userId, newPassword)
          : await _userRepo.changePassword(userId, newPassword);

      if (!mounted) return;

      if (success) {
        // Update local map if mutable
        try {
          widget.user['must_change_password'] = 0;
        } catch (_) {}
        widget.onSuccess();
      } else {
        setState(() {
          _isSubmitting = false;
          _errorMessage = 'Failed to update password. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder, width: 1),
        ),
        backgroundColor: AppColors.surfaceWhite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.brandRed.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: AppColors.brandRed,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Password Change Required',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: AppColors.darkCharcoal,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Security Policy Requirement (Gap 3)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.mutedBrown,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.creamBackground,
                      borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                      border: Border.all(color: AppColors.softBorder, width: 1),
                    ),
                    child: const Text(
                      'Default and temporary credentials must be changed on initial login. Your new password must be at least 8 characters long and include both letters and numbers.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.darkCharcoal,
                        height: 1.4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: _obscureNew,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mutedBrown),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNew ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.mutedBrown,
                        ),
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        borderSide: const BorderSide(color: AppColors.goldenYellow, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirm,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.mutedBrown),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          color: AppColors.mutedBrown,
                        ),
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        borderSide: const BorderSide(color: AppColors.softBorder, width: 1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        borderSide: const BorderSide(color: AppColors.goldenYellow, width: 2),
                      ),
                      filled: true,
                      fillColor: AppColors.surfaceWhite,
                    ),
                  ),
                  if (_errorMessage != null) ...[
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.brandRed.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                        border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, size: 18, color: AppColors.brandRed),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.brandRed,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Wrap(
                    alignment: WrapAlignment.end,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      TextButton(
                        onPressed: _isSubmitting ? null : widget.onCancel,
                        autofocus: true,
                        child: const Text(
                          'Cancel / Log Out',
                          style: TextStyle(
                            color: AppColors.darkCharcoal,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                          boxShadow: _isSubmitting
                              ? null
                              : const [
                                  BoxShadow(
                                    color: AppColors.goldTactileEdge,
                                    offset: Offset(0, 2.5),
                                    blurRadius: 0,
                                    spreadRadius: 0,
                                  ),
                                ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isSubmitting ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldenYellow,
                            foregroundColor: AppColors.darkCharcoal,
                            disabledBackgroundColor: AppColors.disabled,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDesignTokens.radius8)),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: _isSubmitting
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.darkCharcoal),
                                )
                              : const Text(
                                  'Set Password & Continue',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
