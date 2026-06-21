// Archivo: lib/features/history/history_view.dart
import 'package:flutter/material.dart';
import '../../core/models/app_data_model.dart';
import '../../core/services/storage_service.dart';

class HistoryView extends StatefulWidget {
  const HistoryView({super.key});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> {
  final StorageService _storageService = StorageService();
  List<AppData> _records = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  /// Carga los registros almacenados y los ordena por fecha
  Future<void> _loadRecords() async {
    setState(() => _isLoading = true);
    
    final records = await _storageService.getAllRecords();
    // Ordenamos de más reciente a más antiguo
    records.sort((a, b) => b.date.compareTo(a.date));
    
    setState(() {
      _records = records;
      _isLoading = false;
    });
  }

  /// Simula la exportación (aquí conectarás la lógica para crear un archivo .json real)
  Future<void> _exportData() async {
    final jsonData = await _storageService.exportToJson();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Datos exportados a JSON listos para compartir.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Registros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Exportar a JSON',
            onPressed: _exportData,
          ),
        ],
      ),
      // Manejo de estados visuales para calidad CodeCanyon
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : _records.isEmpty
              ? _buildEmptyState(context)
              : _buildRecordsList(),
    );
  }

  /// Estado visual cuando no hay datos guardados
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history_toggle_off,
            size: 64,
            color: Theme.of(context).colorScheme.outline,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay registros guardados aún.',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  /// Lista dinámica de registros guardados
  Widget _buildRecordsList() {
    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _records.length,
        itemBuilder: (context, index) {
          final record = _records[index];
          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: 12),
            // Color de fondo adaptable a modo claro/oscuro
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                child: const Icon(Icons.attach_money),
              ),
              title: Text(
                '${record.amount.toStringAsFixed(2)} ${record.currency}',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(record.description),
                    const SizedBox(height: 4),
                    Text(
                      '${record.date.day.toString().padLeft(2, '0')}/${record.date.month.toString().padLeft(2, '0')}/${record.date.year}',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {
                  // Futura expansión: Editar o eliminar registro
                },
              ),
            ),
          );
        },
      ),
    );
  }
}
