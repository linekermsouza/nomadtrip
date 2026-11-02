import 'dart:convert';
import 'checklist_item.dart';
import 'itinerary_place.dart';

export 'checklist_item.dart';

String cleanMarkdownDecorations(String text) {
  return text.replaceAll('**', '').replaceAll('__', '');
}

String formatDayLabel(int dayNumber, Iterable<TripDay> days) {
  if (dayNumber == 0) return 'No Day';
  final day = days.where((item) => item.dayNumber == dayNumber).firstOrNull;
  if (day == null) return 'Day $dayNumber';
  return day.displayLabel;
}

/// Represents a single day in the nomadtrip itinerary.
class TripDay {
  final int? id;
  final int tripId;
  final int dayNumber;
  final String date; // Format: YYYY-MM-DD
  final String weekday;
  final String title;
  final String lodgingCity;
  final String wakeupCity;
  final List<ChecklistItem> checklist;
  final List<ItineraryPlace> places;

  const TripDay({
    this.id,
    this.tripId = 1,
    required this.dayNumber,
    required this.date,
    required this.weekday,
    required this.title,
    required this.lodgingCity,
    required this.wakeupCity,
    this.checklist = const [],
    this.places = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'day_number': dayNumber,
      'date': date,
      'weekday': weekday,
      'title': cleanMarkdownDecorations(title),
      'lodging_city': cleanMarkdownDecorations(lodgingCity),
      'wakeup_city': cleanMarkdownDecorations(wakeupCity),
      'checklist': jsonEncode(checklist.map((c) => c.toMap()).toList()),
    };
  }

  String get displayDate {
    if (date.isEmpty) return '';
    final parts = date.split('-');
    return parts.length == 3 ? '${parts[2]}/${parts[1]}' : date;
  }

  String get displayLabel => dayNumber == 0
      ? 'No Day'
      : 'Day $dayNumber${displayDate.isEmpty ? '' : ' $displayDate'}${weekday.isEmpty ? '' : ' (${weekday.substring(0, weekday.length < 3 ? weekday.length : 3)})'}';

  factory TripDay.fromMap(
    Map<String, dynamic> map, [
    List<ItineraryPlace> places = const [],
  ]) {
    List<ChecklistItem> parsedChecklist = [];
    if (map['checklist'] != null) {
      try {
        final decoded = map['checklist'] is String
            ? jsonDecode(map['checklist'] as String)
            : map['checklist'];
        if (decoded is List) {
          parsedChecklist = decoded
              .map(
                (c) =>
                    ChecklistItem.fromMap(Map<String, dynamic>.from(c as Map)),
              )
              .toList();
        }
      } catch (_) {}
    }

    return TripDay(
      id: (map['id'] as num?)?.toInt(),
      tripId: (map['trip_id'] as num?)?.toInt() ?? 1,
      dayNumber: (map['day_number'] as num?)?.toInt() ?? 0,
      date: (map['date'] as String?) ?? '',
      weekday: (map['weekday'] as String?) ?? '',
      title: cleanMarkdownDecorations((map['title'] as String?) ?? ''),
      lodgingCity: cleanMarkdownDecorations(
        (map['lodging_city'] as String?) ?? '',
      ),
      wakeupCity: cleanMarkdownDecorations(
        (map['wakeup_city'] as String?) ?? '',
      ),
      checklist: parsedChecklist,
      places: places,
    );
  }

  TripDay copyWith({
    int? id,
    int? tripId,
    int? dayNumber,
    String? date,
    String? weekday,
    String? title,
    String? lodgingCity,
    String? wakeupCity,
    List<ChecklistItem>? checklist,
    List<ItineraryPlace>? places,
  }) {
    return TripDay(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      weekday: weekday ?? this.weekday,
      title: title ?? this.title,
      lodgingCity: lodgingCity ?? this.lodgingCity,
      wakeupCity: wakeupCity ?? this.wakeupCity,
      checklist: checklist ?? this.checklist,
      places: places ?? this.places,
    );
  }
}
