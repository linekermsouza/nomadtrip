import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/trip.dart';

final selectedTripIdProvider = NotifierProvider<SelectedTripIdNotifier, int?>(
  SelectedTripIdNotifier.new,
);

class SelectedTripIdNotifier extends Notifier<int?> {
  @override
  int? build() {
    // Initial fetch from DB
    _loadFromDb();
    return null;
  }

  Future<void> _loadFromDb() async {
    final id = await AppDatabase.instance.getSelectedTripId();
    state = id;
  }

  Future<void> selectTrip(int? tripId) async {
    state = tripId;
    await AppDatabase.instance.setSelectedTripId(tripId);
  }
}

class TripsNotifier extends AsyncNotifier<List<Trip>> {
  @override
  Future<List<Trip>> build() async {
    return await AppDatabase.instance.getAllTrips();
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      return await AppDatabase.instance.getAllTrips();
    });
  }

  Future<int> createTrip(Trip trip) async {
    final newId = await AppDatabase.instance.insertTrip(trip);
    await reload();
    await ref.read(selectedTripIdProvider.notifier).selectTrip(newId);
    return newId;
  }

  Future<void> updateTrip(Trip trip) async {
    await AppDatabase.instance.updateTrip(trip);
    await reload();
  }

  Future<void> deleteTrip(int tripId) async {
    await AppDatabase.instance.deleteTrip(tripId);
    await reload();
    final current = ref.read(selectedTripIdProvider);
    if (current == tripId) {
      final trips = state.value ?? [];
      final next = trips.where((t) => t.id != tripId).firstOrNull;
      await ref.read(selectedTripIdProvider.notifier).selectTrip(next?.id);
    }
  }

  Future<int> importTrip(
    Map<String, dynamic> data, {
    String? customName,
    String? customStartDate,
    String? customEndDate,
  }) async {
    final newId = await AppDatabase.instance.importTripData(
      data,
      customName: customName,
      customStartDate: customStartDate,
      customEndDate: customEndDate,
    );
    await reload();
    await ref.read(selectedTripIdProvider.notifier).selectTrip(newId);
    return newId;
  }
}

final tripsProvider = AsyncNotifierProvider<TripsNotifier, List<Trip>>(() {
  return TripsNotifier();
});
