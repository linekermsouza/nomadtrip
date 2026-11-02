import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/itinerary_place.dart';
import '../../../core/services/image_cache_service.dart';
import '../providers/itinerary_provider.dart';

class PlaceEditScreen extends ConsumerStatefulWidget {
  final ItineraryPlace place;

  const PlaceEditScreen({super.key, required this.place});

  @override
  ConsumerState<PlaceEditScreen> createState() => _PlaceEditScreenState();
}

class _PlaceEditScreenState extends ConsumerState<PlaceEditScreen> {
  late TextEditingController _nameController;
  late TextEditingController _timeController;
  late TextEditingController _descController;
  late TextEditingController _cityController;
  late TextEditingController _notesController;
  late TextEditingController _imageUrlController;
  late TextEditingController _zoneController;
  late TextEditingController _minHeightController;
  late TextEditingController _recommendedAgeController;
  late TextEditingController _avgWaitController;
  late TextEditingController _durationController;
  late TextEditingController _linkInputController;

  late int _selectedDay;
  late String _category;
  late String _parking;
  late int _parkingCost;
  late bool _requiresReservation;
  late bool _isAlternative;
  late String _adrenalineLevel;
  late bool _hasDizzinessWarning;
  late List<String> _links;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    final p = widget.place;
    _nameController = TextEditingController(text: p.name);
    _timeController = TextEditingController(text: p.time);
    _descController = TextEditingController(text: p.rawDescription);
    _cityController = TextEditingController(text: p.city);
    _notesController = TextEditingController(text: p.notes);
    _imageUrlController = TextEditingController(text: p.imageUrl);
    _zoneController = TextEditingController(text: p.zone);
    _minHeightController = TextEditingController(
      text: p.minHeightCm > 0 ? p.minHeightCm.toString() : '',
    );
    _recommendedAgeController = TextEditingController(text: p.recommendedAge);
    _avgWaitController = TextEditingController(
      text: p.avgWaitMinutes > 0 ? p.avgWaitMinutes.toString() : '',
    );
    _durationController = TextEditingController(
      text: p.durationMinutes > 0 ? p.durationMinutes.toString() : '',
    );
    _linkInputController = TextEditingController();

    _selectedDay = p.dayNumber;
    _category = p.category;
    _parking = p.parking;
    _parkingCost = p.parkingCost;
    _requiresReservation = p.requiresReservation;
    _isAlternative = p.isAlternative;
    _adrenalineLevel = p.adrenalineLevel;
    _hasDizzinessWarning = p.hasDizzinessWarning;
    _links = List.from(p.links);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _timeController.dispose();
    _descController.dispose();
    _cityController.dispose();
    _notesController.dispose();
    _imageUrlController.dispose();
    _zoneController.dispose();
    _minHeightController.dispose();
    _recommendedAgeController.dispose();
    _avgWaitController.dispose();
    _durationController.dispose();
    _linkInputController.dispose();
    super.dispose();
  }

  void _addLink() {
    final text = _linkInputController.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _links.add(text);
        _linkInputController.clear();
      });
    }
  }

  void _showPresetImagesDialog() {
    final presets = [
      {
        'name': 'Parque Temático / Castelo',
        'url':
            'https://images.unsplash.com/photo-1575089976121-8ed7b2a54265?w=800',
      },
      {
        'name': 'Montanha-Russa',
        'url':
            'https://images.unsplash.com/photo-1513889961551-628c1e5e2ee9?w=800',
      },
      {
        'name': 'Restaurante / Comida',
        'url':
            'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800',
      },
      {
        'name': 'Doces / Bakery',
        'url':
            'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800',
      },
      {
        'name': 'Shopping / Outlets',
        'url':
            'https://images.unsplash.com/photo-1567401893414-76b7b1e5a7a5?w=800',
      },
      {
        'name': 'Miami / Praia',
        'url':
            'https://images.unsplash.com/photo-1506953823976-52e1fdc0149a?w=800',
      },
      {
        'name': 'Key West / Pôr do Sol',
        'url':
            'https://images.unsplash.com/photo-1507525428034-b723cf961d3e?w=800',
      },
      {
        'name': 'Animais / Natureza',
        'url':
            'https://images.unsplash.com/photo-1534567153574-2b12153a87f0?w=800',
      },
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecionar Imagem'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: presets.length,
            itemBuilder: (context, index) {
              final p = presets[index];
              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.network(
                    p['url']!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                ),
                title: Text(p['name']!),
                onTap: () {
                  setState(() {
                    _imageUrlController.text = p['url']!;
                  });
                  Navigator.pop(ctx);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    final updated = widget.place.copyWith(
      name: _nameController.text.trim(),
      time: _timeController.text.trim(),
      rawDescription: _descController.text.trim(),
      city: _cityController.text.trim(),
      category: _category,
      dayNumber: _selectedDay,
      notes: _notesController.text.trim(),
      parking: _parking,
      parkingCost: _parkingCost,
      requiresReservation: _requiresReservation,
      isAlternative: _isAlternative,
      imageUrl: _imageUrlController.text.trim(),
      zone: _zoneController.text.trim(),
      minHeightCm: int.tryParse(_minHeightController.text.trim()) ?? 0,
      recommendedAge: _recommendedAgeController.text.trim(),
      adrenalineLevel: _adrenalineLevel,
      hasDizzinessWarning: _hasDizzinessWarning,
      avgWaitMinutes: int.tryParse(_avgWaitController.text.trim()) ?? 0,
      durationMinutes: int.tryParse(_durationController.text.trim()) ?? 0,
      links: _links,
    );

    if (widget.place.id == null) {
      ref.read(itineraryProvider.notifier).addPlace(updated);
    } else {
      ref.read(itineraryProvider.notifier).updatePlace(updated);
    }

    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Local salvo com sucesso!')));
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Local'),
        content: Text(
          'Deseja realmente remover "${widget.place.name}" do roteiro?',
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
              Navigator.pop(context); // Close edit screen
              if (widget.place.id != null) {
                ref
                    .read(itineraryProvider.notifier)
                    .deletePlace(widget.place.id!);
              }
            },
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final days = ref.watch(itineraryProvider).value ?? [];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.place.id == null ? 'Novo Local' : 'Editar Local'),
        actions: [
          if (widget.place.id != null)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              tooltip: 'Excluir Local',
              onPressed: _delete,
            ),
          IconButton(
            icon: const Icon(Icons.check),
            tooltip: 'Salvar',
            onPressed: _save,
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Image Preview & Change button (Item 28 & 29)
            Card(
              clipBehavior: Clip.antiAlias,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Stack(
                children: [
                  CachedPlaceImage(
                    imageUrl: _imageUrlController.text.trim(),
                    category: _category,
                    width: double.infinity,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                  Positioned(
                    bottom: 8,
                    right: 8,
                    child: FilledButton.tonalIcon(
                      icon: const Icon(Icons.photo_library, size: 16),
                      label: const Text('Trocar Imagem'),
                      onPressed: _showPresetImagesDialog,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _imageUrlController,
              decoration: const InputDecoration(
                labelText: 'URL da Imagem (opcional)',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.image_outlined),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),

            // Name
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Nome do Local / Atração *',
                prefixIcon: Icon(Icons.place_outlined),
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Nome é obrigatório' : null,
            ),
            const SizedBox(height: 16),

            // Time & Day Selector
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _timeController,
                    decoration: const InputDecoration(
                      labelText: 'Horário *',
                      hintText: '10h00',
                      prefixIcon: Icon(Icons.schedule),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Horário é obrigatório'
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<int>(
                    initialValue: days.any((d) => d.dayNumber == _selectedDay)
                        ? _selectedDay
                        : 0,
                    decoration: const InputDecoration(
                      labelText: 'Dia do Roteiro',
                      border: OutlineInputBorder(),
                    ),
                    items: days.map((d) {
                      return DropdownMenuItem<int>(
                        value: d.dayNumber,
                        child: Text(
                          d.dayNumber == 0
                              ? 'Sem Dia Definido'
                              : 'Dia ${d.dayNumber} (${d.displayDate})',
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedDay = val);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Category & City
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(
                      labelText: 'Categoria',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'theme_park',
                        child: Text('Parque Temático'),
                      ),
                      DropdownMenuItem(
                        value: 'attraction',
                        child: Text('Atração / Passeio'),
                      ),
                      DropdownMenuItem(
                        value: 'food',
                        child: Text('Alimentação / Restaurante'),
                      ),
                      DropdownMenuItem(
                        value: 'shopping',
                        child: Text('Compras / Outlets'),
                      ),
                      DropdownMenuItem(
                        value: 'transit',
                        child: Text('Deslocamento / Trânsito'),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _category = val);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: const InputDecoration(
                      labelText: 'Cidade',
                      hintText: 'Orlando, Miami...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Description
            TextFormField(
              controller: _descController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Descrição e Dicas do Roteiro',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Attraction / Roller Coaster Details Section (Items 15 & 16)
            ExpansionTile(
              title: const Text(
                '🎢 Especificações de Montanha-Russa / Atração',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              initiallyExpanded:
                  _minHeightController.text.isNotEmpty ||
                  _adrenalineLevel.isNotEmpty,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _zoneController,
                              decoration: const InputDecoration(
                                labelText: 'Área / Setor',
                                hintText: 'Tomorrowland, Diagon Alley...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _minHeightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Altura Mínima (cm)',
                                hintText: '107, 122, 137...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _recommendedAgeController,
                              decoration: const InputDecoration(
                                labelText: 'Idade Recomendada',
                                hintText: '6+ anos, 12+ anos...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              initialValue: _adrenalineLevel.isEmpty
                                  ? ''
                                  : _adrenalineLevel,
                              decoration: const InputDecoration(
                                labelText: 'Nível Adrenalina',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(
                                  value: '',
                                  child: Text('Não especificado'),
                                ),
                                DropdownMenuItem(
                                  value: 'Baixo',
                                  child: Text('Baixo (Família)'),
                                ),
                                DropdownMenuItem(
                                  value: 'Médio',
                                  child: Text('Médio'),
                                ),
                                DropdownMenuItem(
                                  value: 'Alto',
                                  child: Text('Alto'),
                                ),
                                DropdownMenuItem(
                                  value: 'Extremo',
                                  child: Text('Extremo'),
                                ),
                              ],
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _adrenalineLevel = val);
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _avgWaitController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Fila Média (minutos)',
                                hintText: '45, 60...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextFormField(
                              controller: _durationController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Duração (minutos)',
                                hintText: '3, 5...',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        title: const Text('Aviso de enjoo / Gira bastante'),
                        subtitle: const Text(
                          'Alerta para crianças ou pessoas com sensibilidade a cinetose',
                        ),
                        value: _hasDizzinessWarning,
                        activeThumbColor: const Color(0xFFD97706),
                        onChanged: (val) =>
                            setState(() => _hasDizzinessWarning = val),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parking
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: _parking,
                    decoration: const InputDecoration(
                      labelText: 'Estacionamento',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Unknown',
                        child: Text('Desconhecido'),
                      ),
                      DropdownMenuItem(value: 'Free', child: Text('Gratuito')),
                      DropdownMenuItem(value: 'Paid', child: Text('Pago')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _parking = val);
                    },
                  ),
                ),
                if (_parking == 'Paid') ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: _parkingCost > 0
                          ? _parkingCost.toString()
                          : '',
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Custo Estacionamento (USD)',
                        prefixText: '\$ ',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (val) => _parkingCost = int.tryParse(val) ?? 0,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 12),

            // Switches: Reservation and Alternative
            SwitchListTile(
              title: const Text('Exige Reserva Antecipada'),
              subtitle: const Text('Será indicado no roteiro caso marcado'),
              value: _requiresReservation,
              activeThumbColor: const Color(0xFFDC2626),
              onChanged: (val) => setState(() => _requiresReservation = val),
            ),
            SwitchListTile(
              title: const Text('Parada Alternativa / "Escolha na Hora"'),
              value: _isAlternative,
              activeThumbColor: const Color(0xFFD97706),
              onChanged: (val) => setState(() => _isAlternative = val),
            ),
            const SizedBox(height: 12),

            // Notes
            TextFormField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notas e Lembretes Pessoais',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // Links Section
            const Text(
              'Links (Instagram, Reels, Menus, YouTube)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _linkInputController,
                    decoration: const InputDecoration(
                      hintText: 'Cole a URL aqui...',
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filled(
                  icon: const Icon(Icons.add),
                  onPressed: _addLink,
                ),
              ],
            ),
            if (_links.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: _links.map((link) {
                  return Chip(
                    label: Text(
                      link.length > 28 ? '${link.substring(0, 25)}...' : link,
                    ),
                    deleteIcon: const Icon(Icons.close, size: 16),
                    onDeleted: () => setState(() => _links.remove(link)),
                  );
                }).toList(),
              ),
            ],
            const SizedBox(height: 32),

            // Save Button
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                icon: const Icon(Icons.save_rounded),
                label: const Text(
                  'Salvar Local',
                  style: TextStyle(fontSize: 16),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF0F766E),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
