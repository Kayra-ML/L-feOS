enum ChatRole { user, assistant }

class ChatMessage {
  ChatMessage({required this.role, required this.text, this.isError = false});

  final ChatRole role;
  final String text;
  final bool isError;
}
