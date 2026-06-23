// Archivo: lib/core/providers/app_provider.dart
import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../database/local_storage_service.dart';
import '../services/currency_service.dart';

/// Gestor de Estado Global para la configuración y ciclo de vida de la aplicación.
/// Maneja preferencias de usuario (Tema, Idioma) y datos globales compartidos (Tasas).
class AppProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  // --- ESTADOS DE CONFIGURACIÓN ---
  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = AppConfig.defaultSeedColor;
  String _language = 'es';
  bool _isLoading = true;

  // --- ESTADOS DE DIVISAS ---
  Map<String, double> _tasasCambio = AppConfig.defaultExchangeRates;
  int _ultimaActualizacionEpoch = 0;
  String _monedaLocal = 'USD';

  // --- GETTERS PÚBLICOS ---
  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  String get language => _language;
  bool get isLoading => _isLoading;
  Map<String, double> get tasasCambio => _tasasCambio;
  int get ultimaActualizacionEpoch => _ultimaActualizacionEpoch;
  String get monedaLocal => _monedaLocal;

  /// Inicializa la app cargando configuraciones persistidas y actualizando divisas.
  Future<void> initApp() async {
    _isLoading = true;
    notifyListeners();

    // 1. Cargar preferencias visuales guardadas
    final String savedTheme = _storage.getSetting('themeMode', defaultValue: 'light');
    _themeMode = savedTheme == 'dark' ? ThemeMode.dark : ThemeMode.light;

    final int savedColorValue = _storage.getSetting('seedColor', defaultValue: AppConfig.defaultSeedColor.value);
    _seedColor = Color(savedColorValue);

    _language = _storage.getSetting('language', defaultValue: 'es');

    // 2. Cargar tasas de cambio locales previas
    final Map? savedRates = _storage.getData('tasasCambio');
    if (savedRates != null) {
      _tasasCambio = savedRates.map((key, value) => MapEntry(key.toString(), double.parse(value.toString())));
    }
    _ultimaActualizacionEpoch = _storage.getData('ultimaActualizacion', defaultValue: 0);
    _monedaLocal = _storage.getSetting('monedaLocal', defaultValue: 'USD');

    // 3. Intentar detectar ubicación automática si es la primera vez
    if (_storage.getSetting('monedaLocal') == null) {
      await _detectarMonedaPorIP();
    }

    // 4. Actualizar tasas de cambio desde internet en segundo plano de forma silenciosa
    await actualizarTasasDesdeInternet();

    _isLoading = false;
    notifyListeners();
  }

  // --- MÉTODOS DE ACCIÓN (MUTADORES DE ESTADO) ---

  /// Alterna entre modo claro y modo oscuro, guardando la elección inmediatamente.
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    _storage.saveSetting('themeMode', isDark ? 'dark' : 'light');
    notifyListeners();
  }

  /// Cambia el color semilla del diseño dinámico Material 3.
  void updateSeedColor(Color newColor) {
    _seedColor = newColor;
    _storage.saveSetting('seedColor', newColor.value);
    notifyListeners();
  }

  /// Cambia el idioma de la interfaz.
  void updateLanguage(String langCode) {
    _language = langCode;
    _storage.saveSetting('language', langCode);
    notifyListeners();
  }

  /// Cambia manualmente la divisa local asignada por el usuario.
  void updateMonedaLocal(String currencyCode) {
    if (_tasasCambio.containsKey(currencyCode)) {
      _monedaLocal = currencyCode;
      _storage.saveSetting('monedaLocal', currencyCode);
      notifyListeners();
    }
  }

  // --- MÉTODOS PRIVADOS Y DE RED ---

  /// Llama al servicio de red para descargar tasas actualizadas
  Future<void> actualizarTasasDesdeInternet() async {
    final Map<String, dynamic>? nuevasTasas = await _currencyService.fetchExchangeRates();
    if (nuevasTasas != null) {
      _tasasCambio = nuevasTasas.map((key, value) => MapEntry(key, double.parse(value.toString())));
      _ultimaActualizacionEpoch = DateTime.now().millisecondsSinceEpoch;
      
      // Persistir datos para arranques offline futuros
      await _storage.saveData('tasasCambio', _tasasCambio);
      await _storage.saveData('ultimaActualizacion', _ultimaActualizacionEpoch);
    }
  }

  /// Intenta geolocalizar al usuario de manera inteligente para preconfigurar su moneda nativa.
  Future<void> _detectarMonedaPorIP() async {
    final locationData = await _currencyService.fetchLocationData();
    if (locationData != null && locationData['currency'] != null) {
      final String detectada = locationData['currency'].toString();
      if (_tasasCambio.containsKey(detectada)) {
        _monedaLocal = detectada;
        await _storage.saveSetting('monedaLocal', _monedaLocal);
      }
    }
  }
}
