# server

Supabase backend: anonymous auth, cloud save, and server-side validation of offline timestamps
(the server owns `last_seen_at`; the client clock is never trusted for offline rewards).

## Local stack

Requires the Supabase CLI (`brew install supabase/tap/supabase`) and a running Docker
(OrbStack or Docker Desktop).

```bash
cd server
supabase start      # API on http://127.0.0.1:54321, Studio on http://127.0.0.1:54323
supabase test db    # pgTAP: access rules, validation and the server clock
supabase db reset   # re-apply migrations from scratch
supabase stop
```

`supabase/config.toml` enables anonymous sign-ins and turns off the services the game does
not use (storage, realtime, analytics, edge runtime, local SMTP). The client defaults to the
local stack and its public publishable key.

## API

| RPC | Who | Returns |
|---|---|---|
| `push_save(save jsonb)` | signed-in player | `{server_now_unix}` |
| `pull_save()` | signed-in player | `{save, last_seen_unix, server_now_unix}` (`save` and `last_seen_unix` null before the first push) |

- `public.cloud_saves` holds one row per player. Row level security lets a player read only their
  own row; there is no direct insert, update or delete, so every write goes through `push_save`.
- `push_save` accepts only a version 3 save that passes the client codec's rules and rejects
  anything else with SQLSTATE `22023` and the codec's message (for example
  `save field 'stage' must be >= 1, got 0`), leaving the stored save unchanged. A save larger than
  16384 bytes of JSON text is rejected the same way (`save is larger than 16384 bytes`); a real
  save is about 400 bytes.
- `push_save` replaces the save's `last_seen_unix` with the server time, so offline time is always
  `server now - server last_seen`.
- Anonymous callers (no player) get `42501`; a token without a player gets `28000 not signed in`.
