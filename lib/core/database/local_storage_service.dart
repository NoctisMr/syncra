// Archivo: lib/core/database/local_storage_service.dart
import 'package:hive_flutter/hive_flutter.dart';

class LocalStorageService {
  // Patrón Singleton para mantener una única instancia en toda la app
  LocalStorageService._privateConstructor();
  static final LocalStorageService instance = LocalStorageService._privateConstructor();

  late Box _dataBox;
  late Box _settingsBox;

  final String _dataBoxName = 'global_data';
  final String _settingsBoxName = 'global_settings';

  // Inicializador necesario para el arranque de la aplicación
  Future<void> init() async {
    await Hive.initFlutter();
    _dataBox = await Hive.openBox(_dataBoxName);
    _settingsBox = await Hive.openBox(_settingsBoxName);
  }

  // =========================================================================
  // MÉTODOS PARA DATOS GENERALES (Presupuesto, Envíos, etc.)
  // =========================================================================
  dynamic getData(String key, {dynamic defaultValue}) {
    return _dataBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveData(String key, dynamic value) async {
    await _dataBox.put(key, value);
  }

  // =========================================================================
  // MÉTODOS PARA AJUSTES DE LA APLICACIÓN (Tema, Idioma, Moneda base)
  // =========================================================================
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }
}
