import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SyncraProvider extends ChangeNotifier {
  late Box dataBox;
  late Box settingsBox;

  // --- CONFIGURACIÓN DE LA APP ---
  ThemeMode themeMode = ThemeMode.light;
  Color seedColor = const Color(0xFF29B6F6);
  String language = 'es';
  bool isLoading = true;

  // --- TASAS DE CAMBIO ---
  Map<String, double> tasasCambio = {
    'USD': 1.0, 'BRL': 5.0, 'PEN': 3.7, 'EUR': 0.92, 
    'VES': 36.5, 'MXN': 17.5, 'JPY': 155.0
  };
  int ultimaActualizacionEpoch = 0;

  // --- PRESUPUESTO ---
  String monedaLocal = 'USD';
  String monedaRef = 'USD';
  String sueldo = "";
  List<Map<String, dynamic>> gastos = [];
  List<Map<String, dynamic>> bovedas = [];
  double balanceLocal = 0.0;
  double balanceEq = 0.0;

  // --- CONVERSOR Y SPREAD ---
  bool applySpread = false;
  String spreadValue = "3.0";
  String monedaDe = 'USD';
  String monedaA = 'USD';

  // --- ENVÍOS ---
  String proxyCosto = "5.0";
  String monedaProxy = 'USD';
  String origenEnvio = 'Japón';
  String destinoEnvio = 'Brasil';
  String monedaOrigenEnvio = 'USD';
  String monedaDestinoEnvio = 'USD';
  List<Map<String, dynamic>> cotizaciones = [];

  final Map<String, Map<String, dynamic>> taxRules = {
    'Brasil': { 'limit': 50.0, 'under_limit_tax': 0.20, 'over_limit_tax': 0.60, 'state_tax_icms': 0.17 },
    'Perú': { 'limit': 200.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.22, 'state_tax_icms': 0.0 },
    'México': { 'limit': 50.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.19, 'state_tax_icms': 0.0 },
    'EE.UU.': { 'limit': 800.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.10, 'state_tax_icms': 0.0 },
    'Europa': { 'limit': 150.0, 'under_limit_tax': 0.21, 'over_limit_tax': 0.235, 'state_tax_icms': 0.0 },
    'Japón': { 'limit': 0.0, 'under_limit_tax': 0.10, 'over_limit_tax': 0.10, 'state_tax_icms': 0.0 },
    'Venezuela': { 'limit': 0.0, 'under_limit_tax': 0.30, 'over_limit_tax': 0.30, 'state_tax_icms': 0.0 },
  };

  SyncraProvider() {
    _init();
  }

  Future<void> _init() async {
    dataBox = Hive.box('dataBox');
    settingsBox = Hive.box('settingsBox');
    _loadSettings();
    _cargarDatosLocales();
    await sincronizarUbicacionYTasas();
    isLoading = false;
    notifyListeners();
  }

  void _loadSettings() {
    themeMode = (settingsBox.get('isDark', defaultValue: false)) ? ThemeMode.dark : ThemeMode.light;
    seedColor = Color(settingsBox.get('themeColor', defaultValue: 0xFF29B6F6));
    language = settingsBox.get('language', defaultValue: 'es');
  }

  void updateSettings(ThemeMode tm, Color color, String lang) {
    settingsBox.put('isDark', tm == ThemeMode.dark);
    settingsBox.put('themeColor', color.value);
    settingsBox.put('language', lang);
    themeMode = tm;
    seedColor = color;
    language = lang;
    notifyListeners();
  }

  void _cargarDatosLocales() {
    sueldo = dataBox.get('sueldo', defaultValue: "");
    monedaLocal = dataBox.get('monedaLocal', defaultValue: "USD");
    monedaRef = dataBox.get('monedaRef', defaultValue: "USD");
    monedaDe = dataBox.get('monedaDe', defaultValue: "USD");
    monedaA = dataBox.get('monedaA', defaultValue: "USD");
    proxyCosto = dataBox.get('proxyCosto', defaultValue: "5.0");
    monedaProxy = dataBox.get('monedaProxy', defaultValue: "USD");
    destinoEnvio = dataBox.get('destinoEnvio', defaultValue: "Brasil");
    monedaDestinoEnvio = dataBox.get('monedaDestinoEnvio', defaultValue: "USD");
    ultimaActualizacionEpoch = dataBox.get('ultima_actualizacion_epoch', defaultValue: 0);
    applySpread = dataBox.get('apply_spread', defaultValue: false);
    spreadValue = dataBox.get('spread_value', defaultValue: "3.0");

    var gastosV2 = dataBox.get('gastos_v2');
    if (gastosV2 != null) gastos = List<Map<String, dynamic>>.from(gastosV2.map((e) => Map<String, dynamic>.from(e)));

    var bov = dataBox.get('bovedas');
    if (bov != null) bovedas = List<Map<String, dynamic>>.from(bov.map((e) => Map<String, dynamic>.from(e)));

    var cot = dataBox.get('cotizaciones');
    if (cot != null) cotizaciones = List<Map<String, dynamic>>.from(cot.map((e) => Map<String, dynamic>.from(e)));

    Map<dynamic, dynamic>? tasasJson = dataBox.get('tasas_historial');
    if (tasasJson != null) {
      tasasJson.forEach((key, value) {
        if (tasasCambio.containsKey(key.toString())) tasasCambio[key.toString()] = (value as num).toDouble();
      });
    }
    calcularPresupuesto(sueldo);
  }

  Future<void> sincronizarUbicacionYTasas() async {
    final headers = { 'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json' };
    String codigoPais = "";
    String monedaDetectada = "USD";
    String paisDetectado = "Otros";

    try {
      final locResponse = await http.get(Uri.parse('https://ipapi.co/json/'), headers: headers).timeout(const Duration(seconds: 5));
      if (locResponse.statusCode == 200) {
        final locData = jsonDecode(locResponse.body);
        codigoPais = locData['country_code'] ?? '';
        String incomingCurrency = locData['currency'] ?? 'USD';
        if (tasasCambio.containsKey(incomingCurrency)) monedaDetectada = incomingCurrency;

        if (codigoPais == 'BR') paisDetectado = 'Brasil'; else if (codigoPais == 'PE') paisDetectado = 'Perú';
        else if (codigoPais == 'MX') paisDetectado = 'México'; else if (codigoPais == 'US') paisDetectado = 'EE.UU.';
        else if (codigoPais == 'JP') paisDetectado = 'Japón'; else if (codigoPais == 'VE') paisDetectado = 'Venezuela';
        else if (['ES','FR','DE','IT','NL'].contains(codigoPais)) paisDetectado = 'Europa';
      }
    } catch (e) { debugPrint('Geolocalización fallida'); }

    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD'), headers: headers).timeout(const Duration(seconds: 6));
      if (response.statusCode == 200) {
        final rates = jsonDecode(response.body)['rates'] as Map<String, dynamic>;
        for (var m in tasasCambio.keys) {
          if (rates.containsKey(m)) tasasCambio[m] = (rates[m] as num).toDouble();
        }
        ultimaActualizacionEpoch = DateTime.now().millisecondsSinceEpoch;
        dataBox.put('ultima_actualizacion_epoch', ultimaActualizacionEpoch);
        dataBox.put('tasas_historial', tasasCambio);

        String ultimoPais = dataBox.get('ultimo_pais_code', defaultValue: "");
        if (codigoPais.isNotEmpty && codigoPais != ultimoPais) {
          monedaLocal = monedaDetectada;
          monedaDe = monedaDetectada;
          destinoEnvio = paisDetectado;
          monedaDestinoEnvio = monedaDetectada;
          dataBox.put('ultimo_pais_code', codigoPais);
        }
      }
    } catch (e) {
      debugPrint('Tasas offline');
    }
    calcularPresupuesto(sueldo);
  }

  void calcularPresupuesto(String sueldoInput) {
    sueldo = sueldoInput;
    dataBox.put('sueldo', sueldo);
    
    double sueldoNum = double.tryParse(sueldo) ?? 0.0;
    double totalGastosLocales = 0.0;

    for (var item in gastos) {
      double montoOriginal = (item['monto_original'] ?? item['monto'] as num).toDouble();
      String monedaOrig = item['moneda_original'] ?? monedaLocal;
      double valorEnUsd = montoOriginal / (tasasCambio[monedaOrig] ?? 1.0);
      double valorLocalCalculado = valorEnUsd * (tasasCambio[monedaLocal] ?? 1.0);
      item['monto'] = valorLocalCalculado; 
      totalGastosLocales += valorLocalCalculado;
    }

    double totalEnBovedas = bovedas.fold(0.0, (sum, b) => sum + (b['ahorrado_local'] as num).toDouble());
    balanceLocal = sueldoNum - totalGastosLocales - totalEnBovedas;
    double netoUsd = balanceLocal / (tasasCambio[monedaLocal] ?? 1.0);
    balanceEq = netoUsd * (tasasCambio[monedaRef] ?? 1.0);
    
    dataBox.put('gastos_v2', gastos);
    notifyListeners();
  }

  // Aquí agregaremos posteriormente los métodos de conversión y envíos para mantenerlo limpio
}
