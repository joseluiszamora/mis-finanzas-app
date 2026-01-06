import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WorksheetService {
  static const String _worksheetsKey = 'worksheets_list';
  static const String _activeWorksheetKey = 'active_worksheet';

  SharedPreferences? _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();

    // Si no hay worksheets guardadas, agregar la del .env como inicial
    final worksheets = await getWorksheets();
    if (worksheets.isEmpty) {
      final defaultWorksheet = dotenv.env['GOOGLE_WORKSHEET_TITLE'] ?? 'Hoja 1';
      await addWorksheet(defaultWorksheet);
      await setActiveWorksheet(defaultWorksheet);
    }
  }

  // Obtener lista de worksheets
  Future<List<String>> getWorksheets() async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!.getStringList(_worksheetsKey) ?? [];
  }

  // Agregar una nueva worksheet
  Future<bool> addWorksheet(String title) async {
    _prefs ??= await SharedPreferences.getInstance();
    final worksheets = await getWorksheets();

    // Verificar que no exista ya
    if (worksheets.contains(title)) {
      return false;
    }

    worksheets.add(title);
    await _prefs!.setStringList(_worksheetsKey, worksheets);
    return true;
  }

  // Eliminar una worksheet
  Future<bool> removeWorksheet(String title) async {
    _prefs ??= await SharedPreferences.getInstance();
    final worksheets = await getWorksheets();
    final activeWorksheet = await getActiveWorksheet();

    // No permitir eliminar si es la única
    if (worksheets.length <= 1) {
      return false;
    }

    // No permitir eliminar la activa
    if (title == activeWorksheet) {
      return false;
    }

    worksheets.remove(title);
    await _prefs!.setStringList(_worksheetsKey, worksheets);
    return true;
  }

  // Obtener la worksheet activa
  Future<String> getActiveWorksheet() async {
    _prefs ??= await SharedPreferences.getInstance();
    final active = _prefs!.getString(_activeWorksheetKey);

    if (active != null) {
      return active;
    }

    // Si no hay activa, usar la primera de la lista o la del .env
    final worksheets = await getWorksheets();
    if (worksheets.isNotEmpty) {
      return worksheets.first;
    }

    return dotenv.env['GOOGLE_WORKSHEET_TITLE'] ?? 'Hoja 1';
  }

  // Establecer la worksheet activa
  Future<void> setActiveWorksheet(String title) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_activeWorksheetKey, title);
  }

  // Verificar si una worksheet existe en la lista
  Future<bool> worksheetExists(String title) async {
    final worksheets = await getWorksheets();
    return worksheets.contains(title);
  }
}
