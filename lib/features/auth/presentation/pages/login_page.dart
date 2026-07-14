import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';
import '../../../admin/presentation/pages/admin_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _selectedRole = 'Admin';

  void _handleLogin() {
    if (_selectedRole == 'Admin') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => AdminShell()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => CashierShell()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = Responsive.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final showBranding = !isMobile && screenWidth > 900;

    return Scaffold(
      backgroundColor: cs.surfaceContainerLowest,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (showBranding)
                  Padding(
                    padding: const EdgeInsets.only(right: 80),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: cs.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(28),
                          ),
                          child: Center(
                            child: Text('NY',
                              style: TextStyle(
                                color: cs.primary,
                                fontSize: 56, fontWeight: FontWeight.w900,
                                letterSpacing: 2,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text('N.Y Kitchen',
                          style: Theme.of(context).textTheme.headlineLarge!.copyWith(
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: 240,
                          child: Text(
                            'Secure Order & Sales Management System',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15, height: 1.5,
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                Card(
                  elevation: 0,
                  color: cs.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Container(
                    width: isMobile ? double.infinity : 420,
                    padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isMobile || screenWidth <= 900) ...[
                          Container(
                            width: 72, height: 72,
                            decoration: BoxDecoration(
                              color: cs.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: Center(
                              child: Text('NY',
                                style: TextStyle(
                                  color: cs.primary,
                                  fontSize: 32, fontWeight: FontWeight.w900,
                                  letterSpacing: 2,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text('N.Y Kitchen',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 4),
                        ],
                        Text('Welcome Back',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 8),
                        Text('Sign in to continue',
                          style: TextStyle(color: cs.onSurfaceVariant),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          decoration: BoxDecoration(
                            color: cs.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedRole,
                              isExpanded: true,
                              icon: Icon(Icons.arrow_drop_down, color: cs.onSurfaceVariant),
                              items: [
                                DropdownMenuItem(
                                  value: 'Admin',
                                  child: Row(
                                    children: [
                                      Icon(Icons.admin_panel_settings, size: 20, color: cs.primary),
                                      const SizedBox(width: 12),
                                      const Text('Login as Admin'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Cashier',
                                  child: Row(
                                    children: [
                                      Icon(Icons.receipt_long, size: 20, color: cs.primary),
                                      const SizedBox(width: 12),
                                      const Text('Login as Cashier'),
                                    ],
                                  ),
                                ),
                              ],
                              onChanged: (val) => setState(() => _selectedRole = val!),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        TextField(
                          decoration: InputDecoration(
                            labelText: 'Username',
                            hintText: 'Enter your username',
                            prefixIcon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Enter your password',
                            prefixIcon: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: cs.onSurfaceVariant,
                              ),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  height: 24, width: 24,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    onChanged: (val) => setState(() => _rememberMe = val!),
                                    activeColor: cs.primary,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text('Remember Me', style: TextStyle(color: cs.onSurface)),
                              ],
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text('Forgot Password?',
                                style: TextStyle(color: cs.error, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: _handleLogin,
                            child: const Text('LOGIN',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        Text('v1.0.0',
                          style: TextStyle(color: cs.onSurfaceVariant, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text('\u00a9 2026 N.Y Kitchen. All rights reserved.',
                          style: TextStyle(color: cs.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
