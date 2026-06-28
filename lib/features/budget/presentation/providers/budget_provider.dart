// Archivo: lib/features/budget/presentation/providers/budget_provider.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/database/local_storage_service.dart';
import '../../data/models/gasto_model.dart';
import '../../data/models/boveda_model.dart';

class BudgetProvider with ChangeNotifier {
  final _storage = LocalStorageService.instance;

  // Controladores de UI
  final TextEditingController sueldoCtrl = TextEditingController();
  final TextEditingController nombreGastoCtrl = TextEditingController();
  final TextEditingController montoGastoCtrl = TextEditingController();

  // --- NUEVO: SISTEMA DE CALENDARIO MENSUAL ---
  DateTime _currentMonth = DateTime.now();
  DateTime get currentMonth => _currentMonth;
  
  // Guardaremos los sueldos en un mapa, ej: {"2026-06": 1500.0}
  Map<String, double> _sueldosMensuales = {};

  List<Gasto> _todosLosGastos = [];
  List<Boveda> bovedas = [];

  // Variables calculadas (Solo para el mes actual)
  double balanceLocal = 0.0;

  BudgetProvider() {
    _loadData();
  }

  // Obtiene la clave del mes actual (ej: "2026-06")
  String get _monthKey => DateFormat('yyyy-MM').format(_currentMonth);

  // Filtra los gastos para mostrar SOLO los del mes actual
  List<Gasto> get gastosDelMes {
    return _todosLosGastos.where((g) {
      return g.fecha.year == _currentMonth.year && g.fecha.month == _currentMonth.month;
    }).toList();
  }

  void _loadData() {
    // Cargar sueldos mensuales
    final sueldosMap = _storage.budgetBox.get('sueldosMensuales') ?? {};
    _sueldosMensuales = Map<String, double>.from(sueldosMap);

    // Cargar gastos
    final gastosData = _storage.budgetBox.get('gastos', defaultValue: []);
    _todosLosGastos = (gastosData as List).map((e) => Gasto.fromMap(Map<String, dynamic>.from(e))).toList();
    
    // Cargar bóvedas
    final bovedasData = _storage.budgetBox.get('bovedas', defaultValue: []);
    bovedas = (bovedasData as List).map((e) => Boveda.fromMap(Map<String, dynamic>.from(e))).toList();

    _actualizarUIAlCambiarMes();
  }

  // --- NAVEGACIÓN DEL CALENDARIO ---
  void cambiarMes(int offset) {
    _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + offset);
    _actualizarUIAlCambiarMes();
  }

  void _actualizarUIAlCambiarMes() {
    // Actualizar el TextField del sueldo al del mes seleccionado
    double sueldoActual = _sueldosMensuales[_monthKey] ?? 0.0;
    sueldoCtrl.text = sueldoActual > 0 ? sueldoActual.toStringAsFixed(2) : '';
    calcularPresupuesto();
  }

  // --- CÁLCULO DINÁMICO ---
  void calcularPresupuesto() {
    double sueldo = double.tryParse(sueldoCtrl.text) ?? 0.0;
    
    // Guardar el sueldo del mes actual en memoria y BD
    _sueldosMensuales[_monthKey] = sueldo;
    _storage.budgetBox.put('sueldosMensuales', _sueldosMensuales);

    double totalGastosMes = gastosDelMes.fold(0.0, (sum, item) => sum + item.montoLocal);
    double totalBovedas = bovedas.fold(0.0, (sum, item) => sum + item.ahorrado);

    balanceLocal = sueldo - totalGastosMes - totalBovedas;
    notifyListeners();
  }

  // --- GESTIÓN DE GASTOS ---
  void addGasto(String nombre, double montoOriginal, String monedaOriginal, String categoria, double tasaDeCambio) {
    double montoLocal = (montoOriginal / tasaDeCambio); // Conversión base (Ajustable con AppProvider luego)
    
    final nuevoGasto = Gasto(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      nombre: nombre,
      montoOriginal: montoOriginal,
      monedaOriginal: monedaOriginal,
      montoLocal: montoLocal,
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
    _storage.budgetBox.put('gastos', _todosLosGastos.map((g) => g.toMap()).toList());
  }

  // --- BÓVEDAS (METAS) ---
  void addBoveda(String nombre, double objetivo) {
    bovedas.add(Boveda(id: DateTime.now().millisecondsSinceEpoch.toString(), nombre: nombre, objetivo: objetivo));
    _saveBovedas();
  }

  void gestionarBoveda(String id, double cantidad, bool esRetiro) {
    int idx = bovedas.indexWhere((b) => b.id == id);
    if (idx != -1) {
      if (esRetiro) {
        bovedas[idx].ahorrado -= cantidad;
        if (bovedas[idx].ahorrado < 0) bovedas[idx].ahorrado = 0;
      } else {
        bovedas[idx].ahorrado += cantidad;
      }
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
    _storage.budgetBox.put('bovedas', bovedas.map((b) => b.toMap()).toList());
  }
}
