// Archivo: lib/domain/models/item_model.dart
import 'dart:convert';
import 'package:hive/hive.dart';

part 'item_model.g.dart'; 

@HiveType(typeId: 0)
class ItemModel {
  
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String name;

  @HiveField(2)
  final String description; 

  @HiveField(3)
  final double length; 

  @HiveField(4)
  final double width; 

  @HiveField(5)
  final double height; 

  @HiveField(6)
  final double price; 

  ItemModel({
    required this.id,
    required this.name,
    this.description = '',
    this.length = 0.0,
    this.width = 0.0,
    this.height = 0.0,
    this.price = 0.0,
  });

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

  String toJson() => json.encode(toMap());

  factory ItemModel.fromJson(String source) => ItemModel.fromMap(json.decode(source));
}
