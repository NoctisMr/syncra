// Archivo: lib/features/budget/presentation/views/budget_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../../core/providers/app_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../providers/budget_provider.dart';

class BudgetView extends StatefulWidget {
  const BudgetView({super.key});

  @override
  State<BudgetView> createState() => _BudgetViewState();
}

class _BudgetViewState extends State<BudgetView> {
  int _touchedChartIndex = -1;
  String _categoriaSeleccionada = 'cat_others';
  String? _monedaGastoSeleccionada;

  final List<Map<String, dynamic>> _categoriesConfig = [
    {'id': 'cat_shopping', 'color': 0xFF29B6F6, 'icon': Icons.shopping_bag},
    {'id': 'cat_services', 'color': 0xFFFF8A65, 'icon': Icons.bolt},
    {'id': 'cat_subs', 'color': 0xFFBA68C8, 'icon': Icons.subscriptions},
    {'id': 'cat_food', 'color': 0xFF81C784, 'icon': Icons.restaurant},
    {'id': 'cat_others', 'color': 0xFF90A4AE, 'icon': Icons.category},
  ];

  final NumberFormat _numFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    final theme = Theme.of(context);
    final bool hasBg = appProvider.backgroundImagePath != null;
    
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    double sueldo = double.tryParse(budgetProvider.sueldoCtrl.text) ?? 0.0;
    // 🌟 AHORA VERIFICAMOS LOS DATOS DEL MES ACTUAL
    bool hasData = sueldo > 0 || budgetProvider.gastosDelMes.isNotEmpty || budgetProvider.bovedas.isNotEmpty;
    
    String currentMonedaGasto = _monedaGastoSeleccionada ?? appProvider.monedaLocal;
    if (!appProvider.tasasCambio.containsKey(currentMonedaGasto)) currentMonedaGasto = appProvider.monedaLocal;

    // Formateador dinámico para el nombre del mes
    String nombreMes = DateFormat('MMMM yyyy', appProvider.language).format(budgetProvider.currentMonth).toUpperCase();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- HEADER: MONEDA Y NAVEGACIÓN MENSUAL ---
          Card(
            elevation: 0,
            color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('local_curr'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        underline: const SizedBox(),
                        value: appProvider.monedaLocal,
                        items: appProvider.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val, style: const TextStyle(fontWeight: FontWeight.bold)))).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            appProvider.updateMonedaLocal(val);
                            budgetProvider.calcularPresupuesto();
                          }
                        },
                      )
                    ],
                  ),
                  const Divider(height: 1),
                  // 🌟 NAVEGADOR DE MESES TIPO CALENDARIO
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => budgetProvider.cambiarMes(-1)),
                      Text(nombreMes, style: TextStyle(fontWeight: FontWeight.w900, color: theme.colorScheme.primary)),
                      IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => budgetProvider.cambiarMes(1)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- INPUT: SUELDO BASE ---
          Card(
            elevation: 0,
            color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : Colors.transparent,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: hasBg ? 8.0 : 0, vertical: hasBg ? 4.0 : 0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: budgetProvider.sueldoCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: t('base_salary'), 
                        border: hasBg ? InputBorder.none : OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                      ),
                      onChanged: (_) => budgetProvider.calcularPresupuesto(),
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.paste), color: theme.colorScheme.primary, onPressed: () => UiHelpers.pasteNumbersFromClipboard(budgetProvider.sueldoCtrl, onDone: budgetProvider.calcularPresupuesto))
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // --- GRÁFICA CIRCULAR ---
          if (hasData) ...[
            _buildChart(budgetProvider, appProvider, sueldo, t, hasBg),
            const SizedBox(height: 24),
          ],

          // ... (Resto de la UI de bóvedas y formulario de gastos, que se mantiene igual a la Parte 3 anterior) ...
          
          // --- HISTORIAL DE GASTOS DEL MES ---
          ...budgetProvider.gastosDelMes.map((gasto) {
            final catConfig = _categoriesConfig.firstWhere((c) => c['id'] == gasto.categoria, orElse: () => _categoriesConfig.last);
            bool esExtranjero = gasto.monedaOriginal != appProvider.monedaLocal;

            return Dismissible(
              key: Key(gasto.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) { 
                budgetProvider.deleteGasto(gasto.id); 
                HapticFeedback.mediumImpact(); 
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0,
                color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : theme.colorScheme.surface,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.5))),
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Color(catConfig['color']).withOpacity(0.15), child: Icon(catConfig['icon'], color: Color(catConfig['color']), size: 20)),
                  title: Text(gasto.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text("${t(gasto.categoria)} • ${DateFormat('dd MMM yyyy, HH:mm').format(gasto.fecha)}", style: const TextStyle(fontSize: 11)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${_numFormat.format(gasto.montoOriginal)} ${gasto.monedaOriginal}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: theme.colorScheme.onSurface)),
                      if (esExtranjero) Text("~ ${_numFormat.format(gasto.montoLocal)} ${appProvider.monedaLocal}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  // Se mantienen los métodos _buildChart, _buildVaultCard, _buildAddExpenseSection y _mostrarDialogoBoveda
  // de la actualización anterior, asegurándose de que iteren sobre budgetProvider.gastosDelMes donde sea necesario.
}
