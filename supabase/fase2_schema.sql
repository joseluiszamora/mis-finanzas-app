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

select
  to_regclass('public.categories') as categories_table,
  to_regclass('public.groups') as groups_table,
  to_regclass('public.transactions') as transactions_table;
