import 'package:flutter/material.dart';
import '../../../../core/utils/responsive.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';
import '../../../admin/presentation/pages/admin_shell.dart';
import '../../../shared/widgets/app_logo.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  bool _obscurePassword = true;
  bool _rememberMe = false;
  String _selectedRole = 'Admin';
  bool _isLoading = false;
  String? _errorMessage;
  String? _usernameError;
  String? _passwordError;

  late final TextEditingController _usernameController;
  late final TextEditingController _passwordController;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _fadeController.forward();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final username = _usernameController.text.trim();
    final password = _passwordController.text;

    String? usernameError;
    String? passwordError;

    if (username.isEmpty) {
      usernameError = 'Please enter your email or username';
    }
    if (password.isEmpty) {
      passwordError = 'Please enter your password';
    }

    if (usernameError != null || passwordError != null) {
      setState(() {
        _usernameError = usernameError;
        _passwordError = passwordError;
        _errorMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _usernameError = null;
      _passwordError = null;
    });

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isMobile = Responsive.isMobile(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth > 900;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        children: [
          if (isWide)
            Expanded(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: _BrandingPane(accentColor: cs.primary),
              ),
            ),
          SizedBox(
            width: isMobile ? double.infinity : (isWide ? 420 : double.infinity),
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!isWide) ...[
                        const Center(
                          child: AppLogo(size: 80, borderRadius: 20, fontSize: 36),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Text('N.Y Kitchen',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Center(
                          child: Text(
                            'Secure Order & Sales Management System',
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 420),
                        child: Container(
                          decoration: BoxDecoration(
                            color: cs.surface,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
                            boxShadow: [
                              BoxShadow(
                                blurRadius: 20,
                                offset: const Offset(0, 2),
                                color: Colors.black.withValues(alpha: 0.06),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text('Sign In',
                                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text('Enter your credentials to continue',
                                style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
                              ),
                              const SizedBox(height: 28),
                              DropdownButtonHideUnderline(
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
                                  onChanged: _isLoading ? null : (val) => setState(() => _selectedRole = val!),
                                ),
                              ),
                              const SizedBox(height: 20),
                              TextField(
                                controller: _usernameController,
                                onChanged: (_) {
                                  if (_usernameError != null) setState(() => _usernameError = null);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Username or email',
                                  hintText: 'your@email.com',
                                  prefixIcon: Icon(Icons.person_outline, color: cs.onSurfaceVariant),
                                  errorText: _usernameError,
                                  errorStyle: TextStyle(color: cs.error, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 16),
                              TextField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                onChanged: (_) {
                                  if (_passwordError != null) setState(() => _passwordError = null);
                                },
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  hintText: 'Enter your password',
                                  prefixIcon: Icon(Icons.lock_outline, color: cs.onSurfaceVariant),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                      color: cs.onSurfaceVariant,
                                    ),
                                    iconSize: 22,
                                    splashRadius: 22,
                                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                  ),
                                  errorText: _passwordError,
                                  errorStyle: TextStyle(color: cs.error, fontSize: 12),
                                ),
                              ),
                              const SizedBox(height: 12),
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
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
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
                                      style: TextStyle(color: cs.primary, fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              if (_errorMessage != null) ...[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  decoration: BoxDecoration(
                                    color: cs.errorContainer.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: cs.error.withValues(alpha: 0.2)),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: cs.error.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Icon(Icons.dangerous_outlined, size: 16, color: cs.error),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(color: cs.error, fontSize: 13, height: 1.4),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: AnimatedSwitcher(
                                    duration: const Duration(milliseconds: 200),
                                    child: _isLoading
                                        ? SizedBox(
                                            key: const ValueKey('loading'),
                                            width: 22, height: 22,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5,
                                              color: cs.onPrimary,
                                            ),
                                          )
                                        : const Text('Sign In',
                                            key: ValueKey('ready'),
                                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                          ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 32),
                              Center(
                                child: Text('v1.0.0',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Center(
                                child: Text('\u00a9 2026 N.Y Kitchen. All rights reserved.',
                                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                                  ),
                                ),
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
          ),
        ],
      ),
    );
  }
}

class _BrandingPane extends StatelessWidget {
  final Color accentColor;

  const _BrandingPane({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withValues(alpha: 0.9),
            accentColor.withValues(alpha: 0.7),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            top: -80, left: -80,
            child: Container(
              width: 400, height: 400,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -120, right: -60,
            child: Container(
              width: 350, height: 350,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(60),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Spacer(),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(28),
                    ),
                    child: const AppLogo(size: 120, borderRadius: 28, fontSize: 56),
                  ),
                  const SizedBox(height: 32),
                  const Text('N.Y Kitchen',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Secure Order & Sales Management System',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 40),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, color: Colors.white.withValues(alpha: 0.9), size: 18),
                        const SizedBox(width: 8),
                        Text(
                          'Trusted by hospitality professionals',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Text('\u00a9 2026 N.Y Kitchen',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
