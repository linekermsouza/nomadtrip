import 'itinerary_place.dart';

String formatDayLabel(int dayNumber, Iterable<TripDay> days) {
  if (dayNumber == 0) return 'No Day';
  final day = days.where((item) => item.dayNumber == dayNumber).firstOrNull;
  if (day == null) return 'Day $dayNumber';
  return day.displayLabel;
}

/// Represents a single day in the nomadtrip itinerary.
class TripDay {
  final int dayNumber;
  final String date; // Format: YYYY-MM-DD
  final String weekday;
  final String title;
  final String lodgingCity;
  final String wakeupCity;
  final List<ItineraryPlace> places;

  const TripDay({
    required this.dayNumber,
    required this.date,
    required this.weekday,
    required this.title,
    required this.lodgingCity,
    required this.wakeupCity,
    this.places = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'day_number': dayNumber,
      'date': date,
      'weekday': weekday,
      'title': title,
      'lodging_city': lodgingCity,
      'wakeup_city': wakeupCity,
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
    return TripDay(
      dayNumber: map['day_number'] as int,
      date: map['date'] as String,
      weekday: map['weekday'] as String,
      title: map['title'] as String,
      lodgingCity: map['lodging_city'] as String,
      wakeupCity: map['wakeup_city'] as String,
      places: places,
    );
  }

  TripDay copyWith({
    int? dayNumber,
    String? date,
    String? weekday,
    String? title,
    String? lodgingCity,
    String? wakeupCity,
    List<ItineraryPlace>? places,
  }) {
    return TripDay(
      dayNumber: dayNumber ?? this.dayNumber,
      date: date ?? this.date,
      weekday: weekday ?? this.weekday,
      title: title ?? this.title,
      lodgingCity: lodgingCity ?? this.lodgingCity,
      wakeupCity: wakeupCity ?? this.wakeupCity,
      places: places ?? this.places,
    );
  }
}
