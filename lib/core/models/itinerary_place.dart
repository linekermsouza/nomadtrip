import 'dart:convert';

/// Represents a scheduled location or activity within a trip day.
class ItineraryPlace {
  final int? id;
  final int dayNumber;
  final String name;
  final String time;
  final String rawDescription;
  final String category; // 'theme_park', 'shopping', 'food', 'transit', 'attraction'
  final String city;
  final double latitude;
  final double longitude;
  final String parking; // 'Free', 'Paid', 'Unknown'
  final int parkingCost; // in USD
  final bool isVisited;
  final DateTime? visitedAt;
  final bool requiresReservation;
  final String notes;
  final List<String> links;

  const ItineraryPlace({
    this.id,
    required this.dayNumber,
    required this.name,
    required this.time,
    required this.rawDescription,
    required this.category,
    required this.city,
    required this.latitude,
    required this.longitude,
    this.parking = 'Unknown',
    this.parkingCost = 0,
    this.isVisited = false,
    this.visitedAt,
    this.requiresReservation = false,
    this.notes = '',
    this.links = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'day_number': dayNumber,
      'name': name,
      'time': time,
      'raw_description': rawDescription,
      'category': category,
      'city': city,
      'latitude': latitude,
      'longitude': longitude,
      'parking': parking,
      'parking_cost': parkingCost,
      'is_visited': isVisited ? 1 : 0,
      'visited_at': visitedAt?.toIso8601String(),
      'requires_reservation': requiresReservation ? 1 : 0,
      'notes': notes,
      'links': jsonEncode(links),
    };
  }

  factory ItineraryPlace.fromMap(Map<String, dynamic> map) {
    List<String> parsedLinks = [];
    if (map['links'] != null) {
      try {
        final decoded = jsonDecode(map['links'] as String);
        if (decoded is List) {
          parsedLinks = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ItineraryPlace(
      id: map['id'] as int?,
      dayNumber: map['day_number'] as int,
      name: map['name'] as String,
      time: map['time'] as String,
      rawDescription: (map['raw_description'] as String?) ?? '',
      category: (map['category'] as String?) ?? 'attraction',
      city: (map['city'] as String?) ?? '',
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      parking: (map['parking'] as String?) ?? 'Unknown',
      parkingCost: (map['parking_cost'] as int?) ?? 0,
      isVisited: (map['is_visited'] as int?) == 1,
      visitedAt: map['visited_at'] != null ? DateTime.tryParse(map['visited_at'] as String) : null,
      requiresReservation: (map['requires_reservation'] as int?) == 1,
      notes: (map['notes'] as String?) ?? '',
      links: parsedLinks,
    );
  }

  ItineraryPlace copyWith({
    int? id,
    int? dayNumber,
    String? name,
    String? time,
    String? rawDescription,
    String? category,
    String? city,
    double? latitude,
    double? longitude,
    String? parking,
    int? parkingCost,
    bool? isVisited,
    DateTime? visitedAt,
    bool? requiresReservation,
    String? notes,
    List<String>? links,
  }) {
    return ItineraryPlace(
      id: id ?? this.id,
      dayNumber: dayNumber ?? this.dayNumber,
      name: name ?? this.name,
      time: time ?? this.time,
      rawDescription: rawDescription ?? this.rawDescription,
      category: category ?? this.category,
      city: city ?? this.city,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      parking: parking ?? this.parking,
      parkingCost: parkingCost ?? this.parkingCost,
      isVisited: isVisited ?? this.isVisited,
      visitedAt: visitedAt ?? this.visitedAt,
      requiresReservation: requiresReservation ?? this.requiresReservation,
      notes: notes ?? this.notes,
      links: links ?? this.links,
    );
  }
}
