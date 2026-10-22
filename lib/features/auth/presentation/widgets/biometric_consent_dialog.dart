import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../shared/widgets/app_buttons.dart';

/// Modal dialog that informs staff of biometric data processing and obtains
/// explicit informed consent prior to facial template enrollment (Fix 2).
///
/// Conforms to ISO/IEC 25010 data privacy, Bishop integrity controls, and
/// statutory biometric retention standards (local-only AES-256-GCM storage,
/// cloud exclusion, voluntary participation, and right to permanent erasure).
class BiometricConsentDialog extends StatefulWidget {
  final String? targetUserName;

  const BiometricConsentDialog({
    super.key,
    this.targetUserName,
  });

  /// Displays the consent dialog and returns `true` if the user accepts or `false` otherwise.
  static Future<bool> show(
    BuildContext context, {
    String? targetUserName,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => BiometricConsentDialog(targetUserName: targetUserName),
    );
    return result ?? false;
  }

  @override
  State<BiometricConsentDialog> createState() => _BiometricConsentDialogState();
}

class _BiometricConsentDialogState extends State<BiometricConsentDialog> {
  bool _acknowledged = false;

  @override
  Widget build(BuildContext context) {
    final nameLabel = widget.targetUserName != null
        ? ' for ${widget.targetUserName}'
        : '';

    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
        side: const BorderSide(color: AppColors.softBorder, width: 1),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
      contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.goldenYellow,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            child: const Icon(
              Icons.fingerprint_rounded,
              color: AppColors.darkCharcoal,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Biometric Consent$nameLabel',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.darkCharcoal,
              ),
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Please review the biometric data terms before enrolling facial authentication:',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.mutedBrown,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              _buildBulletItem(
                icon: Icons.lock_outline_rounded,
                title: 'Local AES-256-GCM Encryption',
                description:
                    'Facial templates are converted to numerical mathematical vectors and encrypted locally using authenticated AES-256-GCM ciphertexts.',
              ),
              const SizedBox(height: 12),
              _buildBulletItem(
                icon: Icons.cloud_off_rounded,
                title: 'No Cloud Transmission',
                description:
                    'Biometric encodings and face images are never uploaded to Supabase or transmitted to external networks. They remain strictly on this terminal.',
              ),
              const SizedBox(height: 12),
              _buildBulletItem(
                icon: Icons.delete_forever_outlined,
                title: 'Right to Permanent Erasure',
                description:
                    'Enrolled biometric profiles can be permanently deleted at any time by an administrator upon staff request.',
              ),
              const SizedBox(height: 12),
              _buildBulletItem(
                icon: Icons.how_to_reg_outlined,
                title: 'Voluntary Participation',
                description:
                    'Biometric login is voluntary. Standard username and password authentication remains available for all operations.',
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.creamBackground,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _acknowledged,
                      activeColor: AppColors.brandRed,
                      onChanged: (val) {
                        setState(() {
                          _acknowledged = val ?? false;
                        });
                      },
                    ),
                    const Expanded(
                      child: Text(
                        'I have informed the employee and consent has been confirmed.',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.darkCharcoal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          autofocus: true,
          onPressed: () => Navigator.of(context).pop(false),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            foregroundColor: AppColors.darkCharcoal,
          ),
          child: const Text(
            'Decline',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
              color: AppColors.darkCharcoal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        AppPrimaryButton(
          text: 'Accept & Proceed',
          onPressed: _acknowledged
              ? () => Navigator.of(context).pop(true)
              : null,
        ),
      ],
    );
  }

  Widget _buildBulletItem({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.creamBackground,
            borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
          ),
          child: Icon(icon, size: 18, color: AppColors.darkCharcoal),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkCharcoal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.mutedBrown,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
