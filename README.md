# Mis Finanzas

Aplicación Flutter para gestión financiera personal con arquitectura local-first.

## Estado actual

- La fuente de verdad es SQLite local usando `drift`.
- La app funciona sin red.
- `Supabase` queda preparado como siguiente paso para sincronización multi-dispositivo, pero en esta fase no está activo.
- Google Sheets deja de ser backend transaccional y queda reservado para una futura capa de exportación/reportes.

## Capacidades incluidas

- Registro de ingresos y egresos
- Edición y eliminación por ID estable
- Resumen de ingresos, egresos y balance
- Filtro por categoría
- Administración local de categorías y grupos dentro de la app
- Cola local de sincronización preparada para futuras operaciones remotas

## Arquitectura

```text
Flutter UI
  -> Provider
  -> Repositories
  -> Drift / SQLite
  -> Sync queue local
  -> Supabase contract (desactivado)
```

### Piezas clave

- `lib/data/local/app_database.dart`
  Base de datos local, tablas y seed inicial.
- `lib/data/repositories/`
  Reglas de negocio y acceso a datos.
- `lib/data/sync/`
  Cola de sync y contrato remoto preparado.
- `lib/providers/movimientos_provider.dart`
  Estado de UI sobre repositorios locales.

## Configuración

### 1. Instalar dependencias

```bash
flutter pub get
```

### 2. Generar código de Drift

En este entorno fue necesario usar JIT:

```bash
flutter pub run build_runner build --force-jit
```

### 3. Ejecutar la app

```bash
flutter run
```

## Sync remoto futuro

La app ya lee estos `dart-defines`, pero en esta fase el sync real sigue desactivado:

```bash
--dart-define=ENABLE_REMOTE_SYNC=false
--dart-define=SUPABASE_URL=
--dart-define=SUPABASE_ANON_KEY=
```

Cuando se active la siguiente fase, la identidad prevista es Google Auth + Supabase.

## Pruebas

```bash
flutter analyze
flutter test
```

## Documentación vigente

- `README.md`
- `ARQUITECTURA.md`

Los demás documentos Markdown de la raíz quedaron archivados porque describían la arquitectura antigua basada en Google Sheets.
