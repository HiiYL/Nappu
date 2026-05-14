# Nappu 🐑

A gamified sleep-habit companion app for teens. Track sleep, complete nightly tasks, earn tokens, customise a virtual pet, and lock distracting apps during bedtime.

Built with **Flutter** + **Supabase** + **Android native services**.

## Overview

Nappu helps teens build better sleep habits through positive reinforcement. Users log their sleep, complete bedtime tasks, and earn tokens they can spend customising their virtual sheep companion. An optional app-lock feature blocks distracting apps during scheduled sleep hours.

### Key Features

- **Sleep Logging** — Record bedtime/wakeup times, track quality, view weekly charts and biweekly AI-generated insights
- **Nightly Tasks** — Checklist (no screens, dim lights, breathing exercises, etc.) that awards tokens on completion
- **Token Economy** — Earn tokens from tasks and sleep logs; spend them in the shop
- **Nappu's Room** — Customise your sheep with hats, outfits, accessories, and room themes
- **App Lock** — Schedule-based Android app blocking with overlay; emergency override costs tokens
- **Streaks & Levels** — Consecutive-day streaks and XP-based levelling system
- **Guest Mode** — Use the app without an account; upgrade to email/password anytime

## Architecture

```
Flutter (Dart)  ──▶  Supabase (Postgres + Auth + RLS)
     │                  ├─ 8 tables with row-level security
     │                  └─ 6 RPC functions (security definer)
     └──▶  Android Native (Kotlin)
              └─ AppLockService (foreground service + overlay)
```

- **Direct reads** for all data; **server-side RPCs** for sensitive writes (tokens, streaks, purchases, sleep logs)
- **Row-level security** restricts client to safe fields only — tokens, XP, and streaks can only be modified through RPCs
- **Optimistic UI** with automatic rollback on server failure
- **Platform channel** bridges Flutter ↔ Android for the native app-lock service

## Repository Structure

```
nappu/
├── README.md                          ← you are here
├── Medi-Innovate Challenge 2026.pdf   # Competition submission document
│
└── nappu_app/                         # Flutter application
    ├── lib/
    │   ├── config/supabase_config.dart    # Supabase URL + anon key (env-overridable)
    │   ├── theme/app_theme.dart           # Dark theme + colour palette
    │   ├── models/app_state.dart          # ChangeNotifier — all app state + business logic
    │   ├── services/
    │   │   ├── supabase_service.dart      # Supabase client calls (auth, profile, RPCs)
    │   │   └── app_lock_native.dart       # Platform channel wrapper for Android
    │   └── screens/
    │       ├── auth_screen.dart            # Sign-up / sign-in / guest mode
    │       ├── home_screen.dart            # Dashboard, stats, tasks, guest upgrade banner
    │       ├── sleep_log_screen.dart       # Log sleep + weekly chart + biweekly insights
    │       ├── app_lock_screen.dart        # Lock schedule + locked app management
    │       ├── nappu_screen.dart           # Pet room + shop (items & themes)
    │       └── token_history_screen.dart   # Transaction log
    │
    ├── android/.../
    │   ├── MainActivity.kt                # Platform channel handler
    │   └── AppLockService.kt              # Foreground service with overlay
    │
    ├── supabase/migrations/
    │   ├── 001_initial_schema.sql          # Tables, RLS, auto-profile trigger, seed data
    │   ├── 002_secure_rpc_functions.sql    # 5 RPCs + tightened RLS policies
    │   ├── 003_add_sleep_log_minutes.sql   # Minute-level sleep times
    │   ├── 004_fix_sleep_streak_logic.sql  # Streak calculation fix
    │   └── 005_emergency_override_rpc.sql  # Dedicated override token deduction
    │
    ├── test/widget_test.dart              # Unit tests (29 cases)
    ├── Makefile                           # Dev commands (run, build, test, analyze)
    └── pubspec.yaml                       # Dependencies
```

## Getting Started

### Prerequisites

- Flutter SDK (stable channel)
- A Supabase project ([supabase.com](https://supabase.com))
- Android device or emulator (for app-lock features)

### Setup

1. **Install dependencies**
   ```bash
   cd nappu_app
   flutter pub get
   ```

2. **Configure Supabase**
   - Create a project on [supabase.com](https://supabase.com/dashboard)
   - Run all SQL migrations in `supabase/migrations/` in order via the SQL Editor
   - Enable **Anonymous Sign-In** under Authentication → Providers (for guest mode)

3. **Set credentials** (choose one)
   ```bash
   # Option A: environment variables (recommended)
   make run SUPABASE_URL=https://your-project.supabase.co SUPABASE_ANON_KEY=your-key

   # Option B: edit the config file directly
   # lib/config/supabase_config.dart
   ```

4. **Android permissions** — The app requests Usage Access and Display Over Apps at runtime for app-lock functionality

### Run

```bash
make run          # debug on connected Android device
make run-web      # debug on Chrome
make build-release # release APK
make test         # run unit tests (29 cases)
make analyze      # static analysis
```

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter (Dart), Provider, fl_chart, Google Fonts |
| Backend | Supabase (PostgreSQL, Auth, RLS, RPC) |
| Native | Kotlin (Android foreground service, UsageStatsManager, WindowManager) |
| Auth | Email/password + anonymous sign-in with upgrade path |

## Security Model

- All token mutations, purchases, task completions, and sleep logging go through **server-side RPC functions** (`security definer`)
- **RLS policies** prevent direct client writes to sensitive columns (tokens, XP, streak)
- Client can only update safe profile fields (`display_name`, `nappu_mood`)
- Emergency override uses a dedicated RPC with balance validation
- Supabase credentials are injectable via `--dart-define` environment variables

## Known Limitations

- **Android only** for app-lock functionality (web/iOS show the UI but cannot block apps)
- No push notifications for bedtime reminders yet
- No delete-account flow yet
- No iOS native implementation
- Shop item prices are trusted client-side (server validates balance but not catalog price)

## License

Private — not open source.
