import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomadtrip/core/models/checklist_item.dart';
import 'package:nomadtrip/core/models/itinerary_place.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Place Checklist Model & Serialization', () {
    test('serializes and deserializes place checklist correctly', () {
      const item1 = ChecklistItem(
        id: '1',
        text: '2 caixas de água',
        isCompleted: true,
      );
      const item2 = ChecklistItem(
        id: '2',
        text: 'Batata Pringles',
        isCompleted: false,
      );

      const place = ItineraryPlace(
        dayNumber: 1,
        name: 'Walmart Supercenter',
        time: '18h45',
        rawDescription: 'Compras de mantimentos',
        category: 'shopping',
        city: 'Orlando',
        latitude: 28.36,
        longitude: -81.42,
        checklist: [item1, item2],
      );

      final map = place.toMap();
      expect(map['checklist'], isA<String>());
      expect(map['checklist'], contains('2 caixas de água'));

      final restored = ItineraryPlace.fromMap(map);
      expect(restored.checklist.length, 2);
      expect(restored.checklist[0].id, '1');
      expect(restored.checklist[0].text, '2 caixas de água');
      expect(restored.checklist[0].isCompleted, isTrue);
      expect(restored.checklist[1].id, '2');
      expect(restored.checklist[1].text, 'Batata Pringles');
      expect(restored.checklist[1].isCompleted, isFalse);
    });

    test('handles place with empty or missing checklist gracefully', () {
      final mapWithoutChecklist = {
        'day_number': 1,
        'name': 'Publix',
        'time': '10h00',
        'raw_description': '',
        'category': 'shopping',
        'city': 'Orlando',
        'latitude': 28.0,
        'longitude': -81.0,
      };

      final restored = ItineraryPlace.fromMap(mapWithoutChecklist);
      expect(restored.checklist, isEmpty);
    });

    test('supports copyWith with updated checklist items', () {
      const place = ItineraryPlace(
        dayNumber: 1,
        name: 'Walmart',
        time: '18h45',
        rawDescription: '',
        category: 'shopping',
        city: 'Orlando',
        latitude: 28.0,
        longitude: -81.0,
      );

      final updated = place.copyWith(
        checklist: [
          const ChecklistItem(id: '1', text: 'Leite', isCompleted: false),
        ],
      );

      expect(updated.checklist.length, 1);
      expect(updated.checklist[0].text, 'Leite');
    });
  });

  group('Database Migration to Version 4 & Schema Compatibility', () {
    test(
      'upgrades version 3 database by adding checklist column to places',
      () async {
        final db = await openDatabase(
          inMemoryDatabasePath,
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE trips (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, start_date TEXT, end_date TEXT, created_at TEXT)
          ''');
            await db.execute('''
            CREATE TABLE days (id INTEGER PRIMARY KEY AUTOINCREMENT, trip_id INTEGER, day_number INTEGER, date TEXT, weekday TEXT, title TEXT, lodging_city TEXT, wakeup_city TEXT, checklist TEXT DEFAULT '[]')
          ''');
            await db.execute('''
            CREATE TABLE places (id INTEGER PRIMARY KEY AUTOINCREMENT, trip_id INTEGER, day_number INTEGER, name TEXT, time TEXT, raw_description TEXT, category TEXT, city TEXT, latitude REAL, longitude REAL, parking TEXT, parking_cost INTEGER, is_visited INTEGER, visited_at TEXT, requires_reservation INTEGER, notes TEXT, links TEXT, is_alternative INTEGER, image_url TEXT, zone TEXT, min_height_cm INTEGER, recommended_age TEXT, adrenaline_level TEXT, has_dizziness_warning INTEGER, avg_wait_minutes INTEGER, duration_minutes INTEGER)
          ''');
          },
        );

        // Insert place on v3 schema
        await db.insert('places', {
          'trip_id': 1,
          'day_number': 1,
          'name': 'Walmart Supercenter',
          'time': '18h45',
        });

        // Simulate upgrade to v4
        await db.execute(
          "ALTER TABLE places ADD COLUMN checklist TEXT DEFAULT '[]'",
        );

        // Verify that existing row has default '[]'
        final rows = await db.query('places');
        expect(rows.first['checklist'], '[]');

        // Update place with checklist JSON
        final checklistJson = jsonEncode([
          {'id': '1', 'text': '2 caixas de água', 'isCompleted': true},
          {'id': '2', 'text': 'Doritos', 'isCompleted': false},
        ]);
        await db.update(
          'places',
          {'checklist': checklistJson},
          where: 'id = ?',
          whereArgs: [rows.first['id']],
        );

        final updatedRows = await db.query('places');
        final place = ItineraryPlace.fromMap(updatedRows.first);
        expect(place.checklist.length, 2);
        expect(place.checklist[0].text, '2 caixas de água');
        expect(place.checklist[0].isCompleted, isTrue);

        await db.close();
      },
    );
  });

  group('Florida 2026 .ntrip Walmart Checklist Validation', () {
    test(
      'validates Walmart on Day 1 contains 26 grocery checklist items',
      () async {
        final file = File('docs/florida2026.ntrip');
        expect(file.existsSync(), isTrue);

        final content =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        final places = (content['places'] as List).cast<Map<String, dynamic>>();

        final walmart = places.firstWhere(
          (p) =>
              p['day_number'] == 1 && (p['name'] as String).contains('Walmart'),
        );

        expect(walmart, isNotNull);
        expect(walmart.containsKey('checklist'), isTrue);

        final decodedChecklist = walmart['checklist'] is String
            ? (jsonDecode(walmart['checklist'] as String) as List)
            : (walmart['checklist'] as List);

        expect(decodedChecklist.length, 26);

        final texts = decodedChecklist.map((c) => c['text'] as String).toList();
        expect(texts, contains('2 caixas de água (35 ou 40 unidades)'));
        expect(texts, contains('1 galão de água para deixar na casa'));
        expect(texts, contains('Suco de laranja (1 ou 2 garrafas)'));
        expect(texts, contains('Leite (2 galões ou 2 embalagens grandes)'));
        expect(texts, contains('Coca-Cola / refrigerante para a casa'));
        expect(texts, contains('Gatorade ou Powerade (6 a 8 unidades)'));
        expect(texts, contains('Batata Pringles'));
        expect(texts, contains('Doritos'));
        expect(texts, contains('Goldfish para as crianças'));
        expect(texts, contains('Cookies Oreo'));
        expect(texts, contains('Barrinhas de cereal'));
        expect(texts, contains('Mix de castanhas/amendoins'));
        expect(texts, contains('Bananas'));
        expect(texts, contains('Maçãs'));
        expect(texts, contains('Pacote de frutas cortadas (se encontrar)'));
        expect(texts, contains('Pizza congelada'));
        expect(texts, contains('Mac and Cheese (é bom?)'));
        expect(texts, contains('Pão de forma'));
        expect(texts, contains('Manteiga'));
        expect(texts, contains('Cream Cheese Philadelphia'));
        expect(texts, contains('Presunto'));
        expect(texts, contains('Queijo fatiado'));
        expect(texts, contains('Ovos (18 unidades)'));
        expect(texts, contains('Bacon'));
        expect(texts, contains('Iogurte'));
        expect(texts, contains('Cereal (Cheerios, Froot Loops, etc.)'));
      },
    );
  });
}
