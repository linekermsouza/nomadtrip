import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_tip.dart';
import '../providers/tips_provider.dart';

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen> {
  String _selectedFilter = 'All'; // 'All', 'Pending', 'Completed'

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'toll':
        return Icons.toll_rounded;
      case 'ticket':
        return Icons.confirmation_number_rounded;
      case 'dining':
        return Icons.restaurant_rounded;
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'pitstop':
        return Icons.local_gas_station_rounded;
      case 'timing':
        return Icons.schedule_rounded;
      case 'airport':
        return Icons.flight_takeoff_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  void _showAddTipDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'general';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Travel Tip or Reminder',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Description / Details',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Category: ', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 8),
                      DropdownButton<String>(
                        value: category,
                        items: const [
                          DropdownMenuItem(value: 'general', child: Text('General')),
                          DropdownMenuItem(value: 'toll', child: Text('Tolls / SunPass')),
                          DropdownMenuItem(value: 'ticket', child: Text('Tickets / Passes')),
                          DropdownMenuItem(value: 'dining', child: Text('Dining')),
                          DropdownMenuItem(value: 'shopping', child: Text('Shopping')),
                          DropdownMenuItem(value: 'airport', child: Text('Flight / Airport')),
                        ],
                        onChanged: (val) {
                          if (val != null) setModalState(() => category = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF0F766E),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        final title = titleController.text.trim();
                        final content = contentController.text.trim();
                        if (title.isNotEmpty) {
                          ref.read(tipsProvider.notifier).addTip(
                                TripTip(
                                  category: category,
                                  title: title,
                                  content: content,
                                ),
                              );
                          Navigator.pop(ctx);
                        }
                      },
                      child: const Text('Add Reminder'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final tipsAsync = ref.watch(tipsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('💡 Tips & Reminders'),
      ),
      body: Column(
        children: [
          // Filter Chips (All, Pending, Completed)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('All'),
                  selected: _selectedFilter == 'All',
                  onSelected: (val) => setState(() => _selectedFilter = 'All'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Pending'),
                  selected: _selectedFilter == 'Pending',
                  onSelected: (val) => setState(() => _selectedFilter = 'Pending'),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Completed'),
                  selected: _selectedFilter == 'Completed',
                  onSelected: (val) => setState(() => _selectedFilter = 'Completed'),
                ),
              ],
            ),
          ),

          // Tips List
          Expanded(
            child: tipsAsync.when(
              data: (tips) {
                final filtered = tips.where((t) {
                  if (_selectedFilter == 'Pending') return !t.isCompleted;
                  if (_selectedFilter == 'Completed') return t.isCompleted;
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.checklist_rounded, size: 48, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text(
                          'No reminders in this category',
                          style: TextStyle(color: Colors.grey[600], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(top: 4, bottom: 80),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final tip = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: tip.isCompleted
                              ? const Color(0xFFDCFCE7)
                              : const Color(0xFFFEF3C7),
                          child: Icon(
                            _getCategoryIcon(tip.category),
                            color: tip.isCompleted
                                ? const Color(0xFF16A34A)
                                : const Color(0xFFD97706),
                            size: 20,
                          ),
                        ),
                        title: Text(
                          tip.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: tip.isCompleted ? TextDecoration.lineThrough : null,
                            color: tip.isCompleted ? Colors.grey : const Color(0xFF0F172A),
                          ),
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tip.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: tip.isCompleted ? Colors.grey[500] : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        trailing: Checkbox(
                          value: tip.isCompleted,
                          activeColor: const Color(0xFF0F766E),
                          onChanged: (val) {
                            if (val != null && tip.id != null) {
                              ref.read(tipsProvider.notifier).toggleTip(tip.id!, val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        tooltip: 'Add Tip',
        onPressed: () => _showAddTipDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
