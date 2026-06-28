// Archivo: lib/core/services/backup_export_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:intl/intl.dart';

import '../database/local_storage_service.dart';

class BackupExportService {
  BackupExportService._();
  static final instance = BackupExportService._();

  /// ==========================================
  /// 1. COPIAS DE SEGURIDAD (JSON)
  /// ==========================================
  
  /// Exporta toda la base de datos a un archivo JSON y abre el menú para guardarlo en la nube o local.
  Future<void> exportBackup() async {
    try {
      final storage = LocalStorageService.instance;
      
      // Recolectar toda la data
      final Map<String, dynamic> fullBackup = {
        'settings': storage.settingsBox.toMap(),
        'budget': storage.budgetBox.toMap(),
        'shipping': storage.shippingBox.toMap(),
        'timestamp': DateTime.now().toIso8601String(),
      };

      final String jsonString = jsonEncode(fullBackup);
      final directory = await getTemporaryDirectory();
      
      final String dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final File file = File('${directory.path}/wallet_backup_$dateStr.json');
      
      await file.writeAsString(jsonString);

      // Compartir para guardar en Drive, iCloud, o local
      await Share.shareXFiles([XFile(file.path)], text: 'Copia de seguridad generada el $dateStr');
    } catch (e) {
      throw Exception("Error al exportar la copia de seguridad: $e");
    }
  }

  /// Importa un archivo JSON de respaldo y sobrescribe la base de datos actual.
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

        final storage = LocalStorageService.instance;

        // Restaurar Ajustes
        if (data.containsKey('settings')) {
          await storage.settingsBox.clear();
          await storage.settingsBox.putAll(Map<String, dynamic>.from(data['settings']));
        }
        
        // Restaurar Presupuestos
        if (data.containsKey('budget')) {
          await storage.budgetBox.clear();
          await storage.budgetBox.putAll(Map<String, dynamic>.from(data['budget']));
        }

        // Restaurar Envíos
        if (data.containsKey('shipping')) {
          await storage.shippingBox.clear();
          await storage.shippingBox.putAll(Map<String, dynamic>.from(data['shipping']));
        }
        
        return true;
      }
      return false;
    } catch (e) {
      throw Exception("Error al restaurar la copia de seguridad: $e");
    }
  }

  /// ==========================================
  /// 2. EXPORTACIÓN A EXCEL (CSV)
  /// ==========================================
  
  /// Exporta la lista de gastos o cotizaciones a formato CSV compatible con Excel.
  Future<void> exportToExcel(String dataType, List<dynamic> items) async {
    try {
      List<List<dynamic>> rows = [];

      if (dataType == 'budget' && items.isNotEmpty) {
        // Cabeceras para Presupuesto
        rows.add(["ID", "Nombre", "Categoria", "Monto Original", "Moneda Original", "Monto Local", "Fecha"]);
        for (var item in items) {
          rows.add([
            item.id, item.nombre, item.categoria, item.montoOriginal,
            item.monedaOriginal, item.montoLocal, item.fecha.toString()
          ]);
        }
      } else if (dataType == 'shipping' && items.isNotEmpty) {
        // Cabeceras para Cotizaciones de Envío
        rows.add(["ID", "Origen", "Destino", "Peso (kg)", "Total", "Moneda", "Fecha"]);
        for (var item in items) {
          rows.add([
            item.id, item.origen, item.destino, item.peso,
            item.total, item.moneda, item.fecha.toString()
          ]);
        }
      } else {
        return; // No hay datos para exportar
      }

      final String csvData = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      
      final String dateStr = DateFormat('yyyyMMdd_HHmm').format(DateTime.now());
      final File file = File('${directory.path}/${dataType}_export_$dateStr.csv');
      
      await file.writeAsString(csvData);

      await Share.shareXFiles([XFile(file.path)], text: 'Exportación de $dataType a Excel');
    } catch (e) {
      throw Exception("Error al exportar a Excel: $e");
    }
  }
}
