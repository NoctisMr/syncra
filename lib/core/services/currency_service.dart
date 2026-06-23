// Archivo: lib/core/services/currency_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Servicio centralizado para la comunicación con APIs externas.
/// Maneja la obtención de tasas de cambio y la geolocalización por IP.
class CurrencyService {
  // Endpoints públicos y gratuitos (Ideales para plantillas sin API Keys complejas)
  static const String _ipApiUrl = 'https://ipapi.co/json/';
  static const String _erApiUrl = 'https://open.er-api.com/v6/latest/USD';
  
  // Headers estándar para evitar bloqueos por parte de servidores públicos
  static const Map<String, String> _headers = {
    'User-Agent': 'Mozilla/5.0',
    'Accept': 'application/json'
  };

  // Patrón Singleton: Una única instancia del servicio en toda la app
  CurrencyService._privateConstructor();
  static final CurrencyService instance = CurrencyService._privateConstructor();

  /// Obtiene los datos de ubicación del usuario basados en su IP pública.
  /// Retorna un mapa con el 'country_code' y la 'currency', o null si falla la red.
  Future<Map<String, dynamic>?> fetchLocationData() async {
    try {
      // Timeout de 5 segundos para no colgar la UI si el internet es lento
      final response = await http
          .get(Uri.parse(_ipApiUrl), headers: _headers)
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        debugPrint('⚠️ Error API Ubicación: Código HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('📶 Sin conexión o timeout en API Ubicación: $e');
    }
    return null;
  }

  /// Obtiene las tasas de cambio globales actualizadas con base en el USD.
  /// Retorna un mapa con las divisas, o null si el dispositivo está offline.
  Future<Map<String, dynamic>?> fetchExchangeRates() async {
    try {
      final response = await http
          .get(Uri.parse(_erApiUrl), headers: _headers)
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['rates'] as Map<String, dynamic>;
      } else {
        debugPrint('⚠️ Error API Divisas: Código HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('📶 Sin conexión o timeout en API Divisas: $e');
    }
    return null;
  }
}
