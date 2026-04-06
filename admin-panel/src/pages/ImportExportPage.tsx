// ════════════════════════════════════════════════════════════════
// IMPORT/EXPORT GLOBAL PAGE v2.0 — Import massif QCM
// Supports : CSV, Excel (XLSX), JSON, Markdown/Texte
// ════════════════════════════════════════════════════════════════
import { useState, useEffect, useRef } from 'react';
import { getMatieres, getSeries, createQuestion, bulkImport } from '../api';
import type { Page } from '../App';

const S = {
  card: '#1e293b', border: '#334155', text: '#e2e8f0',
  muted: '#64748b', green: '#1A5C38', gold: '#D4A017', blue: '#3b82f6',
  red: '#ef4444', purple: '#8b5cf6', success: '#4ade80', input: '#0f172a',
};

// ── Parseurs ──────────────────────────────────────────────────
function parseMarkdown(text: string): any[] {
  const questions: any[] = [];
  const blocks = text.split(/\n\n+/).filter(b => b.trim().length > 10);

  for (const block of blocks) {
    const lines = block.split('\n').map(l => l.trim()).filter(l => l);
    if (lines.length < 3) continue;

    let enonce = '';
    let optA = '', optB = '', optC = '', optD = '';
    let bonneReponse = '';
    let explication = '';

    for (const line of lines) {
      if (/^#+\s*Question\s*\d*\s*:?\s*/i.test(line)) {
        enonce = line.replace(/^#+\s*Question\s*\d*\s*:?\s*/i, '').trim();
      } else if (/^Question\s*:?\s*/i.test(line)) {
        enonce = line.replace(/^Question\s*:?\s*/i, '').trim();
      } else if (/^\*?\*?A[\).:\s]/i.test(line)) {
        optA = line.replace(/^\*?\*?A[\).:\s]\s*/i, '').replace(/\*+/g, '').trim();
      } else if (/^\*?\*?B[\).:\s]/i.test(line)) {
        optB = line.replace(/^\*?\*?B[\).:\s]\s*/i, '').replace(/\*+/g, '').trim();
      } else if (/^\*?\*?C[\).:\s]/i.test(line)) {
        optC = line.replace(/^\*?\*?C[\).:\s]\s*/i, '').replace(/\*+/g, '').trim();
      } else if (/^\*?\*?D[\).:\s]/i.test(line)) {
        optD = line.replace(/^\*?\*?D[\).:\s]\s*/i, '').replace(/\*+/g, '').trim();
      } else if (/^(Bonne\s*[Rr]éponse|Réponse\s*correcte|Réponse|Reponse)\s*:?\s*/i.test(line)) {
        bonneReponse = line.replace(/^(Bonne\s*[Rr]éponse|Réponse\s*correcte|Réponse|Reponse)\s*:?\s*/i, '').trim().toUpperCase().charAt(0);
      } else if (/^(Explication|Justification|Commentaire)\s*:?\s*/i.test(line)) {
        explication = line.replace(/^(Explication|Justification|Commentaire)\s*:?\s*/i, '').trim();
      } else if (!enonce && line.length > 8 && !line.startsWith('-') && !line.startsWith('*')) {
        enonce = line;
      }
    }

    if (enonce && optA && optB && bonneReponse) {
      questions.push({
        enonce, option_a: optA, option_b: optB,
        option_c: optC, option_d: optD,
        bonne_reponse: bonneReponse,
        explication, difficulte: 'INTERMEDIAIRE',
      });
    }
  }
  return questions;
}

function parseCSV(text: string): any[] {
  const lines = text.split('\n').filter(l => l.trim());
  if (lines.length < 2) return [];
  const sep = lines[0].includes(';') ? ';' : ',';
  const headers = lines[0].split(sep).map(h => h.trim().toLowerCase().replace(/['"]/g, '').replace(/\s+/g, '_'));

  return lines.slice(1).map(line => {
    const vals: string[] = [];
    let inQuotes = false; let curr = '';
    for (const ch of line) {
      if (ch === '"') { inQuotes = !inQuotes; }
      else if (ch === sep && !inQuotes) { vals.push(curr.trim()); curr = ''; }
      else curr += ch;
    }
    vals.push(curr.trim());

    const obj: Record<string, string> = {};
    headers.forEach((h, i) => { obj[h] = (vals[i] ?? '').replace(/^["']|["']$/g, ''); });

    return {
      enonce: obj.enonce || obj.question || obj.intitule || obj.libelle || '',
      option_a: obj.option_a || obj.a || obj.choix_a || obj.reponse_a || '',
      option_b: obj.option_b || obj.b || obj.choix_b || obj.reponse_b || '',
      option_c: obj.option_c || obj.c || obj.choix_c || obj.reponse_c || '',
      option_d: obj.option_d || obj.d || obj.choix_d || obj.reponse_d || '',
      bonne_reponse: (obj.bonne_reponse || obj.reponse || obj.answer || obj.correct || 'A').toUpperCase().charAt(0),
      explication: obj.explication || obj.explanation || obj.justification || obj.commentaire || '',
      difficulte: obj.difficulte || obj.niveau || obj.difficulty || 'INTERMEDIAIRE',
    };
  }).filter(q => q.enonce && q.option_a && q.option_b);
}

function parseJSON(text: string): any[] {
  try {
    const data = JSON.parse(text);
    const arr = Array.isArray(data) ? data : (data.questions ?? data.qcm ?? data.data ?? []);
    return arr.map((q: any) => ({
      enonce: q.enonce || q.question || q.intitule || '',
      option_a: q.option_a || q.optionA || q.a || q.A || q.choix?.A || '',
      option_b: q.option_b || q.optionB || q.b || q.B || q.choix?.B || '',
      option_c: q.option_c || q.optionC || q.c || q.C || q.choix?.C || '',
      option_d: q.option_d || q.optionD || q.d || q.D || q.choix?.D || '',
      bonne_reponse: (q.bonne_reponse || q.bonneReponse || q.reponse || q.answer || q.correct || 'A').toUpperCase().charAt(0),
      explication: q.explication || q.explanation || q.justification || '',
      difficulte: q.difficulte || q.niveau || q.difficulty || 'INTERMEDIAIRE',
    })).filter((q: any) => q.enonce && q.option_a && q.option_b);
  } catch { return []; }
}

function parseFile(text: string, filename: string): any[] {
  if (filename.endsWith('.json')) return parseJSON(text);
  if (filename.endsWith('.csv')) return parseCSV(text);
  return parseMarkdown(text); // .md, .txt, .markdown
}

// ── Composant principal ────────────────────────────────────────
export default function ImportExportPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [matieres, setMatieres] = useState<any[]>([]);
  const [series, setSeries] = useState<any[]>([]);
  const [selectedMatiere, setSelectedMatiere] = useState('');
  const [selectedSerie, setSelectedSerie] = useState('');
  const [loadingSeries, setLoadingSeries] = useState(false);

  const [file, setFile] = useState<File | null>(null);
  const [textInput, setTextInput] = useState('');
  const [inputMode, setInputMode] = useState<'file' | 'text'>('file');
  const [parsed, setParsed] = useState<any[]>([]);
  const [importing, setImporting] = useState(false);
  const [importResult, setImportResult] = useState<any>(null);
  const fileRef = useRef<HTMLInputElement>(null);

  const [toast, setToast] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');

  // Onglet actif : import ou export
  const [activeTab, setActiveTab] = useState<'import' | 'export' | 'template'>('import');

  // Export
  const [exportMatiereId, setExportMatiereId] = useState('');
  const [exportSerieId, setExportSerieId] = useState('');
  const [exportFormat, setExportFormat] = useState<'csv' | 'json' | 'markdown'>('csv');
  const [exporting, setExporting] = useState(false);
  const [exportSeriesList, setExportSeriesList] = useState<any[]>([]);

  useEffect(() => { loadMatieres(); }, []);

  async function loadMatieres() {
    try {
      const data = await getMatieres();
      setMatieres(data.matieres ?? []);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
  }

  async function loadSeries(matiereId: string, target: 'import' | 'export') {
    if (!matiereId) return;
    if (target === 'import') { setLoadingSeries(true); setSeries([]); }
    else { setExportSeriesList([]); }
    try {
      const mat = matieres.find(m => m.id === matiereId);
      const data = await getSeries({ matiere: mat?.code, matiere_id: matiereId });
      if (target === 'import') { setSeries(data.series ?? []); setLoadingSeries(false); }
      else setExportSeriesList(data.series ?? []);
    } catch {}
  }

  function showToast(msg: string, type: 'success' | 'error' = 'success') {
    setToast(msg); setToastType(type);
    setTimeout(() => setToast(''), 5000);
  }

  // ── Parsing fichier ────────────────────────────────────────
  async function handleFileChange(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    const text = await f.text();
    const p = parseFile(text, f.name);
    setParsed(p);
    setImportResult(null);
    if (p.length === 0) showToast('⚠️ Aucune question détectée dans ce fichier. Vérifiez le format.', 'error');
    else showToast(`✅ ${p.length} question(s) détectée(s) !`);
  }

  function handleTextChange(t: string) {
    setTextInput(t);
    const p = parseMarkdown(t);
    setParsed(p);
    setImportResult(null);
  }

  // ── Import en masse ────────────────────────────────────────
  async function handleImport() {
    if (!selectedMatiere) { showToast('⚠️ Sélectionnez une matière', 'error'); return; }
    if (parsed.length === 0) { showToast('⚠️ Aucune question à importer', 'error'); return; }
    if (!confirm(`Importer ${parsed.length} questions${selectedSerie ? ' dans la série sélectionnée' : ' (sans série)'} ?`)) return;

    setImporting(true);
    try {
      // Utiliser bulkImport ou fallback question par question
      const questionsWithMeta = parsed.map(q => ({
        ...q,
        matiere_id: selectedMatiere,
        serie_id: selectedSerie || undefined,
      }));

      let success = 0, errors = 0;
      // Essai bulk import (plus rapide)
      try {
        const result = await bulkImport(questionsWithMeta, selectedMatiere);
        success = result.imported ?? result.count ?? parsed.length;
        errors = result.errors ?? 0;
      } catch {
        // Fallback : question par question
        for (const q of questionsWithMeta) {
          try {
            await createQuestion(q);
            success++;
          } catch { errors++; }
        }
      }

      setImportResult({ success, errors, total: parsed.length });
      showToast(`✅ ${success}/${parsed.length} questions importées !`);
      setParsed([]);
      setFile(null);
      setTextInput('');
    } catch (e: any) {
      showToast('❌ ' + e.message, 'error');
    } finally {
      setImporting(false);
    }
  }

  // ── Export ─────────────────────────────────────────────────
  async function handleExport() {
    if (!exportMatiereId) { showToast('⚠️ Sélectionnez une matière', 'error'); return; }
    setExporting(true);
    try {
      const token = localStorage.getItem('admin_token');
      const BASE_URL = window.location.hostname === 'localhost'
        ? 'http://localhost:8787'
        : 'https://ef-fort-bf.yembuaro29.workers.dev';

      let url = `${BASE_URL}/api/admin-cms/questions?matiere_id=${exportMatiereId}&limit=1000`;
      if (exportSerieId) url += `&serie_id=${exportSerieId}`;

      const res = await fetch(url, { headers: { Authorization: `Bearer ${token}` } });
      const data = await res.json();
      const questions: any[] = data.questions ?? [];

      if (questions.length === 0) { showToast('⚠️ Aucune question trouvée', 'error'); setExporting(false); return; }

      const mat = matieres.find(m => m.id === exportMatiereId);
      const serie = exportSeriesList.find(s => s.id === exportSerieId);
      const filename = `${mat?.nom ?? 'export'}${serie ? '_' + serie.titre : ''}_${new Date().toLocaleDateString('fr-FR').replace(/\//g, '-')}`;

      if (exportFormat === 'csv') {
        const headers = 'enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte';
        const rows = questions.map(q =>
          [q.enonce, q.option_a, q.option_b, q.option_c, q.option_d, q.bonne_reponse, q.explication, q.difficulte]
            .map(v => `"${(v || '').replace(/"/g, '""')}"`)
            .join(';')
        );
        downloadFile(filename + '.csv', '\uFEFF' + [headers, ...rows].join('\n'), 'text/csv;charset=utf-8;');
      } else if (exportFormat === 'json') {
        downloadFile(filename + '.json', JSON.stringify(questions, null, 2), 'application/json');
      } else {
        const md = questions.map((q, i) =>
          `Question : ${q.enonce}\nA) ${q.option_a}\nB) ${q.option_b}\n${q.option_c ? `C) ${q.option_c}\n` : ''}${q.option_d ? `D) ${q.option_d}\n` : ''}Bonne réponse : ${q.bonne_reponse}\n${q.explication ? `Explication : ${q.explication}\n` : ''}`
        ).join('\n\n');
        downloadFile(filename + '.md', md, 'text/markdown');
      }

      showToast(`✅ ${questions.length} questions exportées !`);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setExporting(false); }
  }

  function downloadFile(name: string, content: string, type: string) {
    const blob = new Blob([content], { type });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = name; a.click();
    URL.revokeObjectURL(url);
  }

  // ── Template à télécharger ──────────────────────────────────
  function downloadTemplate(format: 'csv' | 'json' | 'markdown') {
    if (format === 'csv') {
      const content = `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte
"Quelle est la capitale du Burkina Faso ?";"Bobo-Dioulasso";"Ouagadougou";"Koudougou";"Banfora";"B";"Ouagadougou est la capitale politique et administrative du Burkina Faso";"DEBUTANT"
"Quel est l'organisme de gestion des fonctionnaires au Burkina ?";"MFPTSS";"DGRH";"ANFP";"CNAS";"C";"L'ANFP (Agence Nationale de Formation Professionnelle) gère les fonctionnaires";"INTERMEDIAIRE"`;
      downloadFile('template_qcm.csv', '\uFEFF' + content, 'text/csv;charset=utf-8;');
    } else if (format === 'json') {
      const content = JSON.stringify([
        {
          enonce: "Quelle est la capitale du Burkina Faso ?",
          option_a: "Bobo-Dioulasso",
          option_b: "Ouagadougou",
          option_c: "Koudougou",
          option_d: "Banfora",
          bonne_reponse: "B",
          explication: "Ouagadougou est la capitale politique et administrative",
          difficulte: "DEBUTANT"
        },
        {
          enonce: "Quel est le rôle principal du DGRH ?",
          option_a: "Gérer les marchés publics",
          option_b: "Gérer les ressources humaines de l'État",
          option_c: "Superviser les concours",
          option_d: "Contrôler les dépenses",
          bonne_reponse: "B",
          explication: "Le DGRH est la Direction Générale des Ressources Humaines",
          difficulte: "INTERMEDIAIRE"
        }
      ], null, 2);
      downloadFile('template_qcm.json', content, 'application/json');
    } else {
      const content = `Question : Quelle est la capitale du Burkina Faso ?
A) Bobo-Dioulasso
B) Ouagadougou
C) Koudougou
D) Banfora
Bonne réponse : B
Explication : Ouagadougou est la capitale politique et administrative du Burkina Faso.

Question : Quel est l'organisme en charge des concours au Burkina Faso ?
A) MFPTSS
B) DGRH
C) ANFP
D) CNAS
Bonne réponse : C
Explication : L'ANFP organise les concours de la fonction publique.`;
      downloadFile('template_qcm.md', content, 'text/markdown');
    }
  }

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

      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ color: S.text, fontSize: 22, fontWeight: 700, marginBottom: 4 }}>
          📤 Import / Export de QCM
        </h2>
        <p style={{ color: S.muted, fontSize: 13 }}>
          Importez vos questions en masse ou exportez pour sauvegarde. Formats : CSV, JSON, Markdown/Texte
        </p>
      </div>

      {/* Tabs */}
      <div style={{ display: 'flex', gap: 2, marginBottom: 24, borderBottom: `1px solid ${S.border}` }}>
        {[
          { key: 'import', icon: '📥', label: 'Importer des QCM' },
          { key: 'export', icon: '📤', label: 'Exporter des QCM' },
          { key: 'template', icon: '📋', label: 'Modèles de fichiers' },
        ].map(tab => (
          <button key={tab.key} onClick={() => setActiveTab(tab.key as any)} style={{
            padding: '10px 18px', background: 'transparent', border: 'none',
            borderBottom: activeTab === tab.key ? `2px solid ${S.green}` : '2px solid transparent',
            color: activeTab === tab.key ? S.text : S.muted,
            fontWeight: activeTab === tab.key ? 700 : 400,
            cursor: 'pointer', fontSize: 14,
          }}>
            {tab.icon} {tab.label}
          </button>
        ))}
      </div>

      {/* ══ TAB : IMPORT ══════════════════════════════════════ */}
      {activeTab === 'import' && (
        <div style={{ display: 'grid', gridTemplateColumns: '340px 1fr', gap: 20 }}>
          {/* Config gauche */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
            {/* Destination */}
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 18 }}>
              <h4 style={{ color: S.text, fontSize: 14, fontWeight: 700, marginBottom: 14 }}>📌 Destination</h4>
              <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
                <div>
                  <label style={labelStyle}>Matière cible *</label>
                  <select value={selectedMatiere} onChange={e => {
                    setSelectedMatiere(e.target.value);
                    setSelectedSerie('');
                    if (e.target.value) loadSeries(e.target.value, 'import');
                  }} style={inputStyle}>
                    <option value="">— Sélectionner —</option>
                    {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
                  </select>
                </div>
                {selectedMatiere && (
                  <div>
                    <label style={labelStyle}>Série (optionnel)</label>
                    {loadingSeries ? (
                      <div style={{ color: S.muted, fontSize: 12 }}>Chargement…</div>
                    ) : (
                      <select value={selectedSerie} onChange={e => setSelectedSerie(e.target.value)} style={inputStyle}>
                        <option value="">— Sans série —</option>
                        {series.map(s => <option key={s.id} value={s.id}>{s.titre}</option>)}
                      </select>
                    )}
                  </div>
                )}
              </div>
            </div>

            {/* Mode saisie */}
            <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 18 }}>
              <h4 style={{ color: S.text, fontSize: 14, fontWeight: 700, marginBottom: 14 }}>📄 Source des données</h4>
              <div style={{ display: 'flex', gap: 8, marginBottom: 14 }}>
                {[
                  { key: 'file', label: '📁 Fichier' },
                  { key: 'text', label: '✍️ Texte brut' },
                ].map(m => (
                  <button key={m.key} onClick={() => setInputMode(m.key as any)} style={{
                    flex: 1, padding: '7px 0', borderRadius: 7,
                    border: `1px solid ${inputMode === m.key ? S.green : S.border}`,
                    background: inputMode === m.key ? `${S.green}30` : '#0f172a',
                    color: inputMode === m.key ? S.success : S.muted,
                    cursor: 'pointer', fontSize: 13, fontWeight: inputMode === m.key ? 700 : 400,
                  }}>{m.label}</button>
                ))}
              </div>

              {inputMode === 'file' ? (
                <div onClick={() => fileRef.current?.click()} style={{
                  border: `2px dashed ${file ? S.green : S.border}`, borderRadius: 10,
                  padding: '20px 16px', textAlign: 'center', cursor: 'pointer', background: '#0f172a',
                }}>
                  <div style={{ fontSize: 30, marginBottom: 8 }}>{file ? '✅' : '📎'}</div>
                  <div style={{ color: S.text, fontSize: 13, fontWeight: 600 }}>
                    {file ? file.name : 'Cliquer pour choisir'}
                  </div>
                  <div style={{ color: S.muted, fontSize: 11, marginTop: 4 }}>
                    .csv, .json, .txt, .md, .markdown
                  </div>
                  <input ref={fileRef} type="file" accept=".csv,.json,.txt,.md,.markdown"
                    onChange={handleFileChange} style={{ display: 'none' }} />
                </div>
              ) : (
                <textarea value={textInput} onChange={e => handleTextChange(e.target.value)}
                  placeholder={`Question : Quelle est la capitale du Burkina Faso ?\nA) Bobo-Dioulasso\nB) Ouagadougou\nC) Koudougou\nD) Banfora\nBonne réponse : B\nExplication : Ouagadougou est la capitale.`}
                  rows={8} style={{ ...inputStyle, resize: 'vertical', fontSize: 12, fontFamily: 'monospace' }} />
              )}
            </div>

            {/* Stats + bouton import */}
            {parsed.length > 0 && (
              <div style={{ background: '#0f2a1a', borderRadius: 12, border: `1px solid ${S.success}`, padding: 16 }}>
                <div style={{ color: S.success, fontWeight: 700, fontSize: 18 }}>{parsed.length}</div>
                <div style={{ color: S.muted, fontSize: 12 }}>questions prêtes à importer</div>
                <button onClick={handleImport} disabled={importing || !selectedMatiere}
                  style={{ ...btnPrimary, marginTop: 12, width: '100%', opacity: !selectedMatiere ? 0.5 : 1 }}>
                  {importing ? '⏳ Import en cours…' : `✅ Importer ${parsed.length} questions`}
                </button>
              </div>
            )}

            {importResult && (
              <div style={{ background: '#065f46', borderRadius: 10, border: `1px solid ${S.success}`, padding: 14 }}>
                <div style={{ color: S.success, fontWeight: 700, fontSize: 14 }}>
                  ✅ Import terminé !
                </div>
                <div style={{ color: S.text, fontSize: 13, marginTop: 6 }}>
                  {importResult.success} importées · {importResult.errors} erreurs · {importResult.total} total
                </div>
              </div>
            )}
          </div>

          {/* Prévisualisation droite */}
          <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
            <div style={{ padding: '12px 16px', background: '#0f172a', borderBottom: `1px solid ${S.border}` }}>
              <h4 style={{ color: S.text, fontSize: 14, fontWeight: 700, margin: 0 }}>
                👁 Prévisualisation ({parsed.length} questions)
              </h4>
            </div>
            {parsed.length === 0 ? (
              <div style={{ padding: 40, textAlign: 'center', color: S.muted, fontSize: 13 }}>
                <div style={{ fontSize: 40, marginBottom: 12 }}>📂</div>
                Chargez un fichier ou saisissez vos questions pour prévisualiser
              </div>
            ) : (
              <div style={{ maxHeight: 560, overflowY: 'auto' }}>
                {parsed.map((q, i) => (
                  <div key={i} style={{ padding: '12px 16px', borderBottom: `1px solid #1e293b` }}>
                    <div style={{ color: S.muted, fontSize: 11, marginBottom: 4 }}>
                      #{i + 1} · Difficulté : {q.difficulte}
                    </div>
                    <div style={{ color: S.text, fontSize: 13, fontWeight: 600, lineHeight: 1.4, marginBottom: 6 }}>
                      {q.enonce}
                    </div>
                    <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 4 }}>
                      {[
                        { k: 'A', v: q.option_a },
                        { k: 'B', v: q.option_b },
                        ...(q.option_c ? [{ k: 'C', v: q.option_c }] : []),
                        ...(q.option_d ? [{ k: 'D', v: q.option_d }] : []),
                      ].map(({ k, v }) => (
                        <div key={k} style={{
                          padding: '4px 8px', borderRadius: 5,
                          background: q.bonne_reponse === k ? '#065f46' : '#0f172a',
                          border: `1px solid ${q.bonne_reponse === k ? S.success : S.border}`,
                          color: q.bonne_reponse === k ? S.success : S.muted,
                          fontSize: 12,
                        }}>
                          <strong>{k})</strong> {v}
                        </div>
                      ))}
                    </div>
                    {q.explication && (
                      <div style={{ color: S.muted, fontSize: 11, marginTop: 6, fontStyle: 'italic' }}>
                        💡 {q.explication}
                      </div>
                    )}
                  </div>
                ))}
              </div>
            )}
          </div>
        </div>
      )}

      {/* ══ TAB : EXPORT ══════════════════════════════════════ */}
      {activeTab === 'export' && (
        <div style={{ maxWidth: 500 }}>
          <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 24 }}>
            <h4 style={{ color: S.text, fontSize: 15, fontWeight: 700, marginBottom: 20 }}>
              📤 Exporter des questions
            </h4>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 14 }}>
              <div>
                <label style={labelStyle}>Matière *</label>
                <select value={exportMatiereId} onChange={e => {
                  setExportMatiereId(e.target.value);
                  setExportSerieId('');
                  if (e.target.value) loadSeries(e.target.value, 'export');
                }} style={inputStyle}>
                  <option value="">— Sélectionner une matière —</option>
                  {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
                </select>
              </div>
              {exportMatiereId && (
                <div>
                  <label style={labelStyle}>Série (optionnel — vide = toutes les séries)</label>
                  <select value={exportSerieId} onChange={e => setExportSerieId(e.target.value)} style={inputStyle}>
                    <option value="">— Toutes les séries —</option>
                    {exportSeriesList.map(s => <option key={s.id} value={s.id}>{s.titre}</option>)}
                  </select>
                </div>
              )}
              <div>
                <label style={labelStyle}>Format d'export</label>
                <div style={{ display: 'flex', gap: 8 }}>
                  {[
                    { k: 'csv', label: '📊 CSV' },
                    { k: 'json', label: '🔧 JSON' },
                    { k: 'markdown', label: '📝 Markdown' },
                  ].map(f => (
                    <button key={f.k} onClick={() => setExportFormat(f.k as any)} style={{
                      flex: 1, padding: '8px 0', borderRadius: 7,
                      border: `1px solid ${exportFormat === f.k ? S.green : S.border}`,
                      background: exportFormat === f.k ? `${S.green}30` : '#0f172a',
                      color: exportFormat === f.k ? S.success : S.muted,
                      cursor: 'pointer', fontSize: 13, fontWeight: exportFormat === f.k ? 700 : 400,
                    }}>{f.label}</button>
                  ))}
                </div>
              </div>
              <button onClick={handleExport} disabled={exporting || !exportMatiereId} style={{
                ...btnPrimary, opacity: !exportMatiereId ? 0.5 : 1, marginTop: 4,
              }}>
                {exporting ? '⏳ Export en cours…' : `⬇ Exporter en ${exportFormat.toUpperCase()}`}
              </button>
            </div>
          </div>
        </div>
      )}

      {/* ══ TAB : TEMPLATES ═══════════════════════════════════ */}
      {activeTab === 'template' && (
        <div>
          <div style={{ marginBottom: 16, color: S.text, fontSize: 14 }}>
            Téléchargez un modèle de fichier pour préparer vos questions à importer.
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 16 }}>
            {[
              {
                format: 'csv' as const,
                icon: '📊',
                title: 'Modèle CSV',
                desc: 'Fichier Excel/tableur. Colonnes : enonce, option_a, option_b, option_c, option_d, bonne_reponse, explication, difficulte.',
                badge: 'Excel compatible',
                badgeColor: '#065f46',
              },
              {
                format: 'json' as const,
                icon: '🔧',
                title: 'Modèle JSON',
                desc: 'Format JSON structuré. Tableau d\'objets avec les champs enonce, option_a–d, bonne_reponse, explication.',
                badge: 'Développeurs',
                badgeColor: '#1e3a5f',
              },
              {
                format: 'markdown' as const,
                icon: '📝',
                title: 'Modèle Markdown/Texte',
                desc: 'Format texte lisible. Question:, A), B), C), D), Bonne réponse:, Explication:. Un bloc par question.',
                badge: 'Le plus simple',
                badgeColor: '#3b1f5a',
              },
            ].map(t => (
              <div key={t.format} style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 20 }}>
                <div style={{ fontSize: 36, marginBottom: 12 }}>{t.icon}</div>
                <div style={{ display: 'flex', gap: 8, marginBottom: 10, alignItems: 'center' }}>
                  <h4 style={{ color: S.text, fontSize: 15, fontWeight: 700, margin: 0 }}>{t.title}</h4>
                  <span style={{ background: t.badgeColor, color: '#fff', fontSize: 10, padding: '2px 7px', borderRadius: 4, fontWeight: 600 }}>{t.badge}</span>
                </div>
                <p style={{ color: S.muted, fontSize: 12, lineHeight: 1.5, marginBottom: 16 }}>{t.desc}</p>
                <button onClick={() => downloadTemplate(t.format)} style={btnPrimary}>
                  ⬇ Télécharger le modèle
                </button>
              </div>
            ))}
          </div>

          {/* Format attendu */}
          <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, padding: 20, marginTop: 20 }}>
            <h4 style={{ color: S.text, fontSize: 14, fontWeight: 700, marginBottom: 14 }}>
              📋 Format Markdown attendu (reconnu automatiquement)
            </h4>
            <pre style={{
              background: '#0f172a', borderRadius: 8, padding: 16, fontSize: 12,
              color: '#94a3b8', fontFamily: 'monospace', lineHeight: 1.7, overflowX: 'auto',
              border: `1px solid ${S.border}`,
            }}>{`Question : Quelle est la capitale du Burkina Faso ?
A) Bobo-Dioulasso
B) Ouagadougou
C) Koudougou
D) Banfora
Bonne réponse : B
Explication : Ouagadougou est la capitale politique et administrative.

Question : Quel est le rôle du DGRH ?
A) Gérer les marchés publics
B) Superviser les élections
C) Gérer les ressources humaines de l'État
D) Contrôler les finances
Bonne réponse : C
Explication : Direction Générale des Ressources Humaines.`}</pre>
          </div>
        </div>
      )}
    </div>
  );
}

// ── Styles ────────────────────────────────────────────────────
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
