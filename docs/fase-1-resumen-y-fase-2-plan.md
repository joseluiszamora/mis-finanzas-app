# Fase 1 y Plan de Fase 2

## Resumen de lo implementado en Fase 1

### Objetivo cumplido

Se completó la migración de una arquitectura basada en Google Sheets a una arquitectura local-first con SQLite, manteniendo la app funcional para el uso diario y dejando preparado el terreno para sincronización remota futura.

### Cambios implementados

#### 1. Fuente de verdad local

- Se reemplazó Google Sheets como backend transaccional.
- La fuente de verdad ahora es SQLite local usando `drift`.
- La app puede operar sin conexión.

Archivos principales:

- `lib/data/local/app_database.dart`
- `lib/main.dart`

#### 2. Nuevo modelo de datos

- `Movimiento` dejó de depender de índices o filas externas.
- Se introdujeron UUIDs generados en cliente como IDs estables.
- Las fechas ahora se almacenan como `DateTime`.
- Los montos ahora se almacenan como `amountCents`.
- Se agregaron estados de sincronización tipados.

Archivos principales:

- `lib/models/movimiento.dart`
- `lib/models/tipo_movimiento.dart`
- `lib/models/sync_status.dart`
- `lib/models/categoria.dart`
- `lib/models/grupo.dart`
- `lib/models/resumen_financiero.dart`

#### 3. Repositorios y separación de responsabilidades

- Se creó `LocalMovimientosRepository` para CRUD y resumen financiero.
- Se creó `LocalCatalogosRepository` para CRUD de categorías y grupos.
- La lógica dejó de vivir en servicios acoplados a una hoja externa.

Archivos principales:

- `lib/data/repositories/movimientos_repository.dart`
- `lib/data/repositories/catalogos_repository.dart`

#### 4. Cola de sincronización local

- Se creó una cola local para registrar mutaciones `create`, `update` y `delete`.
- Se dejó preparado `SyncCoordinator`.
- Se dejó preparado `SupabaseSyncService`, pero sin sync real activo aún.

Archivos principales:

- `lib/data/sync/sync_coordinator.dart`
- `lib/data/sync/supabase_sync_service.dart`
- `lib/config/app_environment.dart`

#### 5. UI adaptada a la nueva arquitectura

- `HomeScreen` ahora consume datos desde SQLite vía `provider`.
- Los movimientos se editan y eliminan por ID estable.
- Se agregó pantalla de administración de categorías y grupos.
- Los formularios de crear y editar ya no dependen de Google Sheets.
- La app muestra explícitamente que está corriendo en modo local.

Archivos principales:

- `lib/providers/movimientos_provider.dart`
- `lib/screens/home_screen.dart`
- `lib/screens/agregar_movimiento_screen.dart`
- `lib/screens/editar_movimiento_screen.dart`
- `lib/screens/gestion_catalogos_screen.dart`

#### 6. Limpieza de arquitectura anterior

- Se removió `google_sheets_service.dart` del flujo principal.
- La documentación principal se actualizó a la nueva arquitectura.
- Los documentos viejos de Google Sheets quedaron archivados.

### Resultado funcional de Fase 1

La app hoy permite:

- registrar ingresos y egresos
- editar y eliminar movimientos sin depender de índices visuales
- ver resumen de ingresos, egresos y balance
- filtrar por categoría
- administrar categorías y grupos desde la app
- trabajar 100% en local
- dejar trazadas las mutaciones para una futura sincronización remota

### Validación realizada

- `flutter analyze`: OK
- `flutter test`: OK

Nota de entorno:

- En esta máquina, para ejecutar `flutter test`, fue necesario usar un shim temporal de linker por una limitación del toolchain local de Flutter/Linux.
- El código del proyecto quedó correcto; ese workaround fue solo del entorno.

## Alcance de Fase 2

### Objetivo

Habilitar sincronización real multi-dispositivo usando Google Auth + Supabase, manteniendo el modelo local-first de Fase 1.

### Resultado esperado al cerrar Fase 2

El usuario podrá:

- iniciar sesión con Google
- usar la misma cuenta en varios dispositivos
- crear, editar y eliminar movimientos localmente
- sincronizar cambios con Supabase en background
- descargar cambios remotos al dispositivo
- resolver conflictos con una política inicial `last-write-wins`

## Plan detallado para Fase 2

### 1. Autenticación con Google

#### Objetivo

Agregar identidad real de usuario para desbloquear sincronización remota por cuenta.

#### Implementación

- Integrar `google_sign_in`.
- Completar la inicialización de `supabase_flutter` con configuración real.
- Autenticar al usuario en Supabase usando Google.
- Persistir sesión y restaurarla al iniciar la app.
- Agregar estado de sesión en `provider` o en un `AuthProvider` separado.

#### Cambios sugeridos

- Crear `lib/services/auth/` o `lib/data/auth/`.
- Agregar `AuthProvider` o `SessionProvider`.
- Agregar pantalla o flujo mínimo de login/logout.

#### Criterios de aceptación

- El usuario puede iniciar sesión con Google.
- La sesión persiste entre aperturas de la app.
- La app conoce un `ownerId` válido para sincronización.

### 2. Modelo remoto en Supabase

#### Objetivo

Crear la estructura remota equivalente a la estructura local.

#### Implementación

- Crear tablas remotas:
  - `categories`
  - `groups`
  - `transactions`
- Todas deben incluir:
  - `id`
  - `owner_id`
  - `created_at`
  - `updated_at`
  - `deleted_at`
- Aplicar `RLS` por `owner_id`.
- Añadir índices por `owner_id`, `updated_at` y `deleted_at`.

#### Criterios de aceptación

- Un usuario solo puede leer y escribir sus propios datos.
- El esquema remoto es compatible con el modelo local.

### 3. Activación real de SyncCoordinator

#### Objetivo

Conectar la cola local con Supabase para que las mutaciones locales se envíen realmente.

#### Implementación

- Activar `ENABLE_REMOTE_SYNC=true` cuando haya sesión válida.
- Implementar `pushMutation` en `SupabaseSyncService`.
- Procesar la cola `sync_queue_entries` en orden.
- Marcar registros como `synced` al confirmar escritura remota.
- Incrementar `attemptCount`, guardar `lastError` y usar `nextRetryAt` cuando falle una mutación.

#### Reglas iniciales

- No bloquear la UI por fallos remotos.
- Mantener la escritura local como primer paso siempre.
- Reintentar en background.

#### Criterios de aceptación

- Un movimiento creado localmente llega a Supabase.
- Updates y deletes también se reflejan remotamente.
- La cola se vacía cuando todo sincroniza bien.

### 4. Descarga de cambios remotos

#### Objetivo

Permitir que un dispositivo reciba cambios hechos desde otro dispositivo del mismo usuario.

#### Implementación

- Guardar `lastSyncAt` en `app_settings`.
- Implementar pull incremental por `updated_at`.
- Upsert local de categorías, grupos y movimientos.
- Respetar borrado lógico con `deleted_at`.
- Actualizar el snapshot local sin romper el modo offline.

#### Política inicial de conflictos

- `last-write-wins` usando `updated_at`.
- Si un cambio remoto es más reciente, sobrescribe el local ya sincronizado.
- Si un cambio local aún está en cola, el merge debe ocurrir cuando se procese esa mutación.

#### Criterios de aceptación

- Dos dispositivos del mismo usuario convergen al mismo estado.
- Los borrados remotos se reflejan localmente.

### 5. Estado de sincronización visible en UI

#### Objetivo

Dar feedback claro al usuario sobre lo que está pasando con sus datos.

#### Implementación

- Mostrar si la sesión está activa o no.
- Mostrar si el sync está:
  - inactivo
  - pendiente
  - sincronizando
  - con error
  - al día
- Exponer mensajes de error remotos accionables.
- Agregar acción manual “Sincronizar ahora”.

#### Criterios de aceptación

- El usuario entiende si sus cambios siguen solo en local o ya están en la nube.

### 6. Inicialización de catálogos por usuario

#### Objetivo

Separar claramente datos semilla globales de datos reales del usuario.

#### Implementación

- Definir si las categorías/grupos semilla se copian al espacio del usuario al primer login.
- Al primer sync con cuenta nueva:
  - subir categorías y grupos locales existentes
  - o recrearlos remotamente y reconciliar IDs si fuera necesario
- Evitar duplicados por nombre.

#### Decisión recomendada

- Mantener UUID local como ID definitivo y subir exactamente esos registros al primer sync.

### 7. Pruebas de Fase 2

#### Unit tests

- autenticación y restauración de sesión
- push de `create`, `update`, `delete`
- pull incremental
- resolución de conflictos `last-write-wins`
- borrado lógico

#### Integration tests

- login + primer sync
- sync desde dos dispositivos simulados
- recuperación después de error remoto
- reprocesamiento de cola fallida

#### Widget tests

- estados de sesión
- banners/estados de sincronización
- acción manual de “Sincronizar ahora”

## Riesgos principales de Fase 2

### 1. Conflictos silenciosos

Si la política `last-write-wins` se aplica sin visibilidad, el usuario puede sentir que “perdió” cambios.

Mitigación:

- mostrar última sincronización
- mostrar errores y reintentos
- registrar conflictos importantes para debugging

### 2. Primera sincronización de datos locales

El primer login de un usuario con datos ya creados offline requiere cuidado para no duplicar categorías/grupos/movimientos.

Mitigación:

- usar los UUID locales como IDs remotos
- hacer upsert, no inserts ciegos

### 3. Complejidad de estados

Con auth + sync + offline, el provider actual puede empezar a quedar muy cargado.

Mitigación:

- considerar separar `AuthProvider` de `MovimientosProvider`
- considerar separar estado de sync de estado de dominio

## Orden recomendado de implementación de Fase 2

1. Google Auth y sesión persistente
2. Esquema remoto y RLS en Supabase
3. Push real de la cola local
4. Pull incremental y merge local
5. Estado de sync visible en UI
6. Hardening de pruebas y manejo de errores

## Definición de terminado para Fase 2

La Fase 2 se considera terminada cuando:

- el usuario puede iniciar sesión con Google
- la app sincroniza categorías, grupos y movimientos con Supabase
- la app sigue funcionando offline
- los cambios convergen entre dos dispositivos del mismo usuario
- la cola local soporta errores y reintentos
- `flutter analyze` y `flutter test` siguen pasando
