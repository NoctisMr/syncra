// Archivo: lib/features/converter/presentation/views/converter_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/app_provider.dart';
import '../providers/converter_provider.dart';

// --- CORRECCIÓN: IMPORTACIONES ABSOLUTAS (A prueba de fallos en compilación) ---
import 'package:global_wallet_shipping/features/budget/presentation/providers/budget_provider.dart';
import 'package:global_wallet_shipping/features/shipping/presentation/providers/shipping_provider.dart';

class ConverterView extends StatelessWidget {
  const ConverterView({super.key});

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final converterProvider = context.watch<ConverterProvider>();
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- TARJETA DE RESULTADO TOTAL ---
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Text(t('total_converted') ?? 'Total Escaneado', style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      "${converterProvider.carritoTotal.toStringAsFixed(2)} USD",
                      style: TextStyle(
                        fontSize: 36, 
                        fontWeight: FontWeight.w900,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // --- BOTONES DE ENLACE (Compartir monto con otras pestañas) ---
            Row(
              children: [
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // Esta línea ahora funciona correctamente gracias a la ruta absoluta
                      context.read<BudgetProvider>().montoGastoCtrl.text = converterProvider.carritoTotal.toStringAsFixed(2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('sent_to_budget') ?? 'Enviado al Presupuesto')),
                      );
                    },
                    icon: const Icon(Icons.account_balance_wallet, size: 18),
                    label: Text(t('to_budget') ?? 'Presupuesto', style: const TextStyle(fontSize: 13)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () {
                      // Esta línea ahora funciona correctamente gracias a la ruta absoluta
                      context.read<ShippingProvider>().precioEnvioCtrl.text = converterProvider.carritoTotal.toStringAsFixed(2);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(t('sent_to_shipping') ?? 'Enviado a Aduanas')),
                      );
                    },
                    icon: const Icon(Icons.local_shipping, size: 18),
                    label: Text(t('to_shipping') ?? 'Aduanas', style: const TextStyle(fontSize: 13)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // --- ESTADO DE ESCANEO / LISTA DE ITEMS ---
            Expanded(
              child: converterProvider.isScanning
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                      itemCount: converterProvider.scannedItems.length,
                      itemBuilder: (context, index) {
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: const Icon(Icons.document_scanner_outlined),
                            title: Text(converterProvider.scannedItems[index]),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => converterProvider.scanImage(),
        icon: const Icon(Icons.camera_alt),
        label: Text(t('scan_receipt') ?? 'Escanear Recibo'),
      ),
    );
  }
}
