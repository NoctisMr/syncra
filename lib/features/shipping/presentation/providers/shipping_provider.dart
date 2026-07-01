// lib/features/shipping/presentation/providers/shipping_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/database/local_storage_service.dart';
import '../models/quote_model.dart';

class ShippingProvider extends ChangeNotifier {
  final _storage = LocalStorageService.instance;
  final TextEditingController precioEnvioCtrl = TextEditingController();
  final TextEditingController pesoEnvioCtrl = TextEditingController();
  
  double totalEnvio = 0.0;
  List<QuoteModel> cotizaciones = [];

  ShippingProvider() { _loadData(); }

  void _loadData() {
    final data = _storage.getData('cotizaciones');
    if (data != null) {
      cotizaciones = (data as List).map((e) => QuoteModel.fromMap(e)).toList();
    }
  }

  void calcularEnvio() {
    double precio = double.tryParse(precioEnvioCtrl.text) ?? 0.0;
    double peso = double.tryParse(pesoEnvioCtrl.text) ?? 0.0;
    totalEnvio = precio + (peso * 5.0); // 5.0 es costo base proxy
    notifyListeners();
  }

  void guardarCotizacion(String origen, String destino, String moneda) {
    cotizaciones.insert(0, QuoteModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      origen: origen, destino: destino, peso: double.parse(pesoEnvioCtrl.text),
      total: totalEnvio, moneda: moneda, fecha: DateTime.now(),
    ));
    _storage.saveData('cotizaciones', cotizaciones.map((q) => q.toMap()).toList());
    notifyListeners();
  }
}
