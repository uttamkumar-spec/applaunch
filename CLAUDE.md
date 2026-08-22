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

## 2. Call out breaking impact, technical debt, and bloat before building

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
- Separately from breaking things outright, also flag it up front if the
  requested approach would introduce technical debt or codebase bloat —
  e.g. a parallel/duplicate way of doing something already handled
  elsewhere, a one-off pattern that diverges from the existing architecture,
  a shortcut that will need revisiting soon, or a dependency/abstraction
  that's heavier than the feature needs. Say so and propose the leaner
  alternative before building, rather than building the heavier version and
  refactoring later. The goal is to keep future refactor need and codebase
  weight low, not to accumulate "fix it later" debt.
- If it doesn't conflict with anything and doesn't add debt/bloat, proceed
  normally — this isn't a license to over-ask, only to flag genuine risk.

## 3. Confirm the design before building it — don't assume

For anything with real product/UX shape — a new screen, a form and the
fields it collects, a flow's steps and ordering, tone/copy, what a feature
actually asks the user or shows them — do not silently decide the details
and build them. This is broader than rule #2 (breaking-impact only applies
to existing features); this applies even to brand-new, non-conflicting work.

- Before writing the screen/flow, lay out the proposed content in the chat
  (fields, steps, options, copy — whatever is user-facing and judgment-based)
  and get explicit confirmation, or ask targeted clarifying questions when
  the requirement is ambiguous.
- "Full clarity" means the field/step-level shape is confirmed, not just the
  high-level feature name. E.g. "build the onboarding quiz" is not enough
  clarity on its own — what it asks, in what order, and why, needs to be
  agreed first.
- Purely mechanical/internal implementation choices (variable names, file
  structure, which widget to use for a given confirmed field) don't need
  sign-off — this rule is about user-facing product decisions, not code
  style.
- If something already built this way turns out wrong, don't just patch it
  quietly either — surface what was assumed and confirm the correction
  before rebuilding.
