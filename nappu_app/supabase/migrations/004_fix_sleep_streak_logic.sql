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
  v_previous_log_date date;
  v_new_streak int;
  v_new_xp int;
  v_new_level int;
  v_max_xp int;
begin
  select exists(
    select 1 from public.sleep_logs
    where user_id = v_user_id and log_date = v_today
  ) into v_already_logged;

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

  if not v_already_logged then
    select * into v_profile from public.profiles where id = v_user_id;

    select max(log_date) into v_previous_log_date
    from public.sleep_logs
    where user_id = v_user_id and log_date < v_today;

    v_new_streak := case
      when v_previous_log_date = v_today - 1 then v_profile.streak + 1
      else 1
    end;
    v_new_xp := v_profile.nappu_xp + 30;
    v_new_level := v_profile.nappu_level;
    v_max_xp := v_profile.nappu_max_xp;

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

    insert into public.token_transactions (user_id, amount, reason)
      values (v_user_id, p_tokens_earned, 'Sleep log');
  end if;

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
