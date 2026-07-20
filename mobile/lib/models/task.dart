class Task {
  Task({
    required this.id,
    required this.title,
    required this.isDone,
    this.type,
    this.priority,
    this.date,
  });

  final String id;
  final String title;
  final bool isDone;
  final String? type;
  final String? priority;
  final String? date; // YYYY-MM-DD

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id'] as String? ?? '',
      title: (json['title'] as String?)?.trim().isNotEmpty == true
          ? json['title'] as String
          : '(Başlıksız)',
      isDone: json['is_done'] as bool? ?? false,
      type: json['type'] as String?,
      priority: json['priority'] as String?,
      date: json['date'] as String?,
    );
  }

  Task copyWith({bool? isDone}) => Task(
        id: id,
        title: title,
        isDone: isDone ?? this.isDone,
        type: type,
        priority: priority,
        date: date,
      );
}
