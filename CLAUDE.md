# Project practices — FitMoveLab

These are standing rules for this project. Follow them automatically on every
task; don't wait to be reminded.

## 1. Credentials never live in the codebase

- All secrets (Gemini API key, Mongo URI, Supabase JWT secret / service role
  key, Strava client secret, Flask secret key, etc.) live only in
  `backend/.env`, which is gitignored. `backend/.env.example` is the checked-in
  template — keep it in sync whenever a new env var is introduced, but only
  with placeholder values.
- The Flutter app never embeds secrets. It only takes public/non-secret values
  (Supabase URL, Supabase anon/publishable key, API base URL) via
  `--dart-define-from-file=env.json` (see `mobile/core/config/env.dart` and
  `mobile/env.example.json`). `env.json` itself is gitignored.
- Anything that must stay server-side (Gemini calls, Mongo access, Strava
  token exchange, Supabase service-role actions) is proxied through the Flask
  backend — the mobile app talks to the backend, never directly to a
  third-party API that requires a secret key.
- Before any commit/push/deploy, check that no new file introduces a literal
  credential, and that any new secret is added to `.env.example` as a
  placeholder, not a real value. The root `.gitignore` and `backend/.gitignore`
  are the safety net — don't rely on memory alone.

## 2. Call out breaking impact before building a new feature

When a new requirement comes in, before writing any code:

- Check whether it conflicts with, breaks, or requires reworking an existing
  feature, data model, API contract, route, or architectural decision already
  in place (e.g. the 3-role model, the central UUID-keyed
  `user_interactions` log, existing Mongo schemas, existing endpoints the
  Flutter app depends on).
- If it does, stop and explain the conflict and the risk to the user
  *before* starting the build — don't silently work around it or build first
  and mention it after. Lay out what would break and the options for handling
  it, and wait for a decision unless the fix is small and unambiguous.
- If it doesn't conflict with anything, proceed normally — this isn't a
  license to over-ask, only to flag genuine breaking impact.
