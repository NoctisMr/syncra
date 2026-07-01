// lib/main.dart
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
  WidgetsFlutterBinding.ensureInitialized();
  
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await LocalStorageService.instance.init();

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
      child: Consumer<AppProvider>(
        builder: (context, appProvider, child) {
          return MaterialApp(
            title: 'Global Wallet & Shipping',
            debugShowCheckedModeBanner: false,
            themeMode: appProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: appProvider.seedColor,
                brightness: Brightness.light,
              ),
              scaffoldBackgroundColor: appProvider.backgroundImagePath != null 
                  ? Colors.transparent 
                  : null,
            ),
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
            home: appProvider.isLoading 
                ? const Scaffold(body: Center(child: CircularProgressIndicator()))
                : const MainNavigationWrapper(),
          );
        },
      ),
    );
  }
}
