import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class CurrencyService {
  // Patrón Singleton para acceso global optimizado
  static final CurrencyService instance = CurrencyService._internal();
  CurrencyService._internal();

  // TODO: Reemplaza con el endpoint de tu API preferida (ej. ExchangeRate-API)
  final String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD'; 
  final String _cacheKey = 'cached_currency_rates';
  final String _dateKey = 'last_updated_date';

  /// Retorna un mapa con las tasas, el estado de red y la fecha de actualización
  Future<Map<String, dynamic>> fetchRates() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Verificamos el estado de la conexión a internet
    final connectivityResults = await Connectivity().checkConnectivity();
    final isDisconnected = connectivityResults.contains(ConnectivityResult.none);

    if (isDisconnected) {
      return _getOfflineData(prefs);
    }

    try {
      // Intento de conexión al servidor
      final response = await http.get(Uri.parse(_apiUrl)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final now = DateTime.now();

        // Guardamos en caché para futuros usos offline
        await prefs.setString(_cacheKey, json.encode(data['rates']));
        await prefs.setString(_dateKey, now.toIso8601String());

        return {
          'rates': data['rates'],
          'isOffline': false,
          'lastUpdated': now,
        };
      } else {
        // Si el servidor falla, mostramos los datos guardados
        return _getOfflineData(prefs); 
      }
    } catch (e) {
      // Si hay un timeout o error de red inesperado
      return _getOfflineData(prefs); 
    }
  }

  Map<String, dynamic> _getOfflineData(SharedPreferences prefs) {
    final cachedRates = prefs.getString(_cacheKey);
    final lastUpdatedStr = prefs.getString(_dateKey);

    if (cachedRates != null && lastUpdatedStr != null) {
      return {
        'rates': json.decode(cachedRates),
        'isOffline': true,
        'lastUpdated': DateTime.parse(lastUpdatedStr),
      };
    }
    
    // Caso crítico: Primera vez abriendo la app, sin internet y sin caché
    return {
      'rates': null, 
      'isOffline': true, 
      'lastUpdated': null
    };
  }
}
