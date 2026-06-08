import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/auth_service.dart';
import '../widgets/auth_layout.dart';

class ForgotVerifyScreen extends StatefulWidget {
  const ForgotVerifyScreen({required this.email, super.key});

  final String email;

  @override
  State<ForgotVerifyScreen> createState() => _ForgotVerifyScreenState();
}

class _ForgotVerifyScreenState extends State<ForgotVerifyScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  final AuthService _authService = AuthService();
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final t = AppLocalizations.of(context);
    final otp = _otpCtrl.text.trim();
    if (otp.length != 4) {
      setState(() => _error = t.t('error_otp_invalid'));
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await _authService.verifyForgotOtp(email: widget.email, otp: otp);
      if (!mounted) return;
      Navigator.of(context).pushNamed(
        AppRouter.forgotNewPassword,
        arguments: {'email': widget.email, 'otp': otp},
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resend() async {
    final t = AppLocalizations.of(context);
    try {
      await _authService.forgotPassword(widget.email);
      if (!mounted) return;
      showToast(context, t.t('toast_success_default'));
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AuthScaffold(
      includeDecorations: false,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final minHeight =
              (constraints.maxHeight - 80)
                  .clamp(0.0, double.infinity)
                  .toDouble();

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 40, 24, 40),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: 480,
                  minHeight: minHeight,
                ),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Align(
                        alignment: Alignment.centerLeft,
                        child: AuthBackButton(size: 40),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        t.t('auth_forgot_otp_title'),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppColors.onSurface,
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.t('auth_forgot_otp_desc'),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.email,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 40),
                      AuthOtpInput(
                        controller: _otpCtrl,
                        hasError: _error != null,
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            const Icon(
                              Icons.error_rounded,
                              color: AppColors.error,
                              size: 16,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                _error!,
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.error,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const Spacer(),
                      AuthPrimaryButton(
                        label: t.t('verify_email'),
                        loading: _loading,
                        onPressed: _verify,
                      ),
                      const SizedBox(height: 24),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${t.t('didnt_get_email')} ',
                            style:
                                Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                          ),
                          TextButton(
                            onPressed: _resend,
                            child: Text(t.t('resend')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
