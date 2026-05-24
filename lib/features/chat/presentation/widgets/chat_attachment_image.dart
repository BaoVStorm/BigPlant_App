import 'dart:io';

import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_network_image.dart';
import '../../domain/models/chat_message.dart';

class ChatAttachmentImage extends StatelessWidget {
  const ChatAttachmentImage({
    required this.attachment,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    super.key,
  });

  final AiChatAttachment attachment;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    if (attachment.isLocalFile) {
      return Image.file(
        File(attachment.localFilePath!),
        fit: fit,
        width: width,
        height: height,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.secondaryContainer, AppColors.primaryFixed],
              ),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          );
        },
      );
    }

    return AppNetworkImage(
      imageUrl: attachment.imageUrl,
      fit: fit,
      width: width,
      height: height,
      icon: Icons.image_outlined,
    );
  }
}
