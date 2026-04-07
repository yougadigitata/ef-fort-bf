// ════════════════════════════════════════════════════════════════
// MATIÈRES PAGE v2.0 — Gestion complète matières + séries QCM
// L'admin peut tout gérer : matières, séries, questions (manuel + import)
// ════════════════════════════════════════════════════════════════
import { useState, useEffect, useRef } from 'react';
import { getMatieres, getSeries, getQuestions, createSerie, deleteSerie, createQuestion, deleteQuestion, updateQuestion } from '../api';
import type { Page } from '../App';

const S = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#e2e8f0',
  muted: '#64748b', green: '#1A5C38', gold: '#D4A017', blue: '#3b82f6',
  red: '#ef4444', purple: '#8b5cf6', cyan: '#06b6d4', orange: '#f59e0b',
  success: '#4ade80', input: '#0f172a',
};

// ── Parseur intelligent de questions (Markdown/Texte brut) ──────
function parseQuestionsFromText(text: string): any[] {
  const questions: any[] = [];
  // Séparer par blocs "Question :"
  const blocks = text.split(/\n(?=Question\s*:|\d+\s*[-.)]\s*[A-Z])/i).filter(b => b.trim());

  for (const block of blocks) {
    const lines = block.split('\n').map(l => l.trim()).filter(l => l);
    if (lines.length < 3) continue;

    let enonce = '';
    let optA = '', optB = '', optC = '', optD = '';
    let bonneReponse = '';
    let explication = '';

    for (const line of lines) {
      if (/^Question\s*:/i.test(line)) {
        enonce = line.replace(/^Question\s*:\s*/i, '').trim();
      } else if (/^A[\).\s]/i.test(line)) {
        optA = line.replace(/^A[\).\s]\s*/i, '').trim();
      } else if (/^B[\).\s]/i.test(line)) {
        optB = line.replace(/^B[\).\s]\s*/i, '').trim();
      } else if (/^C[\).\s]/i.test(line)) {
        optC = line.replace(/^C[\).\s]\s*/i, '').trim();
      } else if (/^D[\).\s]/i.test(line)) {
        optD = line.replace(/^D[\).\s]\s*/i, '').trim();
      } else if (/^(Bonne\s*[Rr]éponse|Réponse|Reponse)\s*:/i.test(line)) {
        bonneReponse = line.replace(/^(Bonne\s*[Rr]éponse|Réponse|Reponse)\s*:\s*/i, '').trim().toUpperCase();
      } else if (/^(Explication|Justification|Commentaire)\s*:/i.test(line)) {
        explication = line.replace(/^(Explication|Justification|Commentaire)\s*:\s*/i, '').trim();
      } else if (!enonce && line.length > 5) {
        // Ligne sans préfixe → peut être l'énoncé
        enonce = line;
      }
    }

    if (enonce && optA && optB && bonneReponse) {
      questions.push({
        enonce,
        option_a: optA, option_b: optB,
        option_c: optC || '', option_d: optD || '',
        bonne_reponse: bonneReponse.charAt(0),
        explication,
        difficulte: 'INTERMEDIAIRE',
      });
    }
  }
  return questions;
}

// ── Parseur CSV ───────────────────────────────────────────────
function parseCSV(text: string): any[] {
  const lines = text.split('\n').filter(l => l.trim());
  if (lines.length < 2) return [];
  const headers = lines[0].split(/[;,]/).map(h => h.trim().toLowerCase().replace(/['"]/g, ''));
  return lines.slice(1).map(line => {
    const vals = line.split(/[;,]/).map(v => v.trim().replace(/^["']|["']$/g, ''));
    const obj: Record<string, string> = {};
    headers.forEach((h, i) => { obj[h] = vals[i] ?? ''; });
    return {
      enonce: obj['enonce'] || obj['question'] || obj['intitule'] || '',
      option_a: obj['option_a'] || obj['a'] || obj['choix_a'] || '',
      option_b: obj['option_b'] || obj['b'] || obj['choix_b'] || '',
      option_c: obj['option_c'] || obj['c'] || obj['choix_c'] || '',
      option_d: obj['option_d'] || obj['d'] || obj['choix_d'] || '',
      bonne_reponse: (obj['bonne_reponse'] || obj['reponse'] || obj['answer'] || 'A').toUpperCase().charAt(0),
      explication: obj['explication'] || obj['explication_reponse'] || '',
      difficulte: obj['difficulte'] || obj['niveau'] || 'INTERMEDIAIRE',
    };
  }).filter(q => q.enonce);
}

// ── Parseur JSON ─────────────────────────────────────────────
function parseJSON(text: string): any[] {
  try {
    const data = JSON.parse(text);
    const arr = Array.isArray(data) ? data : (data.questions ?? data.qcm ?? []);
    return arr.map((q: any) => ({
      enonce: q.enonce || q.question || q.intitule || '',
      option_a: q.option_a || q.a || q.A || '',
      option_b: q.option_b || q.b || q.B || '',
      option_c: q.option_c || q.c || q.C || '',
      option_d: q.option_d || q.d || q.D || '',
      bonne_reponse: (q.bonne_reponse || q.reponse || q.answer || 'A').toUpperCase().charAt(0),
      explication: q.explication || q.explanation || '',
      difficulte: q.difficulte || q.niveau || q.difficulty || 'INTERMEDIAIRE',
    })).filter((q: any) => q.enonce);
  } catch { return []; }
}

// ══════════════════════════════════════════════════════════════
// COMPOSANT PRINCIPAL
// ══════════════════════════════════════════════════════════════
export default function MatieresPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [matieres, setMatieres] = useState<any[]>([]);
  const [selectedMatiere, setSelectedMatiere] = useState<any>(null);
  const [series, setSeries] = useState<any[]>([]);
  const [selectedSerie, setSelectedSerie] = useState<any>(null);
  const [questions, setQuestions] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [loadingSeries, setLoadingSeries] = useState(false);
  const [loadingQuestions, setLoadingQuestions] = useState(false);
  const [toast, setToast] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');

  // Modal créer série
  const [showCreateSerie, setShowCreateSerie] = useState(false);
  const [serieForm, setSerieForm] = useState({ titre: '', numero: '', niveau: 'INTERMEDIAIRE', duree_minutes: '15' });
  const [creatingSerieLoading, setCreatingSerieLoading] = useState(false);

  // Modal créer question manuelle
  const [showCreateQuestion, setShowCreateQuestion] = useState(false);
  const [questionForm, setQuestionForm] = useState({
    enonce: '', option_a: '', option_b: '', option_c: '', option_d: '',
    bonne_reponse: 'A', explication: '', difficulte: 'INTERMEDIAIRE',
  });
  const [savingQuestion, setSavingQuestion] = useState(false);

  // Import en masse
  const [showImport, setShowImport] = useState(false);
  const [importFile, setImportFile] = useState<File | null>(null);
  const [importText, setImportText] = useState('');
  const [importMode, setImportMode] = useState<'file' | 'text'>('file');
  const [importPreview, setImportPreview] = useState<any[]>([]);
  const [importLoading, setImportLoading] = useState(false);
  const [importResult, setImportResult] = useState<any>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  // Edit question
  const [editQuestion, setEditQuestion] = useState<any>(null);

  // Recherche questions
  const [searchQ, setSearchQ] = useState('');

  useEffect(() => { loadMatieres(); }, []);

  async function loadMatieres() {
    setLoading(true);
    try {
      const data = await getMatieres();
      setMatieres(data.matieres ?? []);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setLoading(false); }
  }

  async function loadSeries(matiere: any) {
    setLoadingSeries(true);
    setSeries([]); setSelectedSerie(null); setQuestions([]);
    try {
      const data = await getSeries({ matiere: matiere.code, matiere_id: matiere.id });
      setSeries(data.series ?? []);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setLoadingSeries(false); }
  }

  async function loadQuestions(serie: any) {
    setLoadingQuestions(true);
    setQuestions([]);
    try {
      const data = await getQuestions({ serie_id: serie.id, limit: 500 });
      setQuestions(data.questions ?? []);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setLoadingQuestions(false); }
  }

  function showToast(msg: string, type: 'success' | 'error' = 'success') {
    setToast(msg); setToastType(type);
    setTimeout(() => setToast(''), 4000);
  }

  function selectMatiere(m: any) {
    setSelectedMatiere(m);
    setSelectedSerie(null);
    setQuestions([]);
    loadSeries(m);
  }

  function selectSerie(s: any) {
    setSelectedSerie(s);
    loadQuestions(s);
  }

  // ── Créer une série ─────────────────────────────────────────
  async function handleCreateSerie(e: React.FormEvent) {
    e.preventDefault();
    if (!serieForm.titre.trim()) { showToast('⚠️ Titre requis', 'error'); return; }
    if (!selectedMatiere) { showToast('⚠️ Sélectionnez une matière', 'error'); return; }
    setCreatingSerieLoading(true);
    try {
      await createSerie({
        titre: serieForm.titre.trim(),
        matiere_id: selectedMatiere.id,
        numero: serieForm.numero ? parseInt(serieForm.numero) : undefined,
        niveau: serieForm.niveau,
        duree_minutes: parseInt(serieForm.duree_minutes) || 15,
      });
      showToast('✅ Série créée avec succès !');
      setShowCreateSerie(false);
      setSerieForm({ titre: '', numero: '', niveau: 'INTERMEDIAIRE', duree_minutes: '15' });
      loadSeries(selectedMatiere);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setCreatingSerieLoading(false); }
  }

  // ── Supprimer une série ─────────────────────────────────────
  async function handleDeleteSerie(serie: any) {
    if (!confirm(`Supprimer la série "${serie.titre}" et toutes ses questions ?`)) return;
    try {
      await deleteSerie(serie.id);
      showToast('✅ Série supprimée');
      if (selectedSerie?.id === serie.id) { setSelectedSerie(null); setQuestions([]); }
      loadSeries(selectedMatiere);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
  }

  // ── Créer une question manuelle ─────────────────────────────
  async function handleCreateQuestion(e: React.FormEvent) {
    e.preventDefault();
    if (!questionForm.enonce.trim()) { showToast('⚠️ Énoncé requis', 'error'); return; }
    if (!questionForm.option_a.trim() || !questionForm.option_b.trim()) {
      showToast('⚠️ Options A et B requises', 'error'); return;
    }
    if (!selectedSerie) { showToast('⚠️ Sélectionnez une série', 'error'); return; }
    setSavingQuestion(true);
    try {
      await createQuestion({
        ...questionForm,
        matiere_id: selectedMatiere?.id,
        serie_id: selectedSerie?.id,
      });
      showToast('✅ Question ajoutée !');
      setQuestionForm({ enonce: '', option_a: '', option_b: '', option_c: '', option_d: '', bonne_reponse: 'A', explication: '', difficulte: 'INTERMEDIAIRE' });
      setShowCreateQuestion(false);
      loadQuestions(selectedSerie);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setSavingQuestion(false); }
  }

  // ── Supprimer une question ──────────────────────────────────
  async function handleDeleteQuestion(q: any) {
    if (!confirm(`Supprimer cette question ?\n"${q.enonce?.substring(0, 80)}..."`)) return;
    try {
      await deleteQuestion(q.id);
      showToast('✅ Question supprimée');
      loadQuestions(selectedSerie);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
  }

  // ── Sauvegarder édition question ────────────────────────────
  async function handleUpdateQuestion(e: React.FormEvent) {
    e.preventDefault();
    if (!editQuestion?.enonce?.trim()) { showToast('⚠️ Énoncé requis', 'error'); return; }
    setSavingQuestion(true);
    try {
      await updateQuestion(editQuestion.id, editQuestion);
      showToast('✅ Question mise à jour !');
      setEditQuestion(null);
      loadQuestions(selectedSerie);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setSavingQuestion(false); }
  }

  // ── Parser le fichier d'import ──────────────────────────────
  async function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const file = e.target.files?.[0];
    if (!file) return;
    setImportFile(file);
    const text = await file.text();
    let parsed: any[] = [];
    if (file.name.endsWith('.json')) parsed = parseJSON(text);
    else if (file.name.endsWith('.csv')) parsed = parseCSV(text);
    else parsed = parseQuestionsFromText(text); // .md, .txt, .markdown
    setImportPreview(parsed);
    setImportResult(null);
  }

  function handleTextChange(text: string) {
    setImportText(text);
    const parsed = parseQuestionsFromText(text);
    setImportPreview(parsed);
    setImportResult(null);
  }

  // ── Importer les questions ──────────────────────────────────
  async function handleImport() {
    if (!selectedSerie) { showToast('⚠️ Sélectionnez d\'abord une série', 'error'); return; }
    if (importPreview.length === 0) { showToast('⚠️ Aucune question détectée', 'error'); return; }
    if (!confirm(`Importer ${importPreview.length} questions dans "${selectedSerie.titre}" ?`)) return;

    setImportLoading(true);
    let success = 0; let errors = 0;
    for (const q of importPreview) {
      try {
        await createQuestion({
          ...q,
          matiere_id: selectedMatiere?.id,
          serie_id: selectedSerie.id,
        });
        success++;
      } catch { errors++; }
    }
    setImportResult({ success, errors, total: importPreview.length });
    showToast(`✅ ${success}/${importPreview.length} questions importées !`);
    setImportPreview([]);
    setImportFile(null);
    setImportText('');
    loadQuestions(selectedSerie);
    setImportLoading(false);
  }

  // ── Filtrage des questions ──────────────────────────────────
  const filteredQuestions = searchQ
    ? questions.filter(q => q.enonce?.toLowerCase().includes(searchQ.toLowerCase()))
    : questions;

  // ── Export CSV ──────────────────────────────────────────────
  function handleExport() {
    if (!questions.length) { showToast('⚠️ Aucune question à exporter', 'error'); return; }
    const headers = 'enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte';
    const rows = questions.map(q =>
      [q.enonce, q.option_a, q.option_b, q.option_c, q.option_d, q.bonne_reponse, q.explication, q.difficulte]
        .map(v => `"${(v || '').replace(/"/g, '""')}"`)
        .join(';')
    );
    const csv = [headers, ...rows].join('\n');
    const blob = new Blob(['\uFEFF' + csv], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = `${selectedSerie?.titre || 'export'}.csv`;
    a.click(); URL.revokeObjectURL(url);
    showToast('✅ Export CSV téléchargé !');
  }

  // ════════════════════════════════════════════════════════════
  // RENDU
  // ════════════════════════════════════════════════════════════
  return (
    <div style={{ minHeight: '100vh' }}>
      {/* Toast */}
      {toast && (
        <div style={{
          position: 'fixed', top: 70, right: 20, padding: '12px 20px',
          background: toastType === 'success' ? '#065f46' : '#7f1d1d',
          border: `1px solid ${toastType === 'success' ? '#4ade80' : '#ef4444'}`,
          borderRadius: 10, color: '#fff', fontSize: 17, zIndex: 9999,
          boxShadow: '0 4px 20px rgba(0,0,0,0.4)', maxWidth: 380,
        }}>{toast}</div>
      )}

      {/* Header */}
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ color: S.text, fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
          📚 Gestion des Matières & Séries QCM
        </h2>
        <p style={{ color: S.muted, fontSize: 16 }}>
          Sélectionnez une matière → une série → gérez les questions (manuel ou import)
        </p>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '260px 280px 1fr', gap: 16, alignItems: 'start' }}>

        {/* ── Colonne 1 : Matières ─────────────────────────────── */}
        <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
          <div style={{ padding: '14px 16px', borderBottom: `1px solid ${S.border}`, background: '#0f172a' }}>
            <h3 style={{ color: S.text, fontSize: 17, fontWeight: 700, margin: 0 }}>
              🗂 Matières ({matieres.length})
            </h3>
          </div>
          {loading ? (
            <div style={{ padding: 20, textAlign: 'center', color: S.muted, fontSize: 16 }}>Chargement…</div>
          ) : (
            <div style={{ maxHeight: 600, overflowY: 'auto' }}>
              {matieres.map(m => (
                <div
                  key={m.id}
                  onClick={() => selectMatiere(m)}
                  style={{
                    padding: '12px 16px', cursor: 'pointer', borderBottom: `1px solid #1e293b`,
                    background: selectedMatiere?.id === m.id ? `${S.green}30` : 'transparent',
                    borderLeft: selectedMatiere?.id === m.id ? `3px solid ${S.green}` : '3px solid transparent',
                    transition: 'all 0.2s',
                  }}
                >
                  <div style={{ color: S.text, fontSize: 16, fontWeight: 600 }}>{m.nom}</div>
                  <div style={{ color: S.muted, fontSize: 14, marginTop: 2 }}>
                    {m.total_questions ?? m.nb_questions ?? '?'} questions
                    {m.nb_series ? ` · ${m.nb_series} séries` : ''}
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* ── Colonne 2 : Séries ────────────────────────────────── */}
        <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
          <div style={{ padding: '14px 16px', borderBottom: `1px solid ${S.border}`, background: '#0f172a', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <h3 style={{ color: S.text, fontSize: 17, fontWeight: 700, margin: 0 }}>
              📋 Séries {selectedMatiere ? `(${series.length})` : ''}
            </h3>
            {selectedMatiere && (
              <button onClick={() => setShowCreateSerie(true)} style={{
                background: S.green, color: '#fff', border: 'none', borderRadius: 6,
                padding: '6px 14px', fontSize: 15, cursor: 'pointer', fontWeight: 600,
              }}>+ Nouvelle</button>
            )}
          </div>

          {!selectedMatiere ? (
            <div style={{ padding: 20, textAlign: 'center', color: S.muted, fontSize: 16 }}>
              ← Choisissez une matière
            </div>
          ) : loadingSeries ? (
            <div style={{ padding: 20, textAlign: 'center', color: S.muted, fontSize: 16 }}>Chargement…</div>
          ) : series.length === 0 ? (
            <div style={{ padding: 20, textAlign: 'center', color: S.muted, fontSize: 16 }}>
              Aucune série.<br />
              <span style={{ color: S.green, cursor: 'pointer', fontSize: 15 }}
                onClick={() => setShowCreateSerie(true)}>+ Créer la première série</span>
            </div>
          ) : (
            <div style={{ maxHeight: 600, overflowY: 'auto' }}>
              {series.map(s => (
                <div
                  key={s.id}
                  style={{
                    padding: '10px 16px', borderBottom: `1px solid #1e293b`,
                    background: selectedSerie?.id === s.id ? '#1a3a5c30' : 'transparent',
                    borderLeft: selectedSerie?.id === s.id ? `3px solid ${S.blue}` : '3px solid transparent',
                    cursor: 'pointer',
                  }}
                >
                  <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                    <div onClick={() => selectSerie(s)} style={{ flex: 1 }}>
                      <div style={{ color: S.text, fontSize: 16, fontWeight: 600 }}>{s.titre}</div>
                      <div style={{ color: S.muted, fontSize: 14, marginTop: 2 }}>
                        {s.nb_questions ?? s.count ?? '?'} questions · {s.niveau ?? 'Intermédiaire'}
                      </div>
                    </div>
                    <button
                      onClick={(e) => { e.stopPropagation(); handleDeleteSerie(s); }}
                      style={{ background: 'transparent', border: 'none', color: '#ef4444', cursor: 'pointer', fontSize: 16, padding: '0 4px' }}
                      title="Supprimer cette série"
                    >🗑</button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* ── Colonne 3 : Questions ─────────────────────────────── */}
        <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
          <div style={{ padding: '14px 16px', borderBottom: `1px solid ${S.border}`, background: '#0f172a' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', flexWrap: 'wrap', gap: 8 }}>
              <h3 style={{ color: S.text, fontSize: 17, fontWeight: 700, margin: 0 }}>
                ❓ Questions {selectedSerie ? `(${filteredQuestions.length}/${questions.length})` : ''}
              </h3>
              {selectedSerie && (
                <div style={{ display: 'flex', gap: 8, flexWrap: 'wrap' }}>
                  <button onClick={() => setShowCreateQuestion(true)} style={{
                    background: S.green, color: '#fff', border: 'none', borderRadius: 6,
                    padding: '6px 14px', fontSize: 15, cursor: 'pointer', fontWeight: 600,
                  }}>+ Manuel</button>
                  <button onClick={() => setShowImport(true)} style={{
                    background: S.purple, color: '#fff', border: 'none', borderRadius: 6,
                    padding: '6px 14px', fontSize: 15, cursor: 'pointer', fontWeight: 600,
                  }}>📤 Import</button>
                  {questions.length > 0 && (
                    <button onClick={handleExport} style={{
                      background: '#0f172a', color: S.text, border: `1px solid ${S.border}`, borderRadius: 6,
                      padding: '6px 14px', fontSize: 15, cursor: 'pointer',
                    }}>⬇ CSV</button>
                  )}
                </div>
              )}
            </div>
            {selectedSerie && (
              <input
                value={searchQ}
                onChange={e => setSearchQ(e.target.value)}
                placeholder="🔍 Rechercher une question…"
                style={{
                  marginTop: 10, width: '100%', padding: '7px 12px',
                  background: S.input, border: `1px solid ${S.border}`, borderRadius: 6,
                  color: S.text, fontSize: 16, boxSizing: 'border-box',
                }}
              />
            )}
          </div>

          {!selectedSerie ? (
            <div style={{ padding: 40, textAlign: 'center', color: S.muted, fontSize: 16 }}>
              ← Choisissez une série pour voir ses questions
            </div>
          ) : loadingQuestions ? (
            <div style={{ padding: 40, textAlign: 'center', color: S.muted }}>⏳ Chargement…</div>
          ) : filteredQuestions.length === 0 ? (
            <div style={{ padding: 40, textAlign: 'center', color: S.muted, fontSize: 16 }}>
              Aucune question.{' '}
              <span style={{ color: S.green, cursor: 'pointer' }} onClick={() => setShowCreateQuestion(true)}>
                + Ajouter
              </span>
            </div>
          ) : (
            <div style={{ maxHeight: 580, overflowY: 'auto' }}>
              {filteredQuestions.map((q, i) => (
                <div key={q.id} style={{
                  padding: '12px 16px', borderBottom: `1px solid #1e293b`,
                  display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', gap: 8,
                }}>
                  <div style={{ flex: 1, minWidth: 0 }}>
                    <div style={{ color: S.muted, fontSize: 14, marginBottom: 4 }}>#{i + 1}</div>
                    <div style={{ color: S.text, fontSize: 16, lineHeight: 1.4, wordBreak: 'break-word' }}>
                      {q.enonce?.substring(0, 120)}{q.enonce?.length > 120 ? '…' : ''}
                    </div>
                    <div style={{ color: S.success, fontSize: 14, marginTop: 4 }}>
                      ✓ Réponse : {q.bonne_reponse} · {q.difficulte}
                    </div>
                  </div>
                  <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                    <button onClick={() => setEditQuestion({ ...q })} style={{
                      background: S.blue, color: '#fff', border: 'none', borderRadius: 5,
                      padding: '3px 8px', fontSize: 14, cursor: 'pointer',
                    }}>✏️</button>
                    <button onClick={() => handleDeleteQuestion(q)} style={{
                      background: '#7f1d1d', color: '#fff', border: 'none', borderRadius: 5,
                      padding: '3px 8px', fontSize: 14, cursor: 'pointer',
                    }}>🗑</button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* ════════════════ MODALS ═══════════════════════════════ */}

      {/* Modal : Créer une série */}
      {showCreateSerie && (
        <Modal title={`➕ Nouvelle série — ${selectedMatiere?.nom}`} onClose={() => setShowCreateSerie(false)}>
          <form onSubmit={handleCreateSerie} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <FormField label="Titre de la série *">
              <input value={serieForm.titre} onChange={e => setSerieForm(f => ({ ...f, titre: e.target.value }))}
                placeholder="Ex : Série 3 — Questions avancées" style={inputStyle} />
            </FormField>
            <FormField label="Numéro de série">
              <input type="number" value={serieForm.numero} onChange={e => setSerieForm(f => ({ ...f, numero: e.target.value }))}
                placeholder="Ex : 3" style={inputStyle} />
            </FormField>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <FormField label="Niveau">
                <select value={serieForm.niveau} onChange={e => setSerieForm(f => ({ ...f, niveau: e.target.value }))} style={inputStyle}>
                  <option value="DEBUTANT">Débutant</option>
                  <option value="INTERMEDIAIRE">Intermédiaire</option>
                  <option value="AVANCE">Avancé</option>
                  <option value="EXPERT">Expert</option>
                </select>
              </FormField>
              <FormField label="Durée (minutes)">
                <input type="number" value={serieForm.duree_minutes}
                  onChange={e => setSerieForm(f => ({ ...f, duree_minutes: e.target.value }))} style={inputStyle} />
              </FormField>
            </div>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 4 }}>
              <button type="button" onClick={() => setShowCreateSerie(false)} style={btnSecondary}>Annuler</button>
              <button type="submit" disabled={creatingSerieLoading} style={btnPrimary}>
                {creatingSerieLoading ? '⏳ Création…' : '✅ Créer la série'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Modal : Créer une question manuelle */}
      {showCreateQuestion && (
        <Modal title={`➕ Nouvelle question — ${selectedSerie?.titre}`} onClose={() => setShowCreateQuestion(false)} wide>
          <form onSubmit={handleCreateQuestion} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <FormField label="Énoncé de la question *">
              <textarea value={questionForm.enonce}
                onChange={e => setQuestionForm(f => ({ ...f, enonce: e.target.value }))}
                placeholder="Entrez l'intitulé complet de la question…"
                rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
            </FormField>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <FormField label="Option A *"><input value={questionForm.option_a} onChange={e => setQuestionForm(f => ({ ...f, option_a: e.target.value }))} placeholder="Choix A" style={inputStyle} /></FormField>
              <FormField label="Option B *"><input value={questionForm.option_b} onChange={e => setQuestionForm(f => ({ ...f, option_b: e.target.value }))} placeholder="Choix B" style={inputStyle} /></FormField>
              <FormField label="Option C"><input value={questionForm.option_c} onChange={e => setQuestionForm(f => ({ ...f, option_c: e.target.value }))} placeholder="Choix C (optionnel)" style={inputStyle} /></FormField>
              <FormField label="Option D"><input value={questionForm.option_d} onChange={e => setQuestionForm(f => ({ ...f, option_d: e.target.value }))} placeholder="Choix D (optionnel)" style={inputStyle} /></FormField>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <FormField label="Bonne réponse *">
                <select value={questionForm.bonne_reponse} onChange={e => setQuestionForm(f => ({ ...f, bonne_reponse: e.target.value }))} style={inputStyle}>
                  <option value="A">A</option><option value="B">B</option>
                  <option value="C">C</option><option value="D">D</option>
                </select>
              </FormField>
              <FormField label="Difficulté">
                <select value={questionForm.difficulte} onChange={e => setQuestionForm(f => ({ ...f, difficulte: e.target.value }))} style={inputStyle}>
                  <option value="DEBUTANT">Débutant</option>
                  <option value="INTERMEDIAIRE">Intermédiaire</option>
                  <option value="AVANCE">Avancé</option>
                  <option value="EXPERT">Expert</option>
                </select>
              </FormField>
            </div>
            <FormField label="Explication / Justification (optionnel)">
              <textarea value={questionForm.explication}
                onChange={e => setQuestionForm(f => ({ ...f, explication: e.target.value }))}
                placeholder="Pourquoi cette réponse est correcte…"
                rows={2} style={{ ...inputStyle, resize: 'vertical' }} />
            </FormField>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button type="button" onClick={() => setShowCreateQuestion(false)} style={btnSecondary}>Annuler</button>
              <button type="submit" disabled={savingQuestion} style={btnPrimary}>
                {savingQuestion ? '⏳ Enregistrement…' : '✅ Ajouter la question'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Modal : Éditer une question */}
      {editQuestion && (
        <Modal title="✏️ Modifier la question" onClose={() => setEditQuestion(null)} wide>
          <form onSubmit={handleUpdateQuestion} style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
            <FormField label="Énoncé *">
              <textarea value={editQuestion.enonce} onChange={e => setEditQuestion((q: any) => ({ ...q, enonce: e.target.value }))}
                rows={3} style={{ ...inputStyle, resize: 'vertical' }} />
            </FormField>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <FormField label="A *"><input value={editQuestion.option_a} onChange={e => setEditQuestion((q: any) => ({ ...q, option_a: e.target.value }))} style={inputStyle} /></FormField>
              <FormField label="B *"><input value={editQuestion.option_b} onChange={e => setEditQuestion((q: any) => ({ ...q, option_b: e.target.value }))} style={inputStyle} /></FormField>
              <FormField label="C"><input value={editQuestion.option_c || ''} onChange={e => setEditQuestion((q: any) => ({ ...q, option_c: e.target.value }))} style={inputStyle} /></FormField>
              <FormField label="D"><input value={editQuestion.option_d || ''} onChange={e => setEditQuestion((q: any) => ({ ...q, option_d: e.target.value }))} style={inputStyle} /></FormField>
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12 }}>
              <FormField label="Bonne réponse">
                <select value={editQuestion.bonne_reponse} onChange={e => setEditQuestion((q: any) => ({ ...q, bonne_reponse: e.target.value }))} style={inputStyle}>
                  <option value="A">A</option><option value="B">B</option><option value="C">C</option><option value="D">D</option>
                </select>
              </FormField>
              <FormField label="Difficulté">
                <select value={editQuestion.difficulte || 'INTERMEDIAIRE'} onChange={e => setEditQuestion((q: any) => ({ ...q, difficulte: e.target.value }))} style={inputStyle}>
                  <option value="DEBUTANT">Débutant</option><option value="INTERMEDIAIRE">Intermédiaire</option>
                  <option value="AVANCE">Avancé</option><option value="EXPERT">Expert</option>
                </select>
              </FormField>
            </div>
            <FormField label="Explication">
              <textarea value={editQuestion.explication || ''} onChange={e => setEditQuestion((q: any) => ({ ...q, explication: e.target.value }))}
                rows={2} style={{ ...inputStyle, resize: 'vertical' }} />
            </FormField>
            <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end' }}>
              <button type="button" onClick={() => setEditQuestion(null)} style={btnSecondary}>Annuler</button>
              <button type="submit" disabled={savingQuestion} style={btnPrimary}>
                {savingQuestion ? '⏳…' : '✅ Sauvegarder'}
              </button>
            </div>
          </form>
        </Modal>
      )}

      {/* Modal : Import en masse */}
      {showImport && (
        <Modal title={`📤 Import en masse — ${selectedSerie?.titre}`} onClose={() => { setShowImport(false); setImportPreview([]); setImportResult(null); setImportFile(null); setImportText(''); }} wide>
          <div style={{ display: 'flex', gap: 8, marginBottom: 16 }}>
            <button onClick={() => setImportMode('file')} style={{ ...importMode === 'file' ? btnPrimary : btnSecondary, flex: 1 }}>📁 Fichier</button>
            <button onClick={() => setImportMode('text')} style={{ ...importMode === 'text' ? btnPrimary : btnSecondary, flex: 1 }}>✍️ Texte brut</button>
          </div>

          {importMode === 'file' ? (
            <div>
              <div style={{
                border: `2px dashed ${S.border}`, borderRadius: 10, padding: 20, textAlign: 'center',
                marginBottom: 12, cursor: 'pointer', background: '#0f172a',
              }} onClick={() => fileInputRef.current?.click()}>
                <div style={{ fontSize: 28, marginBottom: 8 }}>📎</div>
                <div style={{ color: S.text, fontSize: 17, fontWeight: 600 }}>
                  {importFile ? importFile.name : 'Cliquer pour choisir un fichier'}
                </div>
                <div style={{ color: S.muted, fontSize: 15, marginTop: 4 }}>
                  Formats acceptés : .csv, .json, .txt, .md, .markdown
                </div>
                <input ref={fileInputRef} type="file" accept=".csv,.json,.txt,.md,.markdown,.xlsx"
                  onChange={handleFileChange} style={{ display: 'none' }} />
              </div>
            </div>
          ) : (
            <div>
              <div style={{ color: S.muted, fontSize: 15, marginBottom: 8 }}>
                Format attendu (coller vos questions) :
              </div>
              <div style={{ background: '#0f172a', borderRadius: 6, padding: 10, marginBottom: 10, border: `1px solid ${S.border}`, fontSize: 14, color: '#94a3b8', fontFamily: 'monospace' }}>
                Question : Quelle est la capitale du Burkina Faso ?<br />
                A) Bobo-Dioulasso<br />
                B) Ouagadougou<br />
                C) Koudougou<br />
                D) Banfora<br />
                Bonne réponse : B<br />
                Explication : Ouagadougou est la capitale politique.
              </div>
              <textarea value={importText} onChange={e => handleTextChange(e.target.value)}
                placeholder="Collez ici vos questions au format ci-dessus…"
                rows={8} style={{ ...inputStyle, width: '100%', resize: 'vertical', fontSize: 15, fontFamily: 'monospace' }} />
            </div>
          )}

          {/* Prévisualisation */}
          {importPreview.length > 0 && (
            <div style={{ marginTop: 12 }}>
              <div style={{ color: S.success, fontSize: 16, fontWeight: 600, marginBottom: 8 }}>
                ✅ {importPreview.length} questions détectées :
              </div>
              <div style={{ maxHeight: 180, overflowY: 'auto', background: '#0f172a', borderRadius: 8, padding: 10, border: `1px solid ${S.border}` }}>
                {importPreview.slice(0, 5).map((q, i) => (
                  <div key={i} style={{ borderBottom: i < 4 ? `1px solid #1e293b` : 'none', paddingBottom: 6, marginBottom: 6 }}>
                    <div style={{ color: S.text, fontSize: 15 }}>{i + 1}. {q.enonce?.substring(0, 80)}</div>
                    <div style={{ color: S.success, fontSize: 14 }}>→ Réponse : {q.bonne_reponse}</div>
                  </div>
                ))}
                {importPreview.length > 5 && (
                  <div style={{ color: S.muted, fontSize: 14, textAlign: 'center' }}>…et {importPreview.length - 5} autres questions</div>
                )}
              </div>
            </div>
          )}

          {/* Résultat import */}
          {importResult && (
            <div style={{ marginTop: 12, padding: 12, background: '#065f46', borderRadius: 8, border: '1px solid #4ade80' }}>
              <div style={{ color: S.success, fontWeight: 700, fontSize: 17 }}>
                ✅ Import terminé : {importResult.success}/{importResult.total} questions importées
                {importResult.errors > 0 && ` (${importResult.errors} erreurs)`}
              </div>
            </div>
          )}

          <div style={{ display: 'flex', gap: 10, justifyContent: 'flex-end', marginTop: 16 }}>
            <button onClick={() => { setShowImport(false); setImportPreview([]); setImportResult(null); setImportFile(null); setImportText(''); }} style={btnSecondary}>Fermer</button>
            {importPreview.length > 0 && (
              <button onClick={handleImport} disabled={importLoading} style={btnPrimary}>
                {importLoading ? `⏳ Import en cours…` : `✅ Importer ${importPreview.length} questions`}
              </button>
            )}
          </div>
        </Modal>
      )}
    </div>
  );
}

// ── Composants utilitaires ──────────────────────────────────────
function Modal({ title, onClose, children, wide = false }: {
  title: string; onClose: () => void; children: React.ReactNode; wide?: boolean;
}) {
  return (
    <div style={{
      position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.7)',
      display: 'flex', alignItems: 'center', justifyContent: 'center', zIndex: 9990, padding: 16,
    }}>
      <div style={{
        background: '#1e293b', border: '1px solid #334155', borderRadius: 14,
        width: wide ? 700 : 480, maxWidth: '100%', maxHeight: '90vh',
        overflow: 'hidden', display: 'flex', flexDirection: 'column',
      }}>
        <div style={{ padding: '16px 20px', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ color: '#f1f5f9', margin: 0, fontSize: 16, fontWeight: 700 }}>{title}</h3>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: '#64748b', fontSize: 20, cursor: 'pointer', lineHeight: 1 }}>×</button>
        </div>
        <div style={{ padding: 20, overflowY: 'auto', flex: 1 }}>{children}</div>
      </div>
    </div>
  );
}

function FormField({ label, children }: { label: string; children: React.ReactNode }) {
  return (
    <div>
      <label style={{ display: 'block', color: '#94a3b8', fontSize: 15, fontWeight: 600, marginBottom: 5 }}>{label}</label>
      {children}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  width: '100%', padding: '8px 12px', background: '#0f172a',
  border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0',
  fontSize: 16, boxSizing: 'border-box',
};

const btnPrimary: React.CSSProperties = {
  background: '#1A5C38', color: '#fff', border: 'none', borderRadius: 7,
  padding: '8px 18px', fontSize: 16, cursor: 'pointer', fontWeight: 600,
};

const btnSecondary: React.CSSProperties = {
  background: '#1e293b', color: '#e2e8f0', border: '1px solid #334155',
  borderRadius: 7, padding: '8px 18px', fontSize: 16, cursor: 'pointer',
};
