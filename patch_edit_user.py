import re

with open('/home/bigplants/BigPlantsApp/BigPlant_App/lib/features/shop/presentation/screens/edit_user_screen.dart', 'r') as f:
    content = f.read()

# Add imports
imports = """import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_globals.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';
import '../../../auth/domain/auth_service.dart';
"""
content = re.sub(r'import \'package:flutter/material\.dart\';\n\nimport \'\.\./\.\./\.\./\.\./core/constants/app_colors\.dart\';\nimport \'\.\./\.\./\.\./\.\./core/localization/app_localizations\.dart\';\nimport \'\.\./\.\./\.\./\.\./core/widgets/app_toast\.dart\';\nimport \'\.\./\.\./\.\./auth/domain/auth_service\.dart\';', imports, content)

# Add photoUrl parameter
content = content.replace("    required this.gender,", "    required this.gender,\n    this.photoUrl,")
content = content.replace("  final String gender;", "  final String gender;\n  final String? photoUrl;")

# Add states & isDirty
states = """  late final TextEditingController _fullNameCtrl;
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
  }"""
content = re.sub(r'  late final TextEditingController _fullNameCtrl;[\s\S]*?bool _saving = false;', states, content)

# Remove _showAvatarMessage and add _pickAvatar
pick_avatar = """
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
"""
content = re.sub(r'  void _showAvatarMessage\(\) \{[\s\S]*?\}', pick_avatar, content)

# Add isDirty checking before pop
pop_scope = """    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showDiscardDialog();
        if (shouldPop == true && mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold("""
content = content.replace("    return Scaffold(", pop_scope)

# Add _showDiscardDialog function
discard_dialog = """
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
  Widget build(BuildContext context) {"""
content = content.replace("  @override\n  Widget build(BuildContext context) {", discard_dialog)

# Close PopScope
content = content.replace("    );\n  }\n}\n\nclass _EditSectionCard", "    ),\n    );\n  }\n}\n\nclass _EditSectionCard")

# Replace Avatar render
avatar_render = """                    child: ClipOval(
                      child: _avatarBytes != null
                        ? Image.memory(_avatarBytes!, fit: BoxFit.cover)
                        : (widget.photoUrl != null && widget.photoUrl!.isNotEmpty)
                          ? AppNetworkImage(url: widget.photoUrl!, fit: BoxFit.cover)
                          : Text(
                              _initials(),
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: AppColors.primary,
                                fontSize: 34,
                              ),
                            ),
                    ),"""
content = re.sub(r'                    child: Text\(\s*_initials\(\),\s*style: theme\.textTheme\.titleLarge\?\.copyWith\([\s\S]*?\),\s*\),', avatar_render, content)

# Replace _showAvatarMessage in onTap
content = content.replace("onTap: _showAvatarMessage,", "onTap: _pickAvatar,")

# Update _save method to pass _base64Avatar
save_method = """      await authService.updateProfile(
        fullName: _fullNameCtrl.text.trim(),
        phoneNumber: phone,
        dateOfBirth: _formatDate(_selectedDate),
        gender: _gender,
        photoBase64: _base64Avatar,
      );"""
content = re.sub(r'      await authService\.updateProfile\([\s\S]*?gender: _gender,\n      \);', save_method, content)

# Update Save Button
save_button = """              AuthPrimaryButton(
                label: t.t('settings_save_changes'),
                loading: _saving,
                onPressed: (!_isDirty || _saving) ? null : _save,
              ),"""
content = re.sub(r'              AuthPrimaryButton\(\s*label: t\.t\(\'settings_save_changes\'\),\s*loading: _saving,\s*onPressed: _save,\s*\),', save_button, content)

with open('/home/bigplants/BigPlantsApp/BigPlant_App/lib/features/shop/presentation/screens/edit_user_screen.dart', 'w') as f:
    f.write(content)
