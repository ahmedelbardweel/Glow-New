-- Draft and publish workflow for admin-managed content packages.
-- Apply from Supabase SQL Editor. Draft JSON is private to authenticated
-- admins; published snapshots are readable by all app users.

create table if not exists public.content_packages (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  description text not null default '',
  cover_url text not null default '',
  status text not null default 'draft' check (status in ('draft', 'published')),
  draft_content jsonb not null default '{"worlds":[]}'::jsonb,
  published_content jsonb,
  version integer not null default 0 check (version >= 0),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  published_at timestamptz,
  constraint content_packages_content_shape check (
    jsonb_typeof(draft_content) = 'object'
    and jsonb_typeof(draft_content->'worlds') = 'array'
  )
);

create index if not exists content_packages_status_updated_idx
  on public.content_packages(status, updated_at desc);

alter table public.content_packages enable row level security;

drop policy if exists "Admins manage package drafts" on public.content_packages;
create policy "Admins manage package drafts"
  on public.content_packages for all to authenticated
  using (exists (
    select 1 from public.users u
    where u.id = auth.uid() and lower(u.role) = 'admin'
  ))
  with check (exists (
    select 1 from public.users u
    where u.id = auth.uid() and lower(u.role) = 'admin'
  ));

drop policy if exists "Anyone reads published packages" on public.content_packages;
create policy "Anyone reads published packages"
  on public.content_packages for select to anon, authenticated
  using (status = 'published');

create or replace function public.publish_content_package(package_id uuid)
returns public.content_packages
language plpgsql
security invoker
set search_path = public
as $$
declare
  result public.content_packages;
begin
  if not exists (
    select 1 from public.users u
    where u.id = auth.uid() and lower(u.role) = 'admin'
  ) then
    raise exception 'admin role required' using errcode = '42501';
  end if;

  update public.content_packages
  set status = 'published',
      published_content = draft_content,
      version = version + 1,
      published_at = now(),
      updated_at = now()
  where id = package_id
  returning * into result;

  if result.id is null then
    raise exception 'package not found' using errcode = 'P0002';
  end if;
  return result;
end;
$$;

revoke all on function public.publish_content_package(uuid) from public;
grant execute on function public.publish_content_package(uuid) to authenticated;

grant select on public.content_packages to anon, authenticated;
grant insert, update, delete on public.content_packages to authenticated;
