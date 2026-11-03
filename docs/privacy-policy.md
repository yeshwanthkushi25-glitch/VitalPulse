# VitalPulse privacy policy

VitalPulse is a health and nutrition tracking app. This policy describes the Flutter app and its Supabase backend. The preserved HTML demos in `demos/` are local-only prototypes and do not provide real authentication or server storage.

## Data the app processes

- Account email and profile name through Supabase Auth.
- Nutrition entries and user-entered daily health summaries (steps, water, sleep, and optional heart rate) in your Supabase account.
- With your explicit permission, steps, heart rate, and sleep read from Apple Health or Google Health Connect and sent to your own VitalPulse account.
- A meal photo is sent to the configured AI provider only after you request a scan. The photo is not saved to VitalPulse storage. The provider may process it to return an estimate.

The app does not request write access to HealthKit or Health Connect. Health data is not used for advertising. Estimates are approximate and are not medical advice.

## Storage and access

Supabase stores account data. Database row-level security restricts records to the signed-in account. The AI scan function requires a signed-in user, limits scans per account per day, and keeps provider credentials on the server. Use a private Supabase project and configure authentication and backups before production.

## Your choices

You can decline or revoke device health permissions in Apple Health or Health Connect. Sign out to end the current session. Delete logged records from the app; for full account deletion, contact the project owner until self-service account deletion is available.

## Contact

This is a starter privacy policy for the VitalPulse project. Replace it with the operating organization’s contact details and review it before public release or store submission.
