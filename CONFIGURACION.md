# Configuración de Google Sheets para la App de Finanzas

## 📝 Pasos para configurar

### 1. Obtener credenciales de Google Cloud

1. **Crear proyecto en Google Cloud Console:**

   - Visita: https://console.cloud.google.com/
   - Crea un nuevo proyecto llamado "Finanzas App"

2. **Habilitar Google Sheets API:**

   - En el menú lateral: APIs y servicios > Biblioteca
   - Busca "Google Sheets API"
   - Haz clic en "Habilitar"

3. **Crear Service Account:**

   - Ve a: APIs y servicios > Credenciales
   - Clic en "Crear credenciales" > "Cuenta de servicio"
   - Nombre: `finanzas-app-service`
   - Rol: Ninguno necesario
   - Clic en "Crear y continuar" > "Listo"

4. **Descargar credenciales JSON:**
   - En la lista de Service Accounts, haz clic en la que creaste
   - Pestaña "Claves"
   - "Agregar clave" > "Crear clave nueva"
   - Selecciona formato JSON
   - Guarda el archivo descargado

### 2. Configurar Google Sheet

1. **Crear hoja de cálculo:**

   - Visita: https://sheets.google.com
   - Crea una nueva hoja llamada "Finanzas Personales"

2. **Configurar encabezados (Primera fila):**

   ```
   fecha | mes | tipo | categoria | concepto | monto | grupo
   ```

3. **Compartir con Service Account:**

   - Haz clic en "Compartir"
   - Pega el email del Service Account (lo encuentras en el JSON como `client_email`)
   - Dale permisos de "Editor"
   - Desmarca "Notificar a las personas"
   - Haz clic en "Compartir"

4. **Copiar ID de la hoja:**
   - De la URL: `https://docs.google.com/spreadsheets/d/[ID_AQUI]/edit`
   - Copia el ID que está entre `/d/` y `/edit`

### 3. Actualizar el código

Abre: `lib/services/google_sheets_service.dart`

**Reemplaza:**

```dart
// Línea 11-22: Pega TODO el contenido del archivo JSON descargado
static const _credentials = r'''
{
  "type": "service_account",
  "project_id": "...",
  "private_key_id": "...",
  "private_key": "...",
  "client_email": "...",
  ...
}
''';

// Línea 26: Pega el ID de tu Google Sheet
static const _spreadsheetId = 'TU_ID_AQUI';

// Línea 29: Si tu hoja tiene otro nombre, cámbialo aquí
static const _worksheetTitle = 'Hoja 1';
```

### 4. Ejecutar la app

```bash
flutter pub get
flutter run
```

## 🎯 Ejemplo de datos en Google Sheet

| fecha      | mes       | tipo    | categoria    | concepto            | monto   | grupo    |
| ---------- | --------- | ------- | ------------ | ------------------- | ------- | -------- |
| 13/11/2025 | noviembre | Egreso  | Alimentación | Compra supermercado | 1500.50 | Personal |
| 13/11/2025 | noviembre | Ingreso | Salario      | Pago quincenal      | 5000.00 | Trabajo  |
| 12/11/2025 | noviembre | Egreso  | Transporte   | Recarga tarjeta     | 500.00  | Personal |

## ⚠️ Notas importantes

- El archivo JSON con las credenciales es sensible, **NO lo subas a repositorios públicos**
- Agrega `google_credentials.json` al `.gitignore` si lo guardas como archivo
- Las credenciales en el código son para desarrollo, para producción usa variables de entorno
- El Service Account debe tener permisos de "Editor" en la hoja

## 🔐 Seguridad

Para producción, considera:

1. Usar variables de entorno para las credenciales
2. Implementar Firebase Authentication
3. Usar Cloud Functions como intermediario
4. Agregar validaciones del lado del servidor

## 📞 ¿Necesitas ayuda?

Si tienes problemas con la configuración:

1. Verifica que Google Sheets API esté habilitada
2. Confirma que compartiste la hoja con el Service Account
3. Revisa que el ID de la hoja sea correcto
4. Mira los logs en la consola de Flutter: `flutter run -v`
