-- =============================================
-- Add minute columns to sleep_logs for precise bedtime/wakeup
-- =============================================

alter table public.sleep_logs
  add column if not exists bedtime_minute int not null default 0,
  add column if not exists wakeup_minute int not null default 0;

-- Update log_sleep RPC to accept minutes
create or replace function public.log_sleep(
  p_quality text,
  p_bedtime_hour int,
  p_wakeup_hour int,
  p_duration_hours numeric,
  p_tokens_earned int default 50,
  p_bedtime_minute int default 0,
  p_wakeup_minute int default 0
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
  insert into public.sleep_logs (user_id, log_date, quality, bedtime_hour, bedtime_minute, wakeup_hour, wakeup_minute, duration_hours, tokens_earned)
    values (v_user_id, v_today, p_quality, p_bedtime_hour, p_bedtime_minute, p_wakeup_hour, p_wakeup_minute, p_duration_hours, p_tokens_earned)
    on conflict (user_id, log_date)
    do update set quality = excluded.quality,
                  bedtime_hour = excluded.bedtime_hour,
                  bedtime_minute = excluded.bedtime_minute,
                  wakeup_hour = excluded.wakeup_hour,
                  wakeup_minute = excluded.wakeup_minute,
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
