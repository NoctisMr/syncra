// Archivo: lib/features/shipping/presentation/views/shipping_view.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/providers/app_provider.dart';
import '../../../../core/localization/app_localizations.dart';
import '../providers/shipping_provider.dart';

class ShippingView extends StatefulWidget {
  const ShippingView({super.key});

  @override
  State<ShippingView> createState() => _ShippingViewState();
}

class _ShippingViewState extends State<ShippingView> {
  final NumberFormat _numFormat = NumberFormat('#,##0.00', 'en_US');

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    final shippingProvider = context.watch<ShippingProvider>();
    String t(String key) => AppLocalizations.translate(appProvider.language, key);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // --- FORMULARIO DE ENTRADA ---
          _buildInputSection(shippingProvider, appProvider, t),
          const SizedBox(height: 16),

          // --- DESGLOSE DE RESULTADOS (RECIBO) ---
          _buildReceiptSection(shippingProvider, appProvider, t),
          const SizedBox(height: 24),

          // --- HISTORIAL DE COTIZACIONES ---
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(t('saved_quotes'), style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
              const Icon(Icons.history, size: 20, color: Colors.grey),
            ],
          ),
          const SizedBox(height: 12),
          ...shippingProvider.cotizaciones.map((quote) => _buildQuoteCard(quote, shippingProvider, t)),
          
          if (shippingProvider.cotizaciones.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Center(
                child: Text(t('no_quotes_yet'), style: const TextStyle(color: Colors.grey)),
              ),
            ),
        ],
      ),
    );
  }

  // =========================================================================
  // MÉTODOS PRIVADOS DE CONSTRUCCIÓN VISUAL
  // =========================================================================

  Widget _buildInputSection(ShippingProvider provider, AppProvider appProvider, String Function(String) t) {
    List<String> divisasDisponibles = appProvider.tasasCambio.keys.toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Selectores de Ruta
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: t('origin'), border: const OutlineInputBorder()),
                    value: divisasDisponibles.contains(provider.origenEnvio) ? provider.origenEnvio : 'USD',
                    items: divisasDisponibles.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) => val != null ? provider.setRuta(val, provider.destinoEnvio, provider.monedaDestinoEnvio) : null,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.flight_takeoff, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: InputDecoration(labelText: t('destination'), border: const OutlineInputBorder()),
                    value: divisasDisponibles.contains(provider.destinoEnvio) ? provider.destinoEnvio : 'BRL',
                    items: divisasDisponibles.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) => val != null ? provider.setRuta(provider.origenEnvio, val, val) : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Campos Numéricos
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: provider.precioEnvioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t('item_price'),
                      prefixText: "${provider.origenEnvio} ",
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (_) => provider.calcularEnvio(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: provider.pesoEnvioCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t('weight'),
                      suffixText: "kg",
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (_) => provider.calcularEnvio(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: provider.proxyCostoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t('proxy_fee'),
                      prefixText: "USD ",
                      border: const UnderlineInputBorder(),
                    ),
                    onChanged: (_) => provider.calcularEnvio(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptSection(ShippingProvider provider, AppProvider appProvider, String Function(String) t) {
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(t('cost_breakdown'), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Divider(),
            const SizedBox(height: 8),

            // Desglose
            _buildReceiptRow(t('item_value_usd'), "\$ ${_numFormat.format(provider.valorArticuloUsd)}", isSub: true),
            _buildReceiptRow(t('freight_usd'), "+ \$ ${_numFormat.format(provider.fleteUsd)}", isSub: true),
            _buildReceiptRow(t('proxy_usd'), "+ \$ ${_numFormat.format(provider.proxyUsd)}", isSub: true),
            
            // Impuestos resaltados si aplican
            if (provider.impuestoUsd > 0)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t('customs_tax'), style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w500)),
                    Text("+ \$ ${_numFormat.format(provider.impuestoUsd)}", style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),

            const SizedBox(height: 8),
            const Divider(),
            
            // Total a Pagar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(t('total_to_pay'), style: TextStyle(fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    Text(
                      "${_numFormat.format(provider.totalEnvio)} ${provider.monedaDestinoEnvio}",
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Theme.of(context).colorScheme.primary),
                    ),
                  ],
                ),
                FilledButton.icon(
                  onPressed: provider.totalEnvio > 0 ? () {
                    provider.guardarCotizacion();
                    HapticFeedback.mediumImpact();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('quote_saved'))));
                  } : null,
                  icon: const Icon(Icons.save, size: 18),
                  label: Text(t('save')),
                  style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                )
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isSub = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: isSub ? Colors.grey.shade600 : null, fontSize: isSub ? 13 : 14)),
          Text(value, style: TextStyle(fontWeight: isSub ? FontWeight.normal : FontWeight.bold, fontSize: isSub ? 13 : 14)),
        ],
      ),
    );
  }

  Widget _buildQuoteCard(dynamic quote, ShippingProvider provider, String Function(String) t) {
    return Dismissible(
      key: Key(quote.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(12)),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) {
        provider.eliminarCotizacion(quote.id);
        HapticFeedback.lightImpact();
      },
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 4),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3)),
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).colorScheme.primaryContainer,
            child: Icon(Icons.local_shipping, color: Theme.of(context).colorScheme.onPrimaryContainer, size: 20),
          ),
          title: Text("${quote.origen} ➔ ${quote.destino}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text("${quote.peso} kg • ${DateFormat('dd MMM yy').format(quote.fecha)}", style: const TextStyle(fontSize: 12)),
          trailing: Text(
            "${_numFormat.format(quote.total)} ${quote.moneda}",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
