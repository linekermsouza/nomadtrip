import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/models/trip_day.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/navigation_launcher.dart';
import '../../itinerary/providers/itinerary_provider.dart';
import '../../itinerary/screens/place_detail_screen.dart';

class MapRadarScreen extends ConsumerStatefulWidget {
  const MapRadarScreen({super.key});

  @override
  ConsumerState<MapRadarScreen> createState() => _MapRadarScreenState();
}

class _MapRadarScreenState extends ConsumerState<MapRadarScreen> {
  final MapController _mapController = MapController();
  bool _showOnlyUnvisited = false;
  ItineraryPlace? _selectedPlace;

  // Mutual exclusive filters (Item 34)
  int? _selectedDayFilter;
  String? _selectedCityFilter;

  void _jumpTo(LatLng target, double zoom) {
    _mapController.move(target, zoom);
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    double minLat = points.first.latitude;
    double maxLat = points.first.latitude;
    double minLng = points.first.longitude;
    double maxLng = points.first.longitude;

    for (final p in points) {
      if (p.latitude < minLat) minLat = p.latitude;
      if (p.latitude > maxLat) maxLat = p.latitude;
      if (p.longitude < minLng) minLng = p.longitude;
      if (p.longitude > maxLng) maxLng = p.longitude;
    }

    final center = LatLng((minLat + maxLat) / 2, (minLng + maxLng) / 2);
    _mapController.move(center, 12);
  }

  void _locateUser() async {
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível obter a localização GPS atual'),
          ),
        );
      }
    }
  }

  void _toggleDayFilter(int dayNumber, List<ItineraryPlace> allPlaces) {
    setState(() {
      if (_selectedDayFilter == dayNumber) {
        // Deselect day
        _selectedDayFilter = null;
        final valid = allPlaces
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if (valid.isNotEmpty) _fitBounds(valid);
      } else {
        // Select day & deselect city (mutual exclusivity, Item 34)
        _selectedDayFilter = dayNumber;
        _selectedCityFilter = null;
        _selectedPlace = null;
        final dayPoints = allPlaces
            .where((p) => p.dayNumber == dayNumber)
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if (dayPoints.isNotEmpty) {
          _fitBounds(dayPoints);
        }
      }
    });
  }

  void _toggleCityFilter(
    String city,
    List<ItineraryPlace> allPlaces,
    LatLng center,
  ) {
    setState(() {
      if (_selectedCityFilter == city) {
        // Deselect city
        _selectedCityFilter = null;
        final valid = allPlaces
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if (valid.isNotEmpty) _fitBounds(valid);
      } else {
        // Select city & deselect day (mutual exclusivity, Item 34)
        _selectedCityFilter = city;
        _selectedDayFilter = null;
        _selectedPlace = null;
        final cityPoints = allPlaces
            .where((p) => p.city.toLowerCase() == city.toLowerCase())
            .map((p) => LatLng(p.latitude, p.longitude))
            .toList();
        if (cityPoints.isNotEmpty) {
          _fitBounds(cityPoints);
        } else {
          _jumpTo(center, 12);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(itineraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Mapa & Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'Minha Localização',
            onPressed: _locateUser,
          ),
        ],
      ),
      body: daysAsync.when(
        data: (days) {
          final allValidPlaces = days
              .expand((d) => d.places)
              .where((p) => p.latitude != 0.0 && p.longitude != 0.0)
              .toList();

          // Extract dynamic cities from current trip (Item 27)
          final Map<String, List<LatLng>> cityPointsMap = {};
          for (final p in allValidPlaces) {
            final c = p.city.trim();
            if (c.isNotEmpty) {
              cityPointsMap
                  .putIfAbsent(c, () => [])
                  .add(LatLng(p.latitude, p.longitude));
            }
          }
          final dynamicCities = cityPointsMap.keys.toList()..sort();

          // Filter places based on active day or city filter (Item 34)
          List<ItineraryPlace> filteredPlaces = allValidPlaces;
          if (_selectedDayFilter != null) {
            filteredPlaces = filteredPlaces
                .where((p) => p.dayNumber == _selectedDayFilter)
                .toList();
          } else if (_selectedCityFilter != null) {
            filteredPlaces = filteredPlaces
                .where(
                  (p) =>
                      p.city.toLowerCase() ==
                      _selectedCityFilter!.toLowerCase(),
                )
                .toList();
          }

          if (_showOnlyUnvisited) {
            filteredPlaces = filteredPlaces.where((p) => !p.isVisited).toList();
          }

          final markers = filteredPlaces.map((place) {
            final isSelected = _selectedPlace?.id == place.id;
            return Marker(
              point: LatLng(place.latitude, place.longitude),
              width: isSelected ? 48 : 38,
              height: isSelected ? 48 : 38,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedPlace = place;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: place.isVisited
                        ? const Color(0xFF64748B)
                        : (isSelected
                              ? const Color(0xFFF97316)
                              : const Color(0xFF0F766E)),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.25),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(
                    place.isVisited ? Icons.check_rounded : Icons.place_rounded,
                    color: Colors.white,
                    size: isSelected ? 24 : 18,
                  ),
                ),
              ),
            );
          }).toList();

          final initialCenter = allValidPlaces.isNotEmpty
              ? LatLng(
                  allValidPlaces.first.latitude,
                  allValidPlaces.first.longitude,
                )
              : const LatLng(28.4310, -81.4700);

          return Stack(
            children: [
              // OpenStreetMap widget
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: initialCenter,
                  initialZoom: 10.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.nomadtrip.app',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Top Bar: Unvisited toggle + Dynamic Cities (Item 27)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        avatar: Icon(
                          _showOnlyUnvisited
                              ? Icons.check_box_rounded
                              : Icons.check_box_outline_blank_rounded,
                          size: 16,
                          color: _showOnlyUnvisited
                              ? Colors.white
                              : Colors.black87,
                        ),
                        label: const Text('Não visitados'),
                        selected: _showOnlyUnvisited,
                        selectedColor: const Color(0xFF0F766E),
                        labelStyle: TextStyle(
                          color: _showOnlyUnvisited
                              ? Colors.white
                              : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          setState(() => _showOnlyUnvisited = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      // Dynamic cities chips from current trip!
                      ...dynamicCities.map((city) {
                        final pts = cityPointsMap[city]!;
                        final avgLat =
                            pts.map((p) => p.latitude).reduce((a, b) => a + b) /
                            pts.length;
                        final avgLng =
                            pts
                                .map((p) => p.longitude)
                                .reduce((a, b) => a + b) /
                            pts.length;
                        final isSelected =
                            _selectedCityFilter?.toLowerCase() ==
                            city.toLowerCase();

                        return Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: FilterChip(
                            label: Text(city),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F766E),
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            avatar: Icon(
                              Icons.location_city_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                            onSelected: (_) => _toggleCityFilter(
                              city,
                              allValidPlaces,
                              LatLng(avgLat, avgLng),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              ),

              // Bottom Selected Place Card (if tapped on a marker)
              if (_selectedPlace != null)
                Positioned(
                  bottom: 74, // Above the days bottom bar
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(
                                    0xFF0F766E,
                                  ).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '${formatDayLabel(_selectedPlace!.dayNumber, days)} • ${_selectedPlace!.time}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () =>
                                    setState(() => _selectedPlace = null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedPlace!.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_selectedPlace!.rawDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedPlace!.rawDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  icon: const Icon(
                                    Icons.info_outline_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Ver Detalhes'),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => PlaceDetailScreen(
                                          place: _selectedPlace!,
                                        ),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(
                                    Icons.navigation_rounded,
                                    size: 16,
                                  ),
                                  label: const Text('Navegar'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F766E),
                                  ),
                                  onPressed: () {
                                    NavigationLauncher.showNavigationSheet(
                                      context,
                                      placeName: _selectedPlace!.name,
                                      latitude: _selectedPlace!.latitude,
                                      longitude: _selectedPlace!.longitude,
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // Bottom Day Selector Bar like mapngo.com (Item 34)
              Positioned(
                bottom: 12,
                left: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: days.map((d) {
                        final isSelected = _selectedDayFilter == d.dayNumber;
                        final label = d.dayNumber == 0
                            ? 'Sem Dia'
                            : 'Dia ${d.dayNumber}';
                        final placeCount = d.places
                            .where((p) => p.latitude != 0.0)
                            .length;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: FilterChip(
                            label: Text('$label ($placeCount)'),
                            selected: isSelected,
                            selectedColor: const Color(0xFF0F766E),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : const Color(0xFF1E293B),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              fontSize: 12,
                            ),
                            backgroundColor: const Color(0xFFF1F5F9),
                            onSelected: (_) =>
                                _toggleDayFilter(d.dayNumber, allValidPlaces),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro ao carregar mapa: $err')),
      ),
    );
  }
}
