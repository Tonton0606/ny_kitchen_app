import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ny_watermark.dart';
import '../../../admin/presentation/pages/admin_shell.dart';
import '../../../cashier/presentation/pages/cashier_shell.dart';

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
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final emailError = email.isEmpty
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

    Future<void>.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      setState(() => _isLoading = false);

      // Phase 1 keeps authentication static while preserving both demo flows.
      final destination = email.toLowerCase().contains('admin')
          ? AdminShell()
          : CashierShell();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute<void>(builder: (_) => destination),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.sizeOf(context).width >= 1200;

    return Scaffold(
      backgroundColor: AppColors.creamBackground,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: isDesktop
              ? Row(
                  children: [
                    const Expanded(flex: 11, child: _PromotionalPanel()),
                    Expanded(flex: 9, child: _buildLoginPanel(isDesktop: true)),
                  ],
                )
              : _buildLoginPanel(isDesktop: false),
        ),
      ),
    );
  }

  Widget _buildLoginPanel({required bool isDesktop}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final horizontalPadding = isDesktop ? 48.0 : 24.0;
        final verticalPadding = isDesktop ? 48.0 : 32.0;
        final minHeight = (constraints.maxHeight - verticalPadding * 2).clamp(
          0.0,
          double.infinity,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: horizontalPadding,
            vertical: verticalPadding,
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: _buildLoginForm(showLogo: !isDesktop),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoginForm({required bool showLogo}) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return AutofillGroup(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLogo) ...[
            Center(child: _OfficialLogo(width: 220)),
            const SizedBox(height: 40),
          ],
          Text(
            'Welcome back',
            style: theme.textTheme.headlineLarge?.copyWith(
              color: AppColors.darkCharcoal,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sign in to your account to continue',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: AppColors.mutedText,
            ),
          ),
          const SizedBox(height: 40),
          TextField(
            controller: _emailController,
            focusNode: _emailFocus,
            enabled: !_isLoading,
            keyboardType: TextInputType.emailAddress,
            autofillHints: const [AutofillHints.email, AutofillHints.username],
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _passwordFocus.requestFocus(),
            onChanged: (_) {
              if (_emailError != null) setState(() => _emailError = null);
            },
            decoration: _inputDecoration(
              colors: colors,
              label: 'Email or username',
              hint: 'Enter email or username',
              icon: Icons.person_outline,
              errorText: _emailError,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _passwordController,
            focusNode: _passwordFocus,
            enabled: !_isLoading,
            obscureText: _obscurePassword,
            autofillHints: const [AutofillHints.password],
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!_isLoading) _handleLogin();
            },
            onChanged: (_) {
              if (_passwordError != null) setState(() => _passwordError = null);
            },
            decoration: _inputDecoration(
              colors: colors,
              label: 'Password',
              hint: 'Enter your password',
              icon: Icons.lock_outline,
              errorText: _passwordError,
              suffix: Tooltip(
                message: _obscurePassword ? 'Show password' : 'Hide password',
                child: IconButton(
                  onPressed: _isLoading
                      ? null
                      : () => setState(
                          () => _obscurePassword = !_obscurePassword,
                        ),
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 16,
            runSpacing: 8,
            children: [
              SizedBox(
                width: 176,
                child: CheckboxListTile(
                  value: _rememberMe,
                  enabled: !_isLoading,
                  onChanged: (value) =>
                      setState(() => _rememberMe = value ?? false),
                  title: Text(
                    'Remember Me',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.darkCharcoal,
                      fontSize: 15,
                    ),
                  ),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  activeColor: AppColors.goldenYellow,
                  checkColor: AppColors.darkCharcoal,
                ),
              ),
              TextButton(
                onPressed: _isLoading ? null : () {},
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandRed,
                  minimumSize: const Size(48, 48),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Forgot Password?'),
              ),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldenYellow,
                foregroundColor: AppColors.darkCharcoal,
                disabledBackgroundColor: AppColors.goldenYellow.withValues(
                  alpha: 0.55,
                ),
                disabledForegroundColor: AppColors.darkCharcoal,
                elevation: 1,
                shadowColor: AppColors.darkCharcoal.withValues(alpha: 0.16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
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
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 40),
          Text(
            '© 2026 N.Y Kitchen. All rights reserved.',
            textAlign: TextAlign.center,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.mutedText,
              fontSize: 12,
              fontWeight: FontWeight.w400,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({
    required ColorScheme colors,
    required String label,
    required String hint,
    required IconData icon,
    required String? errorText,
    Widget? suffix,
  }) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.softBorder),
    );

    return InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: errorText,
      prefixIcon: Icon(icon),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.surfaceWhite,
      labelStyle: const TextStyle(
        color: AppColors.mutedText,
        fontSize: 15,
        height: 1.4,
      ),
      hintStyle: TextStyle(
        color: AppColors.mutedText.withValues(alpha: 0.72),
        fontSize: 15,
      ),
      prefixIconColor: AppColors.mutedText,
      suffixIconColor: AppColors.mutedText,
      contentPadding: const EdgeInsets.all(16),
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
        borderSide: const BorderSide(color: AppColors.goldenYellow, width: 2),
      ),
      errorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
      focusedErrorBorder: border.copyWith(
        borderSide: BorderSide(color: colors.error, width: 2),
      ),
    );
  }
}

class _OfficialLogo extends StatelessWidget {
  const _OfficialLogo({required this.width});

  final double width;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/images/branding/ny_kitchen_logo.png',
      width: width,
      fit: BoxFit.contain,
      semanticLabel: 'N.Y Kitchen official logo',
    );
  }
}

class _PromotionalPanel extends StatelessWidget {
  const _PromotionalPanel();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                final minHeight = (constraints.maxHeight - 96).clamp(
                  0.0,
                  double.infinity,
                );

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 64, vertical: 48),
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
                              height: 36,
                              fit: BoxFit.contain,
                              semanticLabel: 'N.Y Kitchen emblem',
                            ),
                            const SizedBox(width: 9),
                            const Text(
                              'N.Y KITCHEN',
                              style: TextStyle(
                                color: AppColors.darkCharcoal,
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 68),
                        Transform.translate(
                          offset: const Offset(0, 32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'One counter.\nEvery order, tracked.',
                                style: theme.textTheme.headlineLarge?.copyWith(
                                  color: AppColors.darkCharcoal,
                                  fontSize: 40,
                                  fontWeight: FontWeight.w800,
                                  height: 1.2,
                                  letterSpacing: -0.8,
                                ),
                              ),
                              const SizedBox(height: 24),
                              ConstrainedBox(
                                constraints: const BoxConstraints(maxWidth: 560),
                                child: Text(
                                  'A clear, reliable workspace for taking orders and keeping every transaction organized.',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: AppColors.darkCharcoal.withValues(
                                      alpha: 0.76,
                                    ),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 48),
                              const FractionallySizedBox(
                                widthFactor: 0.82,
                                alignment: Alignment.centerLeft,
                                child: _OrderCard(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const _PastilHero(),
        ],
      ),
        ],
      ),
    );
  }
}

class _PastilHero extends StatefulWidget {
  const _PastilHero();

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
    _floatAnimation = Tween<double>(begin: -8, end: 8).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
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
    return Container(
      height: 200,
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
                  child: Text(
                    'NY',
                    style: TextStyle(
                      color: AppColors.darkCharcoal,
                      fontSize: 180,
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
                for (int i = 0; i < _images.length; i++)
                  Transform.translate(
                    offset: Offset(
                      i < _images.length - 1 ? -36.0 : 0,
                      0,
                    ),
                    child: Image.asset(
                      _images[i],
                      height: 160 + (i.isEven ? 30 : 0),
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

class _OrderCard extends StatelessWidget {
  const _OrderCard();

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.softBorder.withValues(alpha: 0.72)),
        boxShadow: [
          BoxShadow(
            color: AppColors.darkCharcoal.withValues(alpha: 0.07),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order No.',
                      style: textTheme.labelMedium?.copyWith(
                        color: AppColors.mutedText,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#00482',
                      style: textTheme.titleLarge?.copyWith(
                        color: AppColors.darkCharcoal,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              const _StatusBadge(),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1, color: AppColors.softBorder),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Sisig Rice',
                  style: textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkCharcoal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Text(
                'Served',
                style: textTheme.labelLarge?.copyWith(
                  color: AppColors.success,
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.successSurface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Text(
        'Served',
        style: TextStyle(
          color: AppColors.success,
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
