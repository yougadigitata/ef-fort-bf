import { useState, useRef, useEffect } from 'react';
import { getExamens, bulkImportExamen, publishExamen, deleteSimulation } from '../api';
import type { Page } from '../App';

export default function ExamensImportPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [examens, setExamens] = useState<any[]>([]);
  const [file, setFile] = useState<File | null>(null);
  const [titre, setTitre] = useState('');
  const [loading, setLoading] = useState(false);
  const [toast, setToast] = useState('');
  const [step, setStep] = useState<'list' | 'import' | 'done'>('list');
  const [importResult, setImportResult] = useState<any>(null);
  const fileInputRef = useRef<HTMLInputElement>(null);

  useEffect(() => { loadExamens(); }, []);

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 5000);
  }

  async function loadExamens() {
    try {
      const data = await getExamens();
      setExamens(data.examens ?? []);
    } catch (e: any) {
      showToast('❌ ' + e.message);
    }
  }

  async function handleFileSelect(e: React.ChangeEvent<HTMLInputElement>) {
    const f = e.target.files?.[0];
    if (f) setFile(f);
  }

  async function handleImport() {
    if (!file) { showToast('❌ Sélectionnez un fichier'); return; }
    if (!titre.trim()) { showToast('❌ Entrez un titre pour cet examen'); return; }
    if (!confirm(`Importer les questions de "${file.name}" comme examen "${titre}" ?`)) return;

    setLoading(true);
    setStep('import');
    try {
      const text = await file.text();
      let questions: any[] = [];

      if (file.name.endsWith('.json')) {
        const parsed = JSON.parse(text);
        questions = Array.isArray(parsed) ? parsed : parsed.questions ?? [];
      } else if (file.name.endsWith('.md') || file.name.endsWith('.txt') || file.name.endsWith('.markdown')) {
        // Envoyer en texte brut au backend
        const baseUrl = window.location.hostname === 'localhost'
          ? 'http://localhost:8787/api/admin-cms'
          : 'https://ef-fort-bf.yembuaro29.workers.dev/api/admin-cms';
        const res = await fetch(`${baseUrl}/examens/bulk-import`, {
          method: 'POST',
          headers: {
            'Content-Type': 'text/plain',
            'Authorization': `Bearer ${localStorage.getItem('admin_token')}`,
            'X-Titre': titre,
          },
          body: text,
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.error ?? 'Erreur');
        setImportResult(data);
        setStep('done');
        showToast(`✅ ${data.imported} questions importées !`);
        loadExamens();
        return;
      } else {
        // CSV
        const lines = text.split('\n').filter((l: string) => l.trim());
        if (lines.length < 2) { showToast('❌ Fichier CSV vide'); setStep('list'); return; }
        const headers = lines[0].split(';').map((h: string) => h.trim().toLowerCase());
        questions = lines.slice(1).map((line: string) => {
          const vals = line.split(';').map((v: string) => v.trim());
          const obj: any = {};
          headers.forEach((h: string, i: number) => { obj[h] = vals[i] ?? ''; });
          return obj;
        });
      }

      const data = await bulkImportExamen(questions, titre);
      setImportResult(data);
      setStep('done');
      showToast(`✅ ${data.imported} questions d'examen importées !`);
      loadExamens();
    } catch (e: any) {
      showToast('❌ ' + e.message);
      setStep('list');
    } finally {
      setLoading(false);
    }
  }

  async function togglePublish(examen: any) {
    try {
      await publishExamen(examen.id, !examen.published);
      showToast(`✅ Examen ${!examen.published ? 'publié' : 'dépublié'}`);
      loadExamens();
    } catch (e: any) {
      showToast('❌ ' + e.message);
    }
  }

  async function handleDelete(id: string, titre: string) {
    if (!confirm(`Supprimer l'examen "${titre}" et toutes ses questions ?`)) return;
    try {
      await deleteSimulation(id);
      showToast('✅ Examen supprimé');
      loadExamens();
    } catch (e: any) {
      showToast('❌ ' + e.message);
    }
  }

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
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>📝 Import Examens / Simulations</h2>
        <p style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
          Importez des questions d'examens blancs (50 questions) — CSV, JSON, Markdown ou TXT
        </p>
      </div>

      {/* Zone d'import */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 24 }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 16 }}>📤 Importer un nouvel examen</h3>

        {/* Titre */}
        <div style={{ marginBottom: 16 }}>
          <label style={{ color: '#94a3b8', fontSize: 12, fontWeight: 600, display: 'block', marginBottom: 6 }}>
            TITRE DE L'EXAMEN *
          </label>
          <input
            type="text"
            value={titre}
            onChange={e => setTitre(e.target.value)}
            placeholder="Ex: Examen Blanc 2025 - Session 1"
            style={{
              width: '100%', padding: '10px 14px',
              background: '#0f172a', border: '1px solid #334155',
              borderRadius: 8, color: '#f1f5f9', fontSize: 14,
              boxSizing: 'border-box',
            }}
          />
        </div>

        {/* Formats acceptés */}
        <div style={{ background: 'rgba(16,185,129,0.1)', border: '1px solid rgba(16,185,129,0.3)', borderRadius: 8, padding: '10px 14px', marginBottom: 16, fontSize: 13, color: '#10b981' }}>
          ✅ <strong>Formats acceptés :</strong> CSV (.csv), JSON (.json), Markdown (.md), Texte (.txt)<br/>
          ✅ <strong>Recommandé :</strong> 50 questions pour un examen blanc officiel
        </div>

        {/* Upload zone */}
        <div
          onClick={() => fileInputRef.current?.click()}
          style={{
            border: '2px dashed #334155', borderRadius: 10, padding: 30,
            textAlign: 'center', cursor: 'pointer',
            background: file ? 'rgba(26,92,56,0.08)' : 'rgba(255,255,255,0.02)',
            borderColor: file ? '#1A5C38' : '#334155',
            marginBottom: 16,
          }}
        >
          {file ? (
            <div>
              <div style={{ fontSize: 36, marginBottom: 8 }}>📂</div>
              <div style={{ color: '#4ade80', fontWeight: 700, fontSize: 15 }}>{file.name}</div>
              <div style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>
                {(file.size / 1024).toFixed(1)} KB
              </div>
              <button
                onClick={e => { e.stopPropagation(); setFile(null); if (fileInputRef.current) fileInputRef.current.value = ''; }}
                style={{ marginTop: 8, padding: '4px 12px', background: 'rgba(239,68,68,0.15)', border: '1px solid rgba(239,68,68,0.3)', color: '#ef4444', borderRadius: 6, cursor: 'pointer', fontSize: 12 }}
              >
                🗑️ Changer
              </button>
            </div>
          ) : (
            <div>
              <div style={{ fontSize: 36, marginBottom: 8 }}>📝</div>
              <div style={{ color: '#94a3b8', fontSize: 15, fontWeight: 600 }}>Cliquer pour uploader</div>
              <div style={{ color: '#475569', fontSize: 12, marginTop: 4 }}>CSV, JSON, .md, .txt — Max 20 MB</div>
            </div>
          )}
          <input ref={fileInputRef} type="file" accept=".csv,.json,.md,.txt,.markdown" onChange={handleFileSelect} style={{ display: 'none' }} />
        </div>

        <button
          onClick={handleImport}
          disabled={loading || !file || !titre.trim()}
          style={{
            width: '100%', padding: 14,
            background: loading || !file || !titre.trim() ? '#334155' : 'linear-gradient(135deg, #1A5C38, #2d9966)',
            border: 'none', borderRadius: 10, color: 'white',
            cursor: loading || !file || !titre.trim() ? 'not-allowed' : 'pointer',
            fontWeight: 700, fontSize: 16,
          }}
        >
          {loading ? '⏳ Import en cours...' : '🚀 IMPORTER L\'EXAMEN'}
        </button>
      </div>

      {/* Résultat import */}
      {step === 'done' && importResult && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid rgba(74,222,128,0.3)', marginBottom: 24 }}>
          <h3 style={{ color: '#4ade80', fontSize: 17, fontWeight: 700, marginBottom: 12 }}>✅ Import réussi !</h3>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(3, 1fr)', gap: 10 }}>
            <StatCard label="✅ Importées" value={importResult.imported} color="#4ade80" />
            <StatCard label="❌ Échecs" value={importResult.failed} color="#ef4444" />
            <StatCard label="⏱ Durée" value={`${importResult.duration_seconds}s`} color="#D4A017" />
          </div>
          {importResult.simulation_id && (
            <div style={{ marginTop: 12, padding: '8px 14px', background: 'rgba(26,92,56,0.15)', borderRadius: 8, color: '#4ade80', fontSize: 13 }}>
              🎯 Simulation créée avec ID: <strong>{importResult.simulation_id}</strong><br/>
              ⚠️ L'examen est <strong>non publié</strong> par défaut — publiez-le ci-dessous quand prêt.
            </div>
          )}
          <button
            onClick={() => { setStep('list'); setFile(null); setTitre(''); setImportResult(null); if (fileInputRef.current) fileInputRef.current.value = ''; }}
            style={{ marginTop: 12, padding: '8px 16px', background: '#334155', border: 'none', color: '#94a3b8', borderRadius: 8, cursor: 'pointer', fontSize: 13 }}
          >
            ← Retour
          </button>
        </div>
      )}

      {/* Liste des examens */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600 }}>📋 Examens existants ({examens.length})</h3>
          <button
            onClick={loadExamens}
            style={{ background: '#334155', border: 'none', color: '#94a3b8', padding: '6px 12px', borderRadius: 8, cursor: 'pointer', fontSize: 12 }}
          >
            🔄 Actualiser
          </button>
        </div>

        {examens.length === 0 ? (
          <div style={{ textAlign: 'center', padding: 40, color: '#64748b' }}>
            <div style={{ fontSize: 40, marginBottom: 12 }}>📭</div>
            <div>Aucun examen pour le moment. Importez votre premier examen ci-dessus.</div>
          </div>
        ) : (
          <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
            {examens.map((ex: any) => (
              <div key={ex.id} style={{
                padding: '14px 16px', background: '#0f172a',
                borderRadius: 10, border: `1px solid ${ex.published ? 'rgba(26,92,56,0.5)' : '#334155'}`,
                display: 'flex', alignItems: 'center', gap: 12,
              }}>
                <div style={{ flex: 1 }}>
                  <div style={{ color: '#f1f5f9', fontWeight: 600, fontSize: 14 }}>{ex.titre}</div>
                  <div style={{ color: '#64748b', fontSize: 12, marginTop: 2 }}>
                    {ex.nb_questions_examen ?? ex.score_max ?? '?'} questions
                    &nbsp;·&nbsp; {ex.duree_minutes} min
                    &nbsp;·&nbsp; Créé le {new Date(ex.created_at).toLocaleDateString('fr-FR')}
                  </div>
                  {ex.description && (
                    <div style={{ color: '#475569', fontSize: 11, marginTop: 2 }}>{ex.description}</div>
                  )}
                </div>
                <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
                  <span style={{
                    padding: '3px 10px', borderRadius: 20, fontSize: 11, fontWeight: 700,
                    background: ex.published ? 'rgba(26,92,56,0.2)' : 'rgba(100,116,139,0.2)',
                    color: ex.published ? '#4ade80' : '#94a3b8',
                    border: `1px solid ${ex.published ? 'rgba(26,92,56,0.4)' : '#334155'}`,
                  }}>
                    {ex.published ? '🟢 Publié' : '⚫ Brouillon'}
                  </span>
                  <button
                    onClick={() => togglePublish(ex)}
                    style={{
                      padding: '5px 12px', borderRadius: 6, border: 'none', cursor: 'pointer', fontSize: 12,
                      background: ex.published ? 'rgba(239,68,68,0.15)' : 'rgba(26,92,56,0.2)',
                      color: ex.published ? '#ef4444' : '#4ade80',
                    }}
                  >
                    {ex.published ? 'Dépublier' : 'Publier'}
                  </button>
                  <button
                    onClick={() => handleDelete(ex.id, ex.titre)}
                    style={{ padding: '5px 10px', borderRadius: 6, border: '1px solid rgba(239,68,68,0.3)', background: 'rgba(239,68,68,0.1)', color: '#ef4444', cursor: 'pointer', fontSize: 12 }}
                  >
                    🗑️
                  </button>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}

function StatCard({ label, value, color }: { label: string; value: any; color: string }) {
  return (
    <div style={{ padding: '12px 16px', background: '#0f172a', borderRadius: 8, border: `1px solid ${color}33`, textAlign: 'center' }}>
      <div style={{ color, fontSize: 22, fontWeight: 800 }}>{value}</div>
      <div style={{ color: '#64748b', fontSize: 11, marginTop: 2 }}>{label}</div>
    </div>
  );
}
