import 'package:flutter_test/flutter_test.dart';
import 'package:nomadtrip/core/models/itinerary_place.dart';
import 'package:nomadtrip/core/models/trip_day.dart';

void main() {
  final days = [
    const TripDay(
      dayNumber: 1,
      date: '2026-11-24',
      weekday: 'Terça',
      title: 'Arrival',
      lodgingCity: 'Orlando',
      wakeupCity: 'Miami',
    ),
  ];

  test('formats scheduled days with date and weekday abbreviation', () {
    expect(formatDayLabel(1, days), 'Day 1 24/11 (Ter)');
  });

  test('formats unscheduled places as No Day', () {
    expect(formatDayLabel(0, days), 'No Day');
  });

  test('preserves alternative flag in database map round trip', () {
    const place = ItineraryPlace(
      dayNumber: 0,
      name: 'Alternative dinner',
      time: '18:00',
      rawDescription: 'Option A or B',
      category: 'food',
      city: 'Orlando',
      latitude: 28.5,
      longitude: -81.3,
      isAlternative: true,
    );

    final restored = ItineraryPlace.fromMap(place.toMap());
    expect(restored.dayNumber, 0);
    expect(restored.isAlternative, isTrue);
    expect(restored.links, isEmpty);
  });
}
