const COUNTER_KEY = "participant_count";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers });
    }

    if (url.pathname === "/join" && request.method === "POST") {
      const current = parseInt((await env.SABBATH_KV.get(COUNTER_KEY)) || "0");
      const next = current + 1;
      await env.SABBATH_KV.put(COUNTER_KEY, next.toString());
      return new Response(JSON.stringify({ count: next }), { headers });
    }

    if (url.pathname === "/count" && request.method === "GET") {
      const count = parseInt((await env.SABBATH_KV.get(COUNTER_KEY)) || "0");
      return new Response(JSON.stringify({ count }), { headers });
    }

    return new Response(JSON.stringify({ error: "not found" }), {
      status: 404,
      headers,
    });
  },
};
