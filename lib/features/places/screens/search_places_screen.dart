import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/models/trip_day.dart';
import '../../itinerary/providers/itinerary_provider.dart';
import '../../../core/services/navigation_launcher.dart';
import '../../itinerary/widgets/place_edit_dialog.dart';
import '../providers/search_provider.dart';

class SearchPlacesScreen extends ConsumerStatefulWidget {
  const SearchPlacesScreen({super.key});

  @override
  ConsumerState<SearchPlacesScreen> createState() => _SearchPlacesScreenState();
}

class _SearchPlacesScreenState extends ConsumerState<SearchPlacesScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    ref.read(searchQueryProvider.notifier).setQuery(value);
  }

  void _clearSearch() {
    _searchController.clear();
    ref.read(searchQueryProvider.notifier).setQuery('');
  }

  @override
  Widget build(BuildContext context) {
    final searchResultsAsync = ref.watch(searchResultsProvider);
    final query = ref.watch(searchQueryProvider);
    final days = ref.watch(itineraryProvider).value ?? const [];

    return Scaffold(
      appBar: AppBar(title: const Text('🔍 Search Places')),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search place, outlet, restaurant, park...',
                prefixIcon: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0F766E),
                ),
                suffixIcon: query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: _clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(
                    color: Color(0xFF0F766E),
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),

          // Duplicate verification banner if query matches
          if (query.trim().isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: searchResultsAsync.when(
                data: (results) {
                  if (results.isNotEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0FDF4),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF86EFAC)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF16A34A),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Found ${results.length} matching stop(s) already in itinerary!',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF15803D),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  } else {
                    return Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline_rounded,
                            color: Color(0xFFDC2626),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'Not in itinerary yet. You can add it using the button below!',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                },
                loading: () => const SizedBox.shrink(),
                error: (err, stack) => const SizedBox.shrink(),
              ),
            ),
          ],

          // Search Results List
          Expanded(
            child: searchResultsAsync.when(
              data: (results) {
                if (results.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          query.isEmpty
                              ? 'Type to search stops in the itinerary'
                              : 'No places found for "$query"',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 8, bottom: 20),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final place = results[index];
                    return Card(
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        leading: CircleAvatar(
                          backgroundColor: place.isVisited
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFF1F5F9),
                          child: Icon(
                            place.isVisited
                                ? Icons.check_rounded
                                : Icons.place_rounded,
                            color: place.isVisited
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF0F766E),
                          ),
                        ),
                        title: Text(
                          place.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              '📅 ${formatDayLabel(place.dayNumber, days)} • ⏰ ${place.time}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF0F766E),
                              ),
                            ),
                            if (place.city.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                '📍 ${place.city}',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.navigation_rounded,
                                color: Color(0xFF0F766E),
                              ),
                              tooltip: 'Navigate',
                              onPressed: () {
                                NavigationLauncher.showNavigationSheet(
                                  context,
                                  placeName: place.name,
                                  latitude: place.latitude,
                                  longitude: place.longitude,
                                );
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit_note_rounded),
                              tooltip: 'Edit',
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  builder: (_) => PlaceEditDialog(place: place),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add Custom Stop'),
        onPressed: () {
          final newPlace = ItineraryPlace(
            dayNumber: 1,
            name: query.trim(),
            time: '12:00',
            rawDescription: '',
            category: 'attraction',
            city: 'Orlando',
            latitude: 28.5383,
            longitude: -81.3792,
            parking: 'Unknown',
          );

          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => PlaceEditDialog(place: newPlace),
          );
        },
      ),
    );
  }
}
