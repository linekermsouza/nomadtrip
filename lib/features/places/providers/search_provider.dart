import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/itinerary_place.dart';
import '../../trips/providers/trips_provider.dart';

class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query;
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

final searchResultsProvider = FutureProvider<List<ItineraryPlace>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  final tripId = ref.watch(selectedTripIdProvider);
  final db = AppDatabase.instance;
  return await db.searchPlaces(query, tripId: tripId);
});

// Check whether a place with a similar name already exists in the itinerary
final duplicateCheckerProvider = Provider.family<ItineraryPlace?, String>((
  ref,
  placeName,
) {
  final searchResults = ref.watch(searchResultsProvider).value ?? [];
  final cleanName = placeName.trim().toLowerCase();
  if (cleanName.isEmpty) return null;

  try {
    return searchResults.firstWhere(
      (p) =>
          p.name.toLowerCase().contains(cleanName) ||
          cleanName.contains(p.name.toLowerCase()),
    );
  } catch (_) {
    return null;
  }
});
