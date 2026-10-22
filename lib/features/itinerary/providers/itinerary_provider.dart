import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/models/trip_day.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

// Currently selected day number (1 to 20) using Riverpod 3 Notifier
class SelectedDayNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void selectDay(int day) => state = day;
}

final selectedDayNumberProvider = NotifierProvider<SelectedDayNotifier, int>(SelectedDayNotifier.new);

// Async notifier for all trip days with places
class ItineraryNotifier extends AsyncNotifier<List<TripDay>> {
  @override
  Future<List<TripDay>> build() async {
    final db = ref.read(databaseProvider);
    return await db.getAllDays();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final db = ref.read(databaseProvider);
      return await db.getAllDays();
    });
  }

  Future<void> togglePlaceVisited(int placeId, bool isVisited) async {
    final db = ref.read(databaseProvider);
    await db.togglePlaceVisited(placeId, isVisited);
    await reload();
  }

  Future<void> addPlace(ItineraryPlace place) async {
    final db = ref.read(databaseProvider);
    await db.insertPlace(place);
    await reload();
  }

  Future<void> updatePlace(ItineraryPlace place) async {
    final db = ref.read(databaseProvider);
    await db.updatePlace(place);
    await reload();
  }

  Future<void> deletePlace(int placeId) async {
    final db = ref.read(databaseProvider);
    await db.deletePlace(placeId);
    await reload();
  }

  Future<void> movePlace(int placeId, int newDayNumber, String newTime) async {
    final db = ref.read(databaseProvider);
    await db.movePlace(placeId, newDayNumber, newTime);
    await reload();
  }
}

final itineraryProvider = AsyncNotifierProvider<ItineraryNotifier, List<TripDay>>(() {
  return ItineraryNotifier();
});

// Helper provider for the currently active day
final currentDayProvider = Provider<TripDay?>((ref) {
  final daysAsync = ref.watch(itineraryProvider);
  final selectedDayNum = ref.watch(selectedDayNumberProvider);

  return daysAsync.when(
    data: (days) {
      return days.firstWhere(
        (d) => d.dayNumber == selectedDayNum,
        orElse: () => days.isNotEmpty ? days.first : const TripDay(
          dayNumber: 1,
          date: '2026-11-24',
          weekday: 'Tuesday',
          title: 'Florida Trip',
          lodgingCity: 'Orlando',
          wakeupCity: 'Miami',
        ),
      );
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});
