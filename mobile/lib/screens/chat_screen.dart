import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../providers/chat_provider.dart';
import '../widgets/chat_bubble.dart';

/// Z-Asistan için ayrı, tam ekran sohbet sayfası.
/// Ana sidebar'daki/AppBar'daki kısayoldan açılır (bkz. home_shell.dart).
class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _inputCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _inputCtrl.text;
    if (text.trim().isEmpty) return;
    _inputCtrl.clear();
    await context.read<ChatProvider>().send(text);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    final chat = context.watch<ChatProvider>();
    _scrollToBottom();

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: const [
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.aiPurple,
              child: Icon(Icons.auto_awesome_rounded, size: 14, color: Colors.white),
            ),
            SizedBox(width: 10),
            Text('Z-Asistan'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: chat.messages.isEmpty
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Z-Asistan\'a görevlerin, günlüklerin ya da notların hakkında soru sorabilirsin.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.textDim),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(14),
                    itemCount: chat.messages.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: ChatBubble(message: chat.messages[i]),
                    ),
                  ),
          ),
          if (chat.isSending)
            const Padding(
              padding: EdgeInsets.only(bottom: 6),
              child: Text('Z-Asistan yazıyor...', style: TextStyle(color: AppColors.textDim, fontSize: 12)),
            ),
          SafeArea(
            top: false,
            child: Container(
              margin: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.panel2,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _inputCtrl,
                      minLines: 1,
                      maxLines: 4,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        filled: false,
                        hintText: 'Z-Asistan\'a bir şey sor...',
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: chat.isSending ? null : _send,
                    icon: const Icon(Icons.send_rounded, color: AppColors.aiPurple),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
