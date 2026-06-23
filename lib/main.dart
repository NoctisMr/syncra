// Archivo: lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

// Importaciones de Core
import 'core/database/local_storage_service.dart';
import 'core/providers/app_provider.dart';

// Importaciones de Características (Features)
import 'features/budget/presentation/providers/budget_provider.dart';
import 'features/converter/presentation/providers/converter_provider.dart';
import 'features/shipping/presentation/providers/shipping_provider.dart';
import 'features/navigation/main_navigation_wrapper.dart';

void main() async {
  // 1. Asegurar que los canales de la plataforma nativa estén inicializados
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Bloquear la orientación de la aplicación en modo vertical de forma estricta
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // 3. Inicializar la base de datos local (Hive / SharedPreferences según implementación)
  await LocalStorageService.instance.init();

  // 4. Encender la aplicación de Flutter
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Inyectores de Estado Global y Lógica de Negocio
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => BudgetProvider()),
        ChangeNotifierProvider(create: (_) => ConverterProvider()),
        ChangeNotifierProvider(create: (_) => ShippingProvider()),
      ],
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Global Wallet & Shipping',
            debugShowCheckedModeBanner: false,
            
            // --- CONFIGURACIÓN DE TEMA DINÁMICO (Material 3 habilitado) ---
            themeMode: appProvider.isDarkMode ? ThemeMode.dark : ThemeMode.light,
            theme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF1E3A8A), // Azul corporativo premium para marca blanca
              brightness: Brightness.light,
              cardTheme: const CardTheme(margin: EdgeInsets.zero),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              colorSchemeSeed: const Color(0xFF1E3A8A),
              brightness: Brightness.dark,
              cardTheme: const CardTheme(margin: EdgeInsets.zero),
            ),

            // --- PUNTO DE ENTRADA CON EL ESQUELETO DE NAVEGACIÓN ---
            home: const MainNavigationWrapper(),
          );
        },
      ),
    );
  }
}
