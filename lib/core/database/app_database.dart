import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/itinerary_place.dart';
import '../models/trip.dart';
import '../models/trip_day.dart';
import '../models/trip_tip.dart';

class TripReductionException implements Exception {
  final String message;
  final List<int> offendingDays;
  const TripReductionException(this.message, this.offendingDays);

  @override
  String toString() => message;
}

class AppDatabase {
  static final AppDatabase instance = AppDatabase._internal();
  static Database? _database;

  AppDatabase._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      databaseFactory = databaseFactoryFfiWeb;
    } else if (defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'nomadtrip.db');

    return await openDatabase(
      path,
      version: 3,
      onCreate: _onCreate,
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            'ALTER TABLE places ADD COLUMN is_alternative INTEGER DEFAULT 0',
          );
          await db.insert('days', {
            'day_number': 0,
            'date': '',
            'weekday': '',
            'title': 'Stops without a scheduled day',
            'lodging_city': '',
            'wakeup_city': '',
          });
        }
        if (oldVersion < 3) {
          await _upgradeToVersion3(db);
        }
      },
    );
  }

  Future<void> _upgradeToVersion3(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    // Add trip_id and checklist to days
    try {
      await db.execute('ALTER TABLE days ADD COLUMN trip_id INTEGER DEFAULT 1');
    } catch (_) {}
    try {
      await db.execute(
        "ALTER TABLE days ADD COLUMN checklist TEXT DEFAULT '[]'",
      );
    } catch (_) {}

    // Add new columns to places
    final placeColumns = [
      'trip_id INTEGER DEFAULT 1',
      "image_url TEXT DEFAULT ''",
      "zone TEXT DEFAULT ''",
      'min_height_cm INTEGER DEFAULT 0',
      "recommended_age TEXT DEFAULT ''",
      "adrenaline_level TEXT DEFAULT ''",
      'has_dizziness_warning INTEGER DEFAULT 0',
      'avg_wait_minutes INTEGER DEFAULT 0',
      'duration_minutes INTEGER DEFAULT 0',
    ];

    for (final col in placeColumns) {
      try {
        await db.execute('ALTER TABLE places ADD COLUMN $col');
      } catch (_) {}
    }

    // Add trip_id and day_number to tips
    try {
      await db.execute('ALTER TABLE tips ADD COLUMN trip_id INTEGER DEFAULT 1');
    } catch (_) {}
    try {
      await db.execute(
        'ALTER TABLE tips ADD COLUMN day_number INTEGER DEFAULT 0',
      );
    } catch (_) {}

    // If existing days/places exist and no trips, create default trip 1
    final existingTrips = await db.query('trips');
    if (existingTrips.isEmpty) {
      final daysRows = await db.rawQuery(
        'SELECT COUNT(*) as c FROM days WHERE day_number > 0',
      );
      final daysCount = (daysRows.first['c'] as num?)?.toInt() ?? 0;
      if (daysCount > 0) {
        await db.insert('trips', {
          'id': 1,
          'name': 'Florida Trip',
          'start_date': '2026-11-24',
          'end_date': '2026-12-13',
          'created_at': DateTime.now().toIso8601String(),
        });
        await db.insert('settings', {'key': 'selected_trip_id', 'value': '1'});
      }
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE trips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT NOT NULL,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE days (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        date TEXT NOT NULL,
        weekday TEXT NOT NULL,
        title TEXT NOT NULL,
        lodging_city TEXT NOT NULL,
        wakeup_city TEXT NOT NULL,
        checklist TEXT DEFAULT '[]'
      )
    ''');

    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER NOT NULL,
        day_number INTEGER NOT NULL,
        name TEXT NOT NULL,
        time TEXT NOT NULL,
        raw_description TEXT,
        category TEXT,
        city TEXT,
        latitude REAL,
        longitude REAL,
        parking TEXT,
        parking_cost INTEGER,
        is_visited INTEGER DEFAULT 0,
        visited_at TEXT,
        requires_reservation INTEGER DEFAULT 0,
        notes TEXT,
        links TEXT,
        is_alternative INTEGER DEFAULT 0,
        image_url TEXT DEFAULT '',
        zone TEXT DEFAULT '',
        min_height_cm INTEGER DEFAULT 0,
        recommended_age TEXT DEFAULT '',
        adrenaline_level TEXT DEFAULT '',
        has_dizziness_warning INTEGER DEFAULT 0,
        avg_wait_minutes INTEGER DEFAULT 0,
        duration_minutes INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        trip_id INTEGER DEFAULT 0,
        day_number INTEGER DEFAULT 0,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    await db.execute(
      'CREATE INDEX idx_places_trip_day ON places (trip_id, day_number)',
    );
    await db.execute('CREATE INDEX idx_places_name ON places (name)');
    await db.execute(
      'CREATE INDEX idx_days_trip ON days (trip_id, day_number)',
    );
  }

  // -------------------------------------------------------------
  // Settings & Selected Trip
  // -------------------------------------------------------------
  Future<int?> getSelectedTripId() async {
    final db = await database;
    final res = await db.query(
      'settings',
      where: 'key = ?',
      whereArgs: ['selected_trip_id'],
    );
    if (res.isEmpty) return null;
    return int.tryParse(res.first['value'] as String);
  }

  Future<void> setSelectedTripId(int? tripId) async {
    final db = await database;
    if (tripId == null) {
      await db.delete(
        'settings',
        where: 'key = ?',
        whereArgs: ['selected_trip_id'],
      );
    } else {
      await db.insert('settings', {
        'key': 'selected_trip_id',
        'value': tripId.toString(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
  }

  // -------------------------------------------------------------
  // Trips Queries
  // -------------------------------------------------------------
  Future<List<Trip>> getAllTrips() async {
    final db = await database;
    final maps = await db.query('trips', orderBy: 'id ASC');
    return maps.map((m) => Trip.fromMap(m)).toList();
  }

  Future<Trip?> getTrip(int tripId) async {
    final db = await database;
    final maps = await db.query('trips', where: 'id = ?', whereArgs: [tripId]);
    if (maps.isEmpty) return null;
    return Trip.fromMap(maps.first);
  }

  Future<int> insertTrip(Trip trip) async {
    final db = await database;
    final tripId = await db.insert('trips', trip.toMap());

    // Generate days for this trip
    await _generateDaysForTrip(
      db,
      tripId,
      trip.startDate,
      trip.endDate,
      trip.name,
    );
    return tripId;
  }

  Future<void> _generateDaysForTrip(
    DatabaseExecutor db,
    int tripId,
    String startDate,
    String endDate,
    String tripName,
  ) async {
    // Day 0: No Day
    await db.insert('days', {
      'trip_id': tripId,
      'day_number': 0,
      'date': '',
      'weekday': '',
      'title': 'Stops without a scheduled day',
      'lodging_city': '',
      'wakeup_city': '',
      'checklist': '[]',
    });

    try {
      final start = DateTime.parse(startDate);
      final end = DateTime.parse(endDate);
      final count = end.difference(start).inDays + 1;
      final weekdayFormatter = DateFormat('EEEE', 'pt_BR');
      final dateFormatter = DateFormat('yyyy-MM-dd');

      for (int i = 0; i < count; i++) {
        final current = start.add(Duration(days: i));
        String weekdayName;
        try {
          weekdayName = weekdayFormatter.format(current);
          weekdayName = weekdayName[0].toUpperCase() + weekdayName.substring(1);
        } catch (_) {
          final weekdays = [
            'Segunda',
            'Terça',
            'Quarta',
            'Quinta',
            'Sexta',
            'Sábado',
            'Domingo',
          ];
          weekdayName = weekdays[current.weekday - 1];
        }

        await db.insert('days', {
          'trip_id': tripId,
          'day_number': i + 1,
          'date': dateFormatter.format(current),
          'weekday': weekdayName,
          'title': 'Dia ${i + 1}',
          'lodging_city': '',
          'wakeup_city': '',
          'checklist': '[]',
        });
      }
    } catch (_) {}
  }

  Future<void> validateTripDurationReduction(
    int tripId,
    int newTotalDays,
  ) async {
    final db = await database;
    final places = await db.query(
      'places',
      columns: ['day_number'],
      where: 'trip_id = ? AND day_number > ?',
      whereArgs: [tripId, newTotalDays],
    );

    if (places.isNotEmpty) {
      final offendingDays =
          places.map((p) => p['day_number'] as int).toSet().toList()..sort();
      throw TripReductionException(
        'Não é possível diminuir a quantidade de dias pois existem locais cadastrados nos dias: ${offendingDays.join(', ')}. Remova os locais desses dias antes de diminuir a duração do roteiro.',
        offendingDays,
      );
    }
  }

  Future<void> updateTrip(Trip trip) async {
    final db = await database;
    if (trip.id == null) return;

    // Check if new duration reduces days
    final newTotalDays = trip.totalDays;
    await validateTripDurationReduction(trip.id!, newTotalDays);

    await db.transaction((txn) async {
      await txn.update(
        'trips',
        trip.toMap(),
        where: 'id = ?',
        whereArgs: [trip.id],
      );

      // Adjust days
      final existingDays = await txn.query(
        'days',
        where: 'trip_id = ? AND day_number > 0',
        orderBy: 'day_number ASC',
      );

      final currentDaysCount = existingDays.length;
      final start = DateTime.tryParse(trip.startDate);
      final dateFormatter = DateFormat('yyyy-MM-dd');

      if (start != null) {
        final weekdays = [
          'Segunda',
          'Terça',
          'Quarta',
          'Quinta',
          'Sexta',
          'Sábado',
          'Domingo',
        ];
        for (int i = 0; i < newTotalDays; i++) {
          final dayNum = i + 1;
          final currentDate = start.add(Duration(days: i));
          final weekdayName = weekdays[currentDate.weekday - 1];
          final dateStr = dateFormatter.format(currentDate);

          if (dayNum <= currentDaysCount) {
            // Update date and weekday for existing day
            await txn.update(
              'days',
              {'date': dateStr, 'weekday': weekdayName},
              where: 'trip_id = ? AND day_number = ?',
              whereArgs: [trip.id, dayNum],
            );
          } else {
            // Insert newly added day
            await txn.insert('days', {
              'trip_id': trip.id,
              'day_number': dayNum,
              'date': dateStr,
              'weekday': weekdayName,
              'title': 'Dia $dayNum',
              'lodging_city': '',
              'wakeup_city': '',
              'checklist': '[]',
            });
          }
        }

        // If new days are fewer than current days, delete the extra days (we already verified no places exist)
        if (newTotalDays < currentDaysCount) {
          await txn.delete(
            'days',
            where: 'trip_id = ? AND day_number > ?',
            whereArgs: [trip.id, newTotalDays],
          );
        }
      }
    });
  }

  Future<void> deleteTrip(int tripId) async {
    final db = await database;
    await db.transaction((txn) async {
      await txn.delete('places', where: 'trip_id = ?', whereArgs: [tripId]);
      await txn.delete('days', where: 'trip_id = ?', whereArgs: [tripId]);
      await txn.delete('tips', where: 'trip_id = ?', whereArgs: [tripId]);
      await txn.delete('trips', where: 'id = ?', whereArgs: [tripId]);
    });

    final currentSelected = await getSelectedTripId();
    if (currentSelected == tripId) {
      final all = await getAllTrips();
      await setSelectedTripId(all.isNotEmpty ? all.first.id : null);
    }
  }

  // -------------------------------------------------------------
  // Days Queries
  // -------------------------------------------------------------
  Future<List<TripDay>> getAllDays({int? tripId}) async {
    final db = await database;
    final effectiveTripId = tripId ?? (await getSelectedTripId()) ?? 1;

    final dayMaps = await db.query(
      'days',
      where: 'trip_id = ?',
      whereArgs: [effectiveTripId],
      orderBy: 'day_number ASC',
    );

    final List<TripDay> days = [];
    for (final dayMap in dayMaps) {
      final dayNum = dayMap['day_number'] as int;
      final placeMaps = await db.query(
        'places',
        where: 'trip_id = ? AND day_number = ?',
        whereArgs: [effectiveTripId, dayNum],
        orderBy: 'id ASC',
      );
      final places = placeMaps.map((p) => ItineraryPlace.fromMap(p)).toList();
      days.add(TripDay.fromMap(dayMap, places));
    }
    return days;
  }

  Future<TripDay?> getDay(int dayNumber, {int? tripId}) async {
    final db = await database;
    final effectiveTripId = tripId ?? (await getSelectedTripId()) ?? 1;
    final dayMaps = await db.query(
      'days',
      where: 'trip_id = ? AND day_number = ?',
      whereArgs: [effectiveTripId, dayNumber],
    );
    if (dayMaps.isEmpty) return null;

    final placeMaps = await db.query(
      'places',
      where: 'trip_id = ? AND day_number = ?',
      whereArgs: [effectiveTripId, dayNumber],
      orderBy: 'id ASC',
    );
    final places = placeMaps.map((p) => ItineraryPlace.fromMap(p)).toList();
    return TripDay.fromMap(dayMaps.first, places);
  }

  Future<void> updateDay(TripDay day) async {
    final db = await database;
    await db.update(
      'days',
      day.toMap(),
      where: 'trip_id = ? AND day_number = ?',
      whereArgs: [day.tripId, day.dayNumber],
    );
  }

  Future<void> updateDayChecklist(
    int tripId,
    int dayNumber,
    List<ChecklistItem> checklist,
  ) async {
    final db = await database;
    await db.update(
      'days',
      {'checklist': jsonEncode(checklist.map((c) => c.toMap()).toList())},
      where: 'trip_id = ? AND day_number = ?',
      whereArgs: [tripId, dayNumber],
    );
  }

  // -------------------------------------------------------------
  // Places Queries
  // -------------------------------------------------------------
  Future<List<ItineraryPlace>> getAllPlaces({int? tripId}) async {
    final db = await database;
    final effectiveTripId = tripId ?? (await getSelectedTripId()) ?? 1;
    final maps = await db.query(
      'places',
      where: 'trip_id = ?',
      whereArgs: [effectiveTripId],
      orderBy: 'day_number ASC, id ASC',
    );
    return maps.map((m) => ItineraryPlace.fromMap(m)).toList();
  }

  Future<List<ItineraryPlace>> searchPlaces(String query, {int? tripId}) async {
    final effectiveTripId = tripId ?? (await getSelectedTripId()) ?? 1;
    if (query.trim().isEmpty) return getAllPlaces(tripId: effectiveTripId);
    final db = await database;
    final cleanQuery = '%${query.trim()}%';
    final maps = await db.query(
      'places',
      where:
          'trip_id = ? AND (name LIKE ? OR raw_description LIKE ? OR city LIKE ? OR notes LIKE ? OR zone LIKE ?)',
      whereArgs: [
        effectiveTripId,
        cleanQuery,
        cleanQuery,
        cleanQuery,
        cleanQuery,
        cleanQuery,
      ],
      orderBy: 'day_number ASC',
    );
    return maps.map((m) => ItineraryPlace.fromMap(m)).toList();
  }

  Future<int> insertPlace(ItineraryPlace place) async {
    final db = await database;
    final effectiveTripId = place.tripId > 0
        ? place.tripId
        : ((await getSelectedTripId()) ?? 1);
    final p = place.copyWith(tripId: effectiveTripId);
    return await db.insert('places', p.toMap());
  }

  Future<int> updatePlace(ItineraryPlace place) async {
    final db = await database;
    return await db.update(
      'places',
      place.toMap(),
      where: 'id = ?',
      whereArgs: [place.id],
    );
  }

  Future<int> togglePlaceVisited(int placeId, bool isVisited) async {
    final db = await database;
    return await db.update(
      'places',
      {
        'is_visited': isVisited ? 1 : 0,
        'visited_at': isVisited ? DateTime.now().toIso8601String() : null,
      },
      where: 'id = ?',
      whereArgs: [placeId],
    );
  }

  Future<int> deletePlace(int placeId) async {
    final db = await database;
    return await db.delete('places', where: 'id = ?', whereArgs: [placeId]);
  }

  Future<void> deletePlaces(List<int> placeIds) async {
    if (placeIds.isEmpty) return;
    final db = await database;
    final batch = db.batch();
    for (final id in placeIds) {
      batch.delete('places', where: 'id = ?', whereArgs: [id]);
    }
    await batch.commit(noResult: true);
  }

  Future<void> deletePlacesForDay(int tripId, int dayNumber) async {
    final db = await database;
    await db.delete(
      'places',
      where: 'trip_id = ? AND day_number = ?',
      whereArgs: [tripId, dayNumber],
    );
  }

  Future<int> movePlace(int placeId, int newDayNumber, String newTime) async {
    final db = await database;
    return await db.update(
      'places',
      {'day_number': newDayNumber, 'time': newTime},
      where: 'id = ?',
      whereArgs: [placeId],
    );
  }

  // -------------------------------------------------------------
  // Tips Queries
  // -------------------------------------------------------------
  Future<List<TripTip>> getAllTips({int? tripId}) async {
    final db = await database;
    final effectiveTripId = tripId ?? (await getSelectedTripId()) ?? 1;
    final maps = await db.query(
      'tips',
      where: 'trip_id = ? OR trip_id = 0',
      whereArgs: [effectiveTripId],
      orderBy: 'day_number ASC, id ASC',
    );
    return maps.map((m) => TripTip.fromMap(m)).toList();
  }

  Future<int> toggleTipCompleted(int tipId, bool isCompleted) async {
    final db = await database;
    return await db.update(
      'tips',
      {'is_completed': isCompleted ? 1 : 0},
      where: 'id = ?',
      whereArgs: [tipId],
    );
  }

  Future<int> insertTip(TripTip tip) async {
    final db = await database;
    final effectiveTripId = tip.tripId > 0
        ? tip.tripId
        : ((await getSelectedTripId()) ?? 1);
    final t = tip.copyWith(tripId: effectiveTripId);
    return await db.insert('tips', t.toMap());
  }

  Future<int> deleteTip(int tipId) async {
    final db = await database;
    return await db.delete('tips', where: 'id = ?', whereArgs: [tipId]);
  }

  // -------------------------------------------------------------
  // Import & Export (.ntrip, .json, .md)
  // -------------------------------------------------------------
  Future<Map<String, dynamic>> exportTripNtrip(int tripId) async {
    final db = await database;
    final tripMaps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
    );
    if (tripMaps.isEmpty) {
      throw Exception('Roteiro não encontrado');
    }
    final trip = tripMaps.first;
    final days = await db.query(
      'days',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'day_number ASC',
    );
    final places = await db.query(
      'places',
      where: 'trip_id = ?',
      whereArgs: [tripId],
      orderBy: 'day_number ASC, id ASC',
    );
    final tips = await db.query(
      'tips',
      where: 'trip_id = ? OR trip_id = 0',
      whereArgs: [tripId],
      orderBy: 'id ASC',
    );

    return {
      'format': 'nomadtrip',
      'version': 2,
      'trip': trip,
      'days': days,
      'places': places,
      'tips': tips,
    };
  }

  Future<String> exportTripMarkdown(int tripId) async {
    final db = await database;
    final tripMaps = await db.query(
      'trips',
      where: 'id = ?',
      whereArgs: [tripId],
    );
    if (tripMaps.isEmpty) throw Exception('Roteiro não encontrado');
    final trip = tripMaps.first;
    final days = await getAllDays(tripId: tripId);
    final tips = await getAllTips(tripId: tripId);

    final sb = StringBuffer();
    sb.writeln('# 🌴 nomadtrip — ${trip['name']}');
    sb.writeln();
    sb.writeln('**Período:** ${trip['start_date']} a ${trip['end_date']}');
    sb.writeln(
      '**Total de Dias:** ${days.where((d) => d.dayNumber > 0).length}',
    );
    sb.writeln();
    sb.writeln('---');
    sb.writeln();

    for (final day in days) {
      if (day.dayNumber == 0) {
        if (day.places.isNotEmpty) {
          sb.writeln('## 📌 Locais sem dia definido');
          sb.writeln();
          for (final place in day.places) {
            sb.writeln(
              '- **${place.name}** (${place.category}) - ${place.rawDescription}',
            );
          }
          sb.writeln();
        }
        continue;
      }

      sb.writeln(
        '## Dia ${day.dayNumber} — ${day.date} (${day.weekday}): ${day.title}',
      );
      if (day.lodgingCity.isNotEmpty || day.wakeupCity.isNotEmpty) {
        sb.writeln(
          '*Acorda em:* ${day.wakeupCity.isEmpty ? '-' : day.wakeupCity} | *Dorme em:* ${day.lodgingCity.isEmpty ? '-' : day.lodgingCity}',
        );
      }
      sb.writeln();

      if (day.checklist.isNotEmpty) {
        sb.writeln('### Checklist do Dia:');
        for (final item in day.checklist) {
          sb.writeln('- [${item.isCompleted ? 'x' : ' '}] ${item.text}');
        }
        sb.writeln();
      }

      if (day.places.isEmpty) {
        sb.writeln('*Nenhum local programado para este dia.*');
        sb.writeln();
      } else {
        sb.writeln('### Itinerário:');
        for (final p in day.places) {
          final res = p.requiresReservation ? ' [RESERVA NECESSÁRIA]' : '';
          final alt = p.isAlternative ? ' [ALTERNATIVA]' : '';
          sb.writeln('- **${p.time}** — **${p.name}**$res$alt');
          if (p.rawDescription.isNotEmpty) {
            sb.writeln('  - *Descrição:* ${p.rawDescription}');
          }
          if (p.zone.isNotEmpty) {
            sb.writeln('  - *Área / Setor:* ${p.zone}');
          }
          if (p.minHeightCm > 0 ||
              p.adrenalineLevel.isNotEmpty ||
              p.hasDizzinessWarning) {
            final details = <String>[];
            if (p.minHeightCm > 0) {
              details.add('Altura mín: ${p.minHeightCm}cm');
            }
            if (p.recommendedAge.isNotEmpty) {
              details.add('Idade: ${p.recommendedAge}');
            }
            if (p.adrenalineLevel.isNotEmpty) {
              details.add('Adrenalina: ${p.adrenalineLevel}');
            }
            if (p.hasDizzinessWarning) {
              details.add('Aviso de enjoo/giros');
            }
            if (p.avgWaitMinutes > 0) {
              details.add('Fila média: ~${p.avgWaitMinutes} min');
            }
            sb.writeln('  - *Atração:* ${details.join(' | ')}');
          }
          if (p.notes.isNotEmpty) {
            sb.writeln('  - *Notas:* ${p.notes}');
          }
          if (p.parking.isNotEmpty && p.parking != 'Unknown') {
            sb.writeln(
              '  - *Estacionamento:* ${p.parking}${p.parkingCost > 0 ? ' (~US\$${p.parkingCost})' : ''}',
            );
          }
        }
        sb.writeln();
      }
    }

    if (tips.isNotEmpty) {
      sb.writeln('---');
      sb.writeln('## 💡 Dicas e Lembretes de Viagem');
      sb.writeln();
      for (final tip in tips) {
        sb.writeln(
          '- **[${tip.category.toUpperCase()}] ${tip.title}:** ${tip.content}',
        );
      }
      sb.writeln();
    }

    return sb.toString();
  }

  Future<int> importTripData(
    Map<String, dynamic> data, {
    String? customName,
    String? customStartDate,
    String? customEndDate,
  }) async {
    final db = await database;

    // Check structure (can be v2 .ntrip or v1 .json)
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

    final finalName = customName?.trim().isNotEmpty == true
        ? customName!.trim()
        : (tripMeta['name'] as String?) ?? 'Meu Roteiro';
    final finalStartDate = customStartDate?.trim().isNotEmpty == true
        ? customStartDate!.trim()
        : (tripMeta['start_date'] as String?) ??
              (tripMeta['startDate'] as String?) ??
              '2026-11-24';
    final finalEndDate = customEndDate?.trim().isNotEmpty == true
        ? customEndDate!.trim()
        : (tripMeta['end_date'] as String?) ??
              (tripMeta['endDate'] as String?) ??
              '2026-12-13';

    final rawDays = (data['days'] as List<dynamic>? ?? []).cast<dynamic>();
    final rawPlaces = (data['places'] as List<dynamic>? ?? []).cast<dynamic>();
    final rawTips = (data['tips'] as List<dynamic>? ?? []).cast<dynamic>();

    int newTripId = 0;
    await db.transaction((txn) async {
      newTripId = await txn.insert('trips', {
        'name': finalName,
        'start_date': finalStartDate,
        'end_date': finalEndDate,
        'created_at': DateTime.now().toIso8601String(),
      });

      // Insert days
      final normalizedPlaces = <Map<String, dynamic>>[];
      for (final rp in rawPlaces) {
        normalizedPlaces.add(Map<String, dynamic>.from(rp as Map));
      }

      final daysToInsert = <Map<String, dynamic>>[];
      for (final rd in rawDays) {
        final dMap = Map<String, dynamic>.from(rd as Map);
        final dayNum = (dMap['day_number'] ?? dMap['dayNumber'] ?? 0) as int;
        daysToInsert.add({
          'trip_id': newTripId,
          'day_number': dayNum,
          'date': dMap['date'] ?? '',
          'weekday': dMap['weekday'] ?? '',
          'title': cleanMarkdownDecorations((dMap['title'] as String?) ?? ''),
          'lodging_city': cleanMarkdownDecorations(
            (dMap['lodging_city'] ?? dMap['lodgingCity'] ?? '') as String,
          ),
          'wakeup_city': cleanMarkdownDecorations(
            (dMap['wakeup_city'] ?? dMap['wakeupCity'] ?? '') as String,
          ),
          'checklist': dMap['checklist'] is String
              ? dMap['checklist']
              : jsonEncode(dMap['checklist'] ?? []),
        });

        // If items are inside day (v1 format), extract them
        if (dMap['items'] is List) {
          for (final item in (dMap['items'] as List)) {
            final source = Map<String, dynamic>.from(item as Map);
            normalizedPlaces.add({
              'day_number': dayNum,
              'name': cleanMarkdownDecorations(
                (source['placeName'] ?? source['name'] ?? '') as String,
              ),
              'time': source['time'] ?? '',
              'raw_description': cleanMarkdownDecorations(
                (source['rawDescription'] ?? source['raw_description'] ?? '')
                    as String,
              ),
              'category': source['category'] ?? 'attraction',
              'city': cleanMarkdownDecorations(
                (source['city'] ?? '') as String,
              ),
              'latitude': source['latitude'] ?? 0.0,
              'longitude': source['longitude'] ?? 0.0,
              'parking': source['parking'] ?? 'Unknown',
              'parking_cost':
                  source['parkingCost'] ?? source['parking_cost'] ?? 0,
              'is_visited': 0,
              'requires_reservation':
                  (source['requiresReservation'] == true ||
                      source['requires_reservation'] == 1)
                  ? 1
                  : 0,
              'notes': cleanMarkdownDecorations(
                (source['notes'] ?? '') as String,
              ),
              'links': source['links'] is String
                  ? source['links']
                  : jsonEncode(source['links'] ?? []),
              'is_alternative':
                  (source['isAlternative'] == true ||
                      source['is_alternative'] == 1)
                  ? 1
                  : 0,
              'image_url': source['image_url'] ?? source['imageUrl'] ?? '',
              'zone': cleanMarkdownDecorations(
                (source['zone'] ?? '') as String,
              ),
              'min_height_cm':
                  source['min_height_cm'] ?? source['minHeightCm'] ?? 0,
              'recommended_age':
                  source['recommended_age'] ?? source['recommendedAge'] ?? '',
              'adrenaline_level':
                  source['adrenaline_level'] ?? source['adrenalineLevel'] ?? '',
              'has_dizziness_warning':
                  (source['has_dizziness_warning'] == 1 ||
                      source['hasDizzinessWarning'] == true)
                  ? 1
                  : 0,
              'avg_wait_minutes':
                  source['avg_wait_minutes'] ?? source['avgWaitMinutes'] ?? 0,
              'duration_minutes':
                  source['duration_minutes'] ?? source['durationMinutes'] ?? 0,
            });
          }
        }
      }

      // Ensure Day 0 exists
      if (!daysToInsert.any((d) => d['day_number'] == 0)) {
        daysToInsert.insert(0, {
          'trip_id': newTripId,
          'day_number': 0,
          'date': '',
          'weekday': '',
          'title': 'Stops without a scheduled day',
          'lodging_city': '',
          'wakeup_city': '',
          'checklist': '[]',
        });
      }

      for (final d in daysToInsert) {
        await txn.insert('days', d);
      }

      for (final p in normalizedPlaces) {
        final copy = Map<String, dynamic>.from(p)..remove('id');
        copy['trip_id'] = newTripId;
        copy['name'] = cleanMarkdownDecorations((copy['name'] ?? '') as String);
        copy['raw_description'] = cleanMarkdownDecorations(
          (copy['raw_description'] ?? '') as String,
        );
        copy['notes'] = cleanMarkdownDecorations(
          (copy['notes'] ?? '') as String,
        );
        copy['zone'] = cleanMarkdownDecorations((copy['zone'] ?? '') as String);
        await txn.insert('places', copy);
      }

      for (final t in rawTips) {
        final tMap = Map<String, dynamic>.from(t as Map)..remove('id');
        tMap['trip_id'] = newTripId;
        tMap['title'] = cleanMarkdownDecorations(
          (tMap['title'] ?? '') as String,
        );
        tMap['content'] = cleanMarkdownDecorations(
          (tMap['content'] ?? '') as String,
        );
        await txn.insert('tips', tMap);
      }
    });

    await setSelectedTripId(newTripId);
    return newTripId;
  }

  // Backward compatibility with previous exportData / importData
  Future<Map<String, dynamic>> exportData() async {
    final selectedTripId = (await getSelectedTripId()) ?? 1;
    final allTrips = await getAllTrips();
    if (allTrips.isEmpty) {
      return {
        'formatVersion': 1,
        'app': 'nomadtrip',
        'days': [],
        'places': [],
        'tips': [],
      };
    }
    return await exportTripNtrip(selectedTripId);
  }

  Future<void> importData(Map<String, dynamic> data) async {
    await importTripData(data);
  }
}
