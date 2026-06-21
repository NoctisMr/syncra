// Archivo: lib/main.dart
import 'package:flutter/material.dart';

// Rutas exactas basadas en tu estructura
import 'package:syncra_app/core/database/local_storage.dart';
import 'package:syncra_app/core/theme/app_theme.dart';
import 'package:syncra_app/ui/layouts/main_layout.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
