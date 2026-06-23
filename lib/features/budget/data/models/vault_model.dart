// Archivo: lib/features/budget/data/models/vault_model.dart

/// Modelo de datos para las Bóvedas (Metas de ahorro).
/// Incluye historial detallado para trazabilidad financiera.
class VaultModel {
  final String id;
  final String nombre;
  final double objetivo;
  final double ahorrado;
  final List<TransactionRecord> historial; // 🌟 Historial con fechas

  VaultModel({
    required this.id,
    required this.nombre,
    required this.objetivo,
    required this.ahorrado,
    required this.historial,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'objetivo': objetivo,
      'ahorrado': ahorrado,
      'historial': historial.map((x) => x.toMap()).toList(),
    };
  }

  factory VaultModel.fromMap(Map<dynamic, dynamic> map) {
    return VaultModel(
      id: map['id']?.toString() ?? '',
      nombre: map['nombre']?.toString() ?? 'Nueva Meta',
      objetivo: (map['objetivo'] as num?)?.toDouble() ?? 0.0,
      ahorrado: (map['ahorrado'] as num?)?.toDouble() ?? 0.0,
      historial: (map['historial'] as List?)
              ?.map((x) => TransactionRecord.fromMap(x))
              .toList() ?? [],
    );
  }
}

/// Sub-modelo para registrar cada movimiento en la bóveda
class TransactionRecord {
  final double monto;
  final DateTime fecha;
  final bool esRetiro; // true = retiro, false = depósito

  TransactionRecord({
    required this.monto,
    required this.fecha,
    required this.esRetiro,
  });

  Map<String, dynamic> toMap() => {
        'monto': monto,
        'fecha': fecha.toIso8601String(),
        'esRetiro': esRetiro,
      };

  factory TransactionRecord.fromMap(Map<dynamic, dynamic> map) => TransactionRecord(
        monto: (map['monto'] as num?)?.toDouble() ?? 0.0,
        fecha: DateTime.parse(map['fecha'].toString()),
        esRetiro: map['esRetiro'] ?? false,
      );
}
