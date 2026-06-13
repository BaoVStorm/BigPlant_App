import re

with open('/home/bigplants/BigPlantsApp/BigPlant_App/lib/features/shop/presentation/screens/settings_tab.dart', 'r') as f:
    content = f.read()

# Add import
imports = """import '../../../../core/routing/app_router.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../../../core/widgets/app_toast.dart';"""
content = content.replace("import '../../../../core/routing/app_router.dart';\nimport '../../../../core/widgets/app_toast.dart';", imports)

# Add _photoUrl state
content = content.replace("  String _gender = 'unknown';", "  String _gender = 'unknown';\n  String? _photoUrl;")

# Load photoUrl
load_state = """    final notifyDeals = await StorageService.getNotifyDeals();
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
    });"""
content = re.sub(r'    final notifyDeals = await StorageService\.getNotifyDeals\(\);\n    final notifyPlantTips = await StorageService\.getNotifyPlantTips\(\);\n\n    if \(!mounted\) return;\n    setState\(\{\n      _displayName = fullName\.isNotEmpty[\s\S]*?_plantCareTips = notifyPlantTips;\n    \}\);', load_state, content)

# Pass photoUrl to EditUserScreen
edit_user = """          dateOfBirth: _dateOfBirth,
          gender: _gender,
          photoUrl: _photoUrl,
        ),"""
content = content.replace("          dateOfBirth: _dateOfBirth,\n          gender: _gender,\n        ),", edit_user)

# Pass photoUrl to _SettingsProfileCard usage
profile_usage = """            _SettingsProfileCard(
              displayName: _displayName,
              email: _displayEmail,
              initials: _initials(),
              photoUrl: _photoUrl,
              onTap: _openEditUser,
            ),"""
content = re.sub(r'            _SettingsProfileCard\(\n              displayName: _displayName,\n              email: _displayEmail,\n              initials: _initials\(\),\n              onTap: _openEditUser,\n            \),', profile_usage, content)

# Add photoUrl to _SettingsProfileCard class
card_class = """class _SettingsProfileCard extends StatelessWidget {
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
  final String? photoUrl;"""
content = re.sub(r'class _SettingsProfileCard extends StatelessWidget \{\n  const _SettingsProfileCard\(\{\n    required this\.displayName,\n    required this\.email,\n    required this\.initials,\n    required this\.onTap,\n  \}\);\n\n  final String displayName;\n  final String email;\n  final String initials;\n  final VoidCallback onTap;', card_class, content)

# Render Avatar
avatar_render = """              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [AppColors.secondaryContainer, AppColors.primaryFixed],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(color: AppColors.surfaceContainerHigh, width: 2),
                ),
                alignment: Alignment.center,
                child: ClipOval(
                  child: (photoUrl != null && photoUrl!.isNotEmpty)
                    ? AppNetworkImage(url: photoUrl!, fit: BoxFit.cover, width: 64, height: 64)
                    : Text(
                        initials,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 20,
                        ),
                      ),
                ),
              ),"""
content = re.sub(r'              Container\(\n                width: 64,\n                height: 64,\n                decoration: BoxDecoration\([\s\S]*?\),\n                alignment: Alignment\.center,\n                child: Text\(\n                  initials,\n                  style: Theme\.of\(context\)\.textTheme\.headlineMedium\?\.copyWith\([\s\S]*?\),\n                \),\n              \),', avatar_render, content)

with open('/home/bigplants/BigPlantsApp/BigPlant_App/lib/features/shop/presentation/screens/settings_tab.dart', 'w') as f:
    f.write(content)
