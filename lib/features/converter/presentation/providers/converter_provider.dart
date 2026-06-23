// Archivo: lib/features/converter/presentation/providers/converter_provider.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class ConverterProvider extends ChangeNotifier {
  double _carritoTotal = 0.0;
  double get carritoTotal => _carritoTotal;

  bool _isScanning = false;
  bool get isScanning => _isScanning;

  List<String> _scannedItems = [];
  List<String> get scannedItems => _scannedItems;

  final ImagePicker _picker = ImagePicker();

  // Lógica completa de escaneo y procesamiento
  Future<void> scanImage() async {
    try {
      _isScanning = true;
      notifyListeners();

      // 1. Captura de imagen
      final XFile? image = await _picker.pickImage(source: ImageSource.camera);
      
      if (image == null) {
        _isScanning = false;
        notifyListeners();
        return;
      }

      // 2. Procesamiento de texto
      final inputImage = InputImage.fromFilePath(image.path);
      final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      _scannedItems.clear();
      double tempTotal = 0.0;

      // 3. Extracción y suma
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          _scannedItems.add(line.text);
          
          final RegExp regex = RegExp(r'\d+[.,]\d+');
          final match = regex.firstMatch(line.text);
          if (match != null) {
            String numStr = match.group(0)!.replaceAll(',', '.');
            double? val = double.tryParse(numStr);
            if (val != null) {
              tempTotal += val;
            }
          }
        }
      }

      _carritoTotal = tempTotal;
      textRecognizer.close();

    } catch (e) {
      _scannedItems.add("Error al escanear: $e");
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }
}
