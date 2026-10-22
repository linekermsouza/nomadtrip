import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../providers/itinerary_provider.dart';
import '../widgets/day_selector.dart';
import '../widgets/lodging_badge.dart';
import '../widgets/place_card.dart';
import '../widgets/place_edit_dialog.dart';

class ItineraryScreen extends ConsumerWidget {
  const ItineraryScreen({super.key});

  void _addNewPlace(BuildContext context, int dayNumber) {
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
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => PlaceEditDialog(place: newPlace),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = ref.watch(currentDayProvider);
    final selectedDayNum = ref.watch(selectedDayNumberProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('🌴 Florida 2026'),
            const Spacer(),
            if (day != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${day.places.where((p) => p.isVisited).length}/${day.places.length} Visited',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F766E)),
                ),
              ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Day Selector Horizontal List
          const DaySelector(),

          // Lodging & Wakeup City Banner
          if (day != null) LodgingBadge(day: day),

          // Timeline List of Places
          Expanded(
            child: (day == null || day.places.isEmpty)
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.event_note_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No stops scheduled for Day $selectedDayNum yet',
                          style: TextStyle(color: Colors.grey[600], fontSize: 15),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 80, top: 4),
                    itemCount: day.places.length,
                    itemBuilder: (context, index) {
                      final place = day.places[index];
                      return PlaceCard(place: place);
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add Stop'),
        onPressed: () => _addNewPlace(context, selectedDayNum),
      ),
    );
  }
}
