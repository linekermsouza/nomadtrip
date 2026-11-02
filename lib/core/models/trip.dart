class Trip {
  final int? id;
  final String name;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final DateTime createdAt;

  const Trip({
    this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.createdAt,
  });

  int get totalDays {
    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      return end.difference(start).inDays + 1;
    } catch (_) {
      return 1;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'start_date': startDate,
      'end_date': endDate,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory Trip.fromMap(Map<String, dynamic> map) {
    return Trip(
      id: (map['id'] as num?)?.toInt(),
      name: (map['name'] as String?) ?? 'Minha Viagem',
      startDate: (map['start_date'] as String?) ?? '',
      endDate: (map['end_date'] as String?) ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Trip copyWith({
    int? id,
    String? name,
    String? startDate,
    String? endDate,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      name: name ?? this.name,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
