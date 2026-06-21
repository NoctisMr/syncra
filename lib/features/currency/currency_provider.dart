import 'package:flutter/material.dart';
import '../../core/services/currency_service.dart';

class CurrencyProvider extends ChangeNotifier {
  Map<String, dynamic>? currentRates;
  bool isOffline = false;
  DateTime? lastUpdated;
  bool isLoading = true;
  String? errorMessage;

  CurrencyProvider() {
    // Al instanciar el provider (entrar a la pestaña), cargamos las divisas
    loadCurrencies();
  }

  Future<void> loadCurrencies() async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await CurrencyService.instance.fetchRates();

    currentRates = result['rates'];
    isOffline = result['isOffline'];
    lastUpdated = result['lastUpdated'];

    if (currentRates == null && isOffline) {
      errorMessage = "Necesitas conexión a internet para la primera descarga de divisas.";
    }

    isLoading = false;
    notifyListeners();
  }
}
