-- Run after admin_upgrade.sql. Existing edits and published packages are preserved.
begin;
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
