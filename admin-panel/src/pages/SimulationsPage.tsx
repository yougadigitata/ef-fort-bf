import React, { useState, useEffect } from 'react';
import { getSimulations, createSimulation, deleteSimulation, updateSimulation, getMatieres } from '../api';
import type { Page } from '../App';

// ══════════════════════════════════════════════════════════════
// SIMULATIONS & EXAMENS PAGE v7.0
// Onglet 1: Simulations (Examens Blancs) — section Examen Blanc
// Onglet 2: Examens Types (vrais sujets) — section Examens Types
// Création manuelle OU Import depuis CMS QCM
// ══════════════════════════════════════════════════════════════

const DUREES = [
  { label: '1h', value: 60 },
  { label: '1h30', value: 90 },
  { label: '2h', value: 120 },
  { label: '3h', value: 180 },
  { label: '4h', value: 240 },
];

export default function SimulationsPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [activeTab, setActiveTab] = useState<'simulation' | 'examen_type'>('simulation');
  const [simulations, setSimulations] = useState<any[]>([]);
  const [examensTypes, setExamensTypes] = useState<any[]>([]);
  const [matieres, setMatieres] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [toast, setToast] = useState('');
  const [saving, setSaving] = useState(false);

  const [form, setForm] = useState({
    titre: '', description: '', duree_minutes: 90, score_max: 50,
    ordre_questions: 'sequential', show_corrections: true, show_score_after: true,
    type: 'simulation' as 'simulation' | 'examen_type',
    config: [] as Array<{ matiere_id: string; matiere_nom: string; count: number }>,
  });

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [simData, matData] = await Promise.all([getSimulations(), getMatieres()]);
      const allSims = simData.simulations ?? [];
      // Séparer par type
      setSimulations(allSims.filter((s: any) => s.type !== 'examen_type'));
      setExamensTypes(allSims.filter((s: any) => s.type === 'examen_type'));
      setMatieres(matData.matieres ?? []);
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
    if (activeTab === 'simulation' && totalSelected !== 50) {
      if (!confirm(`⚠️ Une simulation standard devrait avoir 50 questions. Vous avez sélectionné ${totalSelected}.\nContinuer quand même ?`)) return;
    }

    setSaving(true);
    try {
      const questions = form.config.filter(c => c.count > 0).map(c => ({ matiere_id: c.matiere_id, count: c.count }));
      const data = await createSimulation({
        titre: form.titre, description: form.description,
        duree_minutes: form.duree_minutes, score_max: form.score_max,
        questions, ordre_questions: form.ordre_questions,
        show_corrections: form.show_corrections, show_score_after: form.show_score_after,
        type: activeTab,
      });
      showToast(`✅ ${activeTab === 'simulation' ? 'Simulation' : 'Examen Type'} "${form.titre}" créé(e) !`);
      setShowCreate(false);
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
    finally { setSaving(false); }
  }

  async function handleDelete(id: string, titre: string) {
    if (!confirm(`Supprimer "${titre}" ?`)) return;
    try {
      await deleteSimulation(id);
      showToast('✅ Supprimé(e).');
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  async function handleToggle(s: any) {
    try {
      await updateSimulation(s.id, { published: !s.published });
      showToast(s.published ? '✅ Masqué(e)' : '✅ Publié(e)');
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  const currentList = activeTab === 'simulation' ? simulations : examensTypes;

  return (
    <div>
      {toast && <div style={{ position: 'fixed', top: 70, right: 20, padding: '10px 16px', background: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, zIndex: 1000, maxWidth: 400 }}>{toast}</div>}

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>🎯 Simulations & Examens Types</h2>
          <p style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
            {simulations.length} simulation(s) · {examensTypes.length} examen(s) type
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button
            onClick={() => onNavigate('bulk-import')}
            style={{ padding: '8px 14px', background: 'rgba(37,99,235,0.15)', border: '1px solid rgba(37,99,235,0.4)', borderRadius: 8, color: '#93c5fd', cursor: 'pointer', fontWeight: 600, fontSize: 13 }}
          >
            📤 Importer depuis CMS QCM
          </button>
          <button
            onClick={() => { setShowCreate(!showCreate); setForm(f => ({ ...f, type: activeTab })); }}
            style={{ padding: '8px 16px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 600, fontSize: 14 }}
          >
            {showCreate ? '✕ Fermer' : '✚ Créer manuellement'}
          </button>
        </div>
      </div>

      {/* ── ONGLETS Simulation / Examen Type ─────────────────────────────── */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 24, background: '#0f172a', borderRadius: 12, padding: 6, border: '1px solid #334155' }}>
        <button
          onClick={() => { setActiveTab('simulation'); setShowCreate(false); }}
          style={{
            flex: 1, padding: '12px 16px', borderRadius: 8, border: 'none', cursor: 'pointer',
            fontWeight: 700, fontSize: 14, transition: 'all 0.2s',
            background: activeTab === 'simulation' ? 'linear-gradient(135deg, #1d4ed8, #3b82f6)' : 'transparent',
            color: activeTab === 'simulation' ? 'white' : '#64748b',
          }}
        >
          📄 Simulations (Examens Blancs)
          <div style={{ fontSize: 11, fontWeight: 400, marginTop: 2, opacity: 0.85 }}>
            Visibles dans section Examen → "Examens Blancs" · {simulations.length} créée(s)
          </div>
        </button>
        <button
          onClick={() => { setActiveTab('examen_type'); setShowCreate(false); }}
          style={{
            flex: 1, padding: '12px 16px', borderRadius: 8, border: 'none', cursor: 'pointer',
            fontWeight: 700, fontSize: 14, transition: 'all 0.2s',
            background: activeTab === 'examen_type' ? 'linear-gradient(135deg, #7c3aed, #a855f7)' : 'transparent',
            color: activeTab === 'examen_type' ? 'white' : '#64748b',
          }}
        >
          🏆 Examens Types (Vrais Sujets)
          <div style={{ fontSize: 11, fontWeight: 400, marginTop: 2, opacity: 0.85 }}>
            Visibles dans section Examen → "Examens Types" · {examensTypes.length} créé(s)
          </div>
        </button>
      </div>

      {/* Note explicative contextuelle */}
      <div style={{
        padding: '10px 14px', marginBottom: 20, borderRadius: 8, fontSize: 13,
        background: activeTab === 'simulation' ? 'rgba(37,99,235,0.06)' : 'rgba(124,58,237,0.06)',
        border: activeTab === 'simulation' ? '1px solid rgba(37,99,235,0.25)' : '1px solid rgba(124,58,237,0.25)',
        color: activeTab === 'simulation' ? '#93c5fd' : '#c4b5fd',
      }}>
        {activeTab === 'simulation' ? (
          <>
            <strong>📄 Simulations :</strong> Les candidats voient les <strong>questions à gauche</strong> et noircissent les <strong>cases A/B/C/D/E à droite</strong>.
            Idéal pour 50 questions · 1h30 · Correction détaillée + export PDF après soumission.
          </>
        ) : (
          <>
            <strong>🏆 Examens Types :</strong> Vrais sujets de concours passés.
            Même présentation (questions gauche, cases droite). L'étudiant s'entraîne sur de vrais sujets.
          </>
        )}
      </div>

      {/* ── Formulaire Création manuelle ─────────────────────────────────── */}
      {showCreate && (
        <div style={{
          background: '#1e293b', borderRadius: 12, padding: 24, marginBottom: 24,
          border: activeTab === 'simulation' ? '1px solid rgba(37,99,235,0.4)' : '1px solid rgba(124,58,237,0.4)',
        }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 20 }}>
            {activeTab === 'simulation' ? '📄 Créer une Simulation (Examen Blanc)' : '🏆 Créer un Examen Type'}
          </h3>
          <form onSubmit={handleCreate}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
              <div style={{ gridColumn: '1 / -1' }}>
                <label style={lbl}>Titre *</label>
                <input value={form.titre} onChange={e => setForm(f => ({ ...f, titre: e.target.value }))}
                  placeholder={activeTab === 'simulation' ? "Examen Blanc — Concours ENAM 2026" : "Concours MFPRE 2024 — Épreuve Écrite"}
                  required style={{ ...inp, width: '100%' }} />
              </div>
              <div style={{ gridColumn: '1 / -1' }}>
                <label style={lbl}>Description</label>
                <input value={form.description} onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Simulation complète · Culture générale · 50 questions..." style={{ ...inp, width: '100%' }} />
              </div>
              <div>
                <label style={lbl}>Durée</label>
                <div style={{ display: 'flex', gap: 6 }}>
                  {DUREES.map(d => (
                    <button key={d.value} type="button"
                      onClick={() => setForm(f => ({ ...f, duree_minutes: d.value }))}
                      style={{
                        flex: 1, padding: '8px 4px', border: 'none', borderRadius: 8, cursor: 'pointer', fontSize: 12, fontWeight: 600,
                        background: form.duree_minutes === d.value ? (activeTab === 'simulation' ? '#1d4ed8' : '#7c3aed') : '#0f172a',
                        color: form.duree_minutes === d.value ? 'white' : '#64748b',
                      }}>{d.label}</button>
                  ))}
                </div>
              </div>
              <div>
                <label style={lbl}>Score max (nb questions)</label>
                <input type="number" value={form.score_max} onChange={e => setForm(f => ({ ...f, score_max: parseInt(e.target.value) }))} min="5" max="200" style={{ ...inp, width: '100%' }} />
              </div>
            </div>

            {/* Options */}
            <div style={{ display: 'flex', gap: 20, marginBottom: 16 }}>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: '#94a3b8', fontSize: 13 }}>
                <input type="checkbox" checked={form.ordre_questions === 'random'} onChange={e => setForm(f => ({ ...f, ordre_questions: e.target.checked ? 'random' : 'sequential' }))} />
                Ordre aléatoire
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: '#94a3b8', fontSize: 13 }}>
                <input type="checkbox" checked={form.show_corrections} onChange={e => setForm(f => ({ ...f, show_corrections: e.target.checked }))} />
                Corrections après soumission
              </label>
              <label style={{ display: 'flex', alignItems: 'center', gap: 6, cursor: 'pointer', color: '#94a3b8', fontSize: 13 }}>
                <input type="checkbox" checked={form.show_score_after} onChange={e => setForm(f => ({ ...f, show_score_after: e.target.checked }))} />
                Score visible après
              </label>
            </div>

            {/* Sélection questions par matière */}
            <div style={{ background: '#0f172a', borderRadius: 8, padding: 16, marginBottom: 16 }}>
              <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
                <label style={{ color: '#f1f5f9', fontSize: 14, fontWeight: 600 }}>
                  📋 Questions par matière
                  {activeTab === 'simulation' && <span style={{ color: '#64748b', fontSize: 12, fontWeight: 400 }}> (objectif : 50 questions)</span>}
                </label>
                <span style={{
                  color: totalSelected > 0 ? (activeTab === 'simulation' && totalSelected === 50 ? '#4ade80' : '#fbbf24') : '#64748b',
                  fontSize: 14, fontWeight: 700,
                }}>
                  Total : {totalSelected} / {form.score_max} ✅
                </span>
              </div>
              <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(250px, 1fr))', gap: 8 }}>
                {form.config.map((c, idx) => (
                  <div key={c.matiere_id} style={{
                    display: 'flex', alignItems: 'center', gap: 8,
                    padding: '6px 10px', borderRadius: 6,
                    background: c.count > 0 ? 'rgba(26,92,56,0.2)' : '#1e293b',
                    border: c.count > 0 ? '1px solid rgba(26,92,56,0.5)' : '1px solid #334155',
                  }}>
                    <span style={{ flex: 1, color: c.count > 0 ? '#e2e8f0' : '#64748b', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{c.matiere_nom}</span>
                    <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                      <button type="button" onClick={() => setForm(f => ({ ...f, config: f.config.map((x, i) => i === idx ? { ...x, count: Math.max(0, x.count - 1) } : x) }))}
                        style={{ width: 22, height: 22, background: '#334155', border: 'none', borderRadius: 4, color: 'white', cursor: 'pointer', fontSize: 12 }}>−</button>
                      <span style={{ color: c.count > 0 ? '#4ade80' : '#64748b', fontWeight: 700, fontSize: 14, width: 24, textAlign: 'center' }}>{c.count}</span>
                      <button type="button" onClick={() => setForm(f => ({ ...f, config: f.config.map((x, i) => i === idx ? { ...x, count: x.count + 1 } : x) }))}
                        style={{ width: 22, height: 22, background: '#1A5C38', border: 'none', borderRadius: 4, color: 'white', cursor: 'pointer', fontSize: 12 }}>+</button>
                    </div>
                  </div>
                ))}
              </div>
              {activeTab === 'simulation' && totalSelected > 0 && totalSelected !== 50 && (
                <div style={{ marginTop: 10, color: '#fbbf24', fontSize: 12 }}>
                  ⚠️ Vous avez {totalSelected} questions. Une simulation standard en a 50.
                </div>
              )}
            </div>

            <div style={{ display: 'flex', gap: 12 }}>
              <button type="submit" disabled={saving || totalSelected === 0} style={{
                padding: '12px 28px',
                background: saving || totalSelected === 0 ? '#334155' : activeTab === 'simulation' ? 'linear-gradient(135deg, #1d4ed8, #3b82f6)' : 'linear-gradient(135deg, #7c3aed, #a855f7)',
                border: 'none', borderRadius: 8, color: 'white',
                cursor: saving || totalSelected === 0 ? 'not-allowed' : 'pointer',
                fontWeight: 700, fontSize: 15,
              }}>
                {saving ? '⏳ Création...' : `🚀 Créer (${totalSelected} questions)`}
              </button>
              <button type="button" onClick={() => setShowCreate(false)} style={{ padding: '12px 20px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer' }}>Annuler</button>
            </div>
          </form>
        </div>
      )}

      {/* ── Conseil import ────────────────────────────────────────────────── */}
      {!showCreate && (
        <div style={{ padding: '12px 16px', background: 'rgba(212,160,23,0.06)', border: '1px solid rgba(212,160,23,0.2)', borderRadius: 8, marginBottom: 20, fontSize: 13, color: '#D4A017', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span>
            💡 Vous avez un fichier CSV, MD ou JSON ?
            Utilisez <strong>CMS QCM → Import en masse</strong> pour créer une {activeTab === 'simulation' ? 'simulation' : 'examen type'} automatiquement.
          </span>
          <button onClick={() => onNavigate('bulk-import')} style={{ background: 'rgba(212,160,23,0.15)', border: '1px solid rgba(212,160,23,0.4)', color: '#D4A017', padding: '6px 14px', borderRadius: 6, cursor: 'pointer', fontSize: 12, fontWeight: 600, whiteSpace: 'nowrap', marginLeft: 12 }}>
            📤 Importer →
          </button>
        </div>
      )}

      {/* ── Liste ─────────────────────────────────────────────────────────── */}
      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>
      ) : currentList.length === 0 ? (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>{activeTab === 'simulation' ? '📄' : '🏆'}</div>
          <div style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 8 }}>
            Aucun(e) {activeTab === 'simulation' ? 'simulation' : 'examen type'} créé(e)
          </div>
          <div style={{ color: '#64748b', fontSize: 13 }}>
            Créez manuellement ou importez un fichier via "CMS QCM → Import en masse"
          </div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {currentList.map((s: any) => {
            const qCount = (() => {
              try { return JSON.parse(s.question_ids || '[]').length; } catch { return s.nb_questions_examen ?? 0; }
            })();
            const isSimu = s.type !== 'examen_type';
            return (
              <div key={s.id} style={{
                background: '#1e293b', borderRadius: 12, padding: 20,
                border: s.published ? `1px solid ${isSimu ? 'rgba(37,99,235,0.3)' : 'rgba(124,58,237,0.3)'}` : '1px solid rgba(239,68,68,0.2)',
                display: 'flex', justifyContent: 'space-between', alignItems: 'center',
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ display: 'flex', alignItems: 'center', gap: 10, marginBottom: 6 }}>
                    <span style={{ fontSize: 20 }}>{isSimu ? '📄' : '🏆'}</span>
                    <span style={{ color: '#f1f5f9', fontWeight: 600, fontSize: 16 }}>{s.titre}</span>
                    {s.published ? (
                      <span style={{ background: `rgba(${isSimu ? '37,99,235' : '124,58,237'},0.15)`, color: isSimu ? '#93c5fd' : '#c4b5fd', padding: '2px 8px', borderRadius: 10, fontSize: 11, fontWeight: 700 }}>
                        LIVE
                      </span>
                    ) : (
                      <span style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', padding: '2px 8px', borderRadius: 10, fontSize: 11 }}>Brouillon</span>
                    )}
                  </div>
                  {s.description && <p style={{ color: '#64748b', fontSize: 13, marginBottom: 8 }}>{s.description}</p>}
                  <div style={{ display: 'flex', gap: 16, color: '#64748b', fontSize: 12 }}>
                    <span>⏱️ {Math.floor(s.duree_minutes / 60)}h{s.duree_minutes % 60 > 0 ? `${s.duree_minutes % 60}min` : ''}</span>
                    <span>📋 {qCount} questions</span>
                    <span>🏆 Score max: {s.score_max}</span>
                    <span>📅 {new Date(s.created_at).toLocaleDateString('fr-FR')}</span>
                  </div>
                </div>
                <div style={{ display: 'flex', gap: 8, flexShrink: 0, marginLeft: 16 }}>
                  <button onClick={() => handleToggle(s)} style={{
                    padding: '7px 14px', border: 'none', borderRadius: 6, cursor: 'pointer', fontSize: 13,
                    background: s.published ? 'rgba(239,68,68,0.1)' : `rgba(${isSimu ? '37,99,235' : '124,58,237'},0.15)`,
                    color: s.published ? '#ef4444' : isSimu ? '#93c5fd' : '#c4b5fd',
                  }}>
                    {s.published ? '👁️ Masquer' : '✅ Publier'}
                  </button>
                  <button onClick={() => handleDelete(s.id, s.titre)} style={{
                    padding: '7px 10px', background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                    borderRadius: 6, color: '#ef4444', cursor: 'pointer', fontSize: 13,
                  }}>🗑️</button>
                </div>
              </div>
            );
          })}
        </div>
      )}
    </div>
  );
}

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 4 };
const inp: React.CSSProperties = { padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
