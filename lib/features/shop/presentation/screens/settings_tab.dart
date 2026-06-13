import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/locale_controller.dart';
import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/data/storage_service.dart';
import '../../../auth/domain/auth_service.dart';
import 'edit_user_screen.dart';

class SettingsTab extends StatefulWidget {
  const SettingsTab({super.key});

  @override
  State<SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<SettingsTab> {
  final AuthService _authService = AuthService();

  bool _notifyDeals = true;
  bool _plantCareTips = true;
  bool _loggingOut = false;
  String _displayName = 'User';
  String _displayEmail = '-';
  String _userName = '';
  String _phoneNumber = '';
  String _dateOfBirth = '';
  String _gender = 'unknown';
  String? _photoUrl;

  @override
  void initState() {
    super.initState();
    _loadSettingsState();
  }

  Future<void> _loadSettingsState() async {
    final fullName = (await StorageService.getFullName())?.trim() ?? '';
    final userName = (await StorageService.getUserName())?.trim() ?? '';
    final email = (await StorageService.getEmail())?.trim() ?? '';
    final phone = (await StorageService.getPhoneNumber())?.trim() ?? '';
    final dateOfBirth = (await StorageService.getDateOfBirth())?.trim() ?? '';
    final gender = (await StorageService.getGender())?.trim() ?? 'unknown';
    final notifyDeals = await StorageService.getNotifyDeals();
    final notifyPlantTips = await StorageService.getNotifyPlantTips();
    final photoUrl = await StorageService.getPhotoUrl();

    if (!mounted) return;
    setState(() {
      _displayName = fullName.isNotEmpty
          ? fullName
          : (userName.isNotEmpty ? userName : 'User');
      _displayEmail = email.isNotEmpty ? email : '-';
      _userName = userName;
      _phoneNumber = phone;
      _dateOfBirth = dateOfBirth;
      _gender = gender.isEmpty ? 'unknown' : gender;
      _notifyDeals = notifyDeals;
      _plantCareTips = notifyPlantTips;
      _photoUrl = photoUrl;
    });
  }

  Future<void> _openEditUser() async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditUserScreen(
          userName: _userName,
          fullName: _displayName == 'User' ? '' : _displayName,
          email: _displayEmail == '-' ? '' : _displayEmail,
          phoneNumber: _phoneNumber,
          dateOfBirth: _dateOfBirth,
          gender: _gender,
          photoUrl: _photoUrl,
        ),
      ),
    );

    if (changed == true) {
      await _loadSettingsState();
    }
  }

  Future<void> _toggleDeals(bool value) async {
    setState(() => _notifyDeals = value);
    await StorageService.setNotifyDeals(value);
  }

  Future<void> _togglePlantTips(bool value) async {
    setState(() => _plantCareTips = value);
    await StorageService.setNotifyPlantTips(value);
  }

  Future<void> _toggleLanguage() async {
    await LocaleScope.of(context).toggle();
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _openHelp() async {
    final t = AppLocalizations.of(context);
    AppToast.showInfo(
      context,
      t.t('settings_help_coming_soon'),
    );
  }

  Future<void> _logout() async {
    if (_loggingOut) return;
    setState(() => _loggingOut = true);
    await _authService.logout();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(AppRouter.login, (route) => false);
  }

  String _languageLabel(AppLocalizations t) {
    final code = LocaleScope.of(context).locale.languageCode.toLowerCase();
    return code == 'vi' ? t.t('settings_language_vi') : t.t('settings_language_en');
  }

  String _initials() {
    final source = _displayName.trim().isNotEmpty && _displayName != 'User'
        ? _displayName.trim()
        : (_userName.trim().isNotEmpty ? _userName.trim() : 'User');
    final parts = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.surface,
      ),
      child: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 120),
          children: [
            Center(
              child: Text(
                t.t('settings_title'),
                style: theme.textTheme.headlineMedium?.copyWith(
                  color: AppColors.primary,
                  fontSize: 24,
                ),
              ),
            ),
            const SizedBox(height: 40),
            _SettingsProfileCard(
              displayName: _displayName,
              email: _displayEmail,
              initials: _initials(),
              photoUrl: _photoUrl,
              onTap: _openEditUser,
            ),
            const SizedBox(height: 40),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _ToggleSettingRow(
                    icon: Icons.notifications_active,
                    title: t.t('notify_deals'),
                    subtitle: t.t('settings_deals_subtitle'),
                    value: _notifyDeals,
                    showDivider: true,
                    onChanged: _toggleDeals,
                  ),
                  _ToggleSettingRow(
                    icon: Icons.energy_savings_leaf,
                    title: t.t('notify_tips'),
                    subtitle: t.t('settings_tips_subtitle'),
                    value: _plantCareTips,
                    showDivider: true,
                    onChanged: _togglePlantTips,
                  ),
                  _NavigationSettingRow(
                    icon: Icons.language,
                    title: t.t('language'),
                    trailingLabel: _languageLabel(t),
                    showDivider: true,
                    onTap: _toggleLanguage,
                  ),
                  _NavigationSettingRow(
                    icon: Icons.help_outline,
                    title: t.t('settings_help_support'),
                    subtitle: t.t('settings_help_support_subtitle'),
                    onTap: _openHelp,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: _loggingOut ? null : _logout,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                minimumSize: const Size(double.infinity, 56),
                side: BorderSide(color: AppColors.error.withValues(alpha: 0.2), width: 2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _loggingOut
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.error,
                      ),
                    )
                  : const Icon(Icons.logout),
              label: Text(t.t('logout')),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsProfileCard extends StatelessWidget {
  const _SettingsProfileCard({
    required this.displayName,
    required this.email,
    required this.initials,
    required this.onTap,
    this.photoUrl,
  });

  final String displayName;
  final String email;
  final String initials;
  final VoidCallback onTap;
  final String? photoUrl;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Ink(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryContainer, AppColors.primaryFixed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.surfaceContainerHigh, width: 1),
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? AppNetworkImage(imageUrl: photoUrl!, fit: BoxFit.cover, width: 64, height: 64)
                    : Text(
                        initials,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 20,
                        ),
                      ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        color: AppColors.primary,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      email,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleSettingRow extends StatelessWidget {
  const _ToggleSettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool showDivider;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final row = Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _SettingLeadingIcon(icon: icon),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.onSurface,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontWeight: FontWeight.w400,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeColor: AppColors.white,
            activeTrackColor: AppColors.primary,
            inactiveThumbColor: AppColors.white,
            inactiveTrackColor: AppColors.surfaceContainerHighest,
            onChanged: onChanged,
          ),
        ],
      ),
    );

    return Column(
      children: [
        row,
        if (showDivider)
          const Divider(height: 1, color: AppColors.surfaceContainerHigh, indent: 20, endIndent: 20),
      ],
    );
  }
}

class _NavigationSettingRow extends StatelessWidget {
  const _NavigationSettingRow({
    required this.icon,
    required this.title,
    required this.onTap,
    this.subtitle,
    this.trailingLabel,
    this.showDivider = false,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailingLabel;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final row = Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              _SettingLeadingIcon(icon: icon),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: AppColors.onSurface,
                        fontSize: 16,
                      ),
                    ),
                    if ((subtitle ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: AppColors.onSurfaceVariant,
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if ((trailingLabel ?? '').trim().isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: Text(
                    trailingLabel!,
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.onSurfaceVariant,
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right, color: AppColors.outline),
            ],
          ),
        ),
      ),
    );

    return Column(
      children: [
        row,
        if (showDivider)
          const Divider(height: 1, color: AppColors.surfaceContainerHigh, indent: 20, endIndent: 20),
      ],
    );
  }
}

class _SettingLeadingIcon extends StatelessWidget {
  const _SettingLeadingIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: AppColors.primary),
    );
  }
}
