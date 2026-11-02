import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_tip.dart';
import '../../itinerary/providers/itinerary_provider.dart';
import '../providers/tips_provider.dart';

class TipsScreen extends ConsumerStatefulWidget {
  const TipsScreen({super.key});

  @override
  ConsumerState<TipsScreen> createState() => _TipsScreenState();
}

class _TipsScreenState extends ConsumerState<TipsScreen> {
  String _selectedScope = 'Todas'; // 'Todas', 'Gerais', 'Por Dia'
  String _selectedStatus = 'Todos'; // 'Todos', 'Pendentes', 'Concluídos'
  String _search = '';

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
      case 'strategy':
        return Icons.military_tech_rounded;
      case 'money':
        return Icons.attach_money_rounded;
      case 'packing':
        return Icons.backpack_rounded;
      default:
        return Icons.lightbulb_rounded;
    }
  }

  void _showAddTipDialog(BuildContext context) {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    String category = 'general';
    int dayNumber = 0;
    final days = ref.read(itineraryProvider).value ?? [];

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
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Adicionar Dica ou Lembrete',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Título',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: contentController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Descrição / Detalhes',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: category,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                value: 'general',
                                child: Text('Geral'),
                              ),
                              DropdownMenuItem(
                                value: 'toll',
                                child: Text('Pedágios / Trânsito'),
                              ),
                              DropdownMenuItem(
                                value: 'money',
                                child: Text('Dinheiro / Cartões'),
                              ),
                              DropdownMenuItem(
                                value: 'shopping',
                                child: Text('Compras'),
                              ),
                              DropdownMenuItem(
                                value: 'dining',
                                child: Text('Alimentação'),
                              ),
                              DropdownMenuItem(
                                value: 'packing',
                                child: Text('Itens / Bagagem'),
                              ),
                              DropdownMenuItem(
                                value: 'strategy',
                                child: Text('Estratégia Parques'),
                              ),
                              DropdownMenuItem(
                                value: 'ticket',
                                child: Text('Ingressos'),
                              ),
                              DropdownMenuItem(
                                value: 'airport',
                                child: Text('Voo / Aeroporto'),
                              ),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => category = val);
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            initialValue: dayNumber,
                            decoration: const InputDecoration(
                              labelText: 'Aplicar a',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 0,
                                child: Text('Geral (Todos os dias)'),
                              ),
                              ...days.where((d) => d.dayNumber > 0).map((d) {
                                return DropdownMenuItem(
                                  value: d.dayNumber,
                                  child: Text('Dia ${d.dayNumber}'),
                                );
                              }),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setModalState(() => dayNumber = val);
                              }
                            },
                          ),
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
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: () {
                          final title = titleController.text.trim();
                          final content = contentController.text.trim();
                          if (title.isNotEmpty) {
                            ref
                                .read(tipsProvider.notifier)
                                .addTip(
                                  TripTip(
                                    category: category,
                                    dayNumber: dayNumber,
                                    title: title,
                                    content: content,
                                  ),
                                );
                            Navigator.pop(ctx);
                          }
                        },
                        child: const Text('Salvar Dica'),
                      ),
                    ),
                  ],
                ),
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
    final days = ref.watch(itineraryProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(title: const Text('💡 Dicas & Lembretes')),
      body: Column(
        children: [
          // Filter Chips Row
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: const Text('Todas'),
                  selected: _selectedScope == 'Todas',
                  onSelected: (_) => setState(() => _selectedScope = 'Todas'),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Dicas Gerais'),
                  selected: _selectedScope == 'Gerais',
                  onSelected: (_) => setState(() => _selectedScope = 'Gerais'),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Por Dia'),
                  selected: _selectedScope == 'Por Dia',
                  onSelected: (_) => setState(() => _selectedScope = 'Por Dia'),
                ),
                const SizedBox(width: 12),
                const Text('|', style: TextStyle(color: Colors.grey)),
                const SizedBox(width: 12),
                ChoiceChip(
                  label: const Text('Pendentes'),
                  selected: _selectedStatus == 'Pendentes',
                  onSelected: (_) => setState(
                    () => _selectedStatus = _selectedStatus == 'Pendentes'
                        ? 'Todos'
                        : 'Pendentes',
                  ),
                ),
                const SizedBox(width: 6),
                ChoiceChip(
                  label: const Text('Concluídos'),
                  selected: _selectedStatus == 'Concluídos',
                  onSelected: (_) => setState(
                    () => _selectedStatus = _selectedStatus == 'Concluídos'
                        ? 'Todos'
                        : 'Concluídos',
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              onChanged: (value) => setState(() => _search = value),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText:
                    'Pesquisar dicas (ex: cartões, pedágios, malas, horários)...',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),

          // Tips List
          Expanded(
            child: tipsAsync.when(
              data: (tips) {
                final filtered = tips.where((t) {
                  final q = _search.trim().toLowerCase();

                  // Scope filter (Item 10)
                  if (_selectedScope == 'Gerais' && t.dayNumber != 0) {
                    return false;
                  }
                  if (_selectedScope == 'Por Dia' && t.dayNumber == 0) {
                    return false;
                  }

                  // Status filter
                  if (_selectedStatus == 'Pendentes' && t.isCompleted) {
                    return false;
                  }
                  if (_selectedStatus == 'Concluídos' && !t.isCompleted) {
                    return false;
                  }

                  // Search query
                  final textMatches =
                      q.isEmpty ||
                      t.title.toLowerCase().contains(q) ||
                      t.content.toLowerCase().contains(q) ||
                      t.category.toLowerCase().contains(q);
                  return textMatches;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.checklist_rounded,
                          size: 48,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Nenhuma dica encontrada nesta categoria',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 14,
                          ),
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
                    final dayObj = tip.dayNumber > 0
                        ? days
                              .where((d) => d.dayNumber == tip.dayNumber)
                              .firstOrNull
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                      ),
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 4,
                        ),
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
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                tip.title,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  decoration: tip.isCompleted
                                      ? TextDecoration.lineThrough
                                      : null,
                                  color: tip.isCompleted
                                      ? Colors.grey
                                      : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            if (tip.dayNumber > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'Dia ${tip.dayNumber}${dayObj != null ? ' (${dayObj.displayDate})' : ''}',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              )
                            else
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'Dica Geral',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF2563EB),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            tip.content,
                            style: TextStyle(
                              fontSize: 13,
                              color: tip.isCompleted
                                  ? Colors.grey[500]
                                  : const Color(0xFF475569),
                            ),
                          ),
                        ),
                        trailing: Checkbox(
                          value: tip.isCompleted,
                          activeColor: const Color(0xFF0F766E),
                          onChanged: (val) {
                            if (val != null && tip.id != null) {
                              ref
                                  .read(tipsProvider.notifier)
                                  .toggleTip(tip.id!, val);
                            }
                          },
                        ),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Erro: $err')),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        tooltip: 'Adicionar Dica',
        onPressed: () => _showAddTipDialog(context),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
