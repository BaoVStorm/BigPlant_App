import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _tokenKey = 'token';
  static const _userIdKey = 'user_id';
  static const _userNameKey = 'user_name';
  static const _fullNameKey = 'full_name';
  static const _emailKey = 'email';
  static const _phoneNumberKey = 'phone_number';
  static const _dateOfBirthKey = 'date_of_birth';
  static const _genderKey = 'gender';
  static const _photoUrlKey = 'photo_url';
  static const _languageKey = 'language_code';
  static const _scanLocalModelKey = 'scan.local.selected_model';
  static const _notifyDealsKey = 'settings.notify_deals';
  static const _notifyPlantTipsKey = 'settings.notify_plant_tips';

  static Future<void> saveAuth({
    required String token,
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userIdKey, userId);
  }

  static Future<void> saveUserProfile({
    String? userName,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? photoUrl,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    if (userName != null) {
      await prefs.setString(_userNameKey, userName);
    }
    if (fullName != null) {
      await prefs.setString(_fullNameKey, fullName);
    }
    if (email != null) {
      await prefs.setString(_emailKey, email);
    }
    if (phoneNumber != null) {
      await prefs.setString(_phoneNumberKey, phoneNumber);
    }
    if (dateOfBirth != null) {
      await prefs.setString(_dateOfBirthKey, dateOfBirth);
    }
    if (gender != null) {
      await prefs.setString(_genderKey, gender);
    }
    if (photoUrl != null) {
      await prefs.setString(_photoUrlKey, photoUrl);
    }
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userIdKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getFullName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_fullNameKey);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_phoneNumberKey);
  }

  static Future<String?> getDateOfBirth() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dateOfBirthKey);
  }

  static Future<String?> getGender() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_genderKey);
  }

  static Future<String?> getPhotoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoUrlKey);
  }

  static Future<void> clearAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userIdKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_fullNameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_phoneNumberKey);
    await prefs.remove(_dateOfBirthKey);
    await prefs.remove(_genderKey);
    await prefs.remove(_photoUrlKey);
  }

  static Future<void> setLanguageCode(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  static Future<String?> getLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }

  static Future<void> setScanLocalModel(String modelId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_scanLocalModelKey, modelId);
  }

  static Future<String?> getScanLocalModel() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_scanLocalModelKey);
  }

  static Future<void> setNotifyDeals(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyDealsKey, value);
  }

  static Future<bool> getNotifyDeals() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifyDealsKey) ?? true;
  }

  static Future<void> setNotifyPlantTips(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifyPlantTipsKey, value);
  }

  static Future<bool> getNotifyPlantTips() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifyPlantTipsKey) ?? true;
  }
}
