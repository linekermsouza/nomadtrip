import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/trip_day.dart';
import '../providers/itinerary_provider.dart';

class DayEditDialog extends ConsumerStatefulWidget {
  final TripDay day;

  const DayEditDialog({super.key, required this.day});

  @override
  ConsumerState<DayEditDialog> createState() => _DayEditDialogState();
}

class _DayEditDialogState extends ConsumerState<DayEditDialog> {
  late TextEditingController _titleController;
  late TextEditingController _lodgingController;
  late TextEditingController _wakeupController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.day.title);
    _lodgingController = TextEditingController(text: widget.day.lodgingCity);
    _wakeupController = TextEditingController(text: widget.day.wakeupCity);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _lodgingController.dispose();
    _wakeupController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = widget.day.copyWith(
      title: _titleController.text.trim(),
      lodgingCity: _lodgingController.text.trim(),
      wakeupCity: _wakeupController.text.trim(),
    );
    ref.read(itineraryProvider.notifier).updateDay(updated);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Editar Dia ${widget.day.dayNumber}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título do Dia',
                hintText: 'Ex: Magic Kingdom',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _lodgingController,
              decoration: const InputDecoration(
                labelText: 'Cidade onde vai dormir (Hospedagem)',
                hintText: 'Ex: Orlando, Miami, Key West',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _wakeupController,
              decoration: const InputDecoration(
                labelText: 'Cidade onde vai acordar',
                hintText: 'Ex: Orlando, Miami',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF0F766E),
          ),
          onPressed: _save,
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
