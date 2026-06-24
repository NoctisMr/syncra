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

  // 3. Inicializa la base de datos local (Hive)
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
      // 🌟 SOLUCIÓN: Usamos Consumer para escuchar dinámicamente los cambios visuales y refrescar el tema
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Global Wallet & Shipping',
            debugShowCheckedModeBanner: false,
            themeMode: appProvider.themeMode, // Vinculado a las opciones guardadas
            
            // TEMA CLARO DINÁMICO
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: appProvider.seedColor, // Color puro o inteligentemente mezclado con la foto
                brightness: Brightness.light,
              ),
              // Si hay imagen de fondo, hacemos el andamiaje transparente para renderizar el fondo real detrás
              scaffoldBackgroundColor: appProvider.backgroundImagePath != null 
                  ? Colors.transparent 
                  : null,
            ),
            
            // TEMA OSCURO DINÁMICO
            darkTheme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: appProvider.seedColor,
                brightness: Brightness.dark,
              ),
              scaffoldBackgroundColor: appProvider.backgroundImagePath != null 
                  ? Colors.transparent 
                  : null,
            ),
            
            // Espera a que termine la carga asíncrona de IPs, APIs e idiomas antes de renderizar la UI
            home: appProvider.isLoading 
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : const MainNavigationWrapper(),
          );
        },
      ),
    );
  }
}
