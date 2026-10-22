import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/trip_tip.dart';

class TipsNotifier extends AsyncNotifier<List<TripTip>> {
  @override
  Future<List<TripTip>> build() async {
    final db = AppDatabase.instance;
    return await db.getAllTips();
  }

  Future<void> toggleTip(int tipId, bool isCompleted) async {
    final db = AppDatabase.instance;
    await db.toggleTipCompleted(tipId, isCompleted);
    state = AsyncData(await db.getAllTips());
  }

  Future<void> addTip(TripTip tip) async {
    final db = AppDatabase.instance;
    await db.insertTip(tip);
    state = AsyncData(await db.getAllTips());
  }

  Future<void> deleteTip(int tipId) async {
    final db = AppDatabase.instance;
    await db.deleteTip(tipId);
    state = AsyncData(await db.getAllTips());
  }
}

final tipsProvider = AsyncNotifierProvider<TipsNotifier, List<TripTip>>(() {
  return TipsNotifier();
});
