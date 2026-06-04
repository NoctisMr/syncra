import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../translations.dart';

class PresupuestoTab extends StatefulWidget {
  final String currentLang;
  final Map<String, double> tasasCambio;
  final NumberFormat numFormat;
  final TextEditingController sueldoCtrl;
  final TextEditingController nombreGastoCtrl;
  final TextEditingController montoGastoCtrl;
  final List<Map<String, dynamic>> gastos;
  final String monedaLocal;
  final double balanceLocal;
  final VoidCallback onCalcular;
  final Function(Map<String, dynamic>) onGastoAdded;
  final Function(String) onGastoDeleted;
  final Function(String) onMonedaLocalChanged;
  final List<Map<String, dynamic>> categoriesConfig;
  final Future<void> Function(TextEditingController, VoidCallback) pegarNumeros;

  const PresupuestoTab({
    super.key,
    required this.currentLang,
    required this.tasasCambio,
    required this.numFormat,
    required this.sueldoCtrl,
    required this.nombreGastoCtrl,
    required this.montoGastoCtrl,
    required this.gastos,
    required this.monedaLocal,
    required this.balanceLocal,
    required this.onCalcular,
    required this.onGastoAdded,
    required this.onGastoDeleted,
    required this.onMonedaLocalChanged,
    required this.categoriesConfig,
    required this.pegarNumeros,
  });

  @override
  State<PresupuestoTab> createState() => _PresupuestoTabState();
}

class _PresupuestoTabState extends State<PresupuestoTab> {
  int touhedChartIndex = -1;
  String categoriaSeleccionada = 'cat_others';

  String t(String key) => i18n[widget.currentLang]?[key] ?? key;

  List<PieChartSectionData> _generateChartSections(double sueldoTotal) {
    if (sueldoTotal == 0 && widget.gastos.isEmpty) return [];

    Map<String, double> sumasPorCategoria = {};
    for (var g in widget.gastos) {
      sumasPorCategoria[g['categoria']] = (sumasPorCategoria[g['categoria']] ?? 0.0) + (g['monto'] as double);
    }

    List<PieChartSectionData> sections = [];
    int indexCounter = 0;

    sumasPorCategoria.forEach((catId, montoSumado) {
      final isTouched = indexCounter == touhedChartIndex;
      final fontSize = isTouched ? 16.0 : 12.0;
      final radius = isTouched ? 50.0 : 40.0;
      final catColor = Color(widget.categoriesConfig.firstWhere((c) => c['id'] == catId)['color']);

      sections.add(PieChartSectionData(
        color: catColor,
        value: montoSumado,
        title: sueldoTotal > 0 ? '${((montoSumado / sueldoTotal) * 100).toStringAsFixed(0)}%' : '',
        radius: radius,
        titleStyle: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold, color: Colors.white),
      ));
      indexCounter++;
    });

    if (widget.balanceLocal > 0) {
      final isTouched = indexCounter == touhedChartIndex;
      sections.add(PieChartSectionData(
        color: Theme.of(context).colorScheme.primaryContainer,
        value: widget.balanceLocal,
        title: t('available'),
        radius: isTouched ? 50.0 : 40.0,
        titleStyle: TextStyle(fontSize: isTouched ? 14 : 11, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer),
      ));
    }
    return sections;
  }

  @override
  Widget build(BuildContext context) {
    double sueldo = double.tryParse(widget.sueldoCtrl.text) ?? 0.0;
    bool hasData = sueldo > 0 || widget.gastos.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('local_curr'), style: const TextStyle(fontWeight: FontWeight.bold)),
                      DropdownButton<String>(
                        value: widget.monedaLocal,
                        items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (val) { widget.onMonedaLocalChanged(val!); },
                      )
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.sueldoCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t('base_salary'), border: const OutlineInputBorder()),
                  onChanged: (_) => widget.onCalcular(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.paste), 
                color: Theme.of(context).colorScheme.primary, 
                onPressed: () => widget.pegarNumeros(widget.sueldoCtrl, widget.onCalcular)
              )
            ],
          ),
          const SizedBox(height: 20),
          if (hasData)
            SizedBox(
              height: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  PieChart(
                    PieChartData(
                      pieTouchData: PieTouchData(
                        touchCallback: (FlTouchEvent event, pieTouchResponse) {
                          setState(() {
                            if (!event.isInterestedForInteractions || pieTouchResponse == null || pieTouchResponse.touchedSection == null) {
                              touhedChartIndex = -1;
                              return;
                            }
                            touhedChartIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                          });
                        },
                      ),
                      borderData: FlBorderData(show: false),
                      sectionsSpace: 3,
                      centerSpaceRadius: 60,
                      sections: _generateChartSections(sueldo),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(t('net_balance'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      Text(
                        widget.numFormat.format(widget.balanceLocal),
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: widget.balanceLocal >= 0 ? Theme.of(context).colorScheme.primary : Colors.red),
                      ),
                      Text(widget.monedaLocal, style: const TextStyle(fontSize: 10)),
                    ],
                  )
                ],
              ),
            ),
          const SizedBox(height: 16),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(t('add_expense'), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: widget.categoriesConfig.map((cat) {
                        bool isSelected = categoriaSeleccionada == cat['id'];
                        return GestureDetector(
                          onTap: () => setState(() => categoriaSeleccionada = cat['id']),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(cat['color']).withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: isSelected ? Color(cat['color']) : Colors.grey.withOpacity(0.3)),
                            ),
                            child: Row(
                              children: [
                                Icon(cat['icon'], size: 16, color: Color(cat['color'])),
                                if (isSelected) ...[
                                  const SizedBox(width: 4),
                                  Text(t(cat['id']), style: TextStyle(fontSize: 12, color: Color(cat['color']), fontWeight: FontWeight.bold))
                                ]
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: widget.nombreGastoCtrl, decoration: InputDecoration(hintText: t('name'), border: const UnderlineInputBorder()))),
                      const SizedBox(width: 8),
                      Expanded(child: TextField(controller: widget.montoGastoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(hintText: t('amount'), border: const UnderlineInputBorder()))),
                      IconButton(
                        icon: const Icon(Icons.add_circle, size: 36),
                        color: Theme.of(context).colorScheme.primary,
                        onPressed: () {
                          String nombre = widget.nombreGastoCtrl.text.trim();
                          double? monto = double.tryParse(widget.montoGastoCtrl.text.trim());
                          if (nombre.isNotEmpty && monto != null && monto > 0) {
                            widget.onGastoAdded({
                              'id': DateTime.now().millisecondsSinceEpoch.toString(),
                              'nombre': nombre,
                              'monto': monto,
                              'categoria': categoriaSeleccionada
                            });
                            widget.nombreGastoCtrl.clear();
                            widget.montoGastoCtrl.clear();
                          }
                        },
                      )
                    ],
                  )
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          ...widget.gastos.map((gasto) {
            final catConfig = widget.categoriesConfig.firstWhere((c) => c['id'] == gasto['categoria'], orElse: () => widget.categoriesConfig.last);
            return Dismissible(
              key: Key(gasto['id']),
              direction: DismissDirection.endToStart,
              background: Container(
                margin: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              onDismissed: (direction) {
                widget.onGastoDeleted(gasto['id']);
                HapticFeedback.mediumImpact();
              },
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 4),
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                elevation: 0,
                child: ListTile(
                  leading: CircleAvatar(backgroundColor: Color(catConfig['color']).withOpacity(0.2), child: Icon(catConfig['icon'], color: Color(catConfig['color']), size: 20)),
                  title: Text(gasto['nombre'], style: const TextStyle(fontWeight: FontWeight.w500)),
                  subtitle: Text(t(gasto['categoria']), style: const TextStyle(fontSize: 11)),
                  trailing: Text("${widget.numFormat.format(gasto['monto'])} ${widget.monedaLocal}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
