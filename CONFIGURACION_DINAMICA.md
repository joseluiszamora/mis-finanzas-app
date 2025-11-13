# 🔄 Configuración Dinámica - Resumen de Cambios

## 📋 Descripción General

Se ha implementado un sistema de configuración dinámica que permite cargar las **categorías** y **grupos** desde una hoja de Google Sheets llamada "Config", en lugar de tenerlas codificadas en la aplicación.

## ✨ Cambios Implementados

### 1. Hoja "Config" en Google Sheets

Se creó una nueva estructura en Google Sheets:

- **Columna A**: Lista de categorías (A1 = título "Categorías", A2+ = valores)
- **Columna B**: Lista de grupos (B1 = título "Grupos", B2+ = valores)

### 2. Servicio de Google Sheets (`google_sheets_service.dart`)

**Nuevos métodos agregados:**

```dart
Future<List<String>> obtenerCategorias() async
Future<List<String>> obtenerGrupos() async
```

**Características:**

- Leen desde la hoja "Config"
- Filtran valores vacíos automáticamente
- Retornan valores por defecto si hay error
- Saltan la primera fila (encabezado)

### 3. Provider (`movimientos_provider.dart`)

**Métodos wrapper agregados:**

```dart
Future<List<String>> obtenerCategorias() async
Future<List<String>> obtenerGrupos() async
```

**Propósito:**

- Exponer la funcionalidad del servicio a las pantallas
- Mantener la arquitectura limpia

### 4. Pantalla Agregar Movimiento (`agregar_movimiento_screen.dart`)

**Cambios principales:**

**ANTES:**

```dart
// Categorías hardcodeadas
final Map<String, List<String>> _categoriasPorTipo = {
  'Ingreso': [...],
  'Egreso': [...],
};

// Grupo como campo de texto
final _grupoController = TextEditingController();
TextFormField(controller: _grupoController, ...)
```

**DESPUÉS:**

```dart
// Listas dinámicas
List<String> _categorias = [];
List<String> _grupos = [];
bool _isLoadingConfig = true;

// Carga en initState
@override
void initState() {
  super.initState();
  _cargarConfiguracion();
}

Future<void> _cargarConfiguracion() async {
  final categorias = await provider.obtenerCategorias();
  final grupos = await provider.obtenerGrupos();
  setState(() {
    _categorias = categorias;
    _grupos = grupos;
    _isLoadingConfig = false;
  });
}

// Grupo como dropdown
String? _grupoSeleccionado;
DropdownButtonFormField<String>(
  value: _grupoSeleccionado,
  items: _grupos.map(...).toList(),
  ...
)
```

**Beneficios:**

- ✅ Categorías unificadas (no separadas por tipo Ingreso/Egreso)
- ✅ Grupo es ahora un dropdown en lugar de texto libre
- ✅ Carga dinámica en cada apertura del formulario
- ✅ Estado de carga mientras se obtienen los datos

### 5. Pantalla Editar Movimiento (`editar_movimiento_screen.dart`)

**Mismos cambios que AgregarMovimientoScreen, más:**

```dart
// Validación de valores existentes
setState(() {
  _categorias = categorias;
  _grupos = grupos;
  _isLoadingConfig = false;

  // Si la categoría actual no existe en Config, deseleccionar
  if (_categoriaSeleccionada != null &&
      !_categorias.contains(_categoriaSeleccionada)) {
    _categoriaSeleccionada = null;
  }

  // Si el grupo actual no existe en Config, deseleccionar
  if (_grupoSeleccionado != null &&
      !_grupos.contains(_grupoSeleccionado)) {
    _grupoSeleccionado = null;
  }
});
```

**Protección adicional:**

- Si un movimiento tiene una categoría que ya no existe en Config, se deselecciona
- El usuario debe elegir una nueva categoría/grupo válido

### 6. Eliminación de lógica de tipo-categoría

**ANTES:**

```dart
Widget _buildTipoButton(...) {
  return InkWell(
    onTap: () {
      setState(() {
        _tipoSeleccionado = tipo;
        // Reset categoría si no está en la nueva lista
        if (!_categoriasPorTipo[tipo]!.contains(_categoriaSeleccionada)) {
          _categoriaSeleccionada = null;
        }
      });
    },
    ...
  );
}
```

**DESPUÉS:**

```dart
Widget _buildTipoButton(...) {
  return InkWell(
    onTap: () {
      setState(() {
        _tipoSeleccionado = tipo;
        // La categoría ya no depende del tipo
      });
    },
    ...
  );
}
```

## 📄 Documentación Creada

### 1. `HOJA_CONFIG.md`

- Guía completa de configuración de la hoja Config
- Ejemplos prácticos
- Solución de problemas
- Características y comportamiento

### 2. Actualizaciones a `README.md`

- Instrucciones para crear la hoja Config
- Referencia a HOJA_CONFIG.md
- Explicación de configuración dinámica
- Eliminación de lista hardcodeada de categorías

### 3. Actualizaciones a `ARQUITECTURA.md`

- Diagrama actualizado con hoja Config
- Nuevo flujo de datos para configuración dinámica
- Explicación del patrón de carga

## 🎯 Comportamiento de la Aplicación

### Flujo de Carga

1. Usuario abre formulario (agregar o editar)
2. `initState()` ejecuta `_cargarConfiguracion()`
3. Se muestra estado de carga (`_isLoadingConfig = true`)
4. Provider llama a Service para obtener categorías y grupos
5. Service lee columnas A y B de la hoja Config
6. Se filtran valores vacíos
7. Listas se actualizan en el estado
8. UI se reconstruye con los nuevos valores
9. Dropdowns quedan habilitados con las opciones

### Manejo de Errores

Si ocurre un error al cargar Config:

- Se usan valores predeterminados
- La app continúa funcionando normalmente
- Se imprime error en consola para debugging

**Valores predeterminados:**

```dart
// Categorías
return ['Salario', 'Alimentación', 'Transporte', 'Vivienda', 'Otro'];

// Grupos
return ['Personal', 'Familia', 'Trabajo'];
```

### Validación en Edición

Al editar un movimiento existente:

- Se valida que categoría y grupo actuales existan en Config
- Si no existen, se deseleccionan automáticamente
- El usuario debe elegir nuevos valores válidos antes de guardar

## 🔧 Cambios Técnicos Detallados

### Imports Removidos

- Ya no se necesita TextEditingController para grupo

### Variables de Estado Nuevas

```dart
// AgregarMovimientoScreen y EditarMovimientoScreen
String? _grupoSeleccionado;        // Reemplaza TextEditingController
bool _isLoadingConfig = true;       // Estado de carga
List<String> _categorias = [];      // Lista dinámica de categorías
List<String> _grupos = [];          // Lista dinámica de grupos
```

### Variables de Estado Removidas

```dart
final _grupoController = TextEditingController();  // Ya no se usa
final Map<String, List<String>> _categoriasPorTipo = {...};  // Ya no se usa
```

### Cambios en dispose()

```dart
// ANTES
@override
void dispose() {
  _conceptoController.dispose();
  _montoController.dispose();
  _grupoController.dispose();  // ← Removido
  super.dispose();
}

// DESPUÉS
@override
void dispose() {
  _conceptoController.dispose();
  _montoController.dispose();
  super.dispose();
}
```

### Cambios en guardar movimiento

```dart
// ANTES
final movimiento = Movimiento(
  // ...
  grupo: _grupoController.text,
);

// DESPUÉS
final movimiento = Movimiento(
  // ...
  grupo: _grupoSeleccionado ?? '',
);
```

### Dropdown de Categoría

```dart
DropdownButtonFormField<String>(
  value: _categoriaSeleccionada,
  items: _isLoadingConfig
      ? []  // Sin items durante carga
      : _categorias.map((categoria) => DropdownMenuItem(
          value: categoria,
          child: Text(categoria),
        )).toList(),
  onChanged: _isLoadingConfig
      ? null  // Deshabilitado durante carga
      : (value) {
          setState(() {
            _categoriaSeleccionada = value;
          });
        },
  // ...
)
```

### Dropdown de Grupo

```dart
DropdownButtonFormField<String>(
  value: _grupoSeleccionado,
  decoration: const InputDecoration(
    labelText: 'Grupo (opcional)',
    hintText: 'Selecciona un grupo',  // Cambió de "Ej: Personal, Familia, Trabajo"
    prefixIcon: Icon(Icons.group),
    border: OutlineInputBorder(),
  ),
  items: _isLoadingConfig
      ? []
      : _grupos.map((grupo) => DropdownMenuItem(
          value: grupo,
          child: Text(grupo),
        )).toList(),
  onChanged: _isLoadingConfig
      ? null
      : (value) {
          setState(() {
            _grupoSeleccionado = value;
          });
        },
)
```

## ✅ Ventajas de esta Implementación

1. **Flexibilidad**: Categorías y grupos se pueden cambiar sin tocar el código
2. **Centralización**: Una sola fuente de verdad (Google Sheets)
3. **Mantenibilidad**: Cambios se hacen en Google Sheets, no en la app
4. **Escalabilidad**: Fácil agregar nuevas categorías o grupos
5. **Consistencia**: Todos los usuarios ven las mismas opciones
6. **Simplicidad**: No hay duplicación entre Ingreso y Egreso
7. **Validación**: Grupo ahora es controlado, evita errores de escritura

## 🚀 Próximos Pasos Sugeridos

1. **Cache local**: Guardar categorías/grupos en SharedPreferences para carga offline
2. **Actualización en background**: Refrescar Config periódicamente sin bloquear UI
3. **Administración desde la app**: Agregar pantalla para gestionar Config sin ir a Google Sheets
4. **Categorías por tipo**: Si se necesita en el futuro, agregar columna "tipo" en Config
5. **Iconos personalizados**: Agregar columna para iconos de categorías
6. **Colores**: Agregar columna para colores de categorías

## 📝 Notas de Migración

### Para Usuarios Existentes

Si ya tienes movimientos con:

- Categorías que ya no existen en Config → Al editar, deberás seleccionar una nueva
- Grupos personalizados (texto libre) → Se mantendrán hasta que los edites

### Para Desarrolladores

- Los cambios son **backward compatible** con movimientos existentes
- No se requiere migración de datos
- Google Sheets debe tener ambas hojas: "Hoja 1" y "Config"

## 🐛 Testing Realizado

✅ Compilación sin errores
✅ Carga de categorías desde Config
✅ Carga de grupos desde Config
✅ Dropdown de categorías funcional
✅ Dropdown de grupos funcional
✅ Validación de categorías inexistentes en edición
✅ Validación de grupos inexistentes en edición
✅ Manejo de errores con valores por defecto
✅ Estado de carga mientras se obtienen datos

## 📞 Soporte

Para más información sobre cómo configurar la hoja Config, consulta [HOJA_CONFIG.md](HOJA_CONFIG.md).
