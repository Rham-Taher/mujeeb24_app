import 'package:flutter/material.dart';
import '../../../app/theme/app_theme.dart';

/// Standardized Splash Screen for Mujeeb24.
/// Displays the official brand identity, tagline, and subtle motion transitions during startup session restoration.
class SplashScreen extends StatefulWidget {
  final String? loadingMessage;

  const SplashScreen({
    super.key,
    this.loadingMessage,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _scaleAnim = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF0A75F2), // Vibrant Accent Blue
              AppColors.primaryBlue, // #0866D9 Primary Blue
              AppColors.primaryBlueDark, // #064DA8 Primary Blue Dark
            ],
            stops: [0.0, 0.5, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Ambient Decorative Glow Waves
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.06),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 320,
                height: 320,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // Main Brand Center Content
            SafeArea(
              child: Center(
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: ScaleTransition(
                    scale: _scaleAnim,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xxl),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Spacer(flex: 3),

                          // Brand Icon Container with Soft Glow
                          Container(
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(22),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.18),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                            ),
                            child: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Center(
                                  child: Icon(
                                    Icons.chat_bubble_rounded,
                                    size: 46,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                Positioned(
                                  bottom: -3,
                                  left: -3,
                                  child: Container(
                                    width: 22,
                                    height: 22,
                                    decoration: BoxDecoration(
                                      color: AppColors.presenceOnline,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2.5,
                                      ),
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

                          const SizedBox(height: AppSpacing.lg),

                          // Arabic Wordmark
                          const Text(
                            'مجيب 24',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),

                          const SizedBox(height: 2),

                          // English Subtitle
                          Text(
                            'MUJEEB 24 • CONVERSATIONAL COMMERCE',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.85),
                              letterSpacing: 1.2,
                            ),
                          ),

                          const SizedBox(height: AppSpacing.md),

                          // Tagline pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.full),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                                width: 0.8,
                              ),
                            ),
                            child: const Text(
                              'لا تفوّت عميلك، ولو كنت مشغولًا',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),

                          const Spacer(flex: 3),

                          // Loading indicator & Semantics
                          Semantics(
                            label: widget.loadingMessage ?? 'جاري التحقق من جلسة الدخول',
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 26,
                                  height: 26,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.2,
                                    valueColor: const AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  widget.loadingMessage ?? 'جاري التحقق من الجلسة...',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white.withValues(alpha: 0.8),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Spacer(flex: 1),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
