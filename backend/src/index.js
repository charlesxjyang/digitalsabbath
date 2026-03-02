const COUNTER_KEY = "participant_count";

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const headers = {
      "Content-Type": "application/json",
      "Access-Control-Allow-Origin": "*",
      "Access-Control-Allow-Methods": "GET, POST, OPTIONS",
      "Access-Control-Allow-Headers": "Content-Type",
    };

    if (request.method === "OPTIONS") {
      return new Response(null, { headers });
    }

    if (url.pathname === "/join" && request.method === "POST") {
      let body = {};
      try { body = await request.json(); } catch {}
      const deviceId = body.device_id;
      const phoneHash = body.phone_hash;

      if (deviceId) {
        const existing = await env.SABBATH_KV.get(`device:${deviceId}`);
        if (existing) {
          if (phoneHash) {
            await env.SABBATH_KV.put(`phone:${phoneHash}`, deviceId);
          }
          const count = parseInt((await env.SABBATH_KV.get(COUNTER_KEY)) || "0");
          return new Response(JSON.stringify({ count, duplicate: true }), { headers });
        }
        await env.SABBATH_KV.put(`device:${deviceId}`, "1");
      }

      if (phoneHash) {
        await env.SABBATH_KV.put(`phone:${phoneHash}`, deviceId || "anonymous");
      }

      const current = parseInt((await env.SABBATH_KV.get(COUNTER_KEY)) || "0");
      const next = current + 1;
      await env.SABBATH_KV.put(COUNTER_KEY, next.toString());
      return new Response(JSON.stringify({ count: next }), { headers });
    }

    if (url.pathname === "/match" && request.method === "POST") {
      let body = {};
      try { body = await request.json(); } catch {}
      const contactHashes = body.contact_hashes;
      if (!Array.isArray(contactHashes)) {
        return new Response(JSON.stringify({ error: "contact_hashes must be an array" }), {
          status: 400,
          headers,
        });
      }

      const results = await Promise.all(
        contactHashes.map((hash) => env.SABBATH_KV.get(`phone:${hash}`))
      );
      const matchedHashes = contactHashes.filter((_, i) => results[i] !== null);

      return new Response(
        JSON.stringify({ matched_hashes: matchedHashes, match_count: matchedHashes.length }),
        { headers }
      );
    }

    if (url.pathname === "/count" && request.method === "GET") {
      const count = parseInt((await env.SABBATH_KV.get(COUNTER_KEY)) || "0");
      return new Response(JSON.stringify({ count }), { headers });
    }

    if (url.pathname === "/config" && request.method === "GET") {
      const discord = (await env.SABBATH_KV.get("config:discord_url")) || "";
      const share_url = (await env.SABBATH_KV.get("config:share_url")) || "https://digitalsabbath.app";
      const message = (await env.SABBATH_KV.get("config:message")) || "";
      return new Response(JSON.stringify({ discord_url: discord, share_url: share_url, message }), { headers });
    }

    return new Response(JSON.stringify({ error: "not found" }), {
      status: 404,
      headers,
    });
  },
};
