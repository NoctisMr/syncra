// Archivo: lib/features/budget/presentation/views/budget_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Para formatear las fechas

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

  // Configuración visual estática de las categorías
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
    // Inyectamos ambos Providers (Configuración global y Lógica de Presupuesto)
    final appProvider = context.watch<AppProvider>();
    final budgetProvider = context.watch<BudgetProvider>();
    
    // Función de traducción optimizada
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    double sueldo = double.tryParse(budgetProvider.sueldoCtrl.text) ?? 0.0;
    bool hasData = sueldo > 0 || budgetProvider.gastos.isNotEmpty || budgetProvider.bovedas.isNotEmpty;
    
    String currentMonedaGasto = _monedaGastoSeleccionada ?? appProvider.monedaLocal;
    if (!appProvider.tasasCambio.containsKey(currentMonedaGasto)) {
      currentMonedaGasto = appProvider.monedaLocal;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- HEADER: MONEDA LOCAL ---
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
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
            ),
          ),
          const SizedBox(height: 16),

          // --- INPUT: SUELDO BASE ---
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: budgetProvider.sueldoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: t('base_salary'), 
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.account_balance_wallet_outlined),
                  ),
                  onChanged: (_) => budgetProvider.calcularPresupuesto(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.paste), 
                color: Theme.of(context).colorScheme.primary, 
                onPressed: () => UiHelpers.pasteNumbersFromClipboard(
                  budgetProvider.sueldoCtrl, 
                  onDone: budgetProvider.calcularPresupuesto
                )
              )
            ],
          ),
          const SizedBox(height: 24),

          // --- GRÁFICA CIRCULAR ---
          if (hasData) ...[
            _buildChart(budgetProvider, appProvider, sueldo, t),
            const SizedBox(height: 24),
          ],

          // --- BÓVEDAS (METAS) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('vaults'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              IconButton(
                icon: const Icon(Icons.add_box, color: Colors.amber), 
                onPressed: () => _mostrarDialogoBoveda(context, budgetProvider, appProvider, t)
              ),
            ],
          ),
          if (budgetProvider.bovedas.isNotEmpty) ...[
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: budgetProvider.bovedas.length,
                itemBuilder: (context, index) {
                  return _buildVaultCard(budgetProvider.bovedas[index], budgetProvider, appProvider, t);
                },
              ),
            ),
            const SizedBox(height: 16),
          ],

          // --- FORMULARIO: NUEVO GASTO ---
          _buildAddExpenseSection(budgetProvider, currentMonedaGasto, appProvider.tasasCambio.keys.toList(), t),
          const SizedBox(height: 16),

          // --- HISTORIAL DE GASTOS ---
          ...budgetProvider.gastos.map((gasto) {
            final catConfig = _categoriesConfig.firstWhere((c) => c['id'] == gasto.categoria, orElse: () => _categoriesConfig.last);
            bool esExtranjero = gasto.monedaOriginal != appProvider.monedaLocal;

            return Dismissible(
              key: Key(gasto.id),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
                alignment: Alignment.centerRight, 
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (_) { 
                budgetProvider.deleteGasto(gasto.id); 
                HapticFeedback.mediumImpact(); 
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5)),
                ),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Color(catConfig['color']).withOpacity(0.15), 
                    child: Icon(catConfig['icon'], color: Color(catConfig['color']), size: 20)
                  ),
                  title: Text(gasto.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                  // 🌟 Aquí usamos la nueva fecha del modelo estricto
                  subtitle: Text("${t(gasto.categoria)} • ${DateFormat('dd MMM yyyy, HH:mm').format(gasto.fecha)}", style: const TextStyle(fontSize: 11)),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center, 
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text("${_numFormat.format(gasto.montoOriginal)} ${gasto.monedaOriginal}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Theme.of(context).colorScheme.onSurface)),
                      if (esExtranjero) 
                        Text("~ ${_numFormat.format(gasto.montoLocal)} ${appProvider.monedaLocal}", style: const TextStyle(fontSize: 11, color: Colors.grey)),
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

  // =========================================================================
  // MÉTODOS PRIVADOS PARA CONSTRUIR LA UI Y MANTENER EL BUILD LIMPIO
  // =========================================================================

  Widget _buildChart(BudgetProvider provider, AppProvider appProvider, double sueldoTotal, String Function(String) t) {
    List<PieChartSectionData> sections = [];
    Map<String, double> sumas = {};
    int indexCounter = 0;

    for (var g in provider.gastos) {
      sumas[g.categoria] = (sumas[g.categoria] ?? 0.0) + g.montoLocal;
    }

    sumas.forEach((catId, montoSumado) {
      final isTouched = indexCounter == _touchedChartIndex;
      final catConfig = _categoriesConfig.firstWhere((c) => c['id'] == catId, orElse: () => {'color': 0xFF90A4AE});
      sections.add(PieChartSectionData(
        color: Color(catConfig['color']), value: montoSumado,
        title: sueldoTotal > 0 ? '${((montoSumado / sueldoTotal) * 100).toStringAsFixed(0)}%' : '',
        radius: isTouched ? 50.0 : 40.0,
        titleStyle: TextStyle(fontSize: isTouched ? 16.0 : 12.0, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      indexCounter++;
    });

    double totalBovedas = provider.bovedas.fold(0.0, (sum, b) => sum + b.ahorrado);
    if (totalBovedas > 0) {
      sections.add(PieChartSectionData(color: Colors.amber.shade600, value: totalBovedas, title: '', radius: indexCounter == _touchedChartIndex ? 50.0 : 40.0));
      indexCounter++;
    }

    if (provider.balanceLocal > 0) {
      sections.add(PieChartSectionData(
        color: Theme.of(context).colorScheme.primaryContainer, value: provider.balanceLocal, title: t('available'),
        radius: indexCounter == _touchedChartIndex ? 50.0 : 40.0,
        titleStyle: TextStyle(fontSize: indexCounter == _touchedChartIndex ? 14 : 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ));
    }

    return SizedBox(
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          PieChart(PieChartData(
            pieTouchData: PieTouchData(touchCallback: (FlTouchEvent event, pieTouchResponse) {
              setState(() {
                if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                  _touchedChartIndex = -1; return;
                }
                _touchedChartIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
              });
            }),
            borderData: FlBorderData(show: false), sectionsSpace: 3, centerSpaceRadius: 65, sections: sections,
          )),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('net_balance'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              Text(_numFormat.format(provider.balanceLocal), style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: provider.balanceLocal >= 0 ? Theme.of(context).colorScheme.primary : Colors.red)),
              Text(appProvider.monedaLocal, style: const TextStyle(fontSize: 10)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildVaultCard(dynamic boveda, BudgetProvider budgetProvider, AppProvider appProvider, String Function(String) t) {
    double progreso = (boveda.ahorrado / boveda.objetivo).clamp(0.0, 1.0);
    return Container(
      width: 220, margin: const EdgeInsets.only(right: 12),
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
        elevation: 0,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text(boveda.nombre, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16), overflow: TextOverflow.ellipsis)),
                  GestureDetector(onTap: () => budgetProvider.deleteBoveda(boveda.id), child: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent))
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(value: progreso, backgroundColor: Colors.black12, color: Colors.amber, borderRadius: BorderRadius.circular(4), minHeight: 6),
              const SizedBox(height: 6),
              Text("${(progreso * 100).toStringAsFixed(1)}% ${t('saved')}", style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text("${_numFormat.format(boveda.ahorrado)} ${appProvider.monedaLocal}", style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary, fontSize: 14)),
                      Text("/ ${_numFormat.format(boveda.objetivo)}", style: const TextStyle(fontSize: 10, color: Colors.grey)),
                    ],
                  ),
                  Row(
                    children: [
                      GestureDetector(onTap: () => _mostrarDialogoBoveda(context, budgetProvider, appProvider, t, id: boveda.id, esRetiro: true), child: const Icon(Icons.remove_circle, color: Colors.redAccent, size: 28)),
                      const SizedBox(width: 8),
                      GestureDetector(onTap: () => _mostrarDialogoBoveda(context, budgetProvider, appProvider, t, id: boveda.id, esRetiro: false), child: const Icon(Icons.add_circle, color: Colors.green, size: 28)),
                    ],
                  )
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddExpenseSection(BudgetProvider budgetProvider, String currentMonedaGasto, List<String> divisas, String Function(String) t) {
    return Card(
      elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3))),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t('add_expense'), style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _categoriesConfig.map((cat) {
                  bool isSelected = _categoriaSeleccionada == cat['id'];
                  return GestureDetector(
                    onTap: () => setState(() => _categoriaSeleccionada = cat['id']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? Color(cat['color']).withOpacity(0.15) : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: isSelected ? Color(cat['color']) : Colors.grey.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          Icon(cat['icon'], size: 16, color: isSelected ? Color(cat['color']) : Colors.grey),
                          if (isSelected) ...[ const SizedBox(width: 6), Text(t(cat['id']), style: TextStyle(fontSize: 12, color: Color(cat['color']), fontWeight: FontWeight.bold)) ]
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(flex: 3, child: TextField(controller: budgetProvider.nombreGastoCtrl, decoration: InputDecoration(hintText: t('name'), border: const UnderlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(flex: 3, child: TextField(controller: budgetProvider.montoGastoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: t('amount'), border: const UnderlineInputBorder()))),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: currentMonedaGasto,
                    decoration: const InputDecoration(border: UnderlineInputBorder(), contentPadding: EdgeInsets.zero),
                    items: divisas.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) => setState(() => _monedaGastoSeleccionada = val),
                  )
                ),
                IconButton(
                  icon: const Icon(Icons.arrow_circle_up, size: 36),
                  color: Theme.of(context).colorScheme.primary,
                  onPressed: () {
                    String nombre = budgetProvider.nombreGastoCtrl.text.trim();
                    double? monto = double.tryParse(budgetProvider.montoGastoCtrl.text.trim());
                    if (nombre.isNotEmpty && monto != null && monto > 0) {
                      budgetProvider.addGasto(nombre, monto, currentMonedaGasto, _categoriaSeleccionada);
                      budgetProvider.nombreGastoCtrl.clear(); budgetProvider.montoGastoCtrl.clear();
                      HapticFeedback.lightImpact();
                    }
                  },
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  void _mostrarDialogoBoveda(BuildContext context, BudgetProvider provider, AppProvider appProvider, String Function(String) t, {String? id, bool esRetiro = false}) {
    TextEditingController amountCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(id == null ? t('create_vault') : (esRetiro ? t('withdraw') : t('add_funds'))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (id == null) TextField(controller: provider.nombreGastoCtrl, decoration: InputDecoration(labelText: t('name'))),
            TextField(
              controller: amountCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(labelText: "${id == null ? t('target') : t('amount')} (${appProvider.monedaLocal})"),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              double? amount = double.tryParse(amountCtrl.text);
              if (amount != null && amount > 0) {
                if (id == null && provider.nombreGastoCtrl.text.isNotEmpty) {
                  provider.addBoveda(provider.nombreGastoCtrl.text, amount);
                  provider.nombreGastoCtrl.clear();
                } else if (id != null) {
                  provider.gestionarBoveda(id, amount, esRetiro);
                }
                Navigator.pop(context);
              }
            },
            child: const Text('Confirmar'),
          )
        ],
      ),
    );
  }
}
