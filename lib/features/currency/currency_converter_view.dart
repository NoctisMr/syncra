import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'currency_provider.dart';

class CurrencyConverterView extends StatelessWidget {
  const CurrencyConverterView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Envuelve tu vista principal en ChangeNotifierProvider si no lo has hecho globalmente
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
      backgroundColor: theme.colorScheme.background,
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
                // === BANNER DE MODO OFFLINE ===
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

                // Manejo de error si es la primera vez y no hay internet
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

                // Aquí iría el resto de tu UI (TextFields de conversión, listas, etc.)
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
