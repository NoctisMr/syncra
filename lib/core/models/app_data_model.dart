// Archivo: lib/core/models/app_data_model.dart
class AppData {
  final String id;
  final double amount;
  final String currency;
  final DateTime date;
  final String description;

  AppData({
    required this.id,
    required this.amount,
    required this.currency,
    required this.date,
    required this.description,
  });

  // Convertir a Map para guardar en JSON (nube/local)
  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'currency': currency,
    'date': date.toIso8601String(),
    'description': description,
  };

  // Crear objeto desde Map
  factory AppData.fromMap(Map<String, dynamic> map) => AppData(
    id: map['id'],
    amount: map['amount'],
    currency: map['currency'],
    date: DateTime.parse(map['date']),
    description: map['description'],
  );
}
