import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../domain/models/chat_message.dart';

class AiChatDayDivider extends StatelessWidget {
  const AiChatDayDivider({required this.label, super.key});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLow,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.surfaceContainerHighest),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
        ),
      ),
    );
  }
}

class AiChatTimestamp extends StatelessWidget {
  const AiChatTimestamp({
    required this.label,
    required this.alignEnd,
    this.leftInset = 0,
    this.rightInset = 0,
    super.key,
  });

  final String label;
  final bool alignEnd;
  final double leftInset;
  final double rightInset;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: leftInset, right: rightInset),
      child: Align(
        alignment: alignEnd ? Alignment.centerRight : Alignment.centerLeft,
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.outline,
              ),
        ),
      ),
    );
  }
}

class AiAssistantAvatar extends StatelessWidget {
  const AiAssistantAvatar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.secondaryContainer,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: const Icon(
        Icons.eco,
        color: AppColors.primary,
        size: 16,
      ),
    );
  }
}

class AiTextMessageBubble extends StatelessWidget {
  const AiTextMessageBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
        ),
        border: Border.all(color: AppColors.surfaceContainerHighest),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.02),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.onSurface,
              height: 1.55,
            ),
      ),
    );
  }
}

class AiInsightMessageBubble extends StatelessWidget {
  const AiInsightMessageBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 340),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
        ),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.onSurfaceVariant,
                  height: 1.55,
                ),
          ),
          if (message.insightTitle != null && message.insightTitle!.trim().isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.surfaceContainerHighest.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.water_drop, size: 18, color: AppColors.secondary),
                      const SizedBox(width: 6),
                      Text(
                        message.insightTitle!,
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: AppColors.secondary,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  for (final tip in message.checklistItems) ...[
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(
                            Icons.check_circle,
                            size: 16,
                            color: AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            tip,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppColors.onSurfaceVariant,
                                  height: 1.5,
                                ),
                          ),
                        ),
                      ],
                    ),
                    if (tip != message.checklistItems.last) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
          if (message.followUpPrompt != null && message.followUpPrompt!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              message.followUpPrompt!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class AiImageMessageBubble extends StatelessWidget {
  const AiImageMessageBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachment;
    if (attachment == null) {
      return AiTextMessageBubble(message: message);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLow,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(6),
        ),
        border: Border.all(color: AppColors.surfaceContainerHighest),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.text.trim().isNotEmpty) ...[
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onSurface,
                    height: 1.5,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: attachment.aspectRatio,
              child: Image.network(attachment.imageUrl, fit: BoxFit.cover),
            ),
          ),
          if (attachment.caption.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              attachment.caption,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.onSurfaceVariant,
                    height: 1.45,
                  ),
            ),
          ],
        ],
      ),
    );
  }
}

class UserTextMessageBubble extends StatelessWidget {
  const UserTextMessageBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Text(
        message.text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.white,
              height: 1.55,
            ),
      ),
    );
  }
}

class UserImageMessageBubble extends StatelessWidget {
  const UserImageMessageBubble({required this.message, super.key});

  final AiChatMessage message;

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachment;
    if (attachment == null) {
      return UserTextMessageBubble(message: message);
    }

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.text.trim().isNotEmpty) ...[
            Text(
              message.text,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.white,
                    height: 1.55,
                  ),
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: attachment.aspectRatio,
              child: Image.network(attachment.imageUrl, fit: BoxFit.cover),
            ),
          ),
        ],
      ),
    );
  }
}

class AiChatQuickReplies extends StatelessWidget {
  const AiChatQuickReplies({
    required this.quickReplies,
    required this.onTap,
    super.key,
  });

  final List<String> quickReplies;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    if (quickReplies.isEmpty) return const SizedBox.shrink();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < quickReplies.length; i++) ...[
            OutlinedButton(
              onPressed: () => onTap(quickReplies[i]),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                backgroundColor: AppColors.surface,
                side: const BorderSide(color: AppColors.secondaryContainer),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
              child: Text(quickReplies[i]),
            ),
            if (i != quickReplies.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class AiChatBottomNavPreview extends StatelessWidget {
  const AiChatBottomNavPreview({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context);
    return Container(
      height: 88,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          _PreviewNavItem(icon: Icons.potted_plant, label: t.t('home_tab')),
          _PreviewNavItem(icon: Icons.center_focus_strong, label: t.t('scan_tab')),
          _PreviewNavItem(icon: Icons.shopping_bag, label: t.t('cart_tab')),
          _PreviewNavItem(icon: Icons.settings, label: t.t('settings_tab')),
        ],
      ),
    );
  }
}

class _PreviewNavItem extends StatelessWidget {
  const _PreviewNavItem({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 24, color: AppColors.darkGrey),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.darkGrey,
                ),
          ),
        ],
      ),
    );
  }
}
