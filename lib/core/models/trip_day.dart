import 'itinerary_place.dart';

/// Represents a single day in the Florida trip itinerary.
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

  factory TripDay.fromMap(Map<String, dynamic> map, [List<ItineraryPlace> places = const []]) {
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
