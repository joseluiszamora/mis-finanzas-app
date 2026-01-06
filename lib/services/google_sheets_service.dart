import 'package:gsheets/gsheets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/movimiento.dart';

class GoogleSheetsService {
  // Las credenciales ahora se cargan desde el archivo .env
  // Para configurar:
  // 1. Copia .env.example a .env
  // 2. Completa con tus credenciales de Google Cloud Console
  // 3. Nunca subas el archivo .env al repositorio (está en .gitignore)

  static String get _credentials => dotenv.env['GOOGLE_CREDENTIALS'] ?? '';
  static String get _spreadsheetId => dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';

  GSheets? _gsheets;
  Spreadsheet? _spreadsheet;
  Worksheet? _worksheet;
  String _currentWorksheetTitle = '';

  // Getter para obtener el título actual de la worksheet
  String get currentWorksheetTitle => _currentWorksheetTitle;

  // Inicializar conexión con Google Sheets con una worksheet específica
  Future<bool> init({String? worksheetTitle}) async {
    try {
      _gsheets = GSheets(_credentials);
      _spreadsheet = await _gsheets!.spreadsheet(_spreadsheetId);

      // Usar el título proporcionado o el del .env como fallback
      _currentWorksheetTitle =
          worksheetTitle ?? dotenv.env['GOOGLE_WORKSHEET_TITLE'] ?? 'Hoja 1';

      _worksheet = _spreadsheet!.worksheetByTitle(_currentWorksheetTitle);

      // Si la hoja no existe, intenta obtener la primera hoja disponible
      if (_worksheet == null) {
        _worksheet = _spreadsheet!.worksheetByIndex(0);
        if (_worksheet != null) {
          _currentWorksheetTitle = _worksheet!.title;
        }
      }

      return _worksheet != null;
    } catch (e) {
      print('Error al inicializar Google Sheets: $e');
      return false;
    }
  }

  // Cambiar a una worksheet diferente
  Future<bool> changeWorksheet(String worksheetTitle) async {
    try {
      if (_spreadsheet == null) {
        await init(worksheetTitle: worksheetTitle);
        return _worksheet != null;
      }

      final newWorksheet = _spreadsheet!.worksheetByTitle(worksheetTitle);
      if (newWorksheet != null) {
        _worksheet = newWorksheet;
        _currentWorksheetTitle = worksheetTitle;
        _totalRows = 0; // Resetear el contador de filas
        return true;
      }
      return false;
    } catch (e) {
      print('Error al cambiar worksheet: $e');
      return false;
    }
  }

  // Verificar si una worksheet existe en el spreadsheet
  Future<bool> worksheetExists(String title) async {
    try {
      if (_spreadsheet == null) {
        _gsheets = GSheets(_credentials);
        _spreadsheet = await _gsheets!.spreadsheet(_spreadsheetId);
      }
      return _spreadsheet!.worksheetByTitle(title) != null;
    } catch (e) {
      print('Error al verificar worksheet: $e');
      return false;
    }
  }

  // Obtener lista de todas las worksheets del spreadsheet
  Future<List<String>> getAllWorksheetTitles() async {
    try {
      if (_spreadsheet == null) {
        _gsheets = GSheets(_credentials);
        _spreadsheet = await _gsheets!.spreadsheet(_spreadsheetId);
      }
      return _spreadsheet!.sheets.map((sheet) => sheet.title).toList();
    } catch (e) {
      print('Error al obtener worksheets: $e');
      return [];
    }
  }

  // Variable para almacenar el total de filas (para calcular índices correctos)
  int _totalRows = 0;

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

      // Guardar el total de filas para calcular índices correctamente
      _totalRows = rows.length;

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

      // rowIndex es el índice en la lista invertida (0 = más reciente)
      // La lista está invertida, así que necesitamos convertir al índice real
      // Índice real = (totalRows - 1) - rowIndex
      // La fila en Google Sheets = índice real + 2 (fila 1 es encabezado)
      final realIndex = (_totalRows - 1) - rowIndex;
      final sheetRow = realIndex + 2;

      print(
        'Editando: rowIndex=$rowIndex, totalRows=$_totalRows, realIndex=$realIndex, sheetRow=$sheetRow',
      );

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

      // rowIndex es el índice en la lista invertida (0 = más reciente)
      // La lista está invertida, así que necesitamos convertir al índice real
      // Índice real = (totalRows - 1) - rowIndex
      // La fila en Google Sheets = índice real + 2 (fila 1 es encabezado)
      final realIndex = (_totalRows - 1) - rowIndex;
      final sheetRow = realIndex + 2;

      print(
        'Eliminando: rowIndex=$rowIndex, totalRows=$_totalRows, realIndex=$realIndex, sheetRow=$sheetRow',
      );

      // Eliminar la fila
      await _worksheet!.deleteRow(sheetRow);

      // Actualizar el contador de filas
      _totalRows--;

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
