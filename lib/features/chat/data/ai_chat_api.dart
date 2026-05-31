import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

class AiChatApi {
  AiChatApi(this._client);

  final ApiClient _client;

  Future<Map<String, dynamic>> sendMessage({
    required String message,
    required String sessionId,
    String? userId,
    AiChatImageInput? image,
  }) {
    return _client.post(
      _buildUrl('api/chat/message'),
      body: {
        'message': message,
        'session_id': sessionId,
        if (userId != null && userId.trim().isNotEmpty) 'user_id': userId.trim(),
        if (image != null) 'image': image.toJson(),
      },
      timeout: const Duration(seconds: 90),
    );
  }

  String _buildUrl(String path) {
    final base = ApiConstants.llmChatBoxBaseUrl;
    final normalizedBase = base.endsWith('/') ? base : '$base/';
    return Uri.parse('$normalizedBase$path').toString();
  }
}

class AiChatImageInput {
  const AiChatImageInput({
    this.dataUrl,
    this.base64,
    this.url,
    this.filename,
    this.contentType,
    this.mockLabel,
  });

  final String? dataUrl;
  final String? base64;
  final String? url;
  final String? filename;
  final String? contentType;
  final String? mockLabel;

  Map<String, dynamic> toJson() {
    return {
      if (dataUrl != null && dataUrl!.trim().isNotEmpty) 'data_url': dataUrl,
      if (base64 != null && base64!.trim().isNotEmpty) 'base64': base64,
      if (url != null && url!.trim().isNotEmpty) 'url': url,
      if (filename != null && filename!.trim().isNotEmpty) 'filename': filename,
      if (contentType != null && contentType!.trim().isNotEmpty)
        'content_type': contentType,
      if (mockLabel != null && mockLabel!.trim().isNotEmpty)
        'mock_label': mockLabel,
    };
  }
}
