// ══════════════════════════════════════════════════════════════
// ENTRAIDE v5.0 — Questions/Réponses avec réponses admin
// Utilisateurs : 1 question/statut par jour max
// Admin : peut répondre à toutes les questions, sans limite
// ══════════════════════════════════════════════════════════════
import { Hono } from 'hono';
import { getDB } from '../lib/db';
import { verifyJWT } from '../lib/auth';
const entraide = new Hono();
async function requireAuth(c, next) {
    const h = c.req.header('Authorization');
    if (!h?.startsWith('Bearer '))
        return c.json({ error: 'Auth requise.' }, 401);
    const p = await verifyJWT(h.slice(7));
    if (!p)
        return c.json({ error: 'Token invalide.' }, 401);
    const context = c;
    context.userId = p.id;
    context.isAdmin = p.is_admin === true;
    await next();
}
// ── GET /api/entraide — Messages récents avec réponses ──────────
entraide.get('/', requireAuth, async (c) => {
    const db = getDB(c.env);
    // Récupérer les questions (messages parents = pas de parent_id)
    const { data: messages, error } = await db
        .from('messages_entraide')
        .select('id, contenu, partage_whatsapp, telephone_partage, created_at, user_id, actif')
        .eq('actif', true)
        .is('parent_id', null)
        .order('created_at', { ascending: false })
        .limit(100);
    if (error) {
        // Fallback si la colonne parent_id n'existe pas encore
        const { data: allMessages, error: err2 } = await db
            .from('messages_entraide')
            .select('id, contenu, partage_whatsapp, telephone_partage, created_at, user_id')
            .eq('actif', true)
            .order('created_at', { ascending: false })
            .limit(100);
        if (err2)
            return c.json({ error: err2.message }, 500);
        // Enrichir avec les profils
        const enriched = [];
        for (const m of (allMessages ?? [])) {
            const { data: profile } = await db.from('profiles')
                .select('nom, prenom, is_admin')
                .eq('id', m.user_id).single();
            enriched.push({
                ...m,
                prenom: profile?.prenom ?? 'Utilisateur',
                nom: profile?.nom ?? '',
                is_admin: profile?.is_admin ?? false,
                reponses: [],
            });
        }
        return c.json({ success: true, messages: enriched });
    }
    // Enrichir avec les profils + réponses
    const enriched = [];
    for (const m of (messages ?? [])) {
        const { data: profile } = await db.from('profiles')
            .select('nom, prenom, is_admin')
            .eq('id', m.user_id).single();
        // Récupérer les réponses à ce message
        let reponses = [];
        try {
            const { data: reps } = await db
                .from('messages_entraide')
                .select('id, contenu, created_at, user_id')
                .eq('parent_id', m.id)
                .eq('actif', true)
                .order('created_at', { ascending: true });
            for (const r of (reps ?? [])) {
                const { data: repProfile } = await db.from('profiles')
                    .select('nom, prenom, is_admin')
                    .eq('id', r.user_id).single();
                reponses.push({
                    ...r,
                    prenom: repProfile?.prenom ?? 'Admin',
                    nom: repProfile?.nom ?? '',
                    is_admin: repProfile?.is_admin ?? false,
                });
            }
        }
        catch (_) { }
        enriched.push({
            ...m,
            prenom: profile?.prenom ?? 'Utilisateur',
            nom: profile?.nom ?? '',
            is_admin: profile?.is_admin ?? false,
            reponses,
        });
    }
    return c.json({ success: true, messages: enriched });
});
// ── POST /api/entraide — Publier un message/question ────────────
// Limite 1 message/24h pour les non-admins
entraide.post('/', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const isAdmin = context.isAdmin;
    const body = await c.req.json().catch(() => ({}));
    const { contenu, partage_whatsapp, telephone_partage } = body;
    if (!contenu || String(contenu).trim().length < 3) {
        return c.json({ error: 'Message trop court (minimum 3 caractères).' }, 400);
    }
    const db = getDB(c.env);
    // Vérifier le profil pour avoir is_admin
    const { data: profile } = await db.from('profiles')
        .select('is_admin').eq('id', userId).single();
    const userIsAdmin = isAdmin || profile?.is_admin === true;
    // Limite 1 message/24h UNIQUEMENT pour les non-admins
    if (!userIsAdmin) {
        const cutoff = new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString();
        const { data: existing } = await db
            .from('messages_entraide')
            .select('id')
            .eq('user_id', userId)
            .eq('actif', true)
            .is('parent_id', null)
            .gte('created_at', cutoff)
            .limit(1);
        if (existing && existing.length > 0) {
            return c.json({
                error: 'Vous avez déjà posté votre statut aujourd\'hui. Revenez demain !',
                already_posted: true
            }, 429);
        }
    }
    const insertData = {
        user_id: userId,
        contenu: String(contenu).trim().slice(0, 500),
        partage_whatsapp: partage_whatsapp ?? false,
        telephone_partage: partage_whatsapp ? telephone_partage : null,
        actif: true,
    };
    const { error } = await db.from('messages_entraide').insert(insertData);
    if (error) {
        if (error.message.includes('does not exist') || error.code === '42P01') {
            return c.json({ error: 'La table messages_entraide doit être créée dans Supabase.' }, 500);
        }
        return c.json({ error: error.message }, 500);
    }
    return c.json({ success: true, message: 'Message publié !' });
});
// ── POST /api/entraide/:id/repondre — Admin répond à un message ──
// SEUL L'ADMIN peut répondre (pas de limite de 1/jour pour les réponses)
entraide.post('/:id/repondre', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const isAdmin = context.isAdmin;
    const parentId = c.req.param('id');
    const body = await c.req.json().catch(() => ({}));
    const { contenu } = body;
    if (!contenu || String(contenu).trim().length < 1) {
        return c.json({ error: 'La réponse ne peut pas être vide.' }, 400);
    }
    const db = getDB(c.env);
    // Vérifier que c'est bien un admin
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
    // Insérer la réponse avec parent_id
    const { error } = await db.from('messages_entraide').insert({
        user_id: userId,
        contenu: String(contenu).trim().slice(0, 1000),
        parent_id: parentId,
        partage_whatsapp: false,
        actif: true,
    });
    if (error) {
        // Si la colonne parent_id n'existe pas, créer une réponse sans parent_id
        if (error.message.includes('parent_id') || error.code === '42703') {
            return c.json({
                error: 'Migration requise: ALTER TABLE messages_entraide ADD COLUMN parent_id UUID REFERENCES messages_entraide(id);',
                needs_migration: true
            }, 500);
        }
        return c.json({ error: error.message }, 500);
    }
    return c.json({ success: true, message: 'Réponse publiée !' });
});
// ── DELETE /api/entraide/:id — Supprimer message ──────────────────
// L'admin peut supprimer n'importe quel message
entraide.delete('/:id', requireAuth, async (c) => {
    const context = c;
    const userId = context.userId;
    const isAdmin = context.isAdmin;
    const id = c.req.param('id');
    const db = getDB(c.env);
    // Vérifier si admin dans profiles
    const { data: profile } = await db.from('profiles')
        .select('is_admin').eq('id', userId).single();
    const userIsAdmin = isAdmin || profile?.is_admin === true;
    if (userIsAdmin) {
        await db.from('messages_entraide').update({ actif: false }).eq('id', id);
    }
    else {
        await db.from('messages_entraide')
            .update({ actif: false })
            .eq('id', id)
            .eq('user_id', userId);
    }
    return c.json({ success: true });
});
// ── GET /api/entraide/migration-sql — SQL à exécuter dans Supabase ──
// Endpoint pour obtenir les SQLs de migration nécessaires
entraide.get('/migration-sql', async (c) => {
    const sql = `
-- Migration Entraide v5.0 : Ajout de la colonne parent_id pour les réponses admin
ALTER TABLE public.messages_entraide 
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.messages_entraide(id) ON DELETE CASCADE;

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id ON public.messages_entraide(parent_id);

-- Politique RLS pour les réponses admin
DROP POLICY IF EXISTS "Admin peut inserer reponses" ON public.messages_entraide;
CREATE POLICY "Admin peut inserer reponses" ON public.messages_entraide
  FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Lire messages actifs" ON public.messages_entraide;
CREATE POLICY "Lire messages actifs" ON public.messages_entraide
  FOR SELECT USING (actif = true);
  `;
    return c.json({ success: true, sql: sql.trim() });
});
export default entraide;
