import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../translations.dart';

class EnviosTab extends StatefulWidget {
  final String currentLang;
  final Map<String, double> tasasCambio;
  final NumberFormat numFormat;
  final TextEditingController precioEnvioCtrl;
  final TextEditingController pesoEnvioCtrl;
  final TextEditingController proxyCostoCtrl;
  final String monedaProxy;
  final String origenEnvio;
  final String destinoEnvio;
  final String monedaOrigenEnvio;
  final String monedaDestinoEnvio;
  final String desgloseEnvio;
  final double totalEnvio;
  
  final bool applySpread;
  final TextEditingController spreadCtrl;
  final List<Map<String, dynamic>> cotizaciones;
  final Function(bool) onSpreadToggle;
  final VoidCallback onGuardarCotizacion;
  final Function(String) onEliminarCotizacion;

  final Function({
    String? monedaProxy,
    String? origenEnvio,
    String? destinoEnvio,
    String? monedaOrigenEnvio,
    String? monedaDestinoEnvio,
  }) onParametrosChanged;
  final Future<void> Function(String) copiarResultado;

  const EnviosTab({
    super.key,
    required this.currentLang,
    required this.tasasCambio,
    required this.numFormat,
    required this.precioEnvioCtrl,
    required this.pesoEnvioCtrl,
    required this.proxyCostoCtrl,
    required this.monedaProxy,
    required this.origenEnvio,
    required this.destinoEnvio,
    required this.monedaOrigenEnvio,
    required this.monedaDestinoEnvio,
    required this.desgloseEnvio,
    required this.totalEnvio,
    required this.applySpread,
    required this.spreadCtrl,
    required this.cotizaciones,
    required this.onSpreadToggle,
    required this.onGuardarCotizacion,
    required this.onEliminarCotizacion,
    required this.onParametrosChanged,
    required this.copiarResultado,
  });

  @override
  State<EnviosTab> createState() => _EnviosTabState();
}

class _EnviosTabState extends State<EnviosTab> {
  String t(String key) => i18n[widget.currentLang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('customs'), textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(flex: 4, child: TextField(controller: widget.precioEnvioCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('price'), border: const OutlineInputBorder()), onChanged: (_) => widget.onParametrosChanged())),
                      const SizedBox(width: 8),
                      Expanded(flex: 3, child: DropdownButtonFormField<String>(isExpanded: true, value: widget.monedaOrigenEnvio, decoration: const InputDecoration(border: OutlineInputBorder(), contentPadding: EdgeInsets.symmetric(horizontal: 10)), items: widget.tasasCambio.keys.map((String val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onParametrosChanged(monedaOrigenEnvio: val!); })),
                      const SizedBox(width: 8),
                      Expanded(flex: 4, child: TextField(controller: widget.pesoEnvioCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('weight'), border: const OutlineInputBorder()), onChanged: (_) => widget.onParametrosChanged())),
                    ],
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    isExpanded: true, value: widget.origenEnvio, decoration: InputDecoration(labelText: t('origin')),
                    items: ['Japón', 'China', 'EE.UU.', 'Europa', 'Nacional'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                    onChanged: (val) { widget.onParametrosChanged(origenEnvio: val!); },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(flex: 2, child: TextField(controller: widget.proxyCostoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('proxy_cost'), border: const UnderlineInputBorder()), onChanged: (_) => widget.onParametrosChanged())),
                      const SizedBox(width: 16),
                      Expanded(flex: 1, child: DropdownButton<String>(isExpanded: true, value: widget.monedaProxy, items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onParametrosChanged(monedaProxy: val!); })),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: DropdownButtonFormField<String>(
                        isExpanded: true, value: widget.destinoEnvio, decoration: InputDecoration(labelText: t('destination')),
                        items: ['Brasil', 'Perú', 'México', 'EE.UU.', 'Europa', 'Japón', 'Venezuela', 'Otros'].map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(),
                        onChanged: (val) { widget.onParametrosChanged(destinoEnvio: val!); },
                      )),
                      const SizedBox(width: 12),
                      DropdownButton<String>(value: widget.monedaDestinoEnvio, items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onParametrosChanged(monedaDestinoEnvio: val!); }),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // CONTROLES DE SPREAD
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                    decoration: BoxDecoration(
                      border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
                      borderRadius: BorderRadius.circular(8)
                    ),
                    child: Row(
                      children: [
                        Checkbox(
                          value: widget.applySpread,
                          onChanged: (val) => widget.onSpreadToggle(val ?? false),
                        ),
                        Text(t('apply_fee'), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: widget.spreadCtrl,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            enabled: widget.applySpread,
                            decoration: InputDecoration(labelText: t('bank_fee'), border: InputBorder.none),
                            onChanged: (_) => widget.onParametrosChanged(),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(widget.desgloseEnvio, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(child: Text("${widget.numFormat.format(widget.totalEnvio)} ${widget.monedaDestinoEnvio}", style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary), overflow: TextOverflow.ellipsis)),
                      IconButton(icon: const Icon(Icons.copy), color: Theme.of(context).colorScheme.primary, onPressed: () => widget.copiarResultado(widget.totalEnvio.toStringAsFixed(2)))
                    ],
                  ),
                  if (widget.totalEnvio > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: FilledButton.tonalIcon(
                        onPressed: widget.onGuardarCotizacion,
                        icon: const Icon(Icons.bookmark_add),
                        label: Text(t('save_quote')),
                      ),
                    )
                ],
              ),
            ),
          ),

          // LISTA DE COTIZACIONES GUARDADAS
          if (widget.cotizaciones.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(t('saved_quotes'), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 8),
            ...widget.cotizaciones.map((cot) {
              return Dismissible(
                key: Key(cot['id']),
                direction: DismissDirection.endToStart,
                background: Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(8)),
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  child: const Icon(Icons.delete, color: Colors.white),
                ),
                onDismissed: (_) {
                  widget.onEliminarCotizacion(cot['id']);
                  HapticFeedback.mediumImpact();
                },
                child: Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.4),
                  elevation: 0,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    title: Text("${cot['origen']} ➔ ${cot['destino']}", style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text("${cot['fecha']} • Peso: ${cot['peso']}kg"),
                    trailing: Text("${widget.numFormat.format(cot['total'])} ${cot['moneda']}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Theme.of(context).colorScheme.primary)),
                  ),
                ),
              );
            }),
          ]
        ],
      ),
    );
  }
}
