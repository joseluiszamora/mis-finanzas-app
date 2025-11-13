# 📋 Configuración de la Hoja Config

## Descripción General

La aplicación ahora utiliza una hoja llamada **"Config"** en tu Google Sheet para definir dinámicamente las categorías y grupos disponibles en los formularios de crear y editar movimientos.

## Estructura de la Hoja Config

La hoja "Config" debe tener dos columnas:

### Columna A: Categorías

- **Celda A1**: Título (por ejemplo: "Categorías")
- **A2 en adelante**: Lista de categorías disponibles

### Columna B: Grupos

- **Celda B1**: Título (por ejemplo: "Grupos")
- **B2 en adelante**: Lista de grupos disponibles

## Ejemplo de Configuración

| A (Categorías)  | B (Grupos) |
| --------------- | ---------- |
| Categorías      | Grupos     |
| Salario         | Personal   |
| Freelance       | Familia    |
| Alimentación    | Trabajo    |
| Transporte      | Hogar      |
| Vivienda        | Inversión  |
| Servicios       |            |
| Salud           |            |
| Educación       |            |
| Entretenimiento |            |
| Inversiones     |            |

## Pasos para Configurar

1. **Crear la hoja Config**

   - Abre tu Google Sheet
   - Crea una nueva hoja llamada exactamente **"Config"** (sin comillas)

2. **Agregar las categorías**

   - En la celda A1, escribe "Categorías"
   - A partir de A2, escribe una categoría por celda
   - Puedes agregar tantas categorías como necesites

3. **Agregar los grupos**
   - En la celda B1, escribe "Grupos"
   - A partir de B2, escribe un grupo por celda
   - Puedes agregar tantos grupos como necesites

## Características

### ✅ Ventajas

- **Flexibilidad**: Modifica las categorías y grupos directamente desde Google Sheets sin cambiar el código
- **Centralizado**: Todos los usuarios de la app verán las mismas opciones
- **Fácil mantenimiento**: Agrega, edita o elimina opciones cuando quieras

### 🔄 Comportamiento de la App

- **Categorías unificadas**: Ya no hay separación entre categorías de Ingreso y Egreso. Todas las categorías están disponibles para ambos tipos
- **Grupos como dropdown**: El campo Grupo ahora es un menú desplegable en lugar de texto libre
- **Validación automática**: Al editar un movimiento, si la categoría o grupo ya no existe en Config, se deseleccionará automáticamente
- **Valores por defecto**: Si hay algún error al cargar la configuración, la app usará valores predeterminados

### ⚠️ Consideraciones

1. **Nombre exacto**: La hoja debe llamarse exactamente "Config" (respeta mayúsculas/minúsculas)
2. **Columnas específicas**: Las categorías deben estar en la columna A y los grupos en la columna B
3. **Celdas vacías**: La app ignora automáticamente las celdas vacías
4. **Primera fila**: La primera fila (A1 y B1) se usa como título y no se incluye en las opciones

## Valores por Defecto

Si la hoja Config no existe o hay un error, la aplicación usará estos valores por defecto:

**Categorías predeterminadas:**

- Salario
- Alimentación
- Transporte
- Vivienda
- Otro

**Grupos predeterminados:**

- Personal
- Familia
- Trabajo

## Ejemplo Práctico

### Escenario: Agregar una nueva categoría

1. Abre tu Google Sheet
2. Ve a la hoja "Config"
3. En la columna A, busca la primera celda vacía después de tus categorías existentes
4. Escribe la nueva categoría (por ejemplo: "Mascotas")
5. La próxima vez que abras el formulario en la app, verás "Mascotas" en el menú de categorías

### Escenario: Cambiar un grupo existente

1. Abre tu Google Sheet
2. Ve a la hoja "Config"
3. En la columna B, encuentra el grupo que quieres cambiar
4. Edita el texto (por ejemplo: cambiar "Hogar" por "Casa")
5. Los movimientos ya creados mantendrán el valor antiguo, pero los nuevos usarán el nuevo valor

## Sincronización

La app carga las categorías y grupos cada vez que:

- Abres el formulario de agregar movimiento
- Abres el formulario de editar movimiento

Esto significa que los cambios en la hoja Config se reflejan casi inmediatamente en la aplicación.

## Solución de Problemas

### Problema: Las categorías no aparecen en el dropdown

**Solución:**

1. Verifica que la hoja se llame exactamente "Config"
2. Confirma que las categorías estén en la columna A, empezando en A2
3. Asegúrate de que las celdas no estén completamente vacías

### Problema: Aparecen las categorías por defecto en lugar de las mías

**Solución:**

1. Revisa que tu cuenta de servicio tenga permisos de lectura en la hoja
2. Verifica que el nombre de la hoja sea correcto
3. Comprueba los logs de la app para ver si hay mensajes de error

### Problema: Al editar un movimiento, la categoría aparece vacía

**Solución:**

- Esto ocurre cuando la categoría del movimiento ya no existe en la hoja Config
- Simplemente selecciona una nueva categoría válida y guarda los cambios
