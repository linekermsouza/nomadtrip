import 'trip_day.dart';

/// Represents a practical tip or checklist reminder for nomadtrip.
class TripTip {
  final int? id;
  final int tripId;
  final int dayNumber; // 0 = general / applies to all days, >0 = specific day
  final String
  category; // 'toll', 'ticket', 'dining', 'shopping', 'pitstop', 'timing', 'airport', 'general'
  final String title;
  final String content;
  final bool isCompleted;

  const TripTip({
    this.id,
    this.tripId = 0,
    this.dayNumber = 0,
    required this.category,
    required this.title,
    required this.content,
    this.isCompleted = false,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'day_number': dayNumber,
      'category': category,
      'title': cleanMarkdownDecorations(title),
      'content': cleanMarkdownDecorations(content),
      'is_completed': isCompleted ? 1 : 0,
    };
  }

  factory TripTip.fromMap(Map<String, dynamic> map) {
    return TripTip(
      id: (map['id'] as num?)?.toInt(),
      tripId: (map['trip_id'] as num?)?.toInt() ?? 0,
      dayNumber: (map['day_number'] as num?)?.toInt() ?? 0,
      category: (map['category'] as String?) ?? 'general',
      title: cleanMarkdownDecorations((map['title'] as String?) ?? ''),
      content: cleanMarkdownDecorations((map['content'] as String?) ?? ''),
      isCompleted: (map['is_completed'] as num?) == 1,
    );
  }

  TripTip copyWith({
    int? id,
    int? tripId,
    int? dayNumber,
    String? category,
    String? title,
    String? content,
    bool? isCompleted,
  }) {
    return TripTip(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      category: category ?? this.category,
      title: title ?? this.title,
      content: content ?? this.content,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}
