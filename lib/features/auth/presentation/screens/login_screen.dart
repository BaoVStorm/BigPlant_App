import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/routing/app_router.dart';
import '../../domain/auth_service.dart';
import '../widgets/auth_input.dart';
import '../widgets/auth_layout.dart';

const bool kGoogleLoginEnabled = false;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final AuthService _authService = AuthService();

  bool _agreed = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final t = AppLocalizations.of(context);
    final username = _usernameCtrl.text.trim();
    final password = _passwordCtrl.text;

    if (username.isEmpty) {
      setState(() => _error = t.t('error_username_empty'));
      return;
    }
    if (password.isEmpty) {
      setState(() => _error = t.t('error_password_empty'));
      return;
    }
    if (password.length < 8) {
      setState(() => _error = t.t('error_password_invalid'));
      return;
    }
    if (!_agreed) {
      setState(() => _error = t.t('error_checkbox'));
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await _authService.login(username: username, password: password);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(AppRouter.authHome);
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
          const AuthTopBar(showLogo: true, showLanguage: true),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 432),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        t.t('auth_login_title'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        t.t('auth_login_subtitle'),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 32),
                      AuthInput(
                        controller: _usernameCtrl,
                        label: t.t('auth_username_label'),
                        hint: t.t('username_hint'),
                        icon: Icons.mail_outline_rounded,
                        keyboardType: TextInputType.emailAddress,
                        fillColor: AppColors.surfaceBright,
                      ),
                      const SizedBox(height: 16),
                      AuthInput(
                        controller: _passwordCtrl,
                        label: t.t('auth_password_label'),
                        hint: t.t('password_hint'),
                        icon: Icons.lock_outline_rounded,
                        obscureText: true,
                        fillColor: AppColors.surfaceBright,
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _agreed,
                              activeColor: AppColors.primary,
                              side: const BorderSide(
                                color: AppColors.outlineVariant,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (value) =>
                                  setState(() => _agreed = value ?? false),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.t('terms'),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .labelSmall
                                  ?.copyWith(
                                    color: AppColors.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRouter.forgotPassword),
                            child: Text(t.t('forgot_password')),
                          ),
                        ],
                      ),
                      if (_error != null) ...[
                        const SizedBox(height: 18),
                        AuthErrorBanner(message: _error!),
                      ],
                      const SizedBox(height: 20),
                      AuthPrimaryButton(
                        label: t.t('login'),
                        loading: _loading,
                        radius: 999,
                        onPressed: _login,
                      ),
                      if (kGoogleLoginEnabled) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: Divider(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                t.t('auth_or'),
                                style: Theme.of(context)
                                    .textTheme
                                    .labelSmall
                                    ?.copyWith(
                                      color: AppColors.onSurfaceVariant,
                                    ),
                              ),
                            ),
                            Expanded(
                              child: Divider(
                                color: AppColors.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        AuthSecondaryButton(
                          label: t.t('login_with_google'),
                          icon: const _GoogleMark(),
                          onPressed: () =>
                              showToast(context, t.t('google_coming_soon')),
                        ),
                      ],
                      const SizedBox(height: 28),
                      Wrap(
                        alignment: WrapAlignment.center,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            '${t.t('dont_have_account')} ',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                ),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context)
                                .pushNamed(AppRouter.register),
                            child: Text(t.t('auth_register_link')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return const Text(
      'G',
      style: TextStyle(
        color: Color(0xFF4285F4),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}
