// Worko · ИИ-проверка закрытого наряда через Claude
//
// Деплой:
//   1. Установить Supabase CLI:  npm i -g supabase
//   2. supabase login
//   3. supabase link --project-ref ldjpzjscxothrgmdnlnl
//   4. supabase secrets set ANTHROPIC_API_KEY=sk-ant-...
//   5. supabase functions deploy ai-review --no-verify-jwt
//
// Ключ Anthropic хранится в секретах Supabase и в браузер не попадает.

const CORS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: CORS });

  try {
    const o = await req.json();
    const key = Deno.env.get("ANTHROPIC_API_KEY");
    if (!key) throw new Error("ANTHROPIC_API_KEY не задан");

    const mats = (o.materials || [])
      .map((m: any) => `${m.name} — ${m.qty} ${m.unit} (обычный расход ${m.norm})`)
      .join("; ") || "не списаны";

    const prompt = `Ты — контролёр качества ремонтных работ на обогатительной фабрике.
Проверь закрытый наряд и вынеси вердикт.

ЗАЯВЛЕННАЯ ПРОБЛЕМА: ${o.problem}
ОБОРУДОВАНИЕ: ${o.equipment}, участок ${o.site}
ВЫПОЛНЕННЫЕ РАБОТЫ: ${o.works}
ШИФР НЕИСПРАВНОСТИ: ${o.code} (норматив ${o.normMin} мин)
ФАКТИЧЕСКОЕ ВРЕМЯ: ${o.spentMin} мин
СПИСАННЫЕ МАТЕРИАЛЫ: ${mats}
ФОТО «ПОСЛЕ»: ${o.hasPhoto ? "приложено" : "отсутствует"}

Оцени по пяти пунктам:
1. Полнота закрытия — заполнены ли работы, шифр, материалы, фото
2. Соответствие работ проблеме — устраняют ли описанные работы заявленную неисправность
3. Логичность материалов — соответствует ли расход типу работ, нет ли завышения
4. Время — факт против норматива
5. Качество по фото — приложено ли фото «после»

Верни СТРОГО JSON без markdown и пояснений:
{"verdict":"ok|warn|rework","score":1-5,"explanation":"одно-два предложения по-русски, по делу, без воды","checks":[{"ok":true,"title":"краткое название","note":"что именно проверено"}]}

verdict: ok — всё в порядке, warn — принято с замечаниями, rework — требует доработки.`;

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "x-api-key": key,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: "claude-sonnet-4-6",
        max_tokens: 900,
        messages: [{ role: "user", content: prompt }],
      }),
    });

    if (!res.ok) throw new Error("Anthropic " + res.status + ": " + (await res.text()));

    const data = await res.json();
    const text = (data.content || []).map((c: any) => c.text || "").join("");
    const clean = text.replace(/```json|```/g, "").trim();
    const parsed = JSON.parse(clean);

    return new Response(JSON.stringify(parsed), {
      headers: { ...CORS, "content-type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), {
      status: 500,
      headers: { ...CORS, "content-type": "application/json" },
    });
  }
});
