# 💰 App de Finanzas Personales

Aplicación móvil Flutter para registrar y gestionar movimientos financieros personales, sincronizados con Google Sheets.

## 📋 Características

- ✅ Registro de ingresos y egresos
- 📊 Visualización de movimientos en tiempo real
- 💾 Sincronización automática con Google Sheets
- 📈 Resumen de balance, ingresos y egresos totales
- 🎨 Interfaz moderna y amigable
- 📱 Categorías predefinidas personalizables
- 📅 Selección de fecha con calendario
- 🔄 Actualización en tiempo real

## 🚀 Configuración

### 1. Configurar Google Sheets

#### Paso 1: Crear un proyecto en Google Cloud Console

1. Ve a [Google Cloud Console](https://console.cloud.google.com/)
2. Crea un nuevo proyecto o selecciona uno existente
3. En el menú lateral, ve a **APIs y servicios** > **Biblioteca**
4. Busca y habilita **Google Sheets API**

#### Paso 2: Crear credenciales de Service Account

1. Ve a **APIs y servicios** > **Credenciales**
2. Haz clic en **Crear credenciales** > **Cuenta de servicio**
3. Completa el formulario:
   - Nombre: `finanzas-app-service`
   - ID: Se genera automáticamente
   - Descripción: `Service account para app de finanzas`
4. Haz clic en **Crear y continuar**
5. En permisos (opcional), puedes dejarlo en blanco y hacer clic en **Continuar**
6. Haz clic en **Listo**

#### Paso 3: Generar clave JSON

1. En la lista de cuentas de servicio, haz clic en la que acabas de crear
2. Ve a la pestaña **Claves**
3. Haz clic en **Agregar clave** > **Crear clave nueva**
4. Selecciona **JSON** y haz clic en **Crear**
5. Se descargará un archivo JSON con las credenciales

#### Paso 4: Configurar tu Google Sheet

1. Crea una nueva hoja de cálculo en [Google Sheets](https://sheets.google.com)
2. Nómbrala como quieras (ej: "Finanzas Personales")
3. **Hoja principal (Hoja 1)**: En la primera fila, crea los siguientes encabezados:
   ```
   fecha | mes | tipo | categoria | concepto | monto | grupo
   ```
4. **Hoja de configuración (Config)**: Crea una segunda hoja llamada "Config" con:

   - **Columna A**: Título "Categorías" en A1, luego lista de categorías desde A2
   - **Columna B**: Título "Grupos" en B1, luego lista de grupos desde B2

   Ver [HOJA_CONFIG.md](HOJA_CONFIG.md) para más detalles sobre cómo configurar esta hoja.

5. Comparte la hoja con el email de la cuenta de servicio:

   - Haz clic en **Compartir** (botón verde en la esquina superior derecha)
   - Pega el email de la cuenta de servicio (lo encuentras en el archivo JSON descargado, en el campo `client_email`)
   - Dale permisos de **Editor**
   - Desmarca "Notificar a las personas" para no enviar email
   - Haz clic en **Compartir**

6. Copia el ID de tu hoja de cálculo desde la URL:
   ```
   https://docs.google.com/spreadsheets/d/[ESTE_ES_EL_ID]/edit
   ```

### 2. Configurar la Aplicación

1. Abre el archivo `lib/services/google_sheets_service.dart`

2. Reemplaza las credenciales en la variable `_credentials`:

   ```dart
   static const _credentials = r'''
   {
     // Pega aquí todo el contenido del archivo JSON descargado
   }
   ''';
   ```

3. Reemplaza el ID de tu hoja de cálculo:

   ```dart
   static const _spreadsheetId = 'TU_SPREADSHEET_ID_AQUI';
   ```

4. Si tu hoja tiene un nombre diferente a "Hoja 1", actualiza:
   ```dart
   static const _worksheetTitle = 'NombreDeTuHoja';
   ```

### 3. Instalar dependencias

```bash
flutter pub get
```

### 4. Ejecutar la aplicación

```bash
# Para Android
flutter run

# Para iOS
flutter run

# Para web
flutter run -d chrome
```

## 📱 Uso de la Aplicación

### Pantalla Principal

- **Tarjeta de resumen**: Muestra el total de ingresos, egresos y balance
- **Lista de movimientos**: Muestra todos los movimientos registrados, los más recientes primero
- **Botón "Nuevo"**: Abre el formulario para agregar un nuevo movimiento
- **Botón de actualizar**: Sincroniza los datos con Google Sheets

### Agregar Movimiento

1. Selecciona el tipo: **Ingreso** o **Egreso**
2. Completa el formulario:
   - **Concepto**: Descripción del movimiento (obligatorio)
   - **Monto**: Cantidad en dinero (obligatorio)
   - **Categoría**: Selecciona de la lista dinámica desde Config (obligatorio)
   - **Fecha**: Selecciona del calendario (obligatorio)
   - **Grupo**: Selecciona de la lista dinámica desde Config (opcional)
3. Presiona **Guardar Movimiento**

### Editar o Eliminar Movimiento

- **Deslizar a la derecha** (fondo azul): Edita el movimiento
- **Deslizar a la izquierda** (fondo rojo): Elimina el movimiento (con confirmación)
- **Mantener presionado**: También abre el editor

### Configuración Dinámica

Las **categorías** y **grupos** se cargan dinámicamente desde la hoja "Config" de tu Google Sheet. Esto te permite:

- ✅ Agregar nuevas categorías sin modificar el código
- ✅ Personalizar los grupos según tus necesidades
- ✅ Mantener las opciones centralizadas para todos los usuarios

Ver [HOJA_CONFIG.md](HOJA_CONFIG.md) para más información sobre cómo configurar las categorías y grupos.

## 🛠️ Tecnologías Utilizadas

- **Flutter**: Framework principal
- **Provider**: Manejo de estado
- **gsheets**: Integración con Google Sheets API
- **intl**: Formateo de fechas y monedas

## 📂 Estructura del Proyecto

```
lib/
├── main.dart                           # Punto de entrada
├── models/
│   └── movimiento.dart                 # Modelo de datos
├── providers/
│   └── movimientos_provider.dart       # Manejo de estado
├── screens/
│   ├── home_screen.dart                # Pantalla principal
│   └── agregar_movimiento_screen.dart  # Formulario de nuevo movimiento
└── services/
    └── google_sheets_service.dart      # Servicio de Google Sheets
```

## 🔧 Personalización

### Agregar más categorías

Edita el archivo `lib/screens/agregar_movimiento_screen.dart` y modifica el mapa `_categoriasPorTipo`:

```dart
final Map<String, List<String>> _categoriasPorTipo = {
  'Ingreso': [
    'Tu nueva categoría',
    // ... más categorías
  ],
  'Egreso': [
    'Tu nueva categoría',
    // ... más categorías
  ],
};
```

### Cambiar los colores del tema

Edita `lib/main.dart` en la sección de `ThemeData`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Colors.tuColor, // Cambia aquí
    primary: Colors.tuColor,
  ),
),
```

## 🐛 Solución de Problemas

### Error de conexión con Google Sheets

1. Verifica que las credenciales estén correctamente copiadas
2. Asegúrate de haber compartido la hoja con el email de la cuenta de servicio
3. Verifica que el ID de la hoja sea correcto
4. Confirma que Google Sheets API esté habilitada en tu proyecto

### La aplicación no muestra datos

1. Verifica que la hoja tenga datos (al menos la fila de encabezados)
2. Presiona el botón de actualizar en la app
3. Revisa los logs de la consola para ver errores específicos

### Error al compilar

```bash
flutter clean
flutter pub get
flutter run
```

## 📄 Licencia

Este proyecto es de código abierto y está disponible bajo la Licencia MIT.

---

¡Disfruta gestionando tus finanzas! 💰📊
