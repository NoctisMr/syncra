// Archivo: lib/main.dart
import 'package:flutter/material.dart';
import 'package:syncra_app/core/database/local_storage.dart';
import 'package:syncra_app/app_theme.dart';
import 'package:syncra_app/main_layout.dart';

void main() async {
  // Asegura que los bindings de Flutter estén listos antes de iniciar DBs o ML Kit
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inicializamos Hive
  await LocalStorageService.instance.initDatabase();
  
  runApp(const SyncraApp());
}

class SyncraApp extends StatelessWidget {
  const SyncraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncra App',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      home: const MainLayout(),
    );
  }
}
