// Archivo: lib/features/shipping/presentation/providers/shipping_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../../core/config/app_config.dart';
import '../../data/models/quote_model.dart';

/// Gestor de estado específico para el módulo de Aduanas y Envíos.
/// Centraliza la matemática logística, tarifas por peso, impuestos según país
/// destino y almacenamiento histórico de cotizaciones.
class ShippingProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService.instance;

  // --- CONTROLADORES DE INTERFAZ ---
  final TextEditingController precioEnvioCtrl = TextEditingController();
  final TextEditingController pesoEnvioCtrl = TextEditingController();
  final TextEditingController proxyCostoCtrl = TextEditingController(text: "5.0");

  // --- ESTADO DE DATOS ---
  String _origenEnvio = 'USD';
  String _destinoEnvio = 'BRL';
  String _monedaDestinoEnvio = 'BRL';
  
  double _valorArticuloUsd = 0.0;
  double _fleteUsd = 0.0;
  double _proxyUsd = 0.0;
  double _impuestoUsd = 0.0;
  double _totalEnvio = 0.0;

  List<QuoteModel> _cotizaciones = [];

  // --- GETTERS PÚBLICOS ---
  String get origenEnvio => _origenEnvio;
  String get destinoEnvio => _destinoEnvio;
  String get monedaDestinoEnvio => _monedaDestinoEnvio;
  double get valorArticuloUsd => _valorArticuloUsd;
  double get fleteUsd => _fleteUsd;
  double get proxyUsd => _proxyUsd;
  double get impuestoUsd => _impuestoUsd;
  double get totalEnvio => _totalEnvio;
  List<QuoteModel> get cotizaciones => _cotizaciones;

  ShippingProvider() {
    _loadData();
  }

  // =========================================================================
  // CARGA Y GUARDADO DE DATOS
  // =========================================================================

  void _loadData() {
    _origenEnvio = _storage.getData('origenEnvio', defaultValue: 'USD');
    _destinoEnvio = _storage.getData('destinoEnvio', defaultValue: 'BRL');
    _monedaDestinoEnvio = _storage.getData('monedaDestinoEnvio', defaultValue: 'BRL');
    
    final List? quotesData = _storage.getData('cotizaciones_v2');
    if (quotesData != null) {
      _cotizaciones = quotesData.map((e) => QuoteModel.fromMap(e)).toList();
    }
  }

  void _saveData() {
    _storage.saveData('origenEnvio', _origenEnvio);
    _storage.saveData('destinoEnvio', _destinoEnvio);
    _storage.saveData('monedaDestinoEnvio', _monedaDestinoEnvio);
    _storage.saveData('cotizaciones_v2', _cotizaciones.map((e) => e.toMap()).toList());
    notifyListeners();
  }

  // =========================================================================
  // MATEMÁTICA LOGÍSTICA Y REGLAS ADUANERAS
  // =========================================================================

  void setRuta(String origen, String destino, String monedaDestino) {
    _origenEnvio = origen;
    _destinoEnvio = destino;
    _monedaDestinoEnvio = monedaDestino;
    calcularEnvio();
  }

  /// Ejecuta el cálculo en cadena de la cotización internacional.
  /// Transforma monedas extranjeras a USD base, calcula fletes y aplica leyes aduaneras locales.
  void calcularEnvio() {
    double precioRaw = double.tryParse(precioEnvioCtrl.text.trim()) ?? 0.0;
    double pesoRaw = double.tryParse(pesoEnvioCtrl.text.trim()) ?? 0.0;
    double proxyRaw = double.tryParse(proxyCostoCtrl.text.trim()) ?? 0.0;

    // Obtener las tasas de cambio de internet guardadas de forma global
    final Map<dynamic, dynamic> tasasRaw = _storage.getData('tasasCambio', defaultValue: AppConfig.defaultExchangeRates);
    final Map<String, double> tasas = tasasRaw.map((key, value) => MapEntry(key.toString(), double.parse(value.toString())));

    // 1. Convertir el precio del artículo desde su moneda de origen a USD base.
    double tasaOrigen = tasas[_origenEnvio] ?? 1.0;
    _valorArticuloUsd = precioRaw / tasaOrigen;

    // 2. Calcular Flete base según origen (Ej: Envíos desde USA son más económicos que desde Europa/Asia)
    double tarifaPorKg = (_origenEnvio == 'USD' || _origenEnvio == 'USA') ? 4.50 : 6.50;
    _fleteUsd = pesoRaw * tarifaPorKg;

    // 3. Asignar costo de intermediación/Casillero (Proxy) expresado en USD
    _proxyUsd = proxyRaw;

    // 4. Aplicar Reglas de Impuestos Aduaneros Automatizados (Fórmula CIF/FOB simplificada)
    double baseImponibleUsd = _valorArticuloUsd + _fleteUsd + _proxyUsd;
    
    if (_destinoEnvio == 'BRL' && baseImponibleUsd > 50.0) {
      _impuestoUsd = baseImponibleUsd * 0.60; // Ley brasileña: 60% de arancel de importación si supera los $50 USD
    } else if (_destinoEnvio == 'PEN' && baseImponibleUsd > 200.0) {
      _impuestoUsd = baseImponibleUsd * 0.22; // Ley peruana: ~22% (Arancel + IGV) si supera los $200 USD
    } else if (_destinoEnvio == 'VES') {
      _impuestoUsd = baseImponibleUsd * 0.15; // Tasa aduanera simplificada fija del 15% para Venezuela
    } else {
      _impuestoUsd = 0.0; // Exento de impuestos por no superar los mínimos legales
    }

    // 5. Totalizar en USD y convertir a la divisa del destino elegida para visualización del usuario
    double totalUsd = baseImponibleUsd + _impuestoUsd;
    double tasaDestino = tasas[_monedaDestinoEnvio] ?? 1.0;
    _totalEnvio = totalUsd * tasaDestino;

    _saveData();
  }

  // =========================================================================
  // GESTIÓN DE COTIZACIONES HISTÓRICAS
  // =========================================================================

  void guardarCotizacion() {
    if (_totalEnvio <= 0) return;

    final nuevaCotizacion = QuoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      origen: _origenEnvio,
      destino: _destinoEnvio,
      peso: double.tryParse(pesoEnvioCtrl.text.trim()) ?? 0.0,
      total: _totalEnvio,
      moneda: _monedaDestinoEnvio,
      fecha: DateTime.now(), // 🌟 Timestamp matemático
    );

    _cotizaciones.insert(0, nuevaCotizacion);
    _saveData();
  }

  void eliminarCotizacion(String id) {
    _cotizaciones.removeWhere((e) => e.id == id);
    _saveData();
  }

  @override
  void dispose() {
    precioEnvioCtrl.dispose();
    pesoEnvioCtrl.dispose();
    proxyCostoCtrl.dispose();
    super.dispose();
  }
}
