-- Caps a pushed save at 16384 bytes of JSON text (a real save is about 400), so
-- a player cannot store an arbitrarily large row. Checked before any field.

create function private.check_save_size(save jsonb) returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if octet_length(save::text) > 16384 then
    raise exception 'save is larger than 16384 bytes' using errcode = '22023';
  end if;
end;
$$;

create or replace function public.push_save(save jsonb) returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  player uuid := auth.uid();
  server_now bigint := floor(extract(epoch from now()))::bigint;
begin
  if player is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  perform private.check_save_size(save);
  perform private.validate_save(save);

  insert into public.cloud_saves (user_id, save, save_version, last_seen_at, updated_at)
  values (player, save || jsonb_build_object('last_seen_unix', server_now), 3, now(), now())
  on conflict (user_id) do update
    set save = excluded.save,
        save_version = excluded.save_version,
        last_seen_at = excluded.last_seen_at,
        updated_at = excluded.updated_at;

  return jsonb_build_object('server_now_unix', server_now);
end;
$$;
