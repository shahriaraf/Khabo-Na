// Tiny proxy: keeps your Anthropic key on the server. Needs Node 18+. No dependencies.
import http from 'node:http';
const { ANTHROPIC_API_KEY, APP_TOKEN, PORT = 8787 } = process.env;
if (!ANTHROPIC_API_KEY || !APP_TOKEN) { console.error('Set ANTHROPIC_API_KEY and APP_TOKEN'); process.exit(1); }
const PROMPT = 'List every food item in this photo. Include likely cooking oil or sauce as its own item. Reply ONLY with JSON: {"items":[{"name":"","grams":0,"kcal_per_100g":0,"sugar_per_100g":0}]}. Use cooked weights and standard nutrition values.';
const hits = new Map();

http.createServer(async (req, res) => {
  const send = (c, o) => { res.writeHead(c, { 'content-type': 'application/json' }); res.end(JSON.stringify(o)); };
  if (req.method !== 'POST' || req.url !== '/analyze') return send(404, { error: 'not found' });
  if (req.headers['x-app-token'] !== APP_TOKEN) return send(401, { error: 'unauthorized' });
  const ip = (req.headers['x-forwarded-for'] || req.socket.remoteAddress || '').split(',')[0].trim(), now = Date.now();
  const recent = (hits.get(ip) || []).filter((t) => now - t < 3600e3);
  if (recent.length >= 30) return send(429, { error: 'too many requests' }); // 30 photos per hour per IP
  hits.set(ip, [...recent, now]);
  let body = '', size = 0;
  for await (const ch of req) { size += ch.length; if (size > 6e6) return send(413, { error: 'too large' }); body += ch; }
  try {
    const { image } = JSON.parse(body);
    const r = await fetch('https://api.anthropic.com/v1/messages', {
      method: 'POST',
      headers: { 'x-api-key': ANTHROPIC_API_KEY, 'anthropic-version': '2023-06-01', 'content-type': 'application/json' },
      body: JSON.stringify({ model: 'claude-sonnet-5-5', max_tokens: 800, messages: [{ role: 'user', content: [
        { type: 'image', source: { type: 'base64', media_type: 'image/jpeg', data: image } }, { type: 'text', text: PROMPT }] }] }),
    });
    const t = (await r.json()).content[0].text;
    send(200, JSON.parse(t.slice(t.indexOf('{'), t.lastIndexOf('}') + 1)));
  } catch { send(502, { error: 'analysis failed' }); }
}).listen(PORT, () => console.log('Listening on ' + PORT));
