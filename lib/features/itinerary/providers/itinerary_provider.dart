import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/models/trip_day.dart';
import '../../trips/providers/trips_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) {
  return AppDatabase.instance;
});

// Currently selected day number using Riverpod 3 Notifier
class SelectedDayNotifier extends Notifier<int> {
  @override
  int build() => 1;

  void selectDay(int day) => state = day;
}

final selectedDayNumberProvider = NotifierProvider<SelectedDayNotifier, int>(
  SelectedDayNotifier.new,
);

// Async notifier for trip days with places
class ItineraryNotifier extends AsyncNotifier<List<TripDay>> {
  @override
  Future<List<TripDay>> build() async {
    final tripId = ref.watch(selectedTripIdProvider);
    final db = ref.read(databaseProvider);
    if (tripId == null) {
      final savedId = await db.getSelectedTripId();
      if (savedId != null) {
        return await db.getAllDays(tripId: savedId);
      }
      return [];
    }
    return await db.getAllDays(tripId: tripId);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final tripId = ref.read(selectedTripIdProvider);
      final db = ref.read(databaseProvider);
      return await db.getAllDays(tripId: tripId);
    });
  }

  Future<void> togglePlaceVisited(int placeId, bool isVisited) async {
    final db = ref.read(databaseProvider);
    await db.togglePlaceVisited(placeId, isVisited);
    await reload();
  }

  Future<void> addPlace(ItineraryPlace place) async {
    final tripId = ref.read(selectedTripIdProvider) ?? 1;
    final db = ref.read(databaseProvider);
    await db.insertPlace(place.copyWith(tripId: tripId));
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

  Future<void> deletePlaces(List<int> placeIds) async {
    final db = ref.read(databaseProvider);
    await db.deletePlaces(placeIds);
    await reload();
  }

  Future<void> deletePlacesForDay(int dayNumber) async {
    final tripId = ref.read(selectedTripIdProvider) ?? 1;
    final db = ref.read(databaseProvider);
    await db.deletePlacesForDay(tripId, dayNumber);
    await reload();
  }

  Future<void> movePlace(int placeId, int newDayNumber, String newTime) async {
    final db = ref.read(databaseProvider);
    await db.movePlace(placeId, newDayNumber, newTime);
    await reload();
  }

  Future<void> updateDay(TripDay day) async {
    final db = ref.read(databaseProvider);
    await db.updateDay(day);
    await reload();
  }

  Future<void> toggleChecklistItem(int dayNumber, String itemId) async {
    final days = state.value ?? [];
    final day = days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => days.first,
    );
    final updatedChecklist = day.checklist.map((item) {
      if (item.id == itemId) {
        return item.copyWith(isCompleted: !item.isCompleted);
      }
      return item;
    }).toList();

    final tripId = ref.read(selectedTripIdProvider) ?? day.tripId;
    final db = ref.read(databaseProvider);
    await db.updateDayChecklist(tripId, dayNumber, updatedChecklist);
    await reload();
  }

  Future<void> addChecklistItem(int dayNumber, String text) async {
    if (text.trim().isEmpty) return;
    final days = state.value ?? [];
    final day = days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => days.first,
    );
    final newItem = ChecklistItem(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      text: text.trim(),
      isCompleted: false,
    );
    final updated = [...day.checklist, newItem];
    final tripId = ref.read(selectedTripIdProvider) ?? day.tripId;
    final db = ref.read(databaseProvider);
    await db.updateDayChecklist(tripId, dayNumber, updated);
    await reload();
  }

  Future<void> removeChecklistItem(int dayNumber, String itemId) async {
    final days = state.value ?? [];
    final day = days.firstWhere(
      (d) => d.dayNumber == dayNumber,
      orElse: () => days.first,
    );
    final updated = day.checklist.where((i) => i.id != itemId).toList();
    final tripId = ref.read(selectedTripIdProvider) ?? day.tripId;
    final db = ref.read(databaseProvider);
    await db.updateDayChecklist(tripId, dayNumber, updated);
    await reload();
  }
}

final itineraryProvider =
    AsyncNotifierProvider<ItineraryNotifier, List<TripDay>>(() {
      return ItineraryNotifier();
    });

// Helper provider for the currently active day
final currentDayProvider = Provider<TripDay?>((ref) {
  final daysAsync = ref.watch(itineraryProvider);
  final selectedDayNum = ref.watch(selectedDayNumberProvider);

  return daysAsync.when(
    data: (days) {
      if (days.isEmpty) return null;
      return days.firstWhere(
        (d) => d.dayNumber == selectedDayNum,
        orElse: () => days.first,
      );
    },
    loading: () => null,
    error: (err, stack) => null,
  );
});
