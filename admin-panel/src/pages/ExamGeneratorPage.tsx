// ExamGeneratorPage.tsx — Générateur d'examens composites multi-matières
import { useState, useEffect } from 'react';
import { getMatieres, getSimulations, createSimulation } from '../api';
import type { Page } from '../App';

interface MatiereAlloc { matiereId: string; matiereName: string; count: number; }

export default function ExamGeneratorPage({ onNavigate }: { onNavigate: (p: Page) => void }) {
  const [matieres, setMatieres] = useState<any[]>([]);
  const [simulations, setSimulations] = useState<any[]>([]);
  const [allocs, setAllocs] = useState<MatiereAlloc[]>([]);
  const [titre, setTitre] = useState('');
  const [dureeMinutes, setDureeMinutes] = useState(60);
  const [destination, setDestination] = useState<'simulation' | 'serie'>('simulation');
  const [destSimId, setDestSimId] = useState('');
  const [loading, setLoading] = useState(false);
  const [loadingData, setLoadingData] = useState(true);
  const [result, setResult] = useState<any>(null);
  const [error, setError] = useState('');
  const [preview, setPreview] = useState<any[]>([]);
  const [previewing, setPreviewing] = useState(false);

  const BASE_URL = window.location.hostname === 'localhost'
    ? 'http://localhost:8787'
    : 'https://ef-fort-bf.yembuaro29.workers.dev';

  useEffect(() => {
    async function load() {
      try {
        const [matRes, simRes] = await Promise.all([getMatieres(), getSimulations()]);
        setMatieres(matRes.matieres ?? []);
        setSimulations(simRes.simulations ?? []);
      } catch (e: any) { setError(e.message); }
      finally { setLoadingData(false); }
    }
    load();
  }, []);

  const totalQuestions = allocs.reduce((s, a) => s + a.count, 0);

  function addMatiere(mat: any) {
    if (allocs.find(a => a.matiereId === mat.id)) return;
    setAllocs(prev => [...prev, { matiereId: mat.id, matiereName: mat.nom, count: 10 }]);
  }

  function removeAlloc(matiereId: string) {
    setAllocs(prev => prev.filter(a => a.matiereId !== matiereId));
  }

  function updateCount(matiereId: string, count: number) {
    setAllocs(prev => prev.map(a => a.matiereId === matiereId ? { ...a, count: Math.max(1, count) } : a));
  }

  async function handlePreview() {
    if (allocs.length === 0) { setError('Ajoutez au moins une matière'); return; }
    setPreviewing(true); setError(''); setPreview([]);
    try {
      const token = localStorage.getItem('admin_token');
      const res = await fetch(`${BASE_URL}/api/admin-cms/exam-generator/preview`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ allocations: allocs.map(a => ({ matiere_id: a.matiereId, count: a.count })) }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Erreur preview');
      setPreview(data.questions ?? []);
    } catch (e: any) { setError(e.message); }
    finally { setPreviewing(false); }
  }

  async function handleGenerate() {
    if (!titre.trim()) { setError('Donnez un titre à cet examen'); return; }
    if (allocs.length === 0) { setError('Ajoutez au moins une matière'); return; }
    setLoading(true); setError(''); setResult(null);
    try {
      const token = localStorage.getItem('admin_token');
      const body = {
        titre: titre.trim(),
        duree_minutes: dureeMinutes,
        destination,
        simulation_id: destination === 'simulation' ? destSimId || null : null,
        allocations: allocs.map(a => ({ matiere_id: a.matiereId, count: a.count })),
      };
      const res = await fetch(`${BASE_URL}/api/admin-cms/exam-generator/generate`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify(body),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Erreur génération');
      setResult(data);
    } catch (e: any) { setError(e.message); }
    finally { setLoading(false); }
  }

  if (loadingData) return <div style={{ textAlign: 'center', padding: 60, color: '#94a3b8' }}>Chargement des matières...</div>;

  return (
    <div>
      <div style={{ marginBottom: 24 }}>
        <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700, margin: 0 }}>🧩 Générateur d'Examens Composites</h2>
        <p style={{ color: '#64748b', fontSize: 14, marginTop: 6 }}>
          Composez un examen en puisant des questions dans plusieurs matières. L'examen créé apparaîtra automatiquement dans la section Simulations & Examens.
        </p>
      </div>

      {result && (
        <div style={{ background: 'rgba(34,197,94,0.1)', border: '1px solid #22c55e44', borderRadius: 12, padding: 20, marginBottom: 24 }}>
          <div style={{ color: '#22c55e', fontWeight: 700, fontSize: 16, marginBottom: 8 }}>✅ Examen créé avec succès !</div>
          <div style={{ color: '#94a3b8', fontSize: 14 }}>
            <strong style={{ color: '#f1f5f9' }}>{result.titre ?? titre}</strong> — {result.total_questions ?? totalQuestions} questions QCM avec explications
          </div>
          <div style={{ marginTop: 12, display: 'flex', gap: 10 }}>
            <button onClick={() => onNavigate('simulations')} style={{ background: '#22c55e', color: 'white', border: 'none', padding: '8px 16px', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}>
              Voir l'examen créé →
            </button>
            <button onClick={() => { setResult(null); setAllocs([]); setTitre(''); setPreview([]); }} style={{ background: '#334155', color: '#94a3b8', border: 'none', padding: '8px 16px', borderRadius: 8, cursor: 'pointer' }}>
              Créer un autre examen
            </button>
          </div>
        </div>
      )}

      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 24 }}>
        {/* Colonne gauche: Configuration */}
        <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
          {/* Titre */}
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
            <div style={{ color: '#94a3b8', fontSize: 12, fontWeight: 600, marginBottom: 10, textTransform: 'uppercase' }}>Informations de l'examen</div>
            <input
              value={titre}
              onChange={e => setTitre(e.target.value)}
              placeholder="Ex: Concours 2026 — Épreuve Générale"
              style={{
                width: '100%', background: '#0f172a', border: '1px solid #334155', borderRadius: 8,
                padding: '10px 12px', color: '#f1f5f9', fontSize: 14, marginBottom: 12, boxSizing: 'border-box',
              }}
            />
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <label style={{ color: '#94a3b8', fontSize: 13, whiteSpace: 'nowrap' }}>Durée :</label>
              <input type="number" min={10} max={480} value={dureeMinutes}
                onChange={e => setDureeMinutes(parseInt(e.target.value) || 60)}
                style={{ width: 80, background: '#0f172a', border: '1px solid #334155', borderRadius: 8, padding: '8px 10px', color: '#f1f5f9', fontSize: 14 }}
              />
              <span style={{ color: '#64748b', fontSize: 13 }}>minutes</span>
            </div>
          </div>

          {/* Destination */}
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
            <div style={{ color: '#94a3b8', fontSize: 12, fontWeight: 600, marginBottom: 12, textTransform: 'uppercase' }}>Destination</div>
            <div style={{ display: 'flex', gap: 10, marginBottom: 12 }}>
              {(['simulation', 'serie'] as const).map(d => (
                <button key={d} onClick={() => setDestination(d)} style={{
                  flex: 1, padding: '10px', borderRadius: 8, border: `1px solid ${destination === d ? '#1A5C38' : '#334155'}`,
                  background: destination === d ? 'rgba(26,92,56,0.2)' : 'transparent',
                  color: destination === d ? '#4ade80' : '#64748b', cursor: 'pointer', fontWeight: 600, fontSize: 13,
                }}>
                  {d === 'simulation' ? '🎯 Simulation/Examen' : '📚 Nouvelle Série'}
                </button>
              ))}
            </div>
            {destination === 'simulation' && (
              <select value={destSimId} onChange={e => setDestSimId(e.target.value)}
                style={{ width: '100%', background: '#0f172a', border: '1px solid #334155', borderRadius: 8, padding: '9px 12px', color: '#f1f5f9', fontSize: 13, boxSizing: 'border-box' }}>
                <option value="">— Créer une nouvelle simulation —</option>
                {simulations.map((s: any) => <option key={s.id} value={s.id}>{s.titre}</option>)}
              </select>
            )}
          </div>

          {/* Allocations résumé */}
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 12 }}>
              <div style={{ color: '#94a3b8', fontSize: 12, fontWeight: 600, textTransform: 'uppercase' }}>Répartition des questions</div>
              <div style={{ color: '#D4A017', fontWeight: 700, fontSize: 15 }}>{totalQuestions} QCM total</div>
            </div>
            {allocs.length === 0 ? (
              <div style={{ color: '#475569', fontSize: 13, textAlign: 'center', padding: '20px 0' }}>
                Sélectionnez des matières ci-dessous →
              </div>
            ) : (
              <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
                {allocs.map(a => (
                  <div key={a.matiereId} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                    <div style={{ flex: 1, color: '#e2e8f0', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{a.matiereName}</div>
                    <input type="number" min={1} max={100} value={a.count}
                      onChange={e => updateCount(a.matiereId, parseInt(e.target.value) || 1)}
                      style={{ width: 60, background: '#0f172a', border: '1px solid #475569', borderRadius: 6, padding: '5px 8px', color: '#f1f5f9', fontSize: 13, textAlign: 'center' }}
                    />
                    <span style={{ color: '#64748b', fontSize: 12 }}>Q</span>
                    <button onClick={() => removeAlloc(a.matiereId)} style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', padding: 4, display: 'flex', borderRadius: 4 }}>✕</button>
                  </div>
                ))}
              </div>
            )}
          </div>

          {/* Actions */}
          {error && <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: '10px 14px', color: '#ef4444', fontSize: 13 }}>{error}</div>}
          <div style={{ display: 'flex', gap: 10 }}>
            <button onClick={handlePreview} disabled={previewing || allocs.length === 0} style={{
              flex: 1, background: '#334155', color: '#94a3b8', border: '1px solid #475569',
              padding: '10px', borderRadius: 8, cursor: 'pointer', fontWeight: 600, fontSize: 13,
              opacity: allocs.length === 0 ? 0.5 : 1,
            }}>
              {previewing ? '⏳ Aperçu...' : '👁 Aperçu des questions'}
            </button>
            <button onClick={handleGenerate} disabled={loading || allocs.length === 0 || !titre.trim()} style={{
              flex: 2, background: loading ? '#334155' : '#1A5C38', color: 'white', border: 'none',
              padding: '10px', borderRadius: 8, cursor: 'pointer', fontWeight: 700, fontSize: 14,
              opacity: (loading || allocs.length === 0 || !titre.trim()) ? 0.6 : 1,
            }}>
              {loading ? '⏳ Génération...' : `🚀 Générer l'examen (${totalQuestions} QCM)`}
            </button>
          </div>
        </div>

        {/* Colonne droite: Sélection matières */}
        <div>
          <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
            <div style={{ color: '#94a3b8', fontSize: 12, fontWeight: 600, marginBottom: 14, textTransform: 'uppercase' }}>
              Sélectionner des matières ({matieres.length} disponibles)
            </div>
            <div style={{ display: 'flex', flexWrap: 'wrap', gap: 8 }}>
              {matieres.map((mat: any) => {
                const isSelected = allocs.some(a => a.matiereId === mat.id);
                return (
                  <button key={mat.id} onClick={() => isSelected ? removeAlloc(mat.id) : addMatiere(mat)}
                    style={{
                      padding: '7px 14px', borderRadius: 20, border: `1px solid ${isSelected ? '#1A5C38' : '#334155'}`,
                      background: isSelected ? 'rgba(26,92,56,0.3)' : 'transparent',
                      color: isSelected ? '#4ade80' : '#94a3b8', cursor: 'pointer', fontSize: 12, fontWeight: isSelected ? 700 : 400,
                      transition: 'all 0.15s',
                    }}>
                    {isSelected ? '✓ ' : ''}{mat.nom}
                    {mat.nb_questions ? <span style={{ color: '#64748b', marginLeft: 4 }}>({mat.nb_questions})</span> : ''}
                  </button>
                );
              })}
            </div>
          </div>

          {/* Aperçu */}
          {preview.length > 0 && (
            <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155', marginTop: 16, maxHeight: 400, overflowY: 'auto' }}>
              <div style={{ color: '#f1f5f9', fontWeight: 700, marginBottom: 12 }}>👁 Aperçu — {preview.length} questions sélectionnées</div>
              {preview.slice(0, 10).map((q: any, i) => (
                <div key={q.id} style={{ padding: '8px 0', borderBottom: '1px solid #334155', fontSize: 13 }}>
                  <span style={{ color: '#64748b', marginRight: 8 }}>{i + 1}.</span>
                  <span style={{ color: '#e2e8f0' }}>{q.question?.substring(0, 80)}...</span>
                  <span style={{ color: '#475569', marginLeft: 8, fontSize: 11 }}>[{q.matiere}]</span>
                </div>
              ))}
              {preview.length > 10 && <div style={{ color: '#64748b', fontSize: 12, paddingTop: 8 }}>... et {preview.length - 10} autres questions</div>}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
