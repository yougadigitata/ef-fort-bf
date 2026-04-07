import { useState, useEffect } from 'react';
import { getActualites, deleteActualite, createActualite } from '../api';
import type { Page } from '../App';

interface Actualite {
  id: string;
  titre: string;
  contenu: string;
  categorie: string;
  actif: boolean;
  created_at: string;
}

export default function AnnoncesPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [annonces, setAnnonces] = useState<Actualite[]>([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);
  const [titre, setTitre] = useState('');
  const [contenu, setContenu] = useState('');
  const [categorie, setCategorie] = useState('ACTUALITE');
  const [submitting, setSubmitting] = useState(false);
  const [toast, setToast] = useState('');

  useEffect(() => { loadAnnonces(); }, []);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 4000);
  }

  async function loadAnnonces() {
    setLoading(true);
    try {
      const data = await getActualites();
      setAnnonces(data.actualites ?? []);
    } catch (_) {}
    setLoading(false);
  }

  async function handleDelete(id: string, titre: string) {
    if (!confirm(`Supprimer l'annonce "${titre}" ?`)) return;
    try {
      await deleteActualite(id);
      showToast('✅ Annonce supprimée.');
      loadAnnonces();
    } catch (e: any) {
      showToast('❌ Erreur : ' + e.message);
    }
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!titre.trim() || !contenu.trim()) {
      showToast('❌ Titre et contenu requis.');
      return;
    }
    setSubmitting(true);
    try {
      await createActualite({ titre: titre.trim(), contenu: contenu.trim(), categorie });
      showToast('✅ Annonce publiée !');
      setTitre(''); setContenu(''); setShowForm(false);
      loadAnnonces();
    } catch (e: any) {
      showToast('❌ Erreur : ' + e.message);
    }
    setSubmitting(false);
  }

  function formatDate(dateStr: string) {
    const d = new Date(dateStr);
    return d.toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  }

  const CATEGORIES = ['ACTUALITE', 'CONSEIL', 'ALERTE', 'RESULTATS', 'INFO'];
  const CAT_COLORS: Record<string, string> = {
    ACTUALITE: '#3b82f6', CONSEIL: '#10b981', ALERTE: '#ef4444',
    RESULTATS: '#f59e0b', INFO: '#8b5cf6',
  };

  return (
    <div>
      {/* Toast */}
      {toast && (
        <div style={{
          position: 'fixed', top: 16, right: 16, zIndex: 9999,
          background: toast.startsWith('✅') ? '#10b981' : '#ef4444',
          color: 'white', padding: '10px 18px', borderRadius: 10, fontWeight: 600, fontSize: 17,
          boxShadow: '0 4px 20px rgba(0,0,0,0.25)',
        }}>{toast}</div>
      )}

      <div style={{ marginBottom: 24, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>Gestion des annonces</h2>
          <p style={{ color: '#64748b', fontSize: 17 }}>{annonces.length} annonce(s) publiée(s)</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={loadAnnonces} style={{ background: '#334155', color: '#94a3b8', border: 'none', padding: '8px 16px', borderRadius: 8, cursor: 'pointer', fontSize: 16 }}>
            🔄 Actualiser
          </button>
          <button onClick={() => setShowForm(!showForm)} style={{
            background: '#1A5C38', color: 'white', border: 'none',
            padding: '8px 16px', borderRadius: 8, cursor: 'pointer', fontSize: 16, fontWeight: 600,
          }}>
            {showForm ? '✕ Fermer' : '✚ Nouvelle annonce'}
          </button>
        </div>
      </div>

      {/* Formulaire création */}
      {showForm && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, marginBottom: 24, border: '1px solid #334155' }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 700, marginBottom: 16 }}>📢 Publier une nouvelle annonce</h3>
          <form onSubmit={handleCreate}>
            <div style={{ display: 'grid', gap: 14 }}>
              <div>
                <label style={{ color: '#94a3b8', fontSize: 16, display: 'block', marginBottom: 6 }}>Titre *</label>
                <input value={titre} onChange={e => setTitre(e.target.value)} required
                  style={{ width: '100%', background: '#0f172a', border: '1px solid #334155', color: '#f1f5f9', padding: '10px 14px', borderRadius: 8, fontSize: 17, boxSizing: 'border-box' }}
                  placeholder="Titre de l'annonce..." />
              </div>
              <div>
                <label style={{ color: '#94a3b8', fontSize: 16, display: 'block', marginBottom: 6 }}>Contenu *</label>
                <textarea value={contenu} onChange={e => setContenu(e.target.value)} required rows={4}
                  style={{ width: '100%', background: '#0f172a', border: '1px solid #334155', color: '#f1f5f9', padding: '10px 14px', borderRadius: 8, fontSize: 17, resize: 'vertical', boxSizing: 'border-box' }}
                  placeholder="Contenu de l'annonce..." />
              </div>
              <div>
                <label style={{ color: '#94a3b8', fontSize: 16, display: 'block', marginBottom: 6 }}>Catégorie</label>
                <select value={categorie} onChange={e => setCategorie(e.target.value)}
                  style={{ background: '#0f172a', border: '1px solid #334155', color: '#f1f5f9', padding: '10px 14px', borderRadius: 8, fontSize: 17 }}>
                  {CATEGORIES.map(c => <option key={c} value={c}>{c}</option>)}
                </select>
              </div>
              <div style={{ display: 'flex', gap: 10 }}>
                <button type="submit" disabled={submitting} style={{
                  background: '#1A5C38', color: 'white', border: 'none',
                  padding: '10px 24px', borderRadius: 8, cursor: 'pointer', fontSize: 17, fontWeight: 600,
                }}>
                  {submitting ? '⏳ Publication...' : '📢 Publier'}
                </button>
                <button type="button" onClick={() => setShowForm(false)} style={{
                  background: '#334155', color: '#94a3b8', border: 'none',
                  padding: '10px 20px', borderRadius: 8, cursor: 'pointer', fontSize: 17,
                }}>Annuler</button>
              </div>
            </div>
          </form>
        </div>
      )}

      {/* Liste des annonces */}
      {loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#64748b' }}>⏳ Chargement...</div>
      ) : annonces.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, background: '#1e293b', borderRadius: 12, color: '#64748b' }}>
          <div style={{ fontSize: 48, marginBottom: 12 }}>📰</div>
          <p>Aucune annonce publiée</p>
          <button onClick={() => setShowForm(true)} style={{ marginTop: 16, background: '#1A5C38', color: 'white', border: 'none', padding: '10px 20px', borderRadius: 8, cursor: 'pointer' }}>
            ✚ Créer la première annonce
          </button>
        </div>
      ) : (
        <div style={{ display: 'grid', gap: 12 }}>
          {annonces.map((a) => {
            const catColor = CAT_COLORS[a.categorie] ?? '#64748b';
            return (
              <div key={a.id} style={{
                background: '#1e293b', borderRadius: 12, padding: 20,
                border: '1px solid #334155',
                display: 'flex', gap: 16, alignItems: 'flex-start',
              }}>
                <div style={{
                  width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
                  background: catColor + '22', display: 'flex', alignItems: 'center', justifyContent: 'center',
                  fontSize: 20,
                }}>📢</div>
                <div style={{ flex: 1, minWidth: 0 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 8, flexWrap: 'wrap', marginBottom: 6 }}>
                    <span style={{ color: '#f1f5f9', fontWeight: 700, fontSize: 18 }}>{a.titre}</span>
                    <span style={{
                      background: catColor + '22', color: catColor,
                      padding: '2px 8px', borderRadius: 12, fontSize: 14, fontWeight: 600,
                    }}>{a.categorie}</span>
                    {!a.actif && <span style={{ background: '#ef444422', color: '#ef4444', padding: '2px 8px', borderRadius: 12, fontSize: 14 }}>MASQUÉE</span>}
                  </div>
                  <p style={{ color: '#94a3b8', fontSize: 16, lineHeight: 1.6, margin: '0 0 8px 0' }}>{a.contenu}</p>
                  <div style={{ color: '#475569', fontSize: 15 }}>📅 {formatDate(a.created_at)}</div>
                </div>
                <div style={{ display: 'flex', gap: 8, flexShrink: 0 }}>
                  <button onClick={() => handleDelete(a.id, a.titre)} style={{
                    background: '#ef444422', color: '#ef4444', border: 'none',
                    padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontSize: 16,
                    display: 'flex', alignItems: 'center', gap: 4,
                  }}>🗑 Suppr.</button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}
