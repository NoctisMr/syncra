// Archivo: lib/core/services/storage_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_data_model.dart';

class StorageService {
  static const _key = 'user_data_records';

  Future<void> saveRecord(AppData data) async {
    final prefs = await SharedPreferences.getInstance();
    final records = await getAllRecords();
    records.add(data);
    await prefs.setString(_key, jsonEncode(records.map((e) => e.toMap()).toList()));
  }

  Future<List<AppData>> getAllRecords() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_key);
    if (data == null) return [];
    
    final List<dynamic> decoded = jsonDecode(data);
    return decoded.map((e) => AppData.fromMap(e)).toList();
  }

  // Función para exportar todo a un String JSON (fácil para compartir)
  Future<String> exportToJson() async {
    final records = await getAllRecords();
    return jsonEncode(records.map((e) => e.toMap()).toList());
  }
}
