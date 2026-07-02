# Arquitectura Actual

## Resumen

La app migró de un flujo acoplado a Google Sheets a una arquitectura local-first:

```text
Pantallas Flutter
  -> MovimientosProvider
  -> Repositorios locales
  -> Drift / SQLite
  -> Sync queue
  -> Contrato Supabase desactivado
```

## Capas

### UI

- `HomeScreen`: resumen, filtro, listado, detalle y acceso a gestión de catálogos.
- `AgregarMovimientoScreen` y `EditarMovimientoScreen`: formularios conectados a repositorios locales.
- `GestionCatalogosScreen`: CRUD local de categorías y grupos.

### Estado

- `MovimientosProvider` centraliza carga, errores, mutaciones y refresco desde la base local.

### Datos

- `AppDatabase` define tablas:
  - `categories`
  - `movement_groups`
  - `movements`
  - `sync_queue_entries`
  - `app_settings`
- `LocalMovimientosRepository` y `LocalCatalogosRepository` encapsulan acceso y reglas.

### Sincronización

- `SyncCoordinator` encola operaciones `create`, `update` y `delete`.
- `SupabaseSyncService` deja preparado el contrato remoto, pero no ejecuta sync real en esta fase.
- La política futura prevista es `last-write-wins`.

## Decisiones importantes

- Los movimientos usan UUID cliente, no índices posicionales.
- Las fechas se almacenan como `DateTime`, no como strings.
- Los montos se almacenan como `amountCents` para evitar errores de precisión.
- Categorías y grupos ya no dependen de una hoja `Config`; viven en SQLite y se administran desde la app.

## Estado futuro previsto

Próxima fase:

1. Google Auth
2. `owner_id` por usuario
3. Sync real con Supabase
4. Exportes a PDF, Excel, correo y Google Sheets
