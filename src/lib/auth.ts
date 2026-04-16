// ════════════════════════════════════════════════════════════
// ATTENTION : Ce code de hash est DÉFINITIF.
// Toute modification casse tous les mots de passe existants.
// ════════════════════════════════════════════════════════════

export function cleanTel(tel: string): string {
  const digits = tel.replace(/\D/g, '');
  return digits.slice(-8);
}

export async function hashPassword(password: string, sel: string): Promise<string> {
  const enc = new TextEncoder();
  const buf = await crypto.subtle.digest(
    'SHA-256',
    enc.encode(password + sel + 'EfFort2026BF')
  );
  return Array.from(new Uint8Array(buf))
    .map(b => b.toString(16).padStart(2, '0'))
    .join('');
}

export async function makePasswordHash(password: string): Promise<string> {
  const sel = crypto.randomUUID().replace(/-/g, '').slice(0, 16);
  const hash = await hashPassword(password, sel);
  return `${sel}:${hash}`;
}

export async function verifyPassword(password: string, stored: string): Promise<boolean> {
  if (!stored || !stored.includes(':')) return false;
  const idx = stored.indexOf(':');
  const sel = stored.slice(0, idx);
  const storedHash = stored.slice(idx + 1);
  const computed = await hashPassword(password, sel);
  return computed === storedHash;
}

// ── JWT ──────────────────────────────────────────────────────
// ⚠️ JWT_SECRET est lu depuis l'environnement (secret Cloudflare Workers)
// Ne jamais hardcoder ce secret ici.
const JWT_DAYS = 30;

function getJwtSecret(env?: { JWT_SECRET?: string }): string {
  // Priorité : env > variable globale (Workers) > fallback dev uniquement
  if (env?.JWT_SECRET) return env.JWT_SECRET;
  // @ts-ignore – accès variable globale Workers
  if (typeof globalThis !== 'undefined' && (globalThis as any).JWT_SECRET) {
    // @ts-ignore
    return (globalThis as any).JWT_SECRET;
  }
  // FALLBACK DEV UNIQUEMENT — ne jamais utiliser en production
  console.warn('[SECURITY] JWT_SECRET non défini — utilisation du fallback dev');
  return 'EfFort2026BF!JWT#Secure@Concours';
}

export async function createJWT(payload: Record<string, unknown>, env?: { JWT_SECRET?: string }): Promise<string> {
  const JWT_SECRET = getJwtSecret(env);
  const header = btoa(JSON.stringify({ alg: 'HS256', typ: 'JWT' }))
    .replace(/\+/g,'-').replace(/\//g,'_').replace(/=/g,'');
  const body = btoa(JSON.stringify({
    ...payload,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + JWT_DAYS * 86400,
  })).replace(/\+/g,'-').replace(/\//g,'_').replace(/=/g,'');

  const key = await crypto.subtle.importKey(
    'raw', new TextEncoder().encode(JWT_SECRET),
    { name: 'HMAC', hash: 'SHA-256' }, false, ['sign']
  );
  const sig = await crypto.subtle.sign(
    'HMAC', key, new TextEncoder().encode(`${header}.${body}`)
  );
  const sigB64 = btoa(String.fromCharCode(...new Uint8Array(sig)))
    .replace(/\+/g,'-').replace(/\//g,'_').replace(/=/g,'');
  return `${header}.${body}.${sigB64}`;
}

export async function verifyJWT(token: string, env?: { JWT_SECRET?: string }): Promise<Record<string, unknown> | null> {
  const JWT_SECRET = getJwtSecret(env);
  try {
    const [header, body, sig] = token.split('.');
    if (!header || !body || !sig) return null;
    const key = await crypto.subtle.importKey(
      'raw', new TextEncoder().encode(JWT_SECRET),
      { name: 'HMAC', hash: 'SHA-256' }, false, ['verify']
    );
    const sigPad = sig.replace(/-/g,'+').replace(/_/g,'/');
    const padding = (4 - sigPad.length % 4) % 4;
    const sigBytes = Uint8Array.from(
      atob(sigPad + '='.repeat(padding)), c => c.charCodeAt(0)
    );
    const valid = await crypto.subtle.verify(
      'HMAC', key, sigBytes, new TextEncoder().encode(`${header}.${body}`)
    );
    if (!valid) return null;
    const bodyPad = body.replace(/-/g,'+').replace(/_/g,'/');
    const bodyPadding = (4 - bodyPad.length % 4) % 4;
    const pl = JSON.parse(atob(bodyPad + '='.repeat(bodyPadding)));
    if (pl.exp < Math.floor(Date.now() / 1000)) return null;
    return pl;
  } catch {
    return null;
  }
}
