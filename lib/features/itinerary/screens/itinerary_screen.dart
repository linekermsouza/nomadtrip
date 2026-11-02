import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../places/providers/shared_link_provider.dart';
import '../../trips/providers/trips_provider.dart';
import '../../trips/screens/trip_list_screen.dart';
import '../providers/itinerary_provider.dart';
import '../screens/place_edit_screen.dart';
import '../widgets/day_checklist_widget.dart';
import '../widgets/day_selector.dart';
import '../widgets/lodging_badge.dart';
import '../widgets/place_card.dart';

class ItineraryScreen extends ConsumerStatefulWidget {
  const ItineraryScreen({super.key});

  @override
  ConsumerState<ItineraryScreen> createState() => _ItineraryScreenState();
}

class _ItineraryScreenState extends ConsumerState<ItineraryScreen> {
  bool _isSelectionMode = false;
  final Set<int> _selectedPlaceIds = {};

  void _addNewPlace(BuildContext context, int dayNumber, [String? sharedLink]) {
    final newPlace = ItineraryPlace(
      dayNumber: dayNumber,
      name: '',
      time: '12:00',
      rawDescription: '',
      category: 'attraction',
      city: 'Orlando',
      latitude: 28.5383,
      longitude: -81.3792,
      parking: 'Unknown',
      links: sharedLink == null ? const [] : [sharedLink],
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PlaceEditScreen(place: newPlace)),
    );
  }

  void _toggleSelectAll(List<ItineraryPlace> places) {
    setState(() {
      if (_selectedPlaceIds.length == places.length) {
        _selectedPlaceIds.clear();
      } else {
        _selectedPlaceIds.clear();
        for (final p in places) {
          if (p.id != null) _selectedPlaceIds.add(p.id!);
        }
      }
    });
  }

  void _deleteSelected(BuildContext context) {
    if (_selectedPlaceIds.isEmpty) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Locais Selecionados'),
        content: Text(
          'Deseja realmente excluir os ${_selectedPlaceIds.length} locais selecionados?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(itineraryProvider.notifier)
                  .deletePlaces(_selectedPlaceIds.toList());
              setState(() {
                _selectedPlaceIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Locais excluídos com sucesso!')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  void _deleteAllInDay(BuildContext context, int dayNumber, int count) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Limpar Dia $dayNumber'),
        content: Text(
          'Deseja realmente remover TODOS os $count locais do Dia $dayNumber?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              ref
                  .read(itineraryProvider.notifier)
                  .deletePlacesForDay(dayNumber);
              setState(() {
                _selectedPlaceIds.clear();
                _isSelectionMode = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Todos os locais do Dia $dayNumber foram excluídos.',
                  ),
                ),
              );
            },
            child: const Text('Excluir Todos'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final day = ref.watch(currentDayProvider);
    final selectedDayNum = ref.watch(selectedDayNumberProvider);
    final tripsAsync = ref.watch(tripsProvider);
    final selectedTripId = ref.watch(selectedTripIdProvider);

    final currentTrip = tripsAsync.value
        ?.where((t) => t.id == selectedTripId)
        .firstOrNull;

    ref.listen<String?>(sharedLinkProvider, (previous, next) {
      if (next != null) {
        _addNewPlace(context, selectedDayNum, next);
        ref.read(sharedLinkProvider.notifier).clear();
      }
    });

    final places = day?.places ?? [];

    return Scaffold(
      appBar: AppBar(
        title: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const TripListScreen()),
            );
          },
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🌴 nomadtrip'),
              if (currentTrip != null) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    '• ${currentTrip.name}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ],
          ),
        ),
        actions: [
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all_rounded),
              tooltip: 'Selecionar Todos',
              onPressed: () => _toggleSelectAll(places),
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.red),
              tooltip: 'Excluir Selecionados',
              onPressed: _selectedPlaceIds.isNotEmpty
                  ? () => _deleteSelected(context)
                  : null,
            ),
            IconButton(
              icon: const Icon(Icons.close_rounded),
              tooltip: 'Sair da Seleção',
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedPlaceIds.clear();
                });
              },
            ),
          ] else ...[
            if (places.isNotEmpty)
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded),
                onSelected: (val) {
                  if (val == 'select') {
                    setState(() => _isSelectionMode = true);
                  } else if (val == 'delete_all') {
                    _deleteAllInDay(context, selectedDayNum, places.length);
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(
                    value: 'select',
                    child: Row(
                      children: [
                        Icon(Icons.checklist_rtl_rounded, size: 18),
                        SizedBox(width: 8),
                        Text('Selecionar locais'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete_all',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_forever_rounded,
                          size: 18,
                          color: Colors.red,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Excluir todos do dia',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            IconButton(
              tooltip: 'Trocar de Roteiro',
              icon: const Icon(Icons.swap_horiz_rounded),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TripListScreen()),
                );
              },
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Day Selector Horizontal List (Pinned at top of body)
          const DaySelector(),

          // Selection Mode Action Bar (Item 13)
          if (_isSelectionMode)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: const Color(0xFFF1F5F9),
              child: Row(
                children: [
                  Text(
                    '${_selectedPlaceIds.length} selecionado(s)',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(
                      Icons.delete_outline,
                      size: 16,
                      color: Colors.red,
                    ),
                    label: const Text(
                      'Excluir Selecionados',
                      style: TextStyle(color: Colors.red),
                    ),
                    onPressed: _selectedPlaceIds.isNotEmpty
                        ? () => _deleteSelected(context)
                        : null,
                  ),
                ],
              ),
            ),

          // Scrollable Area: Lodging badge + Checklist + Places all roll together (Item 31)
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 90, top: 4),
              children: [
                // Lodging & Wakeup City Banner (rolls with list!)
                if (day != null) LodgingBadge(day: day),

                // Day Checklist widget (rolls with list!) (Items 17 & 26)
                if (day != null) DayChecklistWidget(day: day),

                const SizedBox(height: 6),

                // Places or Empty State
                if (day == null || places.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.event_note_rounded,
                            size: 48,
                            color: Colors.grey[400],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Nenhum local programado para o Dia $selectedDayNum',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...places.map((place) {
                    final isSelected =
                        place.id != null &&
                        _selectedPlaceIds.contains(place.id);
                    return PlaceCard(
                      place: place,
                      isSelectionMode: _isSelectionMode,
                      isSelected: isSelected,
                      onSelectChanged: (val) {
                        if (place.id == null) return;
                        setState(() {
                          if (val == true) {
                            _selectedPlaceIds.add(place.id!);
                          } else {
                            _selectedPlaceIds.remove(place.id!);
                          }
                        });
                      },
                    );
                  }),
              ],
            ),
          ),
        ],
      ),
      // Item 32: Compact FloatingActionButton with just the icon
      floatingActionButton: FloatingActionButton(
        tooltip: 'Adicionar Local',
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        onPressed: () => _addNewPlace(context, selectedDayNum),
        child: const Icon(Icons.add_location_alt_rounded),
      ),
    );
  }
}
