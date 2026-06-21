// Archivo: lib/main_layout.dart
import 'package:flutter/material.dart';

// Importaciones de tus vistas reales
import 'package:syncra_app/features/ocr/ocr_scanner_view.dart';
import 'package:syncra_app/features/shipping/volumetric_calculator.dart';
import 'package:syncra_app/features/conversion/currency_converter_view.dart';
import 'package:syncra_app/features/backup/cloud_sync_service.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Reemplazamos los placeholders por tus vistas 100% funcionales
  final List<Widget> _screens = [
    const OcrScannerView(),
    const VolumetricCalculatorView(),
    const CurrencyConverterView(),
    const CloudSyncView(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'OCR',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Envíos',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Divisas',
          ),
          NavigationDestination(
            icon: Icon(Icons.cloud_sync_outlined),
            selectedIcon: Icon(Icons.cloud_sync),
            label: 'Respaldo',
          ),
        ],
      ),
    );
  }
}
