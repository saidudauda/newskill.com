-- NEWSKILL PRO starter schema for Supabase.
-- Run in Supabase SQL Editor after creating the project.
-- IMPORTANT: admin role must only be assigned by a trusted operator/server,
-- never by public signup or user-editable user_metadata.

create extension if not exists pgcrypto;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text not null default '',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.project_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null check (char_length(title) between 1 and 120),
  service text not null,
  details text not null check (char_length(details) between 1 and 5000),
  file_path text,
  status text not null default 'submitted'
    check (status in ('submitted','reviewing','quoted','approved','in_progress','revision_requested','completed','cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.account_deletion_requests (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  status text not null default 'pending' check (status in ('pending','reviewing','completed','rejected')),
  created_at timestamptz not null default now()
);

alter table public.profiles enable row level security;
alter table public.project_requests enable row level security;
alter table public.account_deletion_requests enable row level security;

-- Profiles: customers can see/update their own profile only.
create policy "read own profile" on public.profiles
  for select to authenticated using (auth.uid() = id);
create policy "insert own profile" on public.profiles
  for insert to authenticated with check (auth.uid() = id);
create policy "update own profile" on public.profiles
  for update to authenticated using (auth.uid() = id) with check (auth.uid() = id);

-- A trusted auth trigger creates profile rows; client can read/update only own row.
create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, full_name, phone)
  values (
    new.id,
    coalesce(new.raw_user_meta_data ->> 'full_name', ''),
    coalesce(new.raw_user_meta_data ->> 'phone', '')
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- Project requests: customer access is restricted to their own rows.
-- Admin operations should be performed by trusted server-side code with authorization.
create policy "read own project requests" on public.project_requests
  for select to authenticated using (auth.uid() = user_id);
create policy "create own project requests" on public.project_requests
  for insert to authenticated with check (auth.uid() = user_id);
-- Customers cannot directly change project status; no client update policy is granted.

create policy "create own deletion request" on public.account_deletion_requests
  for insert to authenticated with check (auth.uid() = user_id);
create policy "read own deletion requests" on public.account_deletion_requests
  for select to authenticated using (auth.uid() = user_id);

-- Private file storage:
-- Create a PRIVATE bucket named project-files in Storage UI (10MB max recommended).
-- Upload object paths must start with the authenticated user's UUID.
create policy "customer uploads own project files" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'project-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "customer reads own project files" on storage.objects
  for select to authenticated
  using (
    bucket_id = 'project-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
create policy "customer deletes own project files" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'project-files'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

-- Add separate, audited admin policies only when your chosen server-side admin
-- authorization mechanism is implemented and tested. Never rely on hidden UI alone.
