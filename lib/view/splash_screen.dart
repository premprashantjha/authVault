import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  @override
  void initState() {
    super.initState();
    
    // Set system UI to match splash screen
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // Lottie animation controller - longer duration for visibility
    _lottieController = AnimationController(
      duration: const Duration(milliseconds: 2500),
      vsync: this,
    );

    // Fade animation controller
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));

    // Defer animations to next frame to avoid blocking initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      
      setState(() {
        _showContent = true;
      });
      
      // Start animations after UI is rendered
      _fadeController.forward();
      
      // Play animation once, then hold at the end
      _lottieController.forward();
    });

    // Keep splash visible for animation (removed delay, let initialization control timing)
  }

  @override
  void dispose() {
    _lottieController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_showContent) {
      // Show white screen briefly to blend with native splash
      return const Scaffold(
        backgroundColor: Colors.white,
        body: SizedBox.shrink(),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
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
                    // Set the controller duration to match animation
                    _lottieController.duration = composition.duration;
                  },
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback to logo image if Lottie fails
                    return Image.asset(
                      'assets/images/logo.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      cacheWidth: 360, // 2x for better quality
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
