// Archivo: lib/features/ocr/ocr_scanner_view.dart
import 'package:flutter/material.dart';

// TODO: Descomentar estas importaciones en la fase final
// import 'package:image_picker/image_picker.dart';
// import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class OcrScannerView extends StatefulWidget {
  const OcrScannerView({super.key});

  @override
  State<OcrScannerView> createState() => _OcrScannerViewState();
}

class _OcrScannerViewState extends State<OcrScannerView> {
  String _extractedText = '';
  bool _isProcessing = false;

  // TODO: Instanciar dependencias en la fase final
  // final ImagePicker _picker = ImagePicker();
  // final TextRecognizer _textRecognizer = TextRecognizer();

  /// Procesa la imagen seleccionada y extrae el texto
  Future<void> _processImage(/* ImageSource source */) async {
    setState(() {
      _isProcessing = true;
      _extractedText = '';
    });

    try {
      // TODO: Lógica real a implementar tras el pubspec.yaml
      // final XFile? image = await _picker.pickImage(source: source);
      // if (image == null) return;
      // final inputImage = InputImage.fromFilePath(image.path);
      // final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
      // setState(() => _extractedText = recognizedText.text);

      // Simulación temporal para visualizar el comportamiento de la UI
      await Future.delayed(const Duration(seconds: 2));
      setState(() {
        _extractedText = 'Texto simulado extraído exitosamente de la imagen.\nListo para integrarse con ML Kit.';
      });
    } catch (e) {
      debugPrint('Error durante el escaneo OCR: $e');
      setState(() {
        _extractedText = 'Ocurrió un error al procesar la imagen.';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  /// Muestra el modal Material 3 para elegir entre Cámara y Galería
  void _showSourceBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Seleccionar Origen',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _SourceOption(
                      icon: Icons.camera_alt,
                      label: 'Cámara',
                      onTap: () {
                        Navigator.pop(context);
                        _processImage(); // TODO: Pasar ImageSource.camera
                      },
                    ),
                    _SourceOption(
                      icon: Icons.photo_library,
                      label: 'Galería',
                      onTap: () {
                        Navigator.pop(context);
                        _processImage(); // TODO: Pasar ImageSource.gallery
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escáner OCR'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  // Uso estricto de tokens de Material 3
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: _isProcessing
                    ? const Center(child: CircularProgressIndicator())
                    : SingleChildScrollView(
                        child: Text(
                          _extractedText.isEmpty
                              ? 'El texto escaneado aparecerá aquí...'
                              : _extractedText,
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                color: _extractedText.isEmpty
                                    ? Theme.of(context).colorScheme.onSurfaceVariant
                                    : Theme.of(context).colorScheme.onSurface,
                              ),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _showSourceBottomSheet,
              icon: const Icon(Icons.document_scanner),
              label: const Text('Escanear Documento'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget privado para renderizar las opciones del BottomSheet con alta calidad visual
class _SourceOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SourceOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
