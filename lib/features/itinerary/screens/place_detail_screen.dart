import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/services/image_cache_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/navigation_launcher.dart';
import '../providers/itinerary_provider.dart';
import 'place_edit_screen.dart';

class PlaceDetailScreen extends ConsumerWidget {
  final ItineraryPlace place;

  const PlaceDetailScreen({super.key, required this.place});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch latest version of this place from provider
    final days = ref.watch(itineraryProvider).value ?? [];
    final currentPlace =
        days
            .expand((d) => d.places)
            .where((p) => p.id == place.id)
            .firstOrNull ??
        place;

    final categoryColor = _getCategoryColor(currentPlace.category);
    final distanceMeters =
        (currentPlace.latitude != 0.0 && currentPlace.longitude != 0.0)
        ? LocationService.instance.calculateDistanceInMeters(
            currentPlace.latitude,
            currentPlace.longitude,
          )
        : null;
    final distanceText = LocationService.instance.formatDistance(
      distanceMeters,
    );

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            leading: CircleAvatar(
              backgroundColor: Colors.black45,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              CircleAvatar(
                backgroundColor: Colors.black45,
                child: IconButton(
                  icon: const Icon(
                    Icons.edit_note_rounded,
                    color: Colors.white,
                  ),
                  tooltip: 'Editar Local',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PlaceEditScreen(place: currentPlace),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  CachedPlaceImage(
                    imageUrl: currentPlace.imageUrl,
                    category: currentPlace.category,
                    width: double.infinity,
                    height: 250,
                    fit: BoxFit.cover,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black45,
                          Colors.transparent,
                          Colors.black87,
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    right: 16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (currentPlace.zone.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 6),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white24,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Área: ${currentPlace.zone}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        Text(
                          currentPlace.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(color: Colors.black87, blurRadius: 4),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Meta info row
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Chip(
                        avatar: Icon(
                          Icons.schedule,
                          size: 16,
                          color: categoryColor,
                        ),
                        label: Text(
                          '${currentPlace.dayNumber == 0 ? 'Sem Dia' : 'Dia ${currentPlace.dayNumber}'} • ${currentPlace.time}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: categoryColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                      Chip(
                        avatar: Icon(
                          _getCategoryIcon(currentPlace.category),
                          size: 16,
                          color: categoryColor,
                        ),
                        label: Text(
                          currentPlace.category.toUpperCase(),
                          style: TextStyle(
                            color: categoryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 11,
                          ),
                        ),
                        backgroundColor: categoryColor.withValues(alpha: 0.1),
                        side: BorderSide.none,
                      ),
                      if (currentPlace.city.isNotEmpty)
                        Chip(
                          avatar: const Icon(Icons.location_city, size: 16),
                          label: Text(currentPlace.city),
                          side: const BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                      if (distanceText.isNotEmpty)
                        Chip(
                          avatar: const Icon(
                            Icons.navigation,
                            size: 16,
                            color: Color(0xFF0F766E),
                          ),
                          label: Text(distanceText),
                          backgroundColor: const Color(0xFFCCFBF1),
                          side: BorderSide.none,
                        ),
                      // ONLY show reservation badge when true (Item 14)
                      if (currentPlace.requiresReservation)
                        const Chip(
                          avatar: Icon(
                            Icons.event_available,
                            size: 16,
                            color: Colors.white,
                          ),
                          label: Text(
                            'Reserva Necessária',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          backgroundColor: Color(0xFFDC2626),
                          side: BorderSide.none,
                        ),
                      if (currentPlace.isAlternative)
                        const Chip(
                          avatar: Icon(
                            Icons.alt_route,
                            size: 16,
                            color: Color(0xFFB45309),
                          ),
                          label: Text(
                            'Opção Alternativa',
                            style: TextStyle(color: Color(0xFFB45309)),
                          ),
                          backgroundColor: Color(0xFFFEF3C7),
                          side: BorderSide.none,
                        ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Coaster / Attraction Specs Card (Items 15 & 16)
                  if (currentPlace.minHeightCm > 0 ||
                      currentPlace.recommendedAge.isNotEmpty ||
                      currentPlace.adrenalineLevel.isNotEmpty ||
                      currentPlace.hasDizzinessWarning ||
                      currentPlace.avgWaitMinutes > 0 ||
                      currentPlace.durationMinutes > 0) ...[
                    Card(
                      elevation: 0,
                      color: const Color(0xFFF8FAFC),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(
                                  Icons.speed_rounded,
                                  color: Color(0xFF6366F1),
                                  size: 20,
                                ),
                                SizedBox(width: 8),
                                Text(
                                  'Detalhes da Atração / Montanha-Russa',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Wrap(
                              spacing: 16,
                              runSpacing: 12,
                              children: [
                                if (currentPlace.minHeightCm > 0)
                                  _SpecItem(
                                    icon: Icons.height_rounded,
                                    label: 'Altura mínima',
                                    value:
                                        '${currentPlace.minHeightCm} cm (~${(currentPlace.minHeightCm / 2.54).round()} in)',
                                  ),
                                if (currentPlace.recommendedAge.isNotEmpty)
                                  _SpecItem(
                                    icon: Icons.child_care_rounded,
                                    label: 'Idade recomendada',
                                    value: currentPlace.recommendedAge,
                                  ),
                                if (currentPlace.adrenalineLevel.isNotEmpty)
                                  _SpecItem(
                                    icon: Icons.bolt_rounded,
                                    label: 'Nível de adrenalina',
                                    value: currentPlace.adrenalineLevel,
                                    valueColor: _getAdrenalineColor(
                                      currentPlace.adrenalineLevel,
                                    ),
                                  ),
                                if (currentPlace.avgWaitMinutes > 0)
                                  _SpecItem(
                                    icon: Icons.hourglass_top_rounded,
                                    label: 'Fila média',
                                    value:
                                        '~${currentPlace.avgWaitMinutes} min',
                                  ),
                                if (currentPlace.durationMinutes > 0)
                                  _SpecItem(
                                    icon: Icons.timer_outlined,
                                    label: 'Duração',
                                    value:
                                        '${currentPlace.durationMinutes} min',
                                  ),
                              ],
                            ),
                            if (currentPlace.hasDizzinessWarning) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFFBEB),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: const Color(0xFFFDE68A),
                                  ),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.warning_amber_rounded,
                                      size: 18,
                                      color: Color(0xFFD97706),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Aviso: atração que gira bastante ou simulador com movimentos fortes. Risco de enjoo!',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Description
                  if (currentPlace.rawDescription.isNotEmpty) ...[
                    const Text(
                      'Descrição e Roteiro',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentPlace.rawDescription,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: Color(0xFF334155),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Notes
                  if (currentPlace.notes.isNotEmpty) ...[
                    const Text(
                      'Anotações Pessoais',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF3C7),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFFCD34D)),
                      ),
                      child: Text(
                        currentPlace.notes,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF78350F),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Parking info
                  if (currentPlace.parking != 'Unknown') ...[
                    const Text(
                      'Estacionamento',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.local_parking_rounded,
                          color: currentPlace.parking == 'Free'
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFD97706),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          currentPlace.parking == 'Free'
                              ? 'Estacionamento Gratuito'
                              : 'Estacionamento Pago${currentPlace.parkingCost > 0 ? ' (~US\$${currentPlace.parkingCost})' : ''}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Links (Instagram, YouTube, etc.)
                  if (currentPlace.links.isNotEmpty) ...[
                    const Text(
                      'Links e Vídeos de Inspiração',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: currentPlace.links.map((link) {
                        return ActionChip(
                          avatar: const Icon(
                            Icons.link_rounded,
                            size: 16,
                            color: Color(0xFF0F766E),
                          ),
                          label: Text(
                            link.length > 35
                                ? '${link.substring(0, 32)}...'
                                : link,
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontSize: 12,
                            ),
                          ),
                          onPressed: () => NavigationLauncher.openUrl(link),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                  ],

                  const SizedBox(height: 70), // Bottom padding for actions
                ],
              ),
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          children: [
            // Visited toggle button
            OutlinedButton.icon(
              icon: Icon(
                currentPlace.isVisited
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: currentPlace.isVisited
                    ? const Color(0xFF16A34A)
                    : Colors.grey,
              ),
              label: Text(
                currentPlace.isVisited ? 'Visitado' : 'Marcar Visitado',
                style: TextStyle(
                  color: currentPlace.isVisited
                      ? const Color(0xFF16A34A)
                      : const Color(0xFF334155),
                  fontSize: 12,
                ),
              ),
              onPressed: () {
                if (currentPlace.id != null) {
                  ref
                      .read(itineraryProvider.notifier)
                      .togglePlaceVisited(
                        currentPlace.id!,
                        !currentPlace.isVisited,
                      );
                }
              },
            ),
            const SizedBox(width: 12),
            // Navigate button
            Expanded(
              child: FilledButton.icon(
                icon: const Icon(Icons.navigation_rounded, size: 18),
                label: const Text('Navegar GPS'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  NavigationLauncher.showNavigationSheet(
                    context,
                    placeName: currentPlace.name,
                    latitude: currentPlace.latitude,
                    longitude: currentPlace.longitude,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getAdrenalineColor(String level) {
    switch (level.toLowerCase()) {
      case 'baixo':
        return const Color(0xFF16A34A);
      case 'médio':
      case 'medio':
        return const Color(0xFFD97706);
      case 'alto':
        return const Color(0xFFEA580C);
      case 'extremo':
        return const Color(0xFFDC2626);
      default:
        return const Color(0xFF0F766E);
    }
  }
}

class _SpecItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _SpecItem({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF64748B)),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: valueColor ?? const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
