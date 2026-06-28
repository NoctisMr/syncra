// Extracto de Archivo: lib/features/shipping/presentation/views/shipping_view.dart

  Widget _buildInputSection(ShippingProvider provider, AppProvider appProvider, String Function(String) t, ThemeData theme, bool hasBg) {
    List<String> divisasDisponibles = appProvider.tasasCambio.keys.toList();

    return Card(
      elevation: 0,
      color: hasBg ? theme.colorScheme.surface.withOpacity(0.85) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant.withOpacity(0.4)),
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
                // 🌟 NUEVO: CAMPO DE PROXY FLEXIBLE
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: provider.proxyCostoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: t('proxy_fee'),
                      // Mostramos el prefijo solo si es fijo. Si es porcentaje, lo mostramos al final.
                      prefixText: provider.esProxyPorcentaje ? null : "USD ",
                      suffixText: provider.esProxyPorcentaje ? "%" : null,
                      border: const UnderlineInputBorder(),
                      // Botón para alternar
                      suffixIcon: IconButton(
                        icon: Icon(
                          provider.esProxyPorcentaje ? Icons.percent : Icons.attach_money,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        onPressed: () {
                          provider.toggleProxyType();
                          HapticFeedback.lightImpact();
                        },
                        tooltip: "Cambiar tipo de tarifa",
                      ),
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
