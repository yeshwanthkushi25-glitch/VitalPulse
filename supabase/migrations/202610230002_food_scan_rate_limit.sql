-- Private, service-role-only counter to cap AI provider usage per authenticated account.
create table if not exists public.food_scan_daily_limits (
  user_id uuid not null references auth.users (id) on delete cascade,
  scan_date date not null default current_date,
  scan_count integer not null default 0 check (scan_count between 0 and 20),
  primary key (user_id, scan_date)
);

alter table public.food_scan_daily_limits enable row level security;
alter table public.food_scan_daily_limits force row level security;
revoke all on public.food_scan_daily_limits from public, anon, authenticated;
grant all on public.food_scan_daily_limits to service_role;

create or replace function public.take_food_scan_slot(p_user_id uuid)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  updated_count integer;
begin
  if p_user_id is null then
    return false;
  end if;
  insert into public.food_scan_daily_limits (user_id, scan_date, scan_count)
  values (p_user_id, current_date, 1)
  on conflict (user_id, scan_date) do update
    set scan_count = public.food_scan_daily_limits.scan_count + 1
    where public.food_scan_daily_limits.scan_count < 20
  returning scan_count into updated_count;
  return updated_count is not null;
end;
$$;

revoke all on function public.take_food_scan_slot(uuid) from public, anon, authenticated;
grant execute on function public.take_food_scan_slot(uuid) to service_role;
