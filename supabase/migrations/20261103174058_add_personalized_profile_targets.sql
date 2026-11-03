-- Store adjustable wellness targets and sleep preferences on the user's own profile.
alter table public.profiles
  add column if not exists calorie_target_kcal integer,
  add column if not exists water_goal_ml integer,
  add column if not exists sleep_cycle_target smallint not null default 5,
  add column if not exists target_wake_time time without time zone not null default '06:30';

alter table public.profiles
  add constraint profiles_calorie_target_range
    check (calorie_target_kcal is null or calorie_target_kcal between 800 and 10000),
  add constraint profiles_water_goal_range
    check (water_goal_ml is null or water_goal_ml between 500 and 10000),
  add constraint profiles_sleep_cycle_range
    check (sleep_cycle_target between 3 and 8);
