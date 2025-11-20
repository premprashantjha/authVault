import 'package:flutter/material.dart';

enum SnackbarType {
  success,
  error,
  info,
  warning,
}

class CustomSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    String? title,
    SnackbarType type = SnackbarType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    // Use findRootAncestorStateOfType to get the overlay even if context is from a dialog
    final overlay = Overlay.of(context, rootOverlay: true);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _CustomSnackbarWidget(
        message: message,
        title: title,
        type: type,
        duration: duration,
        onDismiss: () => overlayEntry.remove(),
      ),
    );

    overlay.insert(overlayEntry);
  }

  static (Color, Color) _getColors(BuildContext context, SnackbarType type) {
    final colorScheme = Theme.of(context).colorScheme;
    switch (type) {
      case SnackbarType.success:
        return (colorScheme.tertiaryContainer, colorScheme.onTertiaryContainer);
      case SnackbarType.error:
        return (colorScheme.errorContainer, colorScheme.onErrorContainer);
      case SnackbarType.info:
        return (colorScheme.primaryContainer, colorScheme.onPrimaryContainer);
      case SnackbarType.warning:
        return (colorScheme.secondaryContainer, colorScheme.onSecondaryContainer);
    }
  }

  static IconData _getIcon(SnackbarType type) {
    switch (type) {
      case SnackbarType.success:
        return Icons.check_circle;
      case SnackbarType.error:
        return Icons.error;
      case SnackbarType.info:
        return Icons.info;
      case SnackbarType.warning:
        return Icons.warning;
    }
  }
}

class _CustomSnackbarWidget extends StatefulWidget {
  final String message;
  final String? title;
  final SnackbarType type;
  final Duration duration;
  final VoidCallback onDismiss;

  const _CustomSnackbarWidget({
    required this.message,
    this.title,
    required this.type,
    required this.duration,
    required this.onDismiss,
  });

  @override
  State<_CustomSnackbarWidget> createState() => _CustomSnackbarWidgetState();
}

class _CustomSnackbarWidgetState extends State<_CustomSnackbarWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto dismiss after duration
    Future.delayed(widget.duration, () {
      _dismiss();
    });
  }

  void _dismiss() async {
    if (mounted) {
      await _controller.reverse();
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, foregroundColor) = CustomSnackbar._getColors(context, widget.type);
    final icon = CustomSnackbar._getIcon(widget.type);

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SafeArea(
            child: Material(
              color: Colors.transparent,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: GestureDetector(
                  onVerticalDragEnd: (details) {
                    if (details.primaryVelocity! < 0) {
                      _dismiss();
                    }
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: backgroundColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: foregroundColor.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              icon,
                              color: foregroundColor,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (widget.title != null) ...[
                                  Text(
                                    widget.title!,
                                    style: TextStyle(
                                      color: foregroundColor,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                ],
                                Text(
                                  widget.message,
                                  style: TextStyle(
                                    color: foregroundColor.withValues(alpha: 0.9),
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: Icon(Icons.close, color: foregroundColor, size: 20),
                            onPressed: _dismiss,
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
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
