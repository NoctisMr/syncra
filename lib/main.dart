import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const SyncraApp());
}

// --- DICCIONARIO BILINGÜE ---
const Map<String, Map<String, String>> i18n = {
  'es': {
    'budget': 'Presupuesto', 'converter': 'Conversor', 'shipping': 'Envíos',
    'local_curr': 'Moneda Local:', 'ref_curr': 'Moneda Ref:', 'base_salary': 'Sueldo Base Mensual',
    'add_expense': 'AÑADIR SUSCRIPCIÓN / GASTO', 'name': 'Nombre', 'amount': 'Monto',
    'net_balance': 'BALANCE NETO LIBRE', 'deficit': '(Déficit)', 'quick_conv': 'CONVERSOR RÁPIDO',
    'amount_to_convert': 'Monto a cambiar', 'customs': 'ADUANAS Y ENVÍOS', 'price': 'Precio',
    'weight': 'Peso (Kg)', 'origin': 'Origen del artículo', 'proxy_cost': 'Costo Intermediario / Proxy',
    'destination': 'Destino (Aduanas)', 'calc_prompt': 'Ingresa datos para calcular...',
    'copied': 'Copiado al portapapeles', 'settings': 'Ajustes', 'dark_mode': 'Modo Oscuro',
    'theme_color': 'Color del Tema', 'language': 'Idioma', 'value': 'Valor', 'freight': 'Flete',
    'proxy': 'Proxy', 'tax': 'Aduana', 'current_rate': 'Tasa Actual:'
  },
  'en': {
    'budget': 'Budget', 'converter': 'Converter', 'shipping': 'Shipping',
    'local_curr': 'Local Curr:', 'ref_curr': 'Ref Curr:', 'base_salary': 'Base Monthly Salary',
    'add_expense': 'ADD SUBSCRIPTION / EXPENSE', 'name': 'Name', 'amount': 'Amount',
    'net_balance': 'NET FREE BALANCE', 'deficit': '(Deficit)', 'quick_conv': 'QUICK CONVERTER',
    'amount_to_convert': 'Amount to convert', 'customs': 'CUSTOMS & SHIPPING', 'price': 'Price',
    'weight': 'Weight (Kg)', 'origin': 'Item Origin', 'proxy_cost': 'Proxy / Courier Cost',
    'destination': 'Destination (Customs)', 'calc_prompt': 'Enter data to calculate...',
    'copied': 'Copied to clipboard', 'settings': 'Settings', 'dark_mode': 'Dark Mode',
    'theme_color': 'Theme Color', 'language': 'Language', 'value': 'Value', 'freight': 'Freight',
    'proxy': 'Proxy', 'tax': 'Tax', 'current_rate': 'Current Rate:'
  }
};

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

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _themeMode = (prefs.getBool('isDark') ?? false) ? ThemeMode.dark : ThemeMode.light;
      _seedColor = Color(prefs.getInt('themeColor') ?? 0xFF29B6F6);
      _language = prefs.getString('language') ?? 'es';
      _isLoading = false;
    });
  }

  void _updateSettings(ThemeMode tm, Color color, String lang) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('isDark', tm == ThemeMode.dark);
    prefs.setInt('themeColor', color.value);
    prefs.setString('language', lang);
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
  SharedPreferences? prefs;
  Map<String, double> tasasCambio = { 'USD': 1.0, 'BRL': 5.0, 'PEN': 3.7, 'EUR': 0.92, 'VES': 36.5, 'MXN': 17.5, 'JPY': 155.0 };
  
  // Variables Presupuesto
  String monedaLocal = 'USD';
  String monedaRef = 'BRL';
  TextEditingController sueldoCtrl = TextEditingController();
  TextEditingController nombreGastoCtrl = TextEditingController();
  TextEditingController montoGastoCtrl = TextEditingController();
  Map<String, double> gastos = {};
  double balanceLocal = 0.0;
  double balanceEq = 0.0;
  
  // Variables Conversor
  TextEditingController convMontoCtrl = TextEditingController();
  String monedaDe = 'USD';
  String monedaA = 'PEN';
  double resultadoConversion = 0.0;
  
  // Variables Envíos
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

  final List<Color> themeColors = [
    const Color(0xFF29B6F6),
    const Color(0xFF81C784),
    const Color(0xFFBA68C8),
    const Color(0xFFFF8A65),
    const Color(0xFFF06292),
    const Color(0xFF90A4AE),
  ];
  
  String t(String key) => i18n[widget.currentLang]?[key] ?? key;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
    desgloseEnvio = t('calc_prompt');
    _cargarDatosLocales();
    _actualizarTasasInternet();
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

  Future<void> _cargarDatosLocales() async {
    prefs = await SharedPreferences.getInstance();
    setState(() {
      sueldoCtrl.text = prefs?.getString('sueldo') ?? "";
      monedaLocal = prefs?.getString('monedaLocal') ?? "USD";
      monedaRef = prefs?.getString('monedaRef') ?? "BRL";
      monedaDe = prefs?.getString('monedaDe') ?? "USD";
      monedaA = prefs?.getString('monedaA') ?? "PEN";
      proxyCostoCtrl.text = prefs?.getString('proxyCosto') ?? "5.0";
      monedaProxy = prefs?.getString('monedaProxy') ?? "USD";
      
      String? gastosJson = prefs?.getString('gastos');
      if (gastosJson != null) {
        Map<String, dynamic> decoded = jsonDecode(gastosJson);
        gastos = decoded.map((key, value) => MapEntry(key, (value as num).toDouble()));
      }
      
      String? tasasJson = prefs?.getString('tasas_historial');
      if (tasasJson != null) {
        Map<String, dynamic> decodedTasas = jsonDecode(tasasJson);
        decodedTasas.forEach((key, value) {
          if (tasasCambio.containsKey(key)) tasasCambio[key] = (value as num).toDouble();
        });
      }
      _recalcularTodo();
    });
  }

  void _guardarDatos() {
    prefs?.setString('sueldo', sueldoCtrl.text);
    prefs?.setString('monedaLocal', monedaLocal);
    prefs?.setString('monedaRef', monedaRef);
    prefs?.setString('monedaDe', monedaDe);
    prefs?.setString('monedaA', monedaA);
    prefs?.setString('proxyCosto', proxyCostoCtrl.text);
    prefs?.setString('monedaProxy', monedaProxy);
    prefs?.setString('gastos', jsonEncode(gastos));
  }

  Future<void> _actualizarTasasInternet() async {
    try {
      final response = await http.get(Uri.parse('https://open.er-api.com/v6/latest/USD')).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        setState(() {
          for (var m in tasasCambio.keys) {
            if (rates.containsKey(m)) tasasCambio[m] = (rates[m] as num).toDouble();
          }
          prefs?.setString('tasas_historial', jsonEncode(tasasCambio));
          _recalcularTodo(); 
        });
      }
    } catch (e) { }
  }

  void _recalcularTodo() {
    _calcularPresupuesto();
    _calcularConversion();
    _calcularEnvio();
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

  Future<void> _copiarResultado(String texto) async {
    String numeros = texto.replaceAll(RegExp(r'[^0-9.]'), '');
    if (numeros.isNotEmpty) {
      await Clipboard.setData(ClipboardData(text: numeros));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('copied'))));
    }
  }


    // --- MATEMÁTICAS ---
  void _calcularPresupuesto() {
    double sueldo = double.tryParse(sueldoCtrl.text) ?? 0.0;
    double totalGastos = gastos.values.fold(0.0, (sum, val) => sum + val);
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
    double impuestoUsd = 0.0;
    if (origenEnvio == 'Nacional') { costoEnvioUsd = 4.0 + (pesoKg * 2.5); }
    else if (origenEnvio == 'China') { costoEnvioUsd = 3.0 + (pesoKg * 15.0); }
    else if (origenEnvio == 'EE.UU.') { costoEnvioUsd = 12.0 + (pesoKg * 9.0); }
    else if (origenEnvio == 'Japón') { costoEnvioUsd = 15.0 + (pesoKg * 22.0); }
    else if (origenEnvio == 'Europa') { costoEnvioUsd = 14.0 + (pesoKg * 18.0); }

    double baseCif = precioUsd + costoEnvioUsd + proxyFeeUsd;
    switch (destinoEnvio) {
      case 'Brasil': impuestoUsd = precioUsd <= 50.0 ? baseCif * 0.20 : baseCif * 0.92; break;
      case 'Perú': impuestoUsd = precioUsd <= 200.0 ? 0.0 : baseCif * 0.22; break;
      case 'México': impuestoUsd = precioUsd <= 50.0 ? 0.0 : baseCif * 0.19; break;
      case 'EE.UU.': impuestoUsd = precioUsd <= 800.0 ? 0.0 : baseCif * 0.10; break;
      case 'Europa': impuestoUsd = (baseCif * 0.21) + (precioUsd > 150.0 ? baseCif * 0.025 : 0.0); break;
      case 'Japón': impuestoUsd = baseCif * 0.10; break;
      case 'Venezuela': impuestoUsd = baseCif * 0.30; break;
      default: impuestoUsd = baseCif * 0.30;
    }

    double totalUsd = baseCif + impuestoUsd;
    setState(() {
      totalEnvio = totalUsd * (tasasCambio[monedaDestinoEnvio] ?? 1.0);
      desgloseEnvio = "${t('value')} (USD): \$${precioUsd.toStringAsFixed(2)}\n${t('freight')}: \$${costoEnvioUsd.toStringAsFixed(2)}"
          "${proxyFeeUsd > 0 ? ' | ${t('proxy')}: \$${proxyFeeUsd.toStringAsFixed(2)}' : ''}"
          "${impuestoUsd > 0 ? ' | ${t('tax')}: \$${impuestoUsd.toStringAsFixed(2)}' : ''}";
    });
    _guardarDatos();
  }

  void _abrirAjustes() {
    showModalBottomSheet(
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
                    items: const [
                      DropdownMenuItem(value: 'es', child: Text("Español")),
                      DropdownMenuItem(value: 'en', child: Text("English")),
                    ],
                    onChanged: (val) {
                      widget.onSettingsChanged(widget.isDark ? ThemeMode.dark : ThemeMode.light, widget.seedColor, val!);
                      Navigator.pop(context);
                    },
                  )
                ],
              ),
              SwitchListTile(
                title: Text(t('dark_mode')),
                value: widget.isDark,
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  widget.onSettingsChanged(val ? ThemeMode.dark : ThemeMode.light, widget.seedColor, widget.currentLang);
                },
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
                      margin: const EdgeInsets.only(right: 12),
                      width: 40, height: 40,
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

  // --- INTERFAZ ---
  @override
  Widget build(BuildContext context) {
    List<Widget> screens = [ _buildPresupuestoTab(), _buildConversorTab(), _buildEnviosTab() ];
    return Scaffold(
      appBar: AppBar(
        title: null, 
        elevation: 0,
        backgroundColor: Colors.transparent,
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
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          children: screens,
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        onTap: (index) {
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        },
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.account_balance_wallet), label: t('budget')),
          BottomNavigationBarItem(icon: const Icon(Icons.currency_exchange), label: t('converter')),
          BottomNavigationBarItem(icon: const Icon(Icons.local_shipping), label: t('shipping')),
        ],
      ),
    );
  }

  Widget _buildPresupuestoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('local_curr'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: monedaLocal,
                        items: tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (val) { setState(() { monedaLocal = val!; _calcularPresupuesto(); }); },
                      )
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('ref_curr'), style: const TextStyle(color: Colors.grey)),
                      DropdownButton<String>(
                        value: monedaRef,
                        items: tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (val) { setState(() { monedaRef = val!; _calcularPresupuesto(); }); },
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: sueldoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t('base_salary'), border: const OutlineInputBorder()),
                  onChanged: (_) => _calcularPresupuesto(),
                ),
              ),
              IconButton(icon: const Icon(Icons.paste), color: Theme.of(context).colorScheme.primary, onPressed: () => _pegarNumeros(sueldoCtrl, _calcularPresupuesto))
            ],
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('add_expense'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: nombreGastoCtrl, decoration: InputDecoration(hintText: t('name'), border: const UnderlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: montoGastoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: t('amount'), border: const UnderlineInputBorder()))),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 36),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          String nombre = nombreGastoCtrl.text.trim();
                          double? monto = double.tryParse(montoGastoCtrl.text.trim());
                          if (nombre.isNotEmpty && monto != null) {
                            setState(() { gastos[nombre] = monto; nombreGastoCtrl.clear(); montoGastoCtrl.clear(); _calcularPresupuesto(); });
                          }
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...gastos.entries.map((entry) => Card(
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            elevation: 0,
            child: ListTile(
              title: Text(entry.key),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("${entry.value.toStringAsFixed(2)} $monedaLocal", style: const TextStyle(fontWeight: FontWeight.w500)),
                  IconButton(icon: const Icon(Icons.delete, color: Color(0xFFFF8A80)), onPressed: () { setState(() { gastos.remove(entry.key); _calcularPresupuesto(); }); })
                ],
              ),
            ),
          )),
          const SizedBox(height: 16),
          Card(
            color: balanceLocal >= 0 ? Theme.of(context).colorScheme.primary : Theme.of(context).colorScheme.error,
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Text(t('net_balance'), style: TextStyle(color: Theme.of(context).colorScheme.onPrimary, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text(
                    "${balanceLocal.toStringAsFixed(2)} $monedaLocal ${balanceLocal < 0 ? t('deficit') : ''}",
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimary),
                    textAlign: TextAlign.center,
                  ),
                  Text("Eq: ${balanceEq.toStringAsFixed(2)} $monedaRef", style: TextStyle(color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8), fontSize: 13)),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

    Widget _buildConversorTab() {
    double tasaEspecifica = (tasasCambio[monedaA] ?? 1.0) / (tasasCambio[monedaDe] ?? 1.0);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('quick_conv'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: TextField(controller: convMontoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('amount_to_convert'), border: const OutlineInputBorder()), onChanged: (_) => _calcularConversion())),
                  IconButton(icon: const Icon(Icons.paste), color: Theme.of(context).colorScheme.primary, onPressed: () => _pegarNumeros(convMontoCtrl, _calcularConversion))
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  DropdownButton<String>(value: monedaDe, items: tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { setState(() { monedaDe = val!; _calcularConversion(); }); }),
                  IconButton(icon: const Icon(Icons.swap_horiz, size: 36), color: Theme.of(context).colorScheme.primary, onPressed: () { setState(() { String temp = monedaDe; monedaDe = monedaA; monedaA = temp; _calcularConversion(); }); }),
                  DropdownButton<String>(value: monedaA, items: tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { setState(() { monedaA = val!; _calcularConversion(); }); })
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    "1 $monedaDe = ${tasaEspecifica.toStringAsFixed(4)} $monedaA",
                    style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("${resultadoConversion.toStringAsFixed(2)} $monedaA", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                  IconButton(icon: const Icon(Icons.copy), color: Theme.of(context).colorScheme.primary, onPressed: () => _copiarResultado(resultadoConversion.toStringAsFixed(2)))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnviosTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t('customs'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 4, child: TextField(controller: precioEnvioCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('price'), border: const OutlineInputBorder()), onChanged: (_) => _calcularEnvio())),
                  const SizedBox(width: 8),
                  Expanded(flex: 3, child: DropdownButtonFormField<String>(isExpanded: true, value: monedaOrigenEnvio, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)), items: tasasCambio.keys.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { setState(() { monedaOrigenEnvio = val!; _calcularEnvio(); }); })),
                  const SizedBox(width: 8),
                  Expanded(flex: 4, child: TextField(controller: pesoEnvioCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('weight'), border: const OutlineInputBorder()), onChanged: (_) => _calcularEnvio())),
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                isExpanded: true, value: origenEnvio, decoration: InputDecoration(labelText: t('origin')),
                items: ['Japón', 'China', 'EE.UU.', 'Europa', 'Nacional'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                onChanged: (val) { setState(() { origenEnvio = val!; _calcularEnvio(); }); },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(flex: 2, child: TextField(controller: proxyCostoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('proxy_cost'), border: const UnderlineInputBorder()), onChanged: (_) => _calcularEnvio())),
                  const SizedBox(width: 16),
                  Expanded(flex: 1, child: DropdownButton<String>(isExpanded: true, value: monedaProxy, items: tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { setState(() { monedaProxy = val!; _calcularEnvio(); }); })),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: DropdownButtonFormField<String>(
                    isExpanded: true, value: destinoEnvio, decoration: InputDecoration(labelText: t('destination')),
                    items: ['Brasil', 'Perú', 'México', 'EE.UU.', 'Europa', 'Japón', 'Venezuela', 'Otros'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) { setState(() { destinoEnvio = val!; _calcularEnvio(); }); },
                  )),
                  const SizedBox(width: 12),
                  DropdownButton<String>(value: monedaDestinoEnvio, items: tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { setState(() { monedaDestinoEnvio = val!; _calcularEnvio(); }); }),
                ],
              ),
              const SizedBox(height: 16),
              Text(desgloseEnvio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(child: Text("${totalEnvio.toStringAsFixed(2)} $monedaDestinoEnvio", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)),
                  IconButton(icon: const Icon(Icons.copy), color: Theme.of(context).colorScheme.primary, onPressed: () => _copiarResultado(totalEnvio.toStringAsFixed(2)))
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
