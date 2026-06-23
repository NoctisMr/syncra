// Archivo: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'core/database/local_storage_service.dart';
import 'core/providers/app_provider.dart';
import 'features/budget/presentation/providers/budget_provider.dart';
import 'features/converter/presentation/providers/converter_provider.dart';
import 'features/shipping/presentation/providers/shipping_provider.dart';
import 'features/navigation/main_navigation_wrapper.dart';

void main() async {
  // 1. Asegurar la inicialización de los canales nativos
  WidgetsFlutterBinding.ensureInitialized();
  
  // 2. Bloquear en modo vertical
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Inicializa la base de datos (Ahora que Hive está en el pubspec, esto funcionará perfecto)
  await LocalStorageService.instance.init();

  // 4. Iniciar la app
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => ConverterProvider()),
        ChangeNotifierProvider(create: (_) => ShippingProvider()),
      ],
      child: MaterialApp(
        title: 'Global Wallet & Shipping',
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system, // Fallback automático y seguro a nivel sistema
        theme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1E3A8A),
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          useMaterial3: true,
          colorSchemeSeed: const Color(0xFF1E3A8A),
          brightness: Brightness.dark,
        ),
        home: const MainNavigationWrapper(),
      ),
    );
  }
}
