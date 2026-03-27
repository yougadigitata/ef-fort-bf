// ══════════════════════════════════════════════════════════════
// TÂCHE 7 — API Entraide (Chat communautaire)
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
  await next();
}

// GET /api/entraide — Messages récents
entraide.get('/', requireAuth, async (c) => {
  const db = getDB(c.env);
  const { data, error } = await db
    .from('messages_entraide')
    .select(`
      id, contenu, partage_whatsapp, telephone_partage, created_at,
      profiles(nom, prenom, niveau)
    `)
    .eq('actif', true)
    .order('created_at', { ascending: false })
    .limit(50);
  if (error) return c.json({ error: error.message }, 500);
  return c.json({ success: true, messages: data });
});

// POST /api/entraide — Publier un message
entraide.post('/', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const body = await c.req.json().catch(() => ({}));
  const { contenu, partage_whatsapp, telephone_partage } = body;
  
  if (!contenu || String(contenu).trim().length < 3) {
    return c.json({ error: 'Message trop court (minimum 3 caractères).' }, 400);
  }
  
  const db = getDB(c.env);
  const { error } = await db.from('messages_entraide').insert({
    user_id: userId,
    contenu: String(contenu).trim().slice(0, 500),
    partage_whatsapp: partage_whatsapp ?? false,
    telephone_partage: partage_whatsapp ? telephone_partage : null,
    actif: true,
  });
  
  if (error) {
    // Si la table n'existe pas encore
    if (error.message.includes('does not exist') || error.code === '42P01') {
      return c.json({ 
        error: 'La table messages_entraide doit être créée dans Supabase. Contactez l\'administrateur.' 
      }, 500);
    }
    return c.json({ error: error.message }, 500);
  }
  
  return c.json({ success: true, message: 'Message publié !' });
});

// DELETE /api/entraide/:id — Supprimer son propre message
entraide.delete('/:id', requireAuth, async (c) => {
  const context = c as any;
  const userId = context.userId as string;
  const id = c.req.param('id');
  const db = getDB(c.env);
  await db.from('messages_entraide')
    .update({ actif: false })
    .eq('id', id)
    .eq('user_id', userId);
  return c.json({ success: true });
});

export default entraide;
