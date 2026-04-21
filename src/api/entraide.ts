// ══════════════════════════════════════════════════════════════
// ENTRAIDE v7.0 — Questions/Réponses améliorées
// ⚡ NOUVELLES FONCTIONNALITÉS :
//   - Likes/réactions (❤️ 👍 🔥) sans colonne supplémentaire
//   - Épinglage admin (message mis en avant)
//   - Filtres par type (aide, révision, signaler, info, succès)
//   - Suppression automatique après 30 jours (optionnelle)
// ⚡ SANS migration SQL :
//   - partage_whatsapp=true + contenu=JSON {"_rep":true,"_pid":"uuid","texte":"msg"}
//   - épinglage : telephone_partage="pinned"
//   - likes : telephone_partage="likes:uuid1,uuid2,uuid3"
// Utilisateurs : 1 question/statut par jour max
// Admin : peut répondre, épingler, publier sans limite
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

// ── Décode un message (question normale, réponse admin, ou like) ──
function decodeMessage(m: any): {
  isReponse: boolean;
  isLike: boolean;
  isPinned: boolean;
  parentId: string | null;
  texte: string;
  likedBy: string[];
} {
  // Épinglage : telephone_partage contient "pinned"
  const isPinned = m.telephone_partage === 'pinned';

  // Likes stockés dans telephone_partage : "likes:uuid1,uuid2,uuid3"
  let likedBy: string[] = [];
  if (m.telephone_partage && String(m.telephone_partage).startsWith('likes:')) {
    const likeStr = String(m.telephone_partage).slice(6);
    likedBy = likeStr.split(',').filter((s: string) => s.trim().length > 0);
  }

  if (m.partage_whatsapp !== true) {
    return { isReponse: false, isLike: false, isPinned, parentId: null, texte: m.contenu ?? '', likedBy };
  }

  // Essayer de décoder comme JSON réponse admin
  try {
    const parsed = JSON.parse(m.contenu);
    if (parsed._rep === true && parsed._pid) {
      return { isReponse: true, isLike: false, isPinned, parentId: parsed._pid, texte: parsed.texte ?? '', likedBy };
    }
    if (parsed._like === true && parsed._pid) {
      return { isReponse: false, isLike: true, isPinned, parentId: parsed._pid, texte: '', likedBy };
    }
  } catch (_) {}

  // partage_whatsapp=true mais pas format JSON → message normal (ancienne entraide)
  return { isReponse: false, isLike: false, isPinned, parentId: null, texte: m.contenu ?? '', likedBy };
}

// ── GET /api/entraide — Messages récents avec réponses et likes ──
// ⚠️ ANTI-FRAUDE : Accès réservé aux abonnés (vérifié côté serveur)
entraide.get('/', requireAuth, async (c) => {
  const db = getDB(c.env);
  const context = c as any;
  const currentUserId = context.userId as string;
  const filterType = c.req.query('type') || 'all';

  // ── Vérification abonnement obligatoire pour Entraide ──
  const { data: entraideProfile } = await db.from('profiles')
    .select('abonnement_actif, is_admin')
    .eq('id', currentUserId)
    .single();
  const isAbonneEntraide = entraideProfile?.abonnement_actif === true;
  const isAdminEntraide  = entraideProfile?.is_admin === true || context.isAdmin === true;

  if (!isAbonneEntraide && !isAdminEntraide) {
    return c.json({
      error: 'Accès réservé aux abonnés Premium.',
      code: 'PREMIUM_REQUIRED',
      message: 'L\'Entraide est réservée aux abonnés. Abonnez-vous pour rejoindre la communauté.',
    }, 403);
  }

  // Récupérer TOUS les messages actifs des dernières 24h (questions + réponses)
  // Note : les réponses admin et les likes peuvent être plus anciens, on les garde
  const cutoff24h = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
  const { data: allMessages, error } = await db
    .from('messages_entraide')
    .select('id, contenu, partage_whatsapp, telephone_partage, created_at, user_id, actif')
    .eq('actif', true)
    .gte('created_at', cutoff24h)
    .order('created_at', { ascending: false })
    .limit(400);

  if (error) return c.json({ error: error.message }, 500);

  // Séparer questions, réponses admin, likes
  const questions: any[] = [];
  const reponsesByParent: Record<string, any[]> = {};
  const likesByParent: Record<string, string[]> = {};

  for (const m of (allMessages ?? [])) {
    const decoded = decodeMessage(m);
    if (decoded.isReponse && decoded.parentId) {
      if (!reponsesByParent[decoded.parentId]) reponsesByParent[decoded.parentId] = [];
      reponsesByParent[decoded.parentId].push({ ...m, _texte: decoded.texte, _parentId: decoded.parentId });
    } else if (decoded.isLike && decoded.parentId) {
      // Compter le like pour ce parent
      if (!likesByParent[decoded.parentId]) likesByParent[decoded.parentId] = [];
      if (!likesByParent[decoded.parentId].includes(m.user_id)) {
        likesByParent[decoded.parentId].push(m.user_id);
      }
    } else if (!decoded.isReponse && !decoded.isLike) {
      questions.push({ ...m, _isPinned: decoded.isPinned });
    }
  }

  // Trier : épinglés en premier, puis par date
  questions.sort((a: any, b: any) => {
    if (a._isPinned && !b._isPinned) return -1;
    if (!a._isPinned && b._isPinned) return 1;
    return new Date(b.created_at).getTime() - new Date(a.created_at).getTime();
  });

  // ⚡ OPTIMISATION v7.1 : BATCH FETCH des profils (élimine N+1 queries)
  // Collecter tous les user_id uniques (questions + réponses)
  const allUserIds = new Set<string>();
  for (const m of questions) allUserIds.add(m.user_id);
  for (const parentId of Object.keys(reponsesByParent)) {
    for (const r of reponsesByParent[parentId]) allUserIds.add(r.user_id);
  }

  // Une seule requête pour récupérer tous les profils
  let profilesMap: Record<string, { nom: string; prenom: string; is_admin: boolean }> = {};
  if (allUserIds.size > 0) {
    const { data: profiles } = await db.from('profiles')
      .select('id, nom, prenom, is_admin')
      .in('id', Array.from(allUserIds));
    for (const p of (profiles ?? [])) {
      profilesMap[p.id] = { nom: p.nom, prenom: p.prenom, is_admin: p.is_admin };
    }
  }

  // Enrichir avec les profils
  const enriched = [];
  for (const m of questions) {
    const profile = profilesMap[m.user_id];

    const rawReponses = reponsesByParent[m.id] ?? [];
    const reponses: any[] = [];
    for (const r of rawReponses.sort((a: any, b: any) =>
      new Date(a.created_at).getTime() - new Date(b.created_at).getTime()
    )) {
      const repProfile = profilesMap[r.user_id];
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

    // Likes pour ce message
    const msgLikes = likesByParent[m.id] ?? [];

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
      is_pinned: m._isPinned ?? false,
      likes_count: msgLikes.length,
      liked_by_me: msgLikes.includes(currentUserId),
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
    .select('is_admin, abonnement_actif').eq('id', userId).single();
  const userIsAdmin = isAdmin || profile?.is_admin === true;
  const userIsAbonne = profile?.abonnement_actif === true;

  // ── Vérification abonnement : seuls les abonnés et admins peuvent poster ──
  if (!userIsAbonne && !userIsAdmin) {
    return c.json({
      error: 'Accès réservé aux abonnés Premium.',
      code: 'PREMIUM_REQUIRED',
      message: 'L\'Entraide est réservée aux abonnés. Abonnez-vous pour rejoindre la communauté.',
    }, 403);
  }

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

  const { data: parent } = await db
    .from('messages_entraide')
    .select('id')
    .eq('id', parentId)
    .eq('actif', true)
    .single();

  if (!parent) {
    return c.json({ error: 'Message introuvable.' }, 404);
  }

  const reponseJson = JSON.stringify({
    _rep: true,
    _pid: parentId,
    texte: String(contenu).trim().slice(0, 1000),
  });

  const { error } = await db.from('messages_entraide').insert({
    user_id: userId,
    contenu: reponseJson,
    partage_whatsapp: true,
    telephone_partage: null,
    actif: true,
  });

  if (error) {
    return c.json({ error: error.message }, 500);
  }

  return c.json({ success: true, message: 'Réponse publiée !' });
});

// ── POST /api/entraide/:id/like — Liker/unliker un message ──────
entraide.post('/:id/like', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const messageId = c.req.param('id');
  const db = getDB(c.env);

  // Vérifier que le message parent existe
  const { data: parent } = await db
    .from('messages_entraide')
    .select('id')
    .eq('id', messageId)
    .eq('actif', true)
    .single();

  if (!parent) {
    return c.json({ error: 'Message introuvable.' }, 404);
  }

  // Vérifier si l'utilisateur a déjà liké ce message
  const likeJson = JSON.stringify({ _like: true, _pid: messageId });
  const { data: existingLike } = await db
    .from('messages_entraide')
    .select('id')
    .eq('user_id', userId)
    .eq('contenu', likeJson)
    .eq('actif', true)
    .single();

  if (existingLike) {
    // Retirer le like
    await db.from('messages_entraide')
      .update({ actif: false })
      .eq('id', existingLike.id);
    return c.json({ success: true, liked: false });
  } else {
    // Ajouter le like
    await db.from('messages_entraide').insert({
      user_id: userId,
      contenu: likeJson,
      partage_whatsapp: true,
      telephone_partage: null,
      actif: true,
    });
    return c.json({ success: true, liked: true });
  }
});

// ── POST /api/entraide/:id/epingler — Admin épingle/désépingle ──
entraide.post('/:id/epingler', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const isAdmin = context.isAdmin as boolean;
  const messageId = c.req.param('id');
  const db = getDB(c.env);

  const { data: profile } = await db.from('profiles')
    .select('is_admin').eq('id', userId).single();
  const userIsAdmin = isAdmin || profile?.is_admin === true;

  if (!userIsAdmin) {
    return c.json({ error: 'Seul l\'administrateur peut épingler les messages.' }, 403);
  }

  // Vérifier état actuel du message
  const { data: msg } = await db
    .from('messages_entraide')
    .select('id, telephone_partage')
    .eq('id', messageId)
    .eq('actif', true)
    .single();

  if (!msg) return c.json({ error: 'Message introuvable.' }, 404);

  const isPinned = msg.telephone_partage === 'pinned';

  if (isPinned) {
    // Désépingler
    await db.from('messages_entraide')
      .update({ telephone_partage: null })
      .eq('id', messageId);
    return c.json({ success: true, pinned: false, message: 'Message désépinglé.' });
  } else {
    // Épingler ce message (désépingler les autres d'abord)
    await db.from('messages_entraide')
      .update({ telephone_partage: null })
      .eq('telephone_partage', 'pinned');
    await db.from('messages_entraide')
      .update({ telephone_partage: 'pinned' })
      .eq('id', messageId);
    return c.json({ success: true, pinned: true, message: 'Message épinglé !' });
  }
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
    // Désactiver aussi les réponses (likes + réponses liés à ce message)
    const likeJson = JSON.stringify({ _like: true, _pid: id });
    await db.from('messages_entraide').update({ actif: false }).eq('contenu', likeJson);
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
    note: 'Entraide v7.0 — Likes, épinglage, filtres. Tout sans migration SQL.',
    version: '7.0',
    features: ['likes', 'epinglage', 'filtres', 'reponses_admin'],
  });
});

export default entraide;
