import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/navigation_launcher.dart';
import '../providers/itinerary_provider.dart';
import '../screens/place_detail_screen.dart';
import '../screens/place_edit_screen.dart';

class PlaceCard extends ConsumerWidget {
  final ItineraryPlace place;
  final bool isSelectionMode;
  final bool isSelected;
  final ValueChanged<bool?>? onSelectChanged;

  const PlaceCard({
    super.key,
    required this.place,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onSelectChanged,
  });

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
        return const Color(0xFF6366F1);
      case 'shopping':
        return const Color(0xFFEC4899);
      case 'food':
        return const Color(0xFFF97316);
      case 'transit':
        return const Color(0xFF64748B);
      default:
        return const Color(0xFF0F766E);
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

    void openDetail() {
      if (isSelectionMode) {
        onSelectChanged?.call(!isSelected);
        return;
      }
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: place)),
      );
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isSelected
            ? const Color(0xFFE0F2FE)
            : (place.isAlternative
                  ? const Color(0xFFFFFBEB)
                  : (place.isVisited ? const Color(0xFFF8FAFC) : Colors.white)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected
              ? const Color(0xFF0284C7)
              : (place.isAlternative
                    ? const Color(0xFFF59E0B)
                    : (place.isVisited
                          ? const Color(0xFFCBD5E1)
                          : const Color(0xFFE2E8F0))),
          width: isSelected ? 2.0 : 1.2,
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
        onTap: openDetail,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header: Checkbox (if multi-select) / Time, Category, Distance, Visited
              Row(
                children: [
                  if (isSelectionMode) ...[
                    Checkbox(
                      value: isSelected,
                      activeColor: const Color(0xFF0F766E),
                      onChanged: onSelectChanged,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.schedule_rounded,
                          size: 13,
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
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: categoryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getCategoryIcon(place.category),
                      size: 14,
                      color: categoryColor,
                    ),
                  ),
                  if (distanceText.isNotEmpty) ...[
                    const SizedBox(width: 6),
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
                  if (!isSelectionMode)
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
                          horizontal: 8,
                          vertical: 3,
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
                              size: 14,
                              color: place.isVisited
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF94A3B8),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              place.isVisited ? 'Visitado' : 'Marcar',
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

              // Content row: Text + Thumbnail Image (Item 28)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            decoration: place.isVisited
                                ? TextDecoration.lineThrough
                                : null,
                            color: place.isVisited
                                ? const Color(0xFF94A3B8)
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        if (place.zone.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            place.zone,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6366F1),
                            ),
                          ),
                        ],
                        if (place.rawDescription.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            place.rawDescription,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              color: place.isVisited
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (place.imageUrl.isNotEmpty) ...[
                    const SizedBox(width: 10),
                    CachedPlaceImage(
                      imageUrl: place.imageUrl,
                      category: place.category,
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ],
                ],
              ),

              // Coaster/Ride Info Chips if present (Items 15 & 16)
              if (place.minHeightCm > 0 ||
                  place.adrenalineLevel.isNotEmpty ||
                  place.hasDizzinessWarning ||
                  place.avgWaitMinutes > 0) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    if (place.minHeightCm > 0)
                      _MiniChip(
                        icon: Icons.height,
                        label: '${place.minHeightCm}cm',
                        color: const Color(0xFF475569),
                      ),
                    if (place.adrenalineLevel.isNotEmpty)
                      _MiniChip(
                        icon: Icons.bolt,
                        label: place.adrenalineLevel,
                        color: const Color(0xFFEA580C),
                      ),
                    if (place.hasDizzinessWarning)
                      const _MiniChip(
                        icon: Icons.warning_amber,
                        label: 'Gira / Enjoo',
                        color: Color(0xFFD97706),
                      ),
                    if (place.avgWaitMinutes > 0)
                      _MiniChip(
                        icon: Icons.hourglass_top,
                        label: '~${place.avgWaitMinutes}m',
                        color: const Color(0xFF2563EB),
                      ),
                  ],
                ),
              ],

              // Badges row: City, Parking, Reservation (Item 14: ONLY when true)
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  if (place.city.isNotEmpty)
                    _MiniChip(
                      icon: Icons.location_city,
                      label: place.city,
                      color: const Color(0xFF64748B),
                    ),
                  if (place.parking == 'Free')
                    const _MiniChip(
                      icon: Icons.local_parking,
                      label: 'Free Parking',
                      color: Color(0xFF16A34A),
                    )
                  else if (place.parking == 'Paid')
                    _MiniChip(
                      icon: Icons.local_parking,
                      label: place.parkingCost > 0
                          ? '~\$${place.parkingCost}'
                          : 'Pago',
                      color: const Color(0xFFD97706),
                    ),
                  // Item 14: ONLY show reservation if required!
                  if (place.requiresReservation)
                    const _MiniChip(
                      icon: Icons.event_available,
                      label: 'Reserva Req.',
                      color: Color(0xFFDC2626),
                    ),
                  if (place.isAlternative)
                    const _MiniChip(
                      icon: Icons.alt_route,
                      label: 'Alternativa',
                      color: Color(0xFFB45309),
                    ),
                ],
              ),

              // Action Buttons
              if (!isSelectionMode) ...[
                const SizedBox(height: 10),
                const Divider(height: 1, color: Color(0xFFF1F5F9)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.navigation_rounded, size: 15),
                        label: const Text(
                          'Navegar',
                          style: TextStyle(fontSize: 12),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 6),
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
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(8),
                      ),
                      tooltip: 'Editar Local',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PlaceEditScreen(place: place),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
