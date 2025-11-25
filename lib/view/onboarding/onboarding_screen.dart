import 'package:flutter/material.dart';
import '../../app/theme.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final List<String> tips;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.tips,
  });
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinished;
  final bool allowSkip;
  final bool isReviewMode;
  final int initialPageIndex;

  const OnboardingScreen({
    super.key,
    required this.onFinished,
    this.allowSkip = true,
    this.isReviewMode = false,
    this.initialPageIndex = 0,
  });

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final PageController _controller;
  late final int _initialPage;
  int _currentIndex = 0;

  static const List<OnboardingSlide> _slides = [
    OnboardingSlide(
      title: 'Your Vault Stays Local',
      description: 'All secrets are encrypted with AES-256 and never leave this device.',
      icon: Icons.security,
      tips: [
        'No cloud sync or telemetry',
        'Hardware-backed key storage',
        'Only you control your data',
      ],
    ),
    OnboardingSlide(
      title: 'Lock It Down',
      description: 'Add a strong PIN and enable biometrics to protect the vault.',
      icon: Icons.lock_outline,
      tips: [
        'Use 6+ digit PIN that is unique',
        'Biometric is optional but convenient',
        'App relocks automatically after 5 minutes',
      ],
    ),
    OnboardingSlide(
      title: 'Keep Devices Clean',
      description: 'We block screenshots and warn if the device looks compromised.',
      icon: Icons.phonelink_lock,
      tips: [
        'Rooted devices reduce protection',
        'FLAG_SECURE stops screen recording',
        'We detect debugger/developer mode',
      ],
    ),
    OnboardingSlide(
      title: 'Manual Backup Checklist',
      description: 'We never sync secrets to the cloud. Keep offline copies so a lost phone is not a disaster.',
      icon: Icons.sd_card_outlined,
      tips: [
        'Capture the original QR secret or setup key when enrolling an account and store it offline',
        'Save each provider\'s backup codes or recovery paths in the same protected location',
        'Use an encrypted password manager, hardware key, or physical safe—never screenshots or email',
        'Test recovery on a spare device before wiping or upgrading your primary phone',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _initialPage = widget.initialPageIndex.clamp(0, _slides.length - 1);
    _currentIndex = _initialPage;
    _controller = PageController(initialPage: _initialPage);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_currentIndex == _slides.length - 1) {
      widget.onFinished();
      return;
    }
    _controller.nextPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  void _goPrevious() {
    if (_currentIndex == 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLast = _currentIndex == _slides.length - 1;
    final skipLabel = widget.isReviewMode ? 'Close' : 'Skip';
    final completionLabel = widget.isReviewMode ? 'Close' : 'Get Started';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.allowSkip || widget.isReviewMode)
                    TextButton(
                      onPressed: widget.onFinished,
                      child: Text(skipLabel),
                    ),
                ],
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _slides.length,
                onPageChanged: (index) => setState(() => _currentIndex = index),
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          height: 72,
                          width: 72,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Icon(slide.icon, size: 40, color: AppTheme.primaryColor),
                        ),
                        const SizedBox(height: 32),
                        Text(
                          slide.title,
                          style: AppTheme.headlineMedium(theme.colorScheme.onSurface).copyWith(
                            fontWeight: AppTheme.weightBold,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.description,
                          style: AppTheme.bodyMedium(theme.colorScheme.onSurface).copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ...slide.tips.map(
                          (tip) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 24,
                                  alignment: Alignment.topLeft,
                                  child: Icon(Icons.check_circle, size: 18, color: AppTheme.primaryColor),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    tip,
                                    style: AppTheme.bodyMedium(theme.colorScheme.onSurface),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _slides.length,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentIndex == index ? 32 : 10,
                        decoration: BoxDecoration(
                          color: _currentIndex == index
                              ? AppTheme.primaryColor
                              : theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _currentIndex == 0 ? null : _goPrevious,
                          child: const Text('Back'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _goNext,
                          child: Text(isLast ? completionLabel : 'Next'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
