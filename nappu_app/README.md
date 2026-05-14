# Nappu

A gamified sleep-habit companion app for teens. Log sleep, complete nightly tasks, earn tokens, customise your virtual pet Nappu, and lock distracting apps during bedtime — all powered by a Supabase backend with server-side security.

## Features

- **Sleep Logging** — Record bedtime/wakeup, view weekly chart, biweekly AI insights
- **Nightly Tasks** — Checklist (no screen time, dim lights, breathing, etc.) that awards tokens
- **Token Economy** — Earn tokens from tasks and sleep logs; spend in Nappu's Room
- **Nappu's Room** — Customise your sheep with hats, outfits, accessories, and room themes
- **App Lock** — Schedule-based Android app blocking with overlay, emergency override (costs tokens)
- **Streaks & Levels** — Consecutive-day streaks and XP-based levelling
- **Optimistic UI** — Instant feedback with server-verified rollback on failure

## Architecture

```
Flutter (Dart)  ──▶  Supabase (Postgres + Auth)
     │                  ├─ 8 tables with RLS
     │                  └─ 6 RPC functions (security definer)
     └──▶  Android Native (Kotlin)
              └─ AppLockService (foreground service + overlay)
```

- **Direct reads** for all data; **RPC** for sensitive writes (tokens, streaks, purchases, sleep logs)
- **RLS policies** restrict client to safe fields only
- **Platform channel** bridges Flutter ↔ Android for app-lock service

## Project Structure

```
lib/
├── config/supabase_config.dart   # Supabase URL + anon key
├── theme/app_theme.dart          # Dark theme + colour palette
├── models/app_state.dart         # ChangeNotifier — all app state
├── services/
│   ├── supabase_service.dart     # All Supabase client calls
│   └── app_lock_native.dart      # Platform channel wrapper
└── screens/
    ├── auth_screen.dart          # Sign-up / sign-in
    ├── home_screen.dart          # Dashboard + tasks
    ├── sleep_log_screen.dart     # Log sleep + weekly chart
    ├── app_lock_screen.dart      # Schedule + locked apps
    ├── nappu_screen.dart         # Pet room + shop
    └── token_history_screen.dart # Transaction log

android/.../
├── MainActivity.kt              # Platform channel handler
└── AppLockService.kt            # Foreground service with overlay

supabase/migrations/
├── 001_initial_schema.sql
├── 002_secure_rpc_functions.sql
├── 003_add_sleep_log_minutes.sql
├── 004_fix_sleep_streak_logic.sql
└── 005_emergency_override_rpc.sql
```

## Setup

1. **Flutter**: `flutter pub get`
2. **Supabase**: Create a project, run all migrations in `supabase/migrations/` in order via the SQL Editor
3. **Config**: Update `lib/config/supabase_config.dart` with your project URL and anon key
4. **Android permissions**: The app requests Usage Access and Display Over Apps at runtime

## Run

```bash
flutter run                    # debug on connected device
flutter build apk --debug     # build debug APK
flutter test                   # run unit tests
flutter analyze                # static analysis
```

## Known Limitations

- **Android only** for app-lock functionality (web/iOS show UI but cannot block apps)
- No push notifications for bedtime reminders yet
- No delete-account flow yet
- Shop item prices are trusted client-side (server validates balance but not catalog price)
