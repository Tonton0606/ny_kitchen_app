import 'dart:async';
import 'package:flutter/material.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/utils/security_utils.dart';

class AccountManagementPage extends StatefulWidget {
  const AccountManagementPage({super.key});

  @override
  State<AccountManagementPage> createState() => _AccountManagementPageState();
}

class _AccountManagementPageState extends State<AccountManagementPage> {
  final _userRepo = UserRepository();
  String _searchQuery = '';
  bool _showAddCashier = false;
  bool _isLoading = true;
  List<Map<String, dynamic>> _users = [];

  final _addFullNameController = TextEditingController();
  final _addUsernameController = TextEditingController();
  final _addPasswordController = TextEditingController();
  String _addRole = 'cashier';

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _refreshTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      _loadUsersSilent();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _addFullNameController.dispose();
    _addUsernameController.dispose();
    _addPasswordController.dispose();
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
        SnackBar(content: Text('Failed to load users: $e')),
      );
    }
  }

  void _openAddCashier() {
    _addFullNameController.clear();
    _addUsernameController.clear();
    _addPasswordController.clear();
    _addRole = 'cashier';
    setState(() => _showAddCashier = true);
  }
  
  void _closeAddCashier() => setState(() => _showAddCashier = false);

  Future<void> _saveNewCashier() async {
    if (_addFullNameController.text.trim().isEmpty ||
        _addUsernameController.text.trim().isEmpty ||
        _addPasswordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await _userRepo.createUser({
        'full_name': _addFullNameController.text.trim(),
        'username': _addUsernameController.text.trim(),
        'password_hash': SecurityUtils.hashPassword(_addPasswordController.text.trim()),
        'role': _addRole,
        'status': 'active',
      });
      if (!mounted) return;
      _closeAddCashier();
      _loadUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Account created successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating account: $e')),
      );
    }
  }

  void _showEditCashierDialog(BuildContext context, Map<String, dynamic> user) {
    final editFullNameController = TextEditingController(text: user['full_name']);
    final editUsernameController = TextEditingController(text: user['username']);
    String editRole = user['role'];

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: AppColors.goldenYellow.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.edit_outlined,
                    color: AppColors.goldenYellow,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Edit ${user['full_name']}',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: SizedBox(
            width: 400,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Full Name',
                      prefixIcon: const Icon(Icons.person_outline),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    controller: editFullNameController,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    decoration: InputDecoration(
                      labelText: 'Username',
                      prefixIcon: const Icon(Icons.account_circle_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    controller: editUsernameController,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: 'Role',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    initialValue: editRole,
                    items: const [
                      DropdownMenuItem(value: 'admin', child: Text('Admin')),
                      DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                    ],
                    onChanged: (val) {
                      if (val != null) setStateDialog(() => editRole = val);
                    },
                  ),
                ],
              ),
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
                if (editFullNameController.text.trim().isEmpty || editUsernameController.text.trim().isEmpty) return;
                try {
                  await _userRepo.updateUser(user['id'], {
                    'full_name': editFullNameController.text.trim(),
                    'username': editUsernameController.text.trim(),
                    'role': editRole,
                  });
                  if (!context.mounted) return;
                  Navigator.pop(ctx);
                  _loadUsers();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account updated')),
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error updating account: $e')),
                  );
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
                'Update',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResetPasswordDialog(BuildContext context, Map<String, dynamic> user) {
    final passwordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: AppColors.tertiary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.lock_reset,
                  color: AppColors.tertiary,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Reset Password',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Reset password for ${user['full_name']}?',
            style: const TextStyle(
              fontSize: 15,
              color: AppColors.mutedText,
            ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                labelText: 'New Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              decoration: InputDecoration(
                labelText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
          ],
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
              if (passwordController.text.trim().isEmpty) return;
              if (passwordController.text != confirmPasswordController.text) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Passwords do not match')),
                );
                return;
              }
              try {
                await _userRepo.updateUser(user['id'], {
                  'password_hash': SecurityUtils.hashPassword(passwordController.text.trim()),
                });
                if (!context.mounted) return;
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Password reset successfully')),
                );
              } catch (e) {
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error resetting password: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.tertiary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text(
              'Reset Password',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showDisableDialog(BuildContext context, Map<String, dynamic> user) {
    final isActive = user['status'] == 'active';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
        actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.brandRed.withValues(alpha: 0.1)
                    : AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                isActive ? Icons.block : Icons.check_circle,
                color: isActive
                    ? AppColors.brandRed
                    : AppColors.success,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Text(
              '${isActive ? 'Disable' : 'Enable'} Account',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to ${isActive ? 'disable' : 'enable'} ${user['full_name']}\'s account?',
          style:  const TextStyle(
            fontSize: 15,
            color: AppColors.mutedText,
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error updating status: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isActive
                  ? AppColors.brandRed
                  : AppColors.success,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              isActive ? 'Disable' : 'Enable',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final filteredUsers = _users.where((u) {
      if (_searchQuery.isEmpty) return true;
      final query = _searchQuery.toLowerCase();
      return (u['full_name'] as String).toLowerCase().contains(query) ||
          (u['username'] as String).toLowerCase().contains(query);
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F5F0),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(builder: (context, topConstraints) {
                  final isMobileOrNarrow = topConstraints.maxWidth < 650;
                  if (isMobileOrNarrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Management',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Manage cashier accounts and permissions',
                              style: TextStyle(color: AppColors.mutedText, fontSize: 13),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _openAddCashier,
                            icon: const Icon(Icons.person_add, size: 18),
                            label: const Text('Add Cashier', style: TextStyle(fontWeight: FontWeight.bold)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldenYellow,
                              foregroundColor: Colors.black,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Management',
                            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Manage cashier accounts and permissions',
                            style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                          ),
                        ],
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _openAddCashier,
                        icon: const Icon(Icons.person_add, size: 18),
                        label: const Text('Add Cashier', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldenYellow,
                          foregroundColor: Colors.black,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  );
                }),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 340,
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: InputDecoration(
                          hintText: 'Search by name or username...',
                          hintStyle: const TextStyle(color: AppColors.mutedText, fontSize: 14),
                          prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.mutedText),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softBorder)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.softBorder)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: LayoutBuilder(builder: (context, bodyConstraints) {
                    final showSideCard = bodyConstraints.maxWidth >= 950;
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.softBorder)),
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: SizedBox(
                                width: showSideCard
                                    ? (bodyConstraints.maxWidth - 240).clamp(750.0, 1100.0)
                                    : bodyConstraints.maxWidth.clamp(750.0, 1200.0),
                                height: bodyConstraints.maxHeight,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFAF8F5),
                                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                                        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
                                      ),
                                      child: const Row(
                                        children: [
                                          SizedBox(width: 48, child: Text('Avatar', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                          SizedBox(width: 16),
                                          Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                          Expanded(flex: 2, child: Text('Username', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                          SizedBox(width: 90, child: Text('Role', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                          SizedBox(width: 90, child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                          SizedBox(width: 130, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.mutedText))),
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      child: filteredUsers.isEmpty
                                          ? const Center(child: Text('No users found.', style: TextStyle(color: AppColors.mutedText)))
                                          : ListView.separated(
                                              padding: EdgeInsets.zero,
                                              itemCount: filteredUsers.length,
                                              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.softBorder),
                                              itemBuilder: (context, index) {
                                                final user = filteredUsers[index];
                                                final isActive = user['status'] == 'active';
                                                final role = user['role'] == 'admin' ? 'Admin' : 'Cashier';
                                                return Padding(
                                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                                  child: Row(
                                                    children: [
                                                      SizedBox(
                                                        width: 48,
                                                        height: 48,
                                                        child: CircleAvatar(
                                                          radius: 24,
                                                          backgroundColor: AppColors.goldenYellow.withValues(alpha: 0.2),
                                                          child: Text(
                                                            (user['full_name'] as String).isNotEmpty
                                                                ? (user['full_name'] as String)[0].toUpperCase()
                                                                : '?',
                                                            style: const TextStyle(
                                                              color: AppColors.goldenYellow,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      const SizedBox(width: 16),
                                                      Expanded(
                                                        flex: 3,
                                                        child: Text(
                                                          user['full_name'],
                                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.darkCharcoal),
                                                        ),
                                                      ),
                                                      Expanded(
                                                        flex: 2,
                                                        child: Text(
                                                          user['username'],
                                                          style: const TextStyle(fontSize: 14),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 90,
                                                        child: Container(
                                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                                          decoration: BoxDecoration(
                                                            color: role == 'Admin'
                                                                ? AppColors.tertiary.withValues(alpha: 0.1)
                                                                : AppColors.goldenYellow.withValues(alpha: 0.1),
                                                            borderRadius: BorderRadius.circular(6),
                                                          ),
                                                          child: Text(
                                                            role,
                                                            textAlign: TextAlign.center,
                                                            style: TextStyle(
                                                              color: role == 'Admin' ? AppColors.tertiary : AppColors.goldenYellow,
                                                              fontSize: 12,
                                                              fontWeight: FontWeight.bold,
                                                            ),
                                                          ),
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 90,
                                                        child: Row(
                                                          children: [
                                                            Container(
                                                              width: 7,
                                                              height: 7,
                                                              decoration: BoxDecoration(
                                                                color: isActive ? AppColors.success : AppColors.brandRed,
                                                                shape: BoxShape.circle,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Text(
                                                              isActive ? 'Active' : 'Inactive',
                                                              style: TextStyle(
                                                                color: isActive ? AppColors.success : AppColors.brandRed,
                                                                fontWeight: FontWeight.w600,
                                                                fontSize: 12,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        width: 130,
                                                        child: Row(
                                                          children: [
                                                            _buildActionButton(
                                                              icon: Icons.edit_outlined,
                                                              color: AppColors.goldenYellow,
                                                              tooltip: 'Edit',
                                                              onPressed: () => _showEditCashierDialog(context, user),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            _buildActionButton(
                                                              icon: Icons.lock_reset,
                                                              color: AppColors.tertiary,
                                                              tooltip: 'Reset Password',
                                                              onPressed: () => _showResetPasswordDialog(context, user),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            _buildActionButton(
                                                              icon: isActive ? Icons.block : Icons.check_circle,
                                                              color: isActive ? AppColors.brandRed : AppColors.success,
                                                              tooltip: isActive ? 'Disable' : 'Enable',
                                                              onPressed: () => _showDisableDialog(context, user),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.softBorder))),
                                      child: Row(
                                        children: [
                                          Text('Showing ${filteredUsers.length} of ${_users.length} accounts',
                                              style: const TextStyle(color: AppColors.mutedText, fontSize: 13)),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (showSideCard) ...[
                          const SizedBox(width: 20),
                          SizedBox(
                            width: 190,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF8E7),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFFFE8A3)),
                              ),
                              padding: const EdgeInsets.all(20),
                              child: const Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text('👨‍💼', style: TextStyle(fontSize: 52)),
                                  SizedBox(height: 16),
                                  Text('Team Security,', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.darkCharcoal)),
                                  Text('Organized & Safe!', textAlign: TextAlign.center, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.goldenYellow, fontStyle: FontStyle.italic)),
                                  SizedBox(height: 10),
                                  Text('Manage permissions and keep your operations running smoothly.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.mutedText, height: 1.5)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  }),
                ),
              ],
            ),
          ),
          if (_showAddCashier) _buildAddCashierPanel(),
        ],
      ),
    );
  }

  Widget _buildAddCashierPanel() {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        final panelWidth = constraints.maxWidth > 550 ? 500.0 : constraints.maxWidth;
        return Row(
          children: [
            Container(
              width: panelWidth,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(right: BorderSide(color: AppColors.softBorder)),
              boxShadow: const [
                BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(4, 0)),
              ],
            ),
            child: Column(
              children: [
                _buildPanelHeader(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: [
                      Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.goldenYellow.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, size: 36, color: AppColors.mutedText),
                              SizedBox(height: 8),
                              Text('Cashier Avatar', style: TextStyle(color: AppColors.mutedText, fontSize: 13)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addFullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Enter full name',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addUsernameController,
                        decoration: const InputDecoration(
                          labelText: 'Username',
                          hintText: 'Enter username',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _addPasswordController,
                        decoration: const InputDecoration(
                          labelText: 'Password',
                          hintText: 'Enter temporary password',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        obscureText: true,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        initialValue: _addRole,
                        decoration: const InputDecoration(
                          labelText: 'Role',
                          border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'admin', child: Text('Admin')),
                          DropdownMenuItem(value: 'cashier', child: Text('Cashier')),
                        ],
                        onChanged: (val) {
                          if (val != null) setState(() => _addRole = val);
                        },
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _saveNewCashier,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.goldenYellow,
                            foregroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Save Cashier', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _closeAddCashier,
              child: Container(color: Colors.black38),
            ),
          ),
        ],
      );
    }),
  );
}

  Widget _buildPanelHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.softBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.goldenYellow.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.person_add, color: AppColors.goldenYellow, size: 20),
          ),
          const SizedBox(width: 12),
          const Text('Add Cashier', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.darkCharcoal)),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close),
            color: AppColors.darkCharcoal,
            onPressed: _closeAddCashier,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: IconButton(
        icon: Icon(icon, size: 20),
        color: color,
        tooltip: tooltip,
        onPressed: onPressed,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
      ),
    );
  }
}
