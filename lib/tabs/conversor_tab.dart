import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../translations.dart';

class ConversorTab extends StatefulWidget {
  final String currentLang;
  final Map<String, double> tasasCambio;
  final NumberFormat numFormat;
  final TextEditingController convMontoCtrl;
  final String monedaDe;
  final String monedaA;
  final double resultadoConversion;
  final int ultimaActualizacionEpoch;
  final bool applySpread;
  final TextEditingController spreadCtrl;
  final Function(String, String) onMonedasChanged;
  final VoidCallback onCalcular;
  final Function(bool) onSpreadToggle;
  final Future<void> Function(TextEditingController, VoidCallback) pegarNumeros;
  final Future<void> Function(String) copiarResultado;

  const ConversorTab({
    super.key,
    required this.currentLang,
    required this.tasasCambio,
    required this.numFormat,
    required this.convMontoCtrl,
    required this.monedaDe,
    required this.monedaA,
    required this.resultadoConversion,
    required this.ultimaActualizacionEpoch,
    required this.applySpread,
    required this.spreadCtrl,
    required this.onMonedasChanged,
    required this.onCalcular,
    required this.onSpreadToggle,
    required this.pegarNumeros,
    required this.copiarResultado,
  });

  @override
  State<ConversorTab> createState() => _ConversorTabState();
}

class _ConversorTabState extends State<ConversorTab> {
  double _rotationAngle = 0.0;
  String t(String key) => i18n[widget.currentLang]?[key] ?? key;

  @override
  Widget build(BuildContext context) {
    double formulaTasa = (widget.tasasCambio[widget.monedaA] ?? 1.0) / (widget.tasasCambio[widget.monedaDe] ?? 1.0);
    
    // Evaluar si los datos tienen más de 24 horas (86,400,000 milisegundos)
    bool isOutdated = widget.ultimaActualizacionEpoch > 0 && 
                     (DateTime.now().millisecondsSinceEpoch - widget.ultimaActualizacionEpoch > 86400000);
    
    String formattedDate = widget.ultimaActualizacionEpoch == 0 
        ? "---" 
        : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(widget.ultimaActualizacionEpoch));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            color: isOutdated ? Colors.red.withOpacity(0.1) : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: isOutdated ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(isOutdated ? Icons.warning_amber_rounded : Icons.history, size: 16, color: isOutdated ? Colors.redAccent : Theme.of(context).colorScheme.onSecondaryContainer),
                  const SizedBox(width: 8),
                  Text(
                    isOutdated ? "${t('outdated_rates')} $formattedDate" : "${t('last_update')} $formattedDate",
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isOutdated ? Colors.redAccent : Theme.of(context).colorScheme.onSecondaryContainer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            elevation: 1,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(t('quick_conv'), textAlign: TextAlign.center, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: TextField(controller: widget.convMontoCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: t('amount_to_convert'), border: const OutlineInputBorder()), onChanged: (_) => widget.onCalcular())),
                      IconButton(icon: const Icon(Icons.paste), color: Theme.of(context).colorScheme.primary, onPressed: () => widget.pegarNumeros(widget.convMontoCtrl, widget.onCalcular))
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<String>(value: widget.monedaDe, items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onMonedasChanged(val!, widget.monedaA); }),
                      AnimatedRotation(
                        turns: _rotationAngle,
                        duration: const Duration(milliseconds: 300),
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz, size: 36), 
                          color: Theme.of(context).colorScheme.primary, 
                          onPressed: () { 
                            setState(() { 
                              _rotationAngle += 0.5;
                              widget.onMonedasChanged(widget.monedaA, widget.monedaDe);
                            }); 
                          }
                        ),
                      ),
                      DropdownButton<String>(value: widget.monedaA, items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onMonedasChanged(widget.monedaDe, val!); })
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // CONTROLES DE SPREAD (Comisión Bancaria)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                            onChanged: (_) => widget.onCalcular(),
                          ),
                        )
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                      child: Text("1 ${widget.monedaDe} = ${formulaTasa.toStringAsFixed(4)} ${widget.monedaA}", style: TextStyle(fontSize: 14, color: Theme.of(context).colorScheme.onSurfaceVariant)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        transitionBuilder: (Widget child, Animation<double> animation) => ScaleTransition(scale: animation, child: child),
                        child: Text("${widget.numFormat.format(widget.resultadoConversion)} ${widget.monedaA}", key: ValueKey<double>(widget.resultadoConversion), style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
                      ),
                      IconButton(icon: const Icon(Icons.copy), color: Theme.of(context).colorScheme.primary, onPressed: () => widget.copiarResultado(widget.resultadoConversion.toStringAsFixed(2)))
                    ],
                  )
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
