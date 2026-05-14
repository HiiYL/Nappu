-- =============================================
-- Dedicated RPC for emergency override token spending
-- Avoids reusing purchase_shop_item with invalid category
-- =============================================

create or replace function public.spend_emergency_override_tokens(p_cost int default 50)
returns json as $$
declare
  v_user_id uuid := auth.uid();
  v_current_tokens int;
  v_new_balance int;
begin
  -- Get current balance
  select tokens into v_current_tokens
    from public.profiles where id = v_user_id;

  if v_current_tokens is null then
    return json_build_object('success', false, 'error', 'User not found');
  end if;

  if v_current_tokens < p_cost then
    return json_build_object('success', false, 'error', 'Not enough tokens');
  end if;

  -- Deduct tokens
  update public.profiles
    set tokens = tokens - p_cost,
        updated_at = now()
    where id = v_user_id
    returning tokens into v_new_balance;

  -- Log transaction
  insert into public.token_transactions (user_id, amount, reason)
    values (v_user_id, -p_cost, 'Emergency override (15 min)');

  return json_build_object(
    'success', true,
    'new_balance', v_new_balance
  );
end;
$$ language plpgsql security definer;
