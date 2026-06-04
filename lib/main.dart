import 'package:flutter/material.dart';
// Importaciones jerárquicas respetando tu estructura de carpetas
import 'tabs/conversor_tab.dart';
import 'tabs/envios_tab.dart';
import 'tabs/presupuesto_tab.dart';
import 'translations.dart'; 

void main() {
  runApp(const SyncraApp());
}

class SyncraApp extends StatelessWidget {
  const SyncraApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Syncra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      // Punto de entrada a la pantalla principal que gestiona los tabs
      home: const MainLayout(),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Lista de vistas importadas desde la carpeta 'lib/tabs/'
  final List<Widget> _tabs = const [
    ConversorTab(),
    EnviosTab(),
    PresupuestoTab(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.currency_exchange),
            label: 'Conversor', // Aquí puedes usar tus strings de translations.dart
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_shipping),
            label: 'Envíos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Presupuesto',
          ),
        ],
      ),
    );
  }
}
