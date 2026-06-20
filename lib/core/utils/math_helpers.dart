// Archivo: lib/core/utils/math_helpers.dart

class MathHelpers {
  /// Calcula el peso volumétrico basado en la fórmula estándar.
  /// [divisor] por defecto es 5000 (estándar IATA), pero puede ajustarse a 6000 u otro valor.
  static double calculateVolumetricWeight({
    required double length,
    required double width,
    required double height,
    double divisor = 5000.0,
  }) {
    if (divisor <= 0) return 0.0; // Prevención de división por cero
    return (length * width * height) / divisor;
  }

  /// Calcula un porcentaje simple (Ideal para tu futura calculadora de presupuestos)
  static double calculatePercentage(double total, double percent) {
    if (percent < 0) return 0.0;
    return (total * percent) / 100;
  }
  
  /// Convierte dimensiones de pulgadas a centímetros (Ideal para el módulo de conversión)
  static double inchesToCentimeters(double inches) {
    return inches * 2.54;
  }
}
