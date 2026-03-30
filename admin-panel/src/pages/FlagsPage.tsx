import { useState, useEffect } from 'react';
import { getFlags, resolveFlag } from '../api';
import type { Page } from '../App';

export default function FlagsPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [flags, setFlags] = useState<any[]>([]);
  const [status, setStatus] = useState('new');
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [resolveId, setResolveId] = useState<string | null>(null);
  const [adminNote, setAdminNote] = useState('');

  useEffect(() => { loadFlags(); }, [status]);

  async function loadFlags() {
    setLoading(true);
    try {
      const data = await getFlags(status);
      setFlags(data.flags ?? []);
    } catch (err: any) { showToast('❌ ' + err.message); }
    finally { setLoading(false); }
  }

  function showToast(msg: string) { setToast(msg); setTimeout(() => setToast(''), 3000); }

  async function handleResolve(id: string) {
    try {
      await resolveFlag(id, adminNote, 'resolved');
      showToast('✅ Signalement résolu.');
      setResolveId(null);
      setAdminNote('');
      loadFlags();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  const statuses = [
    { key: 'new', label: '🆕 Nouveaux', color: '#ef4444' },
    { key: 'reviewed', label: '👁️ En révision', color: '#fbbf24' },
    { key: 'resolved', label: '✅ Résolus', color: '#4ade80' },
    { key: 'all', label: '📋 Tous', color: '#94a3b8' },
  ];

  return (
    <div>
      {toast && <div style={{ position: 'fixed', top: 70, right: 20, padding: '10px 16px', background: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, zIndex: 1000 }}>{toast}</div>}

      <div style={{ marginBottom: 20 }}>
        <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>🚨 Signalements utilisateurs</h2>
        <p style={{ color: '#64748b', fontSize: 13 }}>Questions signalées comme incorrectes ou ambiguës</p>
      </div>

      {/* Onglets */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {statuses.map(s => (
          <button key={s.key} onClick={() => setStatus(s.key)} style={{
            padding: '8px 16px', border: 'none', borderRadius: 8, cursor: 'pointer', fontSize: 14, fontWeight: 500,
            background: status === s.key ? `${s.color}22` : '#1e293b',
            color: status === s.key ? s.color : '#64748b',
            outline: status === s.key ? `1px solid ${s.color}44` : 'none',
          }}>
            {s.label}
          </button>
        ))}
      </div>

      {/* Dialog résolution */}
      {resolveId && (
        <div style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 200, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, maxWidth: 480, width: '90%', border: '1px solid #334155' }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 16 }}>✅ Résoudre le signalement</h3>
            <textarea
              value={adminNote} onChange={e => setAdminNote(e.target.value)}
              placeholder="Note admin (ex: Explication améliorée, réponse corrigée...)"
              rows={3}
              style={{ width: '100%', padding: '10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, resize: 'vertical', marginBottom: 16 }}
            />
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => handleResolve(resolveId)} style={{ padding: '10px 20px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 600 }}>
                ✅ Marquer résolu
              </button>
              <button onClick={() => setResolveId(null)} style={{ padding: '10px 16px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer' }}>
                Annuler
              </button>
            </div>
          </div>
        </div>
      )}

      {/* Liste */}
      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>
      ) : flags.length === 0 ? (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>✅</div>
          <div style={{ color: '#4ade80', fontSize: 16, fontWeight: 600 }}>Aucun signalement en attente</div>
          <div style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>Tout est sous contrôle !</div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {flags.map((f: any) => (
            <div key={f.id} style={{
              background: '#1e293b', borderRadius: 12, padding: 20,
              border: f.status === 'new' ? '1px solid rgba(239,68,68,0.3)' : '1px solid #334155',
            }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 10 }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 6 }}>
                    <span style={{
                      background: f.status === 'new' ? 'rgba(239,68,68,0.1)' : f.status === 'resolved' ? 'rgba(74,222,128,0.1)' : 'rgba(251,191,36,0.1)',
                      color: f.status === 'new' ? '#ef4444' : f.status === 'resolved' ? '#4ade80' : '#fbbf24',
                      padding: '2px 8px', borderRadius: 10, fontSize: 11,
                    }}>
                      {f.status === 'new' ? '🆕 Nouveau' : f.status === 'resolved' ? '✅ Résolu' : '👁️ En révision'}
                    </span>
                    <span style={{ color: '#64748b', fontSize: 12 }}>
                      Question #{String(f.question_id).substring(0, 8)}...
                    </span>
                    <span style={{ color: '#64748b', fontSize: 12 }}>
                      {new Date(f.created_at).toLocaleDateString('fr-FR')}
                    </span>
                  </div>

                  {/* Question préview */}
                  {f.questions?.enonce && (
                    <div style={{ background: '#0f172a', borderRadius: 8, padding: '8px 12px', marginBottom: 10, fontSize: 13, color: '#e2e8f0' }}>
                      ❓ {f.questions.enonce?.substring(0, 120)}...
                    </div>
                  )}

                  <div style={{ marginBottom: 6 }}>
                    <span style={{ color: '#94a3b8', fontSize: 13 }}>Raison : </span>
                    <span style={{ color: '#f1f5f9', fontSize: 13, fontWeight: 500 }}>{f.reason}</span>
                  </div>
                  {f.details && (
                    <div style={{ color: '#64748b', fontSize: 13 }}>💬 {f.details}</div>
                  )}
                  {f.admin_response && (
                    <div style={{ background: 'rgba(26,92,56,0.1)', border: '1px solid rgba(26,92,56,0.3)', borderRadius: 8, padding: '6px 10px', marginTop: 8, color: '#4ade80', fontSize: 13 }}>
                      📝 Note admin: {f.admin_response}
                    </div>
                  )}
                </div>

                {f.status !== 'resolved' && (
                  <div style={{ display: 'flex', gap: 8, marginLeft: 16, flexShrink: 0 }}>
                    <button onClick={() => onNavigate('questions')} title="Voir et éditer la question" style={{ padding: '6px 12px', background: 'rgba(59,130,246,0.1)', border: '1px solid rgba(59,130,246,0.3)', borderRadius: 6, color: '#3b82f6', cursor: 'pointer', fontSize: 13 }}>
                      ✏️ Éditer Q
                    </button>
                    <button onClick={() => setResolveId(f.id)} style={{ padding: '6px 12px', background: 'rgba(74,222,128,0.1)', border: '1px solid rgba(74,222,128,0.3)', borderRadius: 6, color: '#4ade80', cursor: 'pointer', fontSize: 13, fontWeight: 600 }}>
                      ✅ Résoudre
                    </button>
                  </div>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
