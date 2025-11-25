import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:lottie/lottie.dart';
import '../app/theme.dart';

class SplashScreen extends StatefulWidget {
  final VoidCallback onInitializationComplete;

  const SplashScreen({
    super.key,
    required this.onInitializationComplete,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _lottieController;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  bool _showContent = false;
  final Stopwatch _loadTimer = Stopwatch();

  @override
  void initState() {
    super.initState();
    _loadTimer.start();
    
    // Note: System UI will be set based on theme in build method
    // to ensure it matches the current theme (light/dark)

    // Lottie animation controller - will be set to actual duration in onLoaded
    _lottieController = AnimationController(vsync: this);

    // Fade animation controller - faster fade for better UX
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    ));

    // Show content immediately - no delay to prevent blank screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _showContent = true;
      });
      
      // Start fade animation immediately
      _fadeController.forward();
    });
  }

  @override
  void dispose() {
    _loadTimer.stop();
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Set system UI to match current theme
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: theme.colorScheme.background,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      ),
    );
    
    if (!_showContent) {
      // Show theme background briefly to blend with native splash
      return Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: const SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Lottie animation with error handling and optimization
              SizedBox(
                width: 250,
                height: 250,
                child: Lottie.asset(
                  'assets/images/AuthenticatorLaunch.json',
                  controller: _lottieController,
                  fit: BoxFit.contain,
                  repeat: false,
                  animate: true,
                  frameRate: FrameRate(60),
                  onLoaded: (composition) {
                    // Set the controller duration to match animation and start playing
                    _lottieController.duration = composition.duration;
                    
                    if (mounted) {
                      _lottieController.reset();
                      _lottieController.forward().then((_) {
                        // Animation completed, notify parent after a brief delay
                        Future.delayed(const Duration(milliseconds: 300), () {
                          if (mounted) {
                            widget.onInitializationComplete();
                          }
                        });
                      });
                    }
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to logo image if Lottie fails
                    return Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      cacheWidth: 360, // 2x for better quality
                      errorBuilder: (context, error, stackTrace) {
                        // Ultimate fallback
                        return const Icon(
                          Icons.lock_outline,
                          size: 100,
                          color: Colors.blue,
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              // App name
              Text(
                'Authenticator',
                style: AppTheme.headlineLarge(AppTheme.primaryColor).copyWith(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
