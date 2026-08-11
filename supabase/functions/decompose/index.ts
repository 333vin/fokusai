// FokusAI — decompose: turns one task into tiny, physical microtasks via Claude.
// The Anthropic key never leaves this function.

const ANTHROPIC_API_KEY = Deno.env.get("ANTHROPIC_API_KEY")!;
const MODEL = "claude-haiku-4-5";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
};

const SYSTEM = `You break a teenager's task into 4-6 microtasks for an anti-procrastination app.

HARD RULES:
- The FIRST step is the smallest possible physical action (<=2 min, near-zero effort): "open the doc", "put the reading in front of you". Starting is the whole battle.
- EVERY step is a concrete, observable physical action with a clear finish line. NEVER "understand", "review", "study", "learn", "think about", "brainstorm" — convert those to an output (write one sentence, answer one question, say it aloud, solve one problem).
- Each step is 2-5 minutes.
- Warm, plain, teen-appropriate voice. A little encouraging. Never condescending, never shaming. "Wrong answers totally allowed" energy.

Examples of the vibe:
- "Open a doc and give it any title." (2)
- "Write one ugly sentence about the topic." (3)
- "Attempt problem 1. Wrong answers totally allowed." (5)

Respond with ONLY valid JSON, no markdown fences:
{"task_type":"structured_deliverable|problem_set|reading_review|test_study|open_project|admin","microtasks":[{"order":1,"text":"...","estimated_minutes":3}]}`;

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: cors });

  try {
    const body = await req.json();
    const title = body?.task?.title?.trim();
    if (!title) {
      return new Response(JSON.stringify({ error: "task.title required" }), {
        status: 400, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const ctx = body?.task?.context ?? {};
    const multiplier = body?.personalization?.estimate_multiplier ?? 1.0;

    const userMsg = [
      `TITLE: ${title}`,
      ctx.format ? `FORMAT: ${ctx.format}` : null,
      ctx.deadline ? `DEADLINE: ${ctx.deadline}` : null,
      ctx.scope ? `SCOPE: ${ctx.scope}` : null,
      ctx.time_available_now_minutes ? `TIME NOW: ${ctx.time_available_now_minutes} min` : null,
      `\nThis student runs about ${multiplier}x longer than estimates. Size accordingly.`,
    ].filter(Boolean).join("\n");

    const res = await fetch("https://api.anthropic.com/v1/messages", {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        "x-api-key": ANTHROPIC_API_KEY,
        "anthropic-version": "2023-06-01",
      },
      body: JSON.stringify({
        model: MODEL,
        max_tokens: 1200,
        system: [{ type: "text", text: SYSTEM, cache_control: { type: "ephemeral" } }],
        messages: [{ role: "user", content: userMsg }],
      }),
    });

    if (!res.ok) {
      console.error("anthropic", res.status, await res.text());
      return new Response(JSON.stringify({ error: "decomposition_failed" }), {
        status: 502, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    const data = await res.json();
    const raw = (data.content?.map((c: any) => c.text ?? "").join("") ?? "").trim();
    const cleaned = raw.replace(/```json/g, "").replace(/```/g, "").trim();

    let parsed;
    try { parsed = JSON.parse(cleaned); }
    catch {
      console.error("bad json", raw);
      return new Response(JSON.stringify({ error: "bad_model_output" }), {
        status: 502, headers: { ...cors, "Content-Type": "application/json" },
      });
    }

    parsed.microtasks = (parsed.microtasks ?? []).map((m: any, i: number) => ({
      order: m.order ?? i + 1,
      text: String(m.text ?? "").slice(0, 300),
      estimated_minutes: Math.max(1, Math.round((m.estimated_minutes ?? 3) * multiplier)),
    }));

    return new Response(JSON.stringify(parsed), {
      headers: { ...cors, "Content-Type": "application/json" },
    });
  } catch (e) {
    console.error(e);
    return new Response(JSON.stringify({ error: "unexpected" }), {
      status: 500, headers: { ...cors, "Content-Type": "application/json" },
    });
  }
});