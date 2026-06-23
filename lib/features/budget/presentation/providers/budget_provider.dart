// Archivo: lib/features/budget/presentation/providers/budget_provider.dart
import 'package:flutter/material.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../../../core/config/app_config.dart';
import '../../data/models/gasto_model.dart';
import '../../data/models/vault_model.dart';

/// Gestor de estado específico para el módulo de Presupuesto.
/// Maneja la lógica de cálculos, conversión en tiempo real de gastos 
/// extranjeros y el historial de metas de ahorro (Bóvedas).
class BudgetProvider extends ChangeNotifier {
  final LocalStorageService _storage = LocalStorageService.instance;

  // --- CONTROLADORES DE INTERFAZ ---
  final TextEditingController sueldoCtrl = TextEditingController();
  final TextEditingController nombreGastoCtrl = TextEditingController();
  final TextEditingController montoGastoCtrl = TextEditingController();

  // --- ESTADO DE DATOS ---
  List<GastoModel> _gastos = [];
  List<VaultModel> _bovedas = [];
  double _balanceLocal = 0.0;
  double _balanceEq = 0.0; // Equivalente en divisa de referencia (Ej. USD)

  // --- GETTERS PÚBLICOS ---
  List<GastoModel> get gastos => _gastos;
  List<VaultModel> get bovedas => _bovedas;
  double get balanceLocal => _balanceLocal;
  double get balanceEq => _balanceEq;

  BudgetProvider() {
    _loadData();
  }

  // =========================================================================
  // CARGA Y GUARDADO DE DATOS
  // =========================================================================

  void _loadData() {
    sueldoCtrl.text = _storage.getData('sueldo', defaultValue: "");
    
    final List? gastosData = _storage.getData('gastos_v2');
    if (gastosData != null) {
      _gastos = gastosData.map((e) => GastoModel.fromMap(e)).toList();
    }

    final List? bovedasData = _storage.getData('bovedas');
    if (bovedasData != null) {
      _bovedas = bovedasData.map((e) => VaultModel.fromMap(e)).toList();
    }

    calcularPresupuesto();
  }

  void _saveData() {
    _storage.saveData('sueldo', sueldoCtrl.text);
    _storage.saveData('gastos_v2', _gastos.map((g) => g.toMap()).toList());
    _storage.saveData('bovedas', _bovedas.map((b) => b.toMap()).toList());
    notifyListeners();
  }

  // =========================================================================
  // LÓGICA DE CÁLCULO PRINCIPAL
  // =========================================================================

  /// Recalcula el balance disponible convirtiendo todos los gastos extranjeros 
  /// a la moneda local actual utilizando las tasas de cambio centralizadas.
  void calcularPresupuesto() {
    double sueldo = double.tryParse(sueldoCtrl.text) ?? 0.0;
    double totalGastosLocales = 0.0;

    // Obtener las configuraciones globales desde el almacenamiento
    final String monedaLocal = _storage.getSetting('monedaLocal', defaultValue: 'USD');
    final String monedaRef = _storage.getSetting('monedaRef', defaultValue: 'USD');
    final Map<dynamic, dynamic> tasasRaw = _storage.getData('tasasCambio', defaultValue: AppConfig.defaultExchangeRates);
    final Map<String, double> tasas = tasasRaw.map((key, value) => MapEntry(key.toString(), double.parse(value.toString())));

    // 1. Procesar Gastos (Convirtiendo si la moneda del gasto difiere de la local)
    List<GastoModel> gastosActualizados = [];
    for (var gasto in _gastos) {
      double valorEnUsd = gasto.montoOriginal / (tasas[gasto.monedaOriginal] ?? 1.0);
      double valorLocalCalculado = valorEnUsd * (tasas[monedaLocal] ?? 1.0);
      
      gastosActualizados.add(GastoModel(
        id: gasto.id,
        nombre: gasto.nombre,
        montoOriginal: gasto.montoOriginal,
        monedaOriginal: gasto.monedaOriginal,
        montoLocal: valorLocalCalculado,
        categoria: gasto.categoria,
        fecha: gasto.fecha, // Preservamos la fecha original
      ));
      
      totalGastosLocales += valorLocalCalculado;
    }
    _gastos = gastosActualizados;

    // 2. Sumar el dinero bloqueado en Bóvedas
    double totalEnBovedas = _bovedas.fold(0.0, (sum, b) => sum + b.ahorrado);

    // 3. Calcular Balances Finales
    _balanceLocal = sueldo - totalGastosLocales - totalEnBovedas;
    _balanceEq = (_balanceLocal / (tasas[monedaLocal] ?? 1.0)) * (tasas[monedaRef] ?? 1.0);

    _saveData();
  }

  // =========================================================================
  // GESTIÓN DE GASTOS
  // =========================================================================

  void addGasto(String nombre, double montoOriginal, String monedaOriginal, String categoria) {
    final nuevoGasto = GastoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      montoOriginal: montoOriginal,
      monedaOriginal: monedaOriginal,
      montoLocal: montoOriginal, // Se ajustará en calcularPresupuesto()
      categoria: categoria,
      fecha: DateTime.now(), // 🌟 Registro automático de la fecha actual
    );
    _gastos.insert(0, nuevoGasto);
    calcularPresupuesto();
  }

  void deleteGasto(String id) {
    _gastos.removeWhere((g) => g.id == id);
    calcularPresupuesto();
  }

  // =========================================================================
  // GESTIÓN DE BÓVEDAS (METAS CON HISTORIAL)
  // =========================================================================

  void addBoveda(String nombre, double objetivo) {
    final nuevaBoveda = VaultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      objetivo: objetivo,
      ahorrado: 0.0,
      historial: [], // Inicia con historial vacío
    );
    _bovedas.add(nuevaBoveda);
    calcularPresupuesto();
  }

  void deleteBoveda(String id) {
    _bovedas.removeWhere((b) => b.id == id);
    calcularPresupuesto();
  }

  /// Registra un aporte o retiro, guardando la fecha exacta en el historial de la bóveda
  void gestionarBoveda(String id, double monto, bool esRetiro) {
    int index = _bovedas.indexWhere((b) => b.id == id);
    if (index != -1) {
      VaultModel boveda = _bovedas[index];
      double nuevoAhorrado = boveda.ahorrado;

      if (esRetiro) {
        if (nuevoAhorrado >= monto) nuevoAhorrado -= monto;
      } else {
        nuevoAhorrado += monto;
      }

      // Crear el registro de la transacción con su timestamp 🌟
      final transaccion = TransactionRecord(
        monto: monto,
        fecha: DateTime.now(),
        esRetiro: esRetiro,
      );

      // Crear una copia actualizada de la bóveda
      final bovedaActualizada = VaultModel(
        id: boveda.id,
        nombre: boveda.nombre,
        objetivo: boveda.objetivo,
        ahorrado: nuevoAhorrado,
        historial: List.from(boveda.historial)..insert(0, transaccion), // Nuevo evento de primero
      );

      _bovedas[index] = bovedaActualizada;
      calcularPresupuesto();
    }
  }

  @override
  void dispose() {
    sueldoCtrl.dispose();
    nombreGastoCtrl.dispose();
    montoGastoCtrl.dispose();
    super.dispose();
  }
}
