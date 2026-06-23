// Archivo: lib/core/config/app_config.dart
import 'package:flutter/material.dart';

/// Archivo central de configuración (Marca Blanca)
/// Los compradores de CodeCanyon pueden modificar estos valores para adaptar
/// la aplicación a su propia marca sin tocar la lógica compleja.
class AppConfig {
  // --- INFORMACIÓN DE LA APP ---
  static const String appName = "Syncra Premium";
  static const String appVersion = "2.0.0";
  
  // --- BRANDING (COLORES) ---
  // Color principal por defecto de la aplicación
  static const Color defaultSeedColor = Color(0xFF29B6F6); 
  
  // Lista de colores disponibles para que el usuario elija en los ajustes
  static const List<Color> themeColors = [
    Color(0xFF29B6F6), // Azul Claro (Por defecto)
    Color(0xFF81C784), // Verde
    Color(0xFFBA68C8), // Púrpura
    Color(0xFFFF8A65), // Naranja
    Color(0xFFF06292), // Rosa
    Color(0xFF90A4AE), // Gris Azulado
  ];

  // --- VALORES POR DEFECTO (OFFLINE/PRIMER INICIO) ---
  // Tasas de cambio base para evitar pantallas de error sin internet
  static const Map<String, double> defaultExchangeRates = {
    'USD': 1.0, 
    'BRL': 5.0, 
    'PEN': 3.7, 
    'EUR': 0.92, 
    'VES': 36.5, 
    'MXN': 17.5, 
    'JPY': 155.0
  };

  // --- CONFIGURACIONES DE ADUANAS Y ENVÍOS ---
  // Estos valores rellenarán los campos de texto al abrir la app
  static const double defaultProxyCost = 5.0; // Costo base en USD por kg
  static const double defaultSpreadPercent = 3.0; // Comisión bancaria estándar

  // --- REGLAS DE IMPUESTOS POR PAÍS ---
  static const Map<String, Map<String, dynamic>> taxRules = {
    'Brasil': { 'limit': 50.0, 'under_limit_tax': 0.20, 'over_limit_tax': 0.60, 'state_tax_icms': 0.17 },
    'Perú': { 'limit': 200.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.22, 'state_tax_icms': 0.0 },
    'México': { 'limit': 50.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.19, 'state_tax_icms': 0.0 },
    'EE.UU.': { 'limit': 800.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.10, 'state_tax_icms': 0.0 },
    'Europa': { 'limit': 150.0, 'under_limit_tax': 0.21, 'over_limit_tax': 0.235, 'state_tax_icms': 0.0 },
    'Japón': { 'limit': 0.0, 'under_limit_tax': 0.10, 'over_limit_tax': 0.10, 'state_tax_icms': 0.0 },
    'Venezuela': { 'limit': 0.0, 'under_limit_tax': 0.30, 'over_limit_tax': 0.30, 'state_tax_icms': 0.0 },
  };
}
