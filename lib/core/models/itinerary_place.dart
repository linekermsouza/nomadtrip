import 'dart:convert';
import 'trip_day.dart';

/// Represents a scheduled location or activity within a trip day.
class ItineraryPlace {
  final int? id;
  final int tripId;
  final int dayNumber;
  final String name;
  final String time;
  final String rawDescription;
  final String
  category; // 'theme_park', 'shopping', 'food', 'transit', 'attraction'
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
  final bool isAlternative;
  final String imageUrl;
  final String zone; // e.g. "Tomorrowland", "Diagon Alley", "Celestial Park"
  final int minHeightCm; // 0 if none
  final String recommendedAge; // e.g. "Todas as idades", "6+ anos", "12+ anos"
  final String adrenalineLevel; // 'Baixo', 'Médio', 'Alto', 'Extremo', ''
  final bool hasDizzinessWarning; // se gira bastante ou simulador com enjoo
  final int avgWaitMinutes; // average wait time in minutes
  final int durationMinutes; // duration in minutes

  const ItineraryPlace({
    this.id,
    this.tripId = 1,
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
    this.isAlternative = false,
    this.imageUrl = '',
    this.zone = '',
    this.minHeightCm = 0,
    this.recommendedAge = '',
    this.adrenalineLevel = '',
    this.hasDizzinessWarning = false,
    this.avgWaitMinutes = 0,
    this.durationMinutes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'trip_id': tripId,
      'day_number': dayNumber,
      'name': cleanMarkdownDecorations(name),
      'time': time,
      'raw_description': cleanMarkdownDecorations(rawDescription),
      'category': category,
      'city': cleanMarkdownDecorations(city),
      'latitude': latitude,
      'longitude': longitude,
      'parking': parking,
      'parking_cost': parkingCost,
      'is_visited': isVisited ? 1 : 0,
      'visited_at': visitedAt?.toIso8601String(),
      'requires_reservation': requiresReservation ? 1 : 0,
      'notes': cleanMarkdownDecorations(notes),
      'links': jsonEncode(links),
      'is_alternative': isAlternative ? 1 : 0,
      'image_url': imageUrl,
      'zone': cleanMarkdownDecorations(zone),
      'min_height_cm': minHeightCm,
      'recommended_age': recommendedAge,
      'adrenaline_level': adrenalineLevel,
      'has_dizziness_warning': hasDizzinessWarning ? 1 : 0,
      'avg_wait_minutes': avgWaitMinutes,
      'duration_minutes': durationMinutes,
    };
  }

  factory ItineraryPlace.fromMap(Map<String, dynamic> map) {
    List<String> parsedLinks = [];
    if (map['links'] != null) {
      try {
        final decoded = map['links'] is String
            ? jsonDecode(map['links'] as String)
            : map['links'];
        if (decoded is List) {
          parsedLinks = decoded.map((e) => e.toString()).toList();
        }
      } catch (_) {}
    }

    return ItineraryPlace(
      id: (map['id'] as num?)?.toInt(),
      tripId: (map['trip_id'] as num?)?.toInt() ?? 1,
      dayNumber: (map['day_number'] as num?)?.toInt() ?? 0,
      name: cleanMarkdownDecorations((map['name'] as String?) ?? ''),
      time: (map['time'] as String?) ?? '',
      rawDescription: cleanMarkdownDecorations(
        (map['raw_description'] as String?) ?? '',
      ),
      category: (map['category'] as String?) ?? 'attraction',
      city: cleanMarkdownDecorations((map['city'] as String?) ?? ''),
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      parking: (map['parking'] as String?) ?? 'Unknown',
      parkingCost: (map['parking_cost'] as num?)?.toInt() ?? 0,
      isVisited: (map['is_visited'] as num?) == 1,
      visitedAt: map['visited_at'] != null
          ? DateTime.tryParse(map['visited_at'] as String)
          : null,
      requiresReservation: (map['requires_reservation'] as num?) == 1,
      notes: cleanMarkdownDecorations((map['notes'] as String?) ?? ''),
      links: parsedLinks,
      isAlternative: (map['is_alternative'] as num?) == 1,
      imageUrl: (map['image_url'] as String?) ?? '',
      zone: cleanMarkdownDecorations((map['zone'] as String?) ?? ''),
      minHeightCm: (map['min_height_cm'] as num?)?.toInt() ?? 0,
      recommendedAge: (map['recommended_age'] as String?) ?? '',
      adrenalineLevel: (map['adrenaline_level'] as String?) ?? '',
      hasDizzinessWarning: (map['has_dizziness_warning'] as num?) == 1,
      avgWaitMinutes: (map['avg_wait_minutes'] as num?)?.toInt() ?? 0,
      durationMinutes: (map['duration_minutes'] as num?)?.toInt() ?? 0,
    );
  }

  ItineraryPlace copyWith({
    int? id,
    int? tripId,
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
    bool? isAlternative,
    String? imageUrl,
    String? zone,
    int? minHeightCm,
    String? recommendedAge,
    String? adrenalineLevel,
    bool? hasDizzinessWarning,
    int? avgWaitMinutes,
    int? durationMinutes,
  }) {
    return ItineraryPlace(
      id: id ?? this.id,
      tripId: tripId ?? this.tripId,
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
      isAlternative: isAlternative ?? this.isAlternative,
      imageUrl: imageUrl ?? this.imageUrl,
      zone: zone ?? this.zone,
      minHeightCm: minHeightCm ?? this.minHeightCm,
      recommendedAge: recommendedAge ?? this.recommendedAge,
      adrenalineLevel: adrenalineLevel ?? this.adrenalineLevel,
      hasDizzinessWarning: hasDizzinessWarning ?? this.hasDizzinessWarning,
      avgWaitMinutes: avgWaitMinutes ?? this.avgWaitMinutes,
      durationMinutes: durationMinutes ?? this.durationMinutes,
    );
  }
}
