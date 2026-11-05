import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

class BackupService {
  static Future<void> exportTripNtrip(int tripId, String tripName) async {
    final data = await AppDatabase.instance.exportTripNtrip(tripId);
    final json = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = Uint8List.fromList(utf8.encode(json));
    final safeName = tripName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '_',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: '$safeName.ntrip',
          ),
        ],
        text: 'Roteiro nomadtrip — $tripName (.ntrip)',
        downloadFallbackEnabled: true,
      ),
    );
  }

  static Future<void> exportTripMarkdown(int tripId, String tripName) async {
    final md = await AppDatabase.instance.exportTripMarkdown(tripId);
    final bytes = Uint8List.fromList(utf8.encode(md));
    final safeName = tripName.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]'),
      '_',
    );

    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'text/markdown',
            name: '$safeName.md',
          ),
        ],
        text: 'Roteiro nomadtrip — $tripName (.md)',
        downloadFallbackEnabled: true,
      ),
    );
  }

  static Future<Map<String, dynamic>?> loadBundledFloridaTrip() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/data/florida2026.ntrip');
      final data = jsonDecode(jsonStr);
      if (data is Map<String, dynamic>) {
        return data;
      }
    } catch (_) {}
    return null;
  }

  static Future<Map<String, dynamic>?> pickAndParseTripFile() async {
    // .ntrip has no registered Android MIME type. file_picker falls back to
    // */* for unknown custom extensions on Android, while still filtering by
    // extension on platforms that support it. This keeps .ntrip selectable in
    // both Downloads and Google Drive instead of showing it as unsupported.
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      allowedExtensions: ['ntrip', 'json'],
      withData: true,
    );

    if (result == null || result.isEmpty) return null;

    final file = result.first;
    // Google Drive/Files providers can return a file without the bytes in the
    // picker response. The XFile points to the temporary local copy created by
    // Android's Storage Access Framework, so use it as a fallback.
    final bytes = await File(file.path!).readAsBytes();

    return parseTripBytes(bytes);
  }

  /// Parses the content of a .ntrip (or exported .json) file.
  ///
  /// Kept separate from the platform picker so files shared from Google Drive
  /// and other apps can use exactly the same validation path.
  static Map<String, dynamic> parseTripBytes(Uint8List bytes) {
    if (bytes.isEmpty) {
      throw const FormatException('O arquivo selecionado está vazio.');
    }

    final content = utf8.decode(bytes);
    final data = jsonDecode(content);

    if (data is! Map<String, dynamic>) {
      throw const FormatException(
        'O arquivo selecionado não contém um formato de roteiro nomadtrip válido.',
      );
    }

    final hasTripData = data.containsKey('trip') ||
        data.containsKey('tripName') ||
        data.containsKey('days');

    if (!hasTripData) {
      throw const FormatException(
        'Arquivo JSON inválido. Certifique-se de selecionar um arquivo .ntrip ou .json exportado pelo nomadtrip.',
      );
    }

    return data;
  }

  static Future<void> exportBackup() async {
    final selectedTripId = await AppDatabase.instance.getSelectedTripId();
    if (selectedTripId == null) return;
    await exportTripNtrip(selectedTripId, 'nomadtrip-backup');
  }

  static Future<void> importBackup() async {
    final data = await pickAndParseTripFile();
    if (data != null) {
      await AppDatabase.instance.importTripData(data);
    }
  }
}
