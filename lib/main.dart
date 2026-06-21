import 'package:flutter/material.dart';

// Rutas directas para estructura plana
import 'local_storage.dart';
import 'app_theme.dart';
import 'main_layout.dart';

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
