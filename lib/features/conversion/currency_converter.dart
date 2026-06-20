// Archivo: lib/features/conversion/currency_converter.dart
import 'package:flutter/material.dart';

class CurrencyConverterView extends StatefulWidget {
  const CurrencyConverterView({super.key});

  @override
  State<CurrencyConverterView> createState() => _CurrencyConverterViewState();
}

class _CurrencyConverterViewState extends State<CurrencyConverterView> {
  final TextEditingController _amountController = TextEditingController();
  
  double _convertedAmount = 0.0;
  String _selectedFromCurrency = 'USD';
  String _selectedToCurrency = 'EUR';

  // Tasas de cambio simuladas (En producción, podrías conectarlo a una API REST)
  final Map<String, double> _exchangeRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'MXN': 17.05,
    'COP': 3900.0,
    'ARS': 850.0,
  };

  /// Ejecuta el cálculo de conversión
  void _convertCurrency() {
    final baseAmount = double.tryParse(_amountController.text) ?? 0.0;
    
    final rateFrom = _exchangeRates[_selectedFromCurrency] ?? 1.0;
    final rateTo = _exchangeRates[_selectedToCurrency] ?? 1.0;

    setState(() {
      // Convertimos primero a la moneda base (USD) y luego a la moneda destino
      final amountInBase = baseAmount / rateFrom;
      _convertedAmount = amountInBase * rateTo;
    });
  }

  /// Intercambia las divisas seleccionadas
  void _swapCurrencies() {
    setState(() {
      final temp = _selectedFromCurrency;
      _selectedFromCurrency = _selectedToCurrency;
      _selectedToCurrency = temp;
      _convertCurrency();
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversor de Divisas'),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(24.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildResultCard(context),
                const SizedBox(height: 32),
                _buildConversionControls(context),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: _convertCurrency,
                  icon: const Icon(Icons.currency_exchange),
                  label: const Text('Convertir'),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  /// Tarjeta superior que muestra el resultado de la conversión
  Widget _buildResultCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        // Uso de colores secundarios del token dinámico de Material 3
        color: Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.outlineVariant,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Monto Convertido',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
          ),
          const SizedBox(height: 16),
          Text(
            '$_convertedAmount $_selectedToCurrency',
            style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSecondaryContainer,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  /// Fila de controles interactivos sin desbordamientos visuales
  Widget _buildConversionControls(BuildContext context) {
    return Column(
      children: [
        TextFormField(
          controller: _amountController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Monto a Convertir',
            prefixIcon: Icon(Icons.numbers),
          ),
          onChanged: (_) => _convertCurrency(),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _buildCurrencyDropdown(
                value: _selectedFromCurrency,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedFromCurrency = newValue);
                    _convertCurrency();
                  }
                },
              ),
            ),
            IconButton(
              onPressed: _swapCurrencies,
              icon: const Icon(Icons.swap_horiz),
              color: Theme.of(context).colorScheme.primary,
              iconSize: 32,
            ),
            Expanded(
              child: _buildCurrencyDropdown(
                value: _selectedToCurrency,
                onChanged: (String? newValue) {
                  if (newValue != null) {
                    setState(() => _selectedToCurrency = newValue);
                    _convertCurrency();
                  }
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// Dropdown estilizado para seleccionar las divisas
  Widget _buildCurrencyDropdown({
    required String value,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: const InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      items: _exchangeRates.keys.map((String currency) {
        return DropdownMenuItem(
          value: currency,
          child: Text(currency),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }
}
