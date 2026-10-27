/// Represents a practical tip or checklist reminder for nomadtrip.
class TripTip {
  final int? id;
  final String
  category; // 'toll', 'ticket', 'dining', 'shopping', 'pitstop', 'timing', 'airport'
  final String title;
  final String content;
  final bool isCompleted;

  const TripTip({
    this.id,
    required this.category,
    required this.title,
    required this.content,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'category': category,
      'title': title,
      'content': content,
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory TripTip.fromMap(Map<String, dynamic> map) {
    return TripTip(
      id: map['id'] as int?,
      category: map['category'] as String,
      title: map['title'] as String,
      content: map['content'] as String,
      isCompleted: (map['is_completed'] as int?) == 1,
    );
  }

  TripTip copyWith({
    int? id,
    String? category,
    String? title,
    String? content,
    bool? isCompleted,
  }) {
    return TripTip(
      id: id ?? this.id,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
