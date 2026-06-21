import 'package:flutter/material.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({Key? key}) : super(key: key);

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // Lista de pantallas. IndexedStack mantendrá el estado de cada una.
  final List<Widget> _screens = [
    const _PlaceholderScreen(title: 'Pantalla de Conversor (OCR)', icon: Icons.document_scanner),
    const _PlaceholderScreen(title: 'Pantalla de Envíos (Estimador)', icon: Icons.local_shipping),
    const _PlaceholderScreen(title: 'Ajustes y Nube', icon: Icons.cloud_sync),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack es CLAVE para evitar bugs visuales y pérdida de datos.
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      
      // NavigationBar de Material 3: Más alto, más accesible y con animaciones fluidas.
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (int index) {
          setState(() {
            _currentIndex = index;
          });
        },
        // Tematización dinámica: Se adaptará automáticamente si el usuario cambia a Modo Oscuro.
        backgroundColor: Theme.of(context).colorScheme.surface,
        indicatorColor: Theme.of(context).colorScheme.primaryContainer,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner),
            label: 'Conversor',
          ),
          NavigationDestination(
            icon: Icon(Icons.inventory_2_outlined),
            selectedIcon: Icon(Icons.inventory),
            label: 'Envíos',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}

// Widget temporal para visualizar las pantallas antes de conectarlas
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const _PlaceholderScreen({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 80, color: Theme.of(context).colorScheme.primary.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Módulo en construcción',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ],
        ),
      ),
    );
  }
}
