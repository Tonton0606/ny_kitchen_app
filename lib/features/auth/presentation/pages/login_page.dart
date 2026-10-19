import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_design_tokens.dart';
import '../../../../core/database/repositories/user_repository.dart';
import '../../../../core/session/session_manager.dart';
import '../../../admin/presentation/pages/admin_shell.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';
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
        backgroundColor: AppColors.surfaceWhite,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDesignTokens.radius12),
          side: const BorderSide(color: AppColors.softBorder, width: 1),
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
          _emailError = 'Invalid credentials or inactive account';
          _passwordError = 'Invalid credentials or inactive account';
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
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => ForceChangePasswordDialog(
        user: user,
        onSuccess: () {
          Navigator.of(dialogCtx).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password changed successfully. Welcome!'),
              backgroundColor: AppColors.success,
            ),
          );
          _proceedToShell(user);
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
    return Container(
      color: AppColors.goldenYellow,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final panelWidth = constraints.maxWidth;
          final panelHeight = constraints.maxHeight;
          final horizontalPadding = (panelWidth * 0.08).clamp(32.0, 72.0);
          final verticalPadding = (panelHeight * 0.05).clamp(24.0, 48.0);
          final headlineFontSize = (panelWidth * 0.038).clamp(28.0, 44.0);
          final foodClusterWidth = panelWidth - (horizontalPadding * 2);
          final foodClusterHeight = (panelHeight * 0.28).clamp(130.0, 220.0);

          return Padding(
            padding: EdgeInsets.symmetric(
              horizontal: horizontalPadding,
              vertical: verticalPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Clean brand header with mascot emblem
                Row(
                  children: [
                    Image.asset(
                      'assets/images/branding/ny_kitchen_emblem.png',
                      height: 46,
                      fit: BoxFit.contain,
                      semanticLabel: 'N.Y Kitchen emblem',
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'N.Y KITCHEN',
                          style: TextStyle(
                            color: AppColors.darkCharcoal,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Kagay-an Pastil & Food Bar',
                          style: TextStyle(
                            color: AppColors.darkCharcoal,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const Spacer(flex: 1),

                // Headline
                Text(
                  'One counter.\nEvery order, tracked.',
                  style: TextStyle(
                    color: AppColors.darkCharcoal,
                    fontSize: headlineFontSize,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 12),

                // Subtitle
                Text(
                  'A clear, reliable workspace for taking orders and keeping every transaction organized.',
                  style: TextStyle(
                    color: AppColors.darkCharcoal.withValues(alpha: 0.75),
                    fontSize: 14,
                    height: 1.45,
                  ),
                ),

                const SizedBox(height: 20),

                // Sleek live order card (stretches across full width between margins)
                const _OrderCard(),

                const Spacer(flex: 2),

                // Centerpiece appetizing vector drawing of rice with Kagay-an pastil (kagikit) on top
                _RiceWithPastilVector(
                  width: foodClusterWidth,
                  height: foodClusterHeight,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Artisanal vector drawing of freshly steamed rice with savory Kagay-an pastil (kagikit) on banana leaf
/// surrounded by classic pastil combo meals: crispy hashbrown, sliced embutido, scored red hotdog,
/// lumpiang shanghai, hard-boiled egg half, calamansi, and chili.
class _RiceWithPastilVector extends StatefulWidget {
  final double width;
  final double height;

  const _RiceWithPastilVector({
    this.width = 480,
    this.height = 190,
  });

  @override
  State<_RiceWithPastilVector> createState() => _RiceWithPastilVectorState();
}

class _RiceWithPastilVectorState extends State<_RiceWithPastilVector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Gentle, subtle floating bob (+/- 3.5px)
        final double floatOffset = math.sin(_controller.value * 2 * math.pi) * 3.5;
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: child,
        );
      },
      child: Center(
        child: SizedBox(
          width: widget.width,
          height: widget.height,
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: 480,
              height: 220,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return CustomPaint(
                    size: const Size(480, 220),
                    painter: _RiceWithPastilPainter(
                      animationValue: _controller.value,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RiceWithPastilPainter extends CustomPainter {
  final double animationValue;

  _RiceWithPastilPainter({required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    final double scale = size.width / 480.0;
    canvas.save();
    canvas.scale(scale, scale);

    // 1. Banana Leaf Base (Lush tropical platter for full feast)
    _drawBananaLeaf(canvas);

    // 2. Left Side Sides: Crispy Golden Hashbrown & Sliced Embutido
    _drawHashbrown(canvas, const Offset(76, 168));
    _drawEmbutidoSlices(canvas, const Offset(122, 166));

    // 3. Sliced Hard-Boiled Egg Half (tucked beside the rice)
    _drawEggHalf(canvas, const Offset(160, 174));

    // 4. Centerpiece: Mound of Steamed Jasmine Rice
    _drawRiceMound(canvas);

    // 5. Centerpiece: Kagay-an Pastil (Kagikit) on Top of the Rice
    _drawPastilKagikit(canvas);

    // 6. Right Side Sides: Filipino Red Hotdog with Score Cuts & Crispy Lumpia
    _drawRedHotdog(canvas, const Offset(326, 168));
    _drawLumpia(canvas, const Offset(380, 172));

    // 7. Fresh Garnishes: Calamansi Citrus Slice & Siling Labuyo (Red Chili)
    _drawCalamansi(canvas, const Offset(394, 190));
    _drawRedChili(canvas, const Offset(422, 194));

    // 8. Whimsical Steaming Aroma Wisps (Rising upward with animation)
    _drawSteamWisps(canvas, animationValue);

    canvas.restore();
  }

  void _drawBananaLeaf(Canvas canvas) {
    // Floor ambient shadow under full platter
    final shadowPaint = Paint()
      ..color = AppColors.darkCharcoal.withValues(alpha: 0.16)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawOval(
      const Rect.fromLTWH(30, 185, 420, 28),
      shadowPaint,
    );

    // Banana leaf wide tropical platter
    final leafPath = Path();
    leafPath.moveTo(25, 178);
    leafPath.cubicTo(60, 150, 150, 140, 240, 140);
    leafPath.cubicTo(330, 140, 420, 150, 455, 178);
    leafPath.cubicTo(435, 204, 340, 214, 240, 214);
    leafPath.cubicTo(140, 214, 45, 204, 25, 178);
    leafPath.close();

    final leafGradient = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Color(0xFF43A047), // Vibrant tropical leaf green
        Color(0xFF2E7D32), // Deep emerald green
        Color(0xFF1B5E20), // Rich forest green shadow
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(const Rect.fromLTWH(25, 140, 430, 74));

    canvas.drawPath(leafPath, Paint()..shader = leafGradient);

    // Midrib central spine
    final spinePaint = Paint()
      ..color = const Color(0xFF81C784).withValues(alpha: 0.45)
      ..strokeWidth = 2.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final spinePath = Path();
    spinePath.moveTo(27, 178);
    spinePath.quadraticBezierTo(240, 176, 453, 178);
    canvas.drawPath(spinePath, spinePaint);

    // Lateral vein lines across the entire leaf
    final veinPaint = Paint()
      ..color = const Color(0xFF1B5E20).withValues(alpha: 0.25)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final List<List<double>> veins = [
      [60, 177, 80, 152],
      [100, 176, 125, 146],
      [145, 176, 172, 142],
      [195, 176, 225, 141],
      [250, 176, 280, 141],
      [300, 176, 330, 143],
      [350, 176, 380, 148],
      [395, 177, 420, 154],
      // Bottom veins
      [70, 179, 52, 196],
      [115, 177, 98, 204],
      [165, 177, 150, 210],
      [215, 177, 205, 213],
      [265, 177, 275, 213],
      [315, 177, 330, 210],
      [365, 177, 385, 204],
      [410, 178, 430, 196],
    ];

    for (final v in veins) {
      canvas.drawLine(Offset(v[0], v[1]), Offset(v[2], v[3]), veinPaint);
    }
  }

  void _drawHashbrown(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.16); // natural tilt

    // Soft shadow under hashbrown
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-28, -18, 56, 36),
        const Radius.circular(10),
      ),
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Hashbrown base rounded rectangular patty
    const hbRect = Rect.fromLTWH(-26, -16, 52, 32);
    final hbRRect = RRect.fromRectAndRadius(hbRect, const Radius.circular(8));

    // Crispy golden fried potato gradient
    final hbGradient = const RadialGradient(
      center: Alignment(0.0, -0.2),
      radius: 0.85,
      colors: [
        Color(0xFFFFD54F), // golden crispy core
        Color(0xFFFFB300), // deep amber fried potato
        Color(0xFFE65100), // dark crispy toasted crust
      ],
      stops: [0.0, 0.6, 1.0],
    ).createShader(hbRect);

    canvas.drawRRect(hbRRect, Paint()..shader = hbGradient);

    // Crispy crust outline
    canvas.drawRRect(
      hbRRect,
      Paint()
        ..color = const Color(0xFFBF360C)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.2,
    );

    // Shredded potato lattice texture lines
    final shredPaint = Paint()
      ..color = const Color(0xFFE65100).withValues(alpha: 0.5)
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final shredLight = Paint()
      ..color = Colors.white.withValues(alpha: 0.45)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final List<List<double>> hbLines = [
      [-18, -10, -8, 10],
      [-10, -12, 0, 10],
      [-2, -12, 8, 10],
      [6, -10, 16, 8],
      // Opposing
      [-16, 8, -4, -10],
      [-6, 10, 6, -12],
      [4, 10, 14, -10],
    ];

    for (final l in hbLines) {
      canvas.drawLine(Offset(l[0], l[1]), Offset(l[2], l[3]), shredPaint);
      canvas.drawLine(Offset(l[0] + 0.8, l[1]), Offset(l[2] + 0.8, l[3]), shredLight);
    }

    // Crispy toasted bits / specks
    final speckPaint = Paint()..color = const Color(0xFF8D6E63);
    final List<Offset> specks = [
      const Offset(-14, -4),
      const Offset(-5, 4),
      const Offset(6, -6),
      const Offset(12, 2),
      const Offset(-2, -8),
      const Offset(15, -4),
    ];
    for (final s in specks) {
      canvas.drawCircle(s, 1.2, speckPaint);
    }

    canvas.restore();
  }

  void _drawEmbutidoSlices(Canvas canvas, Offset origin) {
    // 3 overlapping diagonal embutido slices
    final slices = [
      Offset(origin.dx - 14, origin.dy + 8),
      Offset(origin.dx, origin.dy),
      Offset(origin.dx + 14, origin.dy - 6),
    ];

    for (int i = 0; i < slices.length; i++) {
      final pos = slices[i];
      canvas.save();
      canvas.translate(pos.dx, pos.dy);
      canvas.rotate(0.35); // diagonal slice angle

      // Slice shadow
      canvas.drawOval(
        const Rect.fromLTWH(-14, -11, 28, 22),
        Paint()
          ..color = const Color(0xFF1B5E20).withValues(alpha: 0.25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
      );

      // Dark caramelized brown skin rim
      canvas.drawOval(
        const Rect.fromLTWH(-13, -10, 26, 20),
        Paint()..color = const Color(0xFF5D2C10),
      );

      // Savory pinkish-brown meat interior
      const meatRect = Rect.fromLTWH(-11.5, -8.5, 23, 17);
      final meatGradient = const RadialGradient(
        center: Alignment(-0.2, -0.2),
        radius: 0.8,
        colors: [
          Color(0xFFD38B6E), // juicy savory embutido meat
          Color(0xFFB56A4F), // seasoned pork/chicken
          Color(0xFF8D4933), // cured edge
        ],
      ).createShader(meatRect);

      canvas.drawOval(meatRect, Paint()..shader = meatGradient);

      // Egg yolk center speck
      canvas.drawCircle(
        const Offset(-1, 0),
        3.0,
        Paint()..color = const Color(0xFFFFB300),
      );
      canvas.drawCircle(
        const Offset(-1, 0),
        1.5,
        Paint()..color = const Color(0xFFFFD54F),
      );

      // Carrot flecks (orange)
      canvas.drawRect(
        const Rect.fromLTWH(-6, -4, 2.2, 2.2),
        Paint()..color = const Color(0xFFFF5722),
      );
      canvas.drawRect(
        const Rect.fromLTWH(4, 2, 2.0, 2.0),
        Paint()..color = const Color(0xFFFF5722),
      );

      // Relish / scallion fleck (green)
      canvas.drawRect(
        const Rect.fromLTWH(3, -4, 2.0, 2.0),
        Paint()..color = const Color(0xFF388E3C),
      );
      canvas.drawRect(
        const Rect.fromLTWH(-5, 3, 2.0, 1.8),
        Paint()..color = const Color(0xFF388E3C),
      );

      // Raisin speck (dark)
      canvas.drawCircle(
        const Offset(1, 4),
        1.4,
        Paint()..color = const Color(0xFF2E1505),
      );

      canvas.restore();
    }
  }

  void _drawRiceMound(Canvas canvas) {
    // Steamed Rice Mound (Center X = 240)
    final ricePath = Path();
    ricePath.moveTo(164, 182);
    ricePath.cubicTo(162, 150, 186, 116, 210, 102);
    ricePath.cubicTo(224, 94, 256, 94, 270, 102);
    ricePath.cubicTo(294, 116, 318, 150, 316, 182);
    ricePath.cubicTo(280, 194, 200, 194, 164, 182);
    ricePath.close();

    // Soft drop shadow under the rice mound
    canvas.drawPath(
      ricePath,
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Rice body gradient (warm white with subtle cream & shadow tones)
    final riceGradient = const RadialGradient(
      center: Alignment(-0.25, -0.45),
      radius: 0.9,
      colors: [
        Color(0xFFFFFFFF), // pure white highlight
        Color(0xFFFAF7F0), // warm jasmine rice
        Color(0xFFF0E8D8), // subtle rice shading
        Color(0xFFE2D5C0), // base contact shadow
      ],
      stops: [0.0, 0.45, 0.8, 1.0],
    ).createShader(const Rect.fromLTWH(162, 94, 156, 98));

    canvas.drawPath(ricePath, Paint()..shader = riceGradient);

    // Rice edge definition stroke
    canvas.drawPath(
      ricePath,
      Paint()
        ..color = const Color(0xFFDED0BC)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0,
    );

    // Textured rice grains around the surface
    final grainPaint = Paint()..color = Colors.white;
    final grainShadow = Paint()..color = const Color(0xFFE0D3C1);

    final List<List<double>> grains = [
      [175, 170, 7, 3.5, 0.2],
      [188, 154, 7.5, 4, -0.3],
      [200, 138, 7, 3.5, 0.4],
      [194, 168, 8, 4, 0.1],
      [212, 160, 7.5, 3.5, -0.2],
      [226, 172, 8, 4, 0.3],
      [240, 165, 8.5, 4, -0.1],
      [256, 172, 7.5, 3.5, 0.2],
      [272, 162, 8, 4, -0.3],
      [288, 170, 7, 3.5, 0.1],
      [294, 148, 7.5, 3.8, 0.3],
      [304, 164, 7, 3.5, -0.2],
      [208, 120, 6.5, 3.2, 0.3],
      [272, 120, 6.5, 3.2, -0.3],
    ];

    for (final g in grains) {
      canvas.save();
      canvas.translate(g[0], g[1]);
      canvas.rotate(g[4]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: const Offset(0.5, 0.5), width: g[2], height: g[3]),
          Radius.circular(g[3] / 2),
        ),
        grainShadow,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: g[2], height: g[3]),
          Radius.circular(g[3] / 2),
        ),
        grainPaint,
      );
      canvas.restore();
    }
  }

  void _drawPastilKagikit(Canvas canvas) {
    // 1. Kagikit Base Silhouette (Organic, shredded mound on the summit of rice)
    final kagikitPath = Path();
    kagikitPath.moveTo(194, 104);
    kagikitPath.cubicTo(198, 84, 212, 66, 240, 66);
    kagikitPath.cubicTo(268, 66, 282, 84, 286, 104);
    kagikitPath.cubicTo(284, 118, 270, 126, 240, 128);
    kagikitPath.cubicTo(210, 126, 196, 118, 194, 104);
    kagikitPath.close();

    // Deep contact shadow on rice
    canvas.drawPath(
      kagikitPath,
      Paint()
        ..color = const Color(0xFF2B1405).withValues(alpha: 0.35)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
    );

    // Kagikit rich savory base gradient (deep braised chicken/beef pastil)
    final kagikitGradient = const RadialGradient(
      center: Alignment(0.0, -0.3),
      radius: 0.85,
      colors: [
        Color(0xFF8B4513), // warm saddle brown
        Color(0xFF5C2C10), // savory braised amber
        Color(0xFF381A08), // dark caramelized soy glaze
      ],
      stops: [0.0, 0.6, 1.0],
    ).createShader(const Rect.fromLTWH(194, 66, 92, 62));

    canvas.drawPath(kagikitPath, Paint()..shader = kagikitGradient);

    // 2. Layered Shredded Meat Fibers & Texture (distinct hand-shredded pastil flakes)
    final shredShadow = Paint()
      ..color = const Color(0xFF2C1304)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round;

    final shredMid = Paint()
      ..color = const Color(0xFF9E4B17)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeCap = StrokeCap.round;

    final shredHighlight = Paint()
      ..color = const Color(0xFFD97724)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final sauceGlisten = Paint()
      ..color = const Color(0xFFFFB74D).withValues(alpha: 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final List<List<double>> shredCurves = [
      [192, 94, 206, 80, 224, 88],
      [210, 76, 230, 68, 248, 76],
      [234, 74, 255, 70, 274, 82],
      [252, 84, 270, 88, 288, 98],
      [198, 104, 218, 96, 238, 102],
      [222, 90, 240, 82, 262, 92],
      [238, 100, 258, 94, 280, 106],
      [206, 114, 228, 110, 250, 116],
      [232, 112, 252, 108, 272, 118],
      [214, 122, 238, 124, 260, 122],
    ];

    for (final s in shredCurves) {
      final p = Path()
        ..moveTo(s[0], s[1])
        ..quadraticBezierTo(s[2], s[3], s[4], s[5]);
      canvas.drawPath(p, shredShadow);
      canvas.drawPath(p, shredMid);
    }

    final List<List<double>> highlightCurves = [
      [200, 86, 216, 78, 232, 82],
      [224, 76, 240, 72, 256, 76],
      [246, 78, 262, 76, 278, 86],
      [212, 96, 230, 88, 248, 94],
      [230, 92, 248, 86, 266, 94],
      [218, 108, 238, 102, 258, 108],
      [228, 118, 244, 116, 258, 118],
    ];

    for (final s in highlightCurves) {
      final p = Path()
        ..moveTo(s[0], s[1])
        ..quadraticBezierTo(s[2], s[3], s[4], s[5]);
      canvas.drawPath(p, shredHighlight);
    }

    final List<List<double>> glistenCurves = [
      [216, 75, 228, 71, 240, 74],
      [244, 75, 254, 74, 264, 80],
      [222, 88, 236, 84, 248, 88],
      [236, 102, 246, 98, 256, 102],
    ];

    for (final s in glistenCurves) {
      final p = Path()
        ..moveTo(s[0], s[1])
        ..quadraticBezierTo(s[2], s[3], s[4], s[5]);
      canvas.drawPath(p, sauceGlisten);
    }

    // 3. Toasted Golden Garlic Bits (sprinkled on pastil)
    final garlicPaint = Paint()..color = const Color(0xFFFFC107);
    final garlicDark = Paint()..color = const Color(0xFFFFA000);

    final List<List<double>> garlicBits = [
      [212, 84, 3.5],
      [230, 76, 4.0],
      [248, 80, 3.8],
      [264, 88, 3.2],
      [206, 100, 3.6],
      [225, 96, 4.2],
      [242, 92, 3.9],
      [258, 100, 4.0],
      [220, 112, 3.5],
      [240, 116, 4.1],
      [254, 112, 3.4],
      [235, 122, 3.2],
    ];

    for (final g in garlicBits) {
      canvas.drawCircle(Offset(g[0] + 0.5, g[1] + 0.5), g[2] / 2, garlicDark);
      canvas.drawCircle(Offset(g[0], g[1]), g[2] / 2, garlicPaint);
    }

    // 4. Fresh Chopped Scallions (Bright green spring onion rings)
    final scallionPaint = Paint()..color = const Color(0xFF4CAF50);
    final scallionLight = Paint()..color = const Color(0xFF81C784);

    final List<List<double>> scallions = [
      [202, 92, 4.5, 3.0, 0.4],
      [220, 82, 5.0, 3.2, -0.2],
      [238, 74, 4.5, 3.0, 0.3],
      [256, 84, 5.0, 3.2, -0.4],
      [214, 104, 4.8, 3.0, 0.2],
      [234, 98, 5.2, 3.4, -0.1],
      [250, 106, 4.6, 3.0, 0.5],
      [228, 114, 5.0, 3.2, -0.3],
      [246, 120, 4.8, 3.0, 0.1],
    ];

    for (final sc in scallions) {
      canvas.save();
      canvas.translate(sc[0], sc[1]);
      canvas.rotate(sc[4]);
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset.zero, width: sc[2], height: sc[3]),
          const Radius.circular(1.5),
        ),
        scallionPaint,
      );
      canvas.drawCircle(const Offset(0, 0), sc[3] * 0.35, scallionLight);
      canvas.restore();
    }
  }

  void _drawRedHotdog(Canvas canvas, Offset origin) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(-0.25);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-28, -9, 56, 18),
        const Radius.circular(9),
      ),
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Hotdog body
    const hdRect = Rect.fromLTWH(-26, -8, 52, 16);
    final hdRRect = RRect.fromRectAndRadius(hdRect, const Radius.circular(8));

    // Filipino bright red hotdog casing gradient
    final hdGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFF5252), // bright glossy red highlight
        Color(0xFFE53935), // classic tender juicy red
        Color(0xFFB71C1C), // deep savory casing shadow
      ],
      stops: [0.0, 0.45, 1.0],
    ).createShader(hdRect);

    canvas.drawRRect(hdRRect, Paint()..shader = hdGradient);

    // Knife grill / diagonal score marks
    final scoreCut = Paint()
      ..color = const Color(0xFF7F0000)
      ..strokeWidth = 2.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final scoreMeat = Paint()
      ..color = const Color(0xFFFFCDD2)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final List<List<double>> scores = [
      [-16, -6, -11, 6],
      [-6, -6, -1, 6],
      [4, -6, 9, 6],
      [14, -6, 19, 6],
    ];

    for (final s in scores) {
      canvas.drawLine(Offset(s[0], s[1]), Offset(s[2], s[3]), scoreCut);
      canvas.drawLine(Offset(s[0] + 0.6, s[1] + 0.5), Offset(s[2] + 0.6, s[3] - 0.5), scoreMeat);
    }

    // Top glossy reflection shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.55)
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(-20, -5), const Offset(20, -5), shinePaint);

    canvas.restore();
  }

  void _drawLumpia(Canvas canvas, Offset origin) {
    canvas.save();
    canvas.translate(origin.dx, origin.dy);
    canvas.rotate(0.22);

    // Shadow
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        const Rect.fromLTWH(-24, -7, 48, 14),
        const Radius.circular(7),
      ),
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Golden-brown fried spring roll
    const lumpiaRect = Rect.fromLTWH(-22, -6, 44, 12);
    final lumpiaRRect = RRect.fromRectAndRadius(lumpiaRect, const Radius.circular(6));

    final lumpiaGradient = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Color(0xFFFFD54F), // crispy golden blistered top
        Color(0xFFFFA000), // deep amber fried wrapper
        Color(0xFFD84315), // crispy toasted bottom
      ],
      stops: [0.0, 0.55, 1.0],
    ).createShader(lumpiaRect);

    canvas.drawRRect(lumpiaRRect, Paint()..shader = lumpiaGradient);

    // Wrapper seam & fried blisters
    final seamPaint = Paint()
      ..color = const Color(0xFFBF360C)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(lumpiaRRect, seamPaint);

    // Diagonally cut end showing savory meat filling
    final fillingPath = Path();
    fillingPath.addOval(const Rect.fromLTWH(18, -5.5, 4, 11));
    canvas.drawPath(fillingPath, Paint()..color = const Color(0xFF5D2C10));
    canvas.drawCircle(const Offset(20, 0), 1.5, Paint()..color = const Color(0xFFFF5722));

    canvas.restore();
  }

  void _drawEggHalf(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(-0.25); // pleasant natural tilt

    // Egg shadow
    canvas.drawOval(
      const Rect.fromLTWH(-16, -18, 34, 40),
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3),
    );

    // Egg white (smooth rounded oval)
    final whitePaint = Paint()..color = Colors.white;
    final whiteStroke = Paint()
      ..color = const Color(0xFFE0E0E0)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    const eggRect = Rect.fromLTWH(-15, -19, 32, 38);
    canvas.drawOval(eggRect, whitePaint);
    canvas.drawOval(eggRect, whiteStroke);

    // Egg yolk (golden orange rich yolk)
    final yolkGradient = const RadialGradient(
      center: Alignment(-0.2, -0.2),
      radius: 0.8,
      colors: [
        Color(0xFFFFD54F), // bright yellow core highlight
        Color(0xFFFFB300), // golden yolk
        Color(0xFFF57C00), // rich orange yolk rim
      ],
      stops: [0.0, 0.65, 1.0],
    ).createShader(const Rect.fromLTWH(-8, -10, 18, 20));

    const yolkRect = Rect.fromLTWH(-8, -10, 18, 20);
    canvas.drawOval(yolkRect, Paint()..shader = yolkGradient);

    // Specular shine on yolk
    canvas.drawCircle(
      const Offset(-4, -6),
      2.0,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );

    canvas.restore();
  }

  void _drawCalamansi(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);

    // Shadow
    canvas.drawCircle(
      const Offset(0.5, 1.5),
      9.0,
      Paint()
        ..color = const Color(0xFF1B5E20).withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2),
    );

    // Dark green rind
    canvas.drawCircle(
      Offset.zero,
      9.0,
      Paint()..color = const Color(0xFF2E7D32),
    );

    // Light green pith
    canvas.drawCircle(
      Offset.zero,
      7.5,
      Paint()..color = const Color(0xFFDCEDC8),
    );

    // Juicy lime center
    canvas.drawCircle(
      Offset.zero,
      6.5,
      Paint()..color = const Color(0xFFC0CA33),
    );

    // Radial segment lines
    final linePaint = Paint()
      ..color = const Color(0xFFDCEDC8)
      ..strokeWidth = 1.0;
    for (int i = 0; i < 6; i++) {
      final double angle = i * (math.pi / 3);
      canvas.drawLine(
        Offset.zero,
        Offset(math.cos(angle) * 6.5, math.sin(angle) * 6.5),
        linePaint,
      );
    }

    canvas.restore();
  }

  void _drawRedChili(Canvas canvas, Offset center) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(0.35);

    // Red chili body
    final chiliPath = Path();
    chiliPath.moveTo(0, 0);
    chiliPath.cubicTo(6, 4, 14, 5, 20, 2);
    chiliPath.cubicTo(18, 7, 10, 9, 0, 3);
    chiliPath.close();

    canvas.drawPath(
      chiliPath,
      Paint()..color = const Color(0xFFD32F2F),
    );

    // Chili green stem
    final stemPath = Path();
    stemPath.moveTo(0, 0);
    stemPath.lineTo(-3, -2);
    stemPath.lineTo(-1, 2);
    stemPath.close();

    canvas.drawPath(
      stemPath,
      Paint()..color = const Color(0xFF388E3C),
    );

    canvas.restore();
  }

  void _drawSteamWisps(Canvas canvas, double progress) {
    // 3 animated steam lines floating and waving above pastil
    final double bob1 = math.sin(progress * 2 * math.pi) * 3.0;
    final double bob2 = math.cos(progress * 2 * math.pi) * 3.0;
    final double bob3 = math.sin((progress + 0.5) * 2 * math.pi) * 3.0;

    final steamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Steam 1 (left)
    final p1 = Path();
    p1.moveTo(214, 60 + bob1);
    p1.cubicTo(208, 48 + bob1, 220, 36 + bob1, 212, 22 + bob1);
    steamPaint.color = Colors.white.withValues(alpha: 0.42);
    steamPaint.strokeWidth = 2.4;
    canvas.drawPath(p1, steamPaint);

    // Steam 2 (center, tallest)
    final p2 = Path();
    p2.moveTo(240, 56 + bob2);
    p2.cubicTo(248, 42 + bob2, 232, 28 + bob2, 242, 14 + bob2);
    steamPaint.color = Colors.white.withValues(alpha: 0.52);
    steamPaint.strokeWidth = 2.8;
    canvas.drawPath(p2, steamPaint);

    // Steam 3 (right)
    final p3 = Path();
    p3.moveTo(264, 60 + bob3);
    p3.cubicTo(258, 48 + bob3, 272, 38 + bob3, 266, 24 + bob3);
    steamPaint.color = Colors.white.withValues(alpha: 0.40);
    steamPaint.strokeWidth = 2.2;
    canvas.drawPath(p3, steamPaint);
  }

  @override
  bool shouldRepaint(covariant _RiceWithPastilPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue;
  }
}

/// White live order preview card on brand golden surface
class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 3),
                    Text(
                      '#00482',
                      style: TextStyle(
                        color: AppColors.darkCharcoal,
                        fontSize: 19,
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: AppColors.softBorder),
          ),
          Row(
            children: const [
              Icon(LucideIcons.utensils, color: AppColors.darkCharcoal, size: 15),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sisig Rice',
                  style: TextStyle(
                    color: AppColors.darkCharcoal,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(LucideIcons.circle_check, color: AppColors.success, size: 13),
          SizedBox(width: 5),
          Text(
            'Served',
            style: TextStyle(
              color: AppColors.success,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
