import 'dart:async';
import 'package:flutter/material.dart';
import '../localization/app_localizations.dart';

enum AppToastType { success, info, error }

class _ToastRequest {
  final BuildContext context;
  final String message;
  final String? title;
  final AppToastType type;

  _ToastRequest({
    required this.context,
    required this.message,
    this.title,
    required this.type,
  });
}

class AppToast {
  static final List<_ToastRequest> _queue = [];
  static bool _isShowing = false;

  static void showSuccess(BuildContext context, String message, {String? title}) {
    _enqueue(context, message, title: title, type: AppToastType.success);
  }

  static void showInfo(BuildContext context, String message, {String? title}) {
    _enqueue(context, message, title: title, type: AppToastType.info);
  }

  static void showError(BuildContext context, String message, {String? title}) {
    _enqueue(context, message, title: title, type: AppToastType.error);
  }

  static void _enqueue(BuildContext context, String message, {String? title, required AppToastType type}) {
    _queue.add(_ToastRequest(context: context, message: message, title: title, type: type));
    _processQueue();
  }

  static void _processQueue() {
    if (_isShowing || _queue.isEmpty) return;
    
    _isShowing = true;
    final request = _queue.removeAt(0);
    _showToast(request);
  }

  static void _showToast(_ToastRequest request) {
    if (!request.context.mounted) {
      _isShowing = false;
      _processQueue();
      return;
    }

    final overlayState = Overlay.of(request.context);
    OverlayEntry? overlayEntry;

    void onDismiss() {
      overlayEntry?.remove();
      _isShowing = false;
      _processQueue();
    }

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: _ToastWidget(
          title: request.title,
          message: request.message,
          type: request.type,
          onDismiss: onDismiss,
        ),
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.title,
    required this.message,
    required this.type,
    required this.onDismiss,
  });

  final String? title;
  final String message;
  final AppToastType type;
  final VoidCallback onDismiss;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _fadeAnimation;
  Timer? _timer;
  bool _isDismissing = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();
    _startTimer();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(const Duration(seconds: 3), _dismiss);
  }

  void _pauseTimer() {
    _timer?.cancel();
  }

  void _dismiss() {
    if (_isDismissing) return;
    _isDismissing = true;
    _timer?.cancel();
    if (mounted) {
      _controller.reverse().then((_) => widget.onDismiss());
    } else {
      widget.onDismiss();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    List<Color> gradientColors;
    IconData iconData;
    String fallbackTitle;

    switch (widget.type) {
      case AppToastType.success:
        gradientColors = const [Color.fromARGB(255, 30, 134, 85), Color(0xFF25A26A)];
        iconData = Icons.check_circle_rounded;
        fallbackTitle = AppLocalizations.of(context).t('scan_success_title');
        break;
      case AppToastType.error:
        gradientColors = const [Color.fromARGB(255, 198, 40, 40), Color(0xFFE53935)];
        iconData = Icons.error_rounded;
        fallbackTitle = 'Error';
        break;
      case AppToastType.info:
      default:
        gradientColors = const [Color.fromARGB(255, 21, 101, 192), Color(0xFF1E88E5)];
        iconData = Icons.info_rounded;
        fallbackTitle = 'Info';
        break;
    }

    final displayTitle = widget.title ?? fallbackTitle;

    return GestureDetector(
      onTapDown: (_) => _pauseTimer(),
      onTapUp: (_) => _startTimer(),
      onTapCancel: () => _startTimer(),
      onVerticalDragUpdate: (details) {
        if (details.primaryDelta != null && details.primaryDelta! < -5) {
          _dismiss();
        }
      },
      child: Material(
        color: Colors.transparent,
        child: SlideTransition(
          position: _slideAnimation,
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradientColors,
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: gradientColors.last.withValues(alpha: 0.40),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconData,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          displayTitle,
                          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontWeight: FontWeight.w500,
                                fontSize: 12,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.message,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 16,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
