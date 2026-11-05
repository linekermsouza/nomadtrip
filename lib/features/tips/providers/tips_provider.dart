import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/trip_tip.dart';
import '../../trips/providers/trips_provider.dart';

class TipsNotifier extends AsyncNotifier<List<TripTip>> {
  @override
  Future<List<TripTip>> build() async {
    final tripId = ref.watch(selectedTripIdProvider);
    final db = AppDatabase.instance;
    return await db.getAllTips(tripId: tripId);
  }

  Future<void> reload() async {
    final tripId = ref.read(selectedTripIdProvider);
    final db = AppDatabase.instance;
    state = AsyncData(await db.getAllTips(tripId: tripId));
  }

  Future<void> toggleTip(int tipId, bool isCompleted) async {
    final tripId = ref.read(selectedTripIdProvider);
    final db = AppDatabase.instance;
    await db.toggleTipCompleted(tipId, isCompleted);
    state = AsyncData(await db.getAllTips(tripId: tripId));
  }

  Future<void> addTip(TripTip tip) async {
    final tripId = ref.read(selectedTripIdProvider) ?? 1;
    final db = AppDatabase.instance;
    await db.insertTip(tip.copyWith(tripId: tripId));
    state = AsyncData(await db.getAllTips(tripId: tripId));
  }

  Future<void> deleteTip(int tipId) async {
    final tripId = ref.read(selectedTripIdProvider);
    final db = AppDatabase.instance;
    await db.deleteTip(tipId);
    state = AsyncData(await db.getAllTips(tripId: tripId));
  }
}

final tipsProvider = AsyncNotifierProvider<TipsNotifier, List<TripTip>>(() {
  return TipsNotifier();
});
