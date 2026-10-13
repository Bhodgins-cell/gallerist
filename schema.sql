-- Run in Supabase SQL Editor. Every table is protected by owner-scoped RLS.
create extension if not exists pgcrypto;
create table if not exists public.artworks (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
 title text not null, medium text not null default '', dimensions text not null default '', year integer,
 price_cad numeric(12,2) check(price_cad is null or price_cad >= 0),
 status text not null default 'available' check(status in ('available','held','consigned','sold','archived')),
 image_path text, created_at timestamptz not null default now()
);
create table if not exists public.galleries (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
 name text not null, contact_email text, notes text, created_at timestamptz not null default now()
);
create table if not exists public.artwork_assignments (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
 artwork_id uuid not null references public.artworks(id) on delete cascade,
 gallery_id uuid not null references public.galleries(id) on delete cascade,
 stage text not null check(stage in ('initial','reserve','interested','consigned','released')),
 created_at timestamptz not null default now(), released_at timestamptz,
 check((stage='released' and released_at is not null) or (stage<>'released' and released_at is null))
);
-- The unique index enforces one active gallery assignment per artwork across concurrent requests.
create unique index if not exists one_active_gallery_per_artwork on public.artwork_assignments(artwork_id) where released_at is null;
create table if not exists public.approvals (
 id uuid primary key default gen_random_uuid(), owner_id uuid not null references auth.users(id) on delete cascade,
 action_type text not null, description text not null, payload jsonb not null default '{}'::jsonb,
 status text not null default 'pending' check(status in ('pending','approved','rejected','applied')),
 created_at timestamptz not null default now()
);
-- Prevent cross-owner foreign-key references even if a client knows an ID.
create or replace function public.check_assignment_owner() returns trigger language plpgsql set search_path=public as $$
begin
 if not exists(select 1 from public.artworks where id=new.artwork_id and owner_id=new.owner_id)
 or not exists(select 1 from public.galleries where id=new.gallery_id and owner_id=new.owner_id)
 then raise exception 'Artwork and gallery must belong to the same owner'; end if;
 if new.stage <> 'released' and exists(select 1 from public.artworks where id=new.artwork_id and status in ('sold','archived'))
 then raise exception 'Sold or archived artwork cannot be assigned'; end if;
 return new;
end $$;
drop trigger if exists assignment_owner_guard on public.artwork_assignments;
create trigger assignment_owner_guard before insert or update on public.artwork_assignments for each row execute function public.check_assignment_owner();
-- Client updates to assignment status are not allowed directly; server workflows should handle them in a later release.
alter table public.artworks enable row level security;
alter table public.galleries enable row level security;
alter table public.artwork_assignments enable row level security;
alter table public.approvals enable row level security;
create policy "own artworks" on public.artworks for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "own galleries" on public.galleries for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
create policy "read own assignments" on public.artwork_assignments for select to authenticated using(owner_id=auth.uid());
create policy "own approvals" on public.approvals for all to authenticated using(owner_id=auth.uid()) with check(owner_id=auth.uid());
