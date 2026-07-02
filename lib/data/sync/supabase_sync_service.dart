import '../../config/app_environment.dart';

class SupabaseSyncService {
  const SupabaseSyncService({required this.environment});

  final AppEnvironment environment;

  static const remoteSchemaSql = '''
create table if not exists categories (
  id uuid primary key,
  owner_id uuid not null,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz null
);

create table if not exists groups (
  id uuid primary key,
  owner_id uuid not null,
  name text not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz null
);

create table if not exists transactions (
  id uuid primary key,
  owner_id uuid not null,
  tipo text not null,
  categoria_id uuid not null references categories(id),
  grupo_id uuid null references groups(id),
  concepto text not null,
  amount_cents integer not null,
  occurred_at timestamptz not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz null
);
''';

  Future<void> pushMutation(Map<String, dynamic> payload) async {
    if (!environment.enableRemoteSync) {
      return;
    }

    throw UnimplementedError(
      'La sincronización remota real se activará en la siguiente fase con Google Auth.',
    );
  }
}
