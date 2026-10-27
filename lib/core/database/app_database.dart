import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import '../models/itinerary_place.dart';
import '../models/trip_day.dart';
import '../models/trip_tip.dart';

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
      version: 2,
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
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Days table
    await db.execute('''
      CREATE TABLE days (
        day_number INTEGER PRIMARY KEY,
        date TEXT NOT NULL,
        weekday TEXT NOT NULL,
        title TEXT NOT NULL,
        lodging_city TEXT NOT NULL,
        wakeup_city TEXT NOT NULL
      )
    ''');

    // Places table
    await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
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
        FOREIGN KEY (day_number) REFERENCES days (day_number) ON DELETE CASCADE
      )
    ''');

    // Tips table
    await db.execute('''
      CREATE TABLE tips (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        title TEXT NOT NULL,
        content TEXT NOT NULL,
        is_completed INTEGER DEFAULT 0
      )
    ''');

    // Index for fast search
    await db.execute('CREATE INDEX idx_places_day ON places (day_number)');
    await db.execute('CREATE INDEX idx_places_name ON places (name)');

    // Seed database with initial nomadtrip data from JSON asset
    await db.insert('days', {
      'day_number': 0,
      'date': '',
      'weekday': '',
      'title': 'Stops without a scheduled day',
      'lodging_city': '',
      'wakeup_city': '',
    });
    await _seedDatabase(db);
  }

  Future<void> _seedDatabase(Database db) async {
    try {
      final jsonString = await rootBundle.loadString(
        'assets/data/itinerary_seed.json',
      );
      final Map<String, dynamic> data = jsonDecode(jsonString);

      final List<dynamic> daysJson = data['days'] as List<dynamic>;
      final List<dynamic> tipsJson = data['tips'] as List<dynamic>? ?? [];

      final batch = db.batch();

      for (final d in daysJson) {
        batch.insert('days', {
          'day_number': d['dayNumber'],
          'date': d['date'],
          'weekday': d['weekday'],
          'title': d['title'],
          'lodging_city': d['lodgingCity'] ?? 'Orlando',
          'wakeup_city': d['wakeupCity'] ?? 'Orlando',
        });

        final items = d['items'] as List<dynamic>? ?? [];
        for (final item in items) {
          batch.insert('places', {
            'day_number': d['dayNumber'],
            'name': item['placeName'] ?? '',
            'time': item['time'] ?? '',
            'raw_description': item['rawDescription'] ?? '',
            'category': item['category'] ?? 'attraction',
            'city': item['city'] ?? d['lodgingCity'] ?? 'Orlando',
            'latitude': (item['latitude'] as num?)?.toDouble() ?? 0.0,
            'longitude': (item['longitude'] as num?)?.toDouble() ?? 0.0,
            'parking': item['parking'] ?? 'Unknown',
            'parking_cost': (item['parkingCost'] as int?) ?? 0,
            'is_visited': 0,
            'visited_at': null,
            'requires_reservation': item['requiresReservation'] == true ? 1 : 0,
            'notes': '',
            'links': jsonEncode([]),
            'is_alternative': item['isAlternative'] == true ? 1 : 0,
          });
        }
      }

      for (final t in tipsJson) {
        batch.insert('tips', {
          'category': t['category'] ?? 'general',
          'title': t['title'] ?? '',
          'content': t['content'] ?? '',
          'is_completed': 0,
        });
      }

      await batch.commit(noResult: true);
    } catch (e) {
      // In case seeding from asset fails in testing environment
      // database will still function with empty tables
    }
  }

  // Days Queries
  Future<List<TripDay>> getAllDays() async {
    final db = await database;
    final dayMaps = await db.query('days', orderBy: 'day_number ASC');

    final List<TripDay> days = [];
    for (final dayMap in dayMaps) {
      final dayNum = dayMap['day_number'] as int;
      final placeMaps = await db.query(
        'places',
        where: 'day_number = ?',
        whereArgs: [dayNum],
        orderBy: 'id ASC',
      );
      final places = placeMaps.map((p) => ItineraryPlace.fromMap(p)).toList();
      days.add(TripDay.fromMap(dayMap, places));
    }
    return days;
  }

  Future<TripDay?> getDay(int dayNumber) async {
    final db = await database;
    final dayMaps = await db.query(
      'days',
      where: 'day_number = ?',
      whereArgs: [dayNumber],
    );
    if (dayMaps.isEmpty) return null;

    final placeMaps = await db.query(
      'places',
      where: 'day_number = ?',
      whereArgs: [dayNumber],
      orderBy: 'id ASC',
    );
    final places = placeMaps.map((p) => ItineraryPlace.fromMap(p)).toList();
    return TripDay.fromMap(dayMaps.first, places);
  }

  // Places Queries
  Future<List<ItineraryPlace>> getAllPlaces() async {
    final db = await database;
    final maps = await db.query('places', orderBy: 'day_number ASC, id ASC');
    return maps.map((m) => ItineraryPlace.fromMap(m)).toList();
  }

  Future<List<ItineraryPlace>> searchPlaces(String query) async {
    if (query.trim().isEmpty) return getAllPlaces();
    final db = await database;
    final cleanQuery = '%${query.trim()}%';
    final maps = await db.query(
      'places',
      where:
          'name LIKE ? OR raw_description LIKE ? OR city LIKE ? OR notes LIKE ?',
      whereArgs: [cleanQuery, cleanQuery, cleanQuery, cleanQuery],
      orderBy: 'day_number ASC',
    );
    return maps.map((m) => ItineraryPlace.fromMap(m)).toList();
  }

  Future<int> insertPlace(ItineraryPlace place) async {
    final db = await database;
    return await db.insert('places', place.toMap());
  }

  Future<Map<String, dynamic>> exportData() async {
    final db = await database;
    return {
      'formatVersion': 1,
      'app': 'nomadtrip',
      'days': await db.query('days', orderBy: 'day_number ASC'),
      'places': await db.query('places', orderBy: 'day_number ASC, id ASC'),
      'tips': await db.query('tips', orderBy: 'id ASC'),
    };
  }

  Future<void> importData(Map<String, dynamic> data) async {
    final db = await database;
    final rawDays = (data['days'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final places = (data['places'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final tips = (data['tips'] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>();
    final days = <Map<String, dynamic>>[];
    final normalizedPlaces = <Map<String, dynamic>>[...places];
    for (final day in rawDays) {
      days.add(
        day.containsKey('day_number')
            ? day
            : {
                'day_number': day['dayNumber'] ?? 0,
                'date': day['date'] ?? '',
                'weekday': day['weekday'] ?? '',
                'title': day['title'] ?? '',
                'lodgingCity': day['lodgingCity'] ?? '',
                'wakeupCity': day['wakeupCity'] ?? '',
              },
      );
      for (final item in (day['items'] as List<dynamic>? ?? const [])) {
        final source = Map<String, dynamic>.from(item as Map);
        normalizedPlaces.add({
          'day_number': day['dayNumber'] ?? 0,
          'name': source['placeName'] ?? '',
          'time': source['time'] ?? '',
          'raw_description': source['rawDescription'] ?? '',
          'category': source['category'] ?? 'attraction',
          'city': source['city'] ?? '',
          'latitude': source['latitude'] ?? 0.0,
          'longitude': source['longitude'] ?? 0.0,
          'parking': source['parking'] ?? 'Unknown',
          'parking_cost': source['parkingCost'] ?? 0,
          'is_visited': 0,
          'requires_reservation': source['requiresReservation'] == true ? 1 : 0,
          'notes': '',
          'links': jsonEncode([]),
          'is_alternative': source['isAlternative'] == true ? 1 : 0,
        });
      }
    }
    if (!days.any((day) => (day['day_number'] ?? day['dayNumber']) == 0)) {
      days.insert(0, {
        'day_number': 0,
        'date': '',
        'weekday': '',
        'title': 'Stops without a scheduled day',
        'lodging_city': '',
        'wakeup_city': '',
      });
    }
    if (days.isEmpty && normalizedPlaces.isEmpty && tips.isEmpty) {
      throw const FormatException('JSON sem dados de viagem');
    }
    await db.transaction((txn) async {
      await txn.delete('places');
      await txn.delete('days');
      await txn.delete('tips');
      for (final day in days) {
        final copy = Map<String, dynamic>.from(day)..remove('id');
        await txn.insert('days', {
          'day_number': copy['day_number'] ?? copy['dayNumber'] ?? 0,
          'date': copy['date'] ?? '',
          'weekday': copy['weekday'] ?? '',
          'title': copy['title'] ?? '',
          'lodging_city': copy['lodging_city'] ?? copy['lodgingCity'] ?? '',
          'wakeup_city': copy['wakeup_city'] ?? copy['wakeupCity'] ?? '',
        });
      }
      for (final place in normalizedPlaces) {
        final copy = Map<String, dynamic>.from(place)..remove('id');
        await txn.insert('places', copy);
      }
      for (final tip in tips) {
        final copy = Map<String, dynamic>.from(tip)..remove('id');
        await txn.insert('tips', copy);
      }
    });
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

  Future<int> movePlace(int placeId, int newDayNumber, String newTime) async {
    final db = await database;
    return await db.update(
      'places',
      {'day_number': newDayNumber, 'time': newTime},
      where: 'id = ?',
      whereArgs: [placeId],
    );
  }

  // Tips Queries
  Future<List<TripTip>> getAllTips() async {
    final db = await database;
    final maps = await db.query('tips', orderBy: 'id ASC');
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
    return await db.insert('tips', tip.toMap());
  }

  Future<int> deleteTip(int tipId) async {
    final db = await database;
    return await db.delete('tips', where: 'id = ?', whereArgs: [tipId]);
  }
}
