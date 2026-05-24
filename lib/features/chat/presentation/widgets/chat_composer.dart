import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/models/chat_message.dart';
import 'chat_attachment_image.dart';

class AiChatComposer extends StatelessWidget {
  const AiChatComposer({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.draftAttachment,
    required this.onToggleAttachment,
    required this.onRemoveAttachment,
    required this.onSend,
    this.replying = false,
    super.key,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final AiChatAttachment? draftAttachment;
  final VoidCallback onToggleAttachment;
  final VoidCallback onRemoveAttachment;
  final VoidCallback onSend;
  final bool replying;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface.withValues(alpha: 0.95),
            border: Border(
              top: BorderSide(color: AppColors.surfaceContainerHighest),
            ),
          ),
          child: Container(
            constraints: const BoxConstraints(minHeight: 64),
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.surfaceContainerHighest),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (draftAttachment != null) ...[
                  Padding(
                    padding: const EdgeInsets.fromLTRB(6, 2, 6, 10),
                    child: _InlineAttachmentPreview(
                      attachment: draftAttachment!,
                      onRemove: onRemoveAttachment,
                    ),
                  ),
                ],
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: replying ? null : onToggleAttachment,
                      icon: const Icon(Icons.add_circle, color: AppColors.onSurfaceVariant),
                      visualDensity: VisualDensity.compact,
                    ),
                    Expanded(
                      child: TextField(
                        controller: controller,
                        focusNode: focusNode,
                        onTapOutside: (_) => focusNode.unfocus(),
                        minLines: 1,
                        maxLines: 5,
                        textInputAction: TextInputAction.newline,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.onSurface,
                          height: 1.35,
                          fontSize:
                              (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) - 2,
                        ),
                        decoration: InputDecoration(
                          hintText: placeholder,
                          hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.onSurfaceVariant,
                            height: 1.35,
                            fontSize:
                                (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) - 2,
                          ),
                          border: InputBorder.none,
                          isCollapsed: true,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                            horizontal: 8,
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: replying ? null : onSend,
                      child: Container(
                        width: 44,
                        height: 44,
                        margin: const EdgeInsets.only(left: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primary.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: replying
                            ? const Padding(
                                padding: EdgeInsets.all(10),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.white,
                                ),
                              )
                            : const Icon(Icons.send, color: AppColors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineAttachmentPreview extends StatelessWidget {
  const _InlineAttachmentPreview({
    required this.attachment,
    required this.onRemove,
  });

  final AiChatAttachment attachment;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.surfaceContainerHighest),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: ChatAttachmentImage(
              attachment: attachment,
              fit: BoxFit.cover,
            ),
          ),
        ),
        Positioned(
          top: -5,
          right: -5,
          child: Material(
            color: AppColors.surface,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onRemove,
              customBorder: const CircleBorder(),
              child: const Padding(
                padding: EdgeInsets.all(2),
                child: Icon(
                  Icons.close,
                  size: 14,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
