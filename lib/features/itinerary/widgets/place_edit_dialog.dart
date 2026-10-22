import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../providers/itinerary_provider.dart';

class PlaceEditDialog extends ConsumerStatefulWidget {
  final ItineraryPlace place;

  const PlaceEditDialog({super.key, required this.place});

  @override
  ConsumerState<PlaceEditDialog> createState() => _PlaceEditDialogState();
}

class _PlaceEditDialogState extends ConsumerState<PlaceEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late TextEditingController _notesController;
  late TextEditingController _linkController;
  late int _selectedDay;
  late String _parking;
  late int _parkingCost;
  late List<String> _links;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.place.name);
    _timeController = TextEditingController(text: widget.place.time);
    _notesController = TextEditingController(text: widget.place.notes);
    _linkController = TextEditingController();
    _selectedDay = widget.place.dayNumber;
    _parking = widget.place.parking;
    _parkingCost = widget.place.parkingCost;
    _links = List.from(widget.place.links);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _notesController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  void _addLink() {
    final text = _linkController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _links.add(text);
        _linkController.clear();
      });
    }
  }

  void _save() {
    final updated = widget.place.copyWith(
      name: _nameController.text.trim(),
      time: _timeController.text.trim(),
      notes: _notesController.text.trim(),
      dayNumber: _selectedDay,
      parking: _parking,
      parkingCost: _parkingCost,
      links: _links,
    );

    ref.read(itineraryProvider.notifier).updatePlace(updated);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Place updated successfully!')),
    );
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Place'),
        content: Text('Are you sure you want to remove "${widget.place.name}" from the itinerary?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx); // Close alert
              Navigator.pop(context); // Close sheet
              if (widget.place.id != null) {
                ref.read(itineraryProvider.notifier).deletePlace(widget.place.id!);
              }
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.edit_location_alt_rounded, color: Color(0xFF0F766E)),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Edit Itinerary Stop',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  tooltip: 'Delete stop',
                  onPressed: _delete,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Move to another Day selector
            Row(
              children: [
                const Text('Scheduled for: ', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _selectedDay,
                  items: List.generate(20, (index) => index + 1).map((d) {
                    return DropdownMenuItem(
                      value: d,
                      child: Text('Day $d'),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedDay = val);
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Name
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Place Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Time
            TextField(
              controller: _timeController,
              decoration: const InputDecoration(
                labelText: 'Time (e.g. 09:00 - 12:00)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.schedule_outlined),
              ),
            ),
            const SizedBox(height: 12),

            // Notes
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Personal Notes / Reminders',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.note_alt_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Links (Instagram, TikTok, YouTube)
            const Text(
              'Attached Links (Reels, TikTok, Menus):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _linkController,
                    decoration: const InputDecoration(
                      hintText: 'https://instagram.com/reel/...',
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixIcon: Icon(Icons.link_rounded),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonal(
                  onPressed: _addLink,
                  child: const Text('Add'),
                ),
              ],
            ),
            if (_links.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                children: _links.map((link) {
                  return Chip(
                    label: Text(
                      link.length > 25 ? '${link.substring(0, 22)}...' : link,
                      style: const TextStyle(fontSize: 11),
                    ),
                    deleteIcon: const Icon(Icons.close_rounded, size: 14),
                    onDeleted: () {
                      setState(() => _links.remove(link));
                    },
                  );
                }).toList(),
              ),
            ],

            const SizedBox(height: 20),

            // Save Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text('Save Changes'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
