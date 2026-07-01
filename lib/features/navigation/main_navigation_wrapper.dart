// lib/features/navigation/main_navigation_wrapper.dart
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/localization/app_localizations.dart';
import '../../core/providers/app_provider.dart';
import '../../core/services/backup_export_service.dart';
import '../budget/presentation/views/budget_view.dart';
import '../converter/presentation/views/converter_view.dart';
import '../shipping/presentation/views/shipping_view.dart';
import '../budget/presentation/providers/budget_provider.dart';

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

    Widget mainContent = Scaffold(
      backgroundColor: appProvider.backgroundImagePath != null ? Colors.transparent : theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(t('app_name'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: appProvider.backgroundImagePath != null ? Colors.transparent : theme.appBarTheme.backgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => _showCustomizationSheet(context, appProvider, t),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() => _currentIndex = index);
          FocusScope.of(context).unfocus();
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
          NavigationDestination(icon: const Icon(Icons.account_balance_wallet_outlined), selectedIcon: const Icon(Icons.account_balance_wallet), label: t('budget_tab')),
          NavigationDestination(icon: const Icon(Icons.currency_exchange_outlined), selectedIcon: const Icon(Icons.currency_exchange), label: t('converter_tab')),
          NavigationDestination(icon: const Icon(Icons.local_shipping_outlined), selectedIcon: const Icon(Icons.local_shipping), label: t('shipping_tab')),
        ],
      ),
    );

    // Optimized rendering for background images
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
                  cacheWidth: 800, // RAM optimization
                ),
              ),
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
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

    return GestureDetector(onTap: () => FocusScope.of(context).unfocus(), child: mainContent);
  }

  void _showCustomizationSheet(BuildContext context, AppProvider provider, String Function(String) t) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        final theme = Theme.of(context);
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (_, controller) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView(
              controller: controller,
              children: [
                const SizedBox(height: 16),
                Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4), borderRadius: BorderRadius.circular(2)))),
                const SizedBox(height: 24),
                Text("Ajustes Globales", style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                const SizedBox(height: 32),

                // Backup & Export (JSON/CSV)
                Text("Copia de Seguridad y Exportación", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () async {
                        await BackupExportService.instance.exportBackup();
                        if(context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text("Respaldar (JSON)"),
                    ),
                    FilledButton.tonalIcon(
                      onPressed: () async {
                        bool success = await BackupExportService.instance.importBackup();
                        if (success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Datos restaurados con éxito.")));
                          Navigator.pop(context);
                        }
                      },
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text("Restaurar (JSON)"),
                    ),
                    OutlinedButton.icon(
                      onPressed: () async {
                        final gastos = context.read<BudgetProvider>().gastosDelMes;
                        await BackupExportService.instance.exportToExcel('budget', gastos);
                      },
                      icon: const Icon(Icons.table_chart_outlined, size: 18),
                      label: const Text("Exportar Mes (CSV)"),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),

                // Theme settings
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
                    provider.updateThemeMode(mode == ThemeMode.light ? 'light' : mode == ThemeMode.dark ? 'dark' : 'system');
                  },
                ),
                const SizedBox(height: 24),

                // Color Seed settings
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
                          margin: const EdgeInsets.only(right: 14), width: 44, height: 44,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle, border: isSelected ? Border.all(color: theme.colorScheme.onSurface, width: 3) : null),
                          child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // Background Image Optimization settings
                Text("Fondo de Pantalla", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picker = ImagePicker();
                          final XFile? image = await picker.pickImage(
                            source: ImageSource.gallery,
                            imageQuality: 75, // Compression
                            maxWidth: 1080,   // Downscaling
                          );
                          if (image != null) await provider.setBackgroundImage(image.path);
                        },
                        icon: const Icon(Icons.wallpaper_outlined),
                        label: const Text("Cargar desde Galería"),
                      ),
                    ),
                    if (provider.backgroundImagePath != null) ...[
                      const SizedBox(width: 12),
                      IconButton.filledTonal(onPressed: () => provider.setBackgroundImage(null), icon: const Icon(Icons.delete_outline_rounded), color: theme.colorScheme.error),
                    ]
                  ],
                ),
                const SizedBox(height: 24),

                // Localization settings
                Text("Idioma Base", style: theme.textTheme.titleMedium?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: provider.language,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8)),
                  items: const [
                    DropdownMenuItem(value: 'es', child: Text("Español (Castellano)")),
                    DropdownMenuItem(value: 'en', child: Text("English (International)")),
                    DropdownMenuItem(value: 'pt', child: Text("Português (Brasil)")),
                  ],
                  onChanged: (String? newLang) { if (newLang != null) provider.updateLanguage(newLang); },
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        );
      },
    );
  }
}
