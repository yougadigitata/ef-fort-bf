// ══════════════════════════════════════════════════════════════
// ENTRAIDE v4.0 — Chat communautaire avec réponses admin
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

// GET /api/entraide — Messages récents avec réponses
entraide.get('/', requireAuth, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db
    .from('messages_entraide')
    .select(`
      id, contenu, partage_whatsapp, telephone_partage, created_at, user_id,
      profiles(nom, prenom, niveau, is_admin)
    `)
    .eq('actif', true)
    .order('created_at', { ascending: false })
    .limit(100);
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, messages: data });
});

// POST /api/entraide — Publier un message
// L'ADMIN PEUT TOUJOURS POSTER — Pas de limite de 1/jour pour l'admin
entraide.post('/', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const isAdmin = context.isAdmin as boolean;
  const body = await c.req.json().catch(() => ({}));
  const { contenu, partage_whatsapp, telephone_partage } = body;
  
  if (!contenu || String(contenu).trim().length < 3) {
    return c.json({ error: 'Message trop court (minimum 3 caractères).' }, 400);
  }
  
  const db = getDB(c.env);

  // Vérifier le profil pour avoir is_admin
  const { data: profile } = await db
    .from('profiles')
    .select('is_admin')
    .eq('id', userId)
    .single();
  
  const userIsAdmin = isAdmin || profile?.is_admin === true;

  // Limite 1 message/24h UNIQUEMENT pour les non-admins
  if (!userIsAdmin) {
    const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
    const { data: existing } = await db
      .from('messages_entraide')
      .select('id')
      .eq('user_id', userId)
      .eq('actif', true)
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
    partage_whatsapp: partage_whatsapp ?? false,
    telephone_partage: partage_whatsapp ? telephone_partage : null,
    actif: true,
  });
  
  if (error) {
    if (error.message.includes('does not exist') || error.code === '42P01') {
      return c.json({ 
        error: 'La table messages_entraide doit être créée dans Supabase.' 
      }, 500);
    }
    return c.json({ error: error.message }, 500);
  }
  
  return c.json({ success: true, message: 'Message publié !' });
});

// DELETE /api/entraide/:id — Supprimer message
// L'admin peut supprimer n'importe quel message
entraide.delete('/:id', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const isAdmin = context.isAdmin as boolean;
  const id = c.req.param('id');
  const db = getDB(c.env);

  // Vérifier si admin dans profiles
  const { data: profile } = await db
    .from('profiles')
    .select('is_admin')
    .eq('id', userId)
    .single();
  
  const userIsAdmin = isAdmin || profile?.is_admin === true;

  if (userIsAdmin) {
    // Admin: peut supprimer n'importe quel message
    await db.from('messages_entraide')
      .update({ actif: false })
      .eq('id', id);
  } else {
    // Utilisateur: ne peut supprimer que ses propres messages
    await db.from('messages_entraide')
      .update({ actif: false })
      .eq('id', id)
      .eq('user_id', userId);
  }
  return c.json({ success: true });
});

export default entraide;
