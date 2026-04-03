// ══════════════════════════════════════════════════════════════
// ENTRAIDE PAGE — Panel Admin
// Voir toutes les questions et y répondre
// ══════════════════════════════════════════════════════════════
import { useState, useEffect } from 'react';
import { getToken } from '../api';
import type { Page } from '../App';

const BASE_URL = window.location.hostname === 'localhost'
  ? 'http://localhost:8787'
  : 'https://ef-fort-bf.yembuaro29.workers.dev';

interface Message {
  id: string;
  user_id: string;
  contenu: string;
  created_at: string;
  prenom: string;
  nom: string;
  is_admin: boolean;
  reponses?: Reponse[];
}

interface Reponse {
  id: string;
  contenu: string;
  created_at: string;
  prenom: string;
  nom: string;
  is_admin: boolean;
}

export default function EntraidePage({ onNavigate: _n }: { onNavigate: (p: Page) => void }) {
  const [messages, setMessages] = useState<Message[]>([]);
  const [loading, setLoading] = useState(true);
  const [replyTexts, setReplyTexts] = useState<Record<string, string>>({});
  const [sending, setSending] = useState<string | null>(null);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');

  async function load() {
    setLoading(true);
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/entraide`, {
        headers: { Authorization: `Bearer ${token}` },
      });
      const data = await res.json();
      if (data.success) {
        setMessages(data.messages ?? []);
      } else {
        setError(data.error ?? 'Erreur de chargement');
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  async function repondre(messageId: string) {
    const text = (replyTexts[messageId] ?? '').trim();
    if (!text) return;

    setSending(messageId);
    setError(''); setSuccess('');
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/entraide/${messageId}/repondre`, {
        method: 'POST',
        headers: {
          Authorization: `Bearer ${token}`,
          'Content-Type': 'application/json',
        },
        body: JSON.stringify({ contenu: text }),
      });
      const data = await res.json();
      if (res.ok && data.success) {
        setSuccess('Réponse publiée !');
        setReplyTexts(prev => ({ ...prev, [messageId]: '' }));
        await load();
      } else if (data.needs_migration) {
        setError('Migration requise : exécutez le SQL de migration dans Supabase (ajout colonne parent_id)');
      } else {
        setError(data.error ?? 'Erreur');
      }
    } catch (e: any) {
      setError(e.message);
    } finally {
      setSending(null);
    }
  }

  async function supprimer(messageId: string) {
    if (!confirm('Supprimer ce message ?')) return;
    try {
      const token = getToken();
      await fetch(`${BASE_URL}/api/entraide/${messageId}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
      await load();
    } catch (e: any) {
      setError(e.message);
    }
  }

  useEffect(() => { load(); }, []);

  const formatDate = (d: string) => {
    try {
      const dt = new Date(d);
      return dt.toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' });
    } catch { return d; }
  };

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700, margin: 0 }}>🤝 Entraide — Questions Utilisateurs</h2>
          <p style={{ color: '#64748b', fontSize: 14, marginTop: 4 }}>
            {messages.length} message(s) · Répondez aux questions de la communauté
          </p>
        </div>
        <button onClick={load} style={{
          background: '#1A5C38', color: 'white', border: 'none',
          padding: '8px 16px', borderRadius: 8, cursor: 'pointer', fontWeight: 600,
        }}>🔄 Actualiser</button>
      </div>

      {/* SQL Migration Info */}
      <div style={{ background: 'rgba(212,160,23,0.1)', border: '1px solid rgba(212,160,23,0.3)', borderRadius: 12, padding: 14, marginBottom: 20 }}>
        <div style={{ color: '#D4A017', fontWeight: 700, marginBottom: 6, fontSize: 13 }}>⚠️ Migration requise pour les réponses</div>
        <div style={{ color: '#94a3b8', fontSize: 12 }}>
          Pour activer les réponses, exécutez ce SQL dans Supabase Dashboard :
        </div>
        <pre style={{ background: '#0f172a', color: '#4ade80', borderRadius: 8, padding: 12, fontSize: 11, marginTop: 8, overflow: 'auto' }}>{`ALTER TABLE public.messages_entraide 
  ADD COLUMN IF NOT EXISTS parent_id UUID REFERENCES public.messages_entraide(id) ON DELETE CASCADE;

CREATE INDEX IF NOT EXISTS idx_messages_entraide_parent_id ON public.messages_entraide(parent_id);`}</pre>
      </div>

      {error && (
        <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid #ef444444', borderRadius: 8, padding: 12, color: '#ef4444', fontSize: 13, marginBottom: 16 }}>
          ❌ {error}
        </div>
      )}
      {success && (
        <div style={{ background: 'rgba(34,197,94,0.1)', border: '1px solid #22c55e44', borderRadius: 8, padding: 12, color: '#22c55e', fontSize: 13, marginBottom: 16 }}>
          ✅ {success}
        </div>
      )}

      {loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#64748b' }}>Chargement...</div>
      ) : messages.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#64748b', background: '#1e293b', borderRadius: 12 }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>🤝</div>
          <div>Aucun message pour l'instant</div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {messages.map((msg) => (
            <div key={msg.id} style={{
              background: '#1e293b', borderRadius: 16, padding: 20,
              border: msg.is_admin ? '1px solid #1A5C38' : '1px solid #334155',
            }}>
              {/* En-tête */}
              <div style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 12 }}>
                <div style={{
                  width: 40, height: 40, borderRadius: '50%', flexShrink: 0,
                  background: msg.is_admin ? '#1A5C38' : '#334155',
                  display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 14, fontWeight: 700, color: 'white',
                }}>
                  {msg.is_admin ? 'EF' : msg.prenom?.[0]?.toUpperCase() ?? 'U'}
                </div>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                    <span style={{ color: '#f1f5f9', fontWeight: 700, fontSize: 14 }}>
                      {msg.is_admin ? 'EF-FORT.BF' : `${msg.prenom ?? ''} ${msg.nom ?? ''}`}
                    </span>
                    {msg.is_admin && (
                      <span style={{ background: '#1A5C38', color: 'white', fontSize: 9, fontWeight: 700, padding: '2px 6px', borderRadius: 4 }}>OFFICIEL</span>
                    )}
                  </div>
                  <div style={{ color: '#64748b', fontSize: 11 }}>{formatDate(msg.created_at)}</div>
                </div>
                <button onClick={() => supprimer(msg.id)} style={{
                  background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                  color: '#ef4444', padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontSize: 12,
                }}>🗑 Supprimer</button>
              </div>

              {/* Contenu */}
              <div style={{ color: '#e2e8f0', fontSize: 14, lineHeight: 1.6, marginBottom: 12 }}>
                {msg.contenu}
              </div>

              {/* Réponses existantes */}
              {(msg.reponses ?? []).length > 0 && (
                <div style={{ marginBottom: 12 }}>
                  <div style={{ color: '#22c55e', fontSize: 12, fontWeight: 700, marginBottom: 8 }}>
                    ✅ {msg.reponses!.length} réponse(s) officielle(s)
                  </div>
                  {msg.reponses!.map((rep) => (
                    <div key={rep.id} style={{
                      background: 'rgba(26,92,56,0.1)', border: '1px solid rgba(26,92,56,0.3)',
                      borderRadius: 10, padding: 12, marginBottom: 6,
                    }}>
                      <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                        <span style={{ color: '#4ade80', fontSize: 12, fontWeight: 700 }}>🎯 {rep.prenom ?? 'Admin'}</span>
                        <span style={{ color: '#64748b', fontSize: 11 }}>{formatDate(rep.created_at)}</span>
                      </div>
                      <div style={{ color: '#e2e8f0', fontSize: 13 }}>{rep.contenu}</div>
                    </div>
                  ))}
                </div>
              )}

              {/* Zone de réponse admin */}
              {!msg.is_admin && (
                <div style={{ borderTop: '1px solid #334155', paddingTop: 12 }}>
                  <div style={{ color: '#64748b', fontSize: 12, marginBottom: 6 }}>💬 Répondre à ce message</div>
                  <div style={{ display: 'flex', gap: 8 }}>
                    <textarea
                      value={replyTexts[msg.id] ?? ''}
                      onChange={e => setReplyTexts(prev => ({ ...prev, [msg.id]: e.target.value }))}
                      placeholder="Rédigez votre réponse officielle..."
                      rows={3}
                      style={{
                        flex: 1, background: '#0f172a', border: '1px solid #334155',
                        borderRadius: 8, padding: '8px 12px', color: '#f1f5f9', fontSize: 13,
                        resize: 'vertical', fontFamily: 'inherit',
                      }}
                    />
                    <button
                      onClick={() => repondre(msg.id)}
                      disabled={sending === msg.id || !(replyTexts[msg.id] ?? '').trim()}
                      style={{
                        background: sending === msg.id || !(replyTexts[msg.id] ?? '').trim() ? '#334155' : '#1A5C38',
                        color: 'white', border: 'none', padding: '8px 16px',
                        borderRadius: 8, cursor: sending === msg.id || !(replyTexts[msg.id] ?? '').trim() ? 'not-allowed' : 'pointer',
                        fontWeight: 700, fontSize: 13, alignSelf: 'flex-end',
                      }}
                    >
                      {sending === msg.id ? '⏳' : '📤 Répondre'}
                    </button>
                  </div>
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
