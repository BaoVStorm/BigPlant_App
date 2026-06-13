import '../../../core/network/api_client.dart';
import '../data/auth_api.dart';
import '../data/storage_service.dart';

class AuthService {
  AuthService({AuthApi? authApi}) : _authApi = authApi ?? AuthApi(ApiClient());

  final AuthApi _authApi;

  Future<void> _persistAuthResponse(Map<String, dynamic> response) async {
    final token = response['token']?.toString() ?? '';
    final userId = response['user_id']?.toString() ?? '';
    if (token.isNotEmpty && userId.isNotEmpty) {
      await StorageService.saveAuth(token: token, userId: userId);
    }

    final user = response['user'];
    if (user is Map) {
      await StorageService.saveUserProfile(
        userName: user['user_name']?.toString(),
        fullName: user['full_name']?.toString(),
        email: user['email']?.toString(),
        phoneNumber: user['phone_number']?.toString(),
        dateOfBirth: user['date_of_birth']?.toString(),
        gender: user['gender']?.toString(),
      );
    }
  }

  Future<void> login({
    required String username,
    required String password,
  }) async {
    final response = await _authApi.login(
      username: username,
      password: password,
    );
    await _persistAuthResponse(response);
  }

  Future<void> register({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) async {
    final response = await _authApi.register(
      username: username,
      email: email,
      phone: phone,
      password: password,
    );
    await _persistAuthResponse(response);
  }

  Future<void> verifyRegisterOtp({required String email, required String otp}) {
    return _authApi.verifyRegisterOtp(email: email, otp: otp);
  }

  Future<void> resendRegisterOtp(String email) {
    return _authApi.resendRegisterOtp(email);
  }

  Future<void> forgotPassword(String email) {
    return _authApi.forgotPassword(email);
  }

  Future<void> verifyForgotOtp({required String email, required String otp}) {
    return _authApi.verifyForgotOtp(email: email, otp: otp);
  }

  Future<void> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    final response = await _authApi.resetForgotPassword(
      email: email,
      otp: otp,
      newPassword: newPassword,
    );
    await _persistAuthResponse(response);
  }

  Future<void> logout({bool notifyServer = true}) async {
    final token = await StorageService.getToken();
    if (notifyServer && token != null && token.isNotEmpty) {
      try {
        await _authApi.logout(token);
      } on ApiException {
        // Keep local logout behavior even if server logout fails.
      } catch (_) {
        // Keep local logout behavior even if server logout fails.
      }
    }
    await StorageService.clearAuth();
  }

  Future<bool> verifyExistingToken() async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty || token == 'null') {
      await StorageService.clearAuth();
      return false;
    }
    try {
      final response = await _authApi.verifyToken(token);
      if (response['success'] == true) {
        final userId = response['user_id']?.toString() ?? '';
        if (userId.isNotEmpty) {
          await StorageService.saveAuth(token: token, userId: userId);
        }
        final user = response['user'];
        if (user is Map) {
          await StorageService.saveUserProfile(
            userName: user['user_name']?.toString(),
            fullName: user['full_name']?.toString(),
            email: user['email']?.toString(),
            phoneNumber: user['phone_number']?.toString(),
            dateOfBirth: user['date_of_birth']?.toString(),
            gender: user['gender']?.toString(),
            photoUrl: user['photo_url']?.toString(),
          );
        }
        return true;
      }
      await StorageService.clearAuth();
      return false;
    } on ApiException {
      await StorageService.clearAuth();
      return false;
    } catch (_) {
      await StorageService.clearAuth();
      return false;
    }
  }

  Future<void> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? photoBase64,
  }) async {
    final token = await StorageService.getToken();
    if (token == null || token.isEmpty) {
      throw Exception('Authentication token not found');
    }

    final response = await _authApi.updateProfile(
      token: token,
      fullName: fullName,
      phoneNumber: phoneNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      photoBase64: photoBase64,
    );

    await _persistAuthResponse(response);
  }
}
