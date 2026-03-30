import { useState, useRef } from 'react';
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
  const [toast, setToast] = useState('');
  const fileInputRef = useRef<HTMLInputElement>(null);

  useState(() => { loadMatieres(); });

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

  function showToast(msg: string) { setToast(msg); setTimeout(() => setToast(''), 4000); }

  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (!f) return;
    setFile(f);
    setValidation(null);
    setStep('upload');

    // Parser le fichier
    const text = await f.text();
    try {
      if (f.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        setRawData(Array.isArray(parsed) ? parsed : parsed.questions ?? []);
      } else {
        // CSV simple parsing preview
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
        // Parsing CSV
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
    if (!confirm(`Importer ${validation.total_valid} questions ? Cette action est immédiate et visible par tous les utilisateurs.`)) return;

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

  return (
    <div style={{ maxWidth: 900 }}>
      {toast && <div style={{ position: 'fixed', top: 70, right: 20, padding: '12px 18px', background: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, zIndex: 1000 }}>{toast}</div>}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>📤 Import en masse</h2>
          <p style={{ color: '#64748b', fontSize: 13 }}>Importer 100, 400 ou 1000+ questions en CSV ou JSON</p>
        </div>
        <button onClick={loadHistory} style={{ background: '#334155', border: 'none', color: '#94a3b8', padding: '8px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 13 }}>
          📜 Historique imports
        </button>
      </div>

      {/* Format guide */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginBottom: 20 }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 12 }}>📋 Format accepté</h3>
        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
          <div>
            <div style={{ color: '#D4A017', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📊 CSV (séparateur : ;)</div>
            <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 11, color: '#94a3b8', overflow: 'auto' }}>
{`enonce;option_a;option_b;option_c;option_d;bonne_reponse;explication;difficulte;matiere_id
Qui dirige le DOGE ?;Trump;Musk & Ramaswamy;Faye;Sonko;B;DOGE créé en 2025...;MOYEN;[UUID_MATIERE]`}
            </pre>
          </div>
          <div>
            <div style={{ color: '#3b82f6', fontSize: 13, fontWeight: 600, marginBottom: 6 }}>📄 JSON (tableau)</div>
            <pre style={{ background: '#0f172a', borderRadius: 8, padding: 10, fontSize: 11, color: '#94a3b8', overflow: 'auto' }}>
{`[{
  "enonce": "Qui dirige le DOGE ?",
  "option_a": "Trump",
  "option_b": "Musk & Ramaswamy",
  "bonne_reponse": "B",
  "explication": "DOGE créé en 2025...",
  "difficulte": "MOYEN",
  "matiere_id": "[UUID]"
}]`}
            </pre>
          </div>
        </div>
      </div>

      {/* Upload Zone */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 20 }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>1️⃣ Choisir le fichier</h3>

        <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
          <div>
            <label style={lbl}>Matière par défaut</label>
            <select value={selectedMatiere} onChange={e => setSelectedMatiere(e.target.value)} style={sel}>
              <option value="">Utiliser matiere_id dans le fichier</option>
              {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
            </select>
          </div>
        </div>

        <div
          onClick={() => fileInputRef.current?.click()}
          style={{
            border: '2px dashed #334155', borderRadius: 10, padding: 32,
            textAlign: 'center', cursor: 'pointer', transition: 'all 0.2s',
            background: file ? 'rgba(26,92,56,0.1)' : 'transparent',
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
              <div style={{ fontSize: 32, marginBottom: 8 }}>📂</div>
              <div style={{ color: '#4ade80', fontWeight: 600, fontSize: 15 }}>{file.name}</div>
              <div style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>{(file.size / 1024).toFixed(1)} KB — {rawData.length}+ lignes détectées</div>
            </div>
          ) : (
            <div>
              <div style={{ fontSize: 32, marginBottom: 8 }}>📤</div>
              <div style={{ color: '#94a3b8', fontSize: 15 }}>Glisser-déposer ou cliquer pour sélectionner</div>
              <div style={{ color: '#475569', fontSize: 13, marginTop: 4 }}>CSV (.csv) ou JSON (.json) — Max 20 MB</div>
            </div>
          )}
          <input ref={fileInputRef} type="file" accept=".csv,.json" onChange={handleFileSelect} style={{ display: 'none' }} />
        </div>

        {file && (
          <button onClick={handleValidate} disabled={loading} style={{
            marginTop: 16, width: '100%', padding: 14,
            background: loading ? '#334155' : 'linear-gradient(135deg, #3b82f6, #1d4ed8)',
            border: 'none', borderRadius: 8, color: 'white', cursor: loading ? 'not-allowed' : 'pointer',
            fontWeight: 600, fontSize: 15,
          }}>
            {loading ? '⏳ Validation en cours...' : '🔍 Valider le fichier'}
          </button>
        )}
      </div>

      {/* Résultats de validation */}
      {validation && step === 'validate' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 20 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>2️⃣ Résultats de validation</h3>

          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="Total lignes" value={validation.total} color="#94a3b8" />
            <StatCard label="✅ Valides" value={validation.total_valid} color="#4ade80" />
            <StatCard label="❌ Invalides" value={validation.total_invalid} color="#ef4444" />
            <StatCard label="Prêt ?" value={validation.ready_to_import ? 'OUI' : 'NON'} color={validation.ready_to_import ? '#4ade80' : '#ef4444'} />
          </div>

          {/* Erreurs */}
          {validation.errors?.length > 0 && (
            <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: 12, marginBottom: 16 }}>
              <div style={{ color: '#ef4444', fontWeight: 600, fontSize: 13, marginBottom: 8 }}>⚠️ Erreurs détectées :</div>
              {validation.errors.slice(0, 5).map((e: any, i: number) => (
                <div key={i} style={{ color: '#fca5a5', fontSize: 12, marginBottom: 4 }}>
                  Ligne {e.line}: {Array.isArray(e.errors) ? e.errors.join(', ') : e.error}
                </div>
              ))}
              {validation.errors.length > 5 && <div style={{ color: '#64748b', fontSize: 12 }}>... et {validation.errors.length - 5} autres erreurs</div>}
            </div>
          )}

          {/* Prévisualisation */}
          <h4 style={{ color: '#94a3b8', fontSize: 13, fontWeight: 600, marginBottom: 10 }}>👁️ Prévisualisation (5 premières)</h4>
          {validation.preview?.map((p: any, i: number) => (
            <div key={i} style={{ padding: '8px 12px', background: '#0f172a', borderRadius: 6, marginBottom: 6, fontSize: 12 }}>
              <div style={{ color: '#e2e8f0' }}>Q{p.line}. {p.question}</div>
              <div style={{ color: '#64748b', marginTop: 2 }}>
                A: {p.option_a} | B: {p.option_b} | Rép: <span style={{ color: '#4ade80', fontWeight: 600 }}>{p.bonne_reponse}</span>
                &nbsp;— <span style={{ color: p.status.includes('✅') ? '#4ade80' : '#fbbf24' }}>{p.status}</span>
              </div>
            </div>
          ))}

          {validation.ready_to_import && (
            <button onClick={handleImport} disabled={loading} style={{
              marginTop: 16, width: '100%', padding: 14,
              background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
              border: 'none', borderRadius: 8, color: 'white', cursor: loading ? 'not-allowed' : 'pointer',
              fontWeight: 700, fontSize: 16,
            }}>
              🚀 IMPORTER MAINTENANT — {validation.total_valid} questions
            </button>
          )}
        </div>
      )}

      {/* En cours */}
      {step === 'import' && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, border: '1px solid #334155', textAlign: 'center' }}>
          <div style={{ fontSize: 40, marginBottom: 16 }}>⏳</div>
          <div style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600 }}>Import en cours...</div>
          <div style={{ color: '#64748b', fontSize: 13, marginTop: 8 }}>Traitement des questions par lots de 50</div>
          <div style={{ height: 4, background: '#334155', borderRadius: 2, marginTop: 20, overflow: 'hidden' }}>
            <div style={{ height: '100%', background: '#1A5C38', width: '60%', borderRadius: 2, animation: 'loading 1.5s ease-in-out infinite' }} />
          </div>
          <style>{`@keyframes loading { 0% { width: 0% } 50% { width: 80% } 100% { width: 0% } }`}</style>
        </div>
      )}

      {/* Résultats */}
      {step === 'done' && importResult && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid rgba(74,222,128,0.3)', marginBottom: 20 }}>
          <h3 style={{ color: '#4ade80', fontSize: 18, fontWeight: 700, marginBottom: 16 }}>✅ Import terminé !</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 20 }}>
            <StatCard label="✅ Importées" value={importResult.imported} color="#4ade80" />
            <StatCard label="❌ Échecs" value={importResult.failed} color="#ef4444" />
            <StatCard label="Total traité" value={importResult.total} color="#94a3b8" />
            <StatCard label="Durée" value={`${importResult.duration_seconds}s`} color="#D4A017" />
          </div>
          <div style={{ background: 'rgba(74,222,128,0.1)', borderRadius: 8, padding: 12, color: '#4ade80', fontSize: 14, marginBottom: 16 }}>
            🎉 {importResult.imported} questions sont maintenant visibles en direct pour tous les utilisateurs !
            Les séries ont été automatiquement assignées (20 questions/série).
          </div>
          <div style={{ display: 'flex', gap: 12 }}>
            <button onClick={() => { setStep('upload'); setFile(null); setValidation(null); setImportResult(null); }} style={{ padding: '10px 20px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer' }}>
              Nouvel import
            </button>
            <button onClick={() => onNavigate('questions')} style={{ padding: '10px 20px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 600 }}>
              Voir les questions →
            </button>
          </div>
        </div>
      )}

      {/* Historique */}
      {showHistory && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>📜 Historique des imports</h3>
          {history.length === 0 ? (
            <p style={{ color: '#64748b', fontSize: 13 }}>Aucun import enregistré</p>
          ) : history.map((imp: any) => (
            <div key={imp.id} style={{ padding: '10px 0', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ color: '#e2e8f0', fontSize: 13 }}>{imp.filename ?? 'Import ' + imp.id}</div>
                <div style={{ color: '#64748b', fontSize: 12 }}>
                  {new Date(imp.created_at).toLocaleString('fr-FR')} — {imp.imported_count} questions
                  {imp.import_duration_seconds && ` en ${imp.import_duration_seconds}s`}
                </div>
              </div>
              <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                <StatusBadge status={imp.status} />
                {imp.status === 'success' && (
                  <button onClick={() => handleCancelImport(imp.id)} title="Annuler cet import" style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', color: '#ef4444', padding: '4px 8px', borderRadius: 6, cursor: 'pointer', fontSize: 12 }}>
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
    <div style={{ background: '#0f172a', borderRadius: 8, padding: 12, textAlign: 'center' }}>
      <div style={{ color, fontSize: 22, fontWeight: 800 }}>{value?.toLocaleString?.() ?? value}</div>
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
  return <span style={{ background: s.bg, color: s.color, padding: '2px 8px', borderRadius: 10, fontSize: 12 }}>{s.label}</span>;
}

const lbl: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 4, fontWeight: 500 };
const sel: React.CSSProperties = { width: '100%', padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
