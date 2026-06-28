// Archivo: lib/features/shipping/presentation/providers/shipping_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../data/models/quote_model.dart'; // Asumiendo que el modelo está en esta ruta

class ShippingProvider extends ChangeNotifier {
  final TextEditingController precioEnvioCtrl = TextEditingController();
  final TextEditingController pesoEnvioCtrl = TextEditingController();
  final TextEditingController proxyCostoCtrl = TextEditingController();

  String origenEnvio = 'USD';
  String destinoEnvio = 'BRL';
  String monedaDestinoEnvio = 'BRL';

  // 🌟 NUEVO: Control flexible de tipo de tarifa del Proxy
  bool esProxyPorcentaje = false; 

  double valorArticuloUsd = 0.0;
  double fleteUsd = 0.0;
  double proxyUsd = 0.0;
  double impuestoUsd = 0.0;
  double totalEnvio = 0.0;

  List<QuoteModel> cotizaciones = [];

  ShippingProvider() {
    _loadCotizaciones();
    origenEnvio = LocalStorageService.instance.getSetting('origenEnvio', defaultValue: 'USD');
    destinoEnvio = LocalStorageService.instance.getSetting('destinoEnvio', defaultValue: 'BRL');
    monedaDestinoEnvio = LocalStorageService.instance.getSetting('monedaDestinoEnvio', defaultValue: 'BRL');
    // Cargar preferencia del tipo de proxy
    esProxyPorcentaje = LocalStorageService.instance.getSetting('esProxyPorcentaje', defaultValue: false);
  }

  void setRuta(String origen, String destino, String moneda) {
    origenEnvio = origen;
    destinoEnvio = destino;
    monedaDestinoEnvio = moneda;
    
    LocalStorageService.instance.saveSetting('origenEnvio', origen);
    LocalStorageService.instance.saveSetting('destinoEnvio', destino);
    LocalStorageService.instance.saveSetting('monedaDestinoEnvio', moneda);
    
    calcularEnvio();
  }

  void toggleProxyType() {
    esProxyPorcentaje = !esProxyPorcentaje;
    LocalStorageService.instance.saveSetting('esProxyPorcentaje', esProxyPorcentaje);
    calcularEnvio();
  }

  void calcularEnvio() {
    double precio = double.tryParse(precioEnvioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    double peso = double.tryParse(pesoEnvioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    double proxyInput = double.tryParse(proxyCostoCtrl.text.replaceAll(',', '.')) ?? 0.0;

    Map<dynamic, dynamic>? rates = LocalStorageService.instance.getData('tasasCambio');
    double rateOrigen = (rates?[origenEnvio] ?? 1.0).toDouble();
    double rateDestino = (rates?[destinoEnvio] ?? 1.0).toDouble();
    double rateUsd = (rates?['USD'] ?? 1.0).toDouble();
    
    // 1. Artículo a USD
    valorArticuloUsd = (precio / rateOrigen) * rateUsd;
    
    // 2. Flete Base (Ej: $5 por Kg)
    fleteUsd = peso * 5.0; 
    
    // 3. 🌟 Casillero / Proxy Flexible
    if (esProxyPorcentaje) {
      proxyUsd = valorArticuloUsd * (proxyInput / 100);
    } else {
      proxyUsd = proxyInput; // Valor fijo
    }

    // 4. Aranceles (Ejemplo Brasil, ajustable según config)
    if (valorArticuloUsd > 50 && destinoEnvio == 'BRL') {
      impuestoUsd = valorArticuloUsd * 0.60;
    } else {
      impuestoUsd = 0.0;
    }

    // 5. Total
    double totalDolares = valorArticuloUsd + fleteUsd + proxyUsd + impuestoUsd;
    totalEnvio = (totalDolares / rateUsd) * rateDestino;

    notifyListeners();
  }

  // ... (Los métodos guardarCotizacion, eliminarCotizacion y load/save se mantienen iguales)
}
