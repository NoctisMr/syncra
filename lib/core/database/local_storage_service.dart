// Archivo: lib/core/database/local_storage_service.dart
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Servicio centralizado para el manejo de persistencia local con Hive.
/// Proteje la aplicación aislando el almacenamiento físico de la lógica de negocio.
class LocalStorageService {
  static const String _dataBoxName = 'dataBox';
  static const String _settingsBoxName = 'settingsBox';

  // Constructor privado para asegurar el patrón Singleton
  LocalStorageService._privateConstructor();
  static final LocalStorageService instance = LocalStorageService._privateConstructor();

  late Box _dataBox;
  late Box _settingsBox;

  /// Inicializa Hive y abre las cajas necesarias de forma segura.
  /// Se llamará una sola vez en el arranque de la app (main.dart).
  Future<void> initDatabase() async {
    try {
      await Hive.initFlutter();
      _dataBox = await Hive.openBox(_dataBoxName);
      _settingsBox = await Hive.openBox(_settingsBoxName);
      debugPrint('📦 Base de datos local (Hive) inicializada correctamente.');
    } catch (e) {
      debugPrint('❌ Error crítico al inicializar Hive: $e');
    }
  }

  // =========================================================================
  // GESTIÓN DE DATOS GENERALES (Gastos, Bóvedas, Cotizaciones, Tasas)
  // =========================================================================

  /// Recupera un valor de la caja de datos generales utilizando una clave.
  dynamic getData(String key, {dynamic defaultValue}) {
    return _dataBox.get(key, defaultValue: defaultValue);
  }

  /// Guarda o actualiza un registro en la caja de datos generales.
  Future<void> saveData(String key, dynamic value) async {
    await _dataBox.put(key, value);
  }

  // =========================================================================
  // GESTIÓN DE AJUSTES (Idioma, Modo Oscuro, Color de Semilla)
  // =========================================================================

  /// Recupera una configuración de la caja de ajustes.
  dynamic getSetting(String key, {dynamic defaultValue}) {
    return _settingsBox.get(key, defaultValue: defaultValue);
  }

  /// Guarda o actualiza una configuración de la aplicación.
  Future<void> saveSetting(String key, dynamic value) async {
    await _settingsBox.put(key, value);
  }

  // =========================================================================
  // FUNCIONES DE MANTENIMIENTO
  // =========================================================================

  /// Borra por completo el contenido de ambas cajas.
  /// Ideal para implementar un botón de "Restablecer App de Fábrica".
  Future<void> clearAllData() async {
    await _dataBox.clear();
    await _settingsBox.clear();
    debugPrint('🧹 Base de datos local completamente formateada.');
  }
}
