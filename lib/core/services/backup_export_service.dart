// lib/core/services/backup_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';
import 'package:hive_flutter/hive_flutter.dart';

class BackupExportService {
  BackupExportService._();
  static final instance = BackupExportService._();

  Future<void> exportBackup() async {
    try {
      // Dump Hive boxes
      final Box settingsBox = Hive.box('global_settings');
      final Box dataBox = Hive.box('global_data');
      
      final Map<String, dynamic> fullBackup = {
        'settings': settingsBox.toMap().map((key, value) => MapEntry(key.toString(), value)),
        'data': dataBox.toMap().map((key, value) => MapEntry(key.toString(), value)),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final String jsonString = jsonEncode(fullBackup);
      final directory = await getTemporaryDirectory();
      final String dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final File file = File('${directory.path}/wallet_backup_$dateStr.json');
      
      await file.writeAsString(jsonString);
      await Share.shareXFiles([XFile(file.path)], text: 'Backup $dateStr');
    } catch (e) {
      throw Exception("Backup export failed: $e");
    }
  }

  Future<bool> importBackup() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (result != null && result.files.single.path != null) {
        final File file = File(result.files.single.path!);
        final String jsonString = await file.readAsString();
        final Map<String, dynamic> data = jsonDecode(jsonString);

        final Box settingsBox = Hive.box('global_settings');
        final Box dataBox = Hive.box('global_data');

        if (data.containsKey('settings')) {
          await settingsBox.clear();
          await settingsBox.putAll(Map<String, dynamic>.from(data['settings']));
        }
        
        if (data.containsKey('data')) {
          await dataBox.clear();
          await dataBox.putAll(Map<String, dynamic>.from(data['data']));
        }
        
        return true;
      }
      return false;
    } catch (e) {
      throw Exception("Backup import failed: $e");
    }
  }

  Future<void> exportToExcel(String dataType, List<dynamic> items) async {
    try {
      List<List<dynamic>> rows = [];

      if (dataType == 'budget' && items.isNotEmpty) {
        rows.add(["ID", "Nombre", "Categoria", "Monto Original", "Moneda Original", "Monto Local", "Fecha"]);
        for (var item in items) {
          rows.add([item.id, item.nombre, item.categoria, item.montoOriginal, item.monedaOriginal, item.montoLocal, item.fecha.toString()]);
        }
      } else if (dataType == 'shipping' && items.isNotEmpty) {
        rows.add(["ID", "Origen", "Destino", "Peso (kg)", "Total", "Moneda", "Fecha"]);
        for (var item in items) {
          rows.add([item.id, item.origen, item.destino, item.peso, item.total, item.moneda, item.fecha.toString()]);
        }
      } else {
        return;
      }

      final String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final String dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final File file = File('${directory.path}/${dataType}_export_$dateStr.csv');
      
      await file.writeAsString(csvData);
      await Share.shareXFiles([XFile(file.path)], text: 'Export $dataType');
    } catch (e) {
      throw Exception("CSV export failed: $e");
    }
  }
}
