// Archivo: lib/features/backup/cloud_sync_service.dart
import 'package:flutter/material.dart';
import 'dart:io';

// TODO: Ajustar la importación según el nombre real de tu proyecto en el pubspec
// import 'package:syncra_app/core/database/local_storage.dart';
// TODO: Descomentar en la fase final
// import 'package:file_picker/file_picker.dart';
// import 'package:path_provider/path_provider.dart';

class CloudSyncView extends StatefulWidget {
  const CloudSyncView({super.key});

  @override
  State<CloudSyncView> createState() => _CloudSyncViewState();
}

class _CloudSyncViewState extends State<CloudSyncView> {
  bool _isLoading = false;

  /// Lógica para exportar la base de datos a un archivo JSON
  Future<void> _exportData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Descomentar al integrar LocalStorageService
      // final jsonString = LocalStorageService.instance.exportDatabaseToJson();
      final String jsonString = '{"simulated_data": "Este es un respaldo de prueba"}';

      // TODO: Descomentar implementación real con path_provider
      // final directory = await getApplicationDocumentsDirectory();
      // final file = File('${directory.path}/syncra_backup.json');
      // await file.writeAsString(jsonString);
      
      // Simulación visual
      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Copia de seguridad exportada con éxito.'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      debugPrint('Error al exportar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al exportar los datos.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Lógica para importar un archivo JSON y restaurar la base de datos
  Future<void> _importData() async {
    setState(() => _isLoading = true);
    try {
      // TODO: Implementación real con file_picker (Descomentar en la fase final)
      // FilePickerResult? result = await FilePicker.platform.pickFiles(
      //   type: FileType.custom,
      //   allowedExtensions: ['json'],
      // );
      
      // if (result != null && result.files.single.path != null) {
      //   final file = File(result.files.single.path!);
      //   final jsonString = await file.readAsString();
      //   final success = await LocalStorageService.instance.importDatabaseFromJson(jsonString);
      //   
      //   if (!mounted) return;
      //   if (success) {
      //     ScaffoldMessenger.of(context).showSnackBar(
      //       const SnackBar(content: Text('Datos restaurados correctamente.')),
      //     );
      //   } else {
      //     throw Exception('El formato del archivo no es válido.');
      //   }
      // }
      
      // Simulación visual
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Datos importados y restaurados (Simulación).'),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

    } catch (e) {
      debugPrint('Error al importar: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al leer el archivo de respaldo.'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Respaldo y Nube'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(24.0),
            children: [
              _buildInfoCard(
                context,
                title: 'Exportar Datos',
                description: 'Genera un archivo .json con toda la información de tu app. Puedes guardarlo de manera segura en tu dispositivo, Google Drive o iCloud.',
                icon: Icons.cloud_upload_outlined,
                buttonLabel: 'Generar Respaldo',
                onPressed: _exportData,
              ),
              const SizedBox(height: 24),
              _buildInfoCard(
                context,
                title: 'Importar Datos',
                description: 'Restaura tu información seleccionando un archivo de respaldo previo. Esta acción sobrescribirá los datos actuales.',
                icon: Icons.cloud_download_outlined,
                buttonLabel: 'Restaurar Respaldo',
                onPressed: _importData,
                isDestructive: true,
              ),
            ],
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  /// Tarjeta de diseño modular que reutiliza los colores dinámicos de Material 3
  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required String buttonLabel,
    required VoidCallback onPressed,
    bool isDestructive = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 32,
                color: isDestructive 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: isDestructive 
                    ? Theme.of(context).colorScheme.errorContainer 
                    : Theme.of(context).colorScheme.primaryContainer,
                foregroundColor: isDestructive 
                    ? Theme.of(context).colorScheme.onErrorContainer 
                    : Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              child: Text(buttonLabel),
            ),
          ),
        ],
      ),
    );
  }
}
