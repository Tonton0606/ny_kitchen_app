import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_design_tokens.dart';

/// Clean, professional Data Privacy Notice Dialog conforming to UI_PRINCIPLES.md
/// and demonstrating Republic Act No. 10173 (Data Privacy Act of 2012) compliance.
class AppPrivacyDialog extends StatelessWidget {
  const AppPrivacyDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      builder: (ctx) => const AppPrivacyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDesignTokens.radius16),
        side: const BorderSide(color: AppColors.softBorder),
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
        AppDesignTokens.space16,
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
              Icons.privacy_tip_rounded,
              color: AppColors.darkCharcoal,
              size: 24,
            ),
          ),
          const SizedBox(width: AppDesignTokens.space12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Data Privacy & Protection',
                  style: AppTypography.headingLarge,
                ),
                Text(
                  'Republic Act No. 10173 (Data Privacy Act of 2012)',
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: 520,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDesignTokens.space12),
                decoration: BoxDecoration(
                  color: AppColors.canvasBackground,
                  borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                  border: Border.all(color: AppColors.softBorder),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: AppColors.forest,
                      size: 20,
                    ),
                    SizedBox(width: AppDesignTokens.space8),
                    Expanded(
                      child: Text(
                        'N.Y Kitchen POS processes data strictly in accordance with NPC guidelines, focusing on Transparency, Legitimate Purpose, and Proportionality.',
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppDesignTokens.space16),

              _buildPolicySection(
                icon: Icons.minimize_rounded,
                title: 'Data Minimization (Zero Customer PII)',
                description:
                    'Counter checkout collects zero customer personal information (no customer phone numbers, home addresses, or credit cards). Transactions are tracked strictly by receipt serial number.',
              ),
              _buildPolicySection(
                icon: Icons.key_rounded,
                title: 'Credential Protection & Cryptography',
                description:
                    'Employee passwords are encrypted using PBKDF2-HMAC-SHA256 (600,000 iterations) with cryptographically secure random salts. Plaintext passwords and tokens are never stored, logged, or exported.',
              ),
              _buildPolicySection(
                icon: Icons.calendar_month_rounded,
                title: 'Official Data Retention Schedule',
                description:
                    'Sales & tax transactions: 5 years (BIR compliance).\n'
                    'Security audit logs: 2 years (immutable forensic trail).\n'
                    'Failed login attempts: 90 days rolling purge.\n'
                    'Employee accounts: Soft-disabled upon departure to preserve historical attribution.',
              ),
              _buildPolicySection(
                icon: Icons.admin_panel_settings_outlined,
                title: 'Data Subject Rights & Breach Response',
                description:
                    'Employees have the right to information, access, and rectification of account data. Confirmed security incidents follow a mandatory 72-hour National Privacy Commission (NPC) notification protocol (NPC Circular 16-03).',
              ),

              const Divider(height: 24, color: AppColors.softBorder),
              const Center(
                child: Text(
                  'Standard Operating Procedure: docs/DATA_PRIVACY_AND_RETENTION_SOP.md',
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.goldenYellow,
            foregroundColor: AppColors.darkCharcoal,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          child: const Text('Close', style: AppTypography.button),
        ),
      ],
    );
  }

  Widget _buildPolicySection({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDesignTokens.space12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppDesignTokens.space4),
            decoration: BoxDecoration(
              color: AppColors.pageBackground,
              borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
            ),
            child: Icon(icon, size: 16, color: AppColors.darkCharcoal),
          ),
          const SizedBox(width: AppDesignTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.label.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTypography.bodyMuted.copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
