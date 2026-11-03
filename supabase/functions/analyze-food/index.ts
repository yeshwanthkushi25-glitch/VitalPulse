import { createClient } from "npm:@supabase/supabase-js@2.118.0";

const maxImageBytes = 5 * 1024 * 1024;
const allowedMimeTypes = new Set(["image/jpeg", "image/png", "image/webp"]);
const localOriginPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;

Deno.serve(async (request: Request) => {
  const origin = request.headers.get("Origin") ?? "";
  const allowedOrigins = (Deno.env.get("ALLOWED_ORIGINS") ?? "")
    .split(",").map((value) => value.trim()).filter(Boolean);
  const originAllowed = !origin || allowedOrigins.includes(origin) || localOriginPattern.test(origin);
  if (!originAllowed) return json({ error: "Origin is not allowed." }, 403);
  const headers = origin ? { "Access-Control-Allow-Origin": origin, "Vary": "Origin" } : {};
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: { ...headers, "Access-Control-Allow-Headers": "authorization, apikey, content-type, x-client-info", "Access-Control-Allow-Methods": "POST, OPTIONS" } });
  }
  if (request.method !== "POST") return json({ error: "Method not allowed." }, 405, headers);
  const contentLength = Number(request.headers.get("Content-Length") ?? "0");
  if (contentLength > 7 * 1024 * 1024) return json({ error: "Choose an image smaller than 5 MB." }, 413, headers);

  const authorization = request.headers.get("Authorization");
  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const publishableKey = defaultKey("SUPABASE_PUBLISHABLE_KEYS") ?? Deno.env.get("SUPABASE_ANON_KEY");
  const secretKey = defaultKey("SUPABASE_SECRET_KEYS") ?? Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  const openAiKey = Deno.env.get("OPENAI_API_KEY");
  if (!authorization || !supabaseUrl || !publishableKey || !secretKey) return json({ error: "Server authentication is not configured." }, 503, headers);
  if (!openAiKey) return json({ error: "Meal scanning is not configured yet." }, 503, headers);

  try {
    const authClient = createClient(supabaseUrl, publishableKey, { global: { headers: { Authorization: authorization } }, auth: { persistSession: false, autoRefreshToken: false } });
    const { data: { user }, error: authError } = await authClient.auth.getUser();
    if (authError || !user) return json({ error: "Sign in to scan a meal." }, 401, headers);

    const body = await request.json();
    const imageBase64 = body?.image_base64;
    const mimeType = body?.mime_type;
    if (typeof imageBase64 !== "string" || imageBase64.length % 4 !== 0 || !/^[A-Za-z0-9+/]+={0,2}$/.test(imageBase64) || typeof mimeType !== "string" || !allowedMimeTypes.has(mimeType)) {
      return json({ error: "Provide a JPEG, PNG, or WebP image." }, 400, headers);
    }
    if (Math.floor(imageBase64.length * 3 / 4) > maxImageBytes) return json({ error: "Choose an image smaller than 5 MB." }, 413, headers);

    const admin = createClient(supabaseUrl, secretKey, { auth: { persistSession: false, autoRefreshToken: false } });
    const { data: slotAllowed, error: limitError } = await admin.rpc("take_food_scan_slot", { p_user_id: user.id });
    if (limitError) {
      console.error("Food scan rate limit check failed.");
      return json({ error: "Meal scanning is temporarily unavailable." }, 503, headers);
    }
    if (slotAllowed !== true) return json({ error: "Daily photo scan limit reached. Try again tomorrow." }, 429, headers);

    const aiResponse = await fetch("https://api.openai.com/v1/chat/completions", {
      method: "POST",
      headers: { Authorization: `Bearer ${openAiKey}`, "Content-Type": "application/json" },
      body: JSON.stringify({
        model: Deno.env.get("OPENAI_MODEL") ?? "gpt-4o-mini",
        max_tokens: 300,
        response_format: { type: "json_object" },
        messages: [
          { role: "system", content: "Estimate the visible meal's nutrition. Return JSON only with title (string), calories_kcal (number), protein_g (number), carbs_g (number), and fats_g (number). Use one reasonable serving estimate. If the image is not clearly a food or drink, return a short title asking for a clearer meal photo and zero values. Estimates are approximate; do not give medical advice." },
          { role: "user", content: [{ type: "text", text: "Identify this meal and estimate total nutrition for the visible serving." }, { type: "image_url", image_url: { url: `data:${mimeType};base64,${imageBase64}`, detail: "low" } }] },
        ],
      }),
    });
    if (!aiResponse.ok) {
      console.error("Nutrition model request failed with status", aiResponse.status);
      return json({ error: "The nutrition estimate could not be generated." }, 502, headers);
    }
    const payload = await aiResponse.json();
    const content = payload?.choices?.[0]?.message?.content;
    if (typeof content !== "string") return json({ error: "The nutrition estimate was incomplete." }, 502, headers);
    const result = JSON.parse(content);
    const title = typeof result.title === "string" ? result.title.trim().slice(0, 180) : "";
    const calories = Number(result.calories_kcal), protein = Number(result.protein_g), carbs = Number(result.carbs_g), fats = Number(result.fats_g);
    if (!title || !Number.isFinite(calories) || !Number.isFinite(protein) || !Number.isFinite(carbs) || !Number.isFinite(fats) || calories < 0 || calories > 20000 || protein < 0 || protein > 2000 || carbs < 0 || carbs > 3000 || fats < 0 || fats > 1000) {
      return json({ error: "The nutrition estimate was outside the supported range." }, 502, headers);
    }
    return json({ title, calories_kcal: calories, protein_g: protein, carbs_g: carbs, fats_g: fats }, 200, headers);
  } catch {
    return json({ error: "The meal photo could not be analyzed." }, 400, headers);
  }
});

function json(body: Record<string, unknown>, status: number, extraHeaders: Record<string, string> = {}) {
  return new Response(JSON.stringify(body), { status, headers: { ...extraHeaders, "Content-Type": "application/json", "Cache-Control": "no-store" } });
}

function defaultKey(variable: string): string | undefined {
  const raw = Deno.env.get(variable);
  if (!raw) return undefined;
  try {
    const keys = JSON.parse(raw) as Record<string, string>;
    return keys.default ?? Object.values(keys)[0];
  } catch {
    return undefined;
  }
}
