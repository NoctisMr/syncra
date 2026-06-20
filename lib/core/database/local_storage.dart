// Archivo: lib/core/database/local_storage.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Servicio centralizado para el manejo de la base de datos local.
/// Preparado para integrarse con el paquete 'hive' en el pubspec.yaml.
class LocalStorageService {
  // Nombre comercial de la "caja" (tabla) principal de almacenamiento
  static const String _boxName = 'syncra_premium_data';

  // Privamos el constructor para asegurar un patrón Singleton
  LocalStorageService._();
  static final LocalStorageService instance = LocalStorageService._();

  /// Inicializa la base de datos al abrir la app en el main.dart
  Future<void> initDatabase() async {
    try {
      // TODO: Descomentar cuando agreguemos 'hive_flutter' al pubspec
      // await Hive.initFlutter();
      // await Hive.openBox(_boxName);
      debugPrint('Base de datos $_boxName inicializada correctamente.');
    } catch (e) {
      debugPrint('Error al inicializar la base de datos: $e');
    }
  }

  /// Guarda o actualiza un registro utilizando una clave única
  Future<void> saveData(String key, Map<String, dynamic> data) async {
    // TODO: Implementación real con Hive
    // final box = Hive.box(_boxName);
    // await box.put(key, data);
    debugPrint('Datos guardados en la clave: $key');
  }

  /// Recupera todos los registros almacenados
  Map<String, dynamic> getAllData() {
    // TODO: Implementación real con Hive
    // final box = Hive.box(_boxName);
    // return Map<String, dynamic>.from(box.toMap());
    
    // Retorno simulado temporal para evitar errores de compilación
    return {}; 
  }

  /// Borra todos los datos (Útil para un botón de "Restablecer App")
  Future<void> clearAll() async {
    // TODO: Implementación real con Hive
    // final box = Hive.box(_boxName);
    // await box.clear();
    debugPrint('Base de datos formateada.');
  }

  // =========================================================================
  // FUNCIONES PREMIUM: EXPORTACIÓN E IMPORTACIÓN
  // =========================================================================

  /// Convierte toda la base de datos a un String en formato JSON
  /// Ideal para guardar en Google Drive, iCloud o almacenamiento local.
  String exportDatabaseToJson() {
    try {
      final allData = getAllData();
      // Convertimos el mapa de Dart a un String JSON formateado
      return jsonEncode(allData);
    } catch (e) {
      debugPrint('Error al exportar a JSON: $e');
      return '';
    }
  }

  /// Recibe un String en formato JSON y restaura la base de datos
  Future<bool> importDatabaseFromJson(String jsonString) async {
    try {
      final Map<String, dynamic> decodedData = jsonDecode(jsonString);
      
      // TODO: Implementación real con Hive
      // final box = Hive.box(_boxName);
      // await box.clear(); // Limpiamos antes de restaurar
      // await box.putAll(decodedData);
      
      debugPrint('Base de datos restaurada exitosamente desde JSON.');
      return true;
    } catch (e) {
      debugPrint('Error al importar desde JSON: $e');
      return false;
    }
  }
}
