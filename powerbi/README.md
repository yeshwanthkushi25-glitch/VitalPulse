# VitalPulse Power BI project

`VitalPulse_Analytics.pbip` is a source-controlled Power BI Project for the VitalPulse website/app. It models the Supabase tables used by the app:

- `Profiles` — profile details and wellness targets
- `Nutrition Logs` — food and beverage entries, calories, and macros
- `Daily Health Logs` — steps, heart rate, sleep, and hydration

## Open it

1. Install Power BI Desktop with Power BI Project support.
2. Open `VitalPulse_Analytics.pbip`.
3. The report opens with safe, self-contained demo data; no database login is required.
4. Use **Transform data** to replace the three demo M queries with the approved Supabase/PostgreSQL queries when you are ready to connect live data.

The project contains synthetic demo records only. It does not contain a password, service-role key, Supabase publishable key, or private user data.

## Important access note

The app's Supabase RLS policies are based on the signed-in user's `auth.uid()`. Power BI does not automatically carry a VitalPulse user's session JWT into a PostgreSQL connection. Use a separately governed, read-only analytics role or an approved export/warehouse for organisation-wide reporting. Do not put a service-role key or database password in this repository.

## Included measures

The semantic model includes nutrition entries, total calories, protein, carbohydrates, fat, average calories per entry, health days, total/average steps, average sleep, average heart rate, and total/average water.

The report uses the same field names as the live schema so the sample visuals can be validated before connecting real data. After connecting, add slicers for `Profiles[fitness_goal]`, `Nutrition Logs[entry_type]`, and the log dates as needed.
