import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../providers/itinerary_provider.dart';

class PlaceChecklistWidget extends ConsumerStatefulWidget {
  final ItineraryPlace place;

  const PlaceChecklistWidget({super.key, required this.place});

  @override
  ConsumerState<PlaceChecklistWidget> createState() =>
      _PlaceChecklistWidgetState();
}

class _PlaceChecklistWidgetState extends ConsumerState<PlaceChecklistWidget> {
  late bool _isExpanded;
  final TextEditingController _addItemController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.place.checklist.isNotEmpty;
  }

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  void _addItem(int placeId) {
    final text = _addItemController.text.trim();
    if (text.isNotEmpty) {
      ref.read(itineraryProvider.notifier).addPlaceChecklistItem(placeId, text);
      _addItemController.clear();
      if (!_isExpanded) {
        setState(() => _isExpanded = true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(itineraryProvider).value ?? [];
    final currentPlace =
        days
            .expand((d) => d.places)
            .where((p) => p.id == widget.place.id)
            .firstOrNull ??
        widget.place;

    final checklist = currentPlace.checklist;
    final placeId = currentPlace.id;

    if (checklist.isEmpty && !_isExpanded) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 18,
                  color: const Color(0xFF0F766E),
                ),
                const SizedBox(width: 8),
                const Text(
                  '+ Adicionar checklist a este local',
                  style: TextStyle(
                    fontSize: 13,
                    color: Color(0xFF0F766E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final completedCount = checklist.where((c) => c.isCompleted).length;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      size: 20,
                      color: Color(0xFF0F766E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Checklist do Local (${checklist.length} itens)',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E293B),
                          ),
                        ),
                        if (checklist.isNotEmpty)
                          Text(
                            '$completedCount de ${checklist.length} itens concluídos',
                            style: TextStyle(
                              fontSize: 12,
                              color: completedCount == checklist.length
                                  ? const Color(0xFF16A34A)
                                  : const Color(0xFF64748B),
                              fontWeight: completedCount == checklist.length
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Column(
                children: [
                  if (checklist.isNotEmpty)
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: checklist.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Color(0xFFF1F5F9)),
                      itemBuilder: (context, index) {
                        final item = checklist[index];
                        return ListTile(
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                          ),
                          leading: Checkbox(
                            value: item.isCompleted,
                            activeColor: const Color(0xFF0F766E),
                            onChanged: (_) {
                              if (placeId != null) {
                                ref
                                    .read(itineraryProvider.notifier)
                                    .togglePlaceChecklistItem(placeId, item.id);
                              }
                            },
                          ),
                          title: Text(
                            item.text,
                            style: TextStyle(
                              fontSize: 13,
                              decoration: item.isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: item.isCompleted
                                  ? Colors.grey
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(
                              Icons.close,
                              size: 16,
                              color: Colors.grey,
                            ),
                            tooltip: 'Remover item',
                            onPressed: () {
                              if (placeId != null) {
                                ref
                                    .read(itineraryProvider.notifier)
                                    .removePlaceChecklistItem(placeId, item.id);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  const SizedBox(height: 8),
                  // Add new item input field
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _addItemController,
                          decoration: InputDecoration(
                            hintText: 'Adicionar novo item...',
                            hintStyle: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: Color(0xFF0F766E),
                                width: 1.5,
                              ),
                            ),
                          ),
                          style: const TextStyle(fontSize: 13),
                          onSubmitted: (_) {
                            if (placeId != null) _addItem(placeId);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add, size: 18),
                        style: IconButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(10),
                        ),
                        onPressed: () {
                          if (placeId != null) _addItem(placeId);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
