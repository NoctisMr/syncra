// Archivo: lib/domain/models/item_model.dart
import 'dart:convert';

// TODO: Descomentar las siguientes líneas al configurar el pubspec.yaml
// import 'package:hive/hive.dart';
// part 'item_model.g.dart'; // Archivo generado automáticamente después

// TODO: Descomentar la anotación al configurar Hive
// @HiveType(typeId: 0)
class ItemModel {
  // TODO: Descomentar los @HiveField al configurar Hive
  
  // @HiveField(0)
  final String id;

  // @HiveField(1)
  final String name;

  // @HiveField(2)
  final String description; // Ideal para guardar el texto extraído por el OCR

  // @HiveField(3)
  final double length; // Para el estimador volumétrico

  // @HiveField(4)
  final double width; // Para el estimador volumétrico

  // @HiveField(5)
  final double height; // Para el estimador volumétrico

  // @HiveField(6)
  final double price; // Para el cotizador y conversor de divisas

  ItemModel({
    required this.id,
    required this.name,
    this.description = '',
    this.length = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.price = 0.0,
  });

  // =========================================================================
  // FUNCIONES PREMIUM: SERIALIZACIÓN A JSON (Para Exportar/Importar)
  // =========================================================================

  /// Convierte el objeto a un Mapa (Diccionario)
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'length': length,
      'width': width,
      'height': height,
      'price': price,
    };
  }

  /// Crea un objeto ItemModel a partir de un Mapa (Ideal para leer desde la Base de Datos)
  factory ItemModel.fromMap(Map<String, dynamic> map) {
    return ItemModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      length: (map['length'] ?? 0.0).toDouble(),
      width: (map['width'] ?? 0.0).toDouble(),
      height: (map['height'] ?? 0.0).toDouble(),
      price: (map['price'] ?? 0.0).toDouble(),
    );
  }

  /// Convierte el modelo directamente a un String JSON para la exportación a la nube
  String toJson() => json.encode(toMap());

  /// Restaura el modelo desde un String JSON importado
  factory ItemModel.fromJson(String source) => ItemModel.fromMap(json.decode(source));
}
