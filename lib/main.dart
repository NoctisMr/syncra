import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';

import 'translations.dart';
import 'tabs/presupuesto_tab.dart';
import 'tabs/conversor_tab.dart';
import 'tabs/envios_tab.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('settingsBox');
  await Hive.openBox('dataBox');
  runApp(const SyncraApp());
}

class SyncraApp extends StatefulWidget {
  const SyncraApp({super.key});
  @override
  State<SyncraApp> createState() => _SyncraAppState();
}

class _SyncraAppState extends State<SyncraApp> {
  ThemeMode _themeMode = ThemeMode.light;
  Color _seedColor = const Color(0xFF29B6F6);
  String _language = 'es';
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  void _loadSettings() {
    final box = Hive.box('settingsBox');
    setState(() {
      _themeMode = (box.get('isDark', defaultValue: false)) ? ThemeMode.dark : ThemeMode.light;
      _seedColor = Color(box.get('themeColor', defaultValue: 0xFF29B6F6));
      _language = box.get('language', defaultValue: 'es');
      _isLoading = false;
    });
  }

  void _updateSettings(ThemeMode tm, Color color, String lang) {
    final box = Hive.box('settingsBox');
    box.put('isDark', tm == ThemeMode.dark);
    box.put('themeColor', color.value);
    box.put('language', lang);
    setState(() {
      _themeMode = tm;
      _seedColor = color;
      _language = lang;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const MaterialApp(home: Scaffold(body: Center(child: CircularProgressIndicator())));
    return MaterialApp(
      title: 'Syncra',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.light),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: _seedColor, brightness: Brightness.dark),
      ),
      home: MainScreen(
        currentLang: _language,
        isDark: _themeMode == ThemeMode.dark,
        seedColor: _seedColor,
        onSettingsChanged: _updateSettings,
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  final String currentLang;
  final bool isDark;
  final Color seedColor;
  final Function(ThemeMode, Color, String) onSettingsChanged;

  const MainScreen({super.key, required this.currentLang, required this.isDark, required this.seedColor, required this.onSettingsChanged});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;
  late PageController _pageController; 
  late Box dataBox;
  final NumberFormat numFormat = NumberFormat('#,##0.00', 'en_US');

  Map<String, double> tasasCambio = { 'USD': 1.0, 'BRL': 5.0, 'PEN': 3.7, 'EUR': 0.92, 'VES': 36.5, 'MXN': 17.5, 'JPY': 155.0 };
  String ultimaActualizacion = "---";

  // --- VARIABLES PRESUPUESTO ---
  String monedaLocal = 'USD';
  String monedaRef = 'USD'; // Por defecto fijado en Dólar (USD)
  TextEditingController sueldoCtrl = TextEditingController();
  TextEditingController nombreGastoCtrl = TextEditingController();
  TextEditingController montoGastoCtrl = TextEditingController();
  List<Map<String, dynamic>> gastos = [];
  double balanceLocal = 0.0;
  double balanceEq = 0.0;

  // --- VARIABLES CONVERSOR ---
  TextEditingController convMontoCtrl = TextEditingController();
  String monedaDe = 'USD';
  String monedaA = 'USD';
  double resultadoConversion = 0.0;

  // --- VARIABLES ENVÍOS ---
  TextEditingController precioEnvioCtrl = TextEditingController();
  TextEditingController pesoEnvioCtrl = TextEditingController();
  TextEditingController proxyCostoCtrl = TextEditingController();
  String monedaProxy = 'USD';
  String origenEnvio = 'Japón';
  String destinoEnvio = 'Brasil';
  String monedaOrigenEnvio = 'USD';
  String monedaDestinoEnvio = 'USD';
  String desgloseEnvio = "";
  double totalEnvio = 0.0;

  final Map<String, Map<String, dynamic>> taxRules = {
    'Brasil': { 'limit': 50.0, 'under_limit_tax': 0.20, 'over_limit_tax': 0.60, 'state_tax_icms': 0.17 },
    'Perú': { 'limit': 200.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.22, 'state_tax_icms': 0.0 },
    'México': { 'limit': 50.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.19, 'state_tax_icms': 0.0 },
    'EE.UU.': { 'limit': 800.0, 'under_limit_tax': 0.0, 'over_limit_tax': 0.10, 'state_tax_icms': 0.0 },
    'Europa': { 'limit': 150.0, 'under_limit_tax': 0.21, 'over_limit_tax': 0.235, 'state_tax_icms': 0.0 },
    'Japón': { 'limit': 0.0, 'under_limit_tax': 0.10, 'over_limit_tax': 0.10, 'state_tax_icms': 0.0 },
    'Venezuela': { 'limit': 0.0, 'under_limit_tax': 0.30, 'over_limit_tax': 0.30, 'state_tax_icms': 0.0 },
  };

  final List<Color> themeColors = [
    const Color(0xFF29B6F6), const Color(0xFF81C784), const Color(0xFFBA68C8),
    const Color(0xFFFF8A65), const Color(0xFFF06292), const Color(0xFF90A4AE),
  ];

  final List<Map<String, dynamic>> categoriesConfig = [
    {'id': 'cat_shopping', 'color': 0xFF29B6F6, 'icon': Icons.shopping_bag},
    {'id': 'cat_services', 'color': 0xFFFF8A65, 'icon': Icons.bolt},
    {'id': 'cat_subs', 'color': 0xFFBA68C8, 'icon': Icons.subscriptions},
    {'id': 'cat_food', 'color': 0xFF81C784, 'icon': Icons.restaurant},
    {'id': 'cat_others', 'color': 0xFF90A4AE, 'icon': Icons.category},
  ];

  String t(String key) => i18n[widget.currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    desgloseEnvio = t('calc_prompt');
    dataBox = Hive.box('dataBox');
    _cargarDatosLocales();
    _sincronizarUbicacionYTasas();
  }

  @override
  void dispose() {
    _pageController.dispose();
    sueldoCtrl.dispose();
    nombreGastoCtrl.dispose();
    montoGastoCtrl.dispose();
    convMontoCtrl.dispose();
    precioEnvioCtrl.dispose();
    pesoEnvioCtrl.dispose();
    proxyCostoCtrl.dispose();
    super.dispose();
  }

  void _cargarDatosLocales() {
    setState(() {
      sueldoCtrl.text = dataBox.get('sueldo', defaultValue: "");
      monedaLocal = dataBox.get('monedaLocal', defaultValue: "USD");
      monedaRef = dataBox.get('monedaRef', defaultValue: "USD"); // Forzar USD por defecto
      monedaDe = dataBox.get('monedaDe', defaultValue: "USD");
      monedaA = dataBox.get('monedaA', defaultValue: "USD");
      proxyCostoCtrl.text = dataBox.get('proxyCosto', defaultValue: "5.0");
      monedaProxy = dataBox.get('monedaProxy', defaultValue: "USD");
      ultimaActualizacion = dataBox.get('ultima_actualizacion', defaultValue: "---");
      destinoEnvio = dataBox.get('destinoEnvio', defaultValue: "Brasil");
      monedaDestinoEnvio = dataBox.get('monedaDestinoEnvio', defaultValue: "USD");
      
      var gastosGuardadosV2 = dataBox.get('gastos_v2');
      if (gastosGuardadosV2 != null) {
        gastos = List<Map<String, dynamic>>.from(gastosGuardadosV2.map((e) => Map<String, dynamic>.from(e)));
      }
      
      Map<dynamic, dynamic>? tasasJson = dataBox.get('tasas_historial');
      if (tasasJson != null) {
        tasasJson.forEach((key, value) {
          if (tasasCambio.containsKey(key.toString())) tasasCambio[key.toString()] = (value as num).toDouble();
        });
      }
      _recalcularTodo();
    });
  }

  void _guardarDatos() {
    dataBox.put('sueldo', sueldoCtrl.text);
    dataBox.put('monedaLocal', monedaLocal);
    dataBox.put('monedaRef', monedaRef);
    dataBox.put('monedaDe', monedaDe);
    dataBox.put('monedaA', monedaA);
    dataBox.put('proxyCosto', proxyCostoCtrl.text);
    dataBox.put('monedaProxy', monedaProxy);
    dataBox.put('destinoEnvio', destinoEnvio);
    dataBox.put('monedaDestinoEnvio', monedaDestinoEnvio);
    dataBox.put('gastos_v2', gastos);
  }

  Future<void> _sincronizarUbicacionYTasas() async {
    String paisDetectado = "Otros";
    String monedaDetectada = "USD";
    String codigoPais = "";

    // 1. GEO-LOCALIZACIÓN IP (Sin solicitudes de permisos GPS del OS)
    try {
      final locResponse = await http.get(Uri.parse('https://ipapi.co/json/')).timeout(const Duration(seconds: 4));
      if (locResponse.statusCode == 200) {
        final locData = jsonDecode(locResponse.body);
        codigoPais = locData['country_code'] ?? '';
        String incomingCurrency = locData['currency'] ?? 'USD';

        if (tasasCambio.containsKey(incomingCurrency)) {
          monedaDetectada = incomingCurrency;
        }

        // Mapeo geográfico de reglas aduaneras locales
        if (codigoPais == 'BR') paisDetectado = 'Brasil';
        else if (codigoPais == 'PE') paisDetectado = 'Perú';
        else if (codigoPais == 'MX') paisDetectado = 'México';
        else if (codigoPais == 'US') paisDetectado = 'EE.UU.';
        else if (codigoPais == 'JP') paisDetectado = 'Japón';
        else if (codigoPais == 'VE') paisDetectado = 'Venezuela';
        else if (['ES','FR','DE','IT','NL'].contains(codigoPais)) paisDetectado = 'Europa';
      }
    } catch (_) { /* Red no disponible, se salta el paso de re-ubicación */ }

    // 2. DESCARGA DE COTIZACIONES DE DIVISAS
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        
        setState(() {
          for (var m in tasasCambio.keys) {
            if (rates.containsKey(m)) tasasCambio[m] = (rates[m] as num).toDouble();
          }

          ultimaActualizacion = DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
          dataBox.put('ultima_actualizacion', ultimaActualizacion);
          dataBox.put('tasas_historial', tasasCambio);

          // VERIFICACIÓN DINÁMICA DE CAMBIO DE PAÍS
          String ultimoPaisRegistrado = dataBox.get('ultimo_pais_code', defaultValue: "");
          if (codigoPais.isNotEmpty && codigoPais != ultimoPaisRegistrado) {
            monedaLocal = monedaDetectada;
            monedaDe = monedaDetectada;
            destinoEnvio = paisDetectado;
            monedaDestinoEnvio = monedaDetectada;
            dataBox.put('ultimo_pais_code', codigoPais);
          }

          _recalcularTodo(); 
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modo offline: Usando tasas locales'), duration: Duration(seconds: 2)));
      }
    }
  }

  void _recalcularTodo() {
    _calcularPresupuesto();
    _calcularConversion();
    _calcularEnvio();
  }

  void _calcularPresupuesto() {
    double sueldo = double.tryParse(sueldoCtrl.text) ?? 0.0;
    double totalGastos = gastos.fold(0.0, (sum, item) => sum + (item['monto'] as double));
    setState(() {
      balanceLocal = sueldo - totalGastos;
      double netoUsd = balanceLocal / (tasasCambio[monedaLocal] ?? 1.0);
      balanceEq = netoUsd * (tasasCambio[monedaRef] ?? 1.0);
    });
    _guardarDatos();
  }

  void _calcularConversion() {
    double monto = double.tryParse(convMontoCtrl.text) ?? 0.0;
    double montoUsd = monto / (tasasCambio[monedaDe] ?? 1.0);
    setState(() { resultadoConversion = montoUsd * (tasasCambio[monedaA] ?? 1.0); });
    _guardarDatos();
  }

  void _calcularEnvio() {
    double precioOrigen = double.tryParse(precioEnvioCtrl.text) ?? 0.0;
    double pesoKg = double.tryParse(pesoEnvioCtrl.text) ?? 0.0;
    double costoProxyInput = double.tryParse(proxyCostoCtrl.text) ?? 0.0;

    if (precioOrigen == 0 && pesoKg == 0) {
      setState(() { desgloseEnvio = t('calc_prompt'); totalEnvio = 0.0; });
      return;
    }

    double precioUsd = precioOrigen / (tasasCambio[monedaOrigenEnvio] ?? 1.0);
    double proxyFeeUsd = costoProxyInput / (tasasCambio[monedaProxy] ?? 1.0);
    double costoEnvioUsd = 0.0;
    
    if (origenEnvio == 'Nacional') costoEnvioUsd = 4.0 + (pesoKg * 2.5);
    else if (origenEnvio == 'China') costoEnvioUsd = 3.0 + (pesoKg * 15.0);
    else if (origenEnvio == 'EE.UU.') costoEnvioUsd = 12.0 + (pesoKg * 9.0);
    else if (origenEnvio == 'Japón') costoEnvioUsd = 15.0 + (pesoKg * 22.0);
    else if (origenEnvio == 'Europa') costoEnvioUsd = 14.0 + (pesoKg * 18.0);

    double baseCif = precioUsd + costoEnvioUsd + proxyFeeUsd;
    var rule = taxRules[destinoEnvio] ?? { 'limit': 0.0, 'under_limit_tax': 0.30, 'over_limit_tax': 0.30, 'state_tax_icms': 0.0 };
    double baseTaxRate = precioUsd <= rule['limit'] ? rule['under_limit_tax'] : rule['over_limit_tax'];
    double federalTaxUsd = baseCif * baseTaxRate;
    double baseWithFederal = baseCif + federalTaxUsd;
    
    double impuestoUsd = 0.0;
    if (rule['state_tax_icms'] > 0) {
      double finalGrossValue = baseWithFederal / (1 - rule['state_tax_icms']);
      impuestoUsd = finalGrossValue - baseCif;
    } else {
      impuestoUsd = federalTaxUsd;
    }

    double totalUsd = baseCif + impuestoUsd;
    setState(() {
      totalEnvio = totalUsd * (tasasCambio[monedaDestinoEnvio] ?? 1.0);
      desgloseEnvio = "${t('value')} (USD): \$${numFormat.format(precioUsd)}\n${t('freight')}: \$${numFormat.format(costoEnvioUsd)}"
          "${proxyFeeUsd > 0 ? ' | ${t('proxy')}: \$${numFormat.format(proxyFeeUsd)}' : ''}"
          "${impuestoUsd > 0 ? ' | ${t('tax')}: \$${numFormat.format(impuestoUsd)}' : ''}";
    });
    _guardarDatos();
  }

  Future<void> _pegarNumeros(TextEditingController ctrl, VoidCallback onDone) async {
    ClipboardData? data = await Clipboard.getData('text/plain');
    if (data != null && data.text != null) {
      String numeros = data.text!.replaceAll(RegExp(r'[^0-9.]'), '');
      if (numeros.isNotEmpty) {
        setState(() { ctrl.text = numeros; onDone(); });
      }
    }
  }

  Future<void> _copiarResultado(String numeros) async {
    if (numeros.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: numeros));
      HapticFeedback.lightImpact();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('copied'))));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: null, elevation: 0, backgroundColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: IconButton(icon: const Icon(Icons.palette), onPressed: _abrirAjustes),
          ),
        ],
      ),
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const ClampingScrollPhysics(), 
          onPageChanged: (index) { setState(() { _currentIndex = index; }); },
          children: [ 
            PresupuestoTab(
              currentLang: widget.currentLang,
              tasasCambio: tasasCambio,
              numFormat: numFormat,
              sueldoCtrl: sueldoCtrl,
              nombreGastoCtrl: nombreGastoCtrl,
              montoGastoCtrl: montoGastoCtrl,
              gastos: gastos,
              monedaLocal: monedaLocal,
              balanceLocal: balanceLocal,
              onCalcular: _calcularPresupuesto,
              onGastoAdded: (gasto) => setState(() { gastos.insert(0, gasto); _calcularPresupuesto(); }),
              onGastoDeleted: (id) => setState(() { gastos.removeWhere((e) => e['id'] == id); _calcularPresupuesto(); }),
              onMonedaLocalChanged: (val) => setState(() { monedaLocal = val; _calcularPresupuesto(); }),
              categoriesConfig: categoriesConfig,
              pegarNumeros: _pegarNumeros,
            ),
            ConversorTab(
              currentLang: widget.currentLang,
              tasasCambio: tasasCambio,
              numFormat: numFormat,
              convMontoCtrl: convMontoCtrl,
              monedaDe: monedaDe,
              monedaA: monedaA,
              resultadoConversion: resultadoConversion,
              ultimaActualizacion: ultimaActualizacion, // INYECCIÓN DE TIEMPO
              onMonedasChanged: (de, a) => setState(() { monedaDe = de; monedaA = a; _calcularConversion(); }),
              onCalcular: _calcularConversion,
              pegarNumeros: _pegarNumeros,
              copiarResultado: _copiarResultado,
            ),
            EnviosTab(
              currentLang: widget.currentLang,
              tasasCambio: tasasCambio,
              numFormat: numFormat,
              precioEnvioCtrl: precioEnvioCtrl,
              pesoEnvioCtrl: pesoEnvioCtrl,
              proxyCostoCtrl: proxyCostoCtrl,
              monedaProxy: monedaProxy,
              origenEnvio: origenEnvio,
              destinoEnvio: destinoEnvio,
              monedaOrigenEnvio: monedaOrigenEnvio,
              monedaDestinoEnvio: monedaDestinoEnvio,
              desgloseEnvio: desgloseEnvio,
              totalEnvio: totalEnvio,
              onParametrosChanged: ({monedaProxy, origenEnvio, destinoEnvio, monedaOrigenEnvio, monedaDestinoEnvio}) {
                setState(() {
                  if (monedaProxy != null) this.monedaProxy = monedaProxy;
                  if (origenEnvio != null) this.origenEnvio = origenEnvio;
                  if (destinoEnvio != null) this.destinoEnvio = destinoEnvio;
                  if (monedaOrigenEnvio != null) this.monedaOrigenEnvio = monedaOrigenEnvio;
                  if (monedaDestinoEnvio != null) this.monedaDestinoEnvio = monedaDestinoEnvio;
                  _calcularEnvio();
                });
              },
              copiarResultado: _copiarResultado,
            )
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) { _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic); },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: t('budget')),
          BottomNavigationBarItem(icon: const Icon(Icons.currency_exchange), label: t('converter')),
          BottomNavigationBarItem(icon: const Icon(Icons.local_shipping), label: t('shipping')),
        ],
      ),
    );
  }

  void _abrirAjustes() {
    showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t('settings'), style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(t('language'), style: const TextStyle(fontSize: 16)),
                  DropdownButton<String>(
                    value: widget.currentLang,
                    items: const [ DropdownMenuItem(value: 'es', child: Text("Español")), DropdownMenuItem(value: 'en', child: Text("English")) ],
                    onChanged: (val) {
                      widget.onSettingsChanged(widget.isDark ? ThemeMode.dark : ThemeMode.light, widget.seedColor, val!);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              SwitchListTile(
                title: Text(t('dark_mode')), value: widget.isDark, contentPadding: EdgeInsets.zero,
                onChanged: (val) { widget.onSettingsChanged(val ? ThemeMode.dark : ThemeMode.light, widget.seedColor, widget.currentLang); },
              ),
              const SizedBox(height: 10),
              Text(t('theme_color'), style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: themeColors.map((color) => GestureDetector(
                    onTap: () => widget.onSettingsChanged(widget.isDark ? ThemeMode.dark : ThemeMode.light, color, widget.currentLang),
                    child: Container(
                      margin: const EdgeInsets.only(right: 12), width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle,
                        border: Border.all(color: widget.seedColor == color ? Colors.black54 : Colors.transparent, width: 3),
                      ),
                    ),
                  )).toList(),
                ),
              )
            ],
          ),
        );
      }
    );
  }
}
