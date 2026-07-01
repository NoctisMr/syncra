// lib/features/shipping/presentation/views/shipping_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/shipping_provider.dart';

class ShippingView extends StatelessWidget {
  const ShippingView({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ShippingProvider>();
    return Column(children: [
      TextField(controller: p.precioEnvioCtrl, decoration: const InputDecoration(labelText: "Precio"), onChanged: (_) => p.calcularEnvio()),
      TextField(controller: p.pesoEnvioCtrl, decoration: const InputDecoration(labelText: "Peso (kg)"), onChanged: (_) => p.calcularEnvio()),
      Text("Total: ${p.totalEnvio.toStringAsFixed(2)}"),
      ElevatedButton(onPressed: () => p.guardarCotizacion("USA", "Destino", "USD"), child: const Text("Guardar Cotización")),
      Expanded(child: ListView.builder(itemCount: p.cotizaciones.length, itemBuilder: (c, i) => ListTile(title: Text(p.cotizaciones[i].total.toString()))))
    ]);
  }
}
