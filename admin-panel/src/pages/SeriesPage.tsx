import { useState, useEffect } from 'react';
import { getSeries, getMatieres, createSerie, updateSerie, deleteSerie, autoGenerateSerie, harmonizeSeries, getQuestions } from '../api';
import type { Page } from '../App';

// ════════════════════════════════════════════════════════════════
// SERIES PAGE v4.0 — Sélection manuelle OU auto de questions
// L'admin choisit les questions manuellement pour créer une série
// ════════════════════════════════════════════════════════════════

export default function SeriesPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [series, setSeries] = useState<any[]>([]);
  const [matieres, setMatieres] = useState<any[]>([]);
  const [selectedMatiere, setSelectedMatiere] = useState('');
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');
  const [showCreate, setShowCreate] = useState(false);
  const [showQuestionPicker, setShowQuestionPicker] = useState(false);
  const [availableQuestions, setAvailableQuestions] = useState<any[]>([]);
  const [selectedQuestionIds, setSelectedQuestionIds] = useState<Set<string>>(new Set());
  const [loadingQuestions, setLoadingQuestions] = useState(false);
  const [questionSearch, setQuestionSearch] = useState('');
  const [form, setForm] = useState({
    titre: '', matiere_id: '', numero: '', niveau: 'INTERMEDIAIRE', duree_minutes: '15'
  });

  useEffect(() => { loadMatieres(); }, []);
  useEffect(() => { if (selectedMatiere) loadSeries(); }, [selectedMatiere]);

  async function loadMatieres() {
    try {
      const data = await getMatieres();
      setMatieres(data.matieres ?? []);
    } catch (_) {}
  }

  async function loadSeries() {
    if (!selectedMatiere) return;
    setLoading(true);
    try {
      const mat = matieres.find(m => m.id === selectedMatiere);
      const data = await getSeries({ matiere: mat?.code, matiere_id: selectedMatiere });
      setSeries(data.series ?? []);
    } catch (err: any) { showToast('❌ ' + err.message, 'error'); }
    finally { setLoading(false); }
  }

  async function loadQuestionsForPicker(matiereId: string) {
    setLoadingQuestions(true);
    setShowQuestionPicker(true);
    try {
      // Charger toutes les questions de la matière sélectionnée
      const data = await getQuestions({ matiere_id: matiereId, limit: 500 });
      setAvailableQuestions(data.questions ?? []);
    } catch (err: any) {
      showToast('❌ Erreur chargement questions: ' + err.message, 'error');
    } finally {
      setLoadingQuestions(false);
    }
  }

  function showToast(msg: string, type: 'success' | 'error' = 'success') {
    setToast(msg);
    setToastType(type);
    setTimeout(() => setToast(''), 4000);
  }

  function toggleQuestion(id: string) {
    setSelectedQuestionIds(prev => {
      const next = new Set(prev);
      if (next.has(id)) next.delete(id);
      else next.add(id);
      return next;
    });
  }

  function selectAll() {
    const filtered = availableQuestions.filter(q =>
      !questionSearch || q.enonce?.toLowerCase().includes(questionSearch.toLowerCase())
    );
    const allIds = new Set(filtered.map((q: any) => q.id as string));
    setSelectedQuestionIds(allIds);
  }

  function deselectAll() {
    setSelectedQuestionIds(new Set());
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    const matiereTarget = form.matiere_id || selectedMatiere;
    if (!form.titre.trim()) { showToast('⚠️ Titre requis', 'error'); return; }
    if (!matiereTarget) { showToast('⚠️ Matière requise', 'error'); return; }

    const questionIds = Array.from(selectedQuestionIds);

    try {
      const payload: any = {
        titre: form.titre.trim(),
        matiere_id: matiereTarget,
        numero: form.numero ? parseInt(form.numero) : undefined,
        niveau: form.niveau,
        duree_minutes: parseInt(form.duree_minutes) || 15,
      };
      if (questionIds.length > 0) {
        payload.question_ids = questionIds;
      }
      const data = await createSerie(payload);
      showToast(`✅ Série "${form.titre}" créée avec ${questionIds.length} questions !`);
      setShowCreate(false);
      setShowQuestionPicker(false);
      setSelectedQuestionIds(new Set());
      setForm({ titre: '', matiere_id: '', numero: '', niveau: 'INTERMEDIAIRE', duree_minutes: '15' });
      loadSeries();
    } catch (err: any) { showToast('❌ ' + err.message, 'error'); }
  }

  async function handleAutoGenerate() {
    if (!selectedMatiere) { showToast('⚠️ Sélectionner une matière d\'abord', 'error'); return; }
    if (!confirm('Créer une série automatique de 20 questions non assignées pour cette matière ?')) return;
    try {
      const data = await autoGenerateSerie(selectedMatiere, 20);
      showToast(`✅ Série auto créée avec ${data.questions_used} questions assignées automatiquement`);
      loadSeries();
    } catch (err: any) { showToast('❌ ' + err.message, 'error'); }
  }

  async function handleHarmonize() {
    if (!selectedMatiere) { showToast('⚠️ Sélectionner une matière d\'abord', 'error'); return; }
    const mat = matieres.find(m => m.id === selectedMatiere);
    if (!confirm(`⚠️ HARMONISER les séries de "${mat?.nom ?? 'cette matière'}" ?\n\nCeci va :\n✅ Redistribuer TOUTES les questions en séries de 20 exactement\n✅ Supprimer les séries vides ou incomplètes\n✅ Renuméroter les séries de 01 à N\n\n⚠️ Cette opération est irréversible. Continuer ?`)) return;
    try {
      const data = await harmonizeSeries(selectedMatiere);
      showToast(`✅ ${data.series_created} séries harmonisées — ${data.total_questions} questions redistribuées`);
      loadSeries();
    } catch (err: any) { showToast('❌ ' + err.message, 'error'); }
  }

  async function handleDelete(id: string) {
    if (!confirm('Supprimer cette série ? (les questions seront libérées mais pas supprimées)')) return;
    try {
      await deleteSerie(id, 'keep');
      showToast('✅ Série supprimée. Questions libérées.');
      setSeries(s => s.filter(x => x.id !== id));
    } catch (err: any) { showToast('❌ ' + err.message, 'error'); }
  }

  async function handleToggle(s: any) {
    try {
      await updateSerie(s.id, { actif: !s.actif });
      setSeries(prev => prev.map(x => x.id === s.id ? { ...x, actif: !s.actif } : x));
      showToast(s.actif ? '✅ Série masquée (invisible pour les utilisateurs)' : '✅ Série publiée — Visible maintenant !');
    } catch (err: any) { showToast('❌ ' + err.message, 'error'); }
  }

  const filteredQuestions = availableQuestions.filter(q =>
    !questionSearch || q.enonce?.toLowerCase().includes(questionSearch.toLowerCase())
  );

  return (
    <div>
      {toast && (
        <div style={{
          position: 'fixed', top: 70, right: 20, padding: '12px 18px',
          background: toastType === 'error' ? '#7f1d1d' : '#1e293b',
          border: `1px solid ${toastType === 'error' ? '#dc2626' : '#334155'}`,
          borderRadius: 8, color: '#e2e8f0', fontSize: 14, zIndex: 1000,
          boxShadow: '0 4px 20px rgba(0,0,0,0.3)', maxWidth: 380,
        }}>{toast}</div>
      )}

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 20 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700, marginBottom: 4 }}>📚 Gestion des séries QCM</h2>
          <p style={{ color: '#64748b', fontSize: 13 }}>
            {series.length} série(s) {selectedMatiere ? 'pour cette matière' : ''}
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap', justifyContent: 'flex-end' }}>
          <button
            onClick={handleAutoGenerate}
            disabled={!selectedMatiere}
            title="Créer automatiquement une série avec 20 questions non assignées"
            style={{
              padding: '8px 14px', background: selectedMatiere ? '#3b82f6' : '#334155',
              border: 'none', borderRadius: 8, color: 'white',
              cursor: selectedMatiere ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600,
            }}
          >
            🤖 Série auto (20Q)
          </button>
          <button
            onClick={handleHarmonize}
            disabled={!selectedMatiere}
            title="Redistribuer toutes les questions en séries de 20 exactement (supprime doublons/séries incomplètes)"
            style={{
              padding: '8px 14px',
              background: selectedMatiere ? 'linear-gradient(135deg, #d97706, #f59e0b)' : '#334155',
              border: 'none', borderRadius: 8, color: 'white',
              cursor: selectedMatiere ? 'pointer' : 'not-allowed', fontSize: 13, fontWeight: 600,
            }}
          >
            ⚡ Harmoniser séries
          </button>
          <button
            onClick={() => { setShowCreate(true); setShowQuestionPicker(false); setSelectedQuestionIds(new Set()); }}
            style={{ padding: '8px 14px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontSize: 13, fontWeight: 700 }}
          >
            ✚ Créer série (manuel)
          </button>
        </div>
      </div>

      {/* Info box */}
      <div style={{ background: 'rgba(59,130,246,0.08)', border: '1px solid rgba(59,130,246,0.2)', borderRadius: 10, padding: '10px 14px', marginBottom: 16 }}>
        <p style={{ color: '#93c5fd', fontSize: 13, margin: 0 }}>
          💡 <strong>Comment créer une série :</strong> Sélectionnez une matière → Cliquez "Créer série (manuel)" → Choisissez les questions dans le sélecteur → Sauvegardez. 
          La série sera <strong>immédiatement visible</strong> par les utilisateurs dans la matière désignée.
        </p>
      </div>

      {/* Filtre matière */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 16, marginBottom: 20, border: '1px solid #334155' }}>
        <label style={lbl}>Filtrer par matière</label>
        <select
          value={selectedMatiere}
          onChange={e => setSelectedMatiere(e.target.value)}
          style={{ ...sel, minWidth: 260 }}
        >
          <option value="">Sélectionner une matière...</option>
          {matieres.map(m => <option key={m.id} value={m.id}>{m.nom} ({m.code})</option>)}
        </select>
      </div>

      {/* Formulaire création */}
      {showCreate && (
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, border: '1px solid #1A5C38', marginBottom: 20 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 700, marginBottom: 16 }}>✚ Créer une série QCM</h3>
          <form onSubmit={handleCreate}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
              <div>
                <label style={lbl}>Titre de la série *</label>
                <input
                  value={form.titre}
                  onChange={e => setForm(f => ({ ...f, titre: e.target.value }))}
                  placeholder="Ex: Série 5 — Droit Constitutional"
                  required
                  style={{ ...inp, width: '100%' }}
                />
              </div>
              <div>
                <label style={lbl}>Matière *</label>
                <select
                  value={form.matiere_id || selectedMatiere}
                  onChange={e => {
                    setForm(f => ({ ...f, matiere_id: e.target.value }));
                    if (e.target.value) loadQuestionsForPicker(e.target.value);
                  }}
                  required
                  style={{ ...sel, width: '100%' }}
                >
                  <option value="">Sélectionner...</option>
                  {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
                </select>
              </div>
              <div>
                <label style={lbl}>Numéro (auto si vide)</label>
                <input
                  type="number"
                  value={form.numero}
                  onChange={e => setForm(f => ({ ...f, numero: e.target.value }))}
                  placeholder="Auto"
                  min="1"
                  style={{ ...inp, width: '100%' }}
                />
              </div>
              <div>
                <label style={lbl}>Durée (minutes)</label>
                <input
                  type="number"
                  value={form.duree_minutes}
                  onChange={e => setForm(f => ({ ...f, duree_minutes: e.target.value }))}
                  min="5"
                  style={{ ...inp, width: '100%' }}
                />
              </div>
            </div>

            {/* Sélecteur de questions */}
            {(form.matiere_id || selectedMatiere) && (
              <div style={{ marginBottom: 16 }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 8 }}>
                  <label style={{ ...lbl, margin: 0 }}>
                    Questions sélectionnées : <span style={{ color: '#4ade80', fontWeight: 700 }}>{selectedQuestionIds.size}</span>
                    {availableQuestions.length > 0 && <span style={{ color: '#64748b' }}> / {availableQuestions.length} disponibles</span>}
                  </label>
                  <div style={{ display: 'flex', gap: 6 }}>
                    <button
                      type="button"
                      onClick={() => setShowQuestionPicker(!showQuestionPicker)}
                      style={{ padding: '5px 12px', background: '#3b82f6', border: 'none', borderRadius: 6, color: 'white', cursor: 'pointer', fontSize: 12, fontWeight: 600 }}
                    >
                      {showQuestionPicker ? '▲ Masquer' : '▼ Ouvrir le sélecteur'}
                    </button>
                    {selectedQuestionIds.size > 0 && (
                      <button
                        type="button"
                        onClick={deselectAll}
                        style={{ padding: '5px 10px', background: '#ef4444', border: 'none', borderRadius: 6, color: 'white', cursor: 'pointer', fontSize: 12 }}
                      >
                        Tout déselectionner
                      </button>
                    )}
                  </div>
                </div>

                {showQuestionPicker && (
                  <div style={{ background: '#0f172a', border: '1px solid #334155', borderRadius: 10, overflow: 'hidden' }}>
                    {/* Barre de recherche */}
                    <div style={{ padding: '10px 12px', borderBottom: '1px solid #334155', display: 'flex', gap: 8, alignItems: 'center' }}>
                      <input
                        value={questionSearch}
                        onChange={e => setQuestionSearch(e.target.value)}
                        placeholder="🔍 Rechercher une question..."
                        style={{ ...inp, flex: 1 }}
                      />
                      <button
                        type="button"
                        onClick={selectAll}
                        style={{ padding: '5px 10px', background: '#1A5C38', border: 'none', borderRadius: 6, color: 'white', cursor: 'pointer', fontSize: 12, fontWeight: 600, whiteSpace: 'nowrap' }}
                      >
                        ✅ Tout ({filteredQuestions.length})
                      </button>
                    </div>

                    {loadingQuestions ? (
                      <div style={{ padding: 30, textAlign: 'center', color: '#64748b' }}>⏳ Chargement des questions...</div>
                    ) : filteredQuestions.length === 0 ? (
                      <div style={{ padding: 30, textAlign: 'center', color: '#64748b' }}>
                        Aucune question trouvée pour cette matière.<br />
                        <span style={{ fontSize: 12 }}>Créez d'abord des questions dans la section Questions.</span>
                      </div>
                    ) : (
                      <div style={{ maxHeight: 350, overflowY: 'auto' }}>
                        {filteredQuestions.map((q: any) => {
                          const isSelected = selectedQuestionIds.has(q.id);
                          return (
                            <div
                              key={q.id}
                              onClick={() => toggleQuestion(q.id)}
                              style={{
                                padding: '10px 12px',
                                cursor: 'pointer',
                                background: isSelected ? 'rgba(26,92,56,0.3)' : 'transparent',
                                borderBottom: '1px solid #1e293b',
                                display: 'flex',
                                gap: 10,
                                alignItems: 'flex-start',
                                transition: 'background 0.15s',
                              }}
                            >
                              <div style={{
                                width: 20, height: 20, borderRadius: 4, flexShrink: 0, marginTop: 2,
                                background: isSelected ? '#1A5C38' : '#334155',
                                border: `1px solid ${isSelected ? '#4ade80' : '#475569'}`,
                                display: 'flex', alignItems: 'center', justifyContent: 'center',
                              }}>
                                {isSelected && <span style={{ color: 'white', fontSize: 12, fontWeight: 700 }}>✓</span>}
                              </div>
                              <div style={{ flex: 1 }}>
                                <div style={{ color: '#e2e8f0', fontSize: 13, lineHeight: 1.4 }}>
                                  {q.enonce?.substring(0, 120)}{q.enonce?.length > 120 ? '...' : ''}
                                </div>
                                <div style={{ display: 'flex', gap: 8, marginTop: 4 }}>
                                  <span style={{ color: '#4ade80', fontSize: 11 }}>✓ {q.bonne_reponse}</span>
                                  <span style={{ color: '#64748b', fontSize: 11 }}>{q.difficulte ?? 'MOYEN'}</span>
                                  {q.serie_id && <span style={{ color: '#F59E0B', fontSize: 11 }}>⚠️ Déjà dans une série</span>}
                                </div>
                              </div>
                            </div>
                          );
                        })}
                      </div>
                    )}

                    <div style={{ padding: '8px 12px', borderTop: '1px solid #334155', background: '#1e293b', fontSize: 12, color: '#64748b' }}>
                      {selectedQuestionIds.size} question(s) sélectionnée(s) •
                      <span style={{ color: '#F59E0B', marginLeft: 4 }}>⚠️ = déjà assignée à une autre série</span>
                    </div>
                  </div>
                )}
              </div>
            )}

            <div style={{ display: 'flex', gap: 10, marginTop: 4 }}>
              <button
                type="submit"
                style={{
                  padding: '10px 24px', background: '#1A5C38', border: 'none', borderRadius: 8,
                  color: 'white', cursor: 'pointer', fontWeight: 700, fontSize: 14,
                }}
              >
                ✅ Créer la série
              </button>
              <button
                type="button"
                onClick={() => { setShowCreate(false); setShowQuestionPicker(false); setSelectedQuestionIds(new Set()); }}
                style={{ padding: '10px 16px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer' }}
              >
                Annuler
              </button>
              <span style={{ color: '#64748b', fontSize: 12, alignSelf: 'center', marginLeft: 8 }}>
                {selectedQuestionIds.size === 0 ? 'Aucune question sélectionnée (série vide possible)' : `${selectedQuestionIds.size} question(s) seront assignées`}
              </span>
            </div>
          </form>
        </div>
      )}

      {/* Liste des séries */}
      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>
      ) : !selectedMatiere ? (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>📚</div>
          <div style={{ color: '#64748b', fontSize: 14 }}>Sélectionner une matière pour voir ses séries</div>
        </div>
      ) : series.length === 0 ? (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 40, marginBottom: 12 }}>📭</div>
          <div style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 8 }}>Aucune série pour cette matière</div>
          <div style={{ color: '#64748b', fontSize: 13, marginBottom: 16 }}>Créez une série manuellement en sélectionnant des questions, ou utilisez la génération automatique</div>
          <div style={{ display: 'flex', gap: 10, justifyContent: 'center' }}>
            <button
              onClick={() => { setShowCreate(true); setShowQuestionPicker(false); }}
              style={{ background: '#1A5C38', border: 'none', color: 'white', padding: '10px 20px', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}
            >
              ✚ Créer manuellement
            </button>
            <button
              onClick={handleAutoGenerate}
              style={{ background: '#3b82f6', border: 'none', color: 'white', padding: '10px 20px', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}
            >
              🤖 Série auto (20Q)
            </button>
          </div>
        </div>
      ) : (
        <div style={{ background: '#1e293b', borderRadius: 12, border: '1px solid #334155', overflow: 'hidden' }}>
          <div style={{ padding: '10px 16px', borderBottom: '1px solid #334155', background: '#0f172a', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <span style={{ color: '#94a3b8', fontSize: 13 }}>{series.length} série(s) · Les séries <span style={{ color: '#4ade80' }}>actives</span> sont visibles par les utilisateurs</span>
          </div>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#0f172a' }}>
                {['N°', 'Titre', 'Questions', 'Durée', 'Statut', 'Actions'].map(h => (
                  <th key={h} style={{ padding: '10px 12px', color: '#64748b', fontSize: 12, fontWeight: 600, textAlign: 'left', textTransform: 'uppercase' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {series.map((s, idx) => (
                <tr key={s.id} style={{ borderTop: '1px solid #334155', background: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.02)' }}>
                  <td style={{ padding: '10px 12px', color: '#D4A017', fontWeight: 700 }}>#{s.numero}</td>
                  <td style={{ padding: '10px 12px', color: '#e2e8f0', fontSize: 13 }}>{s.titre}</td>
                  <td style={{ padding: '10px 12px', color: '#4ade80', fontSize: 13, fontWeight: 600 }}>{s.nb_questions} Q</td>
                  <td style={{ padding: '10px 12px', color: '#64748b', fontSize: 12 }}>{s.duree_minutes} min</td>
                  <td style={{ padding: '10px 12px' }}>
                    <button
                      onClick={() => handleToggle(s)}
                      style={{
                        background: s.actif ? 'rgba(74,222,128,0.1)' : 'rgba(239,68,68,0.1)',
                        border: 'none', color: s.actif ? '#4ade80' : '#ef4444',
                        padding: '3px 10px', borderRadius: 10, cursor: 'pointer', fontSize: 12, fontWeight: 600,
                      }}
                    >
                      {s.actif ? '✅ Publiée' : '🔴 Masquée'}
                    </button>
                  </td>
                  <td style={{ padding: '10px 12px' }}>
                    <button
                      onClick={() => handleDelete(s.id)}
                      title="Supprimer la série"
                      style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, padding: '2px 6px', borderRadius: 4 }}
                    >
                      🗑️
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 4, fontWeight: 500 };
const inp: React.CSSProperties = { padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
const sel: React.CSSProperties = { padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
