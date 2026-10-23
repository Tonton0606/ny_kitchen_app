import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../admin/presentation/pages/admin_shell.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';
import '../../../shared/widgets/ny_watermark.dart';
import '../widgets/force_change_password_dialog.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _isLoading = false;
  String? _emailError;
  String? _passwordError;

  int _failedAttempts = 0;
  bool _isLockedOut = false;
  Timer? _lockoutTimer;
  int _lockoutSeconds = 0;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _showForgotPasswordDialog() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
              child: const Icon(LucideIcons.key_round, color: AppColors.brandRed, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Password Reset Required',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkCharcoal,
                ),
              ),
            ),
          ],
        ),
        content: const Text(
          'Please contact your Store Administrator to reset your password and unlock your account.',
          style: TextStyle(fontSize: 14, color: AppColors.mutedBrown, height: 1.5),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.darkCharcoal,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
              ),
            ),
            child: const Text('OK', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin() async {
    final username = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = username.isEmpty
        ? 'Please enter your email or username'
        : null;
    final passwordError = password.isEmpty
        ? 'Please enter your password'
        : null;

    if (emailError != null || passwordError != null) {
      setState(() {
        _emailError = emailError;
        _passwordError = passwordError;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _emailError = null;
      _passwordError = null;
    });

    final repo = UserRepository();
    final user = await repo.login(username, password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user != null) {
      _failedAttempts = 0;
      final int mustChange = (user['must_change_password'] as int?) ?? 0;
      if (mustChange == 1) {
        _showForceChangePassword(user);
      } else {
        _proceedToShell(user);
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        setState(() {
          _isLockedOut = true;
          _lockoutSeconds = 30;
          _emailError = null;
          _passwordError = null;
        });
        _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (!mounted) {
            timer.cancel();
            return;
          }
          setState(() {
            _lockoutSeconds--;
            if (_lockoutSeconds <= 0) {
              _isLockedOut = false;
              _failedAttempts = 0;
              timer.cancel();
            }
          });
        });
      } else {
        setState(() {
          _emailError = 'Invalid username or password';
          _passwordError = 'Invalid username or password';
        });
      }
    }
  }

  void _proceedToShell(Map<String, dynamic> user) {
    SessionManager().setSession(user);
    final role = user['role'] as String;
    final destination = role == 'admin' ? const AdminShell() : const CashierShell();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute<void>(builder: (_) => destination),
    );
  }

  void _showForceChangePassword(Map<String, dynamic> user) {
    final mutableUser = Map<String, dynamic>.from(user);
    // Establish authenticated session so repository security guards permit self-service password update
    SessionManager().setSession(mutableUser);

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ForceChangePasswordDialog(
        user: mutableUser,
        onSuccess: () {
          mutableUser['must_change_password'] = 0;
          SessionManager().setSession(mutableUser);
          Navigator.of(dialogCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully. Welcome!'),
              backgroundColor: AppColors.success,
            ),
          );
          _proceedToShell(mutableUser);
        },
        onCancel: () {
          Navigator.of(dialogCtx).pop();
          SessionManager().clearSession();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth >= 960;

              if (isDesktop) {
                return _buildDesktopLayout(constraints);
              }

              return Center(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: constraints.maxWidth < 600 ? 16.0 : 28.0,
                    vertical: 24.0,
                  ),
                  child: _buildMobileOrTabletEnclosure(constraints.maxWidth),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Full-screen responsive split layout for desktop (edge-to-edge)
  Widget _buildDesktopLayout(BoxConstraints constraints) {
    return SizedBox(
      width: constraints.maxWidth,
      height: constraints.maxHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left full-bleed brand yellow showcase
          const Expanded(
            flex: 11,
            child: _PromotionalPanel(),
          ),
          // Right full-bleed white form container
          Expanded(
            flex: 10,
            child: Container(
              color: AppColors.surfaceWhite,
              alignment: Alignment.center,
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _buildLoginForm(showLogo: false),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Tablet & Mobile layout (< 1200px): Adaptive centered card on warm cream background
  Widget _buildMobileOrTabletEnclosure(double width) {
    return Container(
      constraints: BoxConstraints(
        maxWidth: width < 600 ? double.infinity : 440,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.softBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: _buildLoginForm(showLogo: true),
    );
  }

  Widget _buildLoginForm({required bool showLogo}) {
    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            Center(child: _OfficialLogo(width: 170)),
            const SizedBox(height: 28),
          ],
          const Text(
            'Welcome back',
            style: TextStyle(
              color: AppColors.darkCharcoal,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Sign in to your account to continue',
            style: TextStyle(
              color: AppColors.mutedBrown,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 32),

          // Clean Email / Username field (no redundant outer label)
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            enabled: !_isLoading && !_isLockedOut,
            keyboardType: TextInputType.emailAddress,
            inputFormatters: [
              LengthLimitingTextInputFormatter(100),
            ],
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            onChanged: (_) {
              if (_emailError != null && !_isLockedOut) setState(() => _emailError = null);
            },
            style: const TextStyle(
              color: AppColors.darkCharcoal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: _cleanInputDecoration(
              label: 'Email or username',
              icon: LucideIcons.user,
              errorText: _emailError,
            ),
          ),
          const SizedBox(height: 18),

          // Clean Password field (no redundant outer label)
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            enabled: !_isLoading && !_isLockedOut,
            obscureText: _obscurePassword,
            inputFormatters: [
              LengthLimitingTextInputFormatter(64),
            ],
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading && !_isLockedOut) _handleLogin();
            },
            onChanged: (_) {
              if (_passwordError != null && !_isLockedOut) setState(() => _passwordError = null);
            },
            style: const TextStyle(
              color: AppColors.darkCharcoal,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            decoration: _cleanInputDecoration(
              label: 'Password',
              icon: LucideIcons.lock,
              errorText: _passwordError,
              suffix: IconButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() => _obscurePassword = !_obscurePassword),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: AppColors.mutedBrown,
                  size: 20,
                ),
              ),
            ),
          ),

          if (_isLockedOut) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.brandRed.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDesignTokens.radius8),
                border: Border.all(color: AppColors.brandRed.withValues(alpha: 0.3), width: 1),
              ),
              child: Row(
                children: [
                  const Icon(LucideIcons.clock, color: AppColors.brandRed, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Too many failed attempts. Try again in ${_lockoutSeconds}s.',
                      style: const TextStyle(
                        color: AppColors.brandRed,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 18),

          // Remember Me & Forgot Password Row
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 6,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: Checkbox(
                      value: _rememberMe,
                      activeColor: AppColors.goldenYellow,
                      checkColor: AppColors.darkCharcoal,
                      side: const BorderSide(color: AppColors.mutedBrown, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: _isLoading ? null : (v) => setState(() => _rememberMe = v ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _isLoading ? null : () => setState(() => _rememberMe = !_rememberMe),
                    child: const Text(
                      'Remember Me',
                      style: TextStyle(
                        color: AppColors.darkCharcoal,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: _isLoading ? null : _showForgotPasswordDialog,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  foregroundColor: AppColors.brandRed,
                ),
                child: const Text(
                  'Forgot Password?',
                  style: TextStyle(
                    color: AppColors.brandRed,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 26),

          // Primary Brand CTA Button (Golden Yellow)
          SizedBox(
            height: 48,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10.0),
                boxShadow: (!_isLoading && !_isLockedOut)
                    ? const [
                        BoxShadow(
                          color: AppColors.goldTactileEdge,
                          offset: Offset(0, 2),
                          blurRadius: 0,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: ElevatedButton(
                onPressed: (_isLoading || _isLockedOut) ? null : _handleLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldenYellow,
                  foregroundColor: AppColors.darkCharcoal,
                  disabledBackgroundColor: AppColors.disabled,
                  disabledForegroundColor: AppColors.darkCharcoal.withValues(alpha: 0.4),
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: _isLoading
                      ? const SizedBox.square(
                          key: ValueKey('loading'),
                          dimension: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: AppColors.darkCharcoal,
                            semanticsLabel: 'Signing in',
                          ),
                        )
                      : const Text(
                          'Login',
                          key: ValueKey('ready'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // Footer info
          const Text(
            '© 2026 N.Y Kitchen. All rights reserved.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.mutedBrown,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _cleanInputDecoration({
    required String label,
    required IconData icon,
    required String? errorText,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12.0),
      borderSide: const BorderSide(color: AppColors.softBorder, width: 1.2),
    );

    return InputDecoration(
      labelText: label,
      errorText: errorText,
      prefixIcon: Icon(icon, color: AppColors.mutedBrown.withValues(alpha: 0.7), size: 18),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceWhite,
      labelStyle: const TextStyle(
        color: AppColors.mutedBrown,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      floatingLabelStyle: const TextStyle(
        color: AppColors.goldInk,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.goldenYellow, width: 2),
      ),
      errorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.brandRed, width: 1.5),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.brandRed, width: 2),
      ),
    );
  }
}

class _OfficialLogo extends StatelessWidget {
  const _OfficialLogo({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.softBorder, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkCharcoal.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Image.asset(
          'assets/images/branding/ny_kitchen_logo.png',
          width: width,
          fit: BoxFit.contain,
          semanticLabel: 'N.Y Kitchen official logo',
        ),
      ),
    );
  }
}
/// Left side promotional and culinary showcase (desktop >= 960dp) in Brand Golden Yellow
class _PromotionalPanel extends StatelessWidget {
  const _PromotionalPanel();

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.goldenYellow,
      child: Stack(
        children: [
          const NyWatermark(),
          Column(
            children: [
              const _PastilHero(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final minHeight = (constraints.maxHeight - 56).clamp(
                      0.0,
                      double.infinity,
                    );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.only(
                        left: 56,
                        right: 56,
                        top: 24,
                        bottom: 24,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(minHeight: minHeight),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/images/branding/ny_kitchen_emblem.png',
                                  height: 40,
                                  fit: BoxFit.contain,
                                  semanticLabel: 'N.Y Kitchen emblem',
                                ),
                                const SizedBox(width: 12),
                                const Text(
                                  'N.Y KITCHEN',
                                  style: TextStyle(
                                    color: AppColors.darkCharcoal,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 32),
                            const Text(
                              'One counter.\nEvery order, tracked.',
                              style: TextStyle(
                                color: AppColors.darkCharcoal,
                                fontSize: 38,
                                fontWeight: FontWeight.w800,
                                height: 1.15,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 14),
                            ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 520),
                              child: Text(
                                'A clear, reliable workspace for taking orders and keeping every transaction organized.',
                                style: TextStyle(
                                  color: AppColors.darkCharcoal.withValues(alpha: 0.78),
                                  fontSize: 14,
                                  height: 1.5,
                                ),
                              ),
                            ),
                            const SizedBox(height: 28),
                            const FractionallySizedBox(
                              widthFactor: 0.88,
                              alignment: Alignment.centerLeft,
                              child: _OrderCard(),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const _PastilHero(isReversed: true),
            ],
          ),
        ],
      ),
    );
  }
}

class _PastilHero extends StatefulWidget {
  const _PastilHero({this.isReversed = false});

  final bool isReversed;

  @override
  State<_PastilHero> createState() => _PastilHeroState();
}

class _PastilHeroState extends State<_PastilHero>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _floatAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
    _floatAnimation = Tween<double>(
      begin: -8,
      end: 8,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _images = [
    'assets/images/branding/pastil_boiled_egg-removebg-preview.png',
    'assets/images/branding/pastil_chicken_franks-removebg-preview.png',
    'assets/images/branding/pastil_hashbrown-removebg-preview.png',
    'assets/images/branding/pastil_hungarian-removebg-preview.png',
    'assets/images/branding/pastil_korean_spam-removebg-preview.png',
    'assets/images/branding/pastil_lumpiang_shanghai-removebg-preview.png',
  ];

  @override
  Widget build(BuildContext context) {
    final displayImages = widget.isReversed ? _images.reversed.toList() : _images;

    return Container(
      height: 140,
      alignment: Alignment.center,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Center(
              child: Transform.rotate(
                angle: -0.15,
                child: Opacity(
                  opacity: 0.04,
                  child: const Text(
                    'NY',
                    style: TextStyle(
                      color: AppColors.darkCharcoal,
                      fontSize: 140,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 8,
                    ),
                  ),
                ),
              ),
            ),
          ),
          AnimatedBuilder(
            animation: _floatAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(_floatAnimation.value, 0),
                child: child,
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (int i = 0; i < displayImages.length; i++)
                  Transform.translate(
                    offset: Offset(i < displayImages.length - 1 ? -36.0 : 0, 0),
                    child: Image.asset(
                      displayImages[i],
                      height: 105 + (i.isEven ? 20 : 0),
                      fit: BoxFit.contain,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// White live order preview card on brand golden surface
class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: AppColors.softBorder.withValues(alpha: 0.8),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Order No.',
                      style: TextStyle(
                        color: AppColors.mutedBrown,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '#00482',
                      style: TextStyle(
                        color: AppColors.darkCharcoal,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusBadge(),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: AppColors.softBorder),
          ),
          Row(
            children: const [
              Icon(LucideIcons.utensils, color: AppColors.darkCharcoal, size: 16),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sisig Rice',
                  style: TextStyle(
                    color: AppColors.darkCharcoal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Served',
                style: TextStyle(
                  color: AppColors.success,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(LucideIcons.circle_check, color: AppColors.success, size: 14),
          SizedBox(width: 5),
          Text(
            'Served',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
