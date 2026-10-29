-- Cloud save access rules, server-side validation and the server-owned clock.
-- Run with `supabase test db` from server/. Each run is one rolled-back
-- transaction, so now() is constant and the stored timestamps compare exactly.
begin;
select plan(33);

-- Two players and helpers to act as each of them through PostgREST roles.
insert into auth.users (id, aud, role, is_anonymous)
values
  ('11111111-1111-1111-1111-111111111111', 'authenticated', 'authenticated', true),
  ('22222222-2222-2222-2222-222222222222', 'authenticated', 'authenticated', true);

create function pg_temp.act_as(player uuid) returns void language sql as $$
  select set_config('role', 'authenticated', true),
         set_config('request.jwt.claims', json_build_object('sub', player, 'role', 'authenticated')::text, true);
$$;

create function pg_temp.act_as_anon() returns void language sql as $$
  select set_config('role', 'anon', true),
         set_config('request.jwt.claims', json_build_object('role', 'anon')::text, true);
$$;

create function pg_temp.valid_save() returns jsonb language sql as $$
  select jsonb_build_object(
    'version', 3, 'stage', 23, 'gold', '1.5e12',
    'attack_level', 30, 'health_level', 25,
    'crit_chance_level', 4, 'crit_damage_level', 3, 'attack_speed_level', 5,
    'ascension_shards', 6, 'ascension_count', 1,
    'talents', jsonb_build_object('might', 2, 'greed', 1),
    'last_seen_unix', 9999999999
  );
$$;

-- S2: table shape and row level security.
select has_table('public', 'cloud_saves', 'cloud_saves exists');
select col_is_pk('public', 'cloud_saves', 'user_id', 'one row per player');
select ok(
  (select relrowsecurity from pg_class where oid = 'public.cloud_saves'::regclass),
  'row level security is enabled'
);

-- S2: calls without a signed-in user fail.
select pg_temp.act_as_anon();
select throws_ok($$ select public.push_save(pg_temp.valid_save()) $$, '42501', null, 'anon cannot push');
select throws_ok($$ select public.pull_save() $$, '42501', null, 'anon cannot pull');
select throws_ok($$ select * from public.cloud_saves $$, '42501', null, 'anon cannot read the table');
reset role;
select set_config('role', 'authenticated', true), set_config('request.jwt.claims', '{"role":"authenticated"}', true);
select throws_ok($$ select public.push_save(pg_temp.valid_save()) $$, '28000', 'not signed in', 'a token without a user cannot push');
select throws_ok($$ select public.pull_save() $$, '28000', 'not signed in', 'a token without a user cannot pull');
reset role;

-- S4: pulling before any push returns no save, but the server time.
select pg_temp.act_as('11111111-1111-1111-1111-111111111111');
select is(
  public.pull_save(),
  jsonb_build_object('save', null, 'last_seen_unix', null, 'server_now_unix', floor(extract(epoch from now()))::bigint),
  'pull without a save returns nulls and the server time'
);

-- S4: push stores the save stamped with the server clock, not the client's.
select is(
  public.push_save(pg_temp.valid_save()),
  jsonb_build_object('server_now_unix', floor(extract(epoch from now()))::bigint),
  'push returns the server time'
);
select is(
  (public.pull_save() -> 'save' ->> 'last_seen_unix')::bigint,
  floor(extract(epoch from now()))::bigint,
  'the stored save carries the server time, not the client last_seen_unix'
);
select is(
  public.pull_save() -> 'save',
  pg_temp.valid_save() || jsonb_build_object('last_seen_unix', floor(extract(epoch from now()))::bigint),
  'every other field is stored as sent'
);
select is(
  (public.pull_save() ->> 'last_seen_unix')::bigint,
  floor(extract(epoch from now()))::bigint,
  'pull reports the server-owned last_seen'
);
select is(
  (select save_version from public.cloud_saves),
  3,
  'save_version is recorded'
);

-- S4: a second push replaces the row instead of adding one.
do $$ begin perform public.push_save(pg_temp.valid_save() || '{"stage": 24}'); end $$;
select is((select count(*)::int from public.cloud_saves), 1, 'one row per player after two pushes');
select is((public.pull_save() -> 'save' ->> 'stage')::int, 24, 'the latest push wins');

-- S2: clients cannot write the table directly.
select throws_ok(
  $$ insert into public.cloud_saves (user_id, save, save_version, last_seen_at)
     values ('11111111-1111-1111-1111-111111111111', '{}', 3, now()) $$,
  '42501', null, 'direct insert is denied'
);
select throws_ok($$ update public.cloud_saves set save_version = 9 $$, '42501', null, 'direct update is denied');
select throws_ok($$ delete from public.cloud_saves $$, '42501', null, 'direct delete is denied');
reset role;

-- S2: another player sees nothing of the first player's save.
select pg_temp.act_as('22222222-2222-2222-2222-222222222222');
select is((select count(*)::int from public.cloud_saves), 0, 'a player cannot read another player''s row');
select is(public.pull_save() -> 'save', 'null'::jsonb, 'pull only returns the caller''s own save');
reset role;

-- S3: invalid saves are rejected with the client's messages and change nothing.
select pg_temp.act_as('11111111-1111-1111-1111-111111111111');
select throws_ok($$ select public.push_save('[1, 2]') $$, '22023', 'save is not a JSON object', 'non-object save');
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"version": 2}') $$,
  '22023', 'unsupported save version 2', 'only version 3 is accepted'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"stage": 0}') $$,
  '22023', 'save field ''stage'' must be >= 1, got 0', 'stage below 1'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"attack_level": 1.5}') $$,
  '22023', 'save field ''attack_level'' is missing or not an integer', 'fractional level'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() - 'ascension_count') $$,
  '22023', 'save field ''ascension_count'' is missing or not an integer', 'missing field'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"crit_chance_level": -1}') $$,
  '22023', 'save field ''crit_chance_level'' must be >= 0, got -1', 'negative level'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"gold": 100}') $$,
  '22023', 'save field ''gold'' is not a serialized number', 'gold as a JSON number'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"gold": "-5"}') $$,
  '22023', 'save field ''gold'' must not be negative', 'negative gold'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"talents": [1]}') $$,
  '22023', 'save field ''talents'' is not an object', 'talents not an object'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"talents": {"might": -1}}') $$,
  '22023', 'save field ''talents.might'' must be >= 0, got -1', 'negative talent level'
);
select throws_ok(
  $$ select public.push_save(pg_temp.valid_save() || '{"talents": {"might": "2"}}') $$,
  '22023', 'save field ''talents.might'' is missing or not an integer', 'talent level as a string'
);
select is((public.pull_save() -> 'save' ->> 'stage')::int, 24, 'rejected pushes left the stored save unchanged');
reset role;

select * from finish();
rollback;
