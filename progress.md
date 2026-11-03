# VitalPulse Project Progress and Handoff

Updated: 2026-11-04

This document is a working handoff for the next AI or developer. Continue the current task from this state; do not restart the project or replace user work without checking it first.

## User's goal

The user wants the different VitalPulse websites and apps to have the same features, stay connected to one Supabase backend, and be uploaded to the public GitHub repository. They also previously asked to use Flutter in VS Code, run the app in Chrome, deploy it, and upload project demo screenshots.

## Workspace and repository

- Local project: `C:\Users\yeshwanth\OneDrive\healthy_website`
- Git branch: `main`
- Git remote: `https://github.com/yeshwanthkushi25-glitch/VitalPulse.git`
- GitHub repository is public: `https://github.com/yeshwanthkushi25-glitch/VitalPulse`
- Supabase project reference: `jmteswvfobeqcapykswv`
- Supabase URL: `https://jmteswvfobeqcapykswv.supabase.co`
- Intended live site: `https://yeshwanthkushi25-glitch.github.io/VitalPulse/`
- `.vscode/settings.json` is untracked user-specific configuration. Leave it out of commits.
- Local `.env.local` files are ignored. Do not commit them.

## Project shape

- `vitalpulse_app/` is the Flutter app for web, Android, iOS, and Windows.
- `supabase/migrations/` contains the Postgres schema and RLS migrations.
- `supabase/functions/analyze-food/index.ts` contains the authenticated meal photo scanner.
- `demos/` contains the three original HTML prototypes. They remain in source control as project history; the deployed artifact is being configured to serve the same Flutter app at those legacy paths.
- `docs/screenshots/` already contains screenshots for the app and demos: `flutter-app-login.png`, `food-drink-scanner.png`, `personalized-diet.png`, and `supabase-dashboard.png`.

## Work completed in this task

### Flutter feature sync

`vitalpulse_app/lib/main.dart` has been extended so the shared Flutter app covers the main prototype features:

- Supabase email registration/sign-in remains the real authentication flow.
- Default Supabase URL and **publishable** client key are available in the app; they may still be overridden with Dart defines. The publishable key is intended for client use and must always be protected by RLS. No service-role or AI provider keys are in Flutter.
- Profile settings include display name, height, weight, birth year, gender, wellness goal, calorie target, and water target.
- Manual food and beverage entry includes meal type, calories, macros, sugar, fiber, portion, and optional drink volume.
- Common foods and drinks have quick-add buttons.
- Hydration includes quick amounts, decrement, and custom amounts.
- Sleep includes 90-minute cycle choices, wake-time selection, bedtime estimate, and cross-device profile persistence.
- Health sync reads Apple Health / Health Connect only on supported native devices; web shows that mobile sync is needed.
- The app includes seven-day health history, a seven-day calorie trend, deep nutrition summary, and JSON backup copied to the clipboard.
- Meal photo scanning lets the user choose food or beverage; it requests an estimate from the authenticated Supabase Edge Function and asks the user to review before saving.

### Supabase

- Existing database tables remain owner-scoped by RLS.
- A new migration created with the Supabase CLI is stored at `supabase/migrations/20261103174058_add_personalized_profile_targets.sql`. It adds validated calorie, water, sleep cycle, and wake-time preferences to `public.profiles`.
- That migration was applied to production with the Supabase connector. The migration list now includes `20261103174058 add_personalized_profile_targets`.
- The production `analyze-food` Edge Function was redeployed as version 4 and is active with JWT verification enabled.
- It supports OpenRouter first, then the two Gemini fallback secrets, and returns extended optional nutrition details.
- The following secret names are saved in Supabase Edge Function Secrets; **their values must never be copied into source, GitHub, this document, or user-facing output**:
  - `OPENROUTER_API_KEY`
  - `GEMINI_API_KEY_1`
  - `GEMINI_API_KEY_2`
  - `ALLOWED_ORIGINS`
- `ALLOWED_ORIGINS` is set to the GitHub Pages origin `https://yeshwanthkushi25-glitch.github.io`.
- No AI provider request was made while configuring secrets or redeploying the function.
- Performance advisor returned no lints. Security advisor returned one warning: leaked-password protection is disabled. Supabase documentation says this feature is available on Pro and above, not the Free plan. Do not upgrade the plan without the user's agreement. All other previously checked RLS protections were enabled.

### GitHub Pages deployment

- GitHub Pages was disabled when checked through the repository API.
- In GitHub repository Settings → Pages, the source was changed to **GitHub Actions**. The Pages settings now show GitHub Actions as the source.
- `.github/workflows/flutter.yml` was replaced with a workflow that:
  - runs Flutter analyze;
  - builds the web app using base path `/VitalPulse/`;
  - maps the three existing demo paths and three original HTML filenames to the same Flutter app in the Pages build artifact;
  - uploads the Pages artifact and deploys it from `main`;
  - builds an Android preview APK in a separate job and uploads it as a workflow artifact, so Android build failure does not block website deployment.
- Official workflow design follows GitHub Pages' Actions deployment model (`upload-pages-artifact` and `deploy-pages`).
- The final workflow run for commit `e972c78` completed with `build-web` and `deploy` successful. The separate `android-preview` job failed during `flutter build apk --debug`, so no Android APK artifact was uploaded. The Pages artifact was uploaded successfully.

### Documentation

- Root `README.md`, `vitalpulse_app/README.md`, and `supabase/README.md` were updated to describe the shared Flutter app, features, Supabase secrets, and deployment.
- This file, `progress.md`, is a handoff document and should be included in the eventual GitHub commit.

### Latest continuation (2026-11-04)

- Updated `vitalpulse_app/lib/main.dart` so Apple Health / Health Connect controls are rendered only on supported Android and iOS devices. Web and desktop now show the platform status without presenting a clickable sync control that cannot work there.
- Ran `dart format lib/main.dart`; the file was already formatted.
- Ran `flutter analyze --no-pub`; it completed with **No issues found**.
- Ran `MSYS_NO_PATHCONV=1 flutter build web --release --base-href /VitalPulse/`; it completed successfully and produced `build/web/index.html` and `build/web/main.dart.js`. Git Bash path conversion caused the first Windows invocation to reject the base href before compilation; the corrected invocation succeeded.
- Ran `git diff --check`; it passed. The local `.vscode/settings.json` remains untracked and is excluded from the commit.
- Committed the code and progress updates as `5ed05c0` (`fix: clarify health sync availability`) and pushed them to `origin main`.
- The direct Chrome launch was unavailable because this laptop has no supported Chrome device. A local static preview of the completed web artifact was served and opened at `http://localhost:9322/VitalPulse/`; it returned HTTP 200.
- The public Pages URL returned HTTP 200. The successful web deployment run is recorded at `https://github.com/yeshwanthkushi25-glitch/VitalPulse/actions/runs/41707697567`.
- The three deployed demo paths and all three original `vitalpulse_ai_*.html` compatibility URLs also returned HTTP 200.
- Investigated the reported login error. The Supabase Auth settings endpoint and GitHub Pages CORS preflight both returned HTTP 200; email confirmation is enabled in the project.
- Updated `vitalpulse_app/lib/main.dart` to show clearer invalid-credential and unconfirmed-email messages and to provide a resend-confirmation-email action. No credentials or provider secrets were logged.
- Re-ran `dart format lib/main.dart`, `flutter analyze --no-pub` (**No issues found**), and `MSYS_NO_PATHCONV=1 flutter build web --release --base-href /VitalPulse/` (successful).
- The login fix is ready to commit and push; the exact user-visible error text was not supplied.

## Verification so far

- `flutter analyze --no-pub` completed successfully with **No issues found** after the latest Flutter UI edits.
- `flutter build web --release --base-href /VitalPulse/` completed successfully after the latest edits. The output includes `index.html`, `main.dart.js`, assets, and service worker.
- The generated web bundle was checked for the intended Supabase URL and publishable client key; neither provider API keys nor service-role credentials were found in the bundle.
- A local Windows Android debug build was attempted and failed with Gradle error `java.io.IOException: Unable to establish loopback connection`. The GitHub workflow uses Ubuntu and has a separate Android job; check its result there. Do not claim the APK succeeded unless the Actions artifact is present.
- `gh` CLI is not installed. Use `git push` with the configured remote credentials and the GitHub connector or public GitHub API to inspect Actions runs.
- The local built preview is open at `http://localhost:9322/VitalPulse/`; direct Flutter Chrome launch is unavailable on this laptop.

## Immediate remaining work

1. Confirm the Pages URL returns the Flutter app, then confirm each of these compatibility URLs loads the same app:
   - `/VitalPulse/demos/food-drink-scanner/`
   - `/VitalPulse/demos/personalized-diet/`
   - `/VitalPulse/demos/supabase-dashboard/`
   - the three original `vitalpulse_ai_*.html` filenames at the site root.
2. Confirm the production function remains active and JWT-protected, the new migration is listed remotely, and the dashboard has the provider secret names without exposing values.
3. Report the GitHub repository and live Pages URL. State clearly that the Android preview artifact failed in GitHub Actions. Mention the one Free-plan Supabase password-protection warning.

## Safety reminders

- The user pasted provider API keys into the chat earlier. Never repeat them or store them in GitHub. They should rotate those provider keys when convenient because they were shared in chat.
- The Supabase publishable key is intentionally public client configuration; service-role keys and provider API keys are not.
- Food or beverage photo scans can incur AI provider charges. Do not call the scanner as a test unless the user explicitly asks for a provider request.
- Existing source HTML is prototype history. Do not overwrite or delete it; the workflow maps published demo addresses to the canonical Flutter app instead.
