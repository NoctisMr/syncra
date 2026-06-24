// Archivo: lib/features/shipping/presentation/providers/shipping_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/database/local_storage_service.dart';

// Modelo incrustado para evitar errores de rutas perdidas en compilación
class QuoteModel {
  final String id;
  final String origen;
  final String destino;
  final double peso;
  final DateTime fecha;
  final double total;
  final String moneda;

  QuoteModel({
    required this.id, required this.origen, required this.destino,
    required this.peso, required this.fecha, required this.total, required this.moneda,
  });

  Map<String, dynamic> toMap() => {
    'id': id, 'origen': origen, 'destino': destino, 'peso': peso,
    'fecha': fecha.millisecondsSinceEpoch, 'total': total, 'moneda': moneda,
  };

  factory QuoteModel.fromMap(Map<dynamic, dynamic> map) => QuoteModel(
    id: map['id'], origen: map['origen'], destino: map['destino'],
    peso: map['peso'], fecha: DateTime.fromMillisecondsSinceEpoch(map['fecha']),
    total: map['total'], moneda: map['moneda'],
  );
}

class ShippingProvider extends ChangeNotifier {
  // Inicializamos los controladores VACÍOS. (Soluciona el problema de borrar ceros manualmente).
  final TextEditingController precioEnvioCtrl = TextEditingController();
  final TextEditingController pesoEnvioCtrl = TextEditingController();
  final TextEditingController proxyCostoCtrl = TextEditingController();

  String origenEnvio = 'USD';
  String destinoEnvio = 'BRL';
  String monedaDestinoEnvio = 'BRL';

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

  void calcularEnvio() {
    // Si el usuario no escribe nada, asumimos de forma invisible que es 0
    double precio = double.tryParse(precioEnvioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    double peso = double.tryParse(pesoEnvioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    double proxy = double.tryParse(proxyCostoCtrl.text.replaceAll(',', '.')) ?? 0.0;

    Map<dynamic, dynamic>? rates = LocalStorageService.instance.getData('tasasCambio');
    double rateOrigen = (rates?[origenEnvio] ?? 1.0).toDouble();
    double rateDestino = (rates?[destinoEnvio] ?? 1.0).toDouble();
    double rateUsd = (rates?['USD'] ?? 1.0).toDouble();
    
    // 1. Artículo a USD
    valorArticuloUsd = (precio / rateOrigen) * rateUsd;
    
    // 2. Flete Base (Ejemplo logístico: $5 por cada Kg)
    fleteUsd = peso * 5.0; 
    
    // 3. Casillero / Proxy
    proxyUsd = proxy;

    // 4. Aranceles (Ejemplo: Destino BRL cobra 60% sobre artículos mayores a $50 USD)
    if (valorArticuloUsd > 50 && destinoEnvio == 'BRL') {
      impuestoUsd = valorArticuloUsd * 0.60;
    } else {
      impuestoUsd = 0.0;
    }

    // 5. Consolidación Final
    double totalDolares = valorArticuloUsd + fleteUsd + proxyUsd + impuestoUsd;
    totalEnvio = (totalDolares / rateUsd) * rateDestino;

    notifyListeners();
  }

  void guardarCotizacion() {
    if (totalEnvio <= 0) return;

    double peso = double.tryParse(pesoEnvioCtrl.text.replaceAll(',', '.')) ?? 0.0;
    
    final quote = QuoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      origen: origenEnvio,
      destino: destinoEnvio,
      peso: peso,
      fecha: DateTime.now(),
      total: totalEnvio,
      moneda: monedaDestinoEnvio,
    );

    cotizaciones.insert(0, quote);
    _saveCotizaciones();
    
    precioEnvioCtrl.clear();
    pesoEnvioCtrl.clear();
    proxyCostoCtrl.clear();
    calcularEnvio();
  }

  void eliminarCotizacion(String id) {
    cotizaciones.removeWhere((q) => q.id == id);
    _saveCotizaciones();
  }

  void _loadCotizaciones() {
    List? data = LocalStorageService.instance.getData('cotizaciones_v2');
    if (data != null) {
      cotizaciones = data.map((e) => QuoteModel.fromMap(Map<String, dynamic>.from(e))).toList();
      notifyListeners();
    }
  }

  void _saveCotizaciones() {
    LocalStorageService.instance.saveData('cotizaciones_v2', cotizaciones.map((e) => e.toMap()).toList());
    notifyListeners();
  }
}
