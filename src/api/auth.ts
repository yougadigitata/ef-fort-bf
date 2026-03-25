import { Hono } from 'hono';
import { createClient } from '@supabase/supabase-js';
import { getDB, Env } from '../lib/db';
import {
  cleanTel, makePasswordHash, verifyPassword,
  createJWT, verifyJWT
} from '../lib/auth';

const auth = new Hono<{ Bindings: Env }>();

// Créer un user dans auth.users puis dans profiles
async function createUserWithProfile(env: Env, data: {
  nom: string;
  prenom: string;
  telephone: string;
  telClean: string;
  niveau: string;
  password: string;
  is_admin: boolean;
  abonnement_actif: boolean;
}) {
  const db = getDB(env);
  const email = `${data.telClean}@effortbf.local`;

  // 1. Créer dans auth.users via l'API Admin
  const authResponse = await fetch(`${env.SUPABASE_URL}/auth/v1/admin/users`, {
    method: 'POST',
    headers: {
      'apikey': env.SUPABASE_KEY,
      'Authorization': `Bearer ${env.SUPABASE_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      email,
      password: data.password,
      email_confirm: true,
      user_metadata: { nom: data.nom, prenom: data.prenom },
    }),
  });

  if (!authResponse.ok) {
    const errText = await authResponse.text();
    throw new Error(`Auth user creation failed: ${errText}`);
  }

  const authUser = await authResponse.json() as { id: string };
  const userId = authUser.id;

  // 2. Insérer dans profiles avec le même ID
  const passwordHash = await makePasswordHash(data.password);
  const { error: profileError } = await db.from('profiles').insert({
    id: userId,
    nom: data.nom,
    prenom: data.prenom,
    telephone: data.telephone,
    telephone_clean: data.telClean,
    niveau: data.niveau,
    password_hash: passwordHash,
    is_admin: data.is_admin,
    abonnement_actif: data.abonnement_actif,
  });

  if (profileError) {
    // Cleanup: supprimer l'utilisateur auth si le profil échoue
    await fetch(`${env.SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: 'DELETE',
      headers: {
        'apikey': env.SUPABASE_KEY,
        'Authorization': `Bearer ${env.SUPABASE_KEY}`,
      },
    });
    throw new Error(profileError.message);
  }

  return userId;
}

// ── POST /api/auth/init-admin ────────────────────────────────
auth.post('/init-admin', async (c) => {
  const body = await c.req.json().catch(() => ({})) as Record<string, unknown>;
  if (body.secret !== 'EfFortAdmin2026!BF') {
    return c.json({ error: 'Secret invalide.' }, 403);
  }
  const db = getDB(c.env);
  const telClean = '72662161';
  const password = 'EfFort@Admin2026!';
  const email = `${telClean}@effortbf.local`;

  // Vérifier si le profil existe déjà
  const { data: existing } = await db.from('profiles').select('id').eq('telephone_clean', telClean).maybeSingle();

  if (existing) {
    // Profil existant — mettre à jour password et admin
    const passwordHash = await makePasswordHash(password);
    await db.from('profiles').update({
      password_hash: passwordHash,
      is_admin: true,
      abonnement_actif: true,
    }).eq('telephone_clean', telClean);
    return c.json({
      success: true,
      message: 'Compte admin Marc mis à jour.',
      identifiants: { telephone: telClean, password },
    });
  }

  // Vérifier si l'auth user existe déjà
  const listResp = await fetch(`${c.env.SUPABASE_URL}/auth/v1/admin/users?filter=${email}`, {
    headers: {
      'apikey': c.env.SUPABASE_KEY,
      'Authorization': `Bearer ${c.env.SUPABASE_KEY}`,
    },
  });
  const listData = await listResp.json() as { users?: Array<{ id: string; email: string }> };
  const existingAuth = listData.users?.find((u) => u.email === email);

  let userId: string;

  if (existingAuth) {
    userId = existingAuth.id;
    // Mettre à jour le mot de passe
    await fetch(`${c.env.SUPABASE_URL}/auth/v1/admin/users/${userId}`, {
      method: 'PUT',
      headers: {
        'apikey': c.env.SUPABASE_KEY,
        'Authorization': `Bearer ${c.env.SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({ password }),
    });
  } else {
    // Créer l'utilisateur auth
    const authResp = await fetch(`${c.env.SUPABASE_URL}/auth/v1/admin/users`, {
      method: 'POST',
      headers: {
        'apikey': c.env.SUPABASE_KEY,
        'Authorization': `Bearer ${c.env.SUPABASE_KEY}`,
        'Content-Type': 'application/json',
      },
      body: JSON.stringify({
        email,
        password,
        email_confirm: true,
        user_metadata: { nom: 'LOMPO', prenom: 'Marc' },
      }),
    });
    const authUser = await authResp.json() as { id?: string; error?: string };
    if (!authUser.id) {
      return c.json({ error: `Auth creation failed: ${authUser.error ?? 'unknown'}` }, 500);
    }
    userId = authUser.id;
  }

  // Insérer dans profiles
  const passwordHash = await makePasswordHash(password);
  const { error } = await db.from('profiles').insert({
    id: userId,
    nom: 'LOMPO',
    prenom: 'Marc',
    telephone: '+22672662161',
    telephone_clean: telClean,
    niveau: 'MASTER',
    password_hash: passwordHash,
    is_admin: true,
    abonnement_actif: true,
  });

  if (error) return c.json({ error: error.message }, 500);

  return c.json({
    success: true,
    message: 'Compte admin Marc créé avec succès.',
    identifiants: { telephone: telClean, password },
  });
});

// ── POST /api/auth/inscription ───────────────────────────────
auth.post('/inscription', async (c) => {
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps de requête invalide.' }, 400);

  const { nom, prenom, telephone, niveau, password } = body as Record<string, string>;
  if (!nom || !prenom || !telephone || !password) {
    return c.json({ error: 'Tous les champs sont requis.' }, 400);
  }

  const telClean = cleanTel(String(telephone));
  if (telClean.length !== 8) {
    return c.json({ error: 'Numéro de téléphone invalide (8 chiffres burkinabè requis).' }, 400);
  }

  const db = getDB(c.env);

  const { data: exists } = await db
    .from('profiles').select('id').eq('telephone_clean', telClean).maybeSingle();
  if (exists) return c.json({ error: 'Ce numéro est déjà utilisé.' }, 409);

  const niveauxValides = ['CEP','BEPC','BAC','BAC+2','LICENCE','MASTER'];
  const niveauFinal = niveauxValides.includes(niveau) ? niveau : 'BAC';

  try {
    const userId = await createUserWithProfile(c.env, {
      nom: String(nom).toUpperCase().trim(),
      prenom: String(prenom).trim(),
      telephone: '+226' + telClean,
      telClean,
      niveau: niveauFinal,
      password: String(password),
      is_admin: false,
      abonnement_actif: false,
    });

    const token = await createJWT({ id: userId, is_admin: false });
    return c.json({
      success: true, token,
      user: {
        id: userId,
        nom: String(nom).toUpperCase().trim(),
        prenom: String(prenom).trim(),
        telephone: '+226' + telClean,
        niveau: niveauFinal,
        is_admin: false,
        abonnement_actif: false,
      },
    });
  } catch (err: unknown) {
    const msg = err instanceof Error ? err.message : String(err);
    // Si l'email existe déjà dans auth, c'est un doublon
    if (msg.includes('already been registered') || msg.includes('already exists')) {
      return c.json({ error: 'Ce numéro est déjà utilisé.' }, 409);
    }
    return c.json({ error: msg }, 500);
  }
});

// ── POST /api/auth/login ─────────────────────────────────────
auth.post('/login', async (c) => {
  const body = await c.req.json().catch(() => null) as Record<string, unknown> | null;
  if (!body) return c.json({ error: 'Corps de requête invalide.' }, 400);

  const { telephone, password } = body as Record<string, string>;
  if (!telephone || !password) {
    return c.json({ error: 'Téléphone et mot de passe requis.' }, 400);
  }

  const telClean = cleanTel(String(telephone));
  const db = getDB(c.env);

  const { data: user, error } = await db
    .from('profiles').select('*').eq('telephone_clean', telClean).maybeSingle();

  if (error || !user) {
    return c.json({ error: 'Numéro ou mot de passe incorrect.' }, 401);
  }

  const valid = await verifyPassword(String(password), user.password_hash);
  if (!valid) return c.json({ error: 'Numéro ou mot de passe incorrect.' }, 401);

  const token = await createJWT({ id: user.id, is_admin: user.is_admin });
  return c.json({
    success: true, token,
    user: {
      id: user.id, nom: user.nom, prenom: user.prenom,
      telephone: user.telephone, niveau: user.niveau,
      is_admin: user.is_admin, abonnement_actif: user.abonnement_actif,
    },
  });
});

// ── GET /api/auth/me ─────────────────────────────────────────
auth.get('/me', async (c) => {
  const authHeader = c.req.header('Authorization');
  if (!authHeader?.startsWith('Bearer ')) {
    return c.json({ error: 'Token requis.' }, 401);
  }
  const payload = await verifyJWT(authHeader.slice(7));
  if (!payload) return c.json({ error: 'Token invalide ou expiré.' }, 401);

  const db = getDB(c.env);
  const { data: user, error } = await db
    .from('profiles').select('*').eq('id', payload['id']).single();
  if (error || !user) return c.json({ error: 'Utilisateur introuvable.' }, 404);

  return c.json({ success: true, user });
});

export default auth;
