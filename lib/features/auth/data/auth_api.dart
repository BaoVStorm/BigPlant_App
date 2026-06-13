import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AuthApi {
  AuthApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) {
    return _client.post(
      '${ApiConstants.baseUrl}api/auth/login',
      body: {'user_name': username, 'password': password},
    );
  }

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String phone,
    required String password,
  }) {
    return _client.post(
      '${ApiConstants.baseUrl}api/auth/register',
      body: {
        'user_name': username,
        'email': email,
        'phone_number': phone,
        'password': password,
      },
    );
  }

  Future<Map<String, dynamic>> verifyToken(String token) {
    return _client.get(
      '${ApiConstants.baseUrl}api/auth/verify',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>> logout(String token) {
    return _client.get(
      '${ApiConstants.baseUrl}api/auth/logout',
      headers: {'Authorization': 'Bearer $token'},
    );
  }

  Future<Map<String, dynamic>> resendRegisterOtp(String email) {
    return _client.post(
      '${ApiConstants.baseUrl}api/email_verification/',
      body: {'email': email},
    );
  }

  Future<Map<String, dynamic>> verifyRegisterOtp({
    required String email,
    required String otp,
  }) {
    return _client.post(
      '${ApiConstants.baseUrl}api/email_verification/verify',
      body: {'email': email, 'otp': otp},
    );
  }

  Future<Map<String, dynamic>> forgotPassword(String email) {
    return _client.post(
      '${ApiConstants.baseUrl}api/forgot_password/',
      body: {'email': email},
    );
  }

  Future<Map<String, dynamic>> verifyForgotOtp({
    required String email,
    required String otp,
  }) {
    return _client.post(
      '${ApiConstants.baseUrl}api/forgot_password/check_valid_digit',
      body: {'email': email, 'otp': otp},
    );
  }

  Future<Map<String, dynamic>> resetForgotPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) {
    return _client.post(
      '${ApiConstants.baseUrl}api/forgot_password/reset',
      body: {'email': email, 'otp': otp, 'newPassword': newPassword},
    );
  }

  Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? fullName,
    String? phoneNumber,
    String? dateOfBirth,
    String? gender,
    String? photoBase64,
  }) {
    return _client.put(
      '${ApiConstants.baseUrl}api/auth/update-profile',
      headers: {'Authorization': 'Bearer $token'},
      body: {
        if (fullName != null) 'full_name': fullName,
        if (phoneNumber != null) 'phone_number': phoneNumber,
        if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
        if (gender != null) 'gender': gender,
        if (photoBase64 != null) 'photo_base64': photoBase64,
      },
    );
  }
}
