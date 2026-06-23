// Archivo: lib/features/converter/presentation/views/converter_view.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/app_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/ui_helpers.dart';
import '../providers/converter_provider.dart';
import '../../budget/presentation/providers/budget_provider.dart';
import '../../shipping/presentation/providers/shipping_provider.dart';

class ConverterView extends StatefulWidget {
  const ConverterView({super.key});

  @override
  State<ConverterView> createState() => _ConverterViewState();
}

class _ConverterViewState extends State<ConverterView> {
  double _rotationAngle = 0.0;
  final NumberFormat _numFormat = NumberFormat('#,##0.00', 'en_US');

  // =========================================================================
  // FLUJO DEL ESCÁNER OCR (Separado para mantener el build limpio)
  // =========================================================================

  Future<void> _iniciarEscaneo(ConverterProvider converterProvider, String Function(String) t) async {
    // Llamamos a la lógica limpia del Provider
    final double? precioDetectado = await converterProvider.escanearPrecioDesdeCamara();

    if (precioDetectado != null && mounted) {
      _mostrarConfirmacionEscaneo(precioDetectado, converterProvider, t);
    } else if (precioDetectado == null && !converterProvider.isScanning && mounted) {
      // Si devolvió null y no está cargando, significa que no encontró números claros
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('no_price_found'))),
      );
    }
  }

  void _mostrarConfirmacionEscaneo(double precioDetectado, ConverterProvider provider, String Function(String) t) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Precio Detectado', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          "Se detectó el valor:\n\n${_numFormat.format(precioDetectado)} ${provider.monedaDe}\n\n¿Deseas sumarlo al carrito temporal?",
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              provider.sumarAlCarrito(precioDetectado);
              Navigator.pop(context);
            },
            child: const Text('Sumar'),
          )
        ],
      ),
    );
  }

  void _enrutarCarrito(ConverterProvider converterProvider, String Function(String) t) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('purchase_type'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.blue.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.storefront, color: Colors.blue),
                ),
                title: Text(t('physical'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Llevar este valor a mis Gastos de Presupuesto'),
                onTap: () {
                  Navigator.pop(context);
                  // Inyectamos el valor en el módulo de presupuesto
                  context.read<BudgetProvider>().montoGastoCtrl.text = converterProvider.carritoTotal.toStringAsFixed(2);
                  converterProvider.limpiarCarrito();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valor enviado a Presupuesto. ¡Añade un nombre y guárdalo!')));
                },
              ),
              const Divider(),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.flight_takeoff, color: Colors.orange),
                ),
                title: Text(t('shipping_type'), style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: const Text('Llevar este valor a la Calculadora de Aduanas'),
                onTap: () {
                  Navigator.pop(context);
                  // Opcional: Si el módulo de envíos ya existe, inyectar el valor allí.
                  // context.read<ShippingProvider>().setPrecioBase(converterProvider.carritoTotal);
                  converterProvider.limpiarCarrito();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Valor enviado a Envíos (Función próxima a enlazar)')));
                },
              )
            ],
          ),
        );
      }
    );
  }

  // =========================================================================
  // CONSTRUCCIÓN DE LA INTERFAZ VISUAL
  // =========================================================================

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final converterProvider = context.watch<ConverterProvider>();
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    // Cálculos para el banner de advertencia de tasas de internet
    double formulaTasa = (appProvider.tasasCambio[converterProvider.monedaA] ?? 1.0) / (appProvider.tasasCambio[converterProvider.monedaDe] ?? 1.0);
    bool isOutdated = appProvider.ultimaActualizacionEpoch > 0 && 
                     (DateTime.now().millisecondsSinceEpoch - appProvider.ultimaActualizacionEpoch > 86400000);
    String formattedDate = appProvider.ultimaActualizacionEpoch == 0 
        ? "---" 
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(appProvider.ultimaActualizacionEpoch));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          // --- BANNER DE ESTADO DE CONEXIÓN ---
          Card(
            color: isOutdated ? Colors.red.withOpacity(0.1) : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12), 
              side: BorderSide(color: isOutdated ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOutdated ? Icons.warning_amber_rounded : Icons.history, 
                    size: 18, 
                    color: isOutdated ? Colors.redAccent : Theme.of(context).colorScheme.onSecondaryContainer
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isOutdated ? "${t('outdated_rates')} $formattedDate" : "${t('last_update')} $formattedDate",
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isOutdated ? Colors.redAccent : Theme.of(context).colorScheme.onSecondaryContainer),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // --- TARJETA PRINCIPAL DEL CONVERSOR ---
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4))
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Cabecera y Botón OCR
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('quick_conv'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      FilledButton.icon(
                        onPressed: converterProvider.isScanning ? null : () => _iniciarEscaneo(converterProvider, t),
                        icon: converterProvider.isScanning 
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) 
                            : const Icon(Icons.camera_alt, size: 18),
                        label: Text(converterProvider.isScanning ? t('reading_text') : t('scan_price')),
                        style: FilledButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.tertiary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Input de Monto y Pegar
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: converterProvider.convMontoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            labelText: t('amount_to_convert'), 
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          ),
                          onChanged: (_) => converterProvider.calcularConversion(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, borderRadius: BorderRadius.circular(12)),
                        child: IconButton(
                          icon: const Icon(Icons.paste), 
                          color: Theme.of(context).colorScheme.onPrimaryContainer, 
                          onPressed: () => UiHelpers.pasteNumbersFromClipboard(
                            converterProvider.convMontoCtrl, 
                            onDone: converterProvider.calcularConversion
                          )
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Selectores de Monedas y Botón Giratorio de Intercambio
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        DropdownButton<String>(
                          underline: const SizedBox(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          value: converterProvider.monedaDe, 
                          items: appProvider.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), 
                          onChanged: (val) { if(val != null) converterProvider.setMonedas(val, converterProvider.monedaA); }
                        ),
                        AnimatedRotation(
                          turns: _rotationAngle, 
                          duration: const Duration(milliseconds: 300),
                          child: IconButton(
                            icon: const Icon(Icons.swap_horizontal_circle, size: 40), 
                            color: Theme.of(context).colorScheme.primary, 
                            onPressed: () { 
                              setState(() => _rotationAngle += 0.5); 
                              converterProvider.setMonedas(converterProvider.monedaA, converterProvider.monedaDe); 
                            }
                          ),
                        ),
                        DropdownButton<String>(
                          underline: const SizedBox(),
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface),
                          value: converterProvider.monedaA, 
                          items: appProvider.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), 
                          onChanged: (val) { if(val != null) converterProvider.setMonedas(converterProvider.monedaDe, val); }
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Spread Bancario (Comisiones)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), 
                      borderRadius: BorderRadius.circular(12)
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: converterProvider.applySpread, 
                          onChanged: (val) => converterProvider.toggleSpread(val ?? false),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                        ),
                        Text(t('apply_fee'), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: converterProvider.spreadCtrl, 
                            keyboardType: const TextInputType.numberWithOptions(decimal: true), 
                            enabled: converterProvider.applySpread, 
                            decoration: InputDecoration(labelText: t('bank_fee'), border: InputBorder.none, isDense: true), 
                            onChanged: (_) => converterProvider.calcularConversion()
                          )
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Fórmula base estática
                  Center(
                    child: Text(
                      "1 ${converterProvider.monedaDe} = ${formulaTasa.toStringAsFixed(4)} ${converterProvider.monedaA}", 
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurfaceVariant)
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Resultado Final Gigante
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
                          child: Text(
                            "${_numFormat.format(converterProvider.resultadoConversion)} ${converterProvider.monedaA}", 
                            key: ValueKey<double>(converterProvider.resultadoConversion), 
                            style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy), 
                        color: Theme.of(context).colorScheme.primary, 
                        onPressed: () => UiHelpers.copyToClipboard(context, converterProvider.resultadoConversion.toStringAsFixed(2), t('copied'))
                      )
                    ],
                  ),
                  
                  // Botón flotante para procesar Carrito OCR si hay dinero acumulado
                  if (converterProvider.carritoTotal > 0) ...[
                    const SizedBox(height: 24),
                    FilledButton.tonalIcon(
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))
                      ),
                      onPressed: () => _enrutarCarrito(converterProvider, t),
                      icon: const Icon(Icons.shopping_cart_checkout),
                      label: Text("${t('process_cart')} (${_numFormat.format(converterProvider.carritoTotal)} ${converterProvider.monedaDe})"),
                    ),
                    TextButton(
                      onPressed: converterProvider.limpiarCarrito, 
                      child: const Text('Vaciar carrito', style: TextStyle(color: Colors.redAccent))
                    )
                  ]
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
