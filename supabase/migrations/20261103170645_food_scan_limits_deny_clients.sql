-- Explicitly deny direct API access; service_role-only function calls bypass RLS.
create policy "No client access to food scan limits"
  on public.food_scan_daily_limits
  for all
  to anon, authenticated
  using (false)
  with check (false);
