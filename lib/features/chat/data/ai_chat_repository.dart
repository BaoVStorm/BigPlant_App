import '../../../core/network/api_client.dart';
import '../../auth/data/storage_service.dart';
import '../domain/models/chat_message.dart';
import 'ai_chat_api.dart';

class AiChatRepository {
  AiChatRepository({AiChatApi? api}) : _api = api ?? AiChatApi(ApiClient());

  static const String fallbackSessionId = 'session_mock';

  final AiChatApi _api;

  Future<List<AiChatMessage>> loadInitialConversation({
    AiChatMockScenario scenario = AiChatMockScenario.longConversation,
  }) async {
    return [
      AiChatMessage.assistantText(
        id: 'welcome-live',
        sentAt: DateTime.now(),
        text:
            'Xin chào! Mình là trợ lý AI của BigPlant. Bạn có thể hỏi về giá, tồn kho, chọn cây phù hợp, chăm sóc cây hoặc gửi ảnh cây để mình hỗ trợ nhận diện.',
      ),
    ];
  }

  Future<AiChatReply> buildReplyFor(
    AiChatMessage userMessage, {
    required String sessionId,
  }) async {
    try {
      final userId = await StorageService.getUserId();
      final payload = await _api.sendMessage(
        message: userMessage.text,
        userId: userId,
        sessionId: sessionId,
        image: _imageInputFromAttachment(userMessage.attachment),
      );
      final response = AiChatResponse.fromApi(payload);
      return AiChatReply(
        sessionId: response.sessionId ?? sessionId,
        message: response.toChatMessage(),
      );
    } on ApiException catch (error) {
      return AiChatReply(
        sessionId: sessionId,
        message: _buildErrorMessage(error.message),
      );
    } catch (error) {
      return AiChatReply(
        sessionId: sessionId,
        message: _buildErrorMessage(error.toString()),
      );
    }
  }

  AiChatImageInput? _imageInputFromAttachment(AiChatAttachment? attachment) {
    if (attachment == null) return null;
    final base64Data = attachment.base64Data?.trim();
    if (base64Data == null || base64Data.isEmpty) return null;
    return AiChatImageInput(
      base64: base64Data,
      filename: attachment.fileName,
      contentType: attachment.contentType,
    );
  }

  AiChatMessage _buildErrorMessage(String detail) {
    return AiChatMessage(
      id: 'reply-error-${DateTime.now().microsecondsSinceEpoch}',
      role: AiChatRole.assistant,
      sentAt: DateTime.now(),
      text:
          'Mình chưa kết nối được BigPlant AI lúc này. Bạn thử lại sau ít phút nhé.',
      followUpPrompt: detail.trim().isNotEmpty ? detail.trim() : null,
      quickReplies: const [
        'Thử lại',
        'Tư vấn cây dễ chăm',
      ],
    );
  }
}

class AiChatReply {
  const AiChatReply({
    required this.sessionId,
    required this.message,
  });

  final String sessionId;
  final AiChatMessage message;
}

class AiChatResponse {
  const AiChatResponse({
    required this.intent,
    required this.message,
    this.sessionId,
    this.followUpMessage,
    this.suggestedQuestions = const [],
    this.products = const [],
    this.sources = const [],
    this.metadata = const {},
  });

  final String intent;
  final String message;
  final String? sessionId;
  final String? followUpMessage;
  final List<String> suggestedQuestions;
  final List<Map<String, dynamic>> products;
  final List<Map<String, dynamic>> sources;
  final Map<String, dynamic> metadata;

  factory AiChatResponse.fromApi(Map<String, dynamic> raw) {
    return AiChatResponse(
      intent: _stringValue(raw['intent'], fallback: 'general'),
      message: _stringValue(raw['message']),
      sessionId: _nullableString(raw['session_id']),
      followUpMessage: _nullableString(raw['follow_up_message']),
      suggestedQuestions: _stringList(raw['suggested_questions']),
      products: _mapList(raw['products']),
      sources: _mapList(raw['sources']),
      metadata: _toMap(raw['metadata']),
    );
  }

  AiChatMessage toChatMessage() {
    final text = message.trim().isNotEmpty
        ? message.trim()
        : 'Mình đã nhận được yêu cầu của bạn nhưng chưa có nội dung trả lời phù hợp.';
    final followUp = followUpMessage?.trim();
    return AiChatMessage(
      id: 'reply-${DateTime.now().microsecondsSinceEpoch}',
      role: AiChatRole.assistant,
      sentAt: DateTime.now(),
      text: text,
      followUpPrompt: followUp == null || followUp.isEmpty ? null : followUp,
      quickReplies: suggestedQuestions,
    );
  }
}

String _stringValue(dynamic value, {String fallback = ''}) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? fallback : text;
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

List<String> _stringList(dynamic raw) {
  if (raw is! List) return const <String>[];
  return raw
      .map((item) => item?.toString().trim() ?? '')
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

List<Map<String, dynamic>> _mapList(dynamic raw) {
  if (raw is! List) return const <Map<String, dynamic>>[];
  return raw.map(_toMap).where((item) => item.isNotEmpty).toList(growable: false);
}

Map<String, dynamic> _toMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}
