import { useState, useEffect } from 'react';
import { getSimulations, createSimulation, deleteSimulation, updateSimulation, getMatieres } from '../api';
import type { Page } from '../App';

const DUREES = [{ label: '1h30', value: 90 }, { label: '2h', value: 120 }, { label: '3h', value: 180 }, { label: '4h', value: 240 }];

export default function SimulationsPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [simulations, setSimulations] = useState<any[]>([]);
  const [matieres, setMatieres] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [toast, setToast] = useState('');
  const [saving, setSaving] = useState(false);

  const [form, setForm] = useState({
    titre: '', description: '', duree_minutes: 180, score_max: 50,
    ordre_questions: 'random', show_corrections: true, show_score_after: true,
    config: [] as Array<{ matiere_id: string; matiere_nom: string; count: number }>,
  });

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [simData, matData] = await Promise.all([getSimulations(), getMatieres()]);
      setSimulations(simData.simulations ?? []);
      setMatieres(matData.matieres ?? []);
      // Init config avec toutes les matières
      setForm(f => ({
        ...f,
        config: (matData.matieres ?? []).map((m: any) => ({ matiere_id: m.id, matiere_nom: m.nom, count: 0 })),
      }));
    } catch (err: any) { showToast('❌ ' + err.message); }
    finally { setLoading(false); }
  }

  function showToast(msg: string) { setToast(msg); setTimeout(() => setToast(''), 3500); }

  const totalSelected = form.config.reduce((sum, c) => sum + (c.count || 0), 0);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!form.titre.trim()) { showToast('⚠️ Titre requis'); return; }
    if (totalSelected === 0) { showToast('⚠️ Sélectionner au moins 1 question'); return; }

    setSaving(true);
    try {
      const questions = form.config.filter(c => c.count > 0).map(c => ({ matiere_id: c.matiere_id, count: c.count }));
      const data = await createSimulation({
        titre: form.titre, description: form.description,
        duree_minutes: form.duree_minutes, score_max: form.score_max,
        questions, ordre_questions: form.ordre_questions,
        show_corrections: form.show_corrections, show_score_after: form.show_score_after,
      });
      showToast(`✅ Simulation "${form.titre}" créée avec ${data.total_questions} questions !`);
      setShowCreate(false);
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
    finally { setSaving(false); }
  }

  async function handleDelete(id: string, titre: string) {
    if (!confirm(`Supprimer "${titre}" ?`)) return;
    try {
      await deleteSimulation(id);
      showToast('✅ Simulation supprimée.');
      setSimulations(s => s.filter(x => x.id !== id));
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  async function handleToggle(s: any) {
    try {
      await updateSimulation(s.id, { published: !s.published });
      setSimulations(prev => prev.map(x => x.id === s.id ? { ...x, published: !s.published } : x));
      showToast(s.published ? '✅ Simulation masquée' : '✅ Simulation publiée');
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  return (
    <div>
      {toast && <div style={{ position: 'fixed', top: 70, right: 20, padding: '10px 16px', background: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, zIndex: 1000 }}>{toast}</div>}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>🎯 Simulations d'examen</h2>
          <p style={{ color: '#64748b', fontSize: 13 }}>{simulations.length} simulation(s) créée(s)</p>
        </div>
        <button onClick={() => setShowCreate(!showCreate)} style={{ padding: '8px 16px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 600, fontSize: 14 }}>
          {showCreate ? '✕ Fermer' : '✚ Créer simulation'}
        </button>
      </div>

      {/* Formulaire création */}
      {showCreate && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #1A5C38', marginBottom: 24 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 20 }}>🎯 Créer une simulation d'examen</h3>
          <form onSubmit={handleCreate}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
              <div style={{ gridColumn: '1 / -1' }}>
                <label style={lbl}>Titre *</label>
                <input value={form.titre} onChange={e => setForm(f => ({ ...f, titre: e.target.value }))} placeholder="Examen blanc — Concours 2026" required style={{ ...inp, width: '100%' }} />
              </div>
              <div style={{ gridColumn: '1 / -1' }}>
                <label style={lbl}>Description</label>
                <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))} placeholder="Simulation complète avant concours..." style={{ ...inp, width: '100%' }} />
              </div>
              <div>
                <label style={lbl}>Durée</label>
                <div style={{ display: 'flex', gap: 8 }}>
                  {DUREES.map(d => (
                    <button key={d.value} type="button" onClick={() => setForm(f => ({ ...f, duree_minutes: d.value }))} style={{
                      flex: 1, padding: '8px 4px', border: 'none', borderRadius: 8, cursor: 'pointer', fontSize: 13, fontWeight: 600,
                      background: form.duree_minutes === d.value ? '#1A5C38' : '#0f172a',
                      color: form.duree_minutes === d.value ? 'white' : '#64748b',
                      outline: form.duree_minutes === d.value ? '2px solid #1A5C38' : 'none',
                    }}>{d.label}</button>
                  ))}
                </div>
              </div>
              <div>
                <label style={lbl}>Score max</label>
                <input type="number" value={form.score_max} onChange={e => setForm(f => ({ ...f, score_max: parseInt(e.target.value) }))} min="10" max="100" style={{ ...inp, width: '100%' }} />
              </div>
            </div>

            {/* Options */}
            <div style={{ display: 'flex', gap: 16, marginBottom: 16 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: '#94a3b8', fontSize: 13 }}>
                <input type="checkbox" checked={form.ordre_questions === 'random'} onChange={e => setForm(f => ({ ...f, ordre_questions: e.target.checked ? 'random' : 'sequential' }))} />
                Ordre aléatoire
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: '#94a3b8', fontSize: 13 }}>
                <input type="checkbox" checked={form.show_corrections} onChange={e => setForm(f => ({ ...f, show_corrections: e.target.checked }))} />
                Montrer corrections
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: '#94a3b8', fontSize: 13 }}>
                <input type="checkbox" checked={form.show_score_after} onChange={e => setForm(f => ({ ...f, show_score_after: e.target.checked }))} />
                Montrer score après
              </label>
            </div>

            {/* Sélection questions par matière */}
            <div style={{ background: '#0f172a', borderRadius: 8, padding: 16, marginBottom: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <label style={{ color: '#f1f5f9', fontSize: 14, fontWeight: 600 }}>📋 Questions par matière</label>
                <span style={{ color: totalSelected > 0 ? '#4ade80' : '#64748b', fontSize: 14, fontWeight: 600 }}>
                  Total : {totalSelected} questions {totalSelected > 0 ? '✅' : ''}
                </span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 8 }}>
                {form.config.map((c, idx) => (
                  <div key={c.matiere_id} style={{ display: 'flex', alignItems: 'center', gap: 8, padding: '6px 10px', background: c.count > 0 ? 'rgba(26,92,56,0.2)' : '#1e293b', borderRadius: 6, border: c.count > 0 ? '1px solid rgba(26,92,56,0.5)' : '1px solid #334155' }}>
                    <span style={{ flex: 1, color: c.count > 0 ? '#e2e8f0' : '#64748b', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.matiere_nom}</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                      <button type="button" onClick={() => setForm(f => ({ ...f, config: f.config.map((x, i) => i === idx ? { ...x, count: Math.max(0, x.count - 1) } : x) }))} style={{ width: 22, height: 22, background: '#334155', border: 'none', borderRadius: 4, color: 'white', cursor: 'pointer', fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>−</button>
                      <span style={{ color: c.count > 0 ? '#4ade80' : '#64748b', fontWeight: 700, fontSize: 14, width: 24, textAlign: 'center' }}>{c.count}</span>
                      <button type="button" onClick={() => setForm(f => ({ ...f, config: f.config.map((x, i) => i === idx ? { ...x, count: x.count + 1 } : x) }))} style={{ width: 22, height: 22, background: '#1A5C38', border: 'none', borderRadius: 4, color: 'white', cursor: 'pointer', fontSize: 12, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>+</button>
                    </div>
                  </div>
                ))}
              </div>
            </div>

            <div style={{ display: 'flex', gap: 12 }}>
              <button type="submit" disabled={saving || totalSelected === 0} style={{
                padding: '12px 28px', background: saving || totalSelected === 0 ? '#334155' : 'linear-gradient(135deg, #1A5C38, #2d9966)',
                border: 'none', borderRadius: 8, color: 'white', cursor: saving ? 'not-allowed' : 'pointer',
                fontWeight: 700, fontSize: 15,
              }}>
                {saving ? '⏳ Création...' : `🚀 Créer & Publier (${totalSelected} Q)`}
              </button>
              <button type="button" onClick={() => setShowCreate(false)} style={{ padding: '12px 20px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer' }}>Annuler</button>
            </div>
          </form>
        </div>
      )}

      {/* Liste simulations */}
      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>
      ) : simulations.length === 0 ? (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>🎯</div>
          <div style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 8 }}>Aucune simulation créée</div>
          <div style={{ color: '#64748b', fontSize: 13 }}>Créez votre premier examen blanc multi-matières</div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {simulations.map((s: any) => (
            <div key={s.id} style={{
              background: '#1e293b', borderRadius: 12, padding: 20,
              border: s.published ? '1px solid rgba(26,92,56,0.3)' : '1px solid rgba(239,68,68,0.2)',
              display: 'flex', justifyContent: 'space-between', alignItems: 'center',
            }}>
              <div style={{ flex: 1 }}>
                <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                  <span style={{ fontSize: 20 }}>🎯</span>
                  <span style={{ color: '#f1f5f9', fontWeight: 600, fontSize: 16 }}>{s.titre}</span>
                  {s.published ? (
                    <span style={{ background: 'rgba(74,222,128,0.1)', color: '#4ade80', padding: '2px 8px', borderRadius: 10, fontSize: 11 }}>LIVE</span>
                  ) : (
                    <span style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', padding: '2px 8px', borderRadius: 10, fontSize: 11 }}>Masquée</span>
                  )}
                </div>
                {s.description && <p style={{ color: '#64748b', fontSize: 13, marginBottom: 8 }}>{s.description}</p>}
                <div style={{ display: 'flex', gap: 16, color: '#64748b', fontSize: 12 }}>
                  <span>⏱️ {Math.floor(s.duree_minutes / 60)}h{s.duree_minutes % 60 > 0 ? `${s.duree_minutes % 60}min` : ''}</span>
                  <span>📚 {(() => { try { return JSON.parse(s.question_ids || '[]').length; } catch { return 0; } })()} questions</span>
                  <span>🏆 Score max: {s.score_max}</span>
                  <span>📅 {new Date(s.created_at).toLocaleDateString('fr-FR')}</span>
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, flexShrink: 0, marginLeft: 16 }}>
                <button onClick={() => handleToggle(s)} style={{
                  padding: '6px 12px', border: 'none', borderRadius: 6, cursor: 'pointer', fontSize: 13,
                  background: s.published ? 'rgba(239,68,68,0.1)' : 'rgba(74,222,128,0.1)',
                  color: s.published ? '#ef4444' : '#4ade80',
                }}>
                  {s.published ? '👁️ Masquer' : '✅ Publier'}
                </button>
                <button onClick={() => handleDelete(s.id, s.titre)} style={{ padding: '6px 10px', background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 6, color: '#ef4444', cursor: 'pointer', fontSize: 13 }}>
                  🗑️
                </button>
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 4 };
const inp: React.CSSProperties = { padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
