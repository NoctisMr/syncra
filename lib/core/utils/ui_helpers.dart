// Archivo: lib/core/utils/ui_helpers.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Utilidades globales para interactuar con el sistema nativo (Portapapeles, Haptics)
/// y estandarizar componentes visuales rápidos como SnackBars.
class UiHelpers {
  
  /// Copia un texto al portapapeles del dispositivo y muestra un SnackBar elegante estilo Material 3.
  static Future<void> copyToClipboard(BuildContext context, String text, String successMessage) async {
    if (text.isEmpty) return;
    
    // Guardar en el sistema nativo
    await Clipboard.setData(ClipboardData(text: text));
    
    // Generar una vibración sutil (Feedback háptico) para dar sensación de app Premium
    await HapticFeedback.lightImpact();

    // Verificación de seguridad por si el usuario cerró la pantalla durante el proceso asíncrono
    if (!context.mounted) return;

    // Limpiar SnackBars activos antes de mostrar el nuevo para evitar encolamientos visuales
    ScaffoldMessenger.of(context).clearSnackBars();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          successMessage,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// Lee el portapapeles del sistema, extrae únicamente los números o puntos decimales,
  /// y los escribe directamente en un controlador de texto (TextEditingController).
  static Future<void> pasteNumbersFromClipboard(
    TextEditingController controller, {
    required VoidCallback onDone,
  }) async {
    try {
      final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data != null && data.text != null) {
        // Expresión regular que elimina letras, símbolos y espacios, manteniendo solo dígitos y puntos
        final String filteredText = data.text!.replaceAll(RegExp(r'[^0-9.]'), '');
        
        if (filteredText.isNotEmpty) {
          controller.text = filteredText;
          // Feedback háptico de confirmación al pegar con éxito
          await HapticFeedback.mediumImpact();
          onDone();
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error al acceder al portapapeles nativo: $e');
    }
  }
}
