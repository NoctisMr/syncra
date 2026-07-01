// lib/features/budget/presentation/providers/budget_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../data/models/gasto_model.dart';
import '../../data/models/vault_model.dart';

class BudgetProvider with ChangeNotifier {
  final _storage = LocalStorageService.instance;

  final TextEditingController sueldoCtrl = TextEditingController();
  final TextEditingController nombreGastoCtrl = TextEditingController();
  final TextEditingController montoGastoCtrl = TextEditingController();

  DateTime _currentMonth = DateTime.now();
  DateTime get currentMonth => _currentMonth;
  
  Map<String, double> _sueldosMensuales = {};
  List<GastoModel> _todosLosGastos = [];
  List<VaultModel> bovedas = [];

  double balanceLocal = 0.0;
  double balanceEq = 0.0;

  BudgetProvider() {
    _loadData();
  }

  String get _monthKey => DateFormat('yyyy-MM').format(_currentMonth);

  List<GastoModel> get gastosDelMes {
    return _todosLosGastos.where((g) {
      return g.fecha.year == _currentMonth.year && g.fecha.month == _currentMonth.month;
    }).toList();
  }

  void _loadData() {
    final sueldosMap = _storage.getData('sueldosMensuales') ?? {};
    _sueldosMensuales = Map<String, double>.from(sueldosMap);

    final List? gastosData = _storage.getData('gastos_v2');
    if (gastosData != null) {
      _todosLosGastos = gastosData.map((e) => GastoModel.fromMap(e)).toList();
    }
    
    final List? bovedasData = _storage.getData('bovedas');
    if (bovedasData != null) {
      bovedas = bovedasData.map((e) => VaultModel.fromMap(e)).toList();
    }

    _actualizarUIAlCambiarMes();
  }

  void cambiarMes(int offset) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    _actualizarUIAlCambiarMes();
  }

  void _actualizarUIAlCambiarMes() {
    double sueldoActual = _sueldosMensuales[_monthKey] ?? 0.0;
    sueldoCtrl.text = sueldoActual > 0 ? sueldoActual.toStringAsFixed(2) : '';
    calcularPresupuesto();
  }

  void calcularPresupuesto() {
    double sueldo = double.tryParse(sueldoCtrl.text) ?? 0.0;
    
    _sueldosMensuales[_monthKey] = sueldo;
    _storage.saveData('sueldosMensuales', _sueldosMensuales);

    double totalGastosMes = gastosDelMes.fold(0.0, (sum, item) => sum + item.montoLocal);
    double totalBovedas = bovedas.fold(0.0, (sum, item) => sum + item.ahorrado);

    balanceLocal = sueldo - totalGastosMes - totalBovedas;
    notifyListeners();
  }

  void addGasto(String nombre, double montoOriginal, String monedaOriginal, String categoria) {
    final nuevoGasto = GastoModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      montoOriginal: montoOriginal,
      monedaOriginal: monedaOriginal,
      montoLocal: montoOriginal, // Will be adjusted via exchange rates dynamically by UI if needed
      categoria: categoria,
      fecha: DateTime.now(),
    );

    _todosLosGastos.insert(0, nuevoGasto);
    _saveGastos();
    calcularPresupuesto();
  }

  void deleteGasto(String id) {
    _todosLosGastos.removeWhere((g) => g.id == id);
    _saveGastos();
    calcularPresupuesto();
  }

  void _saveGastos() {
    _storage.saveData('gastos_v2', _todosLosGastos.map((g) => g.toMap()).toList());
  }

  void addBoveda(String nombre, double objetivo) {
    bovedas.add(VaultModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(), 
      nombre: nombre, 
      objetivo: objetivo,
      ahorrado: 0.0,
      historial: [],
    ));
    _saveBovedas();
  }

  void gestionarBoveda(String id, double monto, bool esRetiro) {
    int idx = bovedas.indexWhere((b) => b.id == id);
    if (idx != -1) {
      VaultModel boveda = bovedas[idx];
      double nuevoAhorrado = boveda.ahorrado;
      
      if (esRetiro) {
        nuevoAhorrado -= monto;
        if (nuevoAhorrado < 0) nuevoAhorrado = 0;
      } else {
        nuevoAhorrado += monto;
      }
      
      final transaccion = TransactionRecord(
        monto: monto,
        fecha: DateTime.now(),
        esRetiro: esRetiro,
      );

      final bovedaActualizada = VaultModel(
        id: boveda.id,
        nombre: boveda.nombre,
        objetivo: boveda.objetivo,
        ahorrado: nuevoAhorrado,
        historial: List.from(boveda.historial)..insert(0, transaccion),
      );

      bovedas[idx] = bovedaActualizada;
      _saveBovedas();
      calcularPresupuesto();
    }
  }

  void deleteBoveda(String id) {
    bovedas.removeWhere((b) => b.id == id);
    _saveBovedas();
    calcularPresupuesto();
  }

  void _saveBovedas() {
    _storage.saveData('bovedas', bovedas.map((b) => b.toMap()).toList());
  }
}
