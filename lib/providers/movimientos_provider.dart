import 'package:flutter/foundation.dart';
import '../models/movimiento.dart';
import '../services/google_sheets_service.dart';

class MovimientosProvider extends ChangeNotifier {
  final GoogleSheetsService _sheetsService = GoogleSheetsService();

  List<Movimiento> _movimientos = [];
  bool _isLoading = false;
  bool _isInitialized = false;
  String? _error;

  List<Movimiento> get movimientos => _movimientos;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  String? get error => _error;

  // Inicializar el servicio de Google Sheets
  Future<void> init() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _isInitialized = await _sheetsService.init();
      if (_isInitialized) {
        await cargarMovimientos();
      } else {
        _error =
            'No se pudo conectar con Google Sheets. Verifica las credenciales.';
      }
    } catch (e) {
      _error = 'Error al inicializar: $e';
      _isInitialized = false;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Cargar movimientos desde Google Sheets
  Future<void> cargarMovimientos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _movimientos = await _sheetsService.obtenerMovimientos();
    } catch (e) {
      _error = 'Error al cargar movimientos: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  // Agregar un nuevo movimiento
  Future<bool> agregarMovimiento(Movimiento movimiento) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final success = await _sheetsService.agregarMovimiento(movimiento);

      if (success) {
        // Agregar el movimiento localmente también
        _movimientos.insert(0, movimiento);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'No se pudo agregar el movimiento';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al agregar movimiento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Obtener resumen del mes
  Future<Map<String, double>> obtenerResumenMes(String mes) async {
    return await _sheetsService.obtenerResumenMes(mes);
  }

  // Filtrar movimientos por tipo
  List<Movimiento> filtrarPorTipo(String tipo) {
    return _movimientos
        .where((m) => m.tipo.toLowerCase() == tipo.toLowerCase())
        .toList();
  }

  // Calcular totales
  double get totalIngresos {
    return _movimientos
        .where((m) => m.tipo.toLowerCase() == 'ingreso')
        .fold(0, (sum, m) => sum + m.monto);
  }

  double get totalEgresos {
    return _movimientos
        .where((m) => m.tipo.toLowerCase() == 'egreso')
        .fold(0, (sum, m) => sum + m.monto);
  }

  double get balance => totalIngresos - totalEgresos;

  // Obtener categorías desde Google Sheets
  Future<List<String>> obtenerCategorias() async {
    return await _sheetsService.obtenerCategorias();
  }

  // Obtener grupos desde Google Sheets
  Future<List<String>> obtenerGrupos() async {
    return await _sheetsService.obtenerGrupos();
  }

  // Editar un movimiento existente
  Future<bool> editarMovimiento(int index, Movimiento movimientoEditado) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Editar en Google Sheets
      final success = await _sheetsService.editarMovimiento(
        index,
        movimientoEditado,
      );

      if (success) {
        // Actualizar localmente
        _movimientos[index] = movimientoEditado;
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'No se pudo editar el movimiento';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al editar movimiento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Eliminar un movimiento
  Future<bool> eliminarMovimiento(int index) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Eliminar en Google Sheets
      final success = await _sheetsService.eliminarMovimiento(index);

      if (success) {
        // Eliminar localmente
        _movimientos.removeAt(index);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _error = 'No se pudo eliminar el movimiento';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _error = 'Error al eliminar movimiento: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
