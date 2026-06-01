import '../../../core/network/api_client.dart';
import '../../auth/data/storage_service.dart';
import '../domain/models/chat_message.dart';
import 'ai_chat_api.dart';

class AiChatRepository {
  AiChatRepository({AiChatApi? api}) : _api = api ?? AiChatApi(ApiClient());

  static const String fallbackSessionId = 'session_mock';

  final AiChatApi _api;

  Future<AiChatThread> loadInitialConversation({
    AiChatMockScenario scenario = AiChatMockScenario.longConversation,
  }) async {
    final userId = (await StorageService.getUserId())?.trim();
    if (userId == null || userId.isEmpty) {
      return AiChatThread(
        sessionId: fallbackSessionId,
        messages: [_buildWelcomeMessage()],
      );
    }

    try {
      final payload = await _api.fetchLatestSessionChat(userId: userId);
      final data = _toMap(payload['data']);
      final session = AiChatSession.fromApiOrNull(data['session']);
      final messages = _messagesFromApi(data['messages']);
      if (session != null) {
        return AiChatThread(
          sessionId: session.id,
          messages: messages.isEmpty ? [_buildWelcomeMessage()] : messages,
        );
      }
    } catch (_) {
      // Keep the chat usable even when history is temporarily unavailable.
    }

    return AiChatThread(
      sessionId: fallbackSessionId,
      messages: [_buildWelcomeMessage()],
    );
  }

  Future<List<AiChatSession>> fetchSessions() async {
    final userId = (await StorageService.getUserId())?.trim();
    if (userId == null || userId.isEmpty) return const <AiChatSession>[];

    final payload = await _api.fetchSessions(userId: userId);
    final data = _toMap(payload['data']);
    final rawSessions = data['sessions'];
    if (rawSessions is! List) return const <AiChatSession>[];
    return rawSessions
        .map(AiChatSession.fromApiOrNull)
        .whereType<AiChatSession>()
        .toList(growable: false);
  }

  Future<AiChatThread> loadSessionChat(String sessionId) async {
    final trimmedSessionId = sessionId.trim();
    final userId = (await StorageService.getUserId())?.trim();
    final payload = await _api.fetchMessages(
      sessionId: trimmedSessionId,
      userId: userId == null || userId.isEmpty ? null : userId,
    );
    final data = _toMap(payload['data']);
    final messages = _messagesFromApi(data['messages']);
    return AiChatThread(
      sessionId: trimmedSessionId,
      messages: messages.isEmpty ? [_buildWelcomeMessage()] : messages,
    );
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

  AiChatMessage _buildWelcomeMessage() {
    return AiChatMessage.assistantText(
      id: 'welcome-live',
      sentAt: DateTime.now(),
      text:
          'Xin chào! Mình là trợ lý AI của BigPlant. Bạn có thể hỏi về giá, tồn kho, chọn cây phù hợp, chăm sóc cây hoặc gửi ảnh cây để mình hỗ trợ nhận diện.',
    );
  }

  List<AiChatMessage> _messagesFromApi(dynamic raw) {
    if (raw is! List) return const <AiChatMessage>[];
    return raw
        .map((item) => _messageFromApi(_toMap(item)))
        .whereType<AiChatMessage>()
        .toList(growable: false);
  }

  AiChatMessage? _messageFromApi(Map<String, dynamic> raw) {
    final id = _stringValue(
      raw['id'],
      fallback: 'history-${DateTime.now().microsecondsSinceEpoch}',
    );
    final role = _stringValue(raw['role']).toLowerCase();
    final extra = _toMap(raw['extra']);
    final sentAt = _dateTimeFromApi(raw['created_at']);
    var content = _stringValue(raw['content']);

    if (role == 'user') {
      if (content.isEmpty && extra['image_detection'] != null) {
        content = 'Đã gửi một hình ảnh cây.';
      }
      return AiChatMessage.userText(
        id: id,
        sentAt: sentAt,
        text: content,
      );
    }

    if (role == 'assistant') {
      final followUp = _nullableString(extra['follow_up_message']);
      return AiChatMessage(
        id: id,
        role: AiChatRole.assistant,
        sentAt: sentAt,
        text: content,
        followUpPrompt: followUp,
        quickReplies: _stringList(extra['suggested_questions']),
      );
    }

    return null;
  }
}

class AiChatThread {
  const AiChatThread({
    required this.sessionId,
    required this.messages,
  });

  final String sessionId;
  final List<AiChatMessage> messages;
}

class AiChatSession {
  const AiChatSession({
    required this.id,
    required this.note,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String note;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  factory AiChatSession.fromApi(Map<String, dynamic> raw) {
    return AiChatSession(
      id: _stringValue(raw['id']),
      note: _stringValue(raw['note']),
      createdAt: _nullableDateTimeFromApi(raw['created_at']),
      updatedAt: _nullableDateTimeFromApi(raw['updated_at']),
    );
  }

  static AiChatSession? fromApiOrNull(dynamic raw) {
    final data = _toMap(raw);
    final id = _stringValue(data['id']);
    if (id.isEmpty) return null;
    return AiChatSession.fromApi(data);
  }

  String get displayNote => note.trim().isNotEmpty ? note.trim() : id;
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

DateTime _dateTimeFromApi(dynamic value) {
  return _nullableDateTimeFromApi(value) ?? DateTime.now();
}

DateTime? _nullableDateTimeFromApi(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
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
  return raw
      .map(_toMap)
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

Map<String, dynamic> _toMap(dynamic raw) {
  if (raw is Map<String, dynamic>) return raw;
  if (raw is Map) {
    return raw.map((key, value) => MapEntry(key.toString(), value));
  }
  return <String, dynamic>{};
}
