import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_environment.dart';
import '../local/app_database.dart';
import 'sync_types.dart';

abstract class RemoteSyncService {
  Future<void> upsertCategory({
    required String ownerId,
    required Category category,
  });

  Future<void> upsertGroup({
    required String ownerId,
    required MovementGroup group,
  });

  Future<void> upsertMovement({
    required String ownerId,
    required Movement movement,
  });

  Future<void> deleteCategory({
    required String ownerId,
    required Category category,
  });

  Future<void> deleteGroup({
    required String ownerId,
    required MovementGroup group,
  });

  Future<void> deleteMovement({
    required String ownerId,
    required Movement movement,
  });

  Future<RemoteChanges> pullChanges({
    required String ownerId,
    required DateTime? lastCategoriesSyncAt,
    required DateTime? lastGroupsSyncAt,
    required DateTime? lastMovementsSyncAt,
  });
}

class SupabaseSyncService implements RemoteSyncService {
  const SupabaseSyncService({required this.environment, SupabaseClient? client})
    : _client = client;

  final AppEnvironment environment;
  final SupabaseClient? _client;

  SupabaseClient get _supabase => _client ?? Supabase.instance.client;

  static const remoteSchemaSql = '''
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

create or replace function public.set_updated_at()
returns trigger
language plpgsql
as \$\$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
\$\$;

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

alter table public.categories enable row level security;
alter table public.groups enable row level security;
alter table public.transactions enable row level security;

drop policy if exists "categories_select_own" on public.categories;
create policy "categories_select_own"
on public.categories for select
using (owner_id = auth.uid());
drop policy if exists "categories_insert_own" on public.categories;
create policy "categories_insert_own"
on public.categories for insert
with check (owner_id = auth.uid());
drop policy if exists "categories_update_own" on public.categories;
create policy "categories_update_own"
on public.categories for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());
drop policy if exists "categories_delete_own" on public.categories;
create policy "categories_delete_own"
on public.categories for delete
using (owner_id = auth.uid());

drop policy if exists "groups_select_own" on public.groups;
create policy "groups_select_own"
on public.groups for select
using (owner_id = auth.uid());
drop policy if exists "groups_insert_own" on public.groups;
create policy "groups_insert_own"
on public.groups for insert
with check (owner_id = auth.uid());
drop policy if exists "groups_update_own" on public.groups;
create policy "groups_update_own"
on public.groups for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());
drop policy if exists "groups_delete_own" on public.groups;
create policy "groups_delete_own"
on public.groups for delete
using (owner_id = auth.uid());

drop policy if exists "transactions_select_own" on public.transactions;
create policy "transactions_select_own"
on public.transactions for select
using (owner_id = auth.uid());
drop policy if exists "transactions_insert_own" on public.transactions;
create policy "transactions_insert_own"
on public.transactions for insert
with check (owner_id = auth.uid());
drop policy if exists "transactions_update_own" on public.transactions;
create policy "transactions_update_own"
on public.transactions for update
using (owner_id = auth.uid())
with check (owner_id = auth.uid());
drop policy if exists "transactions_delete_own" on public.transactions;
create policy "transactions_delete_own"
on public.transactions for delete
using (owner_id = auth.uid());
''';

  @override
  Future<void> upsertCategory({
    required String ownerId,
    required Category category,
  }) async {
    await _supabase
        .from('categories')
        .upsert(_categoryPayload(ownerId, category));
  }

  @override
  Future<void> upsertGroup({
    required String ownerId,
    required MovementGroup group,
  }) async {
    await _supabase.from('groups').upsert(_groupPayload(ownerId, group));
  }

  @override
  Future<void> upsertMovement({
    required String ownerId,
    required Movement movement,
  }) async {
    await _supabase
        .from('transactions')
        .upsert(_movementPayload(ownerId, movement));
  }

  @override
  Future<void> deleteCategory({
    required String ownerId,
    required Category category,
  }) async {
    await _supabase
        .from('categories')
        .update(_deletePayload(category.deletedAt, category.updatedAt))
        .eq('id', category.id)
        .eq('owner_id', ownerId);
  }

  @override
  Future<void> deleteGroup({
    required String ownerId,
    required MovementGroup group,
  }) async {
    await _supabase
        .from('groups')
        .update(_deletePayload(group.deletedAt, group.updatedAt))
        .eq('id', group.id)
        .eq('owner_id', ownerId);
  }

  @override
  Future<void> deleteMovement({
    required String ownerId,
    required Movement movement,
  }) async {
    await _supabase
        .from('transactions')
        .update(_deletePayload(movement.deletedAt, movement.updatedAt))
        .eq('id', movement.id)
        .eq('owner_id', ownerId);
  }

  @override
  Future<RemoteChanges> pullChanges({
    required String ownerId,
    required DateTime? lastCategoriesSyncAt,
    required DateTime? lastGroupsSyncAt,
    required DateTime? lastMovementsSyncAt,
  }) async {
    final categories = await _pullTable(
      'categories',
      ownerId,
      lastCategoriesSyncAt,
    );
    final groups = await _pullTable('groups', ownerId, lastGroupsSyncAt);
    final movements = await _pullTable(
      'transactions',
      ownerId,
      lastMovementsSyncAt,
    );

    return RemoteChanges(
      categories: categories.map(_remoteCategoryFromJson).toList(),
      groups: groups.map(_remoteGroupFromJson).toList(),
      movements: movements.map(_remoteMovementFromJson).toList(),
    );
  }

  Future<List<Map<String, dynamic>>> _pullTable(
    String table,
    String ownerId,
    DateTime? lastSyncAt,
  ) async {
    final cursor =
        (lastSyncAt ?? DateTime.fromMillisecondsSinceEpoch(0, isUtc: true))
            .toUtc()
            .toIso8601String();
    final response = await _supabase
        .from(table)
        .select()
        .eq('owner_id', ownerId)
        .gt('updated_at', cursor)
        .order('updated_at', ascending: true);
    return response.cast<Map<String, dynamic>>();
  }

  Map<String, dynamic> _categoryPayload(String ownerId, Category category) {
    return {
      'id': category.id,
      'owner_id': ownerId,
      'name': category.name,
      'created_at': category.createdAt.toUtc().toIso8601String(),
      'updated_at': category.updatedAt.toUtc().toIso8601String(),
      'deleted_at': category.deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _groupPayload(String ownerId, MovementGroup group) {
    return {
      'id': group.id,
      'owner_id': ownerId,
      'name': group.name,
      'created_at': group.createdAt.toUtc().toIso8601String(),
      'updated_at': group.updatedAt.toUtc().toIso8601String(),
      'deleted_at': group.deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _movementPayload(String ownerId, Movement movement) {
    return {
      'id': movement.id,
      'owner_id': ownerId,
      'tipo': movement.tipo,
      'categoria_id': movement.categoriaId,
      'grupo_id': movement.grupoId,
      'concepto': movement.concepto,
      'amount_cents': movement.amountCents,
      'occurred_at': movement.occurredAt.toUtc().toIso8601String(),
      'created_at': movement.createdAt.toUtc().toIso8601String(),
      'updated_at': movement.updatedAt.toUtc().toIso8601String(),
      'deleted_at': movement.deletedAt?.toUtc().toIso8601String(),
    };
  }

  Map<String, dynamic> _deletePayload(DateTime? deletedAt, DateTime updatedAt) {
    final effectiveDeletedAt = deletedAt ?? updatedAt;
    return {
      'deleted_at': effectiveDeletedAt.toUtc().toIso8601String(),
      'updated_at': updatedAt.toUtc().toIso8601String(),
    };
  }

  RemoteCategoryRow _remoteCategoryFromJson(Map<String, dynamic> json) {
    return RemoteCategoryRow(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseNullableDate(json['deleted_at']),
    );
  }

  RemoteGroupRow _remoteGroupFromJson(Map<String, dynamic> json) {
    return RemoteGroupRow(
      id: json['id'] as String,
      name: json['name'] as String,
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseNullableDate(json['deleted_at']),
    );
  }

  RemoteMovementRow _remoteMovementFromJson(Map<String, dynamic> json) {
    return RemoteMovementRow(
      id: json['id'] as String,
      tipo: json['tipo'] as String,
      categoriaId: json['categoria_id'] as String,
      grupoId: json['grupo_id'] as String?,
      concepto: json['concepto'] as String,
      amountCents: json['amount_cents'] as int,
      occurredAt: _parseDate(json['occurred_at']),
      createdAt: _parseDate(json['created_at']),
      updatedAt: _parseDate(json['updated_at']),
      deletedAt: _parseNullableDate(json['deleted_at']),
    );
  }

  DateTime _parseDate(Object? value) {
    return DateTime.parse(value as String).toUtc();
  }

  DateTime? _parseNullableDate(Object? value) {
    if (value == null) {
      return null;
    }
    return _parseDate(value);
  }
}
