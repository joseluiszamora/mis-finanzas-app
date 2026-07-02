# Fase 2: Supabase, Esquema y Sincronización

## Objetivo del documento

Este documento define la implementación técnica de Fase 2 para habilitar sincronización real multi-dispositivo sobre la base local-first construida en Fase 1.

Incluye:

- esquema SQL de Supabase
- políticas RLS
- contratos JSON por entidad
- flujo exacto de `push` y `pull`
- estrategia de primer login y primera sincronización
- reglas de conflicto y reintentos

## Principios de diseño

- SQLite local sigue siendo la fuente inmediata de escritura.
- Supabase actúa como backend de sincronización y respaldo por usuario.
- Toda escritura ocurre primero en local y luego se encola.
- La sincronización remota solo se activa si existe sesión válida.
- La resolución inicial de conflictos será `last-write-wins` basada en `updated_at`.

## Identidad y sesión

### Proveedor de identidad

- Google Auth en cliente Flutter
- Supabase Auth como sistema de sesión y emisión de JWT

### Requisito

Cada fila remota debe pertenecer a un único usuario mediante `owner_id`, enlazado a `auth.uid()`.

### Flujo esperado

1. Usuario inicia sesión con Google.
2. Flutter obtiene sesión válida en Supabase.
3. La app activa `ENABLE_REMOTE_SYNC=true` de forma efectiva en runtime.
4. La app usa `owner_id = auth.uid()` para toda operación remota.

## Esquema SQL recomendado

```sql
create extension if not exists "pgcrypto";

create table if not exists public.categories (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz null
);

create table if not exists public.groups (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz null
);

create table if not exists public.transactions (
  id uuid primary key,
  owner_id uuid not null references auth.users(id) on delete cascade,
  tipo text not null check (tipo in ('ingreso', 'egreso')),
  categoria_id uuid not null references public.categories(id),
  grupo_id uuid null references public.groups(id),
  concepto text not null,
  amount_cents integer not null check (amount_cents > 0),
  occurred_at timestamptz not null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  deleted_at timestamptz null
);
```

## Índices recomendados

```sql
create index if not exists categories_owner_id_idx
  on public.categories(owner_id);

create index if not exists categories_owner_updated_at_idx
  on public.categories(owner_id, updated_at desc);

create index if not exists categories_owner_deleted_at_idx
  on public.categories(owner_id, deleted_at);

create unique index if not exists categories_owner_name_active_idx
  on public.categories(owner_id, lower(name))
  where deleted_at is null;

create index if not exists groups_owner_id_idx
  on public.groups(owner_id);

create index if not exists groups_owner_updated_at_idx
  on public.groups(owner_id, updated_at desc);

create index if not exists groups_owner_deleted_at_idx
  on public.groups(owner_id, deleted_at);

create unique index if not exists groups_owner_name_active_idx
  on public.groups(owner_id, lower(name))
  where deleted_at is null;

create index if not exists transactions_owner_id_idx
  on public.transactions(owner_id);

create index if not exists transactions_owner_updated_at_idx
  on public.transactions(owner_id, updated_at desc);

create index if not exists transactions_owner_occurred_at_idx
  on public.transactions(owner_id, occurred_at desc);

create index if not exists transactions_owner_deleted_at_idx
  on public.transactions(owner_id, deleted_at);

create index if not exists transactions_owner_category_idx
  on public.transactions(owner_id, categoria_id);

create index if not exists transactions_owner_group_idx
  on public.transactions(owner_id, grupo_id);
```

## Trigger para `updated_at`

```sql
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists categories_set_updated_at on public.categories;
create trigger categories_set_updated_at
before update on public.categories
for each row
execute function public.set_updated_at();

drop trigger if exists groups_set_updated_at on public.groups;
create trigger groups_set_updated_at
before update on public.groups
for each row
execute function public.set_updated_at();

drop trigger if exists transactions_set_updated_at on public.transactions;
create trigger transactions_set_updated_at
before update on public.transactions
for each row
execute function public.set_updated_at();
```

## Políticas RLS

### Activación

```sql
alter table public.categories enable row level security;
alter table public.groups enable row level security;
alter table public.transactions enable row level security;
```

### Categorías

```sql
create policy "categories_select_own"
on public.categories
for select
using (owner_id = auth.uid());

create policy "categories_insert_own"
on public.categories
for insert
with check (owner_id = auth.uid());

create policy "categories_update_own"
on public.categories
for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "categories_delete_own"
on public.categories
for delete
using (owner_id = auth.uid());
```

### Grupos

```sql
create policy "groups_select_own"
on public.groups
for select
using (owner_id = auth.uid());

create policy "groups_insert_own"
on public.groups
for insert
with check (owner_id = auth.uid());

create policy "groups_update_own"
on public.groups
for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "groups_delete_own"
on public.groups
for delete
using (owner_id = auth.uid());
```

### Movimientos

```sql
create policy "transactions_select_own"
on public.transactions
for select
using (owner_id = auth.uid());

create policy "transactions_insert_own"
on public.transactions
for insert
with check (owner_id = auth.uid());

create policy "transactions_update_own"
on public.transactions
for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());

create policy "transactions_delete_own"
on public.transactions
for delete
using (owner_id = auth.uid());
```

## Contratos JSON por entidad

### Categoría

```json
{
  "id": "7c28f0f3-87b6-4f92-8d66-bf756dc24e7f",
  "owner_id": "8d1ee53e-8440-461a-8cd6-4ed4c1ef0df3",
  "name": "Alimentación",
  "created_at": "2026-07-01T18:00:00.000Z",
  "updated_at": "2026-07-01T18:00:00.000Z",
  "deleted_at": null
}
```

### Grupo

```json
{
  "id": "4458cf95-cfc6-4c03-81f9-e34436d50744",
  "owner_id": "8d1ee53e-8440-461a-8cd6-4ed4c1ef0df3",
  "name": "Familia",
  "created_at": "2026-07-01T18:00:00.000Z",
  "updated_at": "2026-07-01T18:00:00.000Z",
  "deleted_at": null
}
```

### Movimiento

```json
{
  "id": "2cdf2ef8-37c1-4b8e-a5bc-3763df70a3fb",
  "owner_id": "8d1ee53e-8440-461a-8cd6-4ed4c1ef0df3",
  "tipo": "egreso",
  "categoria_id": "7c28f0f3-87b6-4f92-8d66-bf756dc24e7f",
  "grupo_id": "4458cf95-cfc6-4c03-81f9-e34436d50744",
  "concepto": "Supermercado",
  "amount_cents": 15250,
  "occurred_at": "2026-07-01T12:00:00.000Z",
  "created_at": "2026-07-01T18:00:00.000Z",
  "updated_at": "2026-07-01T18:10:00.000Z",
  "deleted_at": null
}
```

## Mapeo local -> remoto

### Tabla `categories`

Local:

- `id`
- `name`
- `createdAt`
- `updatedAt`
- `deletedAt`

Remoto:

- `id`
- `owner_id`
- `name`
- `created_at`
- `updated_at`
- `deleted_at`

### Tabla `movement_groups`

Local:

- `id`
- `name`
- `createdAt`
- `updatedAt`
- `deletedAt`

Remoto:

- `id`
- `owner_id`
- `name`
- `created_at`
- `updated_at`
- `deleted_at`

### Tabla `movements`

Local:

- `id`
- `tipo`
- `categoriaId`
- `grupoId`
- `concepto`
- `amountCents`
- `occurredAt`
- `createdAt`
- `updatedAt`
- `deletedAt`

Remoto:

- `id`
- `owner_id`
- `tipo`
- `categoria_id`
- `grupo_id`
- `concepto`
- `amount_cents`
- `occurred_at`
- `created_at`
- `updated_at`
- `deleted_at`

## Flujo de `push`

### Objetivo

Procesar la cola `sync_queue_entries` y reflejar en Supabase los cambios hechos localmente.

### Orden de procesamiento

1. categorías
2. grupos
3. movimientos

Esto evita errores de claves foráneas cuando un movimiento depende de registros aún no subidos.

### Reglas generales

- Procesar la cola ordenada por `createdAt`.
- Ignorar si no hay sesión válida.
- Ignorar si `ENABLE_REMOTE_SYNC` es falso.
- Ejecutar de a una mutación por vez.
- En caso de éxito:
  - marcar entidad local como `synced`
  - eliminar entrada de `sync_queue_entries`
- En caso de error:
  - incrementar `attemptCount`
  - guardar `lastError`
  - calcular `nextRetryAt`

### Operación `create`

Acción:

- hacer `upsert` remoto usando el mismo UUID local

Motivo:

- permite idempotencia
- evita duplicados si la operación se reintenta

### Operación `update`

Acción:

- hacer `upsert` remoto usando `id`
- incluir `updated_at` local
- no tocar `created_at`

### Operación `delete`

Acción:

- no borrar físicamente
- actualizar `deleted_at`
- actualizar `updated_at`

## Flujo de `pull`

### Objetivo

Descargar cambios remotos hechos en otros dispositivos del mismo usuario.

### Cursor local

Guardar en `app_settings`:

- `last_sync_categories_at`
- `last_sync_groups_at`
- `last_sync_transactions_at`

### Consulta incremental recomendada

```sql
select *
from public.transactions
where owner_id = auth.uid()
  and updated_at > :last_sync_at
order by updated_at asc;
```

La misma lógica aplica para `categories` y `groups`.

### Aplicación local del pull

Para cada fila remota:

1. buscar por `id` en SQLite
2. si no existe, insertar
3. si existe y remoto es más nuevo, sobrescribir
4. si `deleted_at` no es null, marcar borrado local
5. actualizar cursor de sync al último `updated_at` aplicado

## Política de conflictos

### Regla inicial

`last-write-wins` usando `updated_at`.

### Comparación

- si remoto `updated_at` > local `updatedAt`, gana remoto
- si local `updatedAt` > remoto `updated_at`, gana local cuando haga push

### Caso delicado

Si una entidad local aún tiene entradas pendientes en `sync_queue_entries`, el pull no debe sobreescribir ciegamente sin revisar ese estado.

### Regla recomendada

- si la entidad local tiene sync pendiente, no aplicar overwrite inmediato
- dejar el merge para cuando la mutación local termine de procesarse
- si se quiere simplificar la primera versión:
  - permitir overwrite remoto solo si no hay mutaciones pendientes para ese `entityId`

## Estrategia de reintentos

### Campos ya disponibles

- `attemptCount`
- `lastError`
- `nextRetryAt`

### Backoff recomendado

- intento 1: inmediato
- intento 2: +30 segundos
- intento 3: +2 minutos
- intento 4: +10 minutos
- intento 5+: +30 minutos

### Errores reintentables

- timeout
- red no disponible
- error 5xx
- rate limiting

### Errores no reintentables automáticos

- JWT inválido
- fila rechazada por RLS
- payload inválido
- referencia a categoría o grupo inexistente

## Primer login con datos locales ya creados

### Objetivo

Subir a Supabase el estado local existente sin duplicar información.

### Estrategia recomendada

- usar los UUID locales actuales como IDs definitivos remotos
- subir categorías y grupos primero
- subir movimientos después
- usar `upsert` en todo el primer `push`

### Secuencia recomendada

1. login exitoso
2. activar sync remoto
3. convertir toda entidad local no sincronizada a `pendingCreate` si aún no lo estaba
4. llenar la cola si faltan entradas
5. ejecutar `push`
6. ejecutar `pull`
7. guardar cursores `last_sync_*`

## Consultas sugeridas desde Flutter

### Upsert de categoría

```dart
await supabase.from('categories').upsert({
  'id': id,
  'owner_id': ownerId,
  'name': name,
  'created_at': createdAt.toIso8601String(),
  'updated_at': updatedAt.toIso8601String(),
  'deleted_at': deletedAt?.toIso8601String(),
});
```

### Upsert de grupo

```dart
await supabase.from('groups').upsert({
  'id': id,
  'owner_id': ownerId,
  'name': name,
  'created_at': createdAt.toIso8601String(),
  'updated_at': updatedAt.toIso8601String(),
  'deleted_at': deletedAt?.toIso8601String(),
});
```

### Upsert de movimiento

```dart
await supabase.from('transactions').upsert({
  'id': id,
  'owner_id': ownerId,
  'tipo': tipo,
  'categoria_id': categoriaId,
  'grupo_id': grupoId,
  'concepto': concepto,
  'amount_cents': amountCents,
  'occurred_at': occurredAt.toIso8601String(),
  'created_at': createdAt.toIso8601String(),
  'updated_at': updatedAt.toIso8601String(),
  'deleted_at': deletedAt?.toIso8601String(),
});
```

## Cambios de código sugeridos para Fase 2

### Nuevos componentes

- `lib/data/auth/auth_repository.dart`
- `lib/providers/auth_provider.dart`
- `lib/data/sync/supabase_sync_service.dart`
  Implementación real de `push` y `pull`
- `lib/data/sync/sync_worker.dart`
  Ejecutor programado o manual de sincronización

### Cambios sobre código actual

- `main.dart`
  - inicializar Supabase con valores reales
  - restaurar sesión
- `MovimientosProvider`
  - reaccionar a cambios de sesión
  - exponer estado de sync más rico
- `SyncCoordinator`
  - separar `pushPendingEntries` y `pullRemoteChanges`
  - ordenar cola por tipo de entidad
- `AppDatabase`
  - agregar settings para cursores de sync

## Estados de UI recomendados

- `No autenticado`
- `Autenticado sin sincronización inicial`
- `Sincronización pendiente`
- `Sincronizando`
- `Sincronizado`
- `Error de sincronización`

## Criterios de aceptación de Fase 2

- login con Google funcionando
- tablas remotas creadas con RLS activo
- push de categorías, grupos y movimientos funcionando
- pull incremental funcionando
- borrado lógico funcionando entre dispositivos
- dos dispositivos con la misma cuenta convergen al mismo estado
- `flutter analyze` y `flutter test` siguen pasando

## Decisiones explícitas recomendadas

- mantener `groups` como nombre de tabla remota, aunque en SQL sea palabra común
- usar siempre UUID cliente, no UUID generado en servidor
- usar `deleted_at` en lugar de delete físico
- no usar triggers complejos de merge en base; resolver merge en cliente en esta fase
- no activar realtime de Supabase todavía; empezar con sync por pull manual/background

## Próximo paso recomendado

Implementar primero estas piezas, en este orden:

1. Google Auth + sesión persistente
2. SQL y RLS en Supabase
3. `pushMutation` real
4. pull incremental por cursores
5. UI de estado de sync
6. pruebas de conflicto y multi-dispositivo
