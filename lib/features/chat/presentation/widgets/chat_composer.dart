import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/models/chat_message.dart';

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
        if (draftAttachment != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceContainerHighest),
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: AspectRatio(
                      aspectRatio: draftAttachment!.aspectRatio,
                      child: SizedBox(
                        width: 64,
                        child: AppNetworkImage(
                          imageUrl: draftAttachment!.imageUrl,
                          fit: BoxFit.cover,
                          icon: Icons.image_outlined,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      draftAttachment!.caption.isEmpty
                          ? draftAttachment!.altText
                          : draftAttachment!.caption,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.onSurfaceVariant,
                          ),
                    ),
                  ),
                  IconButton(
                    onPressed: onRemoveAttachment,
                    icon: const Icon(Icons.close, color: AppColors.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 12),
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
            child: Row(
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
                    ),
                    decoration: InputDecoration(
                      hintText: placeholder,
                      hintStyle: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.onSurfaceVariant,
                        height: 1.35,
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
          ),
        ),
      ],
    );
  }
}
