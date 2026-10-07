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
