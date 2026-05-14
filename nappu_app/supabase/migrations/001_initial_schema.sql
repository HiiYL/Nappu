-- =============================================
-- Nappu - Supabase Schema
-- Run this in your Supabase SQL Editor
-- =============================================

-- 1. User profiles (extends Supabase auth.users)
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text not null default 'User',
  tokens int not null default 0,
  streak int not null default 0,
  nappu_level int not null default 1,
  nappu_xp int not null default 0,
  nappu_max_xp int not null default 1000,
  nappu_mood text not null default 'happy',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

-- 2. Sleep logs (one per day per user)
create table public.sleep_logs (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  log_date date not null,
  quality text not null check (quality in ('Poor', 'Okay', 'Good', 'Great')),
  bedtime_hour int not null,
  wakeup_hour int not null,
  duration_hours numeric(4,1) not null,
  tokens_earned int not null default 50,
  created_at timestamptz not null default now(),
  unique (user_id, log_date)
);

-- 3. Sleep tasks (nightly checklist)
create table public.sleep_tasks (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  task_date date not null default current_date,
  task_name text not null,
  coins int not null default 0,
  completed boolean not null default false,
  created_at timestamptz not null default now()
);

-- 4. App-lock settings
create table public.app_lock_settings (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  enabled boolean not null default true,
  lock_start_hour int not null default 22,
  lock_start_minute int not null default 30,
  lock_end_hour int not null default 7,
  lock_end_minute int not null default 0,
  updated_at timestamptz not null default now(),
  unique (user_id)
);

-- 5. Locked apps list
create table public.locked_apps (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  app_name text not null,
  status text not null default 'Locked' check (status in ('Locked', 'Reminder')),
  unique (user_id, app_name)
);

-- 6. Inventory (hats, outfits, accessories, room themes)
create table public.inventory (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  category text not null check (category in ('Hats', 'Outfits', 'Accessories', 'Themes')),
  item_name text not null,
  owned boolean not null default false,
  equipped boolean not null default false,
  unique (user_id, category, item_name)
);

-- 7. Biweekly insights (generated summaries)
create table public.biweekly_insights (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  period_start date not null,
  period_end date not null,
  avg_sleep_hours numeric(4,1),
  insight_text text not null,
  created_at timestamptz not null default now()
);

-- 8. Token transactions (compact log of important changes)
create table public.token_transactions (
  id bigint generated always as identity primary key,
  user_id uuid not null references public.profiles(id) on delete cascade,
  amount int not null,
  reason text not null,
  created_at timestamptz not null default now()
);

-- =============================================
-- Row Level Security
-- =============================================
alter table public.profiles enable row level security;
alter table public.sleep_logs enable row level security;
alter table public.sleep_tasks enable row level security;
alter table public.app_lock_settings enable row level security;
alter table public.locked_apps enable row level security;
alter table public.inventory enable row level security;
alter table public.biweekly_insights enable row level security;
alter table public.token_transactions enable row level security;

-- Users can only access their own data
create policy "Users read own profile" on public.profiles
  for select using (auth.uid() = id);
create policy "Users update own profile" on public.profiles
  for update using (auth.uid() = id);
create policy "Users insert own profile" on public.profiles
  for insert with check (auth.uid() = id);

create policy "Users read own sleep_logs" on public.sleep_logs
  for select using (auth.uid() = user_id);
create policy "Users insert own sleep_logs" on public.sleep_logs
  for insert with check (auth.uid() = user_id);

create policy "Users manage own sleep_tasks" on public.sleep_tasks
  for all using (auth.uid() = user_id);

create policy "Users manage own app_lock_settings" on public.app_lock_settings
  for all using (auth.uid() = user_id);

create policy "Users manage own locked_apps" on public.locked_apps
  for all using (auth.uid() = user_id);

create policy "Users manage own inventory" on public.inventory
  for all using (auth.uid() = user_id);

create policy "Users read own insights" on public.biweekly_insights
  for select using (auth.uid() = user_id);
create policy "Users insert own insights" on public.biweekly_insights
  for insert with check (auth.uid() = user_id);

create policy "Users read own transactions" on public.token_transactions
  for select using (auth.uid() = user_id);
create policy "Users insert own transactions" on public.token_transactions
  for insert with check (auth.uid() = user_id);

-- =============================================
-- Auto-create profile on signup
-- =============================================
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data->>'display_name', 'User'));
  
  -- Seed default app-lock settings
  insert into public.app_lock_settings (user_id)
  values (new.id);

  -- Seed default locked apps
  insert into public.locked_apps (user_id, app_name, status) values
    (new.id, 'Instagram', 'Locked'),
    (new.id, 'TikTok', 'Locked'),
    (new.id, 'WhatsApp', 'Reminder'),
    (new.id, 'YouTube', 'Locked');

  -- Seed default inventory (free starter items)
  insert into public.inventory (user_id, category, item_name, owned, equipped) values
    (new.id, 'Hats', 'Top Hat', true, true),
    (new.id, 'Hats', 'Cap', true, false),
    (new.id, 'Outfits', 'Pajamas', true, true),
    (new.id, 'Themes', 'Night Sky', true, true),
    (new.id, 'Themes', 'Sakura', true, false);

  -- Seed today's sleep tasks
  insert into public.sleep_tasks (user_id, task_name, coins) values
    (new.id, 'No screen 30 mins before bed', 20),
    (new.id, 'Dim lights at 10:30 PM', 15),
    (new.id, '5-min mindfulness breathing', 25),
    (new.id, 'Sleep by 11:00 PM', 30);

  return new;
end;
$$ language plpgsql security definer;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- =============================================
-- Indexes
-- =============================================
create index idx_sleep_logs_user_date on public.sleep_logs (user_id, log_date desc);
create index idx_sleep_tasks_user_date on public.sleep_tasks (user_id, task_date);
create index idx_token_transactions_user on public.token_transactions (user_id, created_at desc);
create index idx_inventory_user_cat on public.inventory (user_id, category);
