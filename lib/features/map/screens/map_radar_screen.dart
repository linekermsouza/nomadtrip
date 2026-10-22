import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/navigation_launcher.dart';
import '../../itinerary/providers/itinerary_provider.dart';

class MapRadarScreen extends ConsumerStatefulWidget {
  const MapRadarScreen({super.key});

  @override
  ConsumerState<MapRadarScreen> createState() => _MapRadarScreenState();
}

class _MapRadarScreenState extends ConsumerState<MapRadarScreen> {
  final MapController _mapController = MapController();
  bool _showOnlyUnvisited = false;
  ItineraryPlace? _selectedPlace;

  // Key Florida focus coordinates
  static const LatLng _orlandoCenter = LatLng(28.4310, -81.4700);
  static const LatLng _miamiCenter = LatLng(25.7617, -80.1918);
  static const LatLng _keyWestCenter = LatLng(24.5551, -81.7800);

  void _jumpTo(LatLng target, double zoom) {
    _mapController.move(target, zoom);
  }

  void _locateUser() async {
    final pos = await LocationService.instance.getCurrentPosition();
    if (pos != null) {
      _mapController.move(LatLng(pos.latitude, pos.longitude), 13);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not retrieve current GPS location')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final daysAsync = ref.watch(itineraryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗺️ Florida Map & Radar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location_rounded),
            tooltip: 'My Location',
            onPressed: _locateUser,
          ),
        ],
      ),
      body: daysAsync.when(
        data: (days) {
          // Extract all places with valid coordinates
          final allPlaces = days.expand((d) => d.places).where((p) => p.latitude != 0.0 && p.longitude != 0.0).toList();
          final visiblePlaces = _showOnlyUnvisited
              ? allPlaces.where((p) => !p.isVisited).toList()
              : allPlaces;

          final markers = visiblePlaces.map((place) {
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
                        ? const Color(0xFF64748B) // Slate for visited
                        : (isSelected ? const Color(0xFFF97316) : const Color(0xFF0F766E)),
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

          return Stack(
            children: [
              // OpenStreetMap widget
              FlutterMap(
                mapController: _mapController,
                options: const MapOptions(
                  initialCenter: _orlandoCenter,
                  initialZoom: 10.5,
                ),
                children: [
                  TileLayer(
                    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'com.floridatrip.florida_trip',
                  ),
                  MarkerLayer(markers: markers),
                ],
              ),

              // Filter & Navigation Chips Header
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
                          _showOnlyUnvisited ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                          size: 16,
                          color: _showOnlyUnvisited ? Colors.white : Colors.black87,
                        ),
                        label: const Text('Only Unvisited'),
                        selected: _showOnlyUnvisited,
                        selectedColor: const Color(0xFF0F766E),
                        labelStyle: TextStyle(
                          color: _showOnlyUnvisited ? Colors.white : Colors.black87,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (val) {
                          setState(() => _showOnlyUnvisited = val);
                        },
                      ),
                      const SizedBox(width: 8),
                      ActionChip(
                        label: const Text('Orlando'),
                        avatar: const Icon(Icons.castle_rounded, size: 14),
                        onPressed: () => _jumpTo(_orlandoCenter, 11),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Miami'),
                        avatar: const Icon(Icons.beach_access_rounded, size: 14),
                        onPressed: () => _jumpTo(_miamiCenter, 12),
                      ),
                      const SizedBox(width: 6),
                      ActionChip(
                        label: const Text('Key West'),
                        avatar: const Icon(Icons.wb_sunny_rounded, size: 14),
                        onPressed: () => _jumpTo(_keyWestCenter, 13),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom Card when a marker is tapped
              if (_selectedPlace != null)
                Positioned(
                  bottom: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Day ${_selectedPlace!.dayNumber} • ${_selectedPlace!.time}',
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
                                onPressed: () => setState(() => _selectedPlace = null),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _selectedPlace!.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          if (_selectedPlace!.rawDescription.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              _selectedPlace!.rawDescription,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: FilledButton.icon(
                                  icon: const Icon(Icons.navigation_rounded, size: 16),
                                  label: const Text('Navigate'),
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
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading map: $err')),
      ),
    );
  }
}
