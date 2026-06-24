// Archivo: lib/features/converter/presentation/views/converter_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/app_provider.dart';
import '../providers/converter_provider.dart';
import 'package:global_wallet_shipping/features/budget/presentation/providers/budget_provider.dart';
import 'package:global_wallet_shipping/features/shipping/presentation/providers/shipping_provider.dart';

class ConverterView extends StatefulWidget {
  const ConverterView({super.key});

  @override
  State<ConverterView> createState() => _ConverterViewState();
}

class _ConverterViewState extends State<ConverterView> {
  final TextEditingController _amountCtrl = TextEditingController();
  final TextEditingController _feeCtrl = TextEditingController();
  String _fromCurr = 'USD';
  String _toCurr = 'BRL';

  @override
  void dispose() {
    _amountCtrl.dispose();
    _feeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final converterProvider = context.watch<ConverterProvider>();
    final theme = Theme.of(context);
    
    // 🌟 DETECCIÓN DE FONDO
    final bool hasBg = appProvider.backgroundImagePath != null;
    
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    List<String> currencies = appProvider.tasasCambio.keys.toList();
    if (!currencies.contains(_fromCurr) && currencies.isNotEmpty) _fromCurr = currencies.first;
    if (!currencies.contains(_toCurr) && currencies.isNotEmpty) _toCurr = currencies.first;

    double amount = double.tryParse(_amountCtrl.text.replaceAll(',', '.')) ?? 0.0;
    double fee = double.tryParse(_feeCtrl.text.replaceAll(',', '.')) ?? 0.0;
    double rateFrom = (appProvider.tasasCambio[_fromCurr] ?? 1.0).toDouble();
    double rateTo = (appProvider.tasasCambio[_toCurr] ?? 1.0).toDouble();

    double baseConverted = (amount / rateFrom) * rateTo;
    double finalConverted = baseConverted + (baseConverted * (fee / 100));

    return Scaffold(
      backgroundColor: Colors.transparent, // Permite ver el fondo
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ==========================================
            // SECCIÓN 1: CONVERSIÓN MANUAL CLÁSICA
            // ==========================================
            Text(t('quick_conv') ?? 'Conversión Rápida', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : theme.colorScheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _amountCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: t('amount_to_convert') ?? 'Monto',
                              border: const UnderlineInputBorder(),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _fromCurr,
                            decoration: const InputDecoration(labelText: 'De'),
                            items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _fromCurr = val!),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_outlined, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 1,
                          child: DropdownButtonFormField<String>(
                            value: _toCurr,
                            decoration: const InputDecoration(labelText: 'A'),
                            items: currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) => setState(() => _toCurr = val!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _feeCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: t('bank_fee') ?? 'Comisión Bancaria (%)',
                        border: const UnderlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "${finalConverted.toStringAsFixed(2)} $_toCurr",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // ==========================================
            // SECCIÓN 2: ESCÁNER OCR INTELIGENTE
            // ==========================================
            Text(t('scan_price') ?? 'Escanear Recibo', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
            const SizedBox(height: 8),
            Card(
              elevation: 0,
              color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : theme.colorScheme.secondaryContainer.withOpacity(0.3),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Text(t('total_converted') ?? 'Total Escaneado', style: const TextStyle(fontSize: 14)),
                    const SizedBox(height: 8),
                    Text(
                      "${converterProvider.carritoTotal.toStringAsFixed(2)} USD",
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: converterProvider.carritoTotal > 0 ? () {
                              context.read<BudgetProvider>().montoGastoCtrl.text = converterProvider.carritoTotal.toStringAsFixed(2);
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('to_budget') ?? 'Enviado')));
                            } : null,
                            icon: const Icon(Icons.account_balance_wallet, size: 16),
                            label: Text(t('to_budget') ?? 'Presupuesto', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            onPressed: converterProvider.carritoTotal > 0 ? () {
                              context.read<ShippingProvider>().precioEnvioCtrl.text = converterProvider.carritoTotal.toStringAsFixed(2);
                              context.read<ShippingProvider>().calcularEnvio();
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('to_shipping') ?? 'Enviado')));
                            } : null,
                            icon: const Icon(Icons.local_shipping, size: 16),
                            label: Text(t('to_shipping') ?? 'Aduanas', style: const TextStyle(fontSize: 12)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Lista de items escaneados (Feedback Visual)
            if (converterProvider.isScanning)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else
              ...converterProvider.scannedItems.map((item) => Card(
                color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : theme.colorScheme.surface,
                margin: const EdgeInsets.only(bottom: 4),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.document_scanner_outlined, size: 18),
                  title: Text(item, style: const TextStyle(fontSize: 13)),
                ),
              )),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => converterProvider.scanImage(),
        icon: const Icon(Icons.camera_alt),
        label: Text(t('scan_receipt') ?? 'Escanear'),
      ),
    );
  }
}
