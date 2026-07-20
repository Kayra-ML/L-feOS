import 'package:flutter/foundation.dart';

import '../core/api_client.dart';
import '../models/chat_message.dart';

/// Z-Asistan sohbet ekranının state'i.
class ChatProvider extends ChangeNotifier {
  ChatProvider(this._api);

  final ApiClient _api;

  final List<ChatMessage> _messages = [];
  bool _isSending = false;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get isSending => _isSending;

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _messages.add(ChatMessage(role: ChatRole.user, text: trimmed));
    _isSending = true;
    notifyListeners();

    try {
      final answer = await _api.sendChatMessage(trimmed);
      _messages.add(ChatMessage(role: ChatRole.assistant, text: answer));
    } catch (e) {
      _messages.add(ChatMessage(
        role: ChatRole.assistant,
        text: 'Z-Asistan\'a ulaşılamadı: $e',
        isError: true,
      ));
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }
}
