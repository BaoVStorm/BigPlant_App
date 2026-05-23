import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/mock_ai_chat_repository.dart';
import '../../domain/models/chat_message.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_message_bubbles.dart';

class AiChatTab extends StatefulWidget {
  const AiChatTab({
    this.scenario = AiChatMockScenario.longConversation,
    this.showBottomNavPreview = true,
    super.key,
  });

  final AiChatMockScenario scenario;
  final bool showBottomNavPreview;

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final MockAiChatRepository _repository = MockAiChatRepository();
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<AiChatMessage> _messages = const [];
  AiChatAttachment? _draftAttachment;
  bool _loading = true;
  bool _replying = false;

  @override
  void initState() {
    super.initState();
    _loadConversation();
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadConversation() async {
    final thread = await _repository.loadInitialConversation(
      scenario: widget.scenario,
    );
    if (!mounted) return;
    setState(() {
      _messages = thread;
      _loading = false;
    });
    _scrollToBottom(jump: true);
  }

  void _toggleDraftAttachment() {
    setState(() {
      _draftAttachment = _draftAttachment == null
          ? _repository.buildMockAttachment()
          : null;
    });
  }

  void _removeDraftAttachment() {
    setState(() => _draftAttachment = null);
  }

  Future<void> _sendQuickReply(String text) async {
    _composerController.text = text;
    await _sendCurrentDraft();
  }

  Future<void> _sendCurrentDraft() async {
    final text = _composerController.text.trim();
    final attachment = _draftAttachment;
    if (text.isEmpty && attachment == null) return;

    final userMessage = attachment == null
        ? AiChatMessage.userText(
            id: 'user-${DateTime.now().microsecondsSinceEpoch}',
            sentAt: DateTime.now(),
            text: text,
          )
        : AiChatMessage.userImage(
            id: 'user-${DateTime.now().microsecondsSinceEpoch}',
            sentAt: DateTime.now(),
            text: text,
            attachment: attachment,
          );

    setState(() {
      _messages = [..._messages, userMessage];
      _composerController.clear();
      _draftAttachment = null;
      _replying = true;
    });
    _scrollToBottom();

    final reply = await _repository.buildReplyFor(userMessage);
    if (!mounted) return;
    setState(() {
      _messages = [..._messages, reply];
      _replying = false;
    });
    _scrollToBottom();
  }

  void _handleBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('AI Chat tab is built but not wired into app navigation yet.'),
      ),
    );
  }

  void _handleMore() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('More actions are not wired yet.')),
    );
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      final target = _scrollController.position.maxScrollExtent;
      if (jump) {
        _scrollController.jumpTo(target);
        return;
      }
      _scrollController.animateTo(
        target,
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOut,
      );
    });
  }

  String _formatTimestamp(DateTime value) {
    final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
    final minute = value.minute.toString().padLeft(2, '0');
    final meridiem = value.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $meridiem';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundTop,
      body: Column(
        children: [
          _ChatHeader(onBack: _handleBack, onMore: _handleMore),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    itemCount: _messages.length + 1,
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 24),
                          child: AiChatDayDivider(label: 'Today'),
                        );
                      }
                      final message = _messages[index - 1];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 18),
                        child: _ChatMessageBlock(
                          message: message,
                          timestamp: _formatTimestamp(message.sentAt),
                          onQuickReplyTap: _sendQuickReply,
                        ),
                      );
                    },
                  ),
          ),
          AiChatComposer(
            controller: _composerController,
            focusNode: _composerFocusNode,
            placeholder: 'Nhắn tin cho BigPlant AI...',
            draftAttachment: _draftAttachment,
            onToggleAttachment: _toggleDraftAttachment,
            onRemoveAttachment: _removeDraftAttachment,
            onSend: _sendCurrentDraft,
            replying: _replying,
          ),
          if (widget.showBottomNavPreview) const AiChatBottomNavPreview(),
        ],
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.onBack, required this.onMore});

  final VoidCallback onBack;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.9),
          border: Border(bottom: BorderSide(color: AppColors.surfaceContainerHighest)),
        ),
        child: Row(
          children: [
            IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back, color: AppColors.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: AppColors.secondaryContainer,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.psychology, color: AppColors.primary),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'BigPlant AI',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 24,
                        ),
                  ),
                  Text(
                    'Online',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onMore,
              icon: const Icon(Icons.more_vert, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatMessageBlock extends StatelessWidget {
  const _ChatMessageBlock({
    required this.message,
    required this.timestamp,
    required this.onQuickReplyTap,
  });

  final AiChatMessage message;
  final String timestamp;
  final ValueChanged<String> onQuickReplyTap;

  @override
  Widget build(BuildContext context) {
    if (message.isAssistant) {
      return Align(
        alignment: Alignment.centerLeft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const AiAssistantAvatar(),
                const SizedBox(width: 8),
                Flexible(
                  child: message.hasAttachment
                      ? AiImageMessageBubble(message: message)
                      : message.hasStructuredAdvice
                          ? AiInsightMessageBubble(message: message)
                          : AiTextMessageBubble(message: message),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AiChatTimestamp(label: timestamp, alignEnd: false, leftInset: 40),
            if (message.quickReplies.isNotEmpty) ...[
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.only(left: 40),
                child: AiChatQuickReplies(
                  quickReplies: message.quickReplies,
                  onTap: onQuickReplyTap,
                ),
              ),
            ],
          ],
        ),
      );
    }

    return Align(
      alignment: Alignment.centerRight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          message.hasAttachment
              ? UserImageMessageBubble(message: message)
              : UserTextMessageBubble(message: message),
          const SizedBox(height: 6),
          AiChatTimestamp(label: timestamp, alignEnd: true, rightInset: 8),
        ],
      ),
    );
  }
}
