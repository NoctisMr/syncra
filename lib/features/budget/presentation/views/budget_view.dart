// lib/features/budget/presentation/views/budget_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/providers/app_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/budget_provider.dart';

class BudgetView extends StatelessWidget {
  const BudgetView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetProvider>();
    final appProvider = context.watch<AppProvider>();
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: provider.sueldoCtrl,
            decoration: InputDecoration(labelText: t('base_salary'), prefixIcon: const Icon(Icons.attach_money)),
            keyboardType: TextInputType.number,
            onChanged: (_) => provider.calcularPresupuesto(),
          ),
          const SizedBox(height: 20),
          Text("${t('net_balance')}: ${provider.balanceLocal.toStringAsFixed(2)} ${appProvider.monedaLocal}", 
               style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ...provider.gastosDelMes.map((g) => ListTile(
            title: Text(g.nombre),
            trailing: Text("-${g.montoLocal.toStringAsFixed(2)}"),
            onLongPress: () => provider.deleteGasto(g.id),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddGastoDialog(context, provider, t),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showAddGastoDialog(BuildContext context, BudgetProvider p, Function t) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: Text(t('add_expense')),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: p.nombreGastoCtrl, decoration: InputDecoration(labelText: t('name'))),
        TextField(controller: p.montoGastoCtrl, decoration: InputDecoration(labelText: t('amount')), keyboardType: TextInputType.number),
      ]),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancelar")),
        FilledButton(onPressed: () {
          p.addGasto(p.nombreGastoCtrl.text, double.tryParse(p.montoGastoCtrl.text) ?? 0, 'USD', 'Others');
          Navigator.pop(ctx);
        }, child: const Text("Guardar"))
      ],
    ));
  }
}
