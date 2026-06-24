// Archivo: lib/features/navigation/main_navigation_wrapper.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
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
    final theme = Theme.of(context);

    // Definición de la estructura base del Scaffold
    Widget mainContent = Scaffold(
      backgroundColor: appProvider.backgroundImagePath != null ? Colors.transparent : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('app_name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: appProvider.backgroundImagePath != null ? Colors.transparent : theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.palette_outlined),
            onPressed: () => _showCustomizationSheet(context, appProvider, t),
            tooltip: "Personalizar Interfaz",
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          FocusScope.of(context).unfocus(); // Oculta el teclado nativo automáticamente en los deslizamientos
        },
        children: const [
          BudgetView(),
          ConverterView(),
          ShippingView(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: appProvider.backgroundImagePath != null ? Colors.transparent : null,
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
    );

    // 🌟 ENFOQUE DE DISEÑO PREMIUM: Si existe imagen guardada en disco, aplicamos el renderizado de capas traslúcidas
    if (appProvider.backgroundImagePath != null) {
      final file = File(appProvider.backgroundImagePath!);
      if (file.existsSync()) {
        return GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Stack(
            children: [
              Positioned.fill(
                child: Image.file(
                  file,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10), // Desenfoque cinemático suave
                  child: Container(
                    // Filtro de contraste dinámico que protege la lectura de los textos informativos
                    color: theme.brightness == Brightness.dark
                        ? Colors.black.withOpacity(0.45)
                        : Colors.white.withOpacity(0.45),
                  ),
                ),
              ),
              mainContent,
            ],
          ),
        );
      }
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: mainContent,
    );
  }

  // Despliegue de Panel Inferior de Configuración Visual (Aspecto Premium para CodeCanyon)
  void _showCustomizationSheet(BuildContext context, AppProvider provider, String Function(String) t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        final theme = Theme.of(context);
        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Ajustes de Interfaz",
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // 1. CONTROL DE MODOS DE BRILLO
              Text("Tema del Sistema", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text("Claro")),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text("Oscuro")),
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.phone_android_outlined), label: Text("Auto")),
                ],
                selected: {provider.themeMode},
                onSelectionChanged: (Set<ThemeMode> selection) {
                  final mode = selection.first;
                  if (mode == ThemeMode.light) provider.updateThemeMode('light');
                  else if (mode == ThemeMode.dark) provider.updateThemeMode('dark');
                  else provider.updateThemeMode('system');
                },
              ),
              const SizedBox(height: 24),

              // 2. CONTROL DE PALETA DINÁMICA (Cargados directo de AppConfig para marca blanca)
              Text("Esquema de Color Base", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 12),
              SizedBox(
                height: 50,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: AppConfig.themeColors.length,
                  itemBuilder: (context, index) {
                    final color = AppConfig.themeColors[index];
                    final isSelected = provider.originalSeedColor.value == color.value;
                    return GestureDetector(
                      onTap: () => provider.updateSeedColor(color),
                      child: Container(
                        margin: const EdgeInsets.only(right: 14),
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: theme.colorScheme.onSurface, width: 3)
                              : null,
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.35),
                              blurRadius: 6,
                              offset: const Offset(0, 3),
                            )
                          ],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check, color: Colors.white, size: 20)
                            : null,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // 3. SELECCIÓN DE IMÁGENES DE DISCO NATIVO
              Text("Fondo de Pantalla", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picker = ImagePicker();
                        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                        if (image != null) {
                          await provider.setBackgroundImage(image.path);
                        }
                      },
                      icon: const Icon(Icons.wallpaper_outlined),
                      label: const Text("Cargar desde Galería"),
                    ),
                  ),
                  if (provider.backgroundImagePath != null) ...[
                    const SizedBox(width: 12),
                    IconButton.filledTonal(
                      onPressed: () => provider.setBackgroundImage(null),
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: theme.colorScheme.error,
                    ),
                  ]
                ],
              ),
              const SizedBox(height: 24),

              // 4. CONTROL DE IDIOMA MANUAL CON RECONOCIMIENTO LOCALIZADO
              Text("Idioma Base", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: provider.language,
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                ),
                items: const [
                  DropdownMenuItem(value: 'es', child: Text("Español (Castellano)")),
                  DropdownMenuItem(value: 'en', child: Text("English (International)")),
                  DropdownMenuItem(value: 'pt', child: Text("Português (Brasil)")),
                ],
                onChanged: (String? newLang) {
                  if (newLang != null) {
                    provider.updateLanguage(newLang);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
