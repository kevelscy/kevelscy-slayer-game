-- Save version 4: skill levels are validated and the pushed version is recorded,
-- while version 3 saves keep syncing. Run with `supabase test db` from server/.
begin;
select plan(9);

insert into auth.users (id, aud, role, is_anonymous)
values ('33333333-3333-3333-3333-333333333333', 'authenticated', 'authenticated', true);

select set_config('role', 'authenticated', true),
       set_config('request.jwt.claims', json_build_object('sub', '33333333-3333-3333-3333-333333333333', 'role', 'authenticated')::text, true);

create function pg_temp.v4_save() returns jsonb language sql as $$
  select jsonb_build_object(
    'version', 4, 'stage', 23, 'gold', '1.5e12',
    'attack_level', 30, 'health_level', 25,
    'crit_chance_level', 4, 'crit_damage_level', 3, 'attack_speed_level', 5,
    'ascension_shards', 6, 'ascension_count', 1,
    'talents', jsonb_build_object('might', 2),
    'skills', jsonb_build_object('thunder', 4, 'meteor', 0),
    'last_seen_unix', 9999999999
  );
$$;

select lives_ok($$ select public.push_save(pg_temp.v4_save()) $$, 'a version 4 save is accepted');
select is((select save_version from public.cloud_saves), 4, 'the pushed version is recorded');
select is(
  public.pull_save() -> 'save' -> 'skills',
  '{"thunder": 4, "meteor": 0}'::jsonb,
  'skill levels round-trip'
);

select lives_ok(
  $$ select public.push_save((pg_temp.v4_save() - 'skills') || '{"version": 3}') $$,
  'a version 3 save without skills still syncs'
);
select is((select save_version from public.cloud_saves), 3, 'the version 3 push is recorded as 3');

select throws_ok(
  $$ select public.push_save(pg_temp.v4_save() - 'skills') $$,
  '22023', 'save field ''skills'' is not an object', 'version 4 requires skills'
);
select throws_ok(
  $$ select public.push_save(pg_temp.v4_save() || '{"skills": [1]}') $$,
  '22023', 'save field ''skills'' is not an object', 'skills must be an object'
);
select throws_ok(
  $$ select public.push_save(pg_temp.v4_save() || '{"skills": {"thunder": -1}}') $$,
  '22023', 'save field ''skills.thunder'' must be >= 0, got -1', 'skill levels are not negative'
);
select throws_ok(
  $$ select public.push_save(pg_temp.v4_save() || '{"version": 5}') $$,
  '22023', 'unsupported save version 5', 'version 5 is not accepted yet'
);

select * from finish();
rollback;
