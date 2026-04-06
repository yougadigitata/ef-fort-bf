// ════════════════════════════════════════════════════════════════
// EXAMENS TYPES PAGE v3.0 — Gestion complète des examens types
// Créer, composer (auto ou manuel), gérer les examens types
// ════════════════════════════════════════════════════════════════
import { useState, useEffect } from 'react';
import { getMatieres, getSimulations, createSimulation, deleteSimulation, publishExamen, getQuestions } from '../api';
import { getToken } from '../api';
import type { Page } from '../App';

const S = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#e2e8f0',
  muted: '#64748b', green: '#1A5C38', gold: '#D4A017', blue: '#3b82f6',
  red: '#ef4444', purple: '#8b5cf6', cyan: '#06b6d4', orange: '#f59e0b',
  success: '#4ade80', input: '#0f172a',
};

const BASE_URL = typeof window !== 'undefined'
  ? (window.location.hostname === 'localhost'
      ? 'http://localhost:8787'
      : 'https://ef-fort-bf.yembuaro29.workers.dev')
  : 'https://ef-fort-bf.yembuaro29.workers.dev';

interface MatiereAlloc {
  matiereId: string;
  matiereName: string;
  count: number;
}

export default function ExamensTypesPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [matieres, setMatieres] = useState<any[]>([]);
  const [examens, setExamens] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');

  // Vue active
  const [activeView, setActiveView] = useState<'list' | 'create-auto' | 'create-manual' | 'detail'>('list');
  const [selectedExamen, setSelectedExamen] = useState<any>(null);

  // Formulaire création automatique
  const [autoForm, setAutoForm] = useState({
    titre: '', duree_minutes: '90', allocs: [] as MatiereAlloc[],
  });
  const [preview, setPreview] = useState<any[]>([]);
  const [previewing, setPreviewing] = useState(false);
  const [generating, setGenerating] = useState(false);

  // Formulaire création manuelle
  const [manualForm, setManualForm] = useState({
    titre: '', matiere_id: '', duree_minutes: '90', type_examen: 'TYPE',
  });
  const [manualMatiereQuestions, setManualMatiereQuestions] = useState<any[]>([]);
  const [selectedManualQIds, setSelectedManualQIds] = useState<Set<string>>(new Set());
  const [loadingManualQ, setLoadingManualQ] = useState(false);
  const [creatingManual, setCreatingManual] = useState(false);
  const [searchManual, setSearchManual] = useState('');

  // Filtre examens
  const [filterSearch, setFilterSearch] = useState('');

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [matRes, simRes] = await Promise.allSettled([getMatieres(), getSimulations()]);
      if (matRes.status === 'fulfilled') setMatieres(matRes.value.matieres ?? []);
      if (simRes.status === 'fulfilled') setExamens(simRes.value.simulations ?? simRes.value.examens ?? []);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setLoading(false); }
  }

  function showToast(msg: string, type: 'success' | 'error' = 'success') {
    setToast(msg); setToastType(type);
    setTimeout(() => setToast(''), 5000);
  }

  // ── Gestion allocs pour création auto ──────────────────────
  function addAlloc(mat: any) {
    if (autoForm.allocs.find(a => a.matiereId === mat.id)) return;
    setAutoForm(f => ({
      ...f, allocs: [...f.allocs, { matiereId: mat.id, matiereName: mat.nom, count: 10 }],
    }));
  }
  function removeAlloc(matiereId: string) {
    setAutoForm(f => ({ ...f, allocs: f.allocs.filter(a => a.matiereId !== matiereId) }));
  }
  function updateAllocCount(matiereId: string, count: number) {
    setAutoForm(f => ({
      ...f, allocs: f.allocs.map(a => a.matiereId === matiereId ? { ...a, count: Math.max(1, count) } : a),
    }));
  }
  const totalAuto = autoForm.allocs.reduce((s, a) => s + a.count, 0);

  // ── Prévisualiser l'examen auto ─────────────────────────────
  async function handlePreview() {
    if (autoForm.allocs.length === 0) { showToast('⚠️ Ajoutez au moins une matière', 'error'); return; }
    setPreviewing(true);
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/admin-cms/exam-generator/preview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ allocations: autoForm.allocs.map(a => ({ matiere_id: a.matiereId, count: a.count })) }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Erreur preview');
      setPreview(data.questions ?? []);
      showToast(`✅ ${data.questions?.length ?? 0} questions prêtes pour la prévisualisation`);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setPreviewing(false); }
  }

  // ── Générer l'examen auto ───────────────────────────────────
  async function handleGenerate() {
    if (!autoForm.titre.trim()) { showToast('⚠️ Titre requis', 'error'); return; }
    if (autoForm.allocs.length === 0) { showToast('⚠️ Ajoutez au moins une matière', 'error'); return; }
    setGenerating(true);
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/admin-cms/exam-generator/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({
          titre: autoForm.titre.trim(),
          duree_minutes: parseInt(autoForm.duree_minutes) || 90,
          destination: 'simulation',
          allocations: autoForm.allocs.map(a => ({ matiere_id: a.matiereId, count: a.count })),
        }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Erreur génération');
      showToast(`✅ Examen "${autoForm.titre}" créé avec ${data.total_questions ?? totalAuto} questions !`);
      setAutoForm({ titre: '', duree_minutes: '90', allocs: [] });
      setPreview([]);
      setActiveView('list');
      loadData();
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setGenerating(false); }
  }

  // ── Charger questions pour création manuelle ────────────────
  async function loadManualQuestions(matiereId: string) {
    if (!matiereId) return;
    setLoadingManualQ(true);
    setManualMatiereQuestions([]);
    setSelectedManualQIds(new Set());
    try {
      const data = await getQuestions({ matiere_id: matiereId, limit: 500 });
      setManualMatiereQuestions(data.questions ?? []);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setLoadingManualQ(false); }
  }

  function toggleManualQ(id: string) {
    setSelectedManualQIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id); else next.add(id);
      return next;
    });
  }

  function selectAllManual() {
    const filtered = manualMatiereQuestions.filter(q => !searchManual || q.enonce?.toLowerCase().includes(searchManual.toLowerCase()));
    setSelectedManualQIds(new Set(filtered.map((q: any) => q.id as string)));
  }

  // ── Créer examen manuel ─────────────────────────────────────
  async function handleCreateManual(e: React.FormEvent) {
    e.preventDefault();
    if (!manualForm.titre.trim()) { showToast('⚠️ Titre requis', 'error'); return; }
    if (selectedManualQIds.size === 0) { showToast('⚠️ Sélectionnez au moins une question', 'error'); return; }
    if (!confirm(`Créer l'examen "${manualForm.titre}" avec ${selectedManualQIds.size} questions ?`)) return;
    setCreatingManual(true);
    try {
      await createSimulation({
        titre: manualForm.titre.trim(),
        duree_minutes: parseInt(manualForm.duree_minutes) || 90,
        question_ids: Array.from(selectedManualQIds),
        type_examen: manualForm.type_examen || 'TYPE',
        matiere_id: manualForm.matiere_id || undefined,
      });
      showToast(`✅ Examen créé avec ${selectedManualQIds.size} questions !`);
      setManualForm({ titre: '', matiere_id: '', duree_minutes: '90', type_examen: 'TYPE' });
      setSelectedManualQIds(new Set());
      setManualMatiereQuestions([]);
      setActiveView('list');
      loadData();
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setCreatingManual(false); }
  }

  // ── Supprimer un examen ─────────────────────────────────────
  async function handleDeleteExamen(exam: any) {
    if (!confirm(`Supprimer l'examen "${exam.titre}" ? Cette action est irréversible.`)) return;
    try {
      await deleteSimulation(exam.id);
      showToast('✅ Examen supprimé');
      loadData();
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
  }

  // ── Publier/Dépublier un examen ─────────────────────────────
  async function handleTogglePublish(exam: any) {
    try {
      await publishExamen(exam.id, !exam.published);
      showToast(`✅ Examen ${!exam.published ? 'publié' : 'dépublié'}`);
      loadData();
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
  }

  const filteredExamens = filterSearch
    ? examens.filter(e => e.titre?.toLowerCase().includes(filterSearch.toLowerCase()))
    : examens;

  const filteredManualQ = searchManual
    ? manualMatiereQuestions.filter(q => q.enonce?.toLowerCase().includes(searchManual.toLowerCase()))
    : manualMatiereQuestions;

  // ════════════════════════════════════════════════════════════
  // RENDU
  // ════════════════════════════════════════════════════════════
  return (
    <div style={{ minHeight: '100vh' }}>
      {toast && (
        <div style={{
          position: 'fixed', top: 70, right: 20, padding: '12px 20px',
          background: toastType === 'success' ? '#065f46' : '#7f1d1d',
          border: `1px solid ${toastType === 'success' ? S.success : S.red}`,
          borderRadius: 10, color: '#fff', fontSize: 14, zIndex: 9999,
          boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
        }}>{toast}</div>
      )}

      {/* Header + Navigation */}
      <div style={{ marginBottom: 20 }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', flexWrap: 'wrap', gap: 12 }}>
          <div>
            <h2 style={{ color: S.text, fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
              🎯 Examens Types
            </h2>
            <p style={{ color: S.muted, fontSize: 13 }}>
              {examens.length} examen(s) — Créez des examens composés automatiquement ou manuellement
            </p>
          </div>
          {activeView === 'list' && (
            <div style={{ display: 'flex', gap: 10 }}>
              <button onClick={() => setActiveView('create-auto')} style={{
                background: S.green, color: '#fff', border: 'none', borderRadius: 8,
                padding: '9px 16px', fontSize: 13, cursor: 'pointer', fontWeight: 600,
              }}>🤖 Créer automatiquement</button>
              <button onClick={() => setActiveView('create-manual')} style={{
                background: S.blue, color: '#fff', border: 'none', borderRadius: 8,
                padding: '9px 16px', fontSize: 13, cursor: 'pointer', fontWeight: 600,
              }}>✋ Sélection manuelle</button>
            </div>
          )}
          {activeView !== 'list' && (
            <button onClick={() => { setActiveView('list'); setPreview([]); }} style={{
              background: S.card, color: S.text, border: `1px solid ${S.border}`,
              borderRadius: 8, padding: '8px 16px', fontSize: 13, cursor: 'pointer',
            }}>← Retour à la liste</button>
          )}
        </div>
      </div>

      {/* ══ VUE : LISTE ════════════════════════════════════════ */}
      {activeView === 'list' && (
        <div>
          <div style={{ marginBottom: 16 }}>
            <input value={filterSearch} onChange={e => setFilterSearch(e.target.value)}
              placeholder="🔍 Rechercher un examen…"
              style={{ ...inputStyle, maxWidth: 340 }} />
          </div>

          {loading ? (
            <div style={{ padding: 40, textAlign: 'center', color: S.muted }}>⏳ Chargement…</div>
          ) : filteredExamens.length === 0 ? (
            <div style={{ background: S.card, borderRadius: 12, padding: 40, textAlign: 'center', border: `1px solid ${S.border}` }}>
              <div style={{ fontSize: 40, marginBottom: 12 }}>🎯</div>
              <div style={{ color: S.muted, fontSize: 15 }}>Aucun examen type créé</div>
              <div style={{ marginTop: 16, display: 'flex', justifyContent: 'center', gap: 10 }}>
                <button onClick={() => setActiveView('create-auto')} style={btnPrimary}>🤖 Créer automatiquement</button>
                <button onClick={() => setActiveView('create-manual')} style={{ ...btnPrimary, background: S.blue }}>✋ Sélection manuelle</button>
              </div>
            </div>
          ) : (
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(320px, 1fr))', gap: 14 }}>
              {filteredExamens.map(exam => (
                <div key={exam.id} style={{
                  background: S.card, borderRadius: 12, border: `1px solid ${S.border}`,
                  overflow: 'hidden', transition: 'border-color 0.2s',
                }}>
                  <div style={{
                    padding: '12px 16px', background: '#0f172a',
                    borderBottom: `1px solid ${S.border}`,
                    display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                  }}>
                    <div style={{
                      padding: '3px 8px', borderRadius: 5, fontSize: 11, fontWeight: 700,
                      background: exam.published ? '#065f46' : '#374151',
                      color: exam.published ? S.success : S.muted,
                    }}>
                      {exam.published ? '🟢 Publié' : '⚪ Brouillon'}
                    </div>
                    <div style={{ color: S.muted, fontSize: 11 }}>
                      {exam.type_examen || 'TYPE'}
                    </div>
                  </div>
                  <div style={{ padding: '14px 16px' }}>
                    <div style={{ color: S.text, fontWeight: 700, fontSize: 14, marginBottom: 8, lineHeight: 1.3 }}>
                      {exam.titre}
                    </div>
                    <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap', marginBottom: 12 }}>
                      <span style={{ color: S.muted, fontSize: 12 }}>
                        ❓ {exam.nb_questions ?? exam.question_ids?.length ?? '?'} questions
                      </span>
                      <span style={{ color: S.muted, fontSize: 12 }}>
                        ⏱ {exam.duree_minutes ?? 90} min
                      </span>
                      {exam.matiere_nom && (
                        <span style={{ color: S.muted, fontSize: 12 }}>📚 {exam.matiere_nom}</span>
                      )}
                    </div>
                    <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                      <button
                        onClick={() => handleTogglePublish(exam)}
                        style={{
                          background: exam.published ? '#374151' : '#065f46',
                          color: '#fff', border: 'none', borderRadius: 6,
                          padding: '5px 10px', fontSize: 11, cursor: 'pointer',
                        }}>
                        {exam.published ? '⏸ Dépublier' : '▶ Publier'}
                      </button>
                      <button
                        onClick={() => { setSelectedExamen(exam); setActiveView('detail'); }}
                        style={{ background: S.blue, color: '#fff', border: 'none', borderRadius: 6, padding: '5px 10px', fontSize: 11, cursor: 'pointer' }}>
                        👁 Détails
                      </button>
                      <button
                        onClick={() => handleDeleteExamen(exam)}
                        style={{ background: '#7f1d1d', color: '#fff', border: 'none', borderRadius: 6, padding: '5px 10px', fontSize: 11, cursor: 'pointer' }}>
                        🗑 Supprimer
                      </button>
                    </div>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {/* ══ VUE : CRÉER AUTO ═══════════════════════════════════ */}
      {activeView === 'create-auto' && (
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 20 }}>
          <div>
            {/* Titre + durée */}
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 20, marginBottom: 16 }}>
              <h3 style={{ color: S.text, fontSize: 15, fontWeight: 700, marginBottom: 16 }}>
                🤖 Création automatique d'examen
              </h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div>
                  <label style={labelStyle}>Titre de l'examen *</label>
                  <input value={autoForm.titre} onChange={e => setAutoForm(f => ({ ...f, titre: e.target.value }))}
                    placeholder="Ex : Examen Blanc N°1 — ADJEP 2026" style={inputStyle} />
                </div>
                <div>
                  <label style={labelStyle}>Durée (minutes)</label>
                  <input type="number" value={autoForm.duree_minutes}
                    onChange={e => setAutoForm(f => ({ ...f, duree_minutes: e.target.value }))} style={inputStyle} />
                </div>
              </div>
            </div>

            {/* Sélection matières */}
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
              <div style={{ padding: '12px 16px', background: '#0f172a', borderBottom: `1px solid ${S.border}` }}>
                <div style={{ color: S.text, fontWeight: 700, fontSize: 14 }}>
                  📚 Matières sources — Total : {totalAuto} questions
                </div>
                <div style={{ color: S.muted, fontSize: 12, marginTop: 4 }}>
                  Cliquez sur une matière pour l'ajouter à l'examen
                </div>
              </div>
              <div style={{ maxHeight: 300, overflowY: 'auto' }}>
                {matieres.map(m => {
                  const existing = autoForm.allocs.find(a => a.matiereId === m.id);
                  return (
                    <div key={m.id} style={{
                      padding: '10px 16px', borderBottom: `1px solid #1e293b`,
                      display: 'flex', justifyContent: 'space-between', alignItems: 'center',
                      background: existing ? '#0f2a1a' : 'transparent', cursor: 'pointer',
                    }} onClick={() => !existing && addAlloc(m)}>
                      <div>
                        <div style={{ color: S.text, fontSize: 13 }}>{m.nom}</div>
                        <div style={{ color: S.muted, fontSize: 11 }}>{m.total_questions ?? '?'} questions dispo</div>
                      </div>
                      {existing ? (
                        <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                          <div style={{ display: 'flex', alignItems: 'center', gap: 4 }}>
                            <button onClick={e => { e.stopPropagation(); updateAllocCount(m.id, existing.count - 5); }}
                              style={{ background: '#374151', color: '#fff', border: 'none', borderRadius: 4, padding: '2px 7px', cursor: 'pointer', fontSize: 14 }}>−</button>
                            <span style={{ color: S.success, fontWeight: 700, fontSize: 14, minWidth: 28, textAlign: 'center' }}>{existing.count}</span>
                            <button onClick={e => { e.stopPropagation(); updateAllocCount(m.id, existing.count + 5); }}
                              style={{ background: '#374151', color: '#fff', border: 'none', borderRadius: 4, padding: '2px 7px', cursor: 'pointer', fontSize: 14 }}>+</button>
                          </div>
                          <button onClick={e => { e.stopPropagation(); removeAlloc(m.id); }}
                            style={{ background: '#7f1d1d', color: '#fff', border: 'none', borderRadius: 4, padding: '2px 7px', cursor: 'pointer', fontSize: 11 }}>✕</button>
                        </div>
                      ) : (
                        <span style={{ color: S.green, fontSize: 18 }}>+</span>
                      )}
                    </div>
                  );
                })}
              </div>
            </div>

            {/* Boutons */}
            <div style={{ display: 'flex', gap: 10, marginTop: 16 }}>
              <button onClick={handlePreview} disabled={previewing || autoForm.allocs.length === 0}
                style={{ ...btnSecondary, flex: 1 }}>
                {previewing ? '⏳ Chargement…' : '👁 Prévisualiser'}
              </button>
              <button onClick={handleGenerate} disabled={generating || !autoForm.titre.trim() || autoForm.allocs.length === 0}
                style={{ ...btnPrimary, flex: 1 }}>
                {generating ? '⏳ Génération…' : `✅ Créer (${totalAuto} questions)`}
              </button>
            </div>
          </div>

          {/* Prévisualisation */}
          <div>
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
              <div style={{ padding: '12px 16px', background: '#0f172a', borderBottom: `1px solid ${S.border}` }}>
                <div style={{ color: S.text, fontWeight: 700, fontSize: 14 }}>
                  👁 Prévisualisation ({preview.length} questions)
                </div>
              </div>
              {preview.length === 0 ? (
                <div style={{ padding: 40, textAlign: 'center', color: S.muted, fontSize: 13 }}>
                  Configurez l'examen et cliquez sur « Prévisualiser »
                </div>
              ) : (
                <div style={{ maxHeight: 520, overflowY: 'auto' }}>
                  {preview.slice(0, 20).map((q, i) => (
                    <div key={q.id} style={{ padding: '10px 14px', borderBottom: `1px solid #1e293b` }}>
                      <div style={{ color: S.muted, fontSize: 10, marginBottom: 3 }}>#{i + 1} · {q.matiere_nom || q.matiere}</div>
                      <div style={{ color: S.text, fontSize: 12, lineHeight: 1.4 }}>
                        {q.enonce?.substring(0, 100)}{q.enonce?.length > 100 ? '…' : ''}
                      </div>
                      <div style={{ color: S.success, fontSize: 10, marginTop: 3 }}>→ {q.bonne_reponse}</div>
                    </div>
                  ))}
                  {preview.length > 20 && (
                    <div style={{ padding: 10, textAlign: 'center', color: S.muted, fontSize: 12 }}>
                      … et {preview.length - 20} autres questions
                    </div>
                  )}
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* ══ VUE : CRÉER MANUEL ═════════════════════════════════ */}
      {activeView === 'create-manual' && (
        <form onSubmit={handleCreateManual}>
          <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: 16 }}>
            {/* Panneau gauche : config */}
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 20 }}>
              <h3 style={{ color: S.text, fontSize: 15, fontWeight: 700, marginBottom: 16 }}>✋ Sélection manuelle</h3>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
                <div>
                  <label style={labelStyle}>Titre de l'examen *</label>
                  <input value={manualForm.titre} onChange={e => setManualForm(f => ({ ...f, titre: e.target.value }))}
                    placeholder="Ex : Examen Type — Série 1" style={inputStyle} />
                </div>
                <div>
                  <label style={labelStyle}>Matière source</label>
                  <select value={manualForm.matiere_id} onChange={e => {
                    setManualForm(f => ({ ...f, matiere_id: e.target.value }));
                    loadManualQuestions(e.target.value);
                  }} style={inputStyle}>
                    <option value="">— Sélectionner une matière —</option>
                    {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
                  </select>
                </div>
                <div>
                  <label style={labelStyle}>Durée (min)</label>
                  <input type="number" value={manualForm.duree_minutes}
                    onChange={e => setManualForm(f => ({ ...f, duree_minutes: e.target.value }))} style={inputStyle} />
                </div>
                <div>
                  <label style={labelStyle}>Type</label>
                  <select value={manualForm.type_examen} onChange={e => setManualForm(f => ({ ...f, type_examen: e.target.value }))} style={inputStyle}>
                    <option value="TYPE">Examen Type</option>
                    <option value="BLANC">Examen Blanc</option>
                    <option value="SIMULATION">Simulation</option>
                  </select>
                </div>
                <div style={{ background: '#0f172a', borderRadius: 8, padding: 12, border: `1px solid ${S.border}` }}>
                  <div style={{ color: S.success, fontWeight: 700, fontSize: 16 }}>{selectedManualQIds.size}</div>
                  <div style={{ color: S.muted, fontSize: 12 }}>questions sélectionnées</div>
                </div>
                <button type="submit" disabled={creatingManual || selectedManualQIds.size === 0}
                  style={{ ...btnPrimary, opacity: selectedManualQIds.size === 0 ? 0.5 : 1 }}>
                  {creatingManual ? '⏳ Création…' : `✅ Créer l'examen (${selectedManualQIds.size})`}
                </button>
              </div>
            </div>

            {/* Panneau droit : liste questions */}
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
              <div style={{ padding: '12px 16px', background: '#0f172a', borderBottom: `1px solid ${S.border}` }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 10 }}>
                  <div style={{ color: S.text, fontWeight: 700, fontSize: 14 }}>
                    Questions disponibles ({filteredManualQ.length})
                  </div>
                  {manualMatiereQuestions.length > 0 && (
                    <button type="button" onClick={selectAllManual} style={{ ...btnSecondary, fontSize: 11, padding: '4px 10px' }}>
                      Tout sélectionner
                    </button>
                  )}
                </div>
                <input value={searchManual} onChange={e => setSearchManual(e.target.value)}
                  placeholder="🔍 Filtrer les questions…" style={inputStyle} />
              </div>
              {!manualForm.matiere_id ? (
                <div style={{ padding: 40, textAlign: 'center', color: S.muted, fontSize: 13 }}>
                  ← Choisissez une matière pour voir les questions
                </div>
              ) : loadingManualQ ? (
                <div style={{ padding: 40, textAlign: 'center', color: S.muted }}>⏳ Chargement…</div>
              ) : filteredManualQ.length === 0 ? (
                <div style={{ padding: 40, textAlign: 'center', color: S.muted, fontSize: 13 }}>
                  Aucune question trouvée
                </div>
              ) : (
                <div style={{ maxHeight: 520, overflowY: 'auto' }}>
                  {filteredManualQ.map((q, i) => {
                    const checked = selectedManualQIds.has(q.id);
                    return (
                      <div key={q.id} onClick={() => toggleManualQ(q.id)} style={{
                        padding: '10px 16px', borderBottom: `1px solid #1e293b`,
                        display: 'flex', gap: 12, alignItems: 'flex-start', cursor: 'pointer',
                        background: checked ? '#0f2a1a' : 'transparent',
                        borderLeft: checked ? `3px solid ${S.success}` : '3px solid transparent',
                      }}>
                        <div style={{
                          width: 18, height: 18, borderRadius: 4, flexShrink: 0, marginTop: 2,
                          background: checked ? S.green : '#374151',
                          border: `2px solid ${checked ? S.success : S.border}`,
                          display: 'flex', alignItems: 'center', justifyContent: 'center',
                        }}>
                          {checked && <span style={{ color: '#fff', fontSize: 11 }}>✓</span>}
                        </div>
                        <div style={{ flex: 1 }}>
                          <div style={{ color: S.muted, fontSize: 10, marginBottom: 2 }}>#{i + 1} · {q.difficulte}</div>
                          <div style={{ color: S.text, fontSize: 12, lineHeight: 1.4 }}>
                            {q.enonce?.substring(0, 120)}{q.enonce?.length > 120 ? '…' : ''}
                          </div>
                          <div style={{ color: S.success, fontSize: 10, marginTop: 3 }}>→ Réponse : {q.bonne_reponse}</div>
                        </div>
                      </div>
                    );
                  })}
                </div>
              )}
            </div>
          </div>
        </form>
      )}

      {/* ══ VUE : DÉTAILS ══════════════════════════════════════ */}
      {activeView === 'detail' && selectedExamen && (
        <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
          <div style={{ padding: '16px 20px', background: '#0f172a', borderBottom: `1px solid ${S.border}` }}>
            <h3 style={{ color: S.text, fontSize: 16, fontWeight: 700, margin: 0 }}>{selectedExamen.titre}</h3>
            <div style={{ color: S.muted, fontSize: 13, marginTop: 6 }}>
              ❓ {selectedExamen.nb_questions ?? '?'} questions ·
              ⏱ {selectedExamen.duree_minutes ?? 90} min ·
              {selectedExamen.published ? '🟢 Publié' : '⚪ Brouillon'}
            </div>
          </div>
          <div style={{ padding: 20, textAlign: 'center', color: S.muted }}>
            <div style={{ fontSize: 40, marginBottom: 12 }}>📋</div>
            <p>Les détails complets de cet examen sont gérés via l'onglet <strong style={{ color: S.text }}>Simulations</strong>.</p>
            <button onClick={() => setActiveView('list')} style={{ ...btnPrimary, marginTop: 16 }}>
              ← Retour
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Styles utilitaires ──────────────────────────────────────────
const inputStyle: React.CSSProperties = {
  width: '100%', padding: '8px 12px', background: '#0f172a',
  border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0',
  fontSize: 13, boxSizing: 'border-box',
};

const labelStyle: React.CSSProperties = {
  display: 'block', color: '#94a3b8', fontSize: 12, fontWeight: 600, marginBottom: 5,
};

const btnPrimary: React.CSSProperties = {
  background: '#1A5C38', color: '#fff', border: 'none', borderRadius: 7,
  padding: '8px 18px', fontSize: 13, cursor: 'pointer', fontWeight: 600,
};

const btnSecondary: React.CSSProperties = {
  background: '#1e293b', color: '#e2e8f0', border: '1px solid #334155',
  borderRadius: 7, padding: '8px 18px', fontSize: 13, cursor: 'pointer',
};
