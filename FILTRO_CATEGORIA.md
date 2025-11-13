# 🔍 Filtro por Categoría - Nueva Funcionalidad

## 📋 Descripción General

Se ha agregado un **filtro por categoría** en la pantalla principal (HomeScreen) que permite a los usuarios filtrar la lista de movimientos mostrando solo los de una categoría específica.

## ✨ Características Implementadas

### 1. Dropdown de Filtro

- **Ubicación**: Entre la tarjeta de resumen y la lista de movimientos
- **Diseño**: Card blanco con ícono de filtro y dropdown integrado
- **Opciones**:
  - "Todas las categorías" (opción por defecto)
  - Lista dinámica de categorías desde la hoja Config

### 2. Filtrado Dinámico

- **Tiempo real**: Al seleccionar una categoría, la lista se filtra instantáneamente
- **Sin recarga**: No requiere llamada a Google Sheets, filtra los datos en memoria
- **Reversible**: Puedes volver a "Todas las categorías" en cualquier momento

### 3. Estado Vacío Inteligente

- **Mensaje personalizado**: Si no hay movimientos para la categoría seleccionada
- **Botón de limpiar**: Permite volver rápidamente a mostrar todos los movimientos
- **Icono visual**: Muestra ícono de búsqueda vacía (search_off)

## 🎯 Cambios Técnicos

### Variables de Estado Agregadas

```dart
class _HomeScreenState extends State<HomeScreen> {
  String? _categoriaFiltro; // null = Todas las categorías
  List<String> _categorias = [];
  bool _isLoadingCategorias = true;
  // ...
}
```

**Propósito:**

- `_categoriaFiltro`: Almacena la categoría seleccionada (null = todas)
- `_categorias`: Lista de categorías cargadas desde Config
- `_isLoadingCategorias`: Indica si las categorías están cargándose

### Método de Carga de Categorías

```dart
Future<void> _cargarCategorias() async {
  setState(() {
    _isLoadingCategorias = true;
  });

  try {
    final provider = Provider.of<MovimientosProvider>(context, listen: false);
    final categorias = await provider.obtenerCategorias();

    setState(() {
      _categorias = categorias;
      _isLoadingCategorias = false;
    });
  } catch (e) {
    print('Error al cargar categorías: $e');
    setState(() {
      _isLoadingCategorias = false;
    });
  }
}
```

**Se ejecuta en `initState()`** junto con la inicialización del provider.

### Widget de Filtro

```dart
Widget _buildFiltroCategoria() {
  return Container(
    // Diseño: Card blanco con sombra
    child: Row(
      children: [
        Icon(Icons.filter_list), // Ícono de filtro
        Text('Filtrar por:'),
        DropdownButton<String?>(
          value: _categoriaFiltro,
          items: [
            'Todas las categorías', // Opción por defecto
            ...categorías dinámicas
          ],
          onChanged: (value) {
            setState(() {
              _categoriaFiltro = value;
            });
          },
        ),
      ],
    ),
  );
}
```

**Características:**

- Estado de carga con `CircularProgressIndicator`
- Dropdown expandible (`isExpanded: true`)
- Sin línea inferior (`underline: Container()`)

### Lógica de Filtrado

```dart
Widget _buildMovimientosList(MovimientosProvider provider) {
  // Filtrar movimientos
  final movimientosFiltrados = _categoriaFiltro == null
      ? provider.movimientos
      : provider.movimientos
          .where((m) => m.categoria == _categoriaFiltro)
          .toList();

  // Verificar si hay resultados
  if (movimientosFiltrados.isEmpty) {
    return _buildEmptyStateConFiltro();
  }

  // Mostrar lista filtrada
  return ListView.builder(
    itemCount: movimientosFiltrados.length,
    itemBuilder: (context, index) {
      final movimiento = movimientosFiltrados[index];
      final realIndex = provider.movimientos.indexOf(movimiento);
      return _buildMovimientoCard(movimiento, realIndex);
    },
  );
}
```

**Detalles importantes:**

- **Preserva índices reales**: Para editar/eliminar correctamente
- **Filtrado en memoria**: No hace llamadas a Google Sheets
- **Estado vacío personalizado**: Muestra mensaje específico cuando no hay resultados

## 🎨 Interfaz de Usuario

### Diseño del Filtro

```
┌─────────────────────────────────────────────┐
│  🔍 Filtrar por: [Todas las categorías ▼]  │
└─────────────────────────────────────────────┘
```

**Características visuales:**

- Fondo blanco con sombra sutil
- Padding simétrico para mejor espaciado
- Ícono de filtro en color teal
- Dropdown sin borde inferior para look limpio

### Estado Vacío con Filtro

```
        🔍 (ícono grande)

     No hay movimientos
  para la categoría "Alimentación"

     [🗑️ Limpiar filtro]
```

**Diferente al estado vacío general:**

- Ícono específico de búsqueda vacía
- Mensaje incluye la categoría seleccionada
- Botón para limpiar filtro rápidamente

## 🔄 Flujo de Usuario

### Caso de Uso 1: Filtrar por Categoría

1. Usuario abre la app
2. Ve la tarjeta de resumen y todos los movimientos
3. Hace clic en el dropdown "Todas las categorías"
4. Selecciona "Alimentación"
5. La lista se actualiza instantáneamente
6. Solo se muestran movimientos de Alimentación
7. La tarjeta de resumen sigue mostrando totales generales

### Caso de Uso 2: No hay Movimientos en Categoría

1. Usuario filtra por una categoría sin movimientos
2. Ve mensaje: "No hay movimientos para la categoría [nombre]"
3. Puede hacer clic en "Limpiar filtro"
4. Vuelve a ver todos los movimientos

### Caso de Uso 3: Editar/Eliminar Movimiento Filtrado

1. Usuario filtra por categoría
2. Desliza un movimiento para editar o eliminar
3. La acción se ejecuta correctamente usando el índice real
4. Al volver, el filtro se mantiene activo

## 📊 Datos Mostrados

### Tarjeta de Resumen

✅ **NO se filtra** - Siempre muestra:

- Total de todos los ingresos
- Total de todos los egresos
- Balance general

**Razón**: Los totales deben reflejar la situación financiera completa, independientemente del filtro.

### Lista de Movimientos

✅ **SÍ se filtra** - Muestra solo:

- Movimientos de la categoría seleccionada
- En orden cronológico inverso (más recientes primero)

## 🛠️ Comportamiento Técnico

### Carga de Categorías

**Cuándo se carga:**

- Al iniciar la aplicación (`initState`)
- En paralelo con la carga de movimientos

**Fuente de datos:**

- Hoja "Config", columna A de Google Sheets
- Usa `provider.obtenerCategorias()`

**Manejo de errores:**

- Si falla, muestra lista vacía en dropdown
- Imprime error en consola para debugging
- No bloquea la funcionalidad de la app

### Preservación de Índices

```dart
final realIndex = provider.movimientos.indexOf(movimiento);
```

**Importancia:**

- Los movimientos filtrados tienen índices locales (0, 1, 2...)
- Al editar/eliminar, se necesita el índice real en la lista completa
- `indexOf()` encuentra la posición original del movimiento

**Ejemplo:**

```
Lista completa: [A, B, C, D, E]
Filtrada (cat X): [B, D]
Índice local de B: 0
Índice real de B: 1 ← Se usa este para editar/eliminar
```

### Rendimiento

**Optimizaciones:**

- ✅ Filtrado en memoria (no requiere red)
- ✅ `setState` solo actualiza UI, no recarga datos
- ✅ Categorías se cargan una sola vez
- ✅ No hay recargas innecesarias de Google Sheets

**Complejidad:**

- Filtrado: O(n) donde n = número de movimientos
- Búsqueda de índice real: O(n)
- Aceptable para listas de cientos de movimientos

## 🎯 Mejoras Futuras (Opcional)

### 1. Múltiples Filtros

- Filtrar por tipo (Ingreso/Egreso) además de categoría
- Filtrar por rango de fechas
- Filtrar por grupo

### 2. Resumen Filtrado

- Opción para mostrar totales solo de categoría filtrada
- Toggle para alternar entre resumen completo y filtrado

### 3. Filtros Guardados

- Guardar filtro preferido en SharedPreferences
- Aplicar último filtro usado al abrir la app

### 4. Búsqueda por Texto

- Campo de búsqueda para filtrar por concepto
- Combinar búsqueda con filtro de categoría

### 5. Chips de Filtros Activos

- Mostrar chips con filtros aplicados
- Permitir quitar filtros individualmente

### 6. Animaciones

- Transición suave al aplicar filtros
- Fade in/out de movimientos

## 📝 Notas Importantes

### Interacción con Otras Funcionalidades

**Agregar movimiento:**

- Al agregar un nuevo movimiento y volver
- El filtro **se mantiene activo**
- Si el nuevo movimiento no pertenece a la categoría filtrada, no se verá
- Usuario puede limpiar filtro para verlo

**Editar movimiento:**

- Al editar la categoría de un movimiento filtrado
- Si cambia a otra categoría, desaparecerá de la vista filtrada
- Al volver, el filtro sigue activo

**Actualizar (Pull to refresh):**

- Al hacer pull-to-refresh, se recargan los movimientos
- El filtro **se mantiene activo**
- La lista se vuelve a filtrar automáticamente

**Botón de refresh en AppBar:**

- Recarga movimientos desde Google Sheets
- El filtro **se mantiene activo**

### Casos Especiales

**Sin conexión:**

- Si no hay conexión, las categorías pueden no cargar
- El dropdown mostrará solo "Todas las categorías"
- Los movimientos en caché aún se pueden filtrar

**Categoría eliminada de Config:**

- Si un movimiento tiene una categoría que ya no existe en Config
- Aún se puede filtrar usando los movimientos existentes
- El dropdown no mostrará esa categoría como opción

**Primer uso:**

- Si no hay movimientos, el filtro aparece pero está deshabilitado
- Mensaje de estado vacío general (no el de filtro)

## ✅ Testing Sugerido

### Pruebas Funcionales

1. **Filtrado básico:**

   - ✅ Seleccionar cada categoría
   - ✅ Verificar que solo se muestren movimientos correctos
   - ✅ Verificar que totales no cambien

2. **Estado vacío:**

   - ✅ Filtrar por categoría sin movimientos
   - ✅ Verificar mensaje personalizado
   - ✅ Verificar botón de limpiar filtro

3. **Persistencia de filtro:**

   - ✅ Aplicar filtro
   - ✅ Agregar movimiento
   - ✅ Verificar que filtro siga activo al volver

4. **Editar con filtro:**

   - ✅ Filtrar lista
   - ✅ Editar un movimiento
   - ✅ Verificar que use índice correcto

5. **Eliminar con filtro:**
   - ✅ Filtrar lista
   - ✅ Eliminar un movimiento
   - ✅ Verificar que se elimine el correcto

### Pruebas de UI

1. **Carga de categorías:**

   - ✅ Verificar spinner durante carga
   - ✅ Verificar que dropdown aparezca después

2. **Responsive:**

   - ✅ Verificar en diferentes tamaños de pantalla
   - ✅ Verificar que dropdown se expanda correctamente

3. **Animaciones:**
   - ✅ Verificar transición al filtrar (rebuild inmediato)

## 📞 Resumen

✅ **Implementado**: Filtro por categoría totalmente funcional
✅ **Carga dinámica**: Categorías desde Google Sheets Config
✅ **UI intuitiva**: Dropdown claro con ícono y estado de carga
✅ **Estado vacío**: Mensaje personalizado cuando no hay resultados
✅ **Preserva funcionalidad**: Editar/eliminar funcionan correctamente
✅ **Rendimiento**: Filtrado rápido en memoria sin llamadas de red
