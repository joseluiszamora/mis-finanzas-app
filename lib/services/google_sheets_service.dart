import 'package:gsheets/gsheets.dart';
import '../models/movimiento.dart';

class GoogleSheetsService {
  // IMPORTANTE: Reemplaza esto con tus credenciales de Google Sheets API
  // Para obtener las credenciales:
  // 1. Ve a https://console.cloud.google.com/
  // 2. Crea un proyecto nuevo o usa uno existente
  // 3. Habilita Google Sheets API
  // 4. Crea credenciales (Service Account)
  // 5. Descarga el JSON de credenciales
  static const _credentials = r'''
{
  
}
''';

  // IMPORTANTE: Reemplaza con el ID de tu Google Sheet
  // Lo encuentras en la URL: https://docs.google.com/spreadsheets/d/[SPREADSHEET_ID]/edit
  static const _spreadsheetId = '15qyupEAyvF7Sl0035l8uoSj52fLFTCP3b0LllSDhJT0';

  // Nombre de la hoja donde están los datos
  static const _worksheetTitle = 'Hoja 1'; // Cambia según tu hoja

  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;
  Worksheet? _worksheet;

  // Inicializar conexión con Google Sheets
  Future<bool> init() async {
    try {
      _gsheets = GSheets(_credentials);
      _spreadsheet = await _gsheets!.spreadsheet(_spreadsheetId);
      _worksheet = _spreadsheet!.worksheetByTitle(_worksheetTitle);

      // Si la hoja no existe, intenta obtener la primera hoja disponible
      _worksheet ??= _spreadsheet!.worksheetByIndex(0);

      return _worksheet != null;
    } catch (e) {
      print('Error al inicializar Google Sheets: $e');
      return false;
    }
  }

  // Obtener todos los movimientos
  Future<List<Movimiento>> obtenerMovimientos() async {
    try {
      if (_worksheet == null) {
        final initialized = await init();
        if (!initialized) {
          throw Exception('No se pudo conectar con Google Sheets');
        }
      }

      // Obtener todas las filas (excluyendo el encabezado)
      final rows = await _worksheet!.values.allRows(fromRow: 2);

      return rows
          .map((row) => Movimiento.fromSheetRow(row))
          .toList()
          .reversed // Mostrar los más recientes primero
          .toList();
    } catch (e) {
      print('Error al obtener movimientos: $e');
      return [];
    }
  }

  // Agregar un nuevo movimiento
  Future<bool> agregarMovimiento(Movimiento movimiento) async {
    try {
      if (_worksheet == null) {
        final initialized = await init();
        if (!initialized) {
          throw Exception('No se pudo conectar con Google Sheets');
        }
      }

      // Agregar la fila al final de la hoja
      await _worksheet!.values.appendRow(movimiento.toSheetRow());

      return true;
    } catch (e) {
      print('Error al agregar movimiento: $e');
      return false;
    }
  }

  // Obtener resumen de ingresos y egresos del mes actual
  Future<Map<String, double>> obtenerResumenMes(String mes) async {
    try {
      final movimientos = await obtenerMovimientos();

      double ingresos = 0;
      double egresos = 0;

      for (var mov in movimientos) {
        if (mov.mes.toLowerCase() == mes.toLowerCase()) {
          if (mov.tipo.toLowerCase() == 'ingreso') {
            ingresos += mov.monto;
          } else if (mov.tipo.toLowerCase() == 'egreso') {
            egresos += mov.monto;
          }
        }
      }

      return {
        'ingresos': ingresos,
        'egresos': egresos,
        'balance': ingresos - egresos,
      };
    } catch (e) {
      print('Error al obtener resumen: $e');
      return {'ingresos': 0, 'egresos': 0, 'balance': 0};
    }
  }

  // Editar un movimiento existente
  Future<bool> editarMovimiento(int rowIndex, Movimiento movimiento) async {
    try {
      if (_worksheet == null) {
        final initialized = await init();
        if (!initialized) {
          throw Exception('No se pudo conectar con Google Sheets');
        }
      }

      // rowIndex es el índice en la lista (0-based)
      // pero en Google Sheets las filas empiezan en 1 y la fila 1 es el encabezado
      // entonces la fila real es: rowIndex + 2
      final sheetRow = rowIndex + 2;

      // Actualizar cada celda de la fila
      final row = movimiento.toSheetRow();
      for (int col = 0; col < row.length; col++) {
        await _worksheet!.values.insertValue(
          row[col],
          column: col + 1,
          row: sheetRow,
        );
      }

      return true;
    } catch (e) {
      print('Error al editar movimiento: $e');
      return false;
    }
  }

  // Eliminar un movimiento
  Future<bool> eliminarMovimiento(int rowIndex) async {
    try {
      if (_worksheet == null) {
        final initialized = await init();
        if (!initialized) {
          throw Exception('No se pudo conectar con Google Sheets');
        }
      }

      // rowIndex es el índice en la lista (0-based)
      // pero en Google Sheets las filas empiezan en 1 y la fila 1 es el encabezado
      // entonces la fila real es: rowIndex + 2
      final sheetRow = rowIndex + 2;

      // Eliminar la fila
      await _worksheet!.deleteRow(sheetRow);

      return true;
    } catch (e) {
      print('Error al eliminar movimiento: $e');
      return false;
    }
  }

  // Buscar el índice de un movimiento en la hoja
  Future<int?> buscarIndiceMovimiento(Movimiento movimiento) async {
    try {
      final movimientos = await obtenerMovimientos();

      for (int i = 0; i < movimientos.length; i++) {
        final mov = movimientos[i];
        if (mov.fecha == movimiento.fecha &&
            mov.concepto == movimiento.concepto &&
            mov.monto == movimiento.monto &&
            mov.tipo == movimiento.tipo) {
          return i;
        }
      }

      return null;
    } catch (e) {
      print('Error al buscar índice: $e');
      return null;
    }
  }

  // Obtener categorías desde la hoja Config
  Future<List<String>> obtenerCategorias() async {
    try {
      if (_gsheets == null || _spreadsheet == null) {
        await init();
      }

      // Obtener la hoja Config
      final configSheet = _spreadsheet!.worksheetByTitle('Config');

      if (configSheet == null) {
        print('Hoja Config no encontrada');
        return _categoriasPorDefecto();
      }

      // Obtener valores de la columna A (categorías)
      final valores = await configSheet.values.column(
        1,
        fromRow: 2,
      ); // Desde fila 2 (saltando el título)

      // Filtrar valores vacíos y retornar
      return valores
          .where((v) => v.toString().trim().isNotEmpty)
          .map((v) => v.toString().trim())
          .toList();
    } catch (e) {
      print('Error al obtener categorías: $e');
      return _categoriasPorDefecto();
    }
  }

  // Obtener grupos desde la hoja Config
  Future<List<String>> obtenerGrupos() async {
    try {
      if (_gsheets == null || _spreadsheet == null) {
        await init();
      }

      // Obtener la hoja Config
      final configSheet = _spreadsheet!.worksheetByTitle('Config');

      if (configSheet == null) {
        print('Hoja Config no encontrada');
        return _gruposPorDefecto();
      }

      // Obtener valores de la columna B (grupos)
      final valores = await configSheet.values.column(
        2,
        fromRow: 2,
      ); // Desde fila 2 (saltando el título)

      // Filtrar valores vacíos y retornar
      return valores
          .where((v) => v.toString().trim().isNotEmpty)
          .map((v) => v.toString().trim())
          .toList();
    } catch (e) {
      print('Error al obtener grupos: $e');
      return _gruposPorDefecto();
    }
  }

  // Categorías por defecto si hay error
  List<String> _categoriasPorDefecto() {
    return [
      'Salario',
      'Freelance',
      'Inversiones',
      'Alimentación',
      'Transporte',
      'Vivienda',
      'Servicios',
      'Salud',
      'Educación',
      'Entretenimiento',
      'Ropa',
      'Tecnología',
      'Deudas',
      'Ahorro',
      'Otro',
    ];
  }

  // Grupos por defecto si hay error
  List<String> _gruposPorDefecto() {
    return ['Personal', 'Familia', 'Trabajo', 'Proyecto'];
  }
}
