// Archivo: lib/features/shipping/volumetric_calculator.dart
import 'package:flutter/material.dart';

// TODO: Descomentar y ajustar la importación al nombre real de tu proyecto al configurar el pubspec
// import 'package:syncra_app/core/utils/math_helpers.dart';

class VolumetricCalculatorView extends StatefulWidget {
  const VolumetricCalculatorView({super.key});

  @override
  State<VolumetricCalculatorView> createState() => _VolumetricCalculatorViewState();
}

class _VolumetricCalculatorViewState extends State<VolumetricCalculatorView> {
  final _formKey = GlobalKey<FormState>();
  
  // Controladores para capturar las medidas en la UI
  final TextEditingController _lengthController = TextEditingController();
  final TextEditingController _widthController = TextEditingController();
  final TextEditingController _heightController = TextEditingController();
  
  double _estimatedWeight = 0.0;

  /// Ejecuta el cálculo utilizando nuestra lógica centralizada
  void _calculateWeight() {
    // Validamos que los campos no estén vacíos
    if (_formKey.currentState?.validate() ?? false) {
      final length = double.tryParse(_lengthController.text) ?? 0.0;
      final width = double.tryParse(_widthController.text) ?? 0.0;
      final height = double.tryParse(_heightController.text) ?? 0.0;

      // TODO: Implementación real usando MathHelpers (Descomentar en la fase final)
      // setState(() {
      //   _estimatedWeight = MathHelpers.calculateVolumetricWeight(
      //     length: length,
      //     width: width,
      //     height: height,
      //   );
      // });
      
      // Simulación temporal de la fórmula IATA (Divisor 5000) para visualizar el resultado en la UI
      setState(() {
        _estimatedWeight = (length * width * height) / 5000.0;
      });
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Estimador de Envíos'),
      ),
      body: Form(
        key: _formKey,
        // Layout "Zero Visual Bugs": Slivers para scroll perfecto
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildResultCard(context),
                  const SizedBox(height: 32),
                  _buildInputRow(context),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _calculateWeight,
                    icon: const Icon(Icons.calculate),
                    label: const Text('Calcular Peso Volumétrico'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta superior que muestra el resultado (Utiliza ColorScheme dinámico)
  Widget _buildResultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Peso Estimado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '${_estimatedWeight.toStringAsFixed(2)} kg',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
          ),
        ],
      ),
    );
  }

  /// Fila de campos de texto protegidos contra desbordamiento con `Expanded`
  Widget _buildInputRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: TextFormField(
            controller: _lengthController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Largo (cm)',
            ),
            validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _widthController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Ancho (cm)',
            ),
            validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: _heightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'Alto (cm)',
            ),
            validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
          ),
        ),
      ],
    );
  }
}
