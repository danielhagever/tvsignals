// Tiny CORS proxy for TVSignals stock data.
// Locked to Yahoo Finance hosts so it can't be used as a generic open proxy.
const ALLOWED = /^(query[12]\.)?finance\.yahoo\.com$/;

function withCors(resp) {
  const h = new Headers(resp.headers);
  h.set('Access-Control-Allow-Origin', '*');
  h.set('Access-Control-Allow-Methods', 'GET,OPTIONS');
  h.set('Access-Control-Allow-Headers', '*');
  h.set('Cache-Control', 'public, max-age=10');
  return new Response(resp.body, { status: resp.status, headers: h });
}

export default {
  async fetch(request) {
    if (request.method === 'OPTIONS') return withCors(new Response(null, { status: 204 }));
    const target = new URL(request.url).searchParams.get('url');
    if (!target) return withCors(new Response('missing ?url=', { status: 400 }));
    let t;
    try { t = new URL(target); } catch { return withCors(new Response('bad url', { status: 400 })); }
    if (t.protocol !== 'https:' || !ALLOWED.test(t.hostname))
      return withCors(new Response('host not allowed', { status: 403 }));
    try {
      const upstream = await fetch(target, {
        headers: { 'User-Agent': 'Mozilla/5.0', 'Accept': 'application/json' },
        cf: { cacheTtl: 10, cacheEverything: true },
      });
      return withCors(new Response(await upstream.arrayBuffer(), {
        status: upstream.status,
        headers: { 'Content-Type': upstream.headers.get('Content-Type') || 'application/json' },
      }));
    } catch (e) {
      return withCors(new Response('upstream error: ' + e.message, { status: 502 }));
    }
  },
};
