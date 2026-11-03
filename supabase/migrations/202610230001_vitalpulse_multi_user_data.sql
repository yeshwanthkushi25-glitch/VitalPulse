-- VitalPulse test schema: every record belongs to the authenticated Supabase user.
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null default '',
  height_cm numeric(5,1),
  weight_kg numeric(5,1),
  birth_year integer,
  gender text,
  fitness_goal text not null default 'maintain',
  language_code text not null default 'en',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_height_range check (height_cm is null or height_cm between 80 and 250),
  constraint profiles_weight_range check (weight_kg is null or weight_kg between 20 and 350)
);

create table if not exists public.nutrition_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  entry_type text not null check (entry_type in ('food', 'beverage')),
  title text not null,
  meal_type text,
  logged_at timestamptz not null default now(),
  portion_g numeric(8,2),
  volume_ml integer,
  calories_kcal numeric(8,2) not null default 0,
  protein_g numeric(8,2) not null default 0,
  carbs_g numeric(8,2) not null default 0,
  fats_g numeric(8,2) not null default 0,
  nutrients jsonb not null default '{}'::jsonb,
  estimate_source text not null default 'manual',
  created_at timestamptz not null default now()
);

create index if not exists nutrition_logs_user_date_idx on public.nutrition_logs (user_id, logged_at desc);

create table if not exists public.daily_health_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  log_date date not null default current_date,
  steps integer not null default 0,
  heart_rate_bpm integer,
  sleep_hours numeric(4,2),
  water_ml integer not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, log_date)
);

alter table public.profiles enable row level security;
alter table public.nutrition_logs enable row level security;
alter table public.daily_health_logs enable row level security;
alter table public.profiles force row level security;
alter table public.nutrition_logs force row level security;
alter table public.daily_health_logs force row level security;

-- Reject malformed or abusive values at the database boundary as well as in the app.
alter table public.nutrition_logs
  add constraint nutrition_title_length check (char_length(title) between 1 and 180),
  add constraint nutrition_calories_range check (calories_kcal between 0 and 20000),
  add constraint nutrition_macros_range check (protein_g between 0 and 2000 and carbs_g between 0 and 3000 and fats_g between 0 and 1000),
  add constraint nutrition_portion_range check (portion_g is null or portion_g between 0 and 100000),
  add constraint nutrition_volume_range check (volume_ml is null or volume_ml between 0 and 1000000);
alter table public.daily_health_logs
  add constraint daily_steps_range check (steps between 0 and 200000),
  add constraint daily_hr_range check (heart_rate_bpm is null or heart_rate_bpm between 25 and 250),
  add constraint daily_sleep_range check (sleep_hours is null or sleep_hours between 0 and 24),
  add constraint daily_water_range check (water_ml between 0 and 30000);

drop policy if exists "Users manage their own profile" on public.profiles;
create policy "Users manage their own profile" on public.profiles
  for all to authenticated using (id = (select auth.uid())) with check (id = (select auth.uid()));

drop policy if exists "Users manage their own nutrition logs" on public.nutrition_logs;
create policy "Users manage their own nutrition logs" on public.nutrition_logs
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

drop policy if exists "Users manage their own daily health logs" on public.daily_health_logs;
create policy "Users manage their own daily health logs" on public.daily_health_logs
  for all to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));

-- Authenticated clients need CRUD only on the user-scoped tables. No anonymous access.
revoke all on public.profiles, public.nutrition_logs, public.daily_health_logs from anon;
grant select, insert, update, delete on public.profiles, public.nutrition_logs, public.daily_health_logs to authenticated;

-- New auth users receive a private profile row automatically.
create or replace function public.create_vitalpulse_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, display_name)
  values (new.id, coalesce(new.raw_user_meta_data ->> 'name', ''))
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created_vitalpulse on auth.users;
create trigger on_auth_user_created_vitalpulse
  after insert on auth.users
  for each row execute procedure public.create_vitalpulse_profile();

revoke all on function public.create_vitalpulse_profile() from public, anon, authenticated;
