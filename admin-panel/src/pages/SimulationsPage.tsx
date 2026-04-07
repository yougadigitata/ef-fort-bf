import React, { useState, useEffect } from 'react';
import { getSimulations, createSimulation, deleteSimulation, updateSimulation, getMatieres } from '../api';
import type { Page } from '../App';

// ══════════════════════════════════════════════════════════════
// EXAMENS TYPES PAGE v9.0 — Structure mise à jour
// 10 matières × 2 séries (Série 1 et Série 2)
// + 11e matière : "Examens Blancs" (examens complets multi-matières)
// NB : Les "Examens Blancs" sont désormais intégrés dans Examens Types
// ══════════════════════════════════════════════════════════════

const DUREES = [
  { label: '45 min', value: 45 },
  { label: '1h', value: 60 },
  { label: '1h30', value: 90 },
  { label: '2h', value: 120 },
  { label: '3h', value: 180 },
  { label: '4h', value: 240 },
];

// Structure des matières officielles
const MATIERES_STRUCTURE = [
  { slug: 'culture_generale', nom: 'Culture Générale', icone: '🌍' },
  { slug: 'mathematiques', nom: 'Mathématiques', icone: '📐' },
  { slug: 'francais', nom: 'Français', icone: '📝' },
  { slug: 'droit', nom: 'Droit', icone: '⚖️' },
  { slug: 'economie', nom: 'Économie', icone: '📊' },
  { slug: 'histoire_geo', nom: 'Histoire-Géographie', icone: '🗺️' },
  { slug: 'sciences', nom: 'Sciences', icone: '🔬' },
  { slug: 'informatique', nom: 'Informatique', icone: '💻' },
  { slug: 'psychologie', nom: 'Psychologie', icone: '🧠' },
  { slug: 'anglais', nom: 'Anglais', icone: '🇬🇧' },
  // 11e : Examens Blancs intégrés dans Examens Types
  { slug: 'examens_blancs', nom: 'Examens Blancs (multi-matières)', icone: '📋' },
];

export default function SimulationsPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [activeTab, setActiveTab] = useState<'examen_type' | 'examen_blanc'>('examen_type');
  const [examensTypes, setExamensTypes] = useState<any[]>([]);
  const [examensBlancs, setExamensBlancs] = useState<any[]>([]);
  const [matieres, setMatieres] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [toast, setToast] = useState('');
  const [saving, setSaving] = useState(false);
  const [filterMatiere, setFilterMatiere] = useState<string>('TOUS');

  const [form, setForm] = useState({
    titre: '',
    description: '',
    duree_minutes: 90,
    score_max: 50,
    ordre_questions: 'sequential',
    show_corrections: true,
    show_score_after: true,
    serie_label: 'Série 1',
    type: 'examen_type' as 'examen_type',
    config: [] as Array<{ matiere_id: string; matiere_nom: string; count: number }>,
  });

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [simData, matData] = await Promise.all([getSimulations(), getMatieres()]);
      const allSims = simData.simulations ?? [];

      // Tous sont des examens_type (les "simulations" séparées n'existent plus)
      const typedSims = allSims.filter((s: any) => s.type === 'examen_type');
      const blancs = allSims.filter((s: any) =>
        s.type === 'examen_type' && (
          s.titre?.toLowerCase().includes('blanc') ||
          s.matiere_slug === 'examens_blancs' ||
          s.is_examen_blanc === true
        )
      );
      const types = typedSims.filter((s: any) => !blancs.find((b: any) => b.id === s.id));

      setExamensTypes(types);
      setExamensBlancs(blancs);
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

    setSaving(true);
    try {
      const questions = form.config.filter(c => c.count > 0).map(c => ({ matiere_id: c.matiere_id, count: c.count }));
      await createSimulation({
        titre: form.titre,
        description: form.description,
        duree_minutes: form.duree_minutes,
        score_max: form.score_max,
        questions,
        ordre_questions: form.ordre_questions,
        show_corrections: form.show_corrections,
        show_score_after: form.show_score_after,
        type: 'examen_type',
        serie_label: form.serie_label,
        is_examen_blanc: activeTab === 'examen_blanc',
      });
      showToast(`✅ "${form.titre}" créé avec succès !`);
      setShowCreate(false);
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
    finally { setSaving(false); }
  }

  async function handleDelete(id: string, titre: string) {
    if (!confirm(`Supprimer "${titre}" ?`)) return;
    try {
      await deleteSimulation(id);
      showToast('🗑️ Supprimé');
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  async function togglePublish(sim: any) {
    try {
      await updateSimulation(sim.id, { published: !sim.published });
      showToast(sim.published ? '🔒 Masqué aux utilisateurs' : '✅ Publié et visible');
      loadData();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  const currentList = activeTab === 'examen_type' ? examensTypes : examensBlancs;
  const filteredList = filterMatiere === 'TOUS'
    ? currentList
    : currentList.filter((s: any) => s.matiere_id === filterMatiere || s.matiere_slug === filterMatiere);

  if (loading) return <LoadingSpinner />;

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24, flexWrap: 'wrap', gap: 12 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700, margin: 0 }}>
            🎯 Examens Types
          </h2>
          <p style={{ color: '#64748b', fontSize: 16, marginTop: 4 }}>
            Structure : <strong style={{ color: '#94a3b8' }}>10 matières × 2 séries + Examens Blancs (11e)</strong>
          </p>
        </div>
        <button
          onClick={() => setShowCreate(true)}
          style={{
            background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
            color: 'white', border: 'none', padding: '10px 20px',
            borderRadius: 8, cursor: 'pointer', fontWeight: 600, fontSize: 17,
          }}
        >
          ✚ Créer un Examen
        </button>
      </div>

      {/* Onglets */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 20, background: '#1e293b', borderRadius: 10, padding: 4, width: 'fit-content' }}>
        <TabBtn
          active={activeTab === 'examen_type'}
          onClick={() => setActiveTab('examen_type')}
          label={`📚 Examens Types (${examensTypes.length})`}
          color="#3b82f6"
        />
        <TabBtn
          active={activeTab === 'examen_blanc'}
          onClick={() => setActiveTab('examen_blanc')}
          label={`📋 Examens Blancs (${examensBlancs.length})`}
          color="#D4A017"
        />
      </div>

      {/* Description de la structure */}
      <div style={{
        background: activeTab === 'examen_type' ? 'rgba(59,130,246,0.08)' : 'rgba(212,160,23,0.08)',
        border: `1px solid ${activeTab === 'examen_type' ? 'rgba(59,130,246,0.2)' : 'rgba(212,160,23,0.2)'}`,
        borderRadius: 10, padding: '12px 16px', marginBottom: 20, fontSize: 16,
        color: '#94a3b8',
      }}>
        {activeTab === 'examen_type' ? (
          <>
            📚 <strong style={{ color: '#3b82f6' }}>Examens Types</strong> — Sujets par matière (Série 1 et Série 2) :
            Culture Générale, Mathématiques, Français, Droit, Économie, Histoire-Géo, Sciences, Informatique, Psychologie, Anglais
          </>
        ) : (
          <>
            📋 <strong style={{ color: '#D4A017' }}>Examens Blancs</strong> — Examens complets multi-matières simulant les conditions réelles du concours.
            Ces examens couvrent toutes les matières pour préparer les candidats de façon globale.
          </>
        )}
      </div>

      {/* Filtre par matière (uniquement pour Examens Types) */}
      {activeTab === 'examen_type' && matieres.length > 0 && (
        <div style={{ display: 'flex', gap: 6, flexWrap: 'wrap', marginBottom: 20 }}>
          <FilterBtn active={filterMatiere === 'TOUS'} onClick={() => setFilterMatiere('TOUS')} label="Toutes" />
          {matieres.map((m: any) => (
            <FilterBtn key={m.id} active={filterMatiere === m.id} onClick={() => setFilterMatiere(m.id)} label={`${m.icone ?? '📚'} ${m.nom}`} />
          ))}
        </div>
      )}

      {/* Liste */}
      {filteredList.length === 0 ? (
        <EmptyState
          icon={activeTab === 'examen_type' ? '📚' : '📋'}
          message={activeTab === 'examen_type'
            ? 'Aucun examen type créé. Cliquez sur "Créer un Examen" pour commencer.'
            : 'Aucun examen blanc créé.'}
        />
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
          {filteredList.map((sim: any) => (
            <ExamCard
              key={sim.id}
              sim={sim}
              onDelete={() => handleDelete(sim.id, sim.titre)}
              onTogglePublish={() => togglePublish(sim)}
            />
          ))}
        </div>
      )}

      {/* Modal Créer */}
      {showCreate && (
        <div style={{
          position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)', zIndex: 100,
          display: 'flex', alignItems: 'center', justifyContent: 'center', padding: 16,
        }}>
          <div style={{
            background: '#1e293b', borderRadius: 16, padding: 32,
            width: '100%', maxWidth: 600, maxHeight: '90vh', overflowY: 'auto',
            border: '1px solid #334155',
          }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
              <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 700, margin: 0 }}>
                ✚ Créer un {activeTab === 'examen_blanc' ? 'Examen Blanc' : 'Examen Type'}
              </h3>
              <button onClick={() => setShowCreate(false)} style={{ background: 'none', border: 'none', color: '#94a3b8', cursor: 'pointer', fontSize: 20 }}>✕</button>
            </div>

            <form onSubmit={handleCreate}>
              {/* Titre */}
              <div style={{ marginBottom: 16 }}>
                <label style={labelStyle}>Titre *</label>
                <input
                  value={form.titre}
                  onChange={e => setForm(f => ({ ...f, titre: e.target.value }))}
                  placeholder={activeTab === 'examen_type' ? 'Ex: Mathématiques — Série 1 (2024)' : 'Ex: Examen Blanc N°1 — Session 2026'}
                  style={inputStyle}
                  required
                />
              </div>

              {/* Série label (pour examens types) */}
              {activeTab === 'examen_type' && (
                <div style={{ marginBottom: 16 }}>
                  <label style={labelStyle}>Série</label>
                  <select
                    value={form.serie_label}
                    onChange={e => setForm(f => ({ ...f, serie_label: e.target.value }))}
                    style={inputStyle}
                  >
                    <option value="Série 1">Série 1</option>
                    <option value="Série 2">Série 2</option>
                  </select>
                </div>
              )}

              {/* Description */}
              <div style={{ marginBottom: 16 }}>
                <label style={labelStyle}>Description (optionnel)</label>
                <textarea
                  value={form.description}
                  onChange={e => setForm(f => ({ ...f, description: e.target.value }))}
                  placeholder="Description de l'examen..."
                  rows={2}
                  style={{ ...inputStyle, resize: 'vertical' as const }}
                />
              </div>

              {/* Durée */}
              <div style={{ marginBottom: 16 }}>
                <label style={labelStyle}>Durée</label>
                <select value={form.duree_minutes} onChange={e => setForm(f => ({ ...f, duree_minutes: +e.target.value }))} style={inputStyle}>
                  {DUREES.map(d => <option key={d.value} value={d.value}>{d.label}</option>)}
                </select>
              </div>

              {/* Questions par matière */}
              <div style={{ marginBottom: 20 }}>
                <label style={labelStyle}>Questions par matière</label>
                <div style={{ color: '#475569', fontSize: 15, marginBottom: 10 }}>
                  Total sélectionné : <strong style={{ color: totalSelected > 0 ? '#4ade80' : '#94a3b8' }}>{totalSelected} question(s)</strong>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 8, maxHeight: 280, overflowY: 'auto' }}>
                  {form.config.map((c, i) => (
                    <div key={c.matiere_id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                      <span style={{ color: '#94a3b8', fontSize: 16, width: 200, flexShrink: 0 }}>{c.matiere_nom}</span>
                      <input
                        type="number" min="0" max="100"
                        value={c.count}
                        onChange={e => {
                          const newConfig = [...form.config];
                          newConfig[i] = { ...newConfig[i], count: Math.max(0, +e.target.value) };
                          setForm(f => ({ ...f, config: newConfig }));
                        }}
                        style={{ ...inputStyle, width: 80, padding: '6px 10px', textAlign: 'center' as const }}
                      />
                      <span style={{ color: '#475569', fontSize: 15 }}>questions</span>
                    </div>
                  ))}
                </div>
              </div>

              {/* Options */}
              <div style={{ display: 'flex', gap: 16, marginBottom: 20, flexWrap: 'wrap' }}>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, color: '#94a3b8', fontSize: 16, cursor: 'pointer' }}>
                  <input type="checkbox" checked={form.show_corrections} onChange={e => setForm(f => ({ ...f, show_corrections: e.target.checked }))} />
                  Afficher les corrections
                </label>
                <label style={{ display: 'flex', alignItems: 'center', gap: 8, color: '#94a3b8', fontSize: 16, cursor: 'pointer' }}>
                  <input type="checkbox" checked={form.show_score_after} onChange={e => setForm(f => ({ ...f, show_score_after: e.target.checked }))} />
                  Afficher le score
                </label>
              </div>

              <div style={{ display: 'flex', gap: 12 }}>
                <button type="button" onClick={() => setShowCreate(false)} style={{
                  flex: 1, padding: 12, background: '#334155', border: 'none',
                  borderRadius: 8, color: '#94a3b8', cursor: 'pointer', fontWeight: 600,
                }}>Annuler</button>
                <button type="submit" disabled={saving} style={{
                  flex: 2, padding: 12,
                  background: saving ? '#334155' : 'linear-gradient(135deg, #1A5C38, #2d9966)',
                  border: 'none', borderRadius: 8, color: 'white',
                  cursor: saving ? 'not-allowed' : 'pointer', fontWeight: 600,
                }}>
                  {saving ? '⏳ Création...' : '✅ Créer'}
                </button>
              </div>
            </form>
          </div>
        </div>
      )}

      {/* Toast */}
      {toast && (
        <div style={{
          position: 'fixed', bottom: 24, right: 24, background: toast.includes('❌') ? '#ef4444' : '#1A5C38',
          color: 'white', padding: '12px 20px', borderRadius: 10, fontSize: 17, fontWeight: 600,
          zIndex: 200, boxShadow: '0 4px 20px rgba(0,0,0,0.3)',
        }}>{toast}</div>
      )}
    </div>
  );
}

function ExamCard({ sim, onDelete, onTogglePublish }: { sim: any; onDelete: () => void; onTogglePublish: () => void }) {
  return (
    <div style={{
      background: '#1e293b', borderRadius: 12, padding: '16px 20px',
      border: sim.published ? '1px solid rgba(26,92,56,0.4)' : '1px solid #334155',
      display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap',
    }}>
      <div style={{ flex: 1, minWidth: 200 }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
          <span style={{ color: '#f1f5f9', fontWeight: 700, fontSize: 18 }}>{sim.titre}</span>
          {sim.serie_label && (
            <span style={{ background: 'rgba(59,130,246,0.15)', color: '#3b82f6', fontSize: 14, padding: '2px 8px', borderRadius: 12, fontWeight: 600 }}>
              {sim.serie_label}
            </span>
          )}
        </div>
        <div style={{ color: '#64748b', fontSize: 15, display: 'flex', gap: 12, flexWrap: 'wrap' }}>
          <span>⏱ {sim.duree_minutes} min</span>
          <span>📊 {sim.score_max ?? '?'} points</span>
          {sim.nb_questions && <span>❓ {sim.nb_questions} questions</span>}
          {sim.nb_passages && <span>👥 {sim.nb_passages} passages</span>}
        </div>
        {sim.description && <div style={{ color: '#475569', fontSize: 15, marginTop: 4 }}>{sim.description}</div>}
      </div>
      <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
        <span style={{
          padding: '6px 14px', borderRadius: 20, fontSize: 15, fontWeight: 700,
          background: sim.published ? 'rgba(74,222,128,0.15)' : 'rgba(100,116,139,0.15)',
          color: sim.published ? '#4ade80' : '#64748b',
        }}>
          {sim.published ? '✅ Publié' : '🔒 Masqué'}
        </span>
        <button
          onClick={onTogglePublish}
          style={{
            background: sim.published ? 'rgba(239,68,68,0.1)' : 'rgba(74,222,128,0.1)',
            border: `1px solid ${sim.published ? 'rgba(239,68,68,0.3)' : 'rgba(74,222,128,0.3)'}`,
            color: sim.published ? '#ef4444' : '#4ade80',
            padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontSize: 15, fontWeight: 600,
          }}
        >
          {sim.published ? '🔒 Masquer' : '✅ Publier'}
        </button>
        <button
          onClick={onDelete}
          style={{
            background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.2)',
            color: '#ef4444', padding: '6px 10px', borderRadius: 8, cursor: 'pointer', fontSize: 16,
          }}
        >
          🗑️
        </button>
      </div>
    </div>
  );
}

function TabBtn({ active, onClick, label, color }: { active: boolean; onClick: () => void; label: string; color: string }) {
  return (
    <button onClick={onClick} style={{
      padding: '8px 16px', borderRadius: 8, border: 'none', cursor: 'pointer',
      background: active ? color : 'transparent',
      color: active ? 'white' : '#64748b',
      fontSize: 16, fontWeight: active ? 600 : 400,
      transition: 'all 0.15s',
    }}>{label}</button>
  );
}

function FilterBtn({ active, onClick, label }: { active: boolean; onClick: () => void; label: string }) {
  return (
    <button onClick={onClick} style={{
      padding: '6px 14px', borderRadius: 16, border: 'none', cursor: 'pointer', fontSize: 15,
      background: active ? 'rgba(26,92,56,0.25)' : '#1e293b',
      color: active ? '#4ade80' : '#64748b', fontWeight: active ? 600 : 400,
    }}>{label}</button>
  );
}

function EmptyState({ icon, message }: { icon: string; message: string }) {
  return (
    <div style={{ textAlign: 'center', padding: 60, color: '#64748b', background: '#1e293b', borderRadius: 12 }}>
      <div style={{ fontSize: 48, marginBottom: 16 }}>{icon}</div>
      <div>{message}</div>
    </div>
  );
}

function LoadingSpinner() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 300 }}>
      <div style={{
        width: 40, height: 40, border: '3px solid #334155',
        borderTop: '3px solid #1A5C38', borderRadius: '50%',
        animation: 'spin 1s linear infinite',
      }} />
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}

const labelStyle: React.CSSProperties = {
  display: 'block', color: '#94a3b8', fontSize: 16, marginBottom: 6, fontWeight: 500,
};

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '10px 14px', background: '#0f172a',
  border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0',
  fontSize: 17, outline: 'none', boxSizing: 'border-box' as const,
};
