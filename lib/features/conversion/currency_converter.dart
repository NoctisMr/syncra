// Archivo: lib/features/conversion/currency_converter_view.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'currency_provider.dart';

class CurrencyConverterView extends StatelessWidget {
  const CurrencyConverterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CurrencyProvider(),
      child: const _CurrencyConverterBody(),
    );
  }
}

class _CurrencyConverterBody extends StatelessWidget {
  const _CurrencyConverterBody();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      // CORRECCIÓN: background está obsoleto, se usa surface
      backgroundColor: theme.colorScheme.surface, 
      appBar: AppBar(
        title: const Text('Conversor de Divisas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: provider.isLoading ? null : () => provider.loadCurrencies(),
          )
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (provider.isOffline && provider.lastUpdated != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: theme.colorScheme.errorContainer,
                    child: Row(
                      children: [
                        Icon(Icons.wifi_off_rounded, 
                             color: theme.colorScheme.onErrorContainer, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Modo sin conexión. Tasas del: ${DateFormat('dd MMM yyyy, HH:mm').format(provider.lastUpdated!)}',
                            style: TextStyle(
                              color: theme.colorScheme.onErrorContainer,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (provider.errorMessage != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        provider.errorMessage!,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.error),
                      ),
                    ),
                  ),

                if (provider.currentRates != null)
                  Expanded(
                    child: Center(
                      child: Text(
                        '¡Divisas cargadas con éxito!\n1 USD = ${provider.currentRates?['EUR']} EUR',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
