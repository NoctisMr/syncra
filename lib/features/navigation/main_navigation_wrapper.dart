// Archivo: lib/features/navigation/main_navigation_wrapper.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/localization/app_localizations.dart';
import '../../core/providers/app_provider.dart';
import '../budget/presentation/views/budget_view.dart';
import '../converter/presentation/views/converter_view.dart';
import '../shipping/presentation/views/shipping_view.dart';

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _currentIndex = 0;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    // Envolvemos todo en GestureDetector para ocultar el teclado al tocar fuera
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('app_name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          elevation: 0,
          backgroundColor: Theme.of(context).colorScheme.surface,
          actions: [
            // Selector de Idioma Rápido
            DropdownButton<String>(
              value: appProvider.language,
              underline: const SizedBox(),
              icon: const Icon(Icons.language, size: 20),
              items: const [
                DropdownMenuItem(value: 'es', child: Text('ES ')),
                DropdownMenuItem(value: 'en', child: Text('EN ')),
                DropdownMenuItem(value: 'pt', child: Text('PT ')),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) appProvider.updateLanguage(newValue);
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        // PageView permite deslizar con el dedo entre pestañas
        body: PageView(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() => _currentIndex = index);
            FocusScope.of(context).unfocus(); // Oculta teclado al deslizar
          },
          children: const [
            BudgetView(),
            ConverterView(),
            ShippingView(),
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          },
          destinations: [
            NavigationDestination(
              icon: const Icon(Icons.account_balance_wallet_outlined),
              selectedIcon: const Icon(Icons.account_balance_wallet),
              label: t('budget_tab'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.currency_exchange_outlined),
              selectedIcon: const Icon(Icons.currency_exchange),
              label: t('converter_tab'),
            ),
            NavigationDestination(
              icon: const Icon(Icons.local_shipping_outlined),
              selectedIcon: const Icon(Icons.local_shipping),
              label: t('shipping_tab'),
            ),
          ],
        ),
      ),
    );
  }
}
