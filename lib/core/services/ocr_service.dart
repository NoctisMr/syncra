// Archivo: lib/core/services/ocr_service.dart
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrService {
  // Privamos el constructor para mantener un patrón Singleton de alto rendimiento
  OcrService._privateConstructor();
  static final OcrService instance = OcrService._privateConstructor();

  final ImagePicker _picker = ImagePicker();
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Permite al usuario seleccionar una imagen de la Cámara o Galería
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } catch (e) {
      debugPrint('Error al capturar o seleccionar la imagen: $e');
      return null;
    }
  }

  /// Procesa la imagen seleccionada y extrae todo el texto visible
  Future<String> extractTextFromImage(File imageFile) async {
    try {
      final inputImage = InputImage.fromFile(imageFile);
      final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      return recognizedText.text;
    } catch (e) {
      debugPrint('Error en el procesamiento OCR: $e');
      throw Exception('No se pudo analizar el texto de la imagen.');
    }
  }

  /// Método de seguridad para evitar fugas de memoria (Memory Leaks)
  void dispose() {
    _textRecognizer.close();
  }
}
