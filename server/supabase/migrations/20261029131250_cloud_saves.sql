-- Cloud save: one row per player, written only through push_save so the server
-- validates every save and owns last_seen_at (the client clock is never trusted
-- for offline rewards). Validation mirrors the client SaveCodec version 3 rules
-- and messages.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create table public.cloud_saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  save jsonb not null,
  save_version integer not null,
  last_seen_at timestamptz not null,
  updated_at timestamptz not null default now()
);

alter table public.cloud_saves enable row level security;

-- Players read only their own row; there is no direct write path.
revoke all on table public.cloud_saves from public, anon, authenticated;
grant select on table public.cloud_saves to authenticated;

create policy "players read their own save"
  on public.cloud_saves for select
  to authenticated
  using ((select auth.uid()) = user_id);


-- Raises 22023 naming the first invalid field, in the client's field order.
create function private.validate_save(save jsonb) returns void
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
  talent record;
  gold text;
begin
  if jsonb_typeof(save) is distinct from 'object' then
    raise exception 'save is not a JSON object' using errcode = '22023';
  end if;

  if not private.is_integer(save -> 'version') or (save ->> 'version')::numeric <> 3 then
    raise exception 'unsupported save version %', private.describe(save -> 'version') using errcode = '22023';
  end if;

  foreach field in array integer_fields loop
    minimum := case when field = 'stage' then 1 else 0 end;
    perform private.check_integer(field, save -> field, minimum);
  end loop;

  if jsonb_typeof(save -> 'talents') is distinct from 'object' then
    raise exception 'save field ''talents'' is not an object' using errcode = '22023';
  end if;
  for talent in select key, value from jsonb_each(save -> 'talents') loop
    perform private.check_integer('talents.' || talent.key, talent.value, 0);
  end loop;

  gold := case when jsonb_typeof(save -> 'gold') = 'string' then save ->> 'gold' end;
  if gold is null or gold !~ '^-?\d+(\.\d+)?(e-?\d+)?$' then
    raise exception 'save field ''gold'' is not a serialized number' using errcode = '22023';
  end if;
  if gold ~ '^-' and gold !~ '^-0+(\.0+)?(e-?\d+)?$' then
    raise exception 'save field ''gold'' must not be negative' using errcode = '22023';
  end if;
end;
$$;

-- JSON numbers count as integers only when they have no fractional part.
create function private.is_integer(value jsonb) returns boolean
language sql
immutable
set search_path = ''
as $$
  select coalesce(jsonb_typeof(value) = 'number' and (value #>> '{}')::numeric = trunc((value #>> '{}')::numeric), false);
$$;

create function private.describe(value jsonb) returns text
language sql
immutable
set search_path = ''
as $$
  select case
    when private.is_integer(value) then trunc((value #>> '{}')::numeric)::text
    else coalesce(value #>> '{}', 'null')
  end;
$$;

create function private.check_integer(field text, value jsonb, minimum integer) returns void
language plpgsql
immutable
set search_path = ''
as $$
begin
  if not private.is_integer(value) then
    raise exception 'save field ''%'' is missing or not an integer', field using errcode = '22023';
  end if;
  if (value #>> '{}')::numeric < minimum then
    raise exception 'save field ''%'' must be >= %, got %', field, minimum, private.describe(value)
      using errcode = '22023';
  end if;
end;
$$;


-- Stores the caller's save stamped with the server clock and returns that time.
create function public.push_save(save jsonb) returns jsonb
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

-- Returns the caller's save, when it was last pushed (server time) and the server time now.
create function public.pull_save() returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  player uuid := auth.uid();
  saved public.cloud_saves%rowtype;
begin
  if player is null then
    raise exception 'not signed in' using errcode = '28000';
  end if;
  select * into saved from public.cloud_saves where user_id = player;
  return jsonb_build_object(
    'save', saved.save,
    'last_seen_unix', floor(extract(epoch from saved.last_seen_at))::bigint,
    'server_now_unix', floor(extract(epoch from now()))::bigint
  );
end;
$$;

revoke all on function public.push_save(jsonb) from public, anon;
revoke all on function public.pull_save() from public, anon;
grant execute on function public.push_save(jsonb) to authenticated;
grant execute on function public.pull_save() to authenticated;
