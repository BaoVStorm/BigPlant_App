enum AiChatRole { assistant, user }

enum AiChatMockScenario { shortConversation, longConversation }

class AiChatAttachment {
  const AiChatAttachment({
    required this.id,
    required this.imageUrl,
    required this.altText,
    this.aspectRatio = 1,
    this.caption = '',
  });

  final String id;
  final String imageUrl;
  final String altText;
  final double aspectRatio;
  final String caption;
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.sentAt,
    required this.text,
    this.attachment,
    this.insightTitle,
    this.checklistItems = const [],
    this.followUpPrompt,
    this.quickReplies = const [],
  });

  final String id;
  final AiChatRole role;
  final DateTime sentAt;
  final String text;
  final AiChatAttachment? attachment;
  final String? insightTitle;
  final List<String> checklistItems;
  final String? followUpPrompt;
  final List<String> quickReplies;

  bool get hasAttachment => attachment != null;
  bool get hasStructuredAdvice =>
      (insightTitle?.trim().isNotEmpty ?? false) ||
      checklistItems.isNotEmpty ||
      (followUpPrompt?.trim().isNotEmpty ?? false);

  bool get isAssistant => role == AiChatRole.assistant;
  bool get isUser => role == AiChatRole.user;

  factory AiChatMessage.userText({
    required String id,
    required DateTime sentAt,
    required String text,
  }) {
    return AiChatMessage(
      id: id,
      role: AiChatRole.user,
      sentAt: sentAt,
      text: text,
    );
  }

  factory AiChatMessage.userImage({
    required String id,
    required DateTime sentAt,
    required String text,
    required AiChatAttachment attachment,
  }) {
    return AiChatMessage(
      id: id,
      role: AiChatRole.user,
      sentAt: sentAt,
      text: text,
      attachment: attachment,
    );
  }

  factory AiChatMessage.assistantText({
    required String id,
    required DateTime sentAt,
    required String text,
  }) {
    return AiChatMessage(
      id: id,
      role: AiChatRole.assistant,
      sentAt: sentAt,
      text: text,
    );
  }

  factory AiChatMessage.assistantInsight({
    required String id,
    required DateTime sentAt,
    required String text,
    required String insightTitle,
    required List<String> checklistItems,
    required String followUpPrompt,
    List<String> quickReplies = const [],
  }) {
    return AiChatMessage(
      id: id,
      role: AiChatRole.assistant,
      sentAt: sentAt,
      text: text,
      insightTitle: insightTitle,
      checklistItems: checklistItems,
      followUpPrompt: followUpPrompt,
      quickReplies: quickReplies,
    );
  }

  AiChatMessage copyWith({
    String? id,
    AiChatRole? role,
    DateTime? sentAt,
    String? text,
    AiChatAttachment? attachment,
    String? insightTitle,
    List<String>? checklistItems,
    String? followUpPrompt,
    List<String>? quickReplies,
  }) {
    return AiChatMessage(
      id: id ?? this.id,
      role: role ?? this.role,
      sentAt: sentAt ?? this.sentAt,
      text: text ?? this.text,
      attachment: attachment ?? this.attachment,
      insightTitle: insightTitle ?? this.insightTitle,
      checklistItems: checklistItems ?? this.checklistItems,
      followUpPrompt: followUpPrompt ?? this.followUpPrompt,
      quickReplies: quickReplies ?? this.quickReplies,
    );
  }
}
