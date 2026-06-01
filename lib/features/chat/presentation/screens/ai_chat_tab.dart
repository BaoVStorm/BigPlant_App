import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/ai_chat_repository.dart';
import '../../domain/models/chat_message.dart';
import '../widgets/chat_composer.dart';
import '../widgets/chat_message_bubbles.dart';

class AiChatTab extends StatefulWidget {
  const AiChatTab({
    this.scenario = AiChatMockScenario.longConversation,
    this.showBottomNavPreview = true,
    this.active = true,
    super.key,
  });

  final AiChatMockScenario scenario;
  final bool showBottomNavPreview;
  final bool active;

  @override
  State<AiChatTab> createState() => _AiChatTabState();
}

class _AiChatTabState extends State<AiChatTab> {
  final AiChatRepository _repository = AiChatRepository();
  final ImagePicker _imagePicker = ImagePicker();
  final TextEditingController _composerController = TextEditingController();
  final FocusNode _composerFocusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();

  List<AiChatMessage> _messages = const [];
  AiChatAttachment? _draftAttachment;
  String _sessionId = '';
  bool _loading = true;
  bool _replying = false;
  bool _hasLoadedConversation = false;

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      _loadConversation(showLoading: false);
    } else {
      _loading = false;
    }
  }

  @override
  void didUpdateWidget(covariant AiChatTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      _handleTabActivated();
    }
  }

  @override
  void dispose() {
    _composerController.dispose();
    _composerFocusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleTabActivated() async {
    if (_replying) return;
    if (!_hasLoadedConversation || _sessionId.trim().isEmpty) {
      await _loadConversation();
      return;
    }
    await _loadSession(_sessionId, clearDraft: false, showLoading: false);
  }

  Future<void> _loadConversation({bool showLoading = true}) async {
    if (showLoading && mounted) {
      setState(() {
        _loading = true;
        _replying = false;
      });
    }

    try {
      final thread = await _repository.loadInitialConversation(
        scenario: widget.scenario,
      );
      if (!mounted) return;
      setState(() {
        _sessionId = thread.sessionId;
        _messages = thread.messages;
        _loading = false;
        _hasLoadedConversation = true;
      });
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được phiên chat mới: $error')),
      );
    }
  }

  Future<void> _toggleDraftAttachment() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 92,
    );
    if (picked == null || !mounted) return;

    final imageBytes = await picked.readAsBytes();
    final image = await decodeImageFromList(imageBytes);
    if (!mounted) return;

    setState(() {
      _draftAttachment = AiChatAttachment(
        id: 'draft-${DateTime.now().microsecondsSinceEpoch}',
        imageUrl: '',
        localFilePath: picked.path,
        base64Data: base64Encode(imageBytes),
        contentType: _guessImageContentType(picked.name),
        fileName: picked.name,
        altText: picked.name,
        aspectRatio: image.width / image.height,
        caption: picked.name,
      );
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
    if (_loading) return;

    final text = _composerController.text.trim();
    final attachment = _draftAttachment;
    if (text.isEmpty && attachment == null) return;

    if (_sessionId.trim().isEmpty) {
      await _startNewSession(clearDraft: false);
      if (!mounted || _sessionId.trim().isEmpty) return;
    }

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

    final reply = await _repository.buildReplyFor(
      userMessage,
      sessionId: _sessionId,
    );
    if (!mounted) return;
    setState(() {
      _sessionId = reply.sessionId;
      _messages = [..._messages, reply.message];
      _replying = false;
    });
    _scrollToBottom();
  }

  Future<void> _handleNewSession() async {
    await _startNewSession();
  }

  Future<void> _startNewSession({bool clearDraft = true}) async {
    setState(() {
      _loading = true;
      _replying = false;
      if (clearDraft) _draftAttachment = null;
    });

    try {
      final thread = await _repository.createSession();
      if (!mounted) return;
      setState(() {
        _sessionId = thread.sessionId;
        _messages = thread.messages;
        _loading = false;
        _hasLoadedConversation = true;
      });
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tạo được phiên chat mới: $error')),
      );
    }
  }

  Future<void> _handleSessionPicker() async {
    final sessionsFuture = _repository.fetchSessions();
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      showDragHandle: true,
      builder: (sheetContext) {
        return _SessionPickerSheet(
          sessionsFuture: sessionsFuture,
          selectedSessionId: _sessionId,
          onSessionSelected: (session) {
            Navigator.of(sheetContext).pop();
            _loadSession(session.id);
          },
        );
      },
    );
  }

  Future<void> _loadSession(
    String sessionId, {
    bool clearDraft = true,
    bool showLoading = true,
  }) async {
    if (showLoading || clearDraft) {
      setState(() {
        if (showLoading) _loading = true;
        _replying = false;
        if (clearDraft) _draftAttachment = null;
      });
    }

    try {
      final thread = await _repository.loadSessionChat(sessionId);
      if (!mounted) return;
      setState(() {
        _sessionId = thread.sessionId;
        _messages = thread.messages;
        _loading = false;
        _hasLoadedConversation = true;
      });
      _scrollToBottom(jump: true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không tải được phiên chat: $error')),
      );
    }
  }

  String _guessImageContentType(String fileName) {
    final lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) return 'image/png';
    if (lowerName.endsWith('.webp')) return 'image/webp';
    if (lowerName.endsWith('.heic')) return 'image/heic';
    if (lowerName.endsWith('.heif')) return 'image/heif';
    return 'image/jpeg';
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

  void _dismissKeyboard() {
    final currentFocus = FocusScope.of(context);
    if (!currentFocus.hasPrimaryFocus && currentFocus.focusedChild != null) {
      currentFocus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    final status = _sessionId.trim().isEmpty
        ? 'Đang chuẩn bị phiên chat'
        : '${t.t('ai_chat_status_online')} - $_sessionId';
    return Scaffold(
      backgroundColor: AppColors.backgroundTop,
      body: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: _dismissKeyboard,
        child: Column(
          children: [
            _ChatHeader(
              onNewSession: () {
                _handleNewSession();
              },
              onSessionPicker: () {
                _handleSessionPicker();
              },
              title: t.t('ai_chat_title'),
              status: status,
            ),
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
                          return Padding(
                            padding: EdgeInsets.only(bottom: 24),
                            child: AiChatDayDivider(label: t.t('ai_chat_day_today')),
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
              placeholder: t.t('ai_chat_placeholder'),
              draftAttachment: _draftAttachment,
              onToggleAttachment: _toggleDraftAttachment,
              onRemoveAttachment: _removeDraftAttachment,
              onSend: _sendCurrentDraft,
              replying: _replying,
            ),
            if (widget.showBottomNavPreview) const AiChatBottomNavPreview(),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.onNewSession,
    required this.onSessionPicker,
    required this.title,
    required this.status,
  });

  final VoidCallback onNewSession;
  final VoidCallback onSessionPicker;
  final String title;
  final String status;

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
                    title,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontSize: 24,
                        ),
                  ),
                  Text(
                    status,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onNewSession,
              tooltip: 'Tạo phiên chat mới',
              icon: const Icon(Icons.add, color: AppColors.onSurfaceVariant),
            ),
            IconButton(
              onPressed: onSessionPicker,
              tooltip: 'Chọn phiên chat',
              icon: const Icon(Icons.history, color: AppColors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionPickerSheet extends StatelessWidget {
  const _SessionPickerSheet({
    required this.sessionsFuture,
    required this.selectedSessionId,
    required this.onSessionSelected,
  });

  final Future<List<AiChatSession>> sessionsFuture;
  final String selectedSessionId;
  final ValueChanged<AiChatSession> onSessionSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.58,
        child: FutureBuilder<List<AiChatSession>>(
          future: sessionsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Không tải được danh sách phiên chat.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final sessions = snapshot.data ?? const <AiChatSession>[];
            if (sessions.isEmpty) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    'Chưa có phiên chat nào.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: sessions.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: AppColors.surfaceContainerHighest,
              ),
              itemBuilder: (context, index) {
                final session = sessions[index];
                final selected = session.id == selectedSessionId;
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 6,
                  ),
                  leading: Icon(
                    selected ? Icons.check_circle : Icons.history,
                    color: selected
                        ? AppColors.primary
                        : AppColors.onSurfaceVariant,
                  ),
                  title: Text(
                    session.displayNote,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                        ),
                  ),
                  subtitle: Text(
                    _formatSessionDate(session.updatedAt ?? session.createdAt),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.outline,
                        ),
                  ),
                  onTap: () => onSessionSelected(session),
                );
              },
            );
          },
        ),
      ),
    );
  }

  String _formatSessionDate(DateTime? value) {
    if (value == null) return 'Không rõ thời gian';
    final day = value.day.toString().padLeft(2, '0');
    final month = value.month.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '$day/$month/${value.year} $hour:$minute';
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
