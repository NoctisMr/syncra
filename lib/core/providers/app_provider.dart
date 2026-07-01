// lib/core/providers/app_provider.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:palette_generator/palette_generator.dart';
import '../config/app_config.dart';
import '../database/local_storage_service.dart';
import '../services/currency_service.dart';

class AppProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService.instance;
  final CurrencyService _currencyService = CurrencyService.instance;

  ThemeMode _themeMode = ThemeMode.system;
  Color _originalSeedColor = AppConfig.defaultSeedColor;
  Color _seedColor = AppConfig.defaultSeedColor;
  String _language = 'en';
  bool _isLoading = true;
  String? _backgroundImagePath;

  Map<String, double> _tasasCambio = AppConfig.defaultExchangeRates;
  int _ultimaActualizacionEpoch = 0;
  String _monedaLocal = 'USD';

  ThemeMode get themeMode => _themeMode;
  Color get seedColor => _seedColor;
  Color get originalSeedColor => _originalSeedColor;
  String get language => _language;
  bool get isLoading => _isLoading;
  String? get backgroundImagePath => _backgroundImagePath;
  Map<String, double> get tasasCambio => _tasasCambio;
  int get ultimaActualizacionEpoch => _ultimaActualizacionEpoch;
  String get monedaLocal => _monedaLocal;

  AppProvider() {
    initApp();
  }

  Future<void> initApp() async {
    _isLoading = true;
    notifyListeners();

    // Theme Mode
    final String savedTheme = _storage.getSetting('themeMode', defaultValue: 'system');
    if (savedTheme == 'dark') _themeMode = ThemeMode.dark;
    else if (savedTheme == 'light') _themeMode = ThemeMode.light;
    else _themeMode = ThemeMode.system;

    // Base Color
    final int savedColorValue = _storage.getSetting('seedColor', defaultValue: AppConfig.defaultSeedColor.value);
    _originalSeedColor = Color(savedColorValue);
    _seedColor = _originalSeedColor;

    // Language Detection
    final String? savedLang = _storage.getSetting('language');
    if (savedLang != null) {
      _language = savedLang;
    } else {
      String deviceLang = WidgetsBinding.instance.platformDispatcher.locale.languageCode;
      _language = ['es', 'en', 'pt'].contains(deviceLang) ? deviceLang : 'en';
      _storage.saveSetting('language', _language);
    }

    // Background Image & Palette
    _backgroundImagePath = _storage.getSetting('backgroundImagePath');
    if (_backgroundImagePath != null && File(_backgroundImagePath!).existsSync()) {
      await _updatePaletteFromImage(_backgroundImagePath!);
    } else {
      _backgroundImagePath = null;
    }

    // Exchange Rates
    final Map? savedRates = _storage.getData('tasasCambio');
    if (savedRates != null) {
      _tasasCambio = savedRates.map((key, value) => MapEntry(key.toString(), double.parse(value.toString())));
    }
    _ultimaActualizacionEpoch = _storage.getData('ultimaActualizacion', defaultValue: 0);
    _monedaLocal = _storage.getSetting('monedaLocal', defaultValue: 'USD');

    // Geo-IP Currency Detection
    if (_storage.getSetting('monedaLocal') == null) {
      await _detectarMonedaPorIP();
    }

    await actualizarTasasDesdeInternet();

    _isLoading = false;
    notifyListeners();
  }

  void updateThemeMode(String mode) {
    if (mode == 'dark') _themeMode = ThemeMode.dark;
    else if (mode == 'light') _themeMode = ThemeMode.light;
    else _themeMode = ThemeMode.system;
    
    _storage.saveSetting('themeMode', mode);
    notifyListeners();
  }

  void updateSeedColor(Color newColor) {
    _originalSeedColor = newColor;
    _seedColor = newColor; 
    _storage.saveSetting('seedColor', newColor.value);
    
    if (_backgroundImagePath != null) {
      _updatePaletteFromImage(_backgroundImagePath!);
    } else {
      notifyListeners();
    }
  }

  void updateLanguage(String langCode) {
    _language = langCode;
    _storage.saveSetting('language', langCode);
    notifyListeners();
  }

  Future<void> setBackgroundImage(String? path) async {
    _backgroundImagePath = path;
    if (path == null) {
      _storage.saveSetting('backgroundImagePath', null);
      _seedColor = _originalSeedColor;
      notifyListeners();
    } else {
      _storage.saveSetting('backgroundImagePath', path);
      await _updatePaletteFromImage(path);
    }
  }

  Future<void> _updatePaletteFromImage(String path) async {
    try {
      final PaletteGenerator palette = await PaletteGenerator.fromImageProvider(FileImage(File(path)));
      if (palette.dominantColor != null) {
        _seedColor = Color.lerp(_originalSeedColor, palette.dominantColor!.color, 0.3) ?? _originalSeedColor;
      }
    } catch (e) {
      debugPrint("Palette extraction error: $e");
    }
    notifyListeners();
  }

  void updateMonedaLocal(String currencyCode) {
    if (_tasasCambio.containsKey(currencyCode)) {
      _monedaLocal = currencyCode;
      _storage.saveSetting('monedaLocal', currencyCode);
      notifyListeners();
    }
  }

  Future<void> actualizarTasasDesdeInternet() async {
    final Map<String, dynamic>? nuevasTasas = await _currencyService.fetchExchangeRates();
    if (nuevasTasas != null) {
      _tasasCambio = nuevasTasas.map((key, value) => MapEntry(key, double.parse(value.toString())));
      _ultimaActualizacionEpoch = DateTime.now().millisecondsSinceEpoch;
      
      await _storage.saveData('tasasCambio', _tasasCambio);
      await _storage.saveData('ultimaActualizacion', _ultimaActualizacionEpoch);
      notifyListeners();
    }
  }

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
