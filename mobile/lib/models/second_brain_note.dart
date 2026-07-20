class SecondBrainNote {
  SecondBrainNote({
    required this.id,
    required this.title,
    this.content,
    this.tags = const [],
    this.date,
    this.createdAt,
  });

  final String id;
  final String title;
  final String? content;
  final List<String> tags;
  final String? date;
  final String? createdAt;

  factory SecondBrainNote.fromJson(Map<String, dynamic> json) {
    return SecondBrainNote(
      id: json['id'] as String? ?? '',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : '(Başlıksız)',
      content: json['content'] as String?,
      tags: (json['tags'] as List<dynamic>?)?.map((t) => t.toString()).toList() ?? const [],
      date: json['date'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
