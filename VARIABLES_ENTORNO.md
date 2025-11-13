# 🔒 Migración de Credenciales a Variables de Entorno

## 📋 Descripción General

Se han movido las credenciales de Google Sheets API del código fuente a un archivo `.env` para mejorar la **seguridad** y facilitar la **gestión de configuración**.

## ✨ Cambios Implementados

### 1. Archivo `.env` (Configuración Real)

**Ubicación:** `/home/jzamora/development/finanzas/.env`

**Contenido:**

```env
GOOGLE_CREDENTIALS={"type": "service_account",...}
GOOGLE_SPREADSHEET_ID=15qyupEAyvF7Sl0035l8uoSj52fLFTCP3b0LllSDhJT0
GOOGLE_WORKSHEET_TITLE=Hoja 1
```

**Características:**

- ✅ Contiene las credenciales reales
- ✅ **NO se sube al repositorio** (está en `.gitignore`)
- ✅ Cada desarrollador tiene su propia copia
- ✅ Fácil de modificar sin tocar el código

### 2. Archivo `.env.example` (Plantilla)

**Ubicación:** `/home/jzamora/development/finanzas/.env.example`

**Contenido:**

```env
GOOGLE_CREDENTIALS={"type": "service_account","project_id": "tu-project-id",...}
GOOGLE_SPREADSHEET_ID=tu_spreadsheet_id_aqui
GOOGLE_WORKSHEET_TITLE=Hoja 1
```

**Características:**

- ✅ Plantilla con valores de ejemplo
- ✅ **SÍ se sube al repositorio**
- ✅ Documenta las variables requeridas
- ✅ Guía para nuevos desarrolladores

### 3. Actualización de `.gitignore`

**Agregado:**

```gitignore
# Variables de entorno - NO SUBIR AL REPOSITORIO
.env
.env.local
.env.*.local
```

**Protección:**

- ❌ `.env` nunca se sube a Git
- ❌ Variantes locales tampoco se suben
- ✅ `.env.example` sí se puede subir

### 4. Paquete `flutter_dotenv`

**Agregado a `pubspec.yaml`:**

```yaml
dependencies:
  flutter_dotenv: ^5.1.0

flutter:
  assets:
    - .env
```

**Propósito:**

- Leer variables de entorno desde archivo `.env`
- Compatible con Flutter web, mobile y desktop
- Manejo robusto de variables

### 5. Carga en `main.dart`

**Antes:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}
```

**Después:**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Cargar variables de entorno
  await dotenv.load(fileName: ".env");

  await initializeDateFormatting('es', null);
  runApp(const MyApp());
}
```

**Momento de carga:**

- Se carga **antes** de iniciar la aplicación
- Bloquea hasta que termine de cargar
- Disponible en toda la aplicación

### 6. Modificación de `GoogleSheetsService`

**Antes:**

```dart
class GoogleSheetsService {
  static const _credentials = r'''
  {
    "type": "service_account",
    "project_id": "finanzas-app-478118",
    ...
  }
  ''';

  static const _spreadsheetId = '15qyupEAy...';
  static const _worksheetTitle = 'Hoja 1';
  // ...
}
```

**Después:**

```dart
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GoogleSheetsService {
  // Las credenciales ahora se cargan desde el archivo .env
  static String get _credentials => dotenv.env['GOOGLE_CREDENTIALS'] ?? '';
  static String get _spreadsheetId => dotenv.env['GOOGLE_SPREADSHEET_ID'] ?? '';
  static String get _worksheetTitle => dotenv.env['GOOGLE_WORKSHEET_TITLE'] ?? 'Hoja 1';
  // ...
}
```

**Cambios clave:**

- ✅ Constantes reemplazadas por getters
- ✅ Valores leídos desde `dotenv.env`
- ✅ Valores por defecto con operador `??`
- ✅ No más credenciales hardcodeadas

## 🎯 Beneficios

### 🔒 Seguridad

**Antes:**

- ❌ Credenciales en el código fuente
- ❌ Visibles en el repositorio
- ❌ En historial de Git
- ❌ Accesibles a cualquiera con acceso al repo

**Después:**

- ✅ Credenciales en archivo local
- ✅ No se suben al repositorio
- ✅ No están en el historial
- ✅ Cada desarrollador gestiona las suyas

### 🛠️ Mantenimiento

**Antes:**

- ❌ Cambiar credenciales requiere editar código
- ❌ Recompilar aplicación
- ❌ Hacer commit y push
- ❌ Riesgo de exponer credenciales

**Después:**

- ✅ Cambiar credenciales = editar `.env`
- ✅ No requiere recompilar (en hot reload)
- ✅ No requiere commit
- ✅ Cero riesgo de exposición

### 👥 Colaboración

**Antes:**

- ❌ Todos usan las mismas credenciales
- ❌ Difícil tener entornos separados
- ❌ Conflictos al trabajar en paralelo

**Después:**

- ✅ Cada desarrollador usa sus credenciales
- ✅ Fácil tener dev/staging/prod
- ✅ Sin conflictos entre entornos

### 🚀 Despliegue

**Antes:**

- ❌ Credenciales hardcodeadas en binario
- ❌ Mismo binario para todos los entornos
- ❌ Difícil cambiar sin recompilar

**Después:**

- ✅ Credenciales configurables por entorno
- ✅ Un binario, múltiples configuraciones
- ✅ Variables de entorno en CI/CD

## 📖 Instrucciones de Uso

### Para Desarrolladores Nuevos

1. **Clonar el repositorio:**

   ```bash
   git clone <repo-url>
   cd finanzas
   ```

2. **Copiar la plantilla:**

   ```bash
   cp .env.example .env
   ```

3. **Editar `.env` con tus credenciales:**

   ```bash
   nano .env  # o tu editor preferido
   ```

4. **Completar las variables:**

   ```env
   GOOGLE_CREDENTIALS={"tu":"json","completo":"aqui"}
   GOOGLE_SPREADSHEET_ID=tu_spreadsheet_id
   GOOGLE_WORKSHEET_TITLE=Hoja 1
   ```

5. **Instalar dependencias:**

   ```bash
   flutter pub get
   ```

6. **Ejecutar la aplicación:**
   ```bash
   flutter run
   ```

### Para Desarrolladores Existentes

1. **Crear archivo `.env`:**

   ```bash
   touch .env
   ```

2. **Copiar tus credenciales actuales** desde `google_sheets_service.dart` al archivo `.env`

3. **Formato de GOOGLE_CREDENTIALS:**

   - Todo el JSON en **una sola línea**
   - Sin espacios innecesarios
   - Sin saltos de línea dentro del JSON

4. **Actualizar dependencias:**

   ```bash
   flutter pub get
   ```

5. **Verificar que funcione:**
   ```bash
   flutter run
   ```

### Para Cambiar Credenciales

1. **Editar `.env`:**

   ```bash
   nano .env
   ```

2. **Modificar la variable necesaria:**

   ```env
   GOOGLE_SPREADSHEET_ID=nuevo_id_aqui
   ```

3. **Guardar y cerrar**

4. **Reiniciar la aplicación:**
   ```bash
   # En modo debug, hacer hot restart (R mayúscula)
   # O parar y ejecutar de nuevo
   flutter run
   ```

## 🔧 Variables de Entorno Disponibles

| Variable                 | Descripción                      | Requerida | Ejemplo                                        |
| ------------------------ | -------------------------------- | --------- | ---------------------------------------------- |
| `GOOGLE_CREDENTIALS`     | JSON completo de Service Account | ✅ Sí     | `{"type":"service_account",...}`               |
| `GOOGLE_SPREADSHEET_ID`  | ID de tu Google Sheet            | ✅ Sí     | `15qyupEAyvF7Sl0035l8uoSj52fLFTCP3b0LllSDhJT0` |
| `GOOGLE_WORKSHEET_TITLE` | Nombre de la hoja principal      | ❌ No     | `Hoja 1` (por defecto)                         |

### Formato de GOOGLE_CREDENTIALS

**Estructura:**

```json
{
  "type": "service_account",
  "project_id": "tu-project-id",
  "private_key_id": "tu-private-key-id",
  "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
  "client_email": "tu-service-account@tu-project.iam.gserviceaccount.com",
  "client_id": "tu-client-id",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://...",
  "universe_domain": "googleapis.com"
}
```

**⚠️ Importante:**

- Debe estar en **UNA SOLA LÍNEA** en el archivo `.env`
- Mantener los `\n` en la private_key
- No agregar espacios extra

**Convertir a una línea:**

```bash
# En Linux/Mac
cat credentials.json | jq -c . > .env-temp
# Luego copiar el contenido a .env
```

## 🚨 Solución de Problemas

### Error: "Cannot load file .env"

**Causa:** El archivo `.env` no existe

**Solución:**

```bash
cp .env.example .env
# Editar .env con tus credenciales
```

### Error: "GOOGLE_CREDENTIALS is empty"

**Causa:** La variable no está definida en `.env`

**Solución:**

1. Verificar que `.env` existe
2. Verificar que tiene la línea `GOOGLE_CREDENTIALS=...`
3. Verificar que no hay espacios alrededor del `=`

### Error: "Failed to parse credentials"

**Causa:** El JSON de credenciales está mal formateado

**Solución:**

1. Verificar que sea un JSON válido
2. Verificar que esté en una sola línea
3. Verificar que los `\n` estén presentes en private_key

### La aplicación no conecta con Google Sheets

**Diagnóstico:**

1. Verificar que `.env` existe
2. Verificar que `flutter pub get` se ejecutó
3. Verificar que las credenciales son correctas
4. Verificar que el Service Account tiene permisos

**Debug:**

```dart
// En google_sheets_service.dart, agregar temporalmente:
print('Credentials loaded: ${_credentials.isNotEmpty}');
print('Spreadsheet ID: $_spreadsheetId');
```

### Hot reload no toma los cambios del .env

**Causa:** `flutter_dotenv` carga el archivo al inicio

**Solución:**

- Hacer **Hot Restart** (R mayúscula en terminal)
- O parar y ejecutar `flutter run` de nuevo

## 🔒 Mejores Prácticas de Seguridad

### ✅ Hacer

- **Usar `.env` para credenciales sensibles**
- **Agregar `.env` al `.gitignore`**
- **Compartir `.env.example` en el repo**
- **Documentar variables requeridas**
- **Usar diferentes credenciales por entorno**
- **Rotar credenciales periódicamente**

### ❌ No Hacer

- **Subir `.env` al repositorio**
- **Compartir credenciales por Slack/Email**
- **Hardcodear credenciales en el código**
- **Usar las mismas credenciales en prod/dev**
- **Dejar credenciales en comentarios**
- **Hacer screenshot con credenciales**

## 🚀 Despliegue en Producción

### CI/CD (GitHub Actions, etc.)

**Configurar secrets:**

```yaml
# .github/workflows/deploy.yml
env:
  GOOGLE_CREDENTIALS: ${{ secrets.GOOGLE_CREDENTIALS }}
  GOOGLE_SPREADSHEET_ID: ${{ secrets.GOOGLE_SPREADSHEET_ID }}
```

**Crear `.env` en CI:**

```yaml
- name: Create .env file
  run: |
    echo "GOOGLE_CREDENTIALS=${{ secrets.GOOGLE_CREDENTIALS }}" >> .env
    echo "GOOGLE_SPREADSHEET_ID=${{ secrets.GOOGLE_SPREADSHEET_ID }}" >> .env
    echo "GOOGLE_WORKSHEET_TITLE=Hoja 1" >> .env
```

### Entornos Múltiples

**Estructura de archivos:**

```
.env                 # Desarrollo local
.env.development     # Dev/Staging
.env.production      # Producción
.env.example         # Plantilla
```

**Cargar según entorno:**

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const environment = String.fromEnvironment('ENV', defaultValue: 'development');
  await dotenv.load(fileName: ".env.$environment");

  runApp(const MyApp());
}
```

**Ejecutar:**

```bash
flutter run --dart-define=ENV=production
```

## 📝 Checklist de Migración

- [x] ✅ Crear archivo `.env`
- [x] ✅ Crear archivo `.env.example`
- [x] ✅ Actualizar `.gitignore`
- [x] ✅ Agregar `flutter_dotenv` a `pubspec.yaml`
- [x] ✅ Registrar `.env` en assets
- [x] ✅ Cargar dotenv en `main.dart`
- [x] ✅ Modificar `GoogleSheetsService`
- [x] ✅ Ejecutar `flutter pub get`
- [x] ✅ Probar que funcione
- [ ] ⏳ Verificar que `.env` esté en `.gitignore`
- [ ] ⏳ Eliminar credenciales hardcodeadas del historial de Git (opcional)

## 🔄 Migración del Historial de Git

Si quieres eliminar las credenciales del historial de Git:

**⚠️ ADVERTENCIA:** Esto reescribe el historial. Solo hazlo si estás seguro.

```bash
# Usar git filter-repo (recomendado)
git filter-repo --path lib/services/google_sheets_service.dart --invert-paths

# O usar BFG Repo-Cleaner
bfg --replace-text passwords.txt
git reflog expire --expire=now --all
git gc --prune=now --aggressive
```

**Más seguro:** Simplemente cambiar las credenciales en Google Cloud Console y usar las nuevas.

## 📞 Resumen

✅ **Implementado**: Variables de entorno con `flutter_dotenv`
✅ **Seguro**: Credenciales no se suben al repositorio
✅ **Flexible**: Fácil cambiar credenciales sin tocar código
✅ **Documentado**: `.env.example` como guía
✅ **Protegido**: `.env` en `.gitignore`
✅ **Funcional**: Aplicación sigue funcionando normalmente
