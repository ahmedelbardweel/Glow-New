begin;
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

-- مفاتيح Gemini و Eleven للأدمن. شغّل هذا الملف مرة واحدة من Supabase → SQL Editor.

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.users
    where id = auth.uid()
      and role = 'admin'
  );
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to authenticated;

create table if not exists public.admin_settings (
  id text primary key,
  gemini_key text not null default '',
  eleven_key text not null default '',
  gemini_model text not null default 'gemini-3.8-flash',
  groq_key text not null default '',
  montage_model text not null default 'groq:qwen/qwen3.8-27b',
  updated_at timestamptz not null default now()
);

alter table public.admin_settings add column if not exists groq_key text not null default '';
alter table public.admin_settings add column if not exists montage_model text not null default 'groq:qwen/qwen3.8-27b';

alter table public.admin_settings enable row level security;

drop policy if exists admin_settings_admin on public.admin_settings;
create policy admin_settings_admin
on public.admin_settings
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select, insert, update on public.admin_settings to authenticated;

-- Run AFTER content_packages.sql, in the Supabase SQL Editor.
-- Keeps existing data. Requires an existing public.users row with role=admin.
create or replace function public.content_is_admin()
returns boolean language sql stable security definer set search_path = public
as $$ select exists(select 1 from public.users where id = auth.uid() and lower(role) = 'admin') $$;
revoke all on function public.content_is_admin() from public;
grant execute on function public.content_is_admin() to anon, authenticated;

-- A published package must never expose draft_content through SELECT *.
drop policy if exists "Anyone reads published packages" on public.content_packages;
drop policy if exists content_draft_guard on public.content_packages;
create policy content_draft_guard on public.content_packages as restrictive
for all to anon, authenticated using (public.content_is_admin()) with check (public.content_is_admin());

create table if not exists public.content_publication_rows (
  package_id uuid not null references public.content_packages(id) on delete cascade,
  kind text not null check (kind in ('worlds','missions','stories','questions')),
  entity_id uuid not null,
  data jsonb not null,
  published_at timestamptz not null default now(),
  primary key (package_id,kind,entity_id)
);
create index if not exists content_publication_entity_idx on public.content_publication_rows(kind,entity_id,published_at desc);
alter table public.content_publication_rows enable row level security;
revoke all on public.content_publication_rows from anon, authenticated;

alter table public.worlds enable row level security;
drop policy if exists content_admin_access on public.worlds;
create policy content_admin_access on public.worlds for all to authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
drop policy if exists content_draft_guard on public.worlds;
create policy content_draft_guard on public.worlds as restrictive for all to anon, authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
grant select,insert,update,delete on public.worlds to authenticated;

create or replace function public.read_content_worlds()
returns setof public.worlds language plpgsql stable security definer set search_path = public
as $$ begin
  if public.content_is_admin() then
    return query select * from public.worlds;
  else
    return query select (jsonb_populate_record(null::public.worlds, latest.data)).*
      from (select distinct on (r.entity_id) r.data from public.content_publication_rows r
        join public.content_packages p on p.id=r.package_id
        where r.kind='worlds' and p.status='published'
        order by r.entity_id,r.published_at desc,r.package_id) latest;
  end if;
end $$;
revoke all on function public.read_content_worlds() from public;
grant execute on function public.read_content_worlds() to anon, authenticated;
create or replace view public.content_worlds as select * from public.read_content_worlds();
grant select on public.content_worlds to anon, authenticated;

alter table public.missions enable row level security;
drop policy if exists content_admin_access on public.missions;
create policy content_admin_access on public.missions for all to authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
drop policy if exists content_draft_guard on public.missions;
create policy content_draft_guard on public.missions as restrictive for all to anon, authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
grant select,insert,update,delete on public.missions to authenticated;

create or replace function public.read_content_missions()
returns setof public.missions language plpgsql stable security definer set search_path = public
as $$ begin
  if public.content_is_admin() then
    return query select * from public.missions;
  else
    return query select (jsonb_populate_record(null::public.missions, latest.data)).*
      from (select distinct on (r.entity_id) r.data from public.content_publication_rows r
        join public.content_packages p on p.id=r.package_id
        where r.kind='missions' and p.status='published'
        order by r.entity_id,r.published_at desc,r.package_id) latest;
  end if;
end $$;
revoke all on function public.read_content_missions() from public;
grant execute on function public.read_content_missions() to anon, authenticated;
create or replace view public.content_missions as select * from public.read_content_missions();
grant select on public.content_missions to anon, authenticated;

alter table public.stories enable row level security;
drop policy if exists content_admin_access on public.stories;
create policy content_admin_access on public.stories for all to authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
drop policy if exists content_draft_guard on public.stories;
create policy content_draft_guard on public.stories as restrictive for all to anon, authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
grant select,insert,update,delete on public.stories to authenticated;

create or replace function public.read_content_stories()
returns setof public.stories language plpgsql stable security definer set search_path = public
as $$ begin
  if public.content_is_admin() then
    return query select * from public.stories;
  else
    return query select (jsonb_populate_record(null::public.stories, latest.data)).*
      from (select distinct on (r.entity_id) r.data from public.content_publication_rows r
        join public.content_packages p on p.id=r.package_id
        where r.kind='stories' and p.status='published'
        order by r.entity_id,r.published_at desc,r.package_id) latest;
  end if;
end $$;
revoke all on function public.read_content_stories() from public;
grant execute on function public.read_content_stories() to anon, authenticated;
create or replace view public.content_stories as select * from public.read_content_stories();
grant select on public.content_stories to anon, authenticated;

alter table public.questions enable row level security;
drop policy if exists content_admin_access on public.questions;
create policy content_admin_access on public.questions for all to authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
drop policy if exists content_draft_guard on public.questions;
create policy content_draft_guard on public.questions as restrictive for all to anon, authenticated
using (public.content_is_admin()) with check (public.content_is_admin());
grant select,insert,update,delete on public.questions to authenticated;

create or replace function public.read_content_questions()
returns setof public.questions language plpgsql stable security definer set search_path = public
as $$ begin
  if public.content_is_admin() then
    return query select * from public.questions;
  else
    return query select (jsonb_populate_record(null::public.questions, latest.data)).*
      from (select distinct on (r.entity_id) r.data from public.content_publication_rows r
        join public.content_packages p on p.id=r.package_id
        where r.kind='questions' and p.status='published'
        order by r.entity_id,r.published_at desc,r.package_id) latest;
  end if;
end $$;
revoke all on function public.read_content_questions() from public;
grant execute on function public.read_content_questions() to anon, authenticated;
create or replace view public.content_questions as select * from public.read_content_questions();
grant select on public.content_questions to anon, authenticated;

create index if not exists content_missions_world_idx on public.missions(world_id);
create index if not exists content_stories_mission_idx on public.stories(mission_id);
create index if not exists content_questions_mission_idx on public.questions(mission_id);

create or replace function public.publish_content_package(package_id uuid)
returns public.content_packages language plpgsql security definer set search_path = public
as $$
declare
  result public.content_packages;
  world_ids uuid[];
  snapshot jsonb;
begin
  if not public.content_is_admin() then
    raise exception 'admin role required' using errcode='42501';
  end if;
  select * into result from public.content_packages p where p.id=package_id for update;
  if not found then raise exception 'package not found'; end if;
  select array_agg(distinct (x->>'id')::uuid) into world_ids
    from jsonb_array_elements(result.draft_content->'worlds') x;
  if coalesce(cardinality(world_ids),0)=0 then raise exception 'Add at least one world before publishing'; end if;
  if (select count(*) from public.worlds where id=any(world_ids)) <> cardinality(world_ids) then
    raise exception 'A package world was deleted; remove it from the package before publishing';
  end if;
  -- One statement captures the entire hierarchy at the same database snapshot.
  select jsonb_build_object(
    'worlds', coalesce((select jsonb_agg(to_jsonb(w)) from public.worlds w where w.id=any(world_ids)),'[]'::jsonb),
    'missions', coalesce((select jsonb_agg(to_jsonb(m)) from public.missions m where m.world_id=any(world_ids)),'[]'::jsonb),
    'stories', coalesce((select jsonb_agg(to_jsonb(s)) from public.stories s join public.missions m on m.id=s.mission_id where m.world_id=any(world_ids)),'[]'::jsonb),
    'questions', coalesce((select jsonb_agg(to_jsonb(q)) from public.questions q join public.missions m on m.id=q.mission_id where m.world_id=any(world_ids)),'[]'::jsonb)
  ) into snapshot;
  delete from public.content_publication_rows r where r.package_id=publish_content_package.package_id;
  insert into public.content_publication_rows(package_id,kind,entity_id,data)
    select publish_content_package.package_id, entries.key,(item->>'id')::uuid,item
    from jsonb_each(snapshot) entries cross join lateral jsonb_array_elements(entries.value) item;
  update public.content_packages p set published_content=snapshot,
    version=p.version+1,status='published',published_at=now(),updated_at=now()
    where p.id=publish_content_package.package_id returning p.* into result;
  return result;
end $$;
revoke all on function public.publish_content_package(uuid) from public;
grant execute on function public.publish_content_package(uuid) to authenticated;

-- Media used by world images, story recordings, and character files.
insert into storage.buckets(id,name,public) values
('story_audio','story_audio',true),('story_characters','story_characters',true)
on conflict(id) do nothing;
drop policy if exists content_admin_media_insert on storage.objects;
create policy content_admin_media_insert on storage.objects for insert to authenticated
with check (bucket_id in ('story_audio','story_characters') and public.content_is_admin());
drop policy if exists content_admin_media_select on storage.objects;
create policy content_admin_media_select on storage.objects for select to authenticated
using (bucket_id in ('story_audio','story_characters') and public.content_is_admin());
drop policy if exists content_admin_media_update on storage.objects;
create policy content_admin_media_update on storage.objects for update to authenticated
using (bucket_id in ('story_audio','story_characters') and public.content_is_admin())
with check (bucket_id in ('story_audio','story_characters') and public.content_is_admin());

notify pgrst, 'reload schema';
-- Run after admin_upgrade.sql. Existing edits and published packages are preserved.

create or replace function public.ensure_launch_admin_package(content jsonb)
returns uuid language plpgsql security invoker set search_path = public
as $$
declare
  starter_id constant uuid := 'a1000000-0000-4000-8000-000000000100';
begin
  if not public.content_is_admin() then
    raise exception 'admin role required' using errcode='42501';
  end if;
  -- Two admin devices opening simultaneously must create only one package.
  perform pg_advisory_xact_lock(1000000100);
  if exists(select 1 from public.content_packages where id=starter_id) then
    return starter_id;
  end if;
  if jsonb_typeof(content->'worlds') is distinct from 'array'
     or jsonb_array_length(content->'worlds') = 0
     or jsonb_typeof(content->'missions') is distinct from 'array'
     or jsonb_typeof(content->'stories') is distinct from 'array'
     or jsonb_typeof(content->'questions') is distinct from 'array' then
    raise exception 'Invalid launch content';
  end if;
  insert into public.worlds(id,title,description,image_url)
    select id,title,description,image_url from jsonb_populate_recordset(null::public.worlds,content->'worlds')
    on conflict(id) do nothing;
  insert into public.missions(id,world_id,title,badge_name,stars_reward,order_index)
    select id,world_id,title,badge_name,stars_reward,order_index
    from jsonb_populate_recordset(null::public.missions,content->'missions') on conflict(id) do nothing;
  insert into public.stories(id,mission_id,title,character_name,content,image_url,order_index,audio_url,timeline_data)
    select s.id,s.mission_id,s.title,s.character_name,s.content,s.image_url,s.order_index,s.audio_url,s.timeline_data
    from jsonb_populate_recordset(null::public.stories,ensure_launch_admin_package.content->'stories') s
    on conflict(id) do nothing;
  insert into public.questions(id,mission_id,question_text,options,correct_answer_index)
    select id,mission_id,question_text,options,correct_answer_index
    from jsonb_populate_recordset(null::public.questions,content->'questions') on conflict(id) do nothing;
  insert into public.content_packages(id,title,description,status,created_by,draft_content)
    values(starter_id,'بكج البداية — العادات الخمس',
      'العالم والعادات والقصص والأسئلة المرفقة بالتطبيق، جاهزة للمراجعة والتعديل.',
      'draft',auth.uid(),jsonb_build_object('worlds',(
        select jsonb_agg(to_jsonb(w) order by w.id) from public.worlds w
        where w.id in (select (item->>'id')::uuid from jsonb_array_elements(content->'worlds') item)
      )));
  return starter_id;
end $$;
revoke all on function public.ensure_launch_admin_package(jsonb) from public;
grant execute on function public.ensure_launch_admin_package(jsonb) to authenticated;
notify pgrst, 'reload schema';
commit;
