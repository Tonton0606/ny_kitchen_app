import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../widgets/app_buttons.dart';
import '../widgets/app_text_field.dart';
import '../widgets/app_card.dart';
import '../widgets/app_status_chip.dart';
import '../widgets/app_state_placeholders.dart';
import '../widgets/app_confirm_dialog.dart';
import '../widgets/app_data_table.dart';
import '../widgets/cashier_list_tile.dart';

/// Debug-Only Component Gallery Page to visually inspect, test, and demonstrate
/// all Phase 2 components in one cohesive interface.
class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  final TextEditingController _textController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  int _sampleQty = 2;

  @override
  void dispose() {
    _textController.dispose();
    _passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      appBar: AppBar(
        title: const Text('UI Component Gallery (Debug)'),
        backgroundColor: AppColors.darkCharcoal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppDesignTokens.space24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('1. Buttons & Tactile 3D Depth'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AppPrimaryButton(
                  text: 'Primary Gold (48px)',
                  icon: Icons.check,
                  onPressed: () {},
                ),
                AppPrimaryButton(
                  text: 'Primary POS (56px)',
                  icon: Icons.shopping_cart_checkout,
                  isLarge: true,
                  onPressed: () {},
                ),
                AppPrimaryButton(
                  text: 'Loading',
                  isLoading: true,
                  onPressed: () {},
                ),
                const AppPrimaryButton(
                  text: 'Disabled',
                  onPressed: null,
                ),
                AppSecondaryButton(
                  text: 'Secondary Outline',
                  icon: Icons.tune,
                  onPressed: () {},
                ),
                AppDestructiveButton(
                  text: 'Destructive Red',
                  icon: Icons.delete_outline,
                  onPressed: () => _openConfirmDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('2. Text Fields (Visible Labels & Inline Errors)'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                children: [
                  AppTextField(
                    label: 'Username / Cashier ID',
                    hint: 'e.g. cashier_01',
                    controller: _textController,
                    prefixIcon: const Icon(Icons.person_outline, size: 20, color: AppColors.mutedBrown),
                  ),
                  const SizedBox(height: 16),
                  AppTextField(
                    label: 'Password',
                    hint: 'Enter your password',
                    controller: _passController,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline, size: 20, color: AppColors.mutedBrown),
                  ),
                  const SizedBox(height: 16),
                  const AppTextField(
                    label: 'Field with Inline Error',
                    hint: 'Invalid input demonstration',
                    errorText: 'Password must be at least 8 characters with letters & numbers.',
                    prefixIcon: Icon(Icons.shield_outlined, size: 20, color: AppColors.brandRed),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('3. Semantic Status Chips'),
            const SizedBox(height: 12),
            const Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                AppStatusChip(label: 'Paid / Synced', type: AppStatusType.success),
                AppStatusChip(label: 'Syncing to Cloud', type: AppStatusType.info),
                AppStatusChip(label: 'Low Inventory (2 left)', type: AppStatusType.warning),
                AppStatusChip(label: 'Account Locked (5 fails)', type: AppStatusType.error),
                AppStatusChip(label: 'In Stock', type: AppStatusType.success, isCompact: true),
                AppStatusChip(label: 'Offline', type: AppStatusType.error, isCompact: true),
              ],
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('4. Cashier Cart List Tile'),
            const SizedBox(height: 12),
            AppCard(
              child: CashierListTile(
                title: 'Classic Burger with Cheese',
                subtitle: 'Single patty, cheddar',
                unitPrice: 120.00,
                quantity: _sampleQty,
                onIncrease: () => setState(() => _sampleQty++),
                onDecrease: () => setState(() => _sampleQty = _sampleQty > 1 ? _sampleQty - 1 : 1),
                onRemove: () {},
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('5. Skeletons & Flat Loading'),
            const SizedBox(height: 12),
            AppCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  AppSkeleton(width: 180, height: 18),
                  SizedBox(height: 10),
                  AppSkeleton(width: 280, height: 14),
                  SizedBox(height: 10),
                  AppSkeleton(width: double.infinity, height: 44),
                ],
              ),
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('6. Admin Data Table Example'),
            const SizedBox(height: 12),
            AppDataTable<Map<String, String>>(
              title: 'Recent Audit Logs',
              columnHeaders: const ['Timestamp', 'User', 'Action', 'Status'],
              columnWidths: const [140, 100, 180, 120],
              items: const [
                {'time': '20:34:10', 'user': 'admin', 'action': 'Login Successful', 'status': 'success'},
                {'time': '20:32:05', 'user': 'cashier1', 'action': 'Transaction Created #1042', 'status': 'success'},
                {'time': '20:28:19', 'user': 'cashier2', 'action': 'Failed Login (Attempt 1)', 'status': 'error'},
              ],
              rowBuilder: (item, index) {
                return [
                  Text(
                    item['time']!,
                    style: const TextStyle(
                      fontFeatures: [FontFeature.tabularFigures()],
                      fontSize: 13,
                      color: AppColors.mutedBrown,
                    ),
                  ),
                  Text(
                    item['user']!,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Text(item['action']!, style: const TextStyle(fontSize: 13)),
                  AppStatusChip(
                    label: item['status'] == 'success' ? 'Recorded' : 'Warning',
                    type: item['status'] == 'success' ? AppStatusType.success : AppStatusType.error,
                    isCompact: true,
                  ),
                ];
              },
            ),

            const SizedBox(height: 32),
            _buildSectionHeader('7. Destructive Confirm Dialog Test'),
            const SizedBox(height: 12),
            AppPrimaryButton(
              text: 'Open Destructive Confirm Modal',
              icon: Icons.open_in_new,
              onPressed: () => _openConfirmDialog(context),
            ),

            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  void _openConfirmDialog(BuildContext context) {
    AppConfirmDialog.show(
      context,
      title: 'Void Transaction #1042',
      consequenceText:
          'This action will permanently mark transaction #1042 as Voided in the database and audit log. Cashier daily total will be adjusted immediately.',
      confirmText: 'Void Transaction',
      cancelText: 'Keep Transaction',
      isDestructive: true,
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.darkCharcoal,
      ),
    );
  }
}
