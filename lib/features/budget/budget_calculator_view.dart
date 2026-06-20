// Archivo: lib/features/budget/budget_calculator_view.dart
import 'package:flutter/material.dart';

// TODO: Ajustar la importación según el nombre real de tu proyecto en el pubspec
// import 'package:syncra_app/core/utils/math_helpers.dart';

class BudgetCalculatorView extends StatefulWidget {
  const BudgetCalculatorView({super.key});

  @override
  State<BudgetCalculatorView> createState() => _BudgetCalculatorViewState();
}

class _BudgetCalculatorViewState extends State<BudgetCalculatorView> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para capturar los valores financieros
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _taxController = TextEditingController();
  final TextEditingController _shippingController = TextEditingController();

  double _totalBudget = 0.0;
  double _calculatedTax = 0.0;

  /// Ejecuta el cálculo del presupuesto total
  void _calculateBudget() {
    if (_formKey.currentState?.validate() ?? false) {
      final basePrice = double.tryParse(_priceController.text) ?? 0.0;
      final taxPercentage = double.tryParse(_taxController.text) ?? 0.0;
      final shippingCost = double.tryParse(_shippingController.text) ?? 0.0;

      setState(() {
        // TODO: Integrar con MathHelpers.calculatePercentage en la fase final
        // _calculatedTax = MathHelpers.calculatePercentage(basePrice, taxPercentage);
        
        // Cálculo local temporal para simular el desglose en la UI
        _calculatedTax = (basePrice * taxPercentage) / 100;
        _totalBudget = basePrice + _calculatedTax + shippingCost;
      });
    }
  }

  @override
  void dispose() {
    _priceController.dispose();
    _taxController.dispose();
    _shippingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de Presupuesto'),
      ),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(24.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummaryCard(context),
                  const SizedBox(height: 32),
                  _buildInputFields(),
                  const SizedBox(height: 32),
                  ElevatedButton.icon(
                    onPressed: _calculateBudget,
                    icon: const Icon(Icons.calculate_outlined),
                    label: const Text('Calcular Total'),
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Tarjeta de resumen que utiliza los tonos terciarios de Material 3
  Widget _buildSummaryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Presupuesto Total Estimado',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '\$${_totalBudget.toStringAsFixed(2)}',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Impuestos estimados:',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
              Text(
                '\$${_calculatedTax.toStringAsFixed(2)}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onTertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Construye el formulario con validaciones y adaptabilidad visual
  Widget _buildInputFields() {
    return Column(
      children: [
        TextFormField(
          controller: _priceController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textInputAction: TextInputAction.next,
          decoration: const InputDecoration(
            labelText: 'Precio Base del Objeto (\$)',
            prefixIcon: Icon(Icons.attach_money),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Requerido' : null,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _taxController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Impuestos (%)',
                  prefixIcon: Icon(Icons.percent),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextFormField(
                controller: _shippingController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.done,
                decoration: const InputDecoration(
                  labelText: 'Costo Envío (\$)',
                  prefixIcon: Icon(Icons.local_shipping_outlined),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
