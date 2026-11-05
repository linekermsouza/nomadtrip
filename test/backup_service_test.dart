import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nomadtrip/core/services/backup_service.dart';

void main() {
  test('parses a valid .ntrip payload independently of the platform picker', () {
    final payload = Uint8List.fromList(
      utf8.encode(jsonEncode({'trip': {'name': 'Florida'}, 'days': []})),
    );

    final result = BackupService.parseTripBytes(payload);

    expect(result['trip'], isA<Map<String, dynamic>>());
    expect(result['days'], isEmpty);
  });

  test('rejects an unrelated JSON file', () {
    final payload = Uint8List.fromList(utf8.encode(jsonEncode({'foo': 'bar'})));

    expect(
      () => BackupService.parseTripBytes(payload),
      throwsA(isA<FormatException>()),
    );
  });
