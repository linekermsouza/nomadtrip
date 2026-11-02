import 'dart:convert';
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
    // Note: On Android, custom extensions like .ntrip do not have standard MIME types in Android MimeTypeMap.
    // Using FileType.any allows Android's Storage Access Framework / Google Drive to select .ntrip files without greying them out.
    // withData: true ensures bytes are read into memory even for cloud-backed Google Drive files.
    final result = await FilePicker.pickFiles(
      type: FileType.any,
      withData: true,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;
    Uint8List? bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      bytes = await file.xFile.readAsBytes();
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
