class Journal {
  Journal({
    required this.id,
    required this.content,
    this.category,
    this.date,
    this.time,
    this.createdAt,
  });

  final String id;
  final String content;
  final String? category;
  final String? date; // YYYY-MM-DD
  final String? time; // HH:MM
  final String? createdAt;

  factory Journal.fromJson(Map<String, dynamic> json) {
    return Journal(
      id: json['id'] as String? ?? '',
      content: (json['content'] as String?)?.trim().isNotEmpty == true
          ? json['content'] as String
          : '(Başlıksız)',
      category: json['category'] as String?,
      date: json['date'] as String?,
      time: json['time'] as String?,
      createdAt: json['createdAt'] as String?,
    );
  }
}
