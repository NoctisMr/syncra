import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
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
  final Function(double, String) onProcessCart;
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
    required this.onProcessCart,
    required this.pegarNumeros,
    required this.copiarResultado,
  });

  @override
  State<ConversorTab> createState() => _ConversorTabState();
}

class _ConversorTabState extends State<ConversorTab> {
  double _rotationAngle = 0.0;
  double _carritoTotal = 0.0;
  bool _isScanning = false;

  String t(String key) => i18n[widget.currentLang]?[key] ?? key;

  Future<void> _escanearPrecio() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera);

    if (image != null) {
      setState(() => _isScanning = true);
      try {
        final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
        final RecognizedText recognizedText = await textRecognizer.processImage(InputImage.fromFilePath(image.path));
        
        // RegEx para buscar patrones de precio (ej. 1500, 1,500.50, 1.500,00)
        RegExp exp = RegExp(r'(\d{1,3}(?:[.,]\d{3})*(?:[.,]\d+)?)');
        List<double> preciosEncontrados = [];

        for (TextBlock block in recognizedText.blocks) {
          for (TextLine line in block.lines) {
            final match = exp.firstMatch(line.text);
            if (match != null) {
              String numStr = match.group(0)!.replaceAll(',', '');
              double? val = double.tryParse(numStr);
              if (val != null && val > 0) preciosEncontrados.add(val);
            }
          }
        }
        
        textRecognizer.close();

        if (preciosEncontrados.isNotEmpty) {
          double mayorPrecio = preciosEncontrados.reduce((curr, next) => curr > next ? curr : next);
          _mostrarConfirmacionEscaneo(mayorPrecio);
        } else {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t('no_price_found'))));
        }
      } catch (e) {
        debugPrint("Error OCR: $e");
      }
      setState(() => _isScanning = false);
    }
  }

  void _mostrarConfirmacionEscaneo(double precioDetectado) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Precio Detectado'),
        content: Text("Se detectó el valor: ${widget.numFormat.format(precioDetectado)} ${widget.monedaDe}\n¿Sumar al carrito?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          FilledButton(
            onPressed: () {
              setState(() {
                _carritoTotal += precioDetectado;
                widget.convMontoCtrl.text = _carritoTotal.toStringAsFixed(2);
                widget.onCalcular();
              });
              Navigator.pop(context);
            },
            child: const Text('Sumar'),
          )
        ],
      ),
    );
  }

  void _enrutarCarrito() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(t('purchase_type'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(Icons.storefront, color: Colors.blue),
                title: Text(t('physical')),
                onTap: () {
                  Navigator.pop(context);
                  widget.onProcessCart(_carritoTotal, 'Fisica');
                  setState(() => _carritoTotal = 0.0);
                },
              ),
              ListTile(
                leading: const Icon(Icons.flight_takeoff, color: Colors.orange),
                title: Text(t('shipping_type')),
                onTap: () {
                  Navigator.pop(context);
                  widget.onProcessCart(_carritoTotal, 'Envio');
                  setState(() => _carritoTotal = 0.0);
                },
              )
            ],
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    double formulaTasa = (widget.tasasCambio[widget.monedaA] ?? 1.0) / (widget.tasasCambio[widget.monedaDe] ?? 1.0);
    bool isOutdated = widget.ultimaActualizacionEpoch > 0 && (DateTime.now().millisecondsSinceEpoch - widget.ultimaActualizacionEpoch > 86400000);
    String formattedDate = widget.ultimaActualizacionEpoch == 0 ? "---" : DateFormat('dd/MM/yyyy HH:mm').format(DateTime.fromMillisecondsSinceEpoch(widget.ultimaActualizacionEpoch));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Card(
            color: isOutdated ? Colors.red.withOpacity(0.1) : Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.4),
            elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isOutdated ? Colors.redAccent.withOpacity(0.5) : Colors.transparent)),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t('quick_conv'), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onSurface)),
                      FilledButton.icon(
                        onPressed: _isScanning ? null : _escanearPrecio,
                        icon: _isScanning ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.camera_alt),
                        label: Text(t('scan_price')),
                        style: FilledButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.tertiary),
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: widget.convMontoCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          decoration: InputDecoration(labelText: t('amount_to_convert'), border: const OutlineInputBorder()),
                          onChanged: (_) {
                            widget.onCalcular();
                            setState(() => _carritoTotal = double.tryParse(widget.convMontoCtrl.text) ?? 0.0);
                          }
                        ),
                      ),
                      IconButton(icon: const Icon(Icons.paste), color: Theme.of(context).colorScheme.primary, onPressed: () => widget.pegarNumeros(widget.convMontoCtrl, widget.onCalcular))
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      DropdownButton<String>(value: widget.monedaDe, items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onMonedasChanged(val!, widget.monedaA); }),
                      AnimatedRotation(
                        turns: _rotationAngle, duration: const Duration(milliseconds: 300),
                        child: IconButton(icon: const Icon(Icons.swap_horiz, size: 36), color: Theme.of(context).colorScheme.primary, onPressed: () { setState(() { _rotationAngle += 0.5; widget.onMonedasChanged(widget.monedaA, widget.monedaDe); }); }),
                      ),
                      DropdownButton<String>(value: widget.monedaA, items: widget.tasasCambio.keys.map((val) => DropdownMenuItem(value: val, child: Text(val))).toList(), onChanged: (val) { widget.onMonedasChanged(widget.monedaDe, val!); })
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(border: Border.all(color: Theme.of(context).colorScheme.outlineVariant), borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Checkbox(value: widget.applySpread, onChanged: (val) => widget.onSpreadToggle(val ?? false)),
                        Text(t('apply_fee'), style: const TextStyle(fontSize: 12)),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(controller: widget.spreadCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), enabled: widget.applySpread, decoration: InputDecoration(labelText: t('bank_fee'), border: InputBorder.none), onChanged: (_) => widget.onCalcular()))
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
                  ),
                  if (_carritoTotal > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: FilledButton.tonalIcon(
                        onPressed: _enrutarCarrito,
                        icon: const Icon(Icons.shopping_cart_checkout),
                        label: Text("${t('process_cart')} (${widget.monedaDe})"),
                      ),
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
