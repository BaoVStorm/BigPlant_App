import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_globals.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/domain/auth_service.dart';


class EditUserScreen extends StatefulWidget {
  const EditUserScreen({
    required this.userName,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.dateOfBirth,
    required this.gender,
    this.photoUrl,
    super.key,
  });

  final String userName;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String dateOfBirth;
  final String gender;
  final String? photoUrl;

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  late final TextEditingController _fullNameCtrl;
  late final TextEditingController _phoneCtrl;

  DateTime? _selectedDate;
  late String _gender;
  bool _saving = false;
  
  Uint8List? _avatarBytes;
  String? _base64Avatar;

  bool get _isDirty {
    if (_fullNameCtrl.text.trim() != widget.fullName.trim()) return true;
    if (_phoneCtrl.text.trim() != widget.phoneNumber.trim()) return true;
    if (_formatDate(_selectedDate) != widget.dateOfBirth) return true;
    if (_gender != (widget.gender.isEmpty || widget.gender == 'unknown' ? 'other' : widget.gender)) return true;
    if (_avatarBytes != null) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _fullNameCtrl = TextEditingController(text: widget.fullName);
    _phoneCtrl = TextEditingController(text: widget.phoneNumber);
    _gender = (widget.gender.isEmpty || widget.gender == 'unknown') ? 'other' : widget.gender;
    _selectedDate = _parseDate(widget.dateOfBirth);
  }

  @override
  void dispose() {
    _fullNameCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String value) {
    if (value.trim().isEmpty) return null;
    return DateTime.tryParse(value);
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '';
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  String _displayDate(BuildContext context) {
    final date = _selectedDate;
    if (date == null) {
      return AppLocalizations.of(context).t('settings_field_date_of_birth');
    }
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  String _handleLabel() {
    final userName = widget.userName.trim();
    if (userName.isNotEmpty) return '@$userName';
    return '@flora_member';
  }

  String _initials() {
    final source = _fullNameCtrl.text.trim().isNotEmpty
        ? _fullNameCtrl.text.trim()
        : widget.userName.trim();
    if (source.isEmpty) return 'U';
    final parts = source.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(now.year - 20, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
    );
    if (picked == null || !mounted) return;
    setState(() => _selectedDate = picked);
  }

  bool _isValidPhone(String value) {
    final normalized = value.trim();
    if (normalized.isEmpty) return true;
    return RegExp(r'^[+0-9()\-\s]{7,20}$').hasMatch(normalized);
  }

  Future<void> _save() async {
    final t = AppLocalizations.of(context);
    final phone = _phoneCtrl.text.trim();
    if (!_isValidPhone(phone)) {
      AppToast.showError(
        context,
        t.t('settings_invalid_phone'),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final AuthService authService = AuthService();
      await authService.updateProfile(
        fullName: _fullNameCtrl.text.trim(),
        phoneNumber: phone,
        dateOfBirth: _formatDate(_selectedDate),
        gender: _gender,
        photoBase64: _base64Avatar,
      );
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.showSuccess(
        context,
        t.t('settings_saved'),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      AppToast.showError(
        context,
        'Failed to update profile: $e',
      );
    }
  }


  Future<void> _pickAvatar() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        imageQuality: 80,
      );
      if (image == null) return;

      final bytes = await image.readAsBytes();
      final base64String = base64Encode(bytes);
      
      setState(() {
        _avatarBytes = bytes;
        _base64Avatar = 'data:image/jpeg;base64,$base64String';
      });
    } catch (e) {
      if (!mounted) return;
      AppToast.showError(context, 'Failed to pick image: $e');
    }
  }



  Future<bool?> _showDiscardDialog() {
    final t = AppLocalizations.of(context);
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Discard changes?', style: TextStyle(color: AppColors.primary)),
        content: Text('You have unsaved changes. Are you sure you want to discard them?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel', style: TextStyle(color: AppColors.outline)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Discard', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface.withValues(alpha: 0.9),
        foregroundColor: AppColors.primary,
        elevation: 0,
        centerTitle: true,
        title: Text(
          t.t('settings_edit_title'),
          style: theme.textTheme.headlineMedium?.copyWith(
            color: AppColors.primary,
            fontSize: 24,
          ),
        ),
      ),
      bottomNavigationBar: const _StaticSettingsBottomBar(),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        children: [
          Column(
            children: [
              Stack(
                children: [
                  Container(
                    width: 128,
                    height: 128,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [AppColors.secondaryContainer, AppColors.primaryFixed],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      border: Border.all(
                        color: AppColors.surfaceContainerLowest,
                        width: 4,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: ClipOval(
                      child: _avatarBytes != null
                        ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                        : (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                          ? AppNetworkImage(imageUrl: widget.photoUrl!, fit: BoxFit.cover)
                          : Text(
                              _initials(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontSize: 34,
                              ),
                            ),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Material(
                      color: AppColors.primaryContainer,
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: _pickAvatar,
                        child: Container(
                          width: 40,
                          height: 40,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.surfaceContainerLowest,
                              width: 2,
                            ),
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: AppColors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    _fullNameCtrl.text.trim().isEmpty
                        ? (widget.fullName.trim().isEmpty ? widget.userName : widget.fullName)
                        : _fullNameCtrl.text.trim(),
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppColors.primary,
                      fontSize: 24,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFD8F3DC),
                      borderRadius: BorderRadius.circular(999),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.eco, color: AppColors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          t.t('settings_profile_member_badge'),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(top: 3),
                child: Text(
                  '${_handleLabel()} • ${t.t('settings_profile_secure_account')}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.outline,
                    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) + 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _EditSectionCard(
            title: t.t('settings_edit_account_details'),
            icon: Icons.lock,
            child: Column(
              children: [
                _ReadonlyField(
                  label: t.t('settings_field_username'),
                  value: widget.userName.isEmpty ? '-' : widget.userName,
                ),
                const SizedBox(height: 16),
                _ReadonlyField(
                  label: t.t('settings_field_email'),
                  value: widget.email.isEmpty ? '-' : widget.email,
                  trailing: widget.email.isEmpty
                      ? null
                      : Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryFixed.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle, size: 12, color: AppColors.primaryContainer),
                              const SizedBox(width: 4),
                              Text(
                                t.t('settings_verified'),
                                style: theme.textTheme.labelSmall?.copyWith(
                                  color: AppColors.primaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _EditSectionCard(
            title: t.t('settings_edit_personal_information'),
            icon: Icons.person,
            child: Column(
              children: [
                _LabeledInput(
                  label: t.t('settings_field_full_name'),
                  icon: Icons.badge,
                  child: TextField(
                    controller: _fullNameCtrl,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 2,
                    ),
                    decoration: _fieldDecoration(),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledInput(
                  label: t.t('settings_field_phone'),
                  icon: Icons.phone_iphone,
                  child: TextField(
                    controller: _phoneCtrl,
                    onTapOutside: (_) => FocusScope.of(context).unfocus(),
                    keyboardType: TextInputType.phone,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 2,
                    ),
                    decoration: _fieldDecoration(),
                  ),
                ),
                const SizedBox(height: 16),
                _LabeledInput(
                  label: t.t('settings_field_date_of_birth'),
                  icon: Icons.calendar_month,
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(16),
                    child: InputDecorator(
                      decoration: _fieldDecoration(),
                      child: Text(
                        _displayDate(context),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _selectedDate == null
                              ? AppColors.outline
                              : AppColors.onSurface,
                          fontSize: (theme.textTheme.bodyMedium?.fontSize ?? 14) - 2,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    t.t('settings_field_gender'),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    border: Border.all(color: const Color(0xFFD8F3DC)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        for (final option in _genderOptions(t))
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: ChoiceChip(
                                label: Center(child: Text(option.label)),
                                selected: _gender == option.value,
                                showCheckmark: false,
                                onSelected: (_) => setState(() => _gender = option.value),
                                selectedColor: AppColors.primary,
                                backgroundColor: Colors.transparent,
                                labelStyle: theme.textTheme.labelSmall?.copyWith(
                                  color: _gender == option.value
                                      ? AppColors.onPrimary
                                      : AppColors.outline,
                                  fontWeight: FontWeight.w600,
                                ),
                                side: BorderSide.none,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.onPrimary,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.white,
                    ),
                  )
                : const Icon(Icons.save, size: 20),
            label: Text(t.t('settings_save_changes')),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              minimumSize: const Size(double.infinity, 56),
              side: BorderSide(color: AppColors.primary.withValues(alpha: 0.2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(t.t('settings_cancel')),
          ),
        ],
      ),
    ),
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFD8F3DC)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  List<_GenderOption> _genderOptions(AppLocalizations t) {
    return [
      _GenderOption(value: 'male', label: t.t('settings_gender_male')),
      _GenderOption(value: 'female', label: t.t('settings_gender_female')),
      _GenderOption(value: 'other', label: t.t('settings_gender_other')),
    ];
  }
}


class _EditSectionCard extends StatelessWidget {
  const _EditSectionCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 1, color: AppColors.surfaceContainerHighest),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _ReadonlyField extends StatelessWidget {
  const _ReadonlyField({
    required this.label,
    required this.value,
    this.trailing,
  });

  final String label;
  final String value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.outline,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({
    required this.label,
    required this.icon,
    required this.child,
  });

  final String label;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 14, right: 10),
              child: Icon(icon, color: AppColors.outline),
            ),
            Expanded(child: child),
          ],
        ),
      ],
    );
  }
}

class _GenderOption {
  const _GenderOption({required this.value, required this.label});

  final String value;
  final String label;
}

class _StaticSettingsBottomBar extends StatelessWidget {
  const _StaticSettingsBottomBar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: AbsorbPointer(
        child: Row(
          children: const [
            _StaticNavItem(icon: Icons.local_florist, label: 'Home'),
            _StaticNavItem(icon: Icons.center_focus_strong, label: 'Scan'),
            _StaticNavItem(icon: Icons.shopping_bag, label: 'Cart'),
            _StaticNavItem(icon: Icons.settings, label: 'Settings', selected: true),
          ],
        ),
      ),
    );
  }
}

class _StaticNavItem extends StatelessWidget {
  const _StaticNavItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  final IconData icon;
  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.leafGreenSoft : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: selected ? AppColors.leafGreenDark : AppColors.darkGrey,
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.leafGreenDark : AppColors.darkGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
