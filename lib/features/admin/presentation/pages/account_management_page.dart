import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_design_tokens.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/utils/security_utils.dart';
import '../../../../core/session/session_manager.dart';

/// User & Account Management Page for Administrators.
/// Strictly follows N.Y Kitchen System UI Principles & Design System.
class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final _userRepo = UserRepository();
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'cashier', 'admin'
  String _statusFilter = 'all'; // 'all', 'active', 'locked_or_disabled'

  bool _showAddUser = false;
  bool _isLoading = true;
  bool _addPasswordVisible = false;
  bool _addConfirmPasswordVisible = false;
  List<Map<String, dynamic>> _users = [];

  final _addFullNameController = TextEditingController();
  final _addUsernameController = TextEditingController();
  final _addPasswordController = TextEditingController();
  final _addConfirmPasswordController = TextEditingController();
  final String _addRole = 'cashier';

  String _maskUsername(String username) {
    if (username.isEmpty) return '@—';
    if (username.length <= 3) {
      return '@${username[0]}***';
    }
    final prefix = username.substring(0, 2);
    final suffix = username.substring(username.length - 1);
    return '@$prefix•••$suffix';
  }

  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!_showAddUser) {
        _loadUsersSilent();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _addFullNameController.dispose();
    _addUsernameController.dispose();
    _addPasswordController.dispose();
    _addConfirmPasswordController.dispose();
    _horizontalScrollController.dispose();
    _verticalScrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUsersSilent() async {
    try {
      final users = await _userRepo.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
      });
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoading = true);
    try {
      final users = await _userRepo.getAllUsers();
      if (!mounted) return;
      setState(() {
        _users = users;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load accounts: $e')),
      );
    }
  }

  void _openAddUser() {
    _addFullNameController.clear();
    _addUsernameController.clear();
    _addPasswordController.clear();
    _addConfirmPasswordController.clear();
    _addPasswordVisible = false;
    _addConfirmPasswordVisible = false;
    setState(() => _showAddUser = true);
  }

  void _closeAddUser() => setState(() => _showAddUser = false);

  Future<void> _saveNewUser() async {
    final fullName = _addFullNameController.text.trim();
    final username = _addUsernameController.text.trim();
    final password = _addPasswordController.text;
    final confirmPassword = _addConfirmPasswordController.text;

    if (fullName.isEmpty || username.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (fullName.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Full name must be at least 2 characters long')),
      );
      return;
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    if (!usernameRegex.hasMatch(username)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username must be 3–20 characters (letters, numbers, underscore only)')),
      );
      return;
    }

    final isDuplicate = _users.any((u) =>
        (u['username'] as String? ?? '').toLowerCase() == username.toLowerCase());
    if (isDuplicate) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Username "@$username" is already in use')),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }

    final policyError = SecurityUtils.validatePassword(password);
    if (policyError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(policyError)),
      );
      return;
    }

    try {
      await _userRepo.createUser({
        'full_name': fullName,
        'username': username,
        'password_hash': SecurityUtils.hashPassword(password),
        'role': _addRole,
        'status': 'active',
        'must_change_password': 1,
      });
      if (!mounted) return;
      _closeAddUser();
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      final errorMsg = e.toString().contains('UNIQUE')
          ? 'Username "@$username" is already taken'
          : 'Failed to create account. Please verify input fields.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMsg)),
      );
    }
  }

  void _showEditUserDialog(BuildContext context, Map<String, dynamic> user) {
    final editFullNameController = TextEditingController(text: user['full_name']);
    final editUsernameController = TextEditingController(text: user['username']);
    String editRole = user['role'] ?? 'cashier';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.goldenYellow.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.pencil,
                  color: AppColors.darkCharcoal,
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Edit ${user['full_name']}',
                  style: AppTypography.dialogTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Full Name', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: editFullNameController,
                    inputFormatters: [
                      LengthLimitingTextInputFormatter(50),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter full name',
                      prefixIcon: const Icon(LucideIcons.user, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Username', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  TextField(
                    controller: editUsernameController,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                      LengthLimitingTextInputFormatter(25),
                    ],
                    decoration: InputDecoration(
                      hintText: 'Enter username',
                      prefixIcon: const Icon(LucideIcons.at_sign, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Role', style: AppTypography.cardTitle),
                  const SizedBox(height: 6),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          editRole == 'admin' ? LucideIcons.shield_check : LucideIcons.shopping_bag,
                          size: 18,
                          color: AppColors.mutedText,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          editRole == 'admin'
                              ? 'Administrator (Primary Account)'
                              : 'Cashier (POS Operations)',
                          style: AppTypography.body,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    editRole == 'admin'
                        ? 'System Administrator privileges are reserved for system management.'
                        : 'Cashier role is fixed to prevent unauthorized administrative privilege escalation.',
                    style: AppTypography.caption.copyWith(color: AppColors.mutedText, fontSize: 11),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedText,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newName = editFullNameController.text.trim();
                final newUsername = editUsernameController.text.trim();
                if (newName.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a full name')),
                  );
                  return;
                }
                if (newName.length < 2) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Full name must be at least 2 characters long')),
                  );
                  return;
                }
                final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
                if (!usernameRegex.hasMatch(newUsername)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Username must be 3–20 characters (letters, numbers, underscore only)')),
                  );
                  return;
                }
                final isDuplicate = _users.any((u) =>
                    u['id'] != user['id'] &&
                    (u['username'] as String? ?? '').toLowerCase() == newUsername.toLowerCase());
                if (isDuplicate) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Username "@$newUsername" is already taken')),
                  );
                  return;
                }
                try {
                  await _userRepo.updateUser(user['id'], {
                    'full_name': newName,
                    'username': newUsername,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account updated successfully')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  final errorMsg = e.toString().contains('UNIQUE')
                      ? 'Username "@$newUsername" is already in use'
                      : 'Failed to update account. Please check inputs.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(errorMsg)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldenYellow,
                foregroundColor: AppColors.darkCharcoal,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Map<String, dynamic> user) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool obscurePassword = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogContext, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0xFFE2E8F0)),
          ),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  LucideIcons.key_round,
                  color: Color(0xFF2563EB),
                  size: 20,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Reset Password',
                  style: AppTypography.dialogTitle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter a new temporary password for ${user['full_name']} (@${user['username']}):',
                  style: AppTypography.cardSubtitle,
                ),
                const SizedBox(height: 16),
                const Text('New Temporary Password', style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(64),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Enter new password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(obscurePassword ? LucideIcons.eye_off : LucideIcons.eye, size: 18),
                      onPressed: () => setDialogState(() => obscurePassword = !obscurePassword),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 14),
                const Text('Confirm Password', style: AppTypography.cardTitle),
                const SizedBox(height: 6),
                TextField(
                  controller: confirmPasswordController,
                  obscureText: obscureConfirm,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(64),
                  ],
                  decoration: InputDecoration(
                    hintText: 'Re-enter new password',
                    prefixIcon: const Icon(LucideIcons.lock, size: 18),
                    suffixIcon: IconButton(
                      icon: Icon(obscureConfirm ? LucideIcons.eye_off : LucideIcons.eye, size: 18),
                      onPressed: () => setDialogState(() => obscureConfirm = !obscureConfirm),
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                    ),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  SecurityUtils.passwordPolicyMessage,
                  style: AppTypography.caption.copyWith(color: AppColors.mutedText, fontSize: 11),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.mutedText,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ElevatedButton(
              onPressed: () async {
                final newPass = passwordController.text;
                final confirmPass = confirmPasswordController.text;
                if (newPass.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please enter a new password')),
                  );
                  return;
                }
                if (newPass != confirmPass) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Passwords do not match')),
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
                try {
                  await _userRepo.updateUser(user['id'], {
                    'password_hash': SecurityUtils.hashPassword(newPass),
                    'must_change_password': 1,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Temporary password set. User must rotate on next login.')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to reset password. Please check policy requirements.')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldenYellow,
                foregroundColor: AppColors.darkCharcoal,
                elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    ),
  );
}

  void _showDisableDialog(BuildContext context, Map<String, dynamic> user) {
    final isActive = user['status'] == 'active';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandRed.withValues(alpha: 0.12)
                    : const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? LucideIcons.ban : LucideIcons.circle_check,
                color: isActive ? AppColors.brandRed : const Color(0xFF16A34A),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              '${isActive ? 'Disable' : 'Enable'} Account',
              style: AppTypography.dialogTitle,
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to ${isActive ? 'disable' : 'enable'} ${user['full_name']}\'s account? ${isActive ? 'This user will not be able to log in to the POS or back office until re-enabled.' : 'This will restore login and active permissions.'}',
          style: AppTypography.cardSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (isActive) {
                  await _userRepo.disableUser(user['id']);
                } else {
                  await _userRepo.updateUser(user['id'], {'status': 'active'});
                }
                if (!context.mounted) return;
                Navigator.pop(ctx);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Account ${isActive ? 'disabled' : 'enabled'} successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                final errorMsg = e.toString().contains('SELF_DISABLE_PROHIBITED')
                    ? 'Self-lockout prohibited: Administrators cannot disable their own active account.'
                    : 'Error updating account status. Please try again.';
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(errorMsg)),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive ? AppColors.brandRed : const Color(0xFF16A34A),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              isActive ? 'Disable Account' : 'Enable Account',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showUnlockDialog(BuildContext context, Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 20, 20),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF3C7),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.lock_open,
                color: Color(0xFFD97706),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Text(
              'Unlock Account',
              style: AppTypography.dialogTitle,
            ),
          ],
        ),
        content: Text(
          'Unlock ${user['full_name']}\'s account and reset failed login attempts? This allows the user to log in again immediately.',
          style: AppTypography.cardSubtitle,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.mutedText,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final adminName = SessionManager().fullName ?? 'Admin';
                await _userRepo.unlockUser(user['id'], adminName);
                if (!context.mounted) return;
                Navigator.pop(ctx);
                _loadUsers();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Account unlocked successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Failed to unlock account. Please try again.')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: AppColors.darkCharcoal,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Unlock Account', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  List<Map<String, dynamic>> get _filteredUsers {
    return _users.where((u) {
      // Search Query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final nameMatches = (u['full_name'] as String? ?? '').toLowerCase().contains(query);
        final userMatches = (u['username'] as String? ?? '').toLowerCase().contains(query);
        if (!nameMatches && !userMatches) return false;
      }

      // Role filter
      if (_roleFilter != 'all') {
        if (u['role'] != _roleFilter) return false;
      }

      // Status filter
      if (_statusFilter == 'active') {
        if (u['status'] != 'active') return false;
      } else if (_statusFilter == 'locked_or_disabled') {
        if (u['status'] == 'active') return false;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.canvasBackground,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.goldenYellow),
        ),
      );
    }

    final filtered = _filteredUsers;

    // Aggregate statistics
    final totalUsers = _users.length;
    final totalCashiers = _users.where((u) => u['role'] == 'cashier').length;
    final totalAdmins = _users.where((u) => u['role'] == 'admin').length;

    return Scaffold(
      backgroundColor: AppColors.canvasBackground,
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top 3 Metric KPI Cards
                _buildMetricsStrip(
                  total: totalUsers,
                  cashiers: totalCashiers,
                  admins: totalAdmins,
                ),
                const SizedBox(height: 20),

                // Search & Filter Segmented Pills
                _buildFilterBar(),
                const SizedBox(height: 16),

                // Main Data Table Card
                Expanded(
                  child: _buildAccountsTable(filtered),
                ),
              ],
            ),
          ),

          // Slide-Over Add User Drawer
          if (_showAddUser) _buildAddUserDrawer(),
        ],
      ),
    );
  }


  Widget _buildMetricsStrip({
    required int total,
    required int cashiers,
    required int admins,
  }) {
    return LayoutBuilder(builder: (context, constraints) {
      final isCompact = constraints.maxWidth < 800;
      if (isCompact) {
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            _buildMetricCard('TOTAL ACCOUNTS', '$total', LucideIcons.users, width: (constraints.maxWidth - 12) / 2),
            _buildMetricCard('CASHIERS', '$cashiers', LucideIcons.shopping_bag, width: (constraints.maxWidth - 12) / 2),
            _buildMetricCard('ADMINISTRATORS', '$admins', LucideIcons.shield_check, width: (constraints.maxWidth - 12) / 2),
          ],
        );
      }

      return Row(
        children: [
          Expanded(child: _buildMetricCard('TOTAL ACCOUNTS', '$total', LucideIcons.users)),
          const SizedBox(width: 14),
          Expanded(child: _buildMetricCard('CASHIERS', '$cashiers', LucideIcons.shopping_bag)),
          const SizedBox(width: 14),
          Expanded(child: _buildMetricCard('ADMINISTRATORS', '$admins', LucideIcons.shield_check)),
        ],
      );
    });
  }

  Widget _buildMetricCard(String label, String value, IconData icon, {double? width}) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.darkCharcoal, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: AppTypography.overline),
                const SizedBox(height: 4),
                Text(value, style: AppTypography.heroMetric),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    return LayoutBuilder(builder: (context, constraints) {
      final isNarrow = constraints.maxWidth < 920;
      final addAccountButton = ElevatedButton.icon(
        onPressed: _openAddUser,
        icon: const Icon(LucideIcons.user_plus, size: 18),
        label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.goldenYellow,
          foregroundColor: AppColors.darkCharcoal,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );

      if (isNarrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextField(
                inputFormatters: [
                  LengthLimitingTextInputFormatter(50),
                ],
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search by name or username...',
                  hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                  prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.mutedText),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  filled: true,
                  fillColor: Colors.white,
                ),
              ),
            ),
            const SizedBox(height: 10),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildSegmentedFilterContainer(
                    children: [
                      _buildPill('All Roles', isSelected: _roleFilter == 'all', onTap: () => setState(() => _roleFilter = 'all')),
                      _buildPill('Cashiers', isSelected: _roleFilter == 'cashier', onTap: () => setState(() => _roleFilter = 'cashier')),
                      _buildPill('Admins', isSelected: _roleFilter == 'admin', onTap: () => setState(() => _roleFilter = 'admin')),
                    ],
                  ),
                  const SizedBox(width: 10),
                  _buildSegmentedFilterContainer(
                    children: [
                      _buildPill('All Status', isSelected: _statusFilter == 'all', onTap: () => setState(() => _statusFilter = 'all')),
                      _buildPill('Active', isSelected: _statusFilter == 'active', onTap: () => setState(() => _statusFilter = 'active')),
                      _buildPill('Locked / Disabled', isSelected: _statusFilter == 'locked_or_disabled', onTap: () => setState(() => _statusFilter = 'locked_or_disabled')),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: addAccountButton,
            ),
          ],
        );
      }

      return Row(
        children: [
          SizedBox(
            width: 300,
            height: 44,
            child: TextField(
              inputFormatters: [
                LengthLimitingTextInputFormatter(50),
              ],
              onChanged: (val) => setState(() => _searchQuery = val),
              decoration: InputDecoration(
                hintText: 'Search by name or username...',
                hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 13),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.mutedText),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 14),
          _buildSegmentedFilterContainer(
            children: [
              _buildPill('All Roles', isSelected: _roleFilter == 'all', onTap: () => setState(() => _roleFilter = 'all')),
              _buildPill('Cashiers', isSelected: _roleFilter == 'cashier', onTap: () => setState(() => _roleFilter = 'cashier')),
              _buildPill('Admins', isSelected: _roleFilter == 'admin', onTap: () => setState(() => _roleFilter = 'admin')),
            ],
          ),
          const SizedBox(width: 12),
          _buildSegmentedFilterContainer(
            children: [
              _buildPill('All Status', isSelected: _statusFilter == 'all', onTap: () => setState(() => _statusFilter = 'all')),
              _buildPill('Active', isSelected: _statusFilter == 'active', onTap: () => setState(() => _statusFilter = 'active')),
              _buildPill('Locked / Disabled', isSelected: _statusFilter == 'locked_or_disabled', onTap: () => setState(() => _statusFilter = 'locked_or_disabled')),
            ],
          ),
          const Spacer(),
          addAccountButton,
        ],
      );
    });
  }

  Widget _buildSegmentedFilterContainer({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: children,
      ),
    );
  }

  Widget _buildPill(String label, {required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldenYellow : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? AppColors.darkCharcoal : AppColors.mutedText,
          ),
        ),
      ),
    );
  }

  Widget _buildAccountsTable(List<Map<String, dynamic>> users) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: LayoutBuilder(builder: (context, constraints) {
        const minWidth = 860.0;
        final tableWidth = constraints.maxWidth < minWidth ? minWidth : constraints.maxWidth;

        return Scrollbar(
          controller: _horizontalScrollController,
          thumbVisibility: true,
          child: SingleChildScrollView(
            controller: _horizontalScrollController,
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              height: constraints.maxHeight,
              child: Column(
                children: [
                  // Table Column Headers
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(width: 48, child: Text('AVATAR', style: AppTypography.tableHeader)),
                        SizedBox(width: 16),
                        Expanded(flex: 3, child: Text('NAME', style: AppTypography.tableHeader)),
                        Expanded(flex: 2, child: Text('USERNAME', style: AppTypography.tableHeader)),
                        SizedBox(width: 110, child: Text('ROLE', style: AppTypography.tableHeader)),
                        SizedBox(width: 110, child: Text('STATUS', style: AppTypography.tableHeader)),
                        SizedBox(width: 140, child: Text('ACTIONS', style: AppTypography.tableHeader)),
                      ],
                    ),
                  ),

                  // Table Rows or Empty State
                  Expanded(
                    child: users.isEmpty
                        ? _buildEmptyState()
                        : Scrollbar(
                            controller: _verticalScrollController,
                            thumbVisibility: true,
                            child: ListView.separated(
                              controller: _verticalScrollController,
                              padding: EdgeInsets.zero,
                              itemCount: users.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: Color(0xFFE2E8F0)),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return _buildTableRow(user);
                              },
                            ),
                          ),
                  ),

                  // Footer summary
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: const BoxDecoration(
                      border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Text(
                          'Showing ${users.length} of ${_users.length} accounts',
                          style: AppTypography.cardSubtitle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.users, size: 36, color: AppColors.mutedText),
          ),
          const SizedBox(height: 14),
          const Text('No accounts found', style: AppTypography.sectionTitle),
          const SizedBox(height: 4),
          const Text('Try adjusting your search query or role/status filters', style: AppTypography.cardSubtitle),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _openAddUser,
            icon: const Icon(LucideIcons.user_plus, size: 16),
            label: const Text('Add Account', style: TextStyle(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldenYellow,
              foregroundColor: AppColors.darkCharcoal,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTableRow(Map<String, dynamic> user) {
    final fullName = user['full_name'] as String? ?? '';
    final username = user['username'] as String? ?? '';
    final role = (user['role'] as String? ?? 'cashier').toLowerCase();
    final status = (user['status'] as String? ?? 'active').toLowerCase();
    final isActive = status == 'active';
    final isLocked = status == 'locked';
    final isSelf = SessionManager().userId == user['id'];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          // Avatar
          SizedBox(
            width: 48,
            height: 48,
            child: CircleAvatar(
              radius: 24,
              backgroundColor: role == 'admin'
                  ? const Color(0xFFF1F5F9)
                  : AppColors.goldenYellow.withValues(alpha: 0.2),
              child: Text(
                fullName.isNotEmpty ? fullName[0].toUpperCase() : '?',
                style: TextStyle(
                  color: role == 'admin' ? AppColors.darkCharcoal : const Color(0xFFB45309),
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Name
          Expanded(
            flex: 3,
            child: Text(
              fullName,
              style: AppTypography.tableCellPrimary,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Username
          Expanded(
            flex: 2,
            child: Text(
              _maskUsername(username),
              style: AppTypography.tableCellSecondary,
              overflow: TextOverflow.ellipsis,
            ),
          ),

          // Role Badge
          SizedBox(
            width: 110,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: role == 'admin'
                      ? const Color(0xFFF1F5F9)
                      : AppColors.goldenYellow.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: role == 'admin' ? const Color(0xFFCBD5E1) : const Color(0xFFFDE68A),
                    width: 0.8,
                  ),
                ),
                child: Text(
                  role == 'admin' ? 'Admin' : 'Cashier',
                  style: TextStyle(
                    color: role == 'admin' ? AppColors.darkCharcoal : const Color(0xFF92400E),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),

          // Status Dot & Label
          SizedBox(
            width: 110,
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : (isLocked ? const Color(0xFFD97706) : AppColors.brandRed),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isActive ? 'Active' : (isLocked ? 'Locked' : 'Disabled'),
                  style: TextStyle(
                    color: isActive
                        ? const Color(0xFF16A34A)
                        : (isLocked ? const Color(0xFFD97706) : AppColors.brandRed),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          SizedBox(
            width: 180,
            child: Row(
              children: [
                _buildActionIconButton(
                  icon: LucideIcons.pencil,
                  tooltip: 'Edit Account',
                  color: AppColors.darkCharcoal,
                  onPressed: () => _showEditUserDialog(context, user),
                ),
                const SizedBox(width: 6),
                _buildActionIconButton(
                  icon: LucideIcons.key_round,
                  tooltip: 'Reset Password',
                  color: const Color(0xFF2563EB),
                  onPressed: () => _showResetPasswordDialog(context, user),
                ),
                const SizedBox(width: 6),
                if (isLocked)
                  _buildActionIconButton(
                    icon: LucideIcons.lock_open,
                    tooltip: 'Unlock Account',
                    color: const Color(0xFFD97706),
                    onPressed: () => _showUnlockDialog(context, user),
                  )
                else if (isSelf)
                  _buildActionIconButton(
                    icon: LucideIcons.shield_check,
                    tooltip: 'Current Active Admin Account',
                    color: AppColors.mutedText.withValues(alpha: 0.35),
                    onPressed: null,
                  )
                else
                  _buildActionIconButton(
                    icon: isActive ? LucideIcons.ban : LucideIcons.circle_check,
                    tooltip: isActive ? 'Disable Account' : 'Enable Account',
                    color: isActive ? AppColors.brandRed : const Color(0xFF16A34A),
                    onPressed: () => _showDisableDialog(context, user),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionIconButton({
    required IconData icon,
    required String tooltip,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: IconButton(
        icon: Icon(icon, size: 16),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildAddUserDrawer() {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        final panelWidth = constraints.maxWidth > 520 ? 460.0 : constraints.maxWidth;
        return Row(
          children: [
            Container(
              width: panelWidth,
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(right: BorderSide(color: Color(0xFFE2E8F0))),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 16,
                    offset: Offset(4, 0),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Drawer Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
                    decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.goldenYellow.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(LucideIcons.user_plus, color: AppColors.darkCharcoal, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Add User Account',
                          style: AppTypography.sectionTitle,
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(LucideIcons.x, size: 20),
                          color: AppColors.darkCharcoal,
                          onPressed: _closeAddUser,
                        ),
                      ],
                    ),
                  ),

                  // Drawer Form Fields
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: [
                        const Text('Full Name', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _addFullNameController,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(50),
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g. Maria Santos',
                            prefixIcon: const Icon(LucideIcons.user, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text('Username', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _addUsernameController,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9_]')),
                            LengthLimitingTextInputFormatter(25),
                          ],
                          decoration: InputDecoration(
                            hintText: 'e.g. msantos',
                            prefixIcon: const Icon(LucideIcons.at_sign, size: 18),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text('Temporary Password', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _addPasswordController,
                          obscureText: !_addPasswordVisible,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(64),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Enter initial password',
                            prefixIcon: const Icon(LucideIcons.lock, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _addPasswordVisible ? LucideIcons.eye_off : LucideIcons.eye,
                                size: 18,
                                color: AppColors.mutedText,
                              ),
                              onPressed: () => setState(() => _addPasswordVisible = !_addPasswordVisible),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text('Confirm Password', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _addConfirmPasswordController,
                          obscureText: !_addConfirmPasswordVisible,
                          inputFormatters: [
                            LengthLimitingTextInputFormatter(64),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Re-enter initial password',
                            prefixIcon: const Icon(LucideIcons.lock, size: 18),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _addConfirmPasswordVisible ? LucideIcons.eye_off : LucideIcons.eye,
                                size: 18,
                                color: AppColors.mutedText,
                              ),
                              onPressed: () => setState(() => _addConfirmPasswordVisible = !_addConfirmPasswordVisible),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 18),

                        const Text('Role Assignment', style: AppTypography.cardTitle),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: const Row(
                            children: [
                              Icon(LucideIcons.shopping_bag, size: 18, color: AppColors.mutedText),
                              SizedBox(width: 10),
                              Text('Cashier (Point of Sale Access)', style: AppTypography.body),
                            ],
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'New staff accounts are assigned Cashier role with POS operations access. Only the primary administrator holds Administrator privileges.',
                          style: AppTypography.cardSubtitle,
                        ),
                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _saveNewUser,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldenYellow,
                              foregroundColor: AppColors.darkCharcoal,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Save Account',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Backdrop
            Expanded(
              child: GestureDetector(
                onTap: _closeAddUser,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            ),
          ],
        );
      }),
    );
  }
}
