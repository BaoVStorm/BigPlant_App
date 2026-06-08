import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/auth_service.dart';
import '../widgets/auth_input.dart';
import '../widgets/auth_layout.dart';
import 'success_screen.dart';

class ForgotNewPasswordScreen extends StatefulWidget {
  const ForgotNewPasswordScreen({
    required this.email,
    required this.otp,
    super.key,
  });

  final String email;
  final String otp;

  @override
  State<ForgotNewPasswordScreen> createState() =>
      _ForgotNewPasswordScreenState();
}

class _ForgotNewPasswordScreenState extends State<ForgotNewPasswordScreen> {
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _rePasswordCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _rePasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = AppLocalizations.of(context);
    final password = _passwordCtrl.text;
    final rePassword = _rePasswordCtrl.text;

    if (password.isEmpty) {
      setState(() => _error = t.t('error_password_empty'));
      return;
    }
    if (password.length < 8) {
      setState(() => _error = t.t('error_password_invalid'));
      return;
    }
    if (rePassword.isEmpty) {
      setState(() => _error = t.t('error_repassword_empty'));
      return;
    }
    if (rePassword != password) {
      setState(() => _error = t.t('error_repassword_invalid'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.resetForgotPassword(
        email: widget.email,
        otp: widget.otp,
        newPassword: password,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(
        AppRouter.success,
        arguments: SuccessMode.password,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return AuthScaffold(
      child: Column(
        children: [
          Container(
            color: AppColors.surface.withValues(alpha: 0.8),
            child: const AuthTopBar(showBack: true),
          ),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final minHeight =
                    (constraints.maxHeight - 64)
                        .clamp(0.0, double.infinity)
                        .toDouble();

                return SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 512,
                        minHeight: minHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              t.t('auth_new_password_title'),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              t.t('auth_new_password_desc'),
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 32),
                            AuthInput(
                              controller: _passwordCtrl,
                              label: t.t('auth_new_password_label'),
                              hint: t.t('auth_new_password_hint'),
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              fillColor: AppColors.surfaceBright,
                              borderRadius: 16,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.info_outline_rounded,
                                  size: 16,
                                  color: AppColors.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    t.t('auth_password_rule'),
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: AppColors.onSurfaceVariant,
                                        ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            AuthInput(
                              controller: _rePasswordCtrl,
                              label: t.t('auth_confirm_new_password_label'),
                              hint: t.t('auth_confirm_new_password_hint'),
                              icon: Icons.lock_outline_rounded,
                              obscureText: true,
                              fillColor: AppColors.surfaceBright,
                              borderRadius: 16,
                            ),
                            if (_error != null) ...[
                              const SizedBox(height: 18),
                              AuthErrorBanner(message: _error!),
                            ],
                            const Spacer(),
                            AuthPrimaryButton(
                              label: t.t('auth_save_password'),
                              loading: _loading,
                              icon: Icons.check_rounded,
                              onPressed: _submit,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
