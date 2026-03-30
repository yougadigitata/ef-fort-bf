import { useState, useRef, useEffect } from 'react';
import { validateBulk, bulkImport, getMatieres, getImportHistory, cancelImport } from '../api';
import type { Page } from '../App';

export default function BulkImportPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
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

  // ── Télécharger template CSV ──────────────────────────────────────────
  function downloadCSVTemplate() {
    const selectedM = matieres.find(m => m.id === selectedMatiere || m.matiere_id === selectedMatiere);
    const matiereId = selectedM?.matiere_id ?? selectedM?.id ?? 'UUID_MATIERE_ICI';
    
    const csvContent = `enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id
Quelle est la capitale du Burkina Faso ?;Bobo-Dioulasso;Ouagadougou;Koudougou;Banfora;B;Ouagadougou est la capitale politique et économique du Burkina Faso depuis l'indépendance.;FACILE;${matiereId}
Qui a fondé l'AES ?;Les Nations Unies;Le Burkina, Mali et Niger;La France et le Mali;L'UEMOA;B;L'Alliance des États du Sahel a été fondée par le Burkina Faso, le Mali et le Niger en 2023.;MOYEN;${matiereId}
Quand le Burkina Faso a-t-il obtenu son indépendance ?;3 janvier 1966;5 août 1960;11 décembre 1958;1er janvier 1970;B;La Haute-Volta (actuel Burkina Faso) a accédé à l'indépendance le 5 août 1960.;FACILE;${matiereId}`;

    const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'template_qcm.csv';
    link.click();
    URL.revokeObjectURL(url);
    showToast('✅ Template CSV téléchargé !');
  }

  // ── Télécharger template JSON ─────────────────────────────────────────
  function downloadJSONTemplate() {
    const selectedM = matieres.find(m => m.id === selectedMatiere || m.matiere_id === selectedMatiere);
    const matiereId = selectedM?.matiere_id ?? selectedM?.id ?? 'UUID_MATIERE_ICI';
    
    const jsonContent = [
      {
        enonce: "Quelle est la capitale du Burkina Faso ?",
        option_a: "Bobo-Dioulasso",
        option_b: "Ouagadougou",
        option_c: "Koudougou",
        option_d: "Banfora",
        bonne_reponse: "B",
        explication: "Ouagadougou est la capitale politique et économique du Burkina Faso depuis l'indépendance.",
        difficulte: "FACILE",
        matiere_id: matiereId
      },
      {
        enonce: "Qui a fondé l'AES ?",
        option_a: "Les Nations Unies",
        option_b: "Le Burkina, Mali et Niger",
        option_c: "La France et le Mali",
        option_d: "L'UEMOA",
        bonne_reponse: "B",
        explication: "L'Alliance des États du Sahel a été fondée par le Burkina Faso, le Mali et le Niger en 2023.",
        difficulte: "MOYEN",
        matiere_id: matiereId
      }
    ];

    const blob = new Blob([JSON.stringify(jsonContent, null, 2)], { type: 'application/json' });
    const url = URL.createObjectURL(blob);
    const link = document.createElement('a');
    link.href = url;
    link.download = 'template_qcm.json';
    link.click();
    URL.revokeObjectURL(url);
    showToast('✅ Template JSON téléchargé !');
  }

  // ── Copier ID matière ─────────────────────────────────────────────────
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
    setFile(f);
    setValidation(null);
    setStep('upload');
    const text = await f.text();
    try {
      if (f.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        setRawData(Array.isArray(parsed) ? parsed : parsed.questions ?? []);
      } else {
        const lines = text.split('\n').filter(l => l.trim());
        setRawData(lines.slice(1, 6).map((l, i) => ({ preview: l.substring(0, 80), line: i + 2 })));
      }
    } catch (_) {}
  }

  async function handleValidate() {
    if (!file) return;
    setLoading(true);
    try {
      const text = await file.text();
      let questions: any[] = [];
      if (file.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
      } else {
        const lines = text.split('\n').filter(l => l.trim());
        if (lines.length < 2) { showToast('❌ Fichier CSV vide ou invalide'); return; }
        const headers = lines[0].split(';').map(h => h.trim().toLowerCase());
        questions = lines.slice(1).map(line => {
          const vals = line.split(';').map(v => v.trim().replace(/^["']|["']$/g, ''));
          const obj: any = {};
          headers.forEach((h, i) => { obj[h] = vals[i] ?? ''; });
          return obj;
        });
      }
      const data = await validateBulk(questions, selectedMatiere || undefined);
      setValidation({ ...data, questions });
      setStep('validate');
    } catch (err: any) {
      showToast('❌ Erreur validation: ' + err.message);
    } finally {
      setLoading(false);
    }
  }

  async function handleImport() {
    if (!validation?.questions) return;
    if (!confirm(`⚠️ Importer ${validation.total_valid} questions ?\n\nElles seront immédiatement visibles pour tous les utilisateurs.\nLes séries seront créées automatiquement (20 questions/série).`)) return;
    setLoading(true);
    setStep('import');
    try {
      const data = await bulkImport(validation.questions, selectedMatiere || undefined);
      setImportResult(data);
      setStep('done');
      showToast(`✅ ${data.imported} questions importées en ${data.duration_seconds}s !`);
    } catch (err: any) {
      showToast('❌ Erreur import: ' + err.message);
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
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>📤 Import en masse de QCM</h2>
          <p style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
            Importez 100, 400 ou 1000+ questions CSV/JSON → classement automatique par matière & séries
          </p>
        </div>
        <button onClick={loadHistory} style={{ background: '#334155', border: 'none', color: '#94a3b8', padding: '8px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 13 }}>
          📜 Historique
        </button>
      </div>

      {/* Étape 0 : Sélection matière + Téléchargement templates */}
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
            🗂️ Voir IDs matières
          </button>
        </div>

        {selectedMatiereInfo && (
          <div style={{ marginTop: 10, padding: '8px 12px', background: 'rgba(26,92,56,0.15)', borderRadius: 8, border: '1px solid rgba(26,92,56,0.3)' }}>
            <span style={{ color: '#4ade80', fontSize: 13 }}>
              ✅ Matière sélectionnée : <strong>{selectedMatiereInfo.nom}</strong>
              &nbsp;— Toutes les questions importées iront dans cette matière.
            </span>
          </div>
        )}

        {/* IDs matières */}
        {showMatieres && (
          <div style={{ marginTop: 16 }}>
            <div style={{ color: '#94a3b8', fontSize: 12, marginBottom: 8 }}>
              Cliquez sur une ligne pour copier l'ID UUID à utiliser dans votre fichier :
            </div>
            <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 6 }}>
              {matieres.map(m => (
                <div
                  key={m.id ?? m.matiere_id}
                  onClick={() => copyMatiereId(m.matiere_id ?? m.id, m.nom)}
                  style={{
                    padding: '6px 10px', background: '#0f172a', borderRadius: 6,
                    cursor: 'pointer', display: 'flex', justifyContent: 'space-between',
                    border: '1px solid #334155', fontSize: 12,
                  }}
                  title="Cliquer pour copier l'ID"
                >
                  <span style={{ color: '#e2e8f0', fontWeight: 600 }}>{m.nom}</span>
                  <span style={{ color: '#475569', fontFamily: 'monospace', fontSize: 10 }}>
                    {(m.matiere_id ?? m.id ?? '').substring(0, 12)}... 📋
                  </span>
                </div>
              ))}
            </div>
          </div>
        )}

        {/* Téléchargement templates */}
        <div style={{ marginTop: 16 }}>
          <div style={{ color: '#94a3b8', fontSize: 12, marginBottom: 8, fontWeight: 600 }}>
            📥 Télécharger un template :
            {selectedMatiereInfo && <span style={{ color: '#4ade80' }}> (pré-rempli avec l'ID de {selectedMatiereInfo.nom})</span>}
          </div>
          <div style={{ display: 'flex', gap: 10 }}>
            <button onClick={downloadCSVTemplate} style={{
              padding: '8px 16px', background: 'rgba(212,160,23,0.15)',
              border: '1px solid rgba(212,160,23,0.4)', color: '#D4A017',
              borderRadius: 8, cursor: 'pointer', fontSize: 13, fontWeight: 600,
            }}>
              📊 Template CSV
            </button>
            <button onClick={downloadJSONTemplate} style={{
              padding: '8px 16px', background: 'rgba(59,130,246,0.15)',
              border: '1px solid rgba(59,130,246,0.4)', color: '#3b82f6',
              borderRadius: 8, cursor: 'pointer', fontSize: 13, fontWeight: 600,
            }}>
              📄 Template JSON
            </button>
          </div>
        </div>
      </div>

      {/* Format guide */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 12 }}>📋 Format obligatoire du fichier</h3>
        <div style={{ background: 'rgba(212,160,23,0.1)', border: '1px solid rgba(212,160,23,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 14, fontSize: 13, color: '#D4A017' }}>
          ⚡ <strong>Important :</strong> La bonne réponse doit être A, B, C, D ou E (lettre majuscule).
          La difficulté : FACILE, MOYEN ou DIFFICILE. Le matiere_id est l'UUID de la matière.
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ color: '#D4A017', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📊 CSV (séparateur : ;)</div>
            <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 10, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{`enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id
Capitale du BF?;Bobo;Ouaga;Koudougou;Banfora;B;Ouaga est la capitale;FACILE;[UUID]
Fondateurs AES?;ONU;BF+Mali+Niger;UA;CEDEAO;B;Signée en 2023;MOYEN;[UUID]`}
            </pre>
            <div style={{ color: '#64748b', fontSize: 11, marginTop: 4 }}>
              ✅ Colonnes requises : enonce, option_a, option_b, bonne_reponse<br/>
              ✅ Colonnes optionnelles : option_c, option_d, option_e, explication, difficulte, matiere_id, pieges, sources
            </div>
          </div>
          <div>
            <div style={{ color: '#3b82f6', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📄 JSON (tableau d'objets)</div>
            <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 10, color: '#94a3b8', overflow: 'auto', whiteSpace: 'pre-wrap' }}>
{`[
  {
    "enonce": "Capitale du BF ?",
    "option_a": "Bobo-Dioulasso",
    "option_b": "Ouagadougou",
    "option_c": "Koudougou",
    "option_d": "Banfora",
    "bonne_reponse": "B",
    "explication": "Ouaga est la capitale",
    "difficulte": "FACILE",
    "matiere_id": "[UUID]"
  }
]`}
            </pre>
          </div>
        </div>
      </div>

      {/* Étape 1 : Upload fichier */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 20 }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>1️⃣ Uploader le fichier QCM</h3>

        <div
          onClick={() => fileInputRef.current?.click()}
          style={{
            border: '2px dashed #334155', borderRadius: 10, padding: 36,
            textAlign: 'center', cursor: 'pointer', transition: 'all 0.2s',
            background: file ? 'rgba(26,92,56,0.08)' : 'rgba(255,255,255,0.02)',
            borderColor: file ? '#1A5C38' : '#334155',
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
              <div style={{ color: '#4ade80', fontWeight: 700, fontSize: 16 }}>{file.name}</div>
              <div style={{ color: '#64748b', fontSize: 13, marginTop: 6 }}>
                {(file.size / 1024).toFixed(1)} KB — {rawData.length}+ lignes détectées
              </div>
              <button
                onClick={e => { e.stopPropagation(); setFile(null); setRawData([]); setValidation(null); setStep('upload'); if (fileInputRef.current) fileInputRef.current.value = ''; }}
                style={{ marginTop: 10, padding: '4px 12px', background: 'rgba(239,68,68,0.15)', border: '1px solid rgba(239,68,68,0.3)', color: '#ef4444', borderRadius: 6, cursor: 'pointer', fontSize: 12 }}
              >
                🗑️ Changer
              </button>
            </div>
          ) : (
            <div>
              <div style={{ fontSize: 40, marginBottom: 10 }}>📤</div>
              <div style={{ color: '#94a3b8', fontSize: 15, fontWeight: 600 }}>Glisser-déposer ou cliquer</div>
              <div style={{ color: '#475569', fontSize: 13, marginTop: 6 }}>CSV (.csv) ou JSON (.json) — Max 20 MB</div>
              <div style={{ color: '#334155', fontSize: 12, marginTop: 4 }}>Supporte 100, 400, 1000+ questions</div>
            </div>
          )}
          <input ref={fileInputRef} type="file" accept=".csv,.json" onChange={handleFileSelect} style={{ display: 'none' }} />
        </div>

        {file && (
          <button onClick={handleValidate} disabled={loading} style={{
            marginTop: 16, width: '100%', padding: 15,
            background: loading ? '#334155' : 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
            border: 'none', borderRadius: 10, color: 'white',
            cursor: loading ? 'not-allowed' : 'pointer',
            fontWeight: 700, fontSize: 16, letterSpacing: 0.5,
          }}>
            {loading ? '⏳ Analyse en cours...' : '🔍 Analyser & Valider le fichier →'}
          </button>
        )}
      </div>

      {/* Étape 2 : Résultats de validation */}
      {validation && step === 'validate' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 20 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>2️⃣ Résultats d'analyse</h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="Total lignes" value={validation.total} color="#94a3b8" />
            <StatCard label="✅ Valides" value={validation.total_valid} color="#4ade80" />
            <StatCard label="❌ Invalides" value={validation.total_invalid} color="#ef4444" />
            <StatCard label="Prêt ?" value={validation.ready_to_import ? '✅ OUI' : '❌ NON'} color={validation.ready_to_import ? '#4ade80' : '#ef4444'} />
          </div>

          {/* Matière sélectionnée */}
          {selectedMatiereInfo && (
            <div style={{ background: 'rgba(26,92,56,0.15)', border: '1px solid rgba(26,92,56,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 12, fontSize: 13, color: '#4ade80' }}>
              📚 Toutes les questions seront importées dans : <strong>{selectedMatiereInfo.nom}</strong>
            </div>
          )}

          {/* Erreurs */}
          {validation.errors?.length > 0 && (
            <div style={{ background: 'rgba(239,68,68,0.08)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: 14, marginBottom: 16 }}>
              <div style={{ color: '#ef4444', fontWeight: 600, fontSize: 13, marginBottom: 8 }}>
                ⚠️ {validation.errors.length} erreur(s) détectée(s) :
              </div>
              {validation.errors.slice(0, 5).map((e: any, i: number) => (
                <div key={i} style={{ color: '#fca5a5', fontSize: 12, marginBottom: 4, paddingLeft: 8 }}>
                  • Ligne {e.line}: {Array.isArray(e.errors) ? e.errors.join(', ') : e.error}
                </div>
              ))}
              {validation.errors.length > 5 && (
                <div style={{ color: '#64748b', fontSize: 12, marginTop: 4 }}>... et {validation.errors.length - 5} autres erreurs (les lignes invalides sont ignorées)</div>
              )}
            </div>
          )}

          {/* Prévisualisation */}
          <h4 style={{ color: '#94a3b8', fontSize: 13, fontWeight: 600, marginBottom: 10 }}>👁️ Aperçu (5 premières questions valides)</h4>
          <div style={{ background: '#0f172a', borderRadius: 8, overflow: 'hidden', marginBottom: 16 }}>
            {validation.preview?.map((p: any, i: number) => (
              <div key={i} style={{ padding: '10px 14px', borderBottom: i < (validation.preview.length - 1) ? '1px solid #1e293b' : 'none', fontSize: 12 }}>
                <div style={{ color: '#e2e8f0', fontWeight: 600 }}>
                  Q{p.line}. {p.question}
                </div>
                <div style={{ color: '#64748b', marginTop: 3 }}>
                  A: {p.option_a} | B: {p.option_b}&nbsp;
                  → Rép: <span style={{ color: '#4ade80', fontWeight: 700 }}>{p.bonne_reponse}</span>
                  &nbsp;— <span style={{ color: p.status.includes('✅') ? '#4ade80' : '#fbbf24' }}>{p.status}</span>
                </div>
              </div>
            ))}
          </div>

          {validation.ready_to_import && (
            <button onClick={handleImport} disabled={loading} style={{
              width: '100%', padding: 16,
              background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
              border: 'none', borderRadius: 10, color: 'white',
              cursor: loading ? 'not-allowed' : 'pointer',
              fontWeight: 800, fontSize: 17, letterSpacing: 0.5,
            }}>
              🚀 IMPORTER MAINTENANT — {validation.total_valid} questions
            </button>
          )}
        </div>
      )}

      {/* Étape 3 : Import en cours */}
      {step === 'import' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 48, border: '1px solid #334155', textAlign: 'center' }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>⏳</div>
          <div style={{ color: '#f1f5f9', fontSize: 18, fontWeight: 700 }}>Import en cours...</div>
          <div style={{ color: '#64748b', fontSize: 13, marginTop: 8 }}>
            Traitement par lots de 50 · Création automatique des séries
          </div>
          <div style={{ height: 6, background: '#334155', borderRadius: 3, marginTop: 24, overflow: 'hidden', maxWidth: 400, margin: '24px auto 0' }}>
            <div style={{ height: '100%', background: 'linear-gradient(90deg, #1A5C38, #2d9966)', width: '60%', borderRadius: 3, animation: 'loading 1.5s ease-in-out infinite' }} />
          </div>
          <style>{`@keyframes loading { 0%{width:5%} 50%{width:85%} 100%{width:5%} }`}</style>
        </div>
      )}

      {/* Étape 4 : Résultats */}
      {step === 'done' && importResult && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid rgba(74,222,128,0.3)', marginBottom: 20 }}>
          <h3 style={{ color: '#4ade80', fontSize: 20, fontWeight: 800, marginBottom: 20 }}>✅ Import terminé avec succès !</h3>
          
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="✅ Importées" value={importResult.imported} color="#4ade80" />
            <StatCard label="❌ Échecs" value={importResult.failed} color="#ef4444" />
            <StatCard label="Total traité" value={importResult.total} color="#94a3b8" />
            <StatCard label="Durée" value={`${importResult.duration_seconds}s`} color="#D4A017" />
          </div>

          <div style={{ background: 'rgba(74,222,128,0.08)', border: '1px solid rgba(74,222,128,0.2)', borderRadius: 10, padding: 16, marginBottom: 20 }}>
            <div style={{ color: '#4ade80', fontSize: 14, fontWeight: 700, marginBottom: 8 }}>
              🎉 {importResult.imported} questions sont maintenant disponibles !
            </div>
            <div style={{ color: '#86efac', fontSize: 13 }}>
              ✅ Classées automatiquement dans la bonne matière<br/>
              ✅ Séries créées automatiquement (20 questions/série)<br/>
              ✅ Disponibles immédiatement pour tous les utilisateurs de l'app
            </div>
          </div>

          <div style={{ display: 'flex', gap: 12 }}>
            <button onClick={() => { setStep('upload'); setFile(null); setValidation(null); setImportResult(null); if (fileInputRef.current) fileInputRef.current.value = ''; }} style={{
              padding: '10px 20px', background: '#334155', border: 'none',
              borderRadius: 8, color: '#94a3b8', cursor: 'pointer', fontWeight: 600,
            }}>
              📤 Nouvel import
            </button>
            <button onClick={() => onNavigate('questions')} style={{
              flex: 1, padding: '10px 20px', background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
              border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 700,
            }}>
              Voir les {importResult.imported} questions importées →
            </button>
          </div>
        </div>
      )}

      {/* Historique */}
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
                  {new Date(imp.created_at).toLocaleString('fr-FR')} — {imp.imported_count ?? 0} questions importées
                  {imp.import_duration_seconds && ` en ${imp.import_duration_seconds}s`}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <StatusBadge status={imp.status} />
                {imp.status === 'success' && (
                  <button onClick={() => handleCancelImport(imp.id)} title="Annuler et supprimer" style={{
                    background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                    color: '#ef4444', padding: '4px 10px', borderRadius: 6, cursor: 'pointer', fontSize: 12,
                  }}>
                    🗑️ Annuler
                  </button>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}

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

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 6, fontWeight: 600 };
const sel: React.CSSProperties = {
  width: '100%', padding: '10px 12px', background: '#0f172a',
  border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14,
};
