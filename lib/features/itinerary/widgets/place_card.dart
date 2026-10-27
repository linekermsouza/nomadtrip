import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/navigation_launcher.dart';
import '../providers/itinerary_provider.dart';
import 'place_edit_dialog.dart';

class PlaceCard extends ConsumerWidget {
  final ItineraryPlace place;

  const PlaceCard({super.key, required this.place});

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'theme_park':
        return Icons.attractions_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'food':
        return Icons.restaurant_rounded;
      case 'transit':
        return Icons.directions_car_rounded;
      default:
        return Icons.place_rounded;
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'theme_park':
        return const Color(0xFF6366F1); // Indigo
      case 'shopping':
        return const Color(0xFFEC4899); // Pink
      case 'food':
        return const Color(0xFFF97316); // Orange
      case 'transit':
        return const Color(0xFF64748B); // Slate
      default:
        return const Color(0xFF0F766E); // Teal
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoryColor = _getCategoryColor(place.category);
    final distanceMeters = (place.latitude != 0.0 && place.longitude != 0.0)
        ? LocationService.instance.calculateDistanceInMeters(
            place.latitude,
            place.longitude,
          )
        : null;
    final distanceText = LocationService.instance.formatDistance(
      distanceMeters,
    );

    void showDetails() {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        builder: (_) => _PlaceDetails(place: place),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: place.isAlternative
            ? const Color(0xFFFFFBEB)
            : (place.isVisited ? const Color(0xFFF8FAFC) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: place.isAlternative
              ? const Color(0xFFF59E0B)
              : (place.isVisited
                    ? const Color(0xFFCBD5E1)
                    : const Color(0xFFE2E8F0)),
          width: 1.2,
        ),
        boxShadow: place.isVisited
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: InkWell(
        onTap: showDetails,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Time, Category & Visited Toggle
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 14,
                          color: Color(0xFF475569),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          place.time,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(place.category),
                      size: 15,
                      color: categoryColor,
                    ),
                  ),
                  if (distanceText.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      '📍 $distanceText',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF0F766E),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const Spacer(),
                  // Visited toggle chip
                  InkWell(
                    onTap: () {
                      if (place.id != null) {
                        ref
                            .read(itineraryProvider.notifier)
                            .togglePlaceVisited(place.id!, !place.isVisited);
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: place.isVisited
                            ? const Color(0xFFDCFCE7)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: place.isVisited
                              ? const Color(0xFF86EFAC)
                              : const Color(0xFFE2E8F0),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            place.isVisited
                                ? Icons.check_circle_rounded
                                : Icons.radio_button_unchecked_rounded,
                            size: 15,
                            color: place.isVisited
                                ? const Color(0xFF16A34A)
                                : const Color(0xFF94A3B8),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            place.isVisited ? 'Visited' : 'Mark Visited',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: place.isVisited
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Place Name
              Text(
                place.name,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  decoration: place.isVisited
                      ? TextDecoration.lineThrough
                      : null,
                  color: place.isVisited
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 6),

              // Description / notes
              if (place.rawDescription.isNotEmpty)
                Text(
                  place.rawDescription,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: place.isVisited
                        ? const Color(0xFF94A3B8)
                        : const Color(0xFF475569),
                  ),
                ),

              // User Notes
              if (place.notes.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF3C7),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.sticky_note_2_rounded,
                        size: 14,
                        color: Color(0xFFD97706),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          place.notes,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF92400E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 10),

              // Badges row: Parking, Reservation, City
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (place.city.isNotEmpty)
                    _Badge(
                      icon: Icons.location_city_rounded,
                      label: place.city,
                      color: const Color(0xFF64748B),
                    ),
                  if (place.parking == 'Free')
                    const _Badge(
                      icon: Icons.local_parking_rounded,
                      label: 'Free Parking',
                      color: Color(0xFF16A34A),
                    )
                  else if (place.parking == 'Paid')
                    _Badge(
                      icon: Icons.local_parking_rounded,
                      label: place.parkingCost > 0
                          ? 'Parking ~US\$${place.parkingCost}'
                          : 'Paid Parking',
                      color: const Color(0xFFD97706),
                    ),
                  if (place.requiresReservation)
                    const _Badge(
                      icon: Icons.event_available_rounded,
                      label: 'Reservation Req.',
                      color: Color(0xFFDC2626),
                    ),
                ],
              ),

              // Links list (Instagram, YouTube, etc.)
              if (place.links.isNotEmpty) ...[
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: place.links.map((link) {
                    return ActionChip(
                      avatar: const Icon(
                        Icons.link_rounded,
                        size: 14,
                        color: Color(0xFF0F766E),
                      ),
                      label: Text(
                        link.length > 25 ? '${link.substring(0, 22)}...' : link,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF0F766E),
                        ),
                      ),
                      onPressed: () => NavigationLauncher.openUrl(link),
                    );
                  }).toList(),
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 8),

              if (place.isAlternative)
                const _Badge(
                  icon: Icons.alt_route_rounded,
                  label: 'Alternative',
                  color: Color(0xFFB45309),
                ),
              // Action Buttons
              Row(
                children: [
                  // Route button
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.navigation_rounded, size: 16),
                      label: const Text('Navigate'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF0F766E),
                        side: const BorderSide(color: Color(0xFF0F766E)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                      ),
                      onPressed: () {
                        NavigationLauncher.showNavigationSheet(
                          context,
                          placeName: place.name,
                          latitude: place.latitude,
                          longitude: place.longitude,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.outlined(
                    icon: const Icon(Icons.edit_note_rounded, size: 18),
                    color: const Color(0xFF475569),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE2E8F0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    tooltip: 'Edit / Move / Notes',
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
            ],
          ),
        ),
      ),
    );
  }
}

class _PlaceDetails extends StatelessWidget {
  final ItineraryPlace place;
  const _PlaceDetails({required this.place});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '${place.dayNumber == 0 ? 'No Day' : 'Day ${place.dayNumber}'} • ${place.time}',
              style: const TextStyle(
                color: Color(0xFF0F766E),
                fontWeight: FontWeight.bold,
              ),
            ),
            if (place.city.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text('📍 ${place.city}'),
              ),
            if (place.rawDescription.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(place.rawDescription),
              ),
            if (place.notes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text('Notas: ${place.notes}'),
              ),
            if (place.links.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(place.links.join('\n')),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _Badge({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
