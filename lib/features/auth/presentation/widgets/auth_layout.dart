import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_globals.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';

const String bigPlantLogoAsset = 'assets/branding/bigplant_logo.png';

class AuthLayout extends StatelessWidget {
  const AuthLayout({
    required this.header,
    required this.body,
    this.showBack = false,
    this.onBack,
    this.showLanguageToggle = true,
    super.key,
  });

  final String header;
  final Widget body;
  final bool showBack;
  final VoidCallback? onBack;
  final bool showLanguageToggle;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AuthScaffold(
      child: Column(
        children: [
          AuthTopBar(
            showBack: showBack,
            onBack: onBack,
            title: header,
            showLanguage: showLanguageToggle,
          ),
          Expanded(child: body),
          Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Text(
              t.t('copyright'),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.child,
    this.background = AppColors.surface,
    this.includeDecorations = true,
    super.key,
  });

  final Widget child;
  final Color background;
  final bool includeDecorations;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          if (includeDecorations) const _AuthDecorations(),
          SafeArea(child: child),
        ],
      ),
    );
  }
}

class _AuthDecorations extends StatelessWidget {
  const _AuthDecorations();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            _SoftBlob(
              alignment: Alignment(-1.55, -1.18),
              size: 300,
              color: Color(0x4DBEEAD1),
              blur: 92,
            ),
            _SoftBlob(
              alignment: Alignment(1.35, 1.18),
              size: 360,
              color: Color(0x33B1F0CE),
              blur: 108,
            ),
          ],
        ),
      ),
    );
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({
    required this.alignment,
    required this.size,
    required this.color,
    required this.blur,
  });

  final Alignment alignment;
  final double size;
  final Color color;
  final double blur;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: blur,
              spreadRadius: blur / 6,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthTopBar extends StatelessWidget {
  const AuthTopBar({
    this.showLogo = false,
    this.showBack = false,
    this.showLanguage = false,
    this.title,
    this.onBack,
    this.backButtonSize = 40,
    this.backFilled = false,
    super.key,
  });

  final bool showLogo;
  final bool showBack;
  final bool showLanguage;
  final String? title;
  final VoidCallback? onBack;
  final double backButtonSize;
  final bool backFilled;

  @override
  Widget build(BuildContext context) {
    final hasTitle = title != null && title!.trim().isNotEmpty;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: SizedBox(
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: showLogo
                  ? const AuthLogoMark(size: 40)
                  : showBack
                      ? AuthBackButton(
                          size: backButtonSize,
                          filled: backFilled,
                          onPressed: onBack,
                        )
                      : const SizedBox(width: 40),
            ),
            if (hasTitle)
              Text(
                title!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 24,
                      color: AppColors.primary,
                    ),
              ),
            Align(
              alignment: Alignment.centerRight,
              child: showLanguage
                  ? const AuthLanguageButton()
                  : const SizedBox(width: 40),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthLogoMark extends StatelessWidget {
  const AuthLogoMark({this.size = 40, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.22),
      child: Image.asset(
        bigPlantLogoAsset,
        width: size,
        height: size,
        fit: BoxFit.contain,
      ),
    );
  }
}

class AuthLanguageButton extends StatelessWidget {
  const AuthLanguageButton({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleScope.of(context).locale.languageCode.toUpperCase();
    return Material(
      color: AppColors.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => LocaleScope.of(context).toggle(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.language_rounded,
                size: 18,
                color: AppColors.onSurface,
              ),
              const SizedBox(width: 4),
              Text(
                locale == 'VI' ? 'VN' : 'EN',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurface,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AuthBackButton extends StatelessWidget {
  const AuthBackButton({
    this.onPressed,
    this.size = 40,
    this.filled = false,
    super.key,
  });

  final VoidCallback? onPressed;
  final double size;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.surfaceContainerLowest : Colors.transparent,
      borderRadius: BorderRadius.circular(999),
      elevation: filled ? 1 : 0,
      shadowColor: AppColors.primary.withValues(alpha: 0.08),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onPressed ?? () => Navigator.of(context).pop(),
        child: SizedBox(
          width: size,
          height: size,
          child: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

class AuthCard extends StatelessWidget {
  const AuthCard({
    required this.child,
    this.padding = const EdgeInsets.all(24),
    this.radius = 24,
    this.shadowOpacity = 0.08,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double shadowOpacity;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: shadowOpacity),
            blurRadius: 32,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: child,
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  const AuthPrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.radius = 16,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.45),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
          shadowColor: AppColors.primary.withValues(alpha: 0.25),
          elevation: 6,
        ),
        child: loading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.white,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (icon != null) ...[
                    const SizedBox(width: 8),
                    Icon(icon, size: 20),
                  ],
                ],
              ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  const AuthSecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.radius = 999,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: AppColors.surfaceBright,
          foregroundColor: AppColors.onSurface,
          side: const BorderSide(color: AppColors.outlineVariant),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radius),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 8)],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_rounded, size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class AuthOtpInput extends StatefulWidget {
  const AuthOtpInput({
    required this.controller,
    this.hasError = false,
    this.boxSize = 64,
    super.key,
  });

  final TextEditingController controller;
  final bool hasError;
  final double boxSize;

  @override
  State<AuthOtpInput> createState() => _AuthOtpInputState();
}

class _AuthOtpInputState extends State<AuthOtpInput> {
  late final List<TextEditingController> _digitControllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _digitControllers = List.generate(4, (_) => TextEditingController());
    _focusNodes = List.generate(4, (_) => FocusNode());
    _syncFromParent();
  }

  @override
  void didUpdateWidget(covariant AuthOtpInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      _syncFromParent();
    }
  }

  @override
  void dispose() {
    for (final controller in _digitControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _syncFromParent() {
    final value = widget.controller.text;
    for (var i = 0; i < _digitControllers.length; i++) {
      _digitControllers[i].text = i < value.length ? value[i] : '';
    }
  }

  void _updateParent() {
    widget.controller.text = _digitControllers.map((item) => item.text).join();
  }

  @override
  Widget build(BuildContext context) {
    final borderColor =
        widget.hasError ? AppColors.error : AppColors.surfaceDim;
    final fillColor = widget.hasError
        ? AppColors.errorContainer.withValues(alpha: 0.32)
        : AppColors.surface;
    final textColor = widget.hasError ? AppColors.error : AppColors.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (index) {
        return SizedBox(
          width: widget.boxSize,
          height: widget.boxSize,
          child: TextField(
            controller: _digitControllers[index],
            focusNode: _focusNodes[index],
            onTapOutside: (_) => FocusScope.of(context).unfocus(),
            keyboardType: TextInputType.number,
            textInputAction:
                index == 3 ? TextInputAction.done : TextInputAction.next,
            textAlign: TextAlign.center,
            maxLength: 1,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w700,
                ),
            decoration: InputDecoration(
              counterText: '',
              filled: true,
              fillColor: fillColor,
              hintText: '·',
              hintStyle: TextStyle(color: AppColors.outline.withValues(alpha: 0.6)),
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: borderColor,
                  width: widget.hasError ? 2 : 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(
                  color: widget.hasError ? AppColors.error : AppColors.primary,
                  width: 2,
                ),
              ),
            ),
            onChanged: (value) {
              if (value.length > 1) {
                _digitControllers[index].text = value.substring(value.length - 1);
              }
              _updateParent();
              if (value.isNotEmpty && index < _focusNodes.length - 1) {
                _focusNodes[index + 1].requestFocus();
              } else if (value.isEmpty && index > 0) {
                _focusNodes[index - 1].requestFocus();
              }
            },
          ),
        );
      }),
    );
  }
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

Widget appLogo() {
  return Column(
    children: [
      const AuthLogoMark(size: 112),
      const SizedBox(height: 16),
      Text(
        AppGlobals.appName,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 32,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}
