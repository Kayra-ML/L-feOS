import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../core/theme.dart';
import '../models/chat_message.dart';

class ChatBubble extends StatelessWidget {
  const ChatBubble({super.key, required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final isUser = message.role == ChatRole.user;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.aiPurple,
              child: Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
            ),
            const SizedBox(width: 8),
          ],
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.74),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: isUser
                    ? const LinearGradient(colors: [AppColors.aiPurple, AppColors.aiPurpleDark])
                    : null,
                color: isUser
                    ? null
                    : (message.isError ? AppColors.danger.withOpacity(.12) : AppColors.panel2),
                border: isUser ? null : Border.all(color: AppColors.line),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(14),
                  topRight: const Radius.circular(14),
                  bottomLeft: Radius.circular(isUser ? 14 : 3),
                  bottomRight: Radius.circular(isUser ? 3 : 14),
                ),
              ),
              child: isUser
                  ? Text(message.text, style: const TextStyle(color: Colors.white))
                  : MarkdownBody(
                      data: message.text,
                      selectable: true,
                      styleSheet: MarkdownStyleSheet(
                        p: const TextStyle(color: AppColors.text, fontSize: 14, height: 1.35),
                        strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                        listBullet: const TextStyle(color: AppColors.textDim),
                        code: const TextStyle(
                          backgroundColor: AppColors.bg,
                          color: AppColors.success,
                          fontSize: 12.5,
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
