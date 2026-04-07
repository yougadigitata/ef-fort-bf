import { useState, useRef, useEffect } from 'react';
import { validateBulk, bulkImport, getMatieres, getImportHistory, cancelImport } from '../api';
import type { Page } from '../App';

// ══════════════════════════════════════════════════════════════
// CMS QCM — Import en Masse v7.0
// 3 modes : QCM Matières | Simulation (Examen Blanc) | Examen Type
// Import MD/TXT/CSV/JSON · Choix matière destination
// Ajout à la SUITE des existantes · Séries harmonisées
// ══════════════════════════════════════════════════════════════

type ImportMode = 'qcm' | 'simulation' | 'examen_type';

export default function BulkImportPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [mode, setMode] = useState<ImportMode>('qcm');
  const [step, setStep] = useState<'upload' | 'validate' | 'import' | 'done'>('upload');
  const [file, setFile] = useState<File | null>(null);
  const [rawData, setRawData] = useState<any[]>([]);
  const [matieres, setMatieres] = useState<any[]>([]);
  const [selectedMatiere, setSelectedMatiere] = useState('');
  const [validation, setValidation] = useState<any>(null);
  const [importResult, setImportResult] = useState<any>(null);
  const [history, setHistory] = useState<any[]>([]);
  const [loading, setLoading] = useState(false);
  const [showHistory, setShowHistory] = useState(false);
  const [showMatieres, setShowMatieres] = useState(false);
  const [toast, setToast] = useState('');
  // Champs pour simulation / examen type
  const [examenTitre, setExamenTitre] = useState('');
  const [examenType, setExamenType] = useState<'simulation' | 'examen_type'>('simulation');
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { loadMatieres(); }, []);

  async function loadMatieres() {
    try {
      const data = await getMatieres();
      setMatieres(data.matieres ?? []);
    } catch (_) {}
  }

  async function loadHistory() {
    try {
      const data = await getImportHistory();
      setHistory(data.imports ?? []);
      setShowHistory(true);
    } catch (_) {}
  }

  function showToast(msg: string) { setToast(msg); setTimeout(() => setToast(''), 5000); }

  function resetAll() {
    setStep('upload'); setFile(null); setRawData([]); setValidation(null); setImportResult(null);
    if (fileInputRef.current) fileInputRef.current.value = '';
  }

  function switchMode(m: ImportMode) { setMode(m); resetAll(); }

  function getCmsBase() {
    return window.location.hostname === 'localhost'
      ? 'http://localhost:8787/api/admin-cms'
      : 'https://ef-fort-bf.yembuaro29.workers.dev/api/admin-cms';
  }
  function getToken() { return localStorage.getItem('admin_token') ?? ''; }

  // ── Templates téléchargeables ──────────────────────────────────────────

  function downloadBlob(content: string, filename: string, mime: string) {
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url; a.download = filename; a.click();
    URL.revokeObjectURL(url);
  }

  function downloadCSVTemplate() {
    const m = matieres.find(x => x.id === selectedMatiere || x.matiere_id === selectedMatiere);
    const mid = m?.matiere_id ?? m?.id ?? 'UUID_MATIERE_ICI';
    const csv = `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id\nCapitale du Burkina Faso ?;Bobo-Dioulasso;Ouagadougou;Koudougou;Banfora;B;Ouagadougou est la capitale politique du BF.;FACILE;${mid}\nFondateurs de l'AES ?;Nations Unies;Burkina+Mali+Niger;France+Sahel;CEDEAO;B;Fondée en 2023.;MOYEN;${mid}\nAnnée indépendance BF ?;1956;1960;1962;1966;B;Indépendance le 5 août 1960.;FACILE;${mid}`;
    downloadBlob(csv, 'template_qcm_matiere.csv', 'text/csv;charset=utf-8;');
    showToast('✅ Template CSV QCM téléchargé !');
  }

  function downloadMDTemplate() {
    const md = `## Quelle est la capitale du Burkina Faso ?
A) Bobo-Dioulasso
B) Ouagadougou *
C) Koudougou
D) Banfora
Explication: Ouagadougou est la capitale politique et économique du BF.

## Qui a fondé l'Alliance des États du Sahel ?
A) Les Nations Unies
B) Le Burkina Faso, le Mali et le Niger ✓
C) La France
D) L'UEMOA
Bonne réponse: B
Explication: L'AES a été fondée en 2023.

## En quelle année le Burkina Faso est-il devenu indépendant ?
A) 1956
B) 1960 *
C) 1962
D) 1966
Explication: La Haute-Volta a accédé à l'indépendance le 5 août 1960.
`;
    downloadBlob(md, 'template_questions.md', 'text/markdown;charset=utf-8;');
    showToast('✅ Template Markdown téléchargé !');
  }

  function downloadJSONTemplate() {
    const m = matieres.find(x => x.id === selectedMatiere || x.matiere_id === selectedMatiere);
    const mid = m?.matiere_id ?? m?.id ?? 'UUID_MATIERE_ICI';
    const json = [
      { enonce: "Capitale du Burkina Faso ?", option_a: "Bobo-Dioulasso", option_b: "Ouagadougou", option_c: "Koudougou", option_d: "Banfora", bonne_reponse: "B", explication: "Ouagadougou est la capitale.", difficulte: "FACILE", matiere_id: mid },
      { enonce: "Fondateurs de l'AES ?", option_a: "Nations Unies", option_b: "BF+Mali+Niger", bonne_reponse: "B", explication: "Fondée en 2023.", difficulte: "MOYEN", matiere_id: mid },
    ];
    downloadBlob(JSON.stringify(json, null, 2), 'template_qcm.json', 'application/json');
    showToast('✅ Template JSON téléchargé !');
  }

  function downloadSimuMDTemplate() {
    let md = `# Simulation — Concours ENAM 2026\n# 50 questions de culture générale\n\n`;
    for (let i = 1; i <= 50; i++) {
      md += `## Question ${i} — Exemple\nA) Option A\nB) Option B (bonne réponse) *\nC) Option C\nD) Option D\nExplication: Explication détaillée de la bonne réponse B.\n\n`;
    }
    downloadBlob(md, 'template_simulation_50q.md', 'text/markdown;charset=utf-8;');
    showToast('✅ Template Simulation 50 questions téléchargé !');
  }

  function downloadExamenTypeMDTemplate() {
    const md = `## Quelle est la capitale du Burkina Faso ?
A) Bobo-Dioulasso
B) Ouagadougou *
C) Koudougou
D) Banfora
Explication: Ouagadougou est la capitale politique.

## Qui a fondé l'AES ?
A) Nations Unies
B) Burkina, Mali, Niger ✓
C) France
D) CEDEAO
Explication: Fondée en septembre 2023 après le G5 Sahel.

## Monnaie du Burkina Faso ?
A) Euro
B) Dollar
C) Franc CFA *
D) Naira
Explication: Le Franc CFA (XOF) est la monnaie de l'UEMOA.
`;
    downloadBlob(md, 'template_examen_type.md', 'text/markdown;charset=utf-8;');
    showToast('✅ Template Examen Type téléchargé !');
  }

  function copyMatiereId(id: string, nom: string) {
    navigator.clipboard.writeText(id)
      .then(() => showToast(`✅ ID copié : ${nom}`))
      .catch(() => showToast(`ID : ${id}`));
  }

  // ── Lecture du fichier ─────────────────────────────────────────────────
  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f); setValidation(null); setStep('upload');
    const text = await f.text();
    try {
      if (f.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        setRawData(Array.isArray(parsed) ? parsed : parsed.questions ?? []);
      } else if (f.name.match(/\.(md|txt|markdown)$/)) {
        const lines = text.split('\n').filter(l => l.trim());
        const qCount = lines.filter(l => l.match(/^#{1,3}\s+|^\d+[\.\)]\s+.{10,}/)).length;
        setRawData([{ preview: `Fichier MD/TXT — ~${qCount} questions détectées`, line: 1 }]);
      } else {
        const lines = text.split('\n').filter(l => l.trim());
        setRawData(lines.slice(1, 6).map((l, i) => ({ preview: l.substring(0, 80), line: i + 2 })));
      }
    } catch (_) {}
  }

  // ── Validation ─────────────────────────────────────────────────────────
  async function handleValidate() {
    if (!file) return;
    setLoading(true);
    try {
      const isMdTxt = file.name.match(/\.(md|txt|markdown)$/);
      let data: any;
      if (isMdTxt) {
        const rawText = await file.text();
        const res = await fetch(`${getCmsBase()}/questions/validate-bulk`, {
          method: 'POST',
          headers: { 'Content-Type': 'text/plain', 'Authorization': `Bearer ${getToken()}` },
          body: rawText,
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur validation');
      } else {
        const text = await file.text();
        let questions: any[] = [];
        if (file.name.endsWith('.json')) {
          const parsed = JSON.parse(text);
          questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
        } else {
          const lines = text.split('\n').filter(l => l.trim());
          if (lines.length < 2) { showToast('❌ Fichier CSV vide ou invalide'); return; }
          const headers = lines[0].split(';').map((h: string) => h.trim().toLowerCase());
          questions = lines.slice(1).map((line: string) => {
            const vals = line.split(';').map((v: string) => v.trim().replace(/^[\"']|[\"']$/g, ''));
            const obj: any = {};
            headers.forEach((h: string, i: number) => { obj[h] = vals[i] ?? ''; });
            return obj;
          });
        }
        data = await validateBulk(questions, selectedMatiere || undefined);
        data.questions = questions;
      }
      setValidation({ ...data, _isMdTxt: !!isMdTxt, _rawFile: file });
      setStep('validate');
    } catch (err: any) {
      showToast('❌ Erreur validation: ' + err.message);
    } finally {
      setLoading(false);
    }
  }

  // ── Import QCM Matières ────────────────────────────────────────────────
  async function handleImportQCM() {
    if (!validation?.ready_to_import) return;
    const nbSeries = Math.ceil((validation.total_valid ?? 0) / 20);
    const selectedM = matieres.find(m => m.id === selectedMatiere || m.matiere_id === selectedMatiere);
    const destLabel = selectedM ? `→ ${selectedM.nom}` : '→ matière définie dans le fichier';
    if (!confirm(`⚠️ Importer ${validation.total_valid} questions QCM ?\n\n📁 Destination : ${destLabel}\n✅ ${nbSeries} série(s) de 20 questions seront créées à la SUITE des existantes.\n✅ Aucun doublon de série ne sera créé.\n✅ Les questions seront immédiatement visibles.`)) return;
    setLoading(true); setStep('import');
    try {
      let data: any;
      if (validation._isMdTxt && validation._rawFile) {
        const rawText = await (validation._rawFile as File).text();
        const url = selectedMatiere
          ? `${getCmsBase()}/questions/bulk-import?matiere_id=${selectedMatiere}`
          : `${getCmsBase()}/questions/bulk-import`;
        const res = await fetch(url, {
          method: 'POST',
          headers: { 'Content-Type': 'text/plain', 'Authorization': `Bearer ${getToken()}` },
          body: rawText,
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur import');
      } else {
        const formData = new FormData();
        formData.append('file', validation._rawFile as File);
        if (selectedMatiere) formData.append('matiere_id', selectedMatiere);
        const res = await fetch(`${getCmsBase()}/questions/bulk-import`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${getToken()}` },
          body: formData,
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur import');
      }
      setImportResult({ ...data, _mode: 'qcm', _matiere: selectedM?.nom });
      setStep('done');
      showToast(`✅ ${data.imported} questions importées en ${data.duration_seconds}s !`);
    } catch (err: any) {
      showToast('❌ Erreur import: ' + err.message);
      setStep('validate');
    } finally {
      setLoading(false);
    }
  }

  // ── Import Simulation (Examen Blanc) ou Examen Type ────────────────────
  async function handleImportExamen() {
    if (!validation?.ready_to_import) return;
    const isSimu = mode === 'simulation';
    const questionTarget = isSimu ? 50 : validation.total_valid;
    const titre = examenTitre.trim() || `${isSimu ? 'Examen Blanc' : 'Examen Type'} — ${new Date().toLocaleDateString('fr-FR')} — ${validation.total_valid} questions`;
    const typeLabel = isSimu ? 'Examen Blanc (Simulation)' : 'Examen Type';

    if (!confirm(`⚠️ Créer un ${typeLabel} de ${validation.total_valid} questions ?\n\nTitre : "${titre}"\n\n✅ Les questions seront présentées sur une feuille de questions (gauche)\n✅ Le candidat répond sur la feuille de cases (droite)\n✅ À la soumission : corrections détaillées + export PDF\n✅ Statut initial : Brouillon (à publier depuis "Simulations & Examens")`)) return;
    setLoading(true); setStep('import');
    try {
      let data: any;
      if (validation._isMdTxt && validation._rawFile) {
        const rawText = await (validation._rawFile as File).text();
        const res = await fetch(`${getCmsBase()}/examens/bulk-import`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${getToken()}` },
          body: JSON.stringify({
            questions_text: rawText,
            titre,
            format: 'md',
            type: mode, // 'simulation' ou 'examen_type'
          }),
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur import examen');
      } else {
        const formData = new FormData();
        formData.append('file', validation._rawFile as File);
        formData.append('titre', titre);
        formData.append('type', mode);
        const res = await fetch(`${getCmsBase()}/examens/bulk-import`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${getToken()}` },
          body: formData,
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur import examen');
      }
      setImportResult({ ...data, _mode: mode, _titre: titre });
      setStep('done');
      showToast(`✅ ${typeLabel} créé : ${data.imported} questions !`);
    } catch (err: any) {
      showToast('❌ Erreur : ' + err.message);
      setStep('validate');
    } finally {
      setLoading(false);
    }
  }

  async function handleCancelImport(importId: string) {
    if (!confirm('Annuler cet import et supprimer les questions importées ?')) return;
    try {
      const data = await cancelImport(importId);
      showToast(`✅ Import annulé. ${data.deleted} questions supprimées.`);
      loadHistory();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  const selectedMatiereInfo = matieres.find(m => m.id === selectedMatiere || m.matiere_id === selectedMatiere);

  // ── RENDER ─────────────────────────────────────────────────────────────
  return (
    <div style={{ maxWidth: 1100 }}>
      {toast && (
        <div style={{
          position: 'fixed', top: 70, right: 20, padding: '14px 20px',
          background: '#1e293b', border: '1px solid #334155', borderRadius: 10,
          color: '#e2e8f0', fontSize: 17, zIndex: 1000, maxWidth: 420,
          boxShadow: '0 10px 30px rgba(0,0,0,0.3)',
        }}>{toast}</div>
      )}

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>📤 CMS QCM — Import en masse</h2>
          <p style={{ color: '#64748b', fontSize: 16, marginTop: 4 }}>
            Importez des QCM matières · des Simulations (Examen Blanc) · ou des Examens Types
          </p>
        </div>
        <button onClick={loadHistory} style={{ background: '#334155', border: 'none', color: '#94a3b8', padding: '8px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 16 }}>
          📜 Historique
        </button>
      </div>

      {/* ── ONGLETS MODE ─────────────────────────────────────────────────── */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 24, background: '#0f172a', borderRadius: 12, padding: 6, border: '1px solid #334155' }}>
        <ModeTab
          active={mode === 'qcm'}
          emoji="📚" title="QCM Matières"
          subtitle="Séries de 20 questions · Matières existantes"
          color="#1A5C38"
          onClick={() => switchMode('qcm')}
        />
        <ModeTab
          active={mode === 'simulation'}
          emoji="📄" title="Simulation (Examen Blanc)"
          subtitle="50 questions · Feuille réponses · Section Examen"
          color="#2563eb"
          onClick={() => switchMode('simulation')}
        />
        <ModeTab
          active={mode === 'examen_type'}
          emoji="🏆" title="Examen Type"
          subtitle="Questions par concours · Vrai sujet type"
          color="#7c3aed"
          onClick={() => switchMode('examen_type')}
        />
      </div>

      {/* ══════════════════════════════════════════ MODE QCM ═══════════════ */}
      {mode === 'qcm' && (
        <>
          {/* Étape 0 : Sélection matière */}
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
              0️⃣ Choisir la matière de destination
              <span style={{ color: '#64748b', fontSize: 15, fontWeight: 400 }}> (recommandé — sinon, mettre matiere_id dans chaque ligne du fichier)</span>
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'end' }}>
              <div>
                <label style={lbl}>📁 Dossier de destination</label>
                <select value={selectedMatiere} onChange={e => setSelectedMatiere(e.target.value)} style={sel}>
                  <option value="">— Utiliser le matiere_id présent dans chaque ligne du fichier —</option>
                  {matieres.map(m => (
                    <option key={m.id ?? m.matiere_id} value={m.matiere_id ?? m.id}>
                      {m.icone ?? '📚'} {m.nom} ({m.nb_questions ?? 0} questions existantes)
                    </option>
                  ))}
                </select>
              </div>
              <button onClick={() => setShowMatieres(!showMatieres)} style={{
                background: '#334155', border: 'none', color: '#94a3b8',
                padding: '9px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 16, whiteSpace: 'nowrap',
              }}>
                🗂️ Voir IDs
              </button>
            </div>

            {selectedMatiereInfo && (
              <div style={{ marginTop: 10, padding: '10px 14px', background: 'rgba(26,92,56,0.15)', borderRadius: 8, border: '1px solid rgba(26,92,56,0.3)' }}>
                <span style={{ color: '#4ade80', fontSize: 16 }}>
                  ✅ Destination : <strong>{selectedMatiereInfo.icone} {selectedMatiereInfo.nom}</strong>
                  &nbsp;— Toutes les questions seront ajoutées à la suite des <strong>{selectedMatiereInfo.nb_questions ?? 0}</strong> questions existantes.
                </span>
              </div>
            )}

            {showMatieres && (
              <div style={{ marginTop: 16 }}>
                <div style={{ color: '#94a3b8', fontSize: 15, marginBottom: 8 }}>Cliquez pour copier l'UUID de la matière :</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(270px, 1fr))', gap: 6 }}>
                  {matieres.map(m => (
                    <div key={m.id ?? m.matiere_id} onClick={() => copyMatiereId(m.matiere_id ?? m.id, m.nom)} style={{
                      padding: '6px 10px', background: '#0f172a', borderRadius: 6,
                      cursor: 'pointer', display: 'flex', justifyContent: 'space-between',
                      border: '1px solid #334155', fontSize: 15,
                    }} title="Cliquer pour copier l'ID">
                      <span style={{ color: '#e2e8f0', fontWeight: 600 }}>{m.icone ?? '📚'} {m.nom}</span>
                      <span style={{ color: '#475569', fontFamily: 'monospace', fontSize: 13 }}>
                        {(m.matiere_id ?? m.id ?? '').substring(0, 12)}... 📋
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Note harmonisation séries */}
            <div style={{ marginTop: 14, padding: '10px 14px', background: 'rgba(212,160,23,0.08)', border: '1px solid rgba(212,160,23,0.25)', borderRadius: 8, fontSize: 15, color: '#D4A017' }}>
              <strong>📐 Règle des séries :</strong> Les nouvelles questions sont <strong>ajoutées à la suite</strong> des séries existantes.
              Chaque série contient <strong>exactement 20 questions</strong>. Si la dernière série est incomplète, elle sera complétée d'abord.
              Aucun doublon de série ne sera créé.
            </div>

            {/* Templates QCM */}
            <div style={{ marginTop: 16 }}>
              <div style={{ color: '#94a3b8', fontSize: 15, marginBottom: 8, fontWeight: 600 }}>
                📥 Télécharger un template :
                {selectedMatiereInfo && <span style={{ color: '#4ade80' }}> (pré-rempli avec {selectedMatiereInfo.nom})</span>}
              </div>
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <button onClick={downloadCSVTemplate} style={btnTemplate('#D4A017', 'rgba(212,160,23,0.12)', 'rgba(212,160,23,0.4)')}>📊 Template CSV</button>
                <button onClick={downloadMDTemplate} style={btnTemplate('#10b981', 'rgba(16,185,129,0.12)', 'rgba(16,185,129,0.4)')}>📝 Template Markdown/TXT</button>
                <button onClick={downloadJSONTemplate} style={btnTemplate('#3b82f6', 'rgba(59,130,246,0.12)', 'rgba(59,130,246,0.4)')}>📄 Template JSON</button>
              </div>
            </div>
          </div>

          <FormatGuide mode="qcm" />
        </>
      )}

      {/* ═════════════════════════════ MODE SIMULATION ═════════════════════ */}
      {mode === 'simulation' && (
        <>
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #2563eb40', marginBottom: 20 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
              📄 Configurer l'Examen Blanc (Simulation)
            </h3>
            <div style={{ marginBottom: 14 }}>
              <label style={lbl}>Titre de la simulation <span style={{ color: '#64748b', fontWeight: 400 }}>(optionnel)</span></label>
              <input
                value={examenTitre}
                onChange={e => setExamenTitre(e.target.value)}
                placeholder="Ex: Examen Blanc — Concours ENAM 2026"
                style={{ ...sel, color: '#e2e8f0' }}
              />
            </div>

            <div style={{ background: 'rgba(37,99,235,0.08)', border: '1px solid rgba(37,99,235,0.3)', borderRadius: 8, padding: '14px 16px', fontSize: 16 }}>
              <div style={{ color: '#93c5fd', fontWeight: 600, marginBottom: 8 }}>📄 Comment fonctionne l'Examen Blanc ?</div>
              <div style={{ color: '#bfdbfe', lineHeight: 1.7 }}>
                ✅ Importez <strong>50 questions</strong> d'examen (CSV, JSON, Markdown ou TXT)<br/>
                ✅ Les questions sont présentées sur la <strong>feuille de questions</strong> (colonne gauche)<br/>
                ✅ Le candidat <strong>noircit les cases A/B/C/D/E</strong> sur la feuille de réponses (droite)<br/>
                ✅ À la soumission : <strong>score + corrections détaillées + export PDF</strong><br/>
                ✅ Visible dans la section <strong>Examen → Onglet "Examens Blancs"</strong><br/>
                ✅ Statut initial : <strong>Brouillon</strong> — à publier depuis "Simulations & Examens"
              </div>
            </div>

            <div style={{ marginTop: 16 }}>
              <div style={{ color: '#94a3b8', fontSize: 15, marginBottom: 8, fontWeight: 600 }}>📥 Templates :</div>
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <button onClick={downloadSimuMDTemplate} style={btnTemplate('#93c5fd', 'rgba(37,99,235,0.12)', 'rgba(37,99,235,0.4)')}>📝 Template Simulation 50 questions (MD)</button>
                <button onClick={downloadMDTemplate} style={btnTemplate('#10b981', 'rgba(16,185,129,0.12)', 'rgba(16,185,129,0.4)')}>📄 Format Markdown court</button>
              </div>
            </div>
          </div>

          <FormatGuide mode="examen" />
        </>
      )}

      {/* ═════════════════════════════ MODE EXAMEN TYPE ════════════════════ */}
      {mode === 'examen_type' && (
        <>
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #7c3aed40', marginBottom: 20 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
              🏆 Configurer l'Examen Type (Vrai Sujet)
            </h3>
            <div style={{ marginBottom: 14 }}>
              <label style={lbl}>Titre de l'examen type <span style={{ color: '#64748b', fontWeight: 400 }}>(optionnel)</span></label>
              <input
                value={examenTitre}
                onChange={e => setExamenTitre(e.target.value)}
                placeholder="Ex: Concours MFPRE 2024 — Épreuve écrite de culture générale"
                style={{ ...sel, color: '#e2e8f0' }}
              />
            </div>

            <div style={{ background: 'rgba(124,58,237,0.08)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: 8, padding: '14px 16px', fontSize: 16 }}>
              <div style={{ color: '#c4b5fd', fontWeight: 600, marginBottom: 8 }}>🏆 Comment fonctionne l'Examen Type ?</div>
              <div style={{ color: '#ddd6fe', lineHeight: 1.7 }}>
                ✅ Importez un vrai sujet d'examen (nombre de questions libre)<br/>
                ✅ Même présentation que la simulation : <strong>questions à gauche, réponses à droite</strong><br/>
                ✅ Visible dans la section <strong>Examen → Onglet "Examens Types"</strong><br/>
                ✅ Les réponses/corrections s'affichent avec explications détaillées après soumission<br/>
                ✅ Export PDF de la copie corrigée disponible<br/>
                ✅ Statut initial : <strong>Brouillon</strong> — à publier depuis "Simulations & Examens"
              </div>
            </div>

            <div style={{ marginTop: 16 }}>
              <div style={{ color: '#94a3b8', fontSize: 15, marginBottom: 8, fontWeight: 600 }}>📥 Templates :</div>
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <button onClick={downloadExamenTypeMDTemplate} style={btnTemplate('#c4b5fd', 'rgba(124,58,237,0.12)', 'rgba(124,58,237,0.4)')}>📝 Template Examen Type (MD)</button>
                <button onClick={downloadMDTemplate} style={btnTemplate('#10b981', 'rgba(16,185,129,0.12)', 'rgba(16,185,129,0.4)')}>📄 Format Markdown court</button>
              </div>
            </div>
          </div>

          <FormatGuide mode="examen" />
        </>
      )}

      {/* ── UPLOAD FICHIER (commun tous modes) ───────────────────────────── */}
      <div style={{
        background: '#1e293b', borderRadius: 12, padding: 24,
        border: `1px solid ${mode === 'qcm' ? '#334155' : mode === 'simulation' ? '#2563eb40' : '#7c3aed40'}`,
        marginBottom: 20,
      }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 16 }}>
          1️⃣ Uploader le fichier
          <span style={{ color: '#64748b', fontSize: 15, fontWeight: 400 }}> — CSV, JSON, Markdown (.md), TXT</span>
        </h3>

        <div
          onClick={() => fileInputRef.current?.click()}
          onDragOver={e => e.preventDefault()}
          onDrop={e => {
            e.preventDefault();
            const f = e.dataTransfer.files[0];
            if (f) {
              const dt = new DataTransfer(); dt.items.add(f);
              if (fileInputRef.current) {
                fileInputRef.current.files = dt.files;
                handleFileSelect({ target: fileInputRef.current } as any);
              }
            }
          }}
          style={{
            border: `2px dashed ${file ? (mode === 'qcm' ? '#1A5C38' : mode === 'simulation' ? '#2563eb' : '#7c3aed') : '#334155'}`,
            borderRadius: 10, padding: 36, textAlign: 'center', cursor: 'pointer', transition: 'all 0.2s',
            background: file ? (mode === 'qcm' ? 'rgba(26,92,56,0.06)' : mode === 'simulation' ? 'rgba(37,99,235,0.06)' : 'rgba(124,58,237,0.06)') : 'rgba(255,255,255,0.02)',
          }}
        >
          <input ref={fileInputRef} type="file" accept=".csv,.json,.md,.txt,.markdown" onChange={handleFileSelect} style={{ display: 'none' }} />
          {!file ? (
            <>
              <div style={{ fontSize: 40, marginBottom: 12 }}>📂</div>
              <div style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 6 }}>
                Glissez votre fichier ici ou cliquez pour choisir
              </div>
              <div style={{ color: '#64748b', fontSize: 15 }}>
                Formats supportés : <strong style={{ color: '#94a3b8' }}>CSV · JSON · Markdown (.md) · TXT</strong>
              </div>
            </>
          ) : (
            <>
              <div style={{ fontSize: 32, marginBottom: 8 }}>
                {file.name.endsWith('.csv') ? '📊' : file.name.endsWith('.json') ? '📄' : '📝'}
              </div>
              <div style={{ color: '#4ade80', fontSize: 18, fontWeight: 700 }}>{file.name}</div>
              <div style={{ color: '#64748b', fontSize: 15, marginTop: 4 }}>
                {(file.size / 1024).toFixed(1)} Ko · {rawData.length} ligne(s) prévisualisées · Cliquez pour changer
              </div>
            </>
          )}
        </div>

        {/* Aperçu */}
        {rawData.length > 0 && step === 'upload' && (
          <div style={{ marginTop: 14 }}>
            <div style={{ color: '#64748b', fontSize: 15, marginBottom: 6 }}>📋 Aperçu :</div>
            {rawData.slice(0, 3).map((row: any, i: number) => (
              <div key={i} style={{ padding: '6px 10px', background: '#0f172a', borderRadius: 6, marginBottom: 4, fontSize: 15, color: '#94a3b8', overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {row.preview ?? JSON.stringify(row).substring(0, 100)}
              </div>
            ))}
          </div>
        )}

        {/* Bouton valider */}
        {file && step === 'upload' && (
          <button onClick={handleValidate} disabled={loading} style={{
            marginTop: 16, width: '100%', padding: '12px 0', border: 'none', borderRadius: 8,
            fontWeight: 700, fontSize: 17, cursor: loading ? 'wait' : 'pointer', color: 'white',
            background: mode === 'qcm' ? 'linear-gradient(135deg, #1A5C38, #2d9966)'
              : mode === 'simulation' ? 'linear-gradient(135deg, #1d4ed8, #3b82f6)'
              : 'linear-gradient(135deg, #7c3aed, #a855f7)',
            opacity: loading ? 0.7 : 1,
          }}>
            {loading ? '⏳ Analyse en cours...' : '🔍 Analyser et valider le fichier →'}
          </button>
        )}
      </div>

      {/* ── Étape 2 : Résultats validation ────────────────────────────────── */}
      {step === 'validate' && validation && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 20 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 20 }}>
            2️⃣ Résultats de la validation
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="✅ Valides" value={validation.total_valid ?? 0} color="#4ade80" />
            <StatCard label="❌ Invalides" value={validation.total_invalid ?? 0} color="#ef4444" />
            <StatCard label="Total lignes" value={(validation.total_valid ?? 0) + (validation.total_invalid ?? 0)} color="#94a3b8" />
            <StatCard
              label={mode === 'qcm' ? '📚 Séries créées' : '📋 Questions'}
              value={mode === 'qcm' ? `${Math.ceil((validation.total_valid ?? 0) / 20)} série(s)` : `${validation.total_valid ?? 0} Q`}
              color="#D4A017"
            />
          </div>

          {validation.total_invalid > 0 && (
            <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.2)', borderRadius: 8, padding: 14, marginBottom: 16 }}>
              <div style={{ color: '#ef4444', fontWeight: 600, marginBottom: 8 }}>❌ Erreurs détectées :</div>
              {(validation.errors ?? []).slice(0, 5).map((e: any, i: number) => (
                <div key={i} style={{ color: '#fca5a5', fontSize: 15, marginBottom: 4 }}>
                  • Ligne {e.line ?? i + 1} : {e.error ?? JSON.stringify(e)}
                </div>
              ))}
            </div>
          )}

          {validation.total_valid > 0 && (
            <div style={{ background: 'rgba(74,222,128,0.06)', border: '1px solid rgba(74,222,128,0.2)', borderRadius: 8, padding: 14, marginBottom: 16, fontSize: 16, color: '#86efac', lineHeight: 1.7 }}>
              {mode === 'qcm' ? (
                <>
                  ✅ <strong>{validation.total_valid}</strong> questions prêtes à l'import<br/>
                  ✅ Destination : <strong>{selectedMatiereInfo?.nom ?? 'matière définie dans le fichier'}</strong><br/>
                  ✅ <strong>{Math.ceil(validation.total_valid / 20)}</strong> série(s) de 20 questions seront ajoutées à la suite des existantes<br/>
                  ✅ Les séries incomplètes existantes seront complétées en priorité
                </>
              ) : (
                <>
                  ✅ <strong>{validation.total_valid}</strong> questions prêtes pour {mode === 'simulation' ? 'l\'Examen Blanc' : 'l\'Examen Type'}<br/>
                  ✅ Présentation : questions à gauche, cases de réponses à droite<br/>
                  ✅ Corrections détaillées disponibles après soumission
                </>
              )}
            </div>
          )}

          <div style={{ display: 'flex', gap: 12 }}>
            <button onClick={resetAll} style={{ padding: '10px 18px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer', fontWeight: 600, fontSize: 17 }}>
              ← Recommencer
            </button>
            {validation.ready_to_import && (
              <button
                onClick={mode === 'qcm' ? handleImportQCM : handleImportExamen}
                disabled={loading}
                style={{
                  flex: 1, padding: '12px 0', border: 'none', borderRadius: 8, fontWeight: 700, fontSize: 18,
                  cursor: loading ? 'wait' : 'pointer', color: 'white', opacity: loading ? 0.7 : 1,
                  background: mode === 'qcm' ? 'linear-gradient(135deg, #1A5C38, #2d9966)'
                    : mode === 'simulation' ? 'linear-gradient(135deg, #1d4ed8, #3b82f6)'
                    : 'linear-gradient(135deg, #7c3aed, #a855f7)',
                }}
              >
                {loading ? '⏳ Import en cours...' :
                  mode === 'qcm'
                    ? `🚀 IMPORTER — ${validation.total_valid} questions → ${Math.ceil(validation.total_valid / 20)} série(s)`
                    : mode === 'simulation'
                    ? `📄 CRÉER SIMULATION — ${validation.total_valid} questions`
                    : `🏆 CRÉER EXAMEN TYPE — ${validation.total_valid} questions`
                }
              </button>
            )}
          </div>
        </div>
      )}

      {/* ── Import en cours ───────────────────────────────────────────────── */}
      {step === 'import' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 48, border: '1px solid #334155', textAlign: 'center', marginBottom: 20 }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>
            {mode === 'qcm' ? '⏳' : mode === 'simulation' ? '📄' : '🏆'}
          </div>
          <div style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 700 }}>
            {mode === 'qcm' ? 'Import QCM en cours...' : mode === 'simulation' ? 'Création de la Simulation...' : 'Création de l\'Examen Type...'}
          </div>
          <div style={{ color: '#64748b', fontSize: 16, marginTop: 8 }}>
            {mode === 'qcm' ? 'Traitement par lots · Création des séries (20q) · Aucun doublon' : 'Génération de la feuille de réponses · Insertion des questions'}
          </div>
          <div style={{ height: 6, background: '#334155', borderRadius: 3, marginTop: 24, overflow: 'hidden', maxWidth: 400, margin: '24px auto 0' }}>
            <div style={{
              height: '100%', width: '60%', borderRadius: 3,
              background: mode === 'qcm' ? 'linear-gradient(90deg, #1A5C38, #2d9966)' : mode === 'simulation' ? 'linear-gradient(90deg, #1d4ed8, #3b82f6)' : 'linear-gradient(90deg, #7c3aed, #a855f7)',
              animation: 'loading 1.5s ease-in-out infinite',
            }} />
          </div>
          <style>{`@keyframes loading { 0%{width:5%} 50%{width:85%} 100%{width:5%} }`}</style>
        </div>
      )}

      {/* ── Résultats ─────────────────────────────────────────────────────── */}
      {step === 'done' && importResult && (
        <div style={{
          background: '#1e293b', borderRadius: 12, padding: 24, marginBottom: 20,
          border: `1px solid ${importResult._mode === 'qcm' ? 'rgba(74,222,128,0.3)' : importResult._mode === 'simulation' ? 'rgba(147,197,253,0.3)' : 'rgba(196,181,253,0.3)'}`,
        }}>
          <h3 style={{
            fontSize: 20, fontWeight: 800, marginBottom: 20,
            color: importResult._mode === 'qcm' ? '#4ade80' : importResult._mode === 'simulation' ? '#93c5fd' : '#c4b5fd',
          }}>
            {importResult._mode === 'qcm' ? '✅ Import QCM terminé !' : importResult._mode === 'simulation' ? '📄 Simulation créée !' : '🏆 Examen Type créé !'}
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="✅ Importées" value={importResult.imported} color="#4ade80" />
            <StatCard label="❌ Échecs" value={importResult.failed ?? 0} color="#ef4444" />
            <StatCard label="Total traité" value={importResult.total ?? importResult.imported} color="#94a3b8" />
            <StatCard label="Durée" value={`${importResult.duration_seconds ?? 0}s`} color="#D4A017" />
          </div>

          {importResult._mode === 'qcm' ? (
            <div style={{ background: 'rgba(74,222,128,0.06)', border: '1px solid rgba(74,222,128,0.2)', borderRadius: 10, padding: 16, marginBottom: 20, fontSize: 16, color: '#86efac', lineHeight: 1.8 }}>
              🎉 <strong>{importResult.imported}</strong> questions disponibles immédiatement !<br/>
              📁 Destination : <strong>{importResult._matiere ?? 'Matière définie dans le fichier'}</strong><br/>
              📚 <strong>{Math.ceil(importResult.imported / 20)}</strong> série(s) de 20 questions créées/complétées<br/>
              ✅ Toutes les séries ont exactement 20 questions (ou moins si quota insuffisant)
            </div>
          ) : (
            <div style={{ background: importResult._mode === 'simulation' ? 'rgba(37,99,235,0.08)' : 'rgba(124,58,237,0.08)', border: importResult._mode === 'simulation' ? '1px solid rgba(37,99,235,0.3)' : '1px solid rgba(124,58,237,0.3)', borderRadius: 10, padding: 16, marginBottom: 20, fontSize: 16, lineHeight: 1.8 }}>
              <div style={{ color: importResult._mode === 'simulation' ? '#93c5fd' : '#c4b5fd', fontWeight: 700, marginBottom: 6 }}>
                {importResult._mode === 'simulation' ? '📄 Simulation créée !' : '🏆 Examen Type créé !'}
              </div>
              <div style={{ color: importResult._mode === 'simulation' ? '#bfdbfe' : '#ddd6fe', lineHeight: 1.7 }}>
                ✅ Titre : <strong>{importResult._titre}</strong><br/>
                ✅ <strong>{importResult.imported}</strong> questions importées avec corrections<br/>
                ✅ Feuille de réponses de <strong>{importResult.imported} cases</strong> générée automatiquement<br/>
                ✅ Simulation ID : <code style={{ background: '#0f172a', padding: '2px 6px', borderRadius: 4, fontSize: 14 }}>{importResult.simulation_id}</code><br/>
                ✅ État : <strong>Brouillon</strong> — Publiez depuis "Simulations & Examens"
              </div>
            </div>
          )}

          <div style={{ display: 'flex', gap: 12 }}>
            <button onClick={resetAll} style={{ padding: '10px 20px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer', fontWeight: 600 }}>
              📤 Nouvel import
            </button>
            <button
              onClick={() => onNavigate(importResult._mode === 'qcm' ? 'questions' : 'simulations')}
              style={{
                flex: 1, padding: '10px 20px', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 700, fontSize: 17,
                background: importResult._mode === 'qcm' ? 'linear-gradient(135deg, #1A5C38, #2d9966)' : importResult._mode === 'simulation' ? 'linear-gradient(135deg, #1d4ed8, #3b82f6)' : 'linear-gradient(135deg, #7c3aed, #a855f7)',
              }}
            >
              {importResult._mode === 'qcm' ? `Voir les ${importResult.imported} questions →` : '🎯 Gérer les Simulations & Examens →'}
            </button>
          </div>
        </div>
      )}

      {/* ── Historique ────────────────────────────────────────────────────── */}
      {showHistory && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600 }}>📜 Historique des imports</h3>
            <button onClick={() => setShowHistory(false)} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 18 }}>✕</button>
          </div>
          {history.length === 0 ? (
            <p style={{ color: '#64748b', fontSize: 16 }}>Aucun import enregistré</p>
          ) : history.map((imp: any) => (
            <div key={imp.id} style={{ padding: '12px 0', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ color: '#e2e8f0', fontSize: 16, fontWeight: 600 }}>{imp.filename ?? 'Import #' + imp.id}</div>
                <div style={{ color: '#64748b', fontSize: 15, marginTop: 2 }}>
                  {new Date(imp.created_at).toLocaleString('fr-FR')} — {imp.imported_count ?? 0} questions
                  {imp.import_duration_seconds && ` en ${imp.import_duration_seconds}s`}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <StatusBadge status={imp.status} />
                {imp.status === 'success' && (
                  <button onClick={() => handleCancelImport(imp.id)} style={{
                    background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                    color: '#ef4444', padding: '6px 14px', borderRadius: 6, cursor: 'pointer', fontSize: 15,
                  }}>🗑️ Annuler</button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

// ── Composants ────────────────────────────────────────────────────────────

function ModeTab({ active, emoji, title, subtitle, color, onClick }: {
  active: boolean; emoji: string; title: string; subtitle: string; color: string; onClick: () => void;
}) {
  return (
    <button onClick={onClick} style={{
      flex: 1, padding: '12px 10px', borderRadius: 8, border: 'none', cursor: 'pointer',
      fontWeight: 700, fontSize: 16, transition: 'all 0.2s', textAlign: 'center',
      background: active ? `linear-gradient(135deg, ${color}, ${color}cc)` : 'transparent',
      color: active ? 'white' : '#64748b',
    }}>
      <div style={{ fontSize: 20, marginBottom: 4 }}>{emoji}</div>
      {title}
      <div style={{ fontSize: 14, fontWeight: 400, marginTop: 3, opacity: 0.85 }}>{subtitle}</div>
    </button>
  );
}

function FormatGuide({ mode }: { mode: 'qcm' | 'examen' }) {
  return (
    <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
      <h3 style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 600, marginBottom: 12 }}>
        📋 Formats supportés {mode === 'examen' ? '(simulation/examen type)' : '(QCM matières)'}
      </h3>
      <div style={{ background: 'rgba(212,160,23,0.1)', border: '1px solid rgba(212,160,23,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 14, fontSize: 16, color: '#D4A017' }}>
        ⚡ <strong>Bonne réponse :</strong> A, B, C, D ou E (majuscule).
        Marquer avec <code>*</code> ou <code>✓</code> après l'option, ou ligne <code>Bonne réponse: B</code>.
        Difficulté = FACILE, MOYEN ou DIFFICILE.
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 16 }}>
        <div>
          <div style={{ color: '#10b981', fontSize: 16, fontWeight: 600, marginBottom: 6 }}>📝 Markdown / TXT (recommandé)</div>
          <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 13, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{`## Quelle est la capitale du BF ?
A) Bobo-Dioulasso
B) Ouagadougou *
C) Koudougou
D) Banfora
Explication: Ouaga est la capitale.

## Fondateurs de l'AES ?
A) Nations Unies
B) Burkina, Mali, Niger ✓
C) France
D) CEDEAO
Bonne réponse: B`}
          </pre>
        </div>
        <div>
          <div style={{ color: '#D4A017', fontSize: 16, fontWeight: 600, marginBottom: 6 }}>📊 CSV (séparateur ;)</div>
          <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 13, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{mode === 'qcm'
  ? `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id
Capitale BF?;Bobo;Ouaga;Koudo;Banfora;B;Ouaga...;FACILE;[UUID]`
  : `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte
Capitale BF?;Bobo;Ouaga;Koudo;Banfora;B;Ouaga est la capitale;FACILE`}
          </pre>
        </div>
        <div>
          <div style={{ color: '#3b82f6', fontSize: 16, fontWeight: 600, marginBottom: 6 }}>📄 JSON</div>
          <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 13, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{`[{
  "enonce": "Capitale BF ?",
  "option_a": "Bobo",
  "option_b": "Ouaga",
  "bonne_reponse": "B",
  "explication": "Ouaga...",
  "difficulte": "FACILE"${mode === 'qcm' ? `,\n  "matiere_id": "[UUID]"` : ''}
}]`}
          </pre>
        </div>
      </div>
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: any; color: string }) {
  return (
    <div style={{ background: '#0f172a', borderRadius: 10, padding: 14, textAlign: 'center' }}>
      <div style={{ color, fontSize: 22, fontWeight: 900 }}>{typeof value === 'number' ? value.toLocaleString() : value}</div>
      <div style={{ color: '#64748b', fontSize: 15, marginTop: 4 }}>{label}</div>
    </div>
  );
}

function StatusBadge({ status }: { status: string }) {
  const c: Record<string, any> = {
    success: { bg: 'rgba(74,222,128,0.1)', color: '#4ade80', label: '✅ Succès' },
    pending: { bg: 'rgba(251,191,36,0.1)', color: '#fbbf24', label: '⏳ En cours' },
    failed: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444', label: '❌ Échoué' },
    partial_error: { bg: 'rgba(251,191,36,0.1)', color: '#fbbf24', label: '⚠️ Partiel' },
    cancelled: { bg: 'rgba(148,163,184,0.1)', color: '#94a3b8', label: '🚫 Annulé' },
  };
  const s = c[status] ?? c.pending;
  return <span style={{ background: s.bg, color: s.color, padding: '3px 10px', borderRadius: 10, fontSize: 15, fontWeight: 600 }}>{s.label}</span>;
}

function btnTemplate(color: string, bg: string, border: string): React.CSSProperties {
  return { padding: '8px 14px', background: bg, border: `1px solid ${border}`, color, borderRadius: 8, cursor: 'pointer', fontSize: 16, fontWeight: 600 };
}

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 15, marginBottom: 6, fontWeight: 600 };
const sel: React.CSSProperties = {
  width: '100%', padding: '10px 12px', background: '#0f172a',
  border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 17,
};
