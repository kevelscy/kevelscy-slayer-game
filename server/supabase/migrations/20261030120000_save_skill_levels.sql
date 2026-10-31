-- Save version 4 adds `skills`, an object of skill id to bought level (>= 0),
-- next to `talents`. Version 3 saves stay valid so an older client keeps
-- syncing. push_save records the pushed version instead of a fixed 3.

create or replace function private.validate_save(save jsonb) returns void
language plpgsql
immutable
set search_path = ''
as $$
declare
  integer_fields constant text[] := array[
    'stage', 'attack_level', 'health_level', 'last_seen_unix',
    'crit_chance_level', 'crit_damage_level', 'attack_speed_level',
    'ascension_shards', 'ascension_count'
  ];
  field text;
  minimum integer;
  entry record;
  gold text;
begin
  if jsonb_typeof(save) is distinct from 'object' then
    raise exception 'save is not a JSON object' using errcode = '22023';
  end if;

  if not private.is_integer(save -> 'version') or (save ->> 'version')::numeric not in (3, 4) then
    raise exception 'unsupported save version %', private.describe(save -> 'version') using errcode = '22023';
  end if;

  foreach field in array integer_fields loop
    minimum := case when field = 'stage' then 1 else 0 end;
    perform private.check_integer(field, save -> field, minimum);
  end loop;

  if jsonb_typeof(save -> 'talents') is distinct from 'object' then
    raise exception 'save field ''talents'' is not an object' using errcode = '22023';
  end if;
  for entry in select key, value from jsonb_each(save -> 'talents') loop
    perform private.check_integer('talents.' || entry.key, entry.value, 0);
  end loop;

  if (save ->> 'version')::numeric >= 4 then
    if jsonb_typeof(save -> 'skills') is distinct from 'object' then
      raise exception 'save field ''skills'' is not an object' using errcode = '22023';
    end if;
    for entry in select key, value from jsonb_each(save -> 'skills') loop
      perform private.check_integer('skills.' || entry.key, entry.value, 0);
    end loop;
  end if;

  gold := case when jsonb_typeof(save -> 'gold') = 'string' then save ->> 'gold' end;
  if gold is null or gold !~ '^-?\d+(\.\d+)?(e-?\d+)?$' then
    raise exception 'save field ''gold'' is not a serialized number' using errcode = '22023';
  end if;
  if gold ~ '^-' and gold !~ '^-0+(\.0+)?(e-?\d+)?$' then
    raise exception 'save field ''gold'' must not be negative' using errcode = '22023';
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
  values (
    player, save || jsonb_build_object('last_seen_unix', server_now),
    (save ->> 'version')::integer, now(), now()
  )
  on conflict (user_id) do update
    set save = excluded.save,
        save_version = excluded.save_version,
        last_seen_at = excluded.last_seen_at,
        updated_at = excluded.updated_at;

  return jsonb_build_object('server_now_unix', server_now);
end;
$$;
