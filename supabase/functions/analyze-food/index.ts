import { createClient } from "npm:@supabase/supabase-js@2.118.0";

const maxImageBytes = 5 * 1024 * 1024;
const allowedMimeTypes = new Set(["image/jpeg", "image/png", "image/webp"]);
const localOriginPattern = /^https?:\/\/(localhost|127\.0\.0\.1)(:\d+)?$/;
const systemPrompt = "Estimate the visible meal's nutrition. Return JSON only with title (string), calories_kcal (number), protein_g (number), carbs_g (number), and fats_g (number). Use one reasonable serving estimate. If the image is not clearly a food or drink, return a short title asking for a clearer meal photo and zero values. Estimates are approximate; do not give medical advice.";

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
  const openRouterKey = Deno.env.get("OPENROUTER_API_KEY");
  const geminiKeys = [Deno.env.get("GEMINI_API_KEY_1"), Deno.env.get("GEMINI_API_KEY_2")]
    .filter((key): key is string => Boolean(key));
  if (!authorization || !supabaseUrl || !publishableKey || !secretKey) {
    return json({ error: "Server authentication is not configured." }, 503, headers);
  }
  if (!openRouterKey && geminiKeys.length === 0) {
    return json({ error: "Meal scanning is not configured yet." }, 503, headers);
  }

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

    const estimate = await estimateNutrition({ imageBase64, mimeType, openRouterKey, geminiKeys });
    return json(estimate, 200, headers);
  } catch {
    return json({ error: "The nutrition estimate could not be generated. Please try again." }, 502, headers);
  }
});

async function estimateNutrition(input: {
  imageBase64: string;
  mimeType: string;
  openRouterKey?: string;
  geminiKeys: string[];
}) {
  const attempts: Array<{ name: string; run: () => Promise<unknown> }> = [];
  if (input.openRouterKey) {
    attempts.push({
      name: "OpenRouter",
      run: () => requestOpenRouter(input.openRouterKey!, input.imageBase64, input.mimeType),
    });
  }
  input.geminiKeys.forEach((key, index) => {
    attempts.push({
      name: `Gemini ${index + 1}`,
      run: () => requestGemini(key, input.imageBase64, input.mimeType),
    });
  });

  for (const attempt of attempts) {
    try {
      const result = validateEstimate(await attempt.run());
      return result;
    } catch (error) {
      const status = error instanceof ProviderRequestError ? error.status : undefined;
      console.warn(`Nutrition provider ${attempt.name} failed${status ? ` (${status})` : ""}.`);
    }
  }
  throw new Error("No configured nutrition provider returned a valid estimate.");
}

async function requestOpenRouter(apiKey: string, imageBase64: string, mimeType: string) {
  const response = await fetch("https://openrouter.ai/api/v1/chat/completions", {
    method: "POST",
    headers: { Authorization: `Bearer ${apiKey}`, "Content-Type": "application/json" },
    body: JSON.stringify({
      model: Deno.env.get("OPENROUTER_MODEL") ?? "google/gemini-3.8-flash",
      max_tokens: 300,
      temperature: 0.1,
      response_format: { type: "json_object" },
      messages: [
        { role: "system", content: systemPrompt },
        { role: "user", content: [
          { type: "text", text: "Identify this meal and estimate total nutrition for the visible serving." },
          { type: "image_url", image_url: { url: `data:${mimeType};base64,${imageBase64}`, detail: "low" } },
        ] },
      ],
    }),
  });
  if (!response.ok) throw new ProviderRequestError(response.status);
  const payload = await response.json();
  const content = payload?.choices?.[0]?.message?.content;
  if (typeof content !== "string") throw new Error("OpenRouter returned no text result.");
  return JSON.parse(content);
}

async function requestGemini(apiKey: string, imageBase64: string, mimeType: string) {
  const response = await fetch("https://generativelanguage.googleapis.com/v1beta/models/gemini-3.8-flash:generateContent", {
    method: "POST",
    headers: { "x-goog-api-key": apiKey, "Content-Type": "application/json" },
    body: JSON.stringify({
      contents: [{ parts: [
        { text: `${systemPrompt}\n\nIdentify this meal and estimate total nutrition for the visible serving.` },
        { inline_data: { mime_type: mimeType, data: imageBase64 } },
      ] }],
      generationConfig: {
        responseMimeType: "application/json",
        responseSchema: {
          type: "OBJECT",
          properties: {
            title: { type: "STRING" },
            calories_kcal: { type: "NUMBER" },
            protein_g: { type: "NUMBER" },
            carbs_g: { type: "NUMBER" },
            fats_g: { type: "NUMBER" },
          },
          required: ["title", "calories_kcal", "protein_g", "carbs_g", "fats_g"],
        },
      },
    }),
  });
  if (!response.ok) throw new ProviderRequestError(response.status);
  const payload = await response.json();
  const content = payload?.candidates?.[0]?.content?.parts
    ?.map((part: { text?: string }) => part.text ?? "").join("").trim();
  if (typeof content !== "string" || !content) throw new Error("Gemini returned no text result.");
  return JSON.parse(content);
}

function validateEstimate(result: unknown) {
  if (!result || typeof result !== "object") throw new Error("Invalid estimate.");
  const value = result as Record<string, unknown>;
  const title = typeof value.title === "string" ? value.title.trim().slice(0, 180) : "";
  const calories = Number(value.calories_kcal);
  const protein = Number(value.protein_g);
  const carbs = Number(value.carbs_g);
  const fats = Number(value.fats_g);
  if (!title || !Number.isFinite(calories) || !Number.isFinite(protein) || !Number.isFinite(carbs) || !Number.isFinite(fats) || calories < 0 || calories > 20000 || protein < 0 || protein > 2000 || carbs < 0 || carbs > 3000 || fats < 0 || fats > 1000) {
    throw new Error("Nutrition estimate was outside the supported range.");
  }
  return { title, calories_kcal: calories, protein_g: protein, carbs_g: carbs, fats_g: fats };
}

class ProviderRequestError extends Error {
  constructor(readonly status: number) {
    super("Nutrition provider request failed.");
  }
}

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
