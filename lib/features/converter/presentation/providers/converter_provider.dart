// Archivo: lib/features/converter/presentation/providers/converter_provider.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../../core/config/app_config.dart';

/// Gestor de estado para el módulo de Conversión de Divisas.
/// Controla la lógica matemática, el spread bancario, el carrito temporal
/// y el procesamiento asíncrono del escáner OCR con ML Kit.
class ConverterProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService.instance;

  // --- CONTROLADORES DE INTERFAZ ---
  final TextEditingController convMontoCtrl = TextEditingController();
  final TextEditingController spreadCtrl = TextEditingController(text: "3.0");

  // --- ESTADO DE DATOS ---
  String _monedaDe = 'USD';
  String _monedaA = 'USD'; 
  double _resultadoConversion = 0.0;
  bool _applySpread = false;
  
  // Memoria del carrito para ir sumando precios escaneados
  double _carritoTotal = 0.0;
  
  // Estado de carga del escáner para mostrar el 'spinner' en la UI
  bool _isScanning = false;

  // --- GETTERS PÚBLICOS ---
  String get monedaDe => _monedaDe;
  String get monedaA => _monedaA;
  double get resultadoConversion => _resultadoConversion;
  bool get applySpread => _applySpread;
  double get carritoTotal => _carritoTotal;
  bool get isScanning => _isScanning;

  ConverterProvider() {
    _loadData();
  }

  // =========================================================================
  // CARGA Y GUARDADO DE DATOS LOCALS
  // =========================================================================

  void _loadData() {
    _monedaDe = _storage.getData('monedaDe', defaultValue: 'USD');
    _monedaA = _storage.getData('monedaA', defaultValue: 'USD');
    _applySpread = _storage.getData('apply_spread', defaultValue: false);
    spreadCtrl.text = _storage.getData('spread_value', defaultValue: "3.0");
  }

  void _saveData() {
    _storage.saveData('monedaDe', _monedaDe);
    _storage.saveData('monedaA', _monedaA);
    _storage.saveData('apply_spread', _applySpread);
    _storage.saveData('spread_value', spreadCtrl.text);
  }

  // =========================================================================
  // LÓGICA DE CONVERSIÓN
  // =========================================================================

  void setMonedas(String de, String a) {
    _monedaDe = de;
    _monedaA = a;
    calcularConversion();
  }

  void toggleSpread(bool val) {
    _applySpread = val;
    calcularConversion();
  }

  /// Calcula la conversión cruzando las dos monedas seleccionadas a través del USD base.
  void calcularConversion() {
    double monto = double.tryParse(convMontoCtrl.text) ?? 0.0;
    
    // Obtener tasas globales más recientes
    final Map<dynamic, dynamic> tasasRaw = _storage.getData('tasasCambio', defaultValue: AppConfig.defaultExchangeRates);
    final Map<String, double> tasas = tasasRaw.map((key, value) => MapEntry(key.toString(), double.parse(value.toString())));

    double tasaDe = tasas[_monedaDe] ?? 1.0;
    double tasaA = tasas[_monedaA] ?? 1.0;

    // Fórmula cruzada: Convertir a USD primero, luego a la moneda destino
    double montoUsd = monto / tasaDe;
    double conversionBase = montoUsd * tasaA;

    // Aplicar comisión bancaria si está habilitada
    double spreadPercent = double.tryParse(spreadCtrl.text) ?? 0.0;
    if (_applySpread && spreadPercent > 0) {
      _resultadoConversion = conversionBase * (1 + (spreadPercent / 100));
    } else {
      _resultadoConversion = conversionBase;
    }

    _saveData();
    notifyListeners();
  }

  // =========================================================================
  // GESTIÓN DEL CARRITO DE COMPRAS INTERNACIONAL
  // =========================================================================

  void sumarAlCarrito(double monto) {
    _carritoTotal += monto;
    convMontoCtrl.text = _carritoTotal.toStringAsFixed(2);
    calcularConversion();
  }

  void limpiarCarrito() {
    _carritoTotal = 0.0;
    convMontoCtrl.clear();
    calcularConversion();
  }

  // =========================================================================
  // LÓGICA DE MACHINE LEARNING (OCR)
  // =========================================================================

  /// Abre la cámara, toma la foto, busca patrones numéricos y devuelve el precio mayor encontrado.
  /// Retorna nulo si el usuario cancela o no hay precios claros.
  Future<double?> escanearPrecioDesdeCamara() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image == null) return null; // El usuario cerró la cámara

    _isScanning = true;
    notifyListeners(); // Avisamos a la UI para que gire el botón de carga

    double? precioDetectado;

    try {
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFilePath(image.path));
      
      // RegEx profesional: Detecta '1500', '1.500,50', '1,500.00', etc.
      RegExp exp = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)');
      List<double> precios = [];

      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          final match = exp.firstMatch(line.text);
          if (match != null) {
            // Limpieza de comas para parseo seguro en Dart
            String numStr = match.group(0)!.replaceAll(',', '');
            double? val = double.tryParse(numStr);
            if (val != null && val > 0) precios.add(val);
          }
        }
      }
      
      textRecognizer.close();

      if (precios.isNotEmpty) {
        // Ordenamos los valores. Usualmente el precio más alto en una etiqueta es el Total a pagar.
        precios.sort(); 
        precioDetectado = precios.last; 
      }
    } catch (e) {
      debugPrint("❌ Error procesando ML Kit: $e");
    } finally {
      _isScanning = false;
      notifyListeners(); // Apagamos el estado de carga
    }

    return precioDetectado;
  }

  @override
  void dispose() {
    convMontoCtrl.dispose();
    spreadCtrl.dispose();
    super.dispose();
  }
}
