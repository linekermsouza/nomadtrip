import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/models/trip_day.dart';
import '../../../core/services/navigation_launcher.dart';
import '../../itinerary/providers/itinerary_provider.dart';
import '../../itinerary/screens/place_detail_screen.dart';
import '../../itinerary/screens/place_edit_screen.dart';
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
      appBar: AppBar(title: const Text('🔍 Buscar Locais')),
      body: Column(
        children: [
          // Search Input Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Pesquise parque, restaurante, outlet, atração...',
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
                              'Encontrado(s) ${results.length} local(is) no roteiro!',
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
                  }
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF3C7),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFFFCD34D)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          color: Color(0xFFD97706),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Nenhum local no roteiro com "$query". Você pode adicioná-lo!',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF92400E),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, stackTrace) => const SizedBox.shrink(),
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
                          Icons.travel_explore_rounded,
                          size: 54,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          query.trim().isEmpty
                              ? 'Nenhum local cadastrado no roteiro'
                              : 'Nenhum resultado para "$query"',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 80, top: 4),
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final place = results[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 6,
                        ),
                        // Item 29: Full-screen place detail on tap
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PlaceDetailScreen(place: place),
                            ),
                          );
                        },
                        leading: CircleAvatar(
                          backgroundColor: const Color(
                            0xFF0F766E,
                          ).withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.place_rounded,
                            color: Color(0xFF0F766E),
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
                            const SizedBox(height: 2),
                            Text(
                              '${formatDayLabel(place.dayNumber, days)} • ${place.time}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0F766E),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (place.rawDescription.isNotEmpty) ...[
                              const SizedBox(height: 2),
                              Text(
                                place.rawDescription,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 12),
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
                              tooltip: 'Navegar',
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
                              tooltip: 'Editar',
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        PlaceEditScreen(place: place),
                                  ),
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
              error: (err, stack) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
      // Item 32: Compact icon-only FAB (same icon as itinerary)
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Local',
        child: const Icon(Icons.add_location_alt_rounded),
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

          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => PlaceEditScreen(place: newPlace)),
          );
        },
      ),
    );
  }
}
