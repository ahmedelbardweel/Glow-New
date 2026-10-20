-- جدول الشخصيات المصنوعة بواسطة الآدمن. شغّل هذا الملف من Supabase → SQL Editor.

create table if not exists public.custom_characters (
  id text primary key,
  name text not null,
  body_color text not null,
  belly_color text not null,
  has_hat boolean not null default false,
  hat_color text not null default '#68cf98ff',
  has_glasses boolean not null default false,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.custom_characters enable row level security;

-- السماح لجميع المستخدمين بالقراءة (لعرض الشخصيات في القصص)
drop policy if exists "custom_characters_read" on public.custom_characters;
create policy "custom_characters_read"
on public.custom_characters
for select
to authenticated, anon
using (true);

-- السماح للآدمن بالإضافة والتعديل والحذف
drop policy if exists "custom_characters_admin_write" on public.custom_characters;
create policy "custom_characters_admin_write"
on public.custom_characters
for all
to authenticated
using (public.is_admin())
with check (public.is_admin());

grant select, insert, update, delete on public.custom_characters to authenticated, anon;
