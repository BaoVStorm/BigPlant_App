import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';

class AuthInput extends StatefulWidget {
  const AuthInput({
    required this.controller,
    required this.hint,
    required this.icon,
    this.label,
    this.obscureText = false,
    this.keyboardType,
    this.errorText,
    this.fillColor = AppColors.surface,
    this.borderRadius = 12,
    super.key,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final String? label;
  final bool obscureText;
  final TextInputType? keyboardType;
  final String? errorText;
  final Color fillColor;
  final double borderRadius;

  @override
  State<AuthInput> createState() => _AuthInputState();
}

class _AuthInputState extends State<AuthInput> {
  late bool _obscured;

  @override
  void initState() {
    super.initState();
    _obscured = widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant AuthInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.obscureText != widget.obscureText) {
      _obscured = widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasError = widget.errorText != null && widget.errorText!.isNotEmpty;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        TextField(
          controller: widget.controller,
          onTapOutside: (_) => FocusScope.of(context).unfocus(),
          keyboardType: widget.keyboardType,
          obscureText: _obscured,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurface,
          ),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: theme.textTheme.bodyMedium?.copyWith(
              color: AppColors.outline,
            ),
            filled: true,
            fillColor: widget.fillColor,
            contentPadding: EdgeInsets.fromLTRB(
              48,
              widget.borderRadius >= 16 ? 16 : 14,
              widget.obscureText ? 48 : 16,
              widget.borderRadius >= 16 ? 16 : 14,
            ),
            prefixIcon: Icon(
              widget.icon,
              color: hasError ? AppColors.error : AppColors.outlineVariant,
              size: 22,
            ),
            suffixIcon: widget.obscureText
                ? IconButton(
                    onPressed: () => setState(() => _obscured = !_obscured),
                    icon: Icon(
                      _obscured
                          ? Icons.visibility_off_rounded
                          : Icons.visibility_rounded,
                      color: AppColors.outlineVariant,
                    ),
                  )
                : hasError
                    ? const Icon(Icons.error_rounded, color: AppColors.error)
                    : null,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: hasError
                    ? AppColors.error
                    : AppColors.outlineVariant.withValues(alpha: 0.45),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: BorderSide(
                color: hasError ? AppColors.error : AppColors.primary,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(widget.borderRadius),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
        if (hasError) ...[
          const SizedBox(height: 6),
          Text(
            widget.errorText!,
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.error,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}
