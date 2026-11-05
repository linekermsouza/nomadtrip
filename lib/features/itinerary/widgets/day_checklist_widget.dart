import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_day.dart';
import '../providers/itinerary_provider.dart';

class DayChecklistWidget extends ConsumerStatefulWidget {
  final TripDay day;

  const DayChecklistWidget({super.key, required this.day});

  @override
  ConsumerState<DayChecklistWidget> createState() => _DayChecklistWidgetState();
}

class _DayChecklistWidgetState extends ConsumerState<DayChecklistWidget> {
  bool _isExpanded = false;
  final TextEditingController _addItemController = TextEditingController();

  @override
  void dispose() {
    _addItemController.dispose();
    super.dispose();
  }

  void _addItem() {
    final text = _addItemController.text.trim();
    if (text.isNotEmpty) {
      ref
          .read(itineraryProvider.notifier)
          .addChecklistItem(widget.day.dayNumber, text);
      _addItemController.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final checklist = widget.day.checklist;
    if (checklist.isEmpty && !_isExpanded) {
      // Discreet prompt to add checklist
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: InkWell(
          onTap: () => setState(() => _isExpanded = true),
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.checklist_rounded,
                  size: 16,
                  color: Colors.grey[600],
                ),
                const SizedBox(width: 6),
                Text(
                  '+ Adicionar checklist do dia',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 0,
      color: const Color(0xFFF8FAFC),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.checklist_rounded,
                    size: 18,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Checklist do Dia ($completedCount/${checklist.length} concluídos)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: const Color(0xFF64748B),
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (_isExpanded) ...[
            const Divider(height: 1, color: Color(0xFFE2E8F0)),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: Column(
                children: [
                  ...checklist.map((item) {
                    return ListTile(
                      dense: true,
                      visualDensity: VisualDensity.compact,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                      leading: Checkbox(
                        value: item.isCompleted,
                        activeColor: const Color(0xFF0F766E),
                        onChanged: (_) {
                          ref
                              .read(itineraryProvider.notifier)
                              .toggleChecklistItem(
                                widget.day.dayNumber,
                                item.id,
                              );
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
                        onPressed: () {
                          ref
                              .read(itineraryProvider.notifier)
                              .removeChecklistItem(
                                widget.day.dayNumber,
                                item.id,
                              );
                        },
                      ),
                    );
                  }),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _addItemController,
                            decoration: const InputDecoration(
                              hintText:
                                  'Novo item (ex: protetor solar, capa de chuva)...',
                              isDense: true,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            onSubmitted: (_) => _addItem(),
                          ),
                        ),
                        const SizedBox(width: 6),
                        IconButton.filled(
                          icon: const Icon(Icons.add, size: 16),
                          style: IconButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            minimumSize: const Size(36, 36),
                          ),
                          onPressed: _addItem,
                        ),
                      ],
                    ),
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
