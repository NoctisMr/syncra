// Archivo: lib/features/budget/data/models/gasto_model.dart

/// Modelo de datos estricto para los Gastos.
/// Garantiza que la información se guarde y recupere de la base de datos sin errores de tipado.
class GastoModel {
  final String id;
  final String nombre;
  final double montoOriginal;
  final String monedaOriginal;
  final double montoLocal;
  final String categoria;
  final DateTime fecha; // 🌟 Tu nueva mejora: Fecha exacta del gasto

  GastoModel({
    required this.id,
    required this.nombre,
    required this.montoOriginal,
    required this.monedaOriginal,
    required this.montoLocal,
    required this.categoria,
    required this.fecha,
  });

  /// Convierte el modelo a un formato compatible con Hive/JSON para guardarlo
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'monto_original': montoOriginal,
      'moneda_original': monedaOriginal,
      'monto': montoLocal,
      'categoria': categoria,
      'fecha': fecha.toIso8601String(), // Guardamos la fecha como texto estándar
    };
  }

  /// Reconstruye el objeto a partir de los datos guardados en la base de datos local
  factory GastoModel.fromMap(Map<dynamic, dynamic> map) {
    return GastoModel(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Sin nombre',
      montoOriginal: (map['monto_original'] as num?)?.toDouble() ?? 0.0,
      monedaOriginal: map['moneda_original']?.toString() ?? 'USD',
      montoLocal: (map['monto'] as num?)?.toDouble() ?? 0.0,
      categoria: map['categoria']?.toString() ?? 'cat_others',
      // Si el gasto es antiguo y no tenía fecha, le asignamos la fecha actual por defecto
      fecha: map['fecha'] != null 
          ? DateTime.parse(map['fecha'].toString()) 
          : DateTime.now(),
    );
  }
}
