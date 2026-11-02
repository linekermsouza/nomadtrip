import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/database/app_database.dart';
import '../../../core/models/trip.dart';
import '../../../core/services/backup_service.dart';
import '../../home/screens/home_screen.dart';
import '../providers/trips_provider.dart';

class TripListScreen extends ConsumerWidget {
  const TripListScreen({super.key});

  void _openTrip(BuildContext context, WidgetRef ref, int tripId) async {
    await ref.read(selectedTripIdProvider.notifier).selectTrip(tripId);
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    }
  }

  void _showCreateTripDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController(text: 'Minha Viagem');
    DateTime startDate = DateTime.now();
    DateTime endDate = DateTime.now().add(const Duration(days: 6));
    final dateFormatter = DateFormat('yyyy-MM-dd');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysCount = endDate.difference(startDate).inDays + 1;

            return AlertDialog(
              title: const Text('Novo Roteiro de Viagem'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome da Viagem',
                        hintText: 'Ex: Flórida 2026',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0F766E),
                      ),
                      title: const Text('Data de Início'),
                      subtitle: Text(dateFormatter.format(startDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event,
                        color: Color(0xFF0F766E),
                      ),
                      title: const Text('Data de Término'),
                      subtitle: Text(dateFormatter.format(endDate)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate.isBefore(startDate)
                              ? startDate
                              : endDate,
                          firstDate: startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Color(0xFF0F766E),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Duração calculada: $daysCount dia(s)',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isNotEmpty) {
                      Navigator.pop(ctx);
                      final newTrip = Trip(
                        name: name,
                        startDate: dateFormatter.format(startDate),
                        endDate: dateFormatter.format(endDate),
                        createdAt: DateTime.now(),
                      );
                      final newId = await ref
                          .read(tripsProvider.notifier)
                          .createTrip(newTrip);
                      if (context.mounted) {
                        _openTrip(context, ref, newId);
                      }
                    }
                  },
                  child: const Text('Criar Roteiro'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showImportTripDialog(BuildContext context, WidgetRef ref) async {
    try {
      final data = await BackupService.pickAndParseTripFile();
      if (data == null || !context.mounted) return;

      Map<String, dynamic> tripMeta = {};
      if (data.containsKey('trip') && data['trip'] is Map) {
        tripMeta = Map<String, dynamic>.from(data['trip'] as Map);
      } else {
        tripMeta = {
          'name': data['tripName'] ?? 'Roteiro Importado',
          'start_date': data['startDate'] ?? '2026-11-24',
          'end_date': data['endDate'] ?? '2026-12-13',
        };
      }

      final nameController = TextEditingController(
        text: (tripMeta['name'] as String?) ?? 'Meu Roteiro',
      );
      final startDateController = TextEditingController(
        text: (tripMeta['start_date'] ?? tripMeta['startDate'] ?? '2026-11-24')
            .toString(),
      );
      final endDateController = TextEditingController(
        text: (tripMeta['end_date'] ?? tripMeta['endDate'] ?? '2026-12-13')
            .toString(),
      );

      final daysCount = (data['days'] as List?)?.length ?? 0;
      final placesCount = (data['places'] as List?)?.length ?? 0;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Importar Roteiro'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arquivo com $daysCount dias e $placesCount locais detectado.',
                  style: const TextStyle(
                    fontSize: 13,
                    color: Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Roteiro',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: startDateController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Início (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: endDateController,
                  decoration: const InputDecoration(
                    labelText: 'Data de Término (YYYY-MM-DD)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF0F766E),
              ),
              onPressed: () async {
                Navigator.pop(ctx);
                final newId = await ref
                    .read(tripsProvider.notifier)
                    .importTrip(
                      data,
                      customName: nameController.text.trim(),
                      customStartDate: startDateController.text.trim(),
                      customEndDate: endDateController.text.trim(),
                    );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Roteiro importado com sucesso!'),
                    ),
                  );
                  _openTrip(context, ref, newId);
                }
              },
              child: const Text('Confirmar e Importar'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao importar arquivo: $e')));
      }
    }
  }

  void _showEditTripDialog(BuildContext context, WidgetRef ref, Trip trip) {
    final nameController = TextEditingController(text: trip.name);
    DateTime startDate = DateTime.tryParse(trip.startDate) ?? DateTime.now();
    DateTime endDate = DateTime.tryParse(trip.endDate) ?? DateTime.now();
    final dateFormatter = DateFormat('yyyy-MM-dd');

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final daysCount = endDate.difference(startDate).inDays + 1;

            return AlertDialog(
              title: const Text('Editar Informações do Roteiro'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nome do Roteiro',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF0F766E),
                      ),
                      title: const Text('Data de Início'),
                      subtitle: Text(dateFormatter.format(startDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: startDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() {
                            startDate = picked;
                            if (endDate.isBefore(startDate)) {
                              endDate = startDate;
                            }
                          });
                        }
                      },
                    ),
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      leading: const Icon(
                        Icons.event,
                        color: Color(0xFF0F766E),
                      ),
                      title: const Text('Data de Término'),
                      subtitle: Text(dateFormatter.format(endDate)),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: endDate.isBefore(startDate)
                              ? startDate
                              : endDate,
                          firstDate: startDate,
                          lastDate: DateTime(2035),
                        );
                        if (picked != null) {
                          setDialogState(() => endDate = picked);
                        }
                      },
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Duração: $daysCount dia(s)',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F766E),
                  ),
                  onPressed: () async {
                    final updated = trip.copyWith(
                      name: nameController.text.trim(),
                      startDate: dateFormatter.format(startDate),
                      endDate: dateFormatter.format(endDate),
                    );

                    try {
                      await ref
                          .read(tripsProvider.notifier)
                          .updateTrip(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Roteiro atualizado com sucesso!'),
                          ),
                        );
                      }
                    } on TripReductionException catch (e) {
                      // Item 23: Error message if places exist on truncated days!
                      if (context.mounted) {
                        showDialog(
                          context: context,
                          builder: (errCtx) => AlertDialog(
                            title: const Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Não é possível reduzir dias'),
                              ],
                            ),
                            content: Text(e.message),
                            actions: [
                              FilledButton(
                                onPressed: () => Navigator.pop(errCtx),
                                child: const Text('Entendido'),
                              ),
                            ],
                          ),
                        );
                      }
                    } catch (err) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Erro: $err')));
                      }
                    }
                  },
                  child: const Text('Salvar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showExportOptions(BuildContext context, Trip trip) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Exportar "${trip.name}"',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFEFF6FF),
                  child: Icon(
                    Icons.file_present_rounded,
                    color: Color(0xFF2563EB),
                  ),
                ),
                title: const Text('Exportar em formato nomadtrip (.ntrip)'),
                subtitle: const Text(
                  'Arquivo JSON completo para backup e importação no app',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  BackupService.exportTripNtrip(trip.id!, trip.name);
                },
              ),
              const Divider(),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xFFF0FDF4),
                  child: Icon(Icons.article_rounded, color: Color(0xFF16A34A)),
                ),
                title: const Text('Exportar em Markdown (.md)'),
                subtitle: const Text(
                  'Documento formatado e legível para ler ou imprimir',
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  BackupService.exportTripMarkdown(trip.id!, trip.name);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _deleteTrip(BuildContext context, WidgetRef ref, Trip trip) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Roteiro'),
        content: Text(
          'Deseja realmente excluir o roteiro "${trip.name}"? Todos os dias e locais cadastrados nele serão apagados permanentemente.',
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
              ref.read(tripsProvider.notifier).deleteTrip(trip.id!);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Roteiro excluído.')),
              );
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(tripsProvider);
    final selectedTripId = ref.watch(selectedTripIdProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('🌴 nomadtrip — Meus Roteiros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Importar Roteiro (.ntrip)',
            onPressed: () => _showImportTripDialog(context, ref),
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            // First time empty state as requested (Item 23)
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.travel_explore_rounded,
                        size: 72,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Qual o roteiro da sua próxima viagem?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Crie um roteiro do zero definindo as datas ou importe um arquivo .ntrip pré-configurado.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: FilledButton.icon(
                        icon: const Icon(Icons.add_rounded),
                        label: const Text(
                          'Criar Novo Roteiro',
                          style: TextStyle(fontSize: 15),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0F766E),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _showCreateTripDialog(context, ref),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text(
                          'Importar Roteiro (.ntrip / .json)',
                          style: TextStyle(fontSize: 15),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0F766E),
                          side: const BorderSide(color: Color(0xFF0F766E)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: () => _showImportTripDialog(context, ref),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: Text(
                  'Selecione um roteiro para explorar:',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF475569),
                  ),
                ),
              ),
              ...trips.map((trip) {
                final isSelected = trip.id == selectedTripId;

                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  elevation: isSelected ? 3 : 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isSelected
                          ? const Color(0xFF0F766E)
                          : const Color(0xFFE2E8F0),
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _openTrip(context, ref, trip.id!),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isSelected
                                    ? const Color(0xFF0F766E)
                                    : const Color(0xFFF1F5F9),
                                foregroundColor: isSelected
                                    ? Colors.white
                                    : const Color(0xFF0F766E),
                                child: const Icon(
                                  Icons.flight_takeoff_rounded,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      trip.name,
                                      style: const TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${trip.startDate} até ${trip.endDate} • ${trip.totalDays} dias',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBF1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'Ativo',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0F766E),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(
                                  Icons.file_upload_outlined,
                                  size: 16,
                                ),
                                label: const Text('Exportar'),
                                onPressed: () =>
                                    _showExportOptions(context, trip),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, size: 18),
                                tooltip: 'Editar Informações',
                                onPressed: () =>
                                    _showEditTripDialog(context, ref, trip),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 18,
                                  color: Colors.red,
                                ),
                                tooltip: 'Excluir',
                                onPressed: () =>
                                    _deleteTrip(context, ref, trip),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Erro: $err')),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
        tooltip: 'Criar Roteiro',
        onPressed: () => _showCreateTripDialog(context, ref),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
