// ══════════════════════════════════════════════════════════════
// ENTRAIDE v6.1 — Questions/Réponses avec réponses admin
// ⚡ SANS migration SQL: 
//   - partage_whatsapp=true + contenu=JSON {"_rep":true,"_pid":"uuid","texte":"msg"}
// Utilisateurs : 1 question/statut par jour max
// Admin : peut répondre à toutes les questions, sans limite
// ══════════════════════════════════════════════════════════════
import { Hono } from 'hono';
import { getDB, Env } from '../lib/db';
import { verifyJWT } from '../lib/auth';

const entraide = new Hono<{ Bindings: Env }>();

async function requireAuth(c: any, next: any) {
  const h = c.req.header('Authorization');
  if (!h?.startsWith('Bearer ')) return c.json({ error: 'Auth requise.' }, 401);
  const p = await verifyJWT(h.slice(7));
  if (!p) return c.json({ error: 'Token invalide.' }, 401);
  const context = c as any;
  context.userId = (p as any).id as string;
  context.isAdmin = (p as any).is_admin === true;
  await next();
}

// Décode un message (question normale ou réponse admin)
function decodeMessage(m: any): { isReponse: boolean; parentId: string | null; texte: string } {
  if (m.partage_whatsapp !== true) {
    return { isReponse: false, parentId: null, texte: m.contenu ?? '' };
  }
  // Essayer de décoder comme JSON réponse admin
  try {
    const parsed = JSON.parse(m.contenu);
    if (parsed._rep === true && parsed._pid) {
      return { isReponse: true, parentId: parsed._pid, texte: parsed.texte ?? '' };
    }
  } catch (_) {}
  // partage_whatsapp=true mais pas format JSON → message normal (ancienne entraide)
  return { isReponse: false, parentId: null, texte: m.contenu ?? '' };
}

// ── GET /api/entraide — Messages récents avec réponses ──────────
entraide.get('/', requireAuth, async (c) => {
  const db = getDB(c.env);

  // Récupérer TOUS les messages actifs
  const { data: allMessages, error } = await db
    .from('messages_entraide')
    .select('id, contenu, partage_whatsapp, telephone_partage, created_at, user_id, actif')
    .eq('actif', true)
    .order('created_at', { ascending: false })
    .limit(300);

  if (error) return c.json({ error: error.message }, 500);

  // Séparer questions et réponses admin
  const questions: any[] = [];
  const reponsesByParent: Record<string, any[]> = {};

  for (const m of (allMessages ?? [])) {
    const decoded = decodeMessage(m);
    if (decoded.isReponse && decoded.parentId) {
      if (!reponsesByParent[decoded.parentId]) reponsesByParent[decoded.parentId] = [];
      reponsesByParent[decoded.parentId].push({ ...m, _texte: decoded.texte, _parentId: decoded.parentId });
    } else {
      questions.push(m);
    }
  }

  // Enrichir avec les profils
  const enriched = [];
  for (const m of questions) {
    const { data: profile } = await db.from('profiles')
      .select('nom, prenom, is_admin')
      .eq('id', m.user_id).single();

    const rawReponses = reponsesByParent[m.id] ?? [];
    const reponses: any[] = [];
    for (const r of rawReponses.sort((a: any, b: any) =>
      new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    )) {
      const { data: repProfile } = await db.from('profiles')
        .select('nom, prenom, is_admin')
        .eq('id', r.user_id).single();
      reponses.push({
        id: r.id,
        contenu: r._texte,
        created_at: r.created_at,
        user_id: r.user_id,
        prenom: repProfile?.prenom ?? 'Admin',
        nom: repProfile?.nom ?? '',
        is_admin: repProfile?.is_admin ?? true,
      });
    }

    enriched.push({
      id: m.id,
      contenu: m.contenu,
      created_at: m.created_at,
      user_id: m.user_id,
      actif: m.actif,
      parent_id: null,
      prenom: profile?.prenom ?? 'Utilisateur',
      nom: profile?.nom ?? '',
      is_admin: profile?.is_admin ?? false,
      reponses,
    });
  }

  return c.json({ success: true, messages: enriched });
});

// ── POST /api/entraide — Publier un message/question ────────────
entraide.post('/', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const isAdmin = context.isAdmin as boolean;
  const body = await c.req.json().catch(() => ({}));
  const { contenu } = body;

  if (!contenu || String(contenu).trim().length < 3) {
    return c.json({ error: 'Message trop court (minimum 3 caractères).' }, 400);
  }

  const db = getDB(c.env);
  const { data: profile } = await db.from('profiles')
    .select('is_admin').eq('id', userId).single();
  const userIsAdmin = isAdmin || profile?.is_admin === true;

  if (!userIsAdmin) {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { data: existing } = await db
      .from('messages_entraide')
      .select('id')
      .eq('user_id', userId)
      .eq('actif', true)
      .eq('partage_whatsapp', false)
      .gte('created_at', cutoff)
      .limit(1);

    if (existing && existing.length > 0) {
      return c.json({
        error: 'Vous avez déjà posté votre statut aujourd\'hui. Revenez demain !',
        already_posted: true
      }, 429);
    }
  }

  const { error } = await db.from('messages_entraide').insert({
    user_id: userId,
    contenu: String(contenu).trim().slice(0, 500),
    partage_whatsapp: false,
    telephone_partage: null,
    actif: true,
  });

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({ success: true, message: 'Message publié !' });
});

// ── POST /api/entraide/:id/repondre — Admin répond à un message ──
// ⚡ v6.1: contenu = JSON {"_rep":true,"_pid":"uuid-parent","texte":"réponse"}
// partage_whatsapp = true pour identifier les réponses
entraide.post('/:id/repondre', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const isAdmin = context.isAdmin as boolean;
  const parentId = c.req.param('id');
  const body = await c.req.json().catch(() => ({}));
  const { contenu } = body;

  if (!contenu || String(contenu).trim().length < 1) {
    return c.json({ error: 'La réponse ne peut pas être vide.' }, 400);
  }

  const db = getDB(c.env);
  const { data: profile } = await db.from('profiles')
    .select('is_admin').eq('id', userId).single();

  const userIsAdmin = isAdmin || profile?.is_admin === true;
  if (!userIsAdmin) {
    return c.json({ error: 'Seul l\'administrateur peut répondre aux messages.' }, 403);
  }

  // Vérifier que le message parent existe
  const { data: parent } = await db
    .from('messages_entraide')
    .select('id')
    .eq('id', parentId)
    .eq('actif', true)
    .single();

  if (!parent) {
    return c.json({ error: 'Message introuvable.' }, 404);
  }

  // ⚡ Encoder la réponse comme JSON dans contenu
  const reponseJson = JSON.stringify({
    _rep: true,
    _pid: parentId,
    texte: String(contenu).trim().slice(0, 1000),
  });

  const { error } = await db.from('messages_entraide').insert({
    user_id: userId,
    contenu: reponseJson,
    partage_whatsapp: true,   // true = réponse admin
    telephone_partage: null,
    actif: true,
  });

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({ success: true, message: 'Réponse publiée !' });
});

// ── DELETE /api/entraide/:id — Supprimer message ──────────────────
entraide.delete('/:id', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const isAdmin = context.isAdmin as boolean;
  const id = c.req.param('id');
  const db = getDB(c.env);

  const { data: profile } = await db.from('profiles')
    .select('is_admin').eq('id', userId).single();
  const userIsAdmin = isAdmin || profile?.is_admin === true;

  if (userIsAdmin) {
    await db.from('messages_entraide').update({ actif: false }).eq('id', id);
    // Supprimer aussi les réponses (contenu JSON contient _pid = id)
    // Note: PostgREST ne supporte pas les requêtes JSON, on ne peut pas filtrer par _pid dans contenu
    // Les réponses restent mais seront orphelines (pas visibles car parent supprimé)
  } else {
    await db.from('messages_entraide')
      .update({ actif: false })
      .eq('id', id)
      .eq('user_id', userId);
  }
  return c.json({ success: true });
});

// ── GET /api/entraide/migration-sql — Info migration ──
entraide.get('/migration-sql', async (c) => {
  return c.json({
    success: true,
    note: 'Entraide v6.1 fonctionne sans migration SQL. Les réponses admin sont encodées en JSON dans le champ contenu.',
    version: '6.1',
  });
});

export default entraide;
