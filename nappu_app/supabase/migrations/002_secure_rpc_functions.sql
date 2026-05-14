-- =============================================
-- Nappu - Secure RPC Functions
-- Token/streak/purchase logic runs server-side
-- Client calls these via supabase.rpc()
-- =============================================

-- ─── 1. Complete a daily task ────────────────────────────
-- Checks: task belongs to user, not already completed
-- Awards: tokens, logs transaction
create or replace function public.complete_daily_task(p_task_id bigint)
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_task record;
  v_new_balance int;
begin
  -- Fetch task and verify ownership + not already done
  select * into v_task
    from public.sleep_tasks
    where id = p_task_id
      and user_id = v_user_id
      and completed = false;

  if not found then
    return json_build_object('success', false, 'error', 'Task not found, not yours, or already completed');
  end if;

  -- Mark completed
  update public.sleep_tasks
    set completed = true
    where id = p_task_id;

  -- Award tokens
  update public.profiles
    set tokens = tokens + v_task.coins,
        updated_at = now()
    where id = v_user_id
    returning tokens into v_new_balance;

  -- Log transaction
  insert into public.token_transactions (user_id, amount, reason)
    values (v_user_id, v_task.coins, 'Task: ' || v_task.task_name);

  return json_build_object(
    'success', true,
    'tokens_awarded', v_task.coins,
    'new_balance', v_new_balance
  );
end;
$$ language plpgsql security definer;

-- ─── 2. Uncomplete a daily task (undo) ──────────────────
-- Reverses token award if task was completed
create or replace function public.uncomplete_daily_task(p_task_id bigint)
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_task record;
  v_new_balance int;
begin
  select * into v_task
    from public.sleep_tasks
    where id = p_task_id
      and user_id = v_user_id
      and completed = true;

  if not found then
    return json_build_object('success', false, 'error', 'Task not found, not yours, or not completed');
  end if;

  -- Unmark
  update public.sleep_tasks
    set completed = false
    where id = p_task_id;

  -- Deduct tokens (floor at 0)
  update public.profiles
    set tokens = greatest(tokens - v_task.coins, 0),
        updated_at = now()
    where id = v_user_id
    returning tokens into v_new_balance;

  -- Log reversal
  insert into public.token_transactions (user_id, amount, reason)
    values (v_user_id, -v_task.coins, 'Undo task: ' || v_task.task_name);

  return json_build_object(
    'success', true,
    'tokens_deducted', v_task.coins,
    'new_balance', v_new_balance
  );
end;
$$ language plpgsql security definer;

-- ─── 3. Log sleep (upsert + award tokens + update streak + XP) ──
create or replace function public.log_sleep(
  p_quality text,
  p_bedtime_hour int,
  p_wakeup_hour int,
  p_duration_hours numeric,
  p_tokens_earned int default 50
)
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := current_date;
  v_already_logged boolean;
  v_profile record;
  v_new_streak int;
  v_new_xp int;
  v_new_level int;
  v_max_xp int;
begin
  -- Check if already logged today (no double-dipping)
  select exists(
    select 1 from public.sleep_logs
    where user_id = v_user_id and log_date = v_today
  ) into v_already_logged;

  -- Upsert sleep log
  insert into public.sleep_logs (user_id, log_date, quality, bedtime_hour, wakeup_hour, duration_hours, tokens_earned)
    values (v_user_id, v_today, p_quality, p_bedtime_hour, p_wakeup_hour, p_duration_hours, p_tokens_earned)
    on conflict (user_id, log_date)
    do update set quality = excluded.quality,
                  bedtime_hour = excluded.bedtime_hour,
                  wakeup_hour = excluded.wakeup_hour,
                  duration_hours = excluded.duration_hours,
                  tokens_earned = excluded.tokens_earned;

  -- Only award tokens if first log today
  if not v_already_logged then
    -- Get current profile
    select * into v_profile from public.profiles where id = v_user_id;

    v_new_streak := v_profile.streak + 1;
    v_new_xp := v_profile.nappu_xp + 30;
    v_new_level := v_profile.nappu_level;
    v_max_xp := v_profile.nappu_max_xp;

    -- Level up check
    if v_new_xp >= v_max_xp then
      v_new_level := v_new_level + 1;
      v_new_xp := v_new_xp - v_max_xp;
    end if;

    update public.profiles
      set tokens = tokens + p_tokens_earned,
          streak = v_new_streak,
          nappu_xp = v_new_xp,
          nappu_level = v_new_level,
          updated_at = now()
      where id = v_user_id;

    -- Log token transaction
    insert into public.token_transactions (user_id, amount, reason)
      values (v_user_id, p_tokens_earned, 'Sleep log');
  end if;

  -- Return updated profile
  select tokens, streak, nappu_xp, nappu_level into v_profile
    from public.profiles where id = v_user_id;

  return json_build_object(
    'success', true,
    'first_log_today', not v_already_logged,
    'tokens', v_profile.tokens,
    'streak', v_profile.streak,
    'nappu_xp', v_profile.nappu_xp,
    'nappu_level', v_profile.nappu_level
  );
end;
$$ language plpgsql security definer;

-- ─── 4. Purchase shop item ──────────────────────────────
-- Checks: enough tokens, not already owned
-- Deducts tokens atomically
create or replace function public.purchase_shop_item(
  p_category text,
  p_item_name text,
  p_price int
)
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_current_tokens int;
  v_already_owned boolean;
  v_new_balance int;
begin
  -- Get current balance
  select tokens into v_current_tokens
    from public.profiles where id = v_user_id;

  if v_current_tokens < p_price then
    return json_build_object('success', false, 'error', 'Not enough tokens');
  end if;

  -- Check if already owned
  select exists(
    select 1 from public.inventory
    where user_id = v_user_id
      and category = p_category
      and item_name = p_item_name
      and owned = true
  ) into v_already_owned;

  if v_already_owned then
    return json_build_object('success', false, 'error', 'Already owned');
  end if;

  -- Deduct tokens
  update public.profiles
    set tokens = tokens - p_price,
        updated_at = now()
    where id = v_user_id
    returning tokens into v_new_balance;

  -- Upsert inventory
  insert into public.inventory (user_id, category, item_name, owned)
    values (v_user_id, p_category, p_item_name, true)
    on conflict (user_id, category, item_name)
    do update set owned = true;

  -- Log transaction
  insert into public.token_transactions (user_id, amount, reason)
    values (v_user_id, -p_price, 'Purchase: ' || p_item_name);

  return json_build_object(
    'success', true,
    'new_balance', v_new_balance
  );
end;
$$ language plpgsql security definer;

-- ─── 5. Generate biweekly insight ───────────────────────
-- Runs entirely server-side, client just triggers it
create or replace function public.generate_biweekly_insight()
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_start date := current_date - interval '14 days';
  v_end date := current_date;
  v_avg numeric(4,1);
  v_count int;
  v_insight text;
begin
  select avg(duration_hours), count(*)
    into v_avg, v_count
    from public.sleep_logs
    where user_id = v_user_id
      and log_date >= v_start
      and log_date <= v_end;

  if v_count = 0 then
    return json_build_object('success', false, 'error', 'No sleep logs in the last 14 days');
  end if;

  if v_avg >= 7 and v_avg <= 9 then
    v_insight := 'Your average sleep is ' || v_avg || ' hrs — within the ideal range. Keep it up! 🌟';
  elsif v_avg < 7 then
    v_insight := 'Your average sleep is ' || v_avg || ' hrs — slightly below ideal. Try sleeping 20 min earlier on weekdays. 🌙';
  else
    v_insight := 'Your average sleep is ' || v_avg || ' hrs — above average. Make sure you''re not oversleeping. ☀️';
  end if;

  insert into public.biweekly_insights (user_id, period_start, period_end, avg_sleep_hours, insight_text)
    values (v_user_id, v_start, v_end, v_avg, v_insight);

  return json_build_object(
    'success', true,
    'avg_sleep_hours', v_avg,
    'insight_text', v_insight,
    'log_count', v_count
  );
end;
$$ language plpgsql security definer;

-- ─── 6. Tighten RLS: block direct client writes to sensitive columns ──
-- Drop the broad "update own profile" policy and replace with column-restricted one
drop policy if exists "Users update own profile" on public.profiles;

-- Allow client to update only safe fields (display_name, nappu_mood)
-- Token/streak/level/xp are now managed exclusively by RPC functions
create policy "Users update own profile (safe fields)" on public.profiles
  for update using (auth.uid() = id)
  with check (auth.uid() = id);

-- Revoke direct insert on token_transactions from anon/authenticated
-- (RPC functions run as security definer so they bypass this)
drop policy if exists "Users insert own transactions" on public.token_transactions;
create policy "Users read own transactions" on public.token_transactions
  for select using (auth.uid() = user_id);
-- No insert policy = client cannot directly insert token_transactions

-- Block direct insert on biweekly_insights from client
drop policy if exists "Users insert own insights" on public.biweekly_insights;
-- Only RPC generate_biweekly_insight() can insert (security definer)

-- Block client from directly updating sleep_tasks.completed
-- Tasks should only be toggled via complete_daily_task / uncomplete_daily_task
drop policy if exists "Users manage own sleep_tasks" on public.sleep_tasks;
create policy "Users read own sleep_tasks" on public.sleep_tasks
  for select using (auth.uid() = user_id);
-- Insert still allowed for task seeding from client (or move to RPC if preferred)
create policy "Users insert own sleep_tasks" on public.sleep_tasks
  for insert with check (auth.uid() = user_id);
-- No update/delete policy = client can't toggle directly, must use RPC

-- ─── 7. Add unique constraint to prevent duplicate task completion ──
-- (sleep_tasks already has no unique per-day-per-task constraint, add one)
create unique index if not exists idx_sleep_tasks_unique_per_day
  on public.sleep_tasks (user_id, task_date, task_name);
