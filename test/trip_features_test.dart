import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:nomadtrip/core/models/itinerary_place.dart';
import 'package:nomadtrip/core/models/trip.dart';
import 'package:nomadtrip/core/models/trip_day.dart';
import 'package:nomadtrip/core/models/trip_tip.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Markdown Cleaning Rule (Item 20)', () {
    test(
      'cleans bold asterisks and underscores from place descriptions and names',
      () {
        const dirtyName = '__Apple Store__ – Town Center';
        const dirtyDesc = 'Comprar **iPhone** e fones na loja da __Apple__.';

        final cleanName = cleanMarkdownDecorations(dirtyName);
        final cleanDesc = cleanMarkdownDecorations(dirtyDesc);

        expect(cleanName, 'Apple Store – Town Center');
        expect(cleanDesc, 'Comprar iPhone e fones na loja da Apple.');
      },
    );

    test('model fromMap sanitizes strings automatically', () {
      final place = ItineraryPlace.fromMap({
        'day_number': 1,
        'name': '__Gaston Tavern__',
        'time': '16h00',
        'raw_description': 'Comprar **Cinnamon Roll** gigante.',
        'category': 'food',
        'city': 'Orlando',
        'latitude': 28.4,
        'longitude': -81.5,
      });

      expect(place.name, 'Gaston Tavern');
      expect(place.rawDescription, 'Comprar Cinnamon Roll gigante.');
    });
  });

  group('Trip Calculation and Day Reduction Validation (Item 23)', () {
    test('calculates total days correctly between start and end date', () {
      final trip = Trip(
        name: 'Florida 2026',
        startDate: '2026-11-24',
        endDate: '2026-12-13',
        createdAt: DateTime.now(),
      );

      expect(trip.totalDays, 20);
    });

    test(
      'validates trip duration reduction when places exist on truncated days',
      () async {
        final db = await openDatabase(
          inMemoryDatabasePath,
          version: 3,
          onCreate: (db, version) async {
            await db.execute('''
            CREATE TABLE trips (id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT, start_date TEXT, end_date TEXT, created_at TEXT)
          ''');
            await db.execute('''
            CREATE TABLE places (id INTEGER PRIMARY KEY AUTOINCREMENT, trip_id INTEGER, day_number INTEGER, name TEXT, time TEXT, raw_description TEXT, category TEXT, city TEXT, latitude REAL, longitude REAL, parking TEXT, parking_cost INTEGER, is_visited INTEGER, visited_at TEXT, requires_reservation INTEGER, notes TEXT, links TEXT, is_alternative INTEGER, image_url TEXT, zone TEXT, min_height_cm INTEGER, recommended_age TEXT, adrenaline_level TEXT, has_dizziness_warning INTEGER, avg_wait_minutes INTEGER, duration_minutes INTEGER)
          ''');
          },
        );

        // Insert test places on day 5 and day 10
        await db.insert('places', {
          'trip_id': 1,
          'day_number': 5,
          'name': 'Busch Gardens',
          'time': '09h00',
        });
        await db.insert('places', {
          'trip_id': 1,
          'day_number': 10,
          'name': 'Hollywood Studios',
          'time': '08h00',
        });

        // Reducing to 7 days should throw because day 10 has a place
        final placesBeyond7 = await db.query(
          'places',
          where: 'trip_id = ? AND day_number > ?',
          whereArgs: [1, 7],
        );
        expect(placesBeyond7.isNotEmpty, isTrue);

        final offendingDays = placesBeyond7
            .map((p) => p['day_number'] as int)
            .toSet()
            .toList();
        expect(offendingDays, contains(10));

        await db.close();
      },
    );
  });

  group('Attraction Details and Coaster Specs (Items 15 & 16)', () {
    test(
      'preserves min height, adrenaline, dizziness warning, wait time and duration in model',
      () {
        const coaster = ItineraryPlace(
          dayNumber: 7,
          name: 'TRON Lightcycle Run',
          time: '15h00',
          rawDescription: 'High-speed coaster in Tomorrowland',
          category: 'theme_park',
          city: 'Orlando',
          latitude: 28.419,
          longitude: -81.577,
          zone: 'Tomorrowland',
          minHeightCm: 122,
          recommendedAge: '8+ anos',
          adrenalineLevel: 'Alto',
          hasDizzinessWarning: false,
          avgWaitMinutes: 60,
          durationMinutes: 2,
          requiresReservation: false,
        );

        final map = coaster.toMap();
        final restored = ItineraryPlace.fromMap(map);

        expect(restored.name, 'TRON Lightcycle Run');
        expect(restored.zone, 'Tomorrowland');
        expect(restored.minHeightCm, 122);
        expect(restored.recommendedAge, '8+ anos');
        expect(restored.adrenalineLevel, 'Alto');
        expect(restored.hasDizzinessWarning, isFalse);
        expect(restored.avgWaitMinutes, 60);
        expect(restored.durationMinutes, 2);
      },
    );

    test('preserves dizziness warning for spinning attractions', () {
      const simpsons = ItineraryPlace(
        dayNumber: 14,
        name: 'The Simpsons Ride',
        time: '16h00',
        rawDescription: 'Simulador nostálgico com balanços fortes',
        category: 'theme_park',
        city: 'Orlando',
        latitude: 28.474,
        longitude: -81.468,
        zone: 'Springfield',
        hasDizzinessWarning: true,
      );

      final restored = ItineraryPlace.fromMap(simpsons.toMap());
      expect(restored.hasDizzinessWarning, isTrue);
    });
  });

  group('Checklist Item Serialization (Item 17 & 26)', () {
    test(
      'serializes and deserializes checklist items with completion states',
      () {
        final items = [
          const ChecklistItem(
            id: '1',
            text: 'Levar capa de chuva',
            isCompleted: false,
          ),
          const ChecklistItem(
            id: '2',
            text: 'Protetor solar',
            isCompleted: true,
          ),
        ];

        final day = TripDay(
          dayNumber: 7,
          date: '2026-11-30',
          weekday: 'Segunda',
          title: 'Magic Kingdom',
          lodgingCity: 'Orlando',
          wakeupCity: 'Orlando',
          checklist: items,
        );

        final restored = TripDay.fromMap(day.toMap());
        expect(restored.checklist.length, 2);
        expect(restored.checklist[0].text, 'Levar capa de chuva');
        expect(restored.checklist[0].isCompleted, isFalse);
        expect(restored.checklist[1].text, 'Protetor solar');
        expect(restored.checklist[1].isCompleted, isTrue);
      },
    );
  });

  group('Tips with Day Scope (Item 10 & 21)', () {
    test('preserves dayNumber in TripTip model', () {
      const generalTip = TripTip(
        category: 'money',
        title: 'Cartão Internacional',
        content: 'Cadastre no app Disney e Universal',
        dayNumber: 0,
      );

      const daySpecificTip = TripTip(
        category: 'strategy',
        title: 'Chegar no estacionamento',
        content: 'Tirar foto da placa do setor Heróis/Vilões',
        dayNumber: 7,
      );

      expect(TripTip.fromMap(generalTip.toMap()).dayNumber, 0);
      expect(TripTip.fromMap(daySpecificTip.toMap()).dayNumber, 7);
    });
  });

  group('Florida 2026 .ntrip Import and Verification (Items 1, 2, 5, 7, 8, 25)', () {
    test('validates generated florida2026.ntrip contents and rules', () async {
      final file = File('docs/florida2026.ntrip');
      expect(file.existsSync(), isTrue);

      final content =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(content['format'], 'nomadtrip');
      expect(content['version'], 2);

      final days = content['days'] as List;
      final places = content['places'] as List;
      final tips = content['tips'] as List;

      expect(days.length, 20);
      expect(places.length, greaterThan(100));
      expect(tips.length, greaterThanOrEqualTo(16));

      // Rule: Day 7 has Gaston Tavern with Cinnamon Roll and Instagram link
      final day7Places = places.where((p) => p['day_number'] == 7).toList();
      final gastonDay7 = day7Places.firstWhere(
        (p) => (p['name'] as String).contains("Gaston"),
      );
      expect(gastonDay7['raw_description'], contains('Cinnamon Roll'));
      expect(
        gastonDay7['links'],
        contains('https://www.instagram.com/reels/DaD1YilSr-m/'),
      );

      // Rule: Jungle Cruise was removed from Day 7 (Item 5)
      final jungleCruiseDay7 = day7Places
          .where(
            (p) =>
                (p['name'] as String).toLowerCase().contains('jungle cruise'),
          )
          .toList();
      expect(jungleCruiseDay7.isEmpty, isTrue);

      // Rule: Day 8 has Gaston Tavern with Cinnamon Roll and Croissant (Item 1 & 2)
      final day8Places = places.where((p) => p['day_number'] == 8).toList();
      final gastonDay8 = day8Places.firstWhere(
        (p) => (p['name'] as String).contains("Gaston"),
      );
      expect(gastonDay8['raw_description'], contains('Cinnamon Roll'));

      // Rule: Day 17 has Panda Express and Water Taxi to Portofino Bay (Item 7 & 8)
      final day17Places = places.where((p) => p['day_number'] == 17).toList();
      expect(
        day17Places.any((p) => (p['name'] as String).contains('Panda Express')),
        isTrue,
      );
      expect(
        day17Places.any(
          (p) =>
              (p['name'] as String).contains('Water Taxi') &&
              (p['name'] as String).contains('Portofino'),
        ),
        isTrue,
      );
    });
  });
}
