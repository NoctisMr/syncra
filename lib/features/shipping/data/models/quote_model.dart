// Archivo: lib/features/shipping/data/models/quote_model.dart

/// Modelo de datos estricto para las Cotizaciones de Envío guardadas.
/// Mantiene un registro histórico de los cálculos aduaneros realizados por el usuario.
class QuoteModel {
  final String id;
  final String origen;
  final String destino;
  final double peso;
  final double total;
  final String moneda;
  final DateTime fecha; // 🌟 Fecha exacta en la que se calculó y guardó la cotización

  QuoteModel({
    required this.id,
    required this.origen,
    required this.destino,
    required this.peso,
    required this.total,
    required this.moneda,
    required this.fecha,
  });

  /// Convierte el objeto a un mapa compatible con el almacenamiento local (Hive)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'origen': origen,
      'destino': destino,
      'peso': peso,
      'total': total,
      'moneda': moneda,
      'fecha': fecha.toIso8601String(),
    };
  }

  /// Reconstruye el objeto a partir de los datos guardados
  factory QuoteModel.fromMap(Map<dynamic, dynamic> map) {
    return QuoteModel(
      id: map['id']?.toString() ?? '',
      origen: map['origen']?.toString() ?? 'Desconocido',
      destino: map['destino']?.toString() ?? 'Desconocido',
      peso: (map['peso'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num?)?.toDouble() ?? 0.0,
      moneda: map['moneda']?.toString() ?? 'USD',
      fecha: map['fecha'] != null 
          ? DateTime.parse(map['fecha'].toString()) 
          : DateTime.now(), // Fallback para datos antiguos
    );
  }
}
