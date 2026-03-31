import { useState, useRef, useEffect } from 'react';
import { validateBulk, bulkImport, getMatieres, getImportHistory, cancelImport, bulkImportExamen } from '../api';
import type { Page } from '../App';

type ImportMode = 'qcm' | 'examen';

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
  // Champs spécifiques examen
  const [examenTitre, setExamenTitre] = useState('');
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

  // ── Changer de mode ───────────────────────────────────────────────────────
  function switchMode(m: ImportMode) {
    setMode(m);
    resetAll();
  }

  // ── Helpers URL ───────────────────────────────────────────────────────────
  function getCmsBase() {
    return window.location.hostname === 'localhost'
      ? 'http://localhost:8787/api/admin-cms'
      : 'https://ef-fort-bf.yembuaro29.workers.dev/api/admin-cms';
  }

  function getToken() { return localStorage.getItem('admin_token') ?? ''; }

  // ── Télécharger template CSV QCM ──────────────────────────────────────
  function downloadCSVTemplate() {
    const selectedM = matieres.find(m => m.id === selectedMatiere || m.matiere_id === selectedMatiere);
    const matiereId = selectedM?.matiere_id ?? selectedM?.id ?? 'UUID_MATIERE_ICI';
    const csvContent = `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id
Quelle est la capitale du Burkina Faso ?;Bobo-Dioulasso;Ouagadougou;Koudougou;Banfora;B;Ouagadougou est la capitale politique et économique du Burkina Faso depuis l'indépendance.;FACILE;${matiereId}
Qui a fondé l'AES ?;Les Nations Unies;Le Burkina, Mali et Niger;La France et le Mali;L'UEMOA;B;L'Alliance des États du Sahel a été fondée par le Burkina Faso, le Mali et le Niger en 2023.;MOYEN;${matiereId}
Quand le Burkina Faso a-t-il obtenu son indépendance ?;3 janvier 1966;5 août 1960;11 décembre 1958;1er janvier 1970;B;La Haute-Volta (actuel Burkina Faso) a accédé à l'indépendance le 5 août 1960.;FACILE;${matiereId}`;
    downloadBlob(csvContent, 'template_qcm.csv', 'text/csv;charset=utf-8;');
    showToast('✅ Template CSV téléchargé !');
  }

  // ── Télécharger template JSON QCM ─────────────────────────────────────
  function downloadJSONTemplate() {
    const selectedM = matieres.find(m => m.id === selectedMatiere || m.matiere_id === selectedMatiere);
    const matiereId = selectedM?.matiere_id ?? selectedM?.id ?? 'UUID_MATIERE_ICI';
    const jsonContent = [
      { enonce: "Quelle est la capitale du Burkina Faso ?", option_a: "Bobo-Dioulasso", option_b: "Ouagadougou", option_c: "Koudougou", option_d: "Banfora", bonne_reponse: "B", explication: "Ouagadougou est la capitale.", difficulte: "FACILE", matiere_id: matiereId },
      { enonce: "Qui a fondé l'AES ?", option_a: "Les Nations Unies", option_b: "Le Burkina, Mali et Niger", option_c: "La France et le Mali", option_d: "L'UEMOA", bonne_reponse: "B", explication: "AES fondée en 2023.", difficulte: "MOYEN", matiere_id: matiereId }
    ];
    downloadBlob(JSON.stringify(jsonContent, null, 2), 'template_qcm.json', 'application/json');
    showToast('✅ Template JSON téléchargé !');
  }

  // ── Télécharger template Examen CSV ───────────────────────────────────
  function downloadExamenCSVTemplate() {
    const csv = `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte
Quelle est la capitale du Burkina Faso ?;Bobo-Dioulasso;Ouagadougou;Koudougou;Banfora;B;Ouagadougou est la capitale.;FACILE
Qui a fondé l'AES ?;ONU;Burkina+Mali+Niger;France;UA;B;Fondée en 2023.;MOYEN
En quelle année le Burkina Faso est-il devenu indépendant ?;1958;1960;1962;1966;B;Indépendance le 5 août 1960.;FACILE
Quelle est la monnaie du Burkina Faso ?;Franc CFA;Euro;Dollar;Naira;A;Le FCFA est utilisé.;FACILE
Quel est le chef-lieu de la région du Centre ?;Koudougou;Ouagadougou;Bobo;Dédougou;B;Le chef-lieu est Ouagadougou.;MOYEN`;
    downloadBlob(csv, 'template_examen.csv', 'text/csv;charset=utf-8;');
    showToast('✅ Template Examen CSV (5 questions exemples) téléchargé !');
  }

  // ── Télécharger template Examen Markdown ──────────────────────────────
  function downloadExamenMDTemplate() {
    const md = `## Quelle est la capitale du Burkina Faso ?
A) Bobo-Dioulasso
B) Ouagadougou *
C) Koudougou
D) Banfora
Explication: Ouagadougou est la capitale politique et économique.

## Qui a fondé l'Alliance des États du Sahel ?
A) Les Nations Unies
B) Le Burkina Faso, le Mali et le Niger *
C) La France et le Mali
D) L'UEMOA
Bonne réponse: B
Explication: L'AES a été fondée en 2023.

## En quelle année le Burkina Faso est-il devenu indépendant ?
A) 1958
B) 1960 ✓
C) 1962
D) 1966
Explication: La Haute-Volta a accédé à l'indépendance le 5 août 1960.
`;
    downloadBlob(md, 'template_examen.md', 'text/markdown;charset=utf-8;');
    showToast('✅ Template Examen Markdown téléchargé !');
  }

  function downloadBlob(content: string, filename: string, mime: string) {
    const blob = new Blob([content], { type: mime });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url; link.download = filename; link.click();
    URL.revokeObjectURL(url);
  }

  function copyMatiereId(id: string, nom: string) {
    navigator.clipboard.writeText(id).then(() => {
      showToast(`✅ ID copié : ${nom}`);
    }).catch(() => {
      showToast(`ID : ${id}`);
    });
  }

  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f); setValidation(null); setStep('upload');
    const text = await f.text();
    try {
      if (f.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        setRawData(Array.isArray(parsed) ? parsed : parsed.questions ?? []);
      } else if (f.name.endsWith('.md') || f.name.endsWith('.txt') || f.name.endsWith('.markdown')) {
        const lines = text.split('\n').filter(l => l.trim());
        const qCount = lines.filter(l => l.match(/^#{1,3}\s+|^\d+[\.\)]\s+.{10,}|^[Qq]uestion\s*\d+/)).length;
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
      const isMdTxt = file.name.endsWith('.md') || file.name.endsWith('.txt') || file.name.endsWith('.markdown');
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
            const vals = line.split(';').map((v: string) => v.trim().replace(/^["']|["']$/g, ''));
            const obj: any = {};
            headers.forEach((h: string, i: number) => { obj[h] = vals[i] ?? ''; });
            return obj;
          });
        }
        data = await validateBulk(questions, selectedMatiere || undefined);
        data.questions = questions;
      }

      setValidation({ ...data, _isMdTxt: isMdTxt, _rawFile: file });
      setStep('validate');
    } catch (err: any) {
      showToast('❌ Erreur validation: ' + err.message);
    } finally {
      setLoading(false);
    }
  }

  // ── Import QCM ─────────────────────────────────────────────────────────
  async function handleImportQCM() {
    if (!validation?.ready_to_import) return;
    const nbSeries = Math.ceil((validation.total_valid ?? 0) / 20);
    if (!confirm(`⚠️ Importer ${validation.total_valid} questions ?\n\nElles seront immédiatement visibles pour tous les utilisateurs.\n✅ ${nbSeries} série(s) de 20 questions seront créées automatiquement.`)) return;
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
        // Envoyer le fichier directement via FormData pour éviter les limites de payload JSON
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
      setImportResult({ ...data, _mode: 'qcm' });
      setStep('done');
      showToast(`✅ ${data.imported} questions importées en ${data.duration_seconds}s !`);
    } catch (err: any) {
      showToast('❌ Erreur import: ' + err.message);
      setStep('validate');
    } finally {
      setLoading(false);
    }
  }

  // ── Import Examen ───────────────────────────────────────────────────────
  async function handleImportExamen() {
    if (!validation?.ready_to_import) return;
    const titre = examenTitre.trim() || `Examen ${new Date().toLocaleDateString('fr-FR')} — ${validation.total_valid} questions`;
    if (!confirm(`⚠️ Créer un examen de ${validation.total_valid} questions ?\n\nTitre : "${titre}"\n\n✅ Une feuille de réponses de ${validation.total_valid} cases sera générée automatiquement.\n✅ L'examen sera visible dans la section Simulations (état brouillon).`)) return;
    setLoading(true); setStep('import');
    try {
      let data: any;
      if (validation._isMdTxt && validation._rawFile) {
        const rawText = await (validation._rawFile as File).text();
        const res = await fetch(`${getCmsBase()}/examens/bulk-import`, {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'Authorization': `Bearer ${getToken()}` },
          body: JSON.stringify({ questions_text: rawText, titre, format: 'md' }),
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur import examen');
      } else {
        // Envoyer via FormData
        const formData = new FormData();
        formData.append('file', validation._rawFile as File);
        formData.append('titre', titre);
        const res = await fetch(`${getCmsBase()}/examens/bulk-import`, {
          method: 'POST',
          headers: { 'Authorization': `Bearer ${getToken()}` },
          body: formData,
        });
        data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur import examen');
      }
      setImportResult({ ...data, _mode: 'examen', _titre: titre });
      setStep('done');
      showToast(`✅ Examen créé : ${data.imported} questions !`);
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

  return (
    <div style={{ maxWidth: 1000 }}>
      {toast && (
        <div style={{
          position: 'fixed', top: 70, right: 20, padding: '14px 20px',
          background: '#1e293b', border: '1px solid #334155', borderRadius: 10,
          color: '#e2e8f0', fontSize: 14, zIndex: 1000, maxWidth: 400,
          boxShadow: '0 10px 30px rgba(0,0,0,0.3)',
        }}>{toast}</div>
      )}

      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>📤 Import en masse</h2>
          <p style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
            Importez des QCM (matières/séries) ou des Examens (50 questions + feuille de réponses)
          </p>
        </div>
        <button onClick={loadHistory} style={{ background: '#334155', border: 'none', color: '#94a3b8', padding: '8px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 13 }}>
          📜 Historique
        </button>
      </div>

      {/* ── ONGLETS MODE ─────────────────────────────────────────────────── */}
      <div style={{ display: 'flex', gap: 4, marginBottom: 24, background: '#0f172a', borderRadius: 12, padding: 6, border: '1px solid #334155' }}>
        <button
          onClick={() => switchMode('qcm')}
          style={{
            flex: 1, padding: '12px 16px', borderRadius: 8, border: 'none', cursor: 'pointer', fontWeight: 700, fontSize: 14, transition: 'all 0.2s',
            background: mode === 'qcm' ? 'linear-gradient(135deg, #1A5C38, #2d9966)' : 'transparent',
            color: mode === 'qcm' ? 'white' : '#64748b',
          }}
        >
          📚 QCM Matières
          <div style={{ fontSize: 11, fontWeight: 400, marginTop: 2, opacity: 0.85 }}>
            18 matières · séries de 20 questions
          </div>
        </button>
        <button
          onClick={() => switchMode('examen')}
          style={{
            flex: 1, padding: '12px 16px', borderRadius: 8, border: 'none', cursor: 'pointer', fontWeight: 700, fontSize: 14, transition: 'all 0.2s',
            background: mode === 'examen' ? 'linear-gradient(135deg, #7c3aed, #a855f7)' : 'transparent',
            color: mode === 'examen' ? 'white' : '#64748b',
          }}
        >
          🎓 Examen Officiel
          <div style={{ fontSize: 11, fontWeight: 400, marginTop: 2, opacity: 0.85 }}>
            50 questions · feuille de réponses
          </div>
        </button>
      </div>

      {/* ══════════════════════════════════════════════════════ */}
      {/* ── MODE QCM ──────────────────────────────────────── */}
      {/* ══════════════════════════════════════════════════════ */}
      {mode === 'qcm' && (
        <>
          {/* Étape 0 : Sélection matière */}
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>
              0️⃣ Choisir la matière <span style={{ color: '#64748b', fontSize: 12, fontWeight: 400 }}>(recommandé)</span>
            </h3>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr auto', gap: 12, alignItems: 'end' }}>
              <div>
                <label style={lbl}>Matière cible</label>
                <select value={selectedMatiere} onChange={e => setSelectedMatiere(e.target.value)} style={sel}>
                  <option value="">— Utiliser le matiere_id dans chaque ligne du fichier —</option>
                  {matieres.map(m => (
                    <option key={m.id ?? m.matiere_id} value={m.matiere_id ?? m.id}>
                      {m.nom} ({m.nb_questions ?? 0} questions)
                    </option>
                  ))}
                </select>
              </div>
              <button onClick={() => setShowMatieres(!showMatieres)} style={{
                background: '#334155', border: 'none', color: '#94a3b8',
                padding: '9px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 13, whiteSpace: 'nowrap',
              }}>
                🗂️ Voir IDs
              </button>
            </div>

            {selectedMatiereInfo && (
              <div style={{ marginTop: 10, padding: '8px 12px', background: 'rgba(26,92,56,0.15)', borderRadius: 8, border: '1px solid rgba(26,92,56,0.3)' }}>
                <span style={{ color: '#4ade80', fontSize: 13 }}>
                  ✅ Matière sélectionnée : <strong>{selectedMatiereInfo.nom}</strong> — Toutes les questions iront dans cette matière.
                </span>
              </div>
            )}

            {showMatieres && (
              <div style={{ marginTop: 16 }}>
                <div style={{ color: '#94a3b8', fontSize: 12, marginBottom: 8 }}>Cliquez pour copier l'UUID :</div>
                <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(270px, 1fr))', gap: 6 }}>
                  {matieres.map(m => (
                    <div key={m.id ?? m.matiere_id} onClick={() => copyMatiereId(m.matiere_id ?? m.id, m.nom)} style={{
                      padding: '6px 10px', background: '#0f172a', borderRadius: 6,
                      cursor: 'pointer', display: 'flex', justifyContent: 'space-between',
                      border: '1px solid #334155', fontSize: 12,
                    }} title="Cliquer pour copier l'ID">
                      <span style={{ color: '#e2e8f0', fontWeight: 600 }}>{m.icone ?? '📚'} {m.nom}</span>
                      <span style={{ color: '#475569', fontFamily: 'monospace', fontSize: 10 }}>
                        {(m.matiere_id ?? m.id ?? '').substring(0, 12)}... 📋
                      </span>
                    </div>
                  ))}
                </div>
              </div>
            )}

            {/* Templates QCM */}
            <div style={{ marginTop: 16 }}>
              <div style={{ color: '#94a3b8', fontSize: 12, marginBottom: 8, fontWeight: 600 }}>
                📥 Télécharger un template :
                {selectedMatiereInfo && <span style={{ color: '#4ade80' }}> (pré-rempli avec l'ID de {selectedMatiereInfo.nom})</span>}
              </div>
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <button onClick={downloadCSVTemplate} style={btnTemplate('#D4A017', 'rgba(212,160,23,0.15)', 'rgba(212,160,23,0.4)')}>📊 Template CSV</button>
                <button onClick={downloadJSONTemplate} style={btnTemplate('#3b82f6', 'rgba(59,130,246,0.15)', 'rgba(59,130,246,0.4)')}>📄 Template JSON</button>
              </div>
            </div>
          </div>

          {/* Format guide QCM */}
          <FormatGuide mode="qcm" />
        </>
      )}

      {/* ══════════════════════════════════════════════════════ */}
      {/* ── MODE EXAMEN ────────────────────────────────────── */}
      {/* ══════════════════════════════════════════════════════ */}
      {mode === 'examen' && (
        <>
          {/* Config examen */}
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #7c3aed40', marginBottom: 20 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>
              🎓 Configuration de l'examen
            </h3>
            <div style={{ marginBottom: 14 }}>
              <label style={lbl}>Titre de l'examen <span style={{ color: '#64748b', fontWeight: 400 }}>(optionnel — auto-généré si vide)</span></label>
              <input
                value={examenTitre}
                onChange={e => setExamenTitre(e.target.value)}
                placeholder={`Ex: Concours ENAM 2025 — Épreuve de Culture Générale`}
                style={{ ...sel, color: '#e2e8f0' }}
              />
            </div>

            <div style={{ background: 'rgba(124,58,237,0.1)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: 8, padding: '12px 14px', fontSize: 13 }}>
              <div style={{ color: '#c4b5fd', fontWeight: 600, marginBottom: 6 }}>🎓 Comment fonctionne l'import d'examen :</div>
              <div style={{ color: '#a78bfa', lineHeight: 1.6 }}>
                ✅ Importez <strong>1 à 100 questions</strong> d'examen officiel (CSV, JSON, Markdown ou TXT)<br/>
                ✅ Le système crée automatiquement une <strong>feuille de réponses</strong> avec autant de cases que de questions<br/>
                ✅ L'examen est créé en mode <strong>brouillon</strong> — vous le publiez depuis la section Simulations<br/>
                ✅ Les <strong>séries de 20 questions</strong> s'appliquent si l'examen est associé à une matière<br/>
                ✅ Exemple typique : 50 questions · 1h30 · feuille de réponses 50 cases
              </div>
            </div>

            {/* Templates Examen */}
            <div style={{ marginTop: 16 }}>
              <div style={{ color: '#94a3b8', fontSize: 12, marginBottom: 8, fontWeight: 600 }}>📥 Télécharger un template :</div>
              <div style={{ display: 'flex', gap: 10, flexWrap: 'wrap' }}>
                <button onClick={downloadExamenCSVTemplate} style={btnTemplate('#D4A017', 'rgba(212,160,23,0.15)', 'rgba(212,160,23,0.4)')}>📊 Template Examen CSV</button>
                <button onClick={downloadExamenMDTemplate} style={btnTemplate('#10b981', 'rgba(16,185,129,0.15)', 'rgba(16,185,129,0.4)')}>📝 Template Examen Markdown</button>
              </div>
            </div>
          </div>

          {/* Format guide Examen */}
          <FormatGuide mode="examen" />
        </>
      )}

      {/* ── UPLOAD FICHIER (commun) ────────────────────────────────────────── */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: `1px solid ${mode === 'examen' ? '#7c3aed40' : '#334155'}`, marginBottom: 20 }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>
          1️⃣ Uploader le fichier {mode === 'qcm' ? 'QCM' : 'd\'examen'}
        </h3>

        <div
          onClick={() => fileInputRef.current?.click()}
          style={{
            border: `2px dashed ${file ? (mode === 'examen' ? '#7c3aed' : '#1A5C38') : '#334155'}`, borderRadius: 10, padding: 36,
            textAlign: 'center', cursor: 'pointer', transition: 'all 0.2s',
            background: file ? (mode === 'examen' ? 'rgba(124,58,237,0.05)' : 'rgba(26,92,56,0.08)') : 'rgba(255,255,255,0.02)',
          }}
          onDragOver={e => e.preventDefault()}
          onDrop={e => {
            e.preventDefault();
            const f = e.dataTransfer.files[0];
            if (f) { const dt = new DataTransfer(); dt.items.add(f); if (fileInputRef.current) { fileInputRef.current.files = dt.files; handleFileSelect({ target: fileInputRef.current } as any); } }
          }}
        >
          {file ? (
            <div>
              <div style={{ fontSize: 40, marginBottom: 10 }}>📂</div>
              <div style={{ color: mode === 'examen' ? '#c4b5fd' : '#4ade80', fontWeight: 700, fontSize: 16 }}>{file.name}</div>
              <div style={{ color: '#64748b', fontSize: 13, marginTop: 6 }}>
                {(file.size / 1024).toFixed(1)} KB — {rawData.length}+ lignes détectées
              </div>
              <button onClick={e => { e.stopPropagation(); resetAll(); }} style={{
                marginTop: 10, padding: '4px 12px', background: 'rgba(239,68,68,0.15)',
                border: '1px solid rgba(239,68,68,0.3)', color: '#ef4444', borderRadius: 6, cursor: 'pointer', fontSize: 12,
              }}>
                🗑️ Changer
              </button>
            </div>
          ) : (
            <div>
              <div style={{ fontSize: 40, marginBottom: 10 }}>📤</div>
              <div style={{ color: '#94a3b8', fontSize: 15, fontWeight: 600 }}>Glisser-déposer ou cliquer</div>
              <div style={{ color: '#475569', fontSize: 13, marginTop: 6 }}>
                CSV, JSON, Markdown (.md) ou Texte (.txt) — Max 20 MB
              </div>
              <div style={{ color: '#334155', fontSize: 12, marginTop: 4 }}>
                {mode === 'qcm' ? 'Supporte 100, 600, 1000+ questions' : 'Exemple : 50 questions d\'examen officiel'}
              </div>
            </div>
          )}
          <input ref={fileInputRef} type="file" accept=".csv,.json,.md,.txt,.markdown" onChange={handleFileSelect} style={{ display: 'none' }} />
        </div>

        {file && (
          <button onClick={handleValidate} disabled={loading} style={{
            marginTop: 16, width: '100%', padding: 15,
            background: loading ? '#334155' : mode === 'examen'
              ? 'linear-gradient(135deg, #7c3aed, #a855f7)'
              : 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
            border: 'none', borderRadius: 10, color: 'white',
            cursor: loading ? 'not-allowed' : 'pointer',
            fontWeight: 700, fontSize: 16, letterSpacing: 0.5,
          }}>
            {loading ? '⏳ Analyse en cours...' : '🔍 Analyser & Valider le fichier →'}
          </button>
        )}
      </div>

      {/* ── Étape 2 : Résultats de validation ──────────────────────────────── */}
      {validation && step === 'validate' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: `1px solid ${mode === 'examen' ? '#7c3aed40' : '#334155'}`, marginBottom: 20 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>2️⃣ Résultats d'analyse</h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="Total lignes" value={validation.total} color="#94a3b8" />
            <StatCard label="✅ Valides" value={validation.total_valid} color="#4ade80" />
            <StatCard label="❌ Invalides" value={validation.total_invalid} color="#ef4444" />
            {mode === 'qcm' ? (
              <StatCard label="Séries de 20" value={Math.ceil((validation.total_valid ?? 0) / 20)} color="#D4A017" />
            ) : (
              <StatCard label="Cases réponses" value={validation.total_valid} color="#c4b5fd" />
            )}
          </div>

          {/* Info séries QCM */}
          {mode === 'qcm' && validation.total_valid > 0 && (
            <div style={{ background: 'rgba(26,92,56,0.1)', border: '1px solid rgba(26,92,56,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 12, fontSize: 13, color: '#4ade80' }}>
              📊 {validation.total_valid} questions → <strong>{Math.ceil(validation.total_valid / 20)} séries de 20 questions</strong> créées automatiquement
              {selectedMatiereInfo && ` dans la matière "${selectedMatiereInfo.nom}"`}
            </div>
          )}

          {/* Info feuille réponses Examen */}
          {mode === 'examen' && validation.total_valid > 0 && (
            <div style={{ background: 'rgba(124,58,237,0.1)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 12, fontSize: 13, color: '#c4b5fd' }}>
              🎓 Examen de <strong>{validation.total_valid} questions</strong> — Feuille de réponses de <strong>{validation.total_valid} cases</strong> générée automatiquement
              {examenTitre && ` · Titre : "${examenTitre}"`}
            </div>
          )}

          {validation.errors?.length > 0 && (
            <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: 14, marginBottom: 16 }}>
              <div style={{ color: '#ef4444', fontWeight: 600, fontSize: 13, marginBottom: 8 }}>⚠️ {validation.errors.length} erreur(s) :</div>
              {validation.errors.slice(0, 5).map((e: any, i: number) => (
                <div key={i} style={{ color: '#fca5a5', fontSize: 12, marginBottom: 4, paddingLeft: 8 }}>
                  • Ligne {e.line}: {Array.isArray(e.errors) ? e.errors.join(', ') : e.error}
                </div>
              ))}
              {validation.errors.length > 5 && (
                <div style={{ color: '#64748b', fontSize: 12, marginTop: 4 }}>... et {validation.errors.length - 5} autres (ignorées)</div>
              )}
            </div>
          )}

          <h4 style={{ color: '#94a3b8', fontSize: 13, fontWeight: 600, marginBottom: 10 }}>👁️ Aperçu (premières questions)</h4>
          <div style={{ background: '#0f172a', borderRadius: 8, overflow: 'hidden', marginBottom: 16 }}>
            {validation.preview?.map((p: any, i: number) => (
              <div key={i} style={{ padding: '10px 14px', borderBottom: i < (validation.preview.length - 1) ? '1px solid #1e293b' : 'none', fontSize: 12 }}>
                <div style={{ color: '#e2e8f0', fontWeight: 600 }}>Q{p.line}. {p.question}</div>
                <div style={{ color: '#64748b', marginTop: 3 }}>
                  A: {p.option_a} | B: {p.option_b} → Rép: <span style={{ color: '#4ade80', fontWeight: 700 }}>{p.bonne_reponse}</span>
                  &nbsp;— <span style={{ color: p.status?.includes('✅') ? '#4ade80' : '#fbbf24' }}>{p.status}</span>
                </div>
              </div>
            ))}
          </div>

          {validation.ready_to_import && (
            <button
              onClick={mode === 'qcm' ? handleImportQCM : handleImportExamen}
              disabled={loading}
              style={{
                width: '100%', padding: 16, border: 'none', borderRadius: 10, color: 'white',
                cursor: loading ? 'not-allowed' : 'pointer', fontWeight: 800, fontSize: 17, letterSpacing: 0.5,
                background: mode === 'examen'
                  ? 'linear-gradient(135deg, #7c3aed, #a855f7)'
                  : 'linear-gradient(135deg, #1A5C38, #2d9966)',
              }}
            >
              {mode === 'examen'
                ? `🎓 CRÉER L'EXAMEN — ${validation.total_valid} questions · Feuille de réponses ${validation.total_valid} cases`
                : `🚀 IMPORTER — ${validation.total_valid} questions · ${Math.ceil(validation.total_valid / 20)} séries`
              }
            </button>
          )}
        </div>
      )}

      {/* ── Étape 3 : Import en cours ────────────────────────────────────── */}
      {step === 'import' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 48, border: '1px solid #334155', textAlign: 'center' }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>{mode === 'examen' ? '🎓' : '⏳'}</div>
          <div style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 700 }}>
            {mode === 'examen' ? 'Création de l\'examen en cours...' : 'Import en cours...'}
          </div>
          <div style={{ color: '#64748b', fontSize: 13, marginTop: 8 }}>
            {mode === 'examen' ? 'Génération de la feuille de réponses · Insertion des questions' : 'Traitement par lots de 50 · Création automatique des séries'}
          </div>
          <div style={{ height: 6, background: '#334155', borderRadius: 3, marginTop: 24, overflow: 'hidden', maxWidth: 400, margin: '24px auto 0' }}>
            <div style={{ height: '100%', background: mode === 'examen' ? 'linear-gradient(90deg, #7c3aed, #a855f7)' : 'linear-gradient(90deg, #1A5C38, #2d9966)', width: '60%', borderRadius: 3, animation: 'loading 1.5s ease-in-out infinite' }} />
          </div>
          <style>{`@keyframes loading { 0%{width:5%} 50%{width:85%} 100%{width:5%} }`}</style>
        </div>
      )}

      {/* ── Étape 4 : Résultats ──────────────────────────────────────────── */}
      {step === 'done' && importResult && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: `1px solid ${importResult._mode === 'examen' ? 'rgba(196,181,253,0.3)' : 'rgba(74,222,128,0.3)'}`, marginBottom: 20 }}>
          <h3 style={{ color: importResult._mode === 'examen' ? '#c4b5fd' : '#4ade80', fontSize: 20, fontWeight: 800, marginBottom: 20 }}>
            {importResult._mode === 'examen' ? '🎓 Examen créé avec succès !' : '✅ Import terminé avec succès !'}
          </h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="✅ Importées" value={importResult.imported} color="#4ade80" />
            <StatCard label="❌ Échecs" value={importResult.failed} color="#ef4444" />
            <StatCard label="Total traité" value={importResult.total} color="#94a3b8" />
            <StatCard label="Durée" value={`${importResult.duration_seconds}s`} color="#D4A017" />
          </div>

          {importResult._mode === 'examen' ? (
            <div style={{ background: 'rgba(124,58,237,0.1)', border: '1px solid rgba(124,58,237,0.3)', borderRadius: 10, padding: 16, marginBottom: 20 }}>
              <div style={{ color: '#c4b5fd', fontSize: 14, fontWeight: 700, marginBottom: 8 }}>🎓 Examen créé !</div>
              <div style={{ color: '#a78bfa', fontSize: 13, lineHeight: 1.7 }}>
                ✅ Titre : <strong>{importResult._titre}</strong><br/>
                ✅ Feuille de réponses de <strong>{importResult.imported} cases</strong> générée automatiquement<br/>
                ✅ Simulation ID : <code style={{ background: '#0f172a', padding: '2px 6px', borderRadius: 4, fontSize: 11 }}>{importResult.simulation_id}</code><br/>
                ✅ État : <strong>Brouillon</strong> — Publiez-le depuis la section Simulations
              </div>
            </div>
          ) : (
            <div style={{ background: 'rgba(74,222,128,0.08)', border: '1px solid rgba(74,222,128,0.2)', borderRadius: 10, padding: 16, marginBottom: 20 }}>
              <div style={{ color: '#4ade80', fontSize: 14, fontWeight: 700, marginBottom: 8 }}>🎉 {importResult.imported} questions disponibles !</div>
              <div style={{ color: '#86efac', fontSize: 13, lineHeight: 1.7 }}>
                ✅ Classées automatiquement dans la bonne matière<br/>
                ✅ {Math.ceil(importResult.imported / 20)} série(s) de 20 questions créées<br/>
                ✅ Disponibles immédiatement pour tous les utilisateurs
              </div>
            </div>
          )}

          <div style={{ display: 'flex', gap: 12 }}>
            <button onClick={resetAll} style={{ padding: '10px 20px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer', fontWeight: 600 }}>
              📤 Nouvel import
            </button>
            <button onClick={() => onNavigate(importResult._mode === 'examen' ? 'simulations' : 'questions')} style={{
              flex: 1, padding: '10px 20px', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 700,
              background: importResult._mode === 'examen' ? 'linear-gradient(135deg, #7c3aed, #a855f7)' : 'linear-gradient(135deg, #1A5C38, #2d9966)',
            }}>
              {importResult._mode === 'examen' ? '🎓 Gérer les Simulations →' : `Voir les ${importResult.imported} questions →`}
            </button>
          </div>
        </div>
      )}

      {/* ── Historique ────────────────────────────────────────────────────── */}
      {showHistory && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600 }}>📜 Historique des imports</h3>
            <button onClick={() => setShowHistory(false)} style={{ background: 'none', border: 'none', color: '#64748b', cursor: 'pointer', fontSize: 18 }}>✕</button>
          </div>
          {history.length === 0 ? (
            <p style={{ color: '#64748b', fontSize: 13 }}>Aucun import enregistré</p>
          ) : history.map((imp: any) => (
            <div key={imp.id} style={{ padding: '12px 0', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ color: '#e2e8f0', fontSize: 13, fontWeight: 600 }}>{imp.filename ?? 'Import #' + imp.id}</div>
                <div style={{ color: '#64748b', fontSize: 12, marginTop: 2 }}>
                  {new Date(imp.created_at).toLocaleString('fr-FR')} — {imp.imported_count ?? 0} questions
                  {imp.import_duration_seconds && ` en ${imp.import_duration_seconds}s`}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <StatusBadge status={imp.status} />
                {imp.status === 'success' && (
                  <button onClick={() => handleCancelImport(imp.id)} style={{
                    background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                    color: '#ef4444', padding: '4px 10px', borderRadius: 6, cursor: 'pointer', fontSize: 12,
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

// ── Composant guide format ─────────────────────────────────────────────────
function FormatGuide({ mode }: { mode: 'qcm' | 'examen' }) {
  return (
    <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: `1px solid ${mode === 'examen' ? '#7c3aed40' : '#334155'}`, marginBottom: 20 }}>
      <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 12 }}>
        📋 Format du fichier {mode === 'examen' ? 'd\'examen' : 'QCM'}
      </h3>
      <div style={{ background: 'rgba(212,160,23,0.1)', border: '1px solid rgba(212,160,23,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 14, fontSize: 13, color: '#D4A017' }}>
        ⚡ <strong>Important :</strong> Bonne réponse = A, B, C, D ou E (majuscule). Difficulté = FACILE, MOYEN ou DIFFICILE.
        {mode === 'examen' && ' Pour un examen de 50 questions, préparez 50 lignes.'}
      </div>
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fit, minmax(280px, 1fr))', gap: 16 }}>
        <div>
          <div style={{ color: '#D4A017', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📊 CSV (séparateur : ;)</div>
          <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 10, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{mode === 'qcm'
? `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id
Capitale du BF?;Bobo;Ouaga;Koudougou;Banfora;B;Ouaga est la capitale;FACILE;[UUID]
Fondateurs AES?;ONU;BF+Mali+Niger;UA;CEDEAO;B;Signée en 2023;MOYEN;[UUID]`
: `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte
Capitale du BF?;Bobo;Ouaga;Koudougou;Banfora;B;Ouaga est la capitale;FACILE
Qui a fondé l'AES?;ONU;BF+Mali+Niger;UA;CEDEAO;B;Signée en 2023;MOYEN`}
          </pre>
        </div>
        <div>
          <div style={{ color: '#10b981', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📝 Markdown / TXT</div>
          <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 10, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{`## Quelle est la capitale du BF ?
A) Bobo-Dioulasso
B) Ouagadougou *
C) Koudougou
D) Banfora
Explication: Ouaga est la capitale

## Qui a fondé l'AES ?
A) ONU
B) Burkina, Mali, Niger ✓
C) UA
Bonne réponse: B`}
          </pre>
        </div>
        <div>
          <div style={{ color: '#3b82f6', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📄 JSON (tableau)</div>
          <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 10, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{`[
  {
    "enonce": "Capitale du BF ?",
    "option_a": "Bobo-Dioulasso",
    "option_b": "Ouagadougou",
    "bonne_reponse": "B",
    "explication": "Ouaga est...",
    "difficulte": "FACILE"${mode === 'qcm' ? `,\n    "matiere_id": "[UUID]"` : ''}
  }
]`}
          </pre>
        </div>
      </div>
    </div>
  );
}

// ── Composants utilitaires ────────────────────────────────────────────────
function StatCard({ label, value, color }: { label: string; value: any; color: string }) {
  return (
    <div style={{ background: '#0f172a', borderRadius: 10, padding: 14, textAlign: 'center' }}>
      <div style={{ color, fontSize: 24, fontWeight: 900 }}>{typeof value === 'number' ? value.toLocaleString() : value}</div>
      <div style={{ color: '#64748b', fontSize: 12, marginTop: 4 }}>{label}</div>
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
  return <span style={{ background: s.bg, color: s.color, padding: '3px 10px', borderRadius: 10, fontSize: 12, fontWeight: 600 }}>{s.label}</span>;
}

function btnTemplate(color: string, bg: string, border: string): React.CSSProperties {
  return { padding: '8px 16px', background: bg, border: `1px solid ${border}`, color, borderRadius: 8, cursor: 'pointer', fontSize: 13, fontWeight: 600 };
}

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 6, fontWeight: 600 };
const sel: React.CSSProperties = {
  width: '100%', padding: '10px 12px', background: '#0f172a',
  border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14,
};
