import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mujeeb24_app/app/localization/app_localizations.dart';
import 'package:mujeeb24_app/app/theme/app_theme.dart';
import 'package:mujeeb24_app/core/auth/biometric_service.dart';
import 'package:mujeeb24_app/features/auth/providers/auth_provider.dart';

/// Redesigned Login Screen matching Mujeeb24 Master Visual Reference.
/// Retains 100% of business logic, validation, authentication flows, and navigation callbacks.
class LoginScreen extends StatefulWidget {
  final AuthProvider authProvider;
  final VoidCallback onLoginSuccess;
  final VoidCallback onNavigateToInvitation;
  final FlutterSecureStorage? secureStorage;
  final BiometricService? biometricService;

  const LoginScreen({
    super.key,
    required this.authProvider,
    required this.onLoginSuccess,
    required this.onNavigateToInvitation,
    this.secureStorage,
    this.biometricService,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const String _savedEmailKey = 'mujeeb24_saved_email';
  static const String _rememberMeKey = 'mujeeb24_remember_me';
  static const String _biometricPasswordKey = 'mujeeb24_biometric_password';

  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late final FlutterSecureStorage _secureStorage;
  late final BiometricService _biometricService;
  bool _obscurePassword = true;
  bool _rememberMe = false;
  bool _canCheckBiometrics = false;
  bool _isBiometricAuthenticating = false;
  String? _biometricError;
  int _failedAttempts = 0;
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    _secureStorage = widget.secureStorage ?? const FlutterSecureStorage();
    _biometricService = widget.biometricService ?? BiometricService();
    widget.authProvider.addListener(_onAuthChanged);
    _loadSavedCredentials();
    _checkBiometricsAvailability();
  }

  Future<void> _checkBiometricsAvailability() async {
    try {
      final available = await _biometricService.isBiometricAvailable();
      if (mounted) {
        setState(() {
          _canCheckBiometrics = available;
        });
      }
    } catch (_) {
      // Gracefully ignore checking errors
    }
  }

  Future<void> _loadSavedCredentials() async {
    try {
      final remember = await _secureStorage.read(key: _rememberMeKey);
      if (remember == 'true') {
        final savedEmail = await _secureStorage.read(key: _savedEmailKey);
        if (savedEmail != null && savedEmail.isNotEmpty && mounted) {
          setState(() {
            _rememberMe = true;
            _emailController.text = savedEmail;
          });
        }
      }
    } catch (_) {
      // Gracefully ignore storage read issues
    }
  }

  void _onAuthChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    widget.authProvider.removeListener(_onAuthChanged);
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _startCooldown([int seconds = 30]) {
    _cooldownTimer?.cancel();
    setState(() {
      _cooldownSeconds = seconds;
    });
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        setState(() {
          _cooldownSeconds = 0;
          _failedAttempts = 0;
        });
      } else {
        setState(() {
          _cooldownSeconds--;
        });
      }
    });
  }

  void _fillDemoCredentials() {
    if (_cooldownSeconds > 0) return;
    setState(() {
      _emailController.text = 'admin@alufuq.com';
      _passwordController.text = 'Password123!';
    });
  }

  Future<void> _handleBiometricLogin() async {
    if (_cooldownSeconds > 0 || _isBiometricAuthenticating || widget.authProvider.isLoading) return;

    setState(() {
      _isBiometricAuthenticating = true;
      _biometricError = null;
    });

    try {
      final authenticated = await _biometricService.authenticate(
        localizedReason: AppStrings.get('biometric_prompt', context),
      );

      if (authenticated) {
        // Step 1: Try restoring the current rotating refresh cookie from secure store
        await widget.authProvider.authRepository.apiClient.restoreRefreshCookie();
        await widget.authProvider.initSession();

        if (widget.authProvider.isAuthenticated && mounted) {
          widget.onLoginSuccess();
          return;
        }

        // Step 2: If session token was expired/absent, login with biometrically protected Keystore credentials
        final savedEmail = await _secureStorage.read(key: _savedEmailKey);
        final savedPassword = await _secureStorage.read(key: _biometricPasswordKey);

        if (savedEmail != null && savedPassword != null && savedEmail.isNotEmpty && savedPassword.isNotEmpty) {
          final loginOk = await widget.authProvider.login(savedEmail, savedPassword);
          if (loginOk && mounted) {
            widget.onLoginSuccess();
            return;
          }
        }

        // Step 3: If no credentials stored yet, show friendly guidance
        if (mounted) {
          setState(() {
            _biometricError = AppStrings.get('biometric_first_login_required', context);
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _biometricError = AppStrings.get('biometric_not_available', context);
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isBiometricAuthenticating = false;
        });
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_cooldownSeconds > 0) return;
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final success = await widget.authProvider.login(email, password);

    if (success) {
      _failedAttempts = 0;
      try {
        if (_rememberMe) {
          await _secureStorage.write(key: _rememberMeKey, value: 'true');
          await _secureStorage.write(key: _savedEmailKey, value: email);
        } else {
          await _secureStorage.delete(key: _rememberMeKey);
          await _secureStorage.delete(key: _savedEmailKey);
        }
        // Save encrypted credentials in hardware Keystore for instant biometric login
        await _secureStorage.write(key: _biometricPasswordKey, value: password);
        await _secureStorage.write(key: _savedEmailKey, value: email);
      } catch (_) {
        // Gracefully ignore storage write issues
      }

      if (mounted) {
        widget.onLoginSuccess();
      }
    } else {
      _failedAttempts++;
      if (_failedAttempts >= 5) {
        _startCooldown(30);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ensureScreenUtilInitialized();
    final auth = widget.authProvider;
    String strings(String key) => AppStrings.get(key, context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.xl,
                vertical: AppSpacing.lg,
              ),
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutCubic,
              tween: Tween<double>(begin: 0.0, end: 1.0),
              builder: (context, opacity, child) {
                return Opacity(
                  opacity: opacity,
                  child: child,
                );
              },
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: AppSpacing.xs),

                    // Brand Header & Mascot Container
                    Center(
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 76,
                            height: 76,
                            decoration: BoxDecoration(
                              color: AppColors.primaryFixed,
                              borderRadius: BorderRadius.circular(AppRadius.xl),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primaryBlue.withValues(alpha: 0.16),
                                  blurRadius: 18,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            alignment: Alignment.center,
                            child: const Icon(
                              Icons.chat_bubble_rounded,
                              size: 40,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            left: -2,
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: AppColors.presenceOnline,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppColors.cardWhite,
                                  width: 2,
                                ),
                                boxShadow: AppShadows.subtle,
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.bolt_rounded,
                                size: 13,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // App Title & B2B Badge
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            strings('app_name'),
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.headingNavy,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs + 2),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.secondaryFixed,
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: AppColors.primaryBlue.withValues(alpha: 0.18),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'B2B',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.onSecondaryFixed,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),

                    // Tagline
                    Center(
                      child: Text(
                        strings('app_tagline'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Welcome Card with Omnipresence Indicators
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(color: AppColors.borderLightBlue),
                        boxShadow: AppShadows.subtle,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryContainer,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                ),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.waving_hand_outlined,
                                  size: 22,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      strings('login_title'),
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.headingNavy,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      strings('login_subtitle'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.secondaryText,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),
                          // Multichannel indicators row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.md,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.cardWhite,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              border: Border.all(color: AppColors.borderLightBlue),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Flexible(
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 7,
                                        height: 7,
                                        decoration: const BoxDecoration(
                                          color: AppColors.presenceOnline,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      const Flexible(
                                        child: Text(
                                          'جاهزية القنوات الفورية:',
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: AppColors.secondaryText,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.chat_bubble_rounded,
                                      size: 15,
                                      color: AppColors.channelWhatsapp,
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.camera_alt_rounded,
                                      size: 15,
                                      color: AppColors.channelInstagram,
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      Icons.facebook_rounded,
                                      size: 15,
                                      color: AppColors.channelFacebook,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Quick Fill Demo Credentials Chip
                    InkWell(
                      onTap: (auth.isLoading || _cooldownSeconds > 0) ? null : _fillDemoCredentials,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.aiSuggestedContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.aiSuggested.withValues(alpha: 0.28),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 17,
                                    color: AppColors.aiSuggested,
                                  ),
                                  const SizedBox(width: AppSpacing.sm),
                                  Flexible(
                                    child: Text(
                                      strings('demo_fill'),
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.aiSuggested,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              strings('demo_fill_btn'),
                              style: const TextStyle(
                                fontSize: 12,
                                decoration: TextDecoration.underline,
                                color: AppColors.aiSuggested,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Error Banner if present
                    if (auth.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.statusErrorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.statusError.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.only(top: 2),
                                  child: Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: AppColors.statusError,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Text(
                                    auth.errorMessage!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.statusError,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (auth.lastRequestId != null &&
                                auth.lastRequestId!.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.xs),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  borderRadius: BorderRadius.circular(AppRadius.sm),
                                ),
                                child: Text(
                                  '${strings('request_id')}: ${auth.lastRequestId}',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textMuted,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Cooldown Timer Banner if active
                    if (_cooldownSeconds > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.statusWarningContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.statusWarning.withValues(alpha: 0.4),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.lock_clock_rounded,
                              size: 20,
                              color: AppColors.statusWarning,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                '${strings('too_many_attempts')} (00:${_cooldownSeconds.toString().padLeft(2, '0')})',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.headingNavy,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Email / Username Field
                    Text(
                      strings('email_or_username'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.headingNavy,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    TextFormField(
                      controller: _emailController,
                      enabled: !auth.isLoading && _cooldownSeconds == 0,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.headingNavy,
                      ),
                      decoration: InputDecoration(
                        hintText: strings('email_hint'),
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                        filled: true,
                        fillColor: AppColors.cardWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.borderLightBlue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.borderLightBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline_rounded,
                          size: 20,
                          color: AppColors.secondaryText,
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return strings('required_field');
                        }
                        if (!value.contains('@')) {
                          return strings('invalid_email');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Password Field
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          strings('password'),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.headingNavy,
                          ),
                        ),
                        const Text(
                          'نسيت كلمة المرور؟',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    TextFormField(
                      controller: _passwordController,
                      enabled: !auth.isLoading && _cooldownSeconds == 0,
                      obscureText: _obscurePassword,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.headingNavy,
                      ),
                      decoration: InputDecoration(
                        hintText: strings('password_hint'),
                        hintStyle: const TextStyle(
                          fontSize: 13,
                          color: AppColors.secondaryText,
                        ),
                        filled: true,
                        fillColor: AppColors.cardWhite,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.md,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.borderLightBlue),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(color: AppColors.borderLightBlue),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          borderSide: const BorderSide(
                            color: AppColors.primaryBlue,
                            width: 1.5,
                          ),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline_rounded,
                          size: 20,
                          color: AppColors.secondaryText,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            size: 20,
                            color: AppColors.secondaryText,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return strings('required_field');
                        }
                        if (value.length < 6) {
                          return strings('password_too_short');
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Remember Me Checkbox
                    Row(
                      children: [
                        SizedBox(
                          height: 22,
                          width: 22,
                          child: Checkbox(
                            value: _rememberMe,
                            activeColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            onChanged: auth.isLoading || _cooldownSeconds > 0
                                ? null
                                : (value) {
                                    setState(() {
                                      _rememberMe = value ?? false;
                                    });
                                  },
                          ),
                        ),
                        const SizedBox(width: AppSpacing.xs + 2),
                        GestureDetector(
                          onTap: auth.isLoading || _cooldownSeconds > 0
                              ? null
                              : () {
                                  setState(() {
                                    _rememberMe = !_rememberMe;
                                  });
                                },
                          child: Text(
                            strings('remember_me'),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.headingNavy,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Biometric Error Banner if present
                    if (_biometricError != null) ...[
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.sm + 2),
                        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                        decoration: BoxDecoration(
                          color: AppColors.statusErrorContainer,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(
                            color: AppColors.statusError.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: AppColors.statusError,
                            ),
                            const SizedBox(width: AppSpacing.xs + 2),
                            Expanded(
                              child: Text(
                                _biometricError!,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.statusError,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Primary Login Button & Biometric Action Row
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (auth.isLoading || _cooldownSeconds > 0 || _isBiometricAuthenticating)
                                ? null
                                : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: _cooldownSeconds > 0
                                  ? AppColors.disabledBackground
                                  : null,
                              disabledForegroundColor: _cooldownSeconds > 0
                                  ? AppColors.disabledText
                                  : null,
                              minimumSize: const Size(double.infinity, 48),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(AppRadius.md),
                              ),
                              elevation: 0,
                            ),
                            child: _cooldownSeconds > 0
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.lock_clock_rounded,
                                        size: 18,
                                        color: AppColors.disabledText,
                                      ),
                                      const SizedBox(width: AppSpacing.sm),
                                      Text(
                                        '${strings('cooldown_wait')} (00:${_cooldownSeconds.toString().padLeft(2, '0')})',
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.disabledText,
                                        ),
                                      ),
                                    ],
                                  )
                                : auth.isLoading
                                    ? Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: AppSpacing.sm),
                                          Text(strings('logging_in')),
                                        ],
                                      )
                                    : Text(
                                        strings('login_button'),
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                          ),
                        ),
                        if (_canCheckBiometrics) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Tooltip(
                            message: strings('biometric_login'),
                            child: InkWell(
                              onTap: (auth.isLoading || _cooldownSeconds > 0 || _isBiometricAuthenticating)
                                  ? null
                                  : _handleBiometricLogin,
                              borderRadius: BorderRadius.circular(AppRadius.md),
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlueLight,
                                  borderRadius: BorderRadius.circular(AppRadius.md),
                                  border: Border.all(
                                    color: AppColors.primaryBlue.withValues(alpha: 0.35),
                                    width: 1.2,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: _isBiometricAuthenticating
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            AppColors.primaryBlue,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.fingerprint_rounded,
                                        size: 26,
                                        color: AppColors.primaryBlue,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Navigate to Invitation Button
                    OutlinedButton.icon(
                      onPressed: auth.isLoading
                          ? null
                          : widget.onNavigateToInvitation,
                      icon: const Icon(Icons.card_membership_rounded, size: 18),
                      label: Text(strings('invitation_title')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.headingNavy,
                        side: const BorderSide(color: AppColors.borderLightBlue),
                        minimumSize: const Size(double.infinity, 46),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          ),
        ),
      ),
    );
  }
}
