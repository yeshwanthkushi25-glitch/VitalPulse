# VitalPulse test backend

This folder contains the Supabase CLI project and a multi-user schema. Nutrition and daily health rows are owned by authenticated Supabase users and protected by row-level security.

## After Docker Desktop is installed

From this folder's parent directory, run:

```powershell
npx supabase start
```

The local stack is for development and testing. It runs locally and is not a public website host.

## Connect to a Supabase cloud project

After signing in with `npx supabase login`, link this project using the project reference, then apply the migration with `npx supabase db push`. The website still needs a static web host or local web server; Supabase CLI deploys database migrations and backend services, not this standalone HTML page.

Do not put service-role keys or AI provider keys in the HTML source. Configure browser AI keys locally for testing only. A public deployment needs server-side key handling.
