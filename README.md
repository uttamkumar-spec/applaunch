# FitMoveLab

A fitness app for people who've never really known where to start. Built as
a **Flutter app** (Android, iOS, and Web from one codebase) backed by a
**Flask + MongoDB** API, **Supabase** for authentication, **Gemini 2.5
Flash** for the AI coach, and **Strava** for activity sync.

## Who it's for

Three roles, one app:

- **Athlete** — takes a short onboarding quiz, gets a beginner-friendly
  workout plan, chats with an AI coach (including photo/video form checks),
  tracks nutrition/habits and progress, and can find and request a human
  coach (with an AI recommendation to help pick one).
- **Coach** — basic dashboard: accept/decline athlete requests, see
  assigned athletes, generate a workout plan with AI and push it to an
  athlete (it shows up as their plan on the Athlete side).
- **Admin** — basic console: create users of any role (Supabase-backed),
  and set platform-wide limits (max athletes per coach, daily AI messages
  per athlete).

Every athlete's onboarding answers, goals, workout plans, execution
summaries, chat turns (with the raw Gemini response), form-check results,
nutrition/habit logs, and Strava syncs are written to a central, UUID-keyed
interaction log — see
[`backend/app/services/interaction_logger.py`](backend/app/services/interaction_logger.py)
— intended as the raw dataset for training an in-house SLM later. Export it
with `backend/scripts/export_training_data.py`.

## Structure

```
mobile/    Flutter app (Android / iOS / Web)
backend/   Flask API (MongoDB, Supabase auth, Gemini, Strava)
```

## Quick start

### 1. Backend

```bash
cd backend
python3 -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env   # fill in Supabase / Mongo / Gemini / Strava values
python run.py           # http://localhost:5000
```

You need:
- A **MongoDB** instance (Atlas free tier or local `mongod`) → `MONGODB_URI`
- A **Supabase** project → `SUPABASE_URL`, `SUPABASE_JWT_SECRET` (Project
  Settings → API → JWT Settings), and `SUPABASE_SERVICE_ROLE_KEY` (only
  needed for the admin "create user" flow)
- A **Gemini API key** (Google AI Studio) → `GEMINI_API_KEY`
- A **Strava API application** (optional, for progress sync) →
  `STRAVA_CLIENT_ID` / `STRAVA_CLIENT_SECRET` / `STRAVA_REDIRECT_URI`

The app works without any of these being real — every route degrades
gracefully (empty lists, friendly errors) so you can run the UI standalone.

### 2. Flutter app

```bash
cd mobile
cp env.example.json env.json   # fill in SUPABASE_URL / SUPABASE_ANON_KEY / API_BASE_URL
flutter pub get
flutter run --dart-define-from-file=env.json                 # phone/emulator
flutter run -d chrome --dart-define-from-file=env.json       # web
```

Notes:
- On the **Android emulator**, `10.0.2.2` (the default `API_BASE_URL` in
  `env.example.json`) reaches your machine's `localhost:5000`. On a
  physical device or iOS simulator, use your machine's LAN IP instead.
- Without Supabase configured, the welcome/onboarding screens still work;
  sign-up/login will show a friendly error until real credentials are set.

### 3. Roles

Public sign-up always creates an **athlete**. Coach and Admin accounts are
then created by an Admin via the in-app "New user" flow (Admin → users),
which uses the Supabase service role key server-side.

To bootstrap your very first Admin: sign up normally in the app (creating
an athlete account), then run:

```bash
cd backend && source .venv/bin/activate
python scripts/promote_user.py --email you@example.com --role admin
```

Log out and back in — you'll land on the Admin dashboard, and can create
Coach/Admin accounts from there for everyone else.

## Tech stack

| Layer     | Choice                                   |
|-----------|-------------------------------------------|
| Mobile/Web app | Flutter (Riverpod, go_router)        |
| Backend API    | Flask (Python)                       |
| Database       | MongoDB                              |
| Auth           | Supabase                             |
| AI             | Gemini 2.5 Flash                     |
| Activity sync  | Strava OAuth                         |
