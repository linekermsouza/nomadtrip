import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../database/app_database.dart';

class BackupService {
  static Future<void> exportBackup() async {
    final json = const JsonEncoder.withIndent(
      '  ',
    ).convert(await AppDatabase.instance.exportData());
    final bytes = Uint8List.fromList(utf8.encode(json));
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile.fromData(
            bytes,
            mimeType: 'application/json',
            name: 'nomadtrip-backup.json',
          ),
        ],
        text: 'Backup do nomadtrip',
        downloadFallbackEnabled: true,
      ),
    );
  }

  static Future<void> importBackup() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );
    if (result.isEmpty) return;
    final bytes = await result.first.readAsBytes();
    final data = jsonDecode(utf8.decode(bytes));
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Formato de backup inválido');
    }
    await AppDatabase.instance.importData(data);
  }
}
