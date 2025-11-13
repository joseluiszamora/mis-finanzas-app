# 🏗️ Arquitectura de la Aplicación

## 📊 Diagrama de Flujo

```
┌─────────────────────────────────────────────────┐
│                   USUARIO                        │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│              HomeScreen (UI)                     │
│  ┌──────────────────────────────────────────┐   │
│  │  📊 Tarjeta Resumen                      │   │
│  │     - Total Ingresos                     │   │
│  │     - Total Egresos                      │   │
│  │     - Balance                            │   │
│  └──────────────────────────────────────────┘   │
│  ┌──────────────────────────────────────────┐   │
│  │  📋 Lista de Movimientos                 │   │
│  │     - Concepto                           │   │
│  │     - Categoría                          │   │
│  │     - Monto                              │   │
│  │     - Fecha                              │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  [➕ Botón Nuevo Movimiento]                    │   │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│      AgregarMovimientoScreen (UI)               │
│  ┌──────────────────────────────────────────┐   │
│  │  📝 Formulario                           │   │
│  │     ○ Tipo (Ingreso/Egreso)             │   │
│  │     ○ Concepto                          │   │
│  │     ○ Monto                             │   │
│  │     ○ Categoría                         │   │
│  │     ○ Fecha                             │   │
│  │     ○ Grupo                             │   │
│  │                                          │   │
│  │  [💾 Guardar]                           │   │
│  └──────────────────────────────────────────┘   │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│       MovimientosProvider (State Management)    │
│                                                  │
│  📦 Estado:                                      │
│     - List<Movimiento> _movimientos             │
│     - bool _isLoading                           │
│     - bool _isInitialized                       │
│     - String? _error                            │
│                                                  │
│  🔧 Métodos:                                     │
│     - init()                                     │
│     - cargarMovimientos()                       │
│     - agregarMovimiento()                       │
│     - obtenerResumenMes()                       │
│     - filtrarPorTipo()                          │
│                                                  │
│  📊 Getters:                                     │
│     - totalIngresos                             │
│     - totalEgresos                              │
│     - balance                                   │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│      GoogleSheetsService (Data Layer)           │
│                                                  │
│  🔑 Configuración:                               │
│     - credentials (Service Account JSON)        │
│     - spreadsheetId                             │
│     - worksheetTitle                            │
│                                                  │
│  🔧 Métodos:                                     │
│     - init()                                     │
│     - obtenerMovimientos()                      │
│     - agregarMovimiento()                       │
│     - obtenerResumenMes()                       │
│     - obtenerCategorias()                      │
│     - obtenerGrupos()                          │
└────────────────────┬────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────┐
│           Google Sheets API                      │
│                                                  │
│  📄 Hoja de Cálculo: "Hoja 1"                   │  │
│  ┌──────────────────────────────────────────┐   │
│  │ fecha | mes | tipo | categoria | ...    │   │
│  ├──────────────────────────────────────────┤   │
│  │ 13/11 | nov | Egreso | Alimen... | ...   │   │
│  │ 12/11 | nov | Ingreso | Salario | ...    │   │
│  │ ...                                      │   │
│  └──────────────────────────────────────────┘   │
│                                                  │
│  📋 Hoja de Configuración: "Config"             │
│  ┌─────────────────┬─────────────────────────┐  │
│  │ A (Categorías)  │ B (Grupos)              │  │
│  ├─────────────────┼─────────────────────────┤  │
│  │ Categorías      │ Grupos                  │  │
│  │ Salario         │ Personal                │  │
│  │ Alimentación    │ Familia                 │  │
│  │ Transporte      │ Trabajo                 │  │
│  │ ...             │ ...                     │  │
│  └─────────────────┴─────────────────────────┘  │
└─────────────────────────────────────────────────┘
```

## 🎯 Flujo de Datos

### 1. Inicialización de la App

```
main.dart
  ├─> Inicializar Provider (MovimientosProvider)
  ├─> Configurar tema y localización (es_ES)
  └─> Navegar a HomeScreen

HomeScreen.initState()
  └─> Provider.init()
       ├─> GoogleSheetsService.init()
       │    └─> Autenticar con credenciales
       └─> cargarMovimientos()
            └─> GoogleSheetsService.obtenerMovimientos()
                 └─> GET request a Google Sheets API
                      └─> Parsear filas a List<Movimiento>
```

### 2. Agregar un Nuevo Movimiento

```
Usuario presiona [➕ Nuevo]
  └─> Navegar a AgregarMovimientoScreen
       └─> Usuario llena formulario
            └─> Usuario presiona [💾 Guardar]
                 └─> Validar formulario
                      └─> Crear objeto Movimiento
                           └─> Provider.agregarMovimiento()
                                ├─> GoogleSheetsService.agregarMovimiento()
                                │    └─> POST request a Google Sheets API
                                │         └─> Agregar fila a la hoja
                                └─> Actualizar estado local
                                     └─> notifyListeners()
                                          └─> HomeScreen se actualiza (rebuild)
```

### 3. Actualizar Lista de Movimientos

```
Usuario presiona [🔄 Refresh]
  └─> Provider.cargarMovimientos()
       └─> GoogleSheetsService.obtenerMovimientos()
            └─> GET request a Google Sheets API
                 └─> Parsear todas las filas
                      └─> Actualizar _movimientos
                           └─> notifyListeners()
                                └─> UI se actualiza
```

### 4. Carga de Configuración Dinámica (Categorías y Grupos)

```
Usuario abre AgregarMovimientoScreen o EditarMovimientoScreen
  └─> initState() se ejecuta
       └─> _cargarConfiguracion()
            └─> Provider.obtenerCategorias()
            │    └─> GoogleSheetsService.obtenerCategorias()
            │         └─> GET Column A from "Config" sheet (fromRow: 2)
            │              └─> Filtrar celdas vacías
            │                   └─> Retornar List<String> con valores por defecto si hay error
            │                        └─> Actualizar _categorias
            │
            └─> Provider.obtenerGrupos()
                 └─> GoogleSheetsService.obtenerGrupos()
                      └─> GET Column B from "Config" sheet (fromRow: 2)
                           └─> Filtrar celdas vacías
                                └─> Retornar List<String> con valores por defecto si hay error
                                     └─> Actualizar _grupos
                                          └─> setState() para actualizar UI
                                               └─> Dropdowns muestran opciones dinámicas
```

**Características:**

- Las categorías y grupos se cargan cada vez que se abre el formulario
- Los cambios en la hoja Config se reflejan inmediatamente en la app
- Si hay error, se usan valores predeterminados para no bloquear la funcionalidad
- Las categorías ya no dependen del tipo de movimiento (Ingreso/Egreso)
- El campo Grupo ahora es un dropdown en lugar de texto libre

## 📦 Modelo de Datos

### Movimiento

```dart
class Movimiento {
  String fecha;       // "13/11/2025"
  String mes;         // "noviembre"
  String tipo;        // "Ingreso" | "Egreso"
  String categoria;   // "Alimentación", "Salario", etc.
  String concepto;    // "Compra en supermercado"
  double monto;       // 1500.50
  String grupo;       // "Personal", "Familia", etc.
}
```

## 🔄 Patrón de Diseño

### Provider Pattern (State Management)

```
┌────────────────────┐
│  ChangeNotifier   │
│   (Provider)      │
└────────┬───────────┘
         │
         ├─> notifyListeners()
         │    └─> Notifica a todos los widgets escuchando
         │
         ▼
┌────────────────────┐
│    Consumer        │
│  (Widget listener) │
└────────────────────┘
         │
         └─> Widget se reconstruye automáticamente
```

**Ventajas:**

- ✅ Separación de lógica y UI
- ✅ Estado reactivo
- ✅ Fácil de testear
- ✅ Evita prop drilling

## 🛠️ Componentes Principales

### 1. HomeScreen

- **Responsabilidad:** Mostrar lista de movimientos y resumen
- **Estado:** Consume MovimientosProvider
- **Acciones:** Navegar a agregar, refrescar lista, ver detalles

### 2. AgregarMovimientoScreen

- **Responsabilidad:** Capturar datos de nuevo movimiento
- **Estado:** Local (formulario) + Provider (guardar)
- **Validaciones:** Campos requeridos, formato de monto

### 3. MovimientosProvider

- **Responsabilidad:** Gestionar estado de movimientos
- **Métodos:** CRUD operations, filtros, cálculos
- **Notificaciones:** Automáticas al cambiar estado

### 4. GoogleSheetsService

- **Responsabilidad:** Comunicación con Google Sheets API
- **Autenticación:** Service Account
- **Operaciones:** Read, Write, Append

## 🔐 Seguridad

### Actual (Desarrollo)

```
App → Credenciales hardcodeadas → Google Sheets API
```

### Recomendado (Producción)

```
App → Firebase Auth → Cloud Function → Google Sheets API
                    ↓
              Validación de permisos
```

## 📱 Responsive Design

La app está diseñada para adaptarse a diferentes tamaños de pantalla:

- **Móvil:** Layout optimizado para una columna
- **Tablet:** Puede mostrar más información sin scroll
- **Orientación:** Se adapta automáticamente

## 🎨 Temas y Colores

```dart
Principal: Teal (Colors.teal)
├─> Ingreso: Green
├─> Egreso: Red
├─> Fondo: Grey[100]
└─> Cards: White con elevation
```

## 📊 Gestión de Estados

```
Estado Inicial
  ├─> isLoading: false
  ├─> isInitialized: false
  ├─> movimientos: []
  └─> error: null

Cargando
  ├─> isLoading: true
  └─> Mostrar CircularProgressIndicator

Éxito
  ├─> isLoading: false
  ├─> isInitialized: true
  ├─> movimientos: [datos]
  └─> Mostrar lista

Error
  ├─> isLoading: false
  ├─> error: "mensaje"
  └─> Mostrar pantalla de error
```

## 🚀 Optimizaciones Futuras

1. **Caché Local:**

   - SQLite/Hive para datos offline
   - Sincronización cuando hay conexión

2. **Paginación:**

   - Cargar movimientos por lotes
   - Scroll infinito

3. **Filtros Avanzados:**

   - Por rango de fechas
   - Por categorías múltiples
   - Por monto mínimo/máximo

4. **Gráficas:**

   - Charts de ingresos vs egresos
   - Distribución por categorías
   - Tendencias mensuales

5. **Exportación:**
   - PDF reports
   - Excel export
   - Backup automático
