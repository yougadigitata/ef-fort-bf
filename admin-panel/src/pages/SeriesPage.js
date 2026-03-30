import { useState, useEffect } from 'react';
import { getSeries, getMatieres, createSerie, updateSerie, deleteSerie, autoGenerateSerie } from '../api';
export default function SeriesPage({ onNavigate }) {
    const [series, setSeries] = useState([]);
    const [matieres, setMatieres] = useState([]);
    const [selectedMatiere, setSelectedMatiere] = useState('');
    const [loading, setLoading] = useState(false);
    const [toast, setToast] = useState('');
    const [showCreate, setShowCreate] = useState(false);
    const [editSerie, setEditSerie] = useState(null);
    const [form, setForm] = useState({ titre: '', matiere_id: '', numero: '', niveau: 'INTERMEDIAIRE', duree_minutes: '15' });
    useEffect(() => { loadMatieres(); }, []);
    useEffect(() => { if (selectedMatiere)
        loadSeries(); }, [selectedMatiere]);
    async function loadMatieres() {
        try {
            const data = await getMatieres();
            setMatieres(data.matieres ?? []);
        }
        catch (_) { }
    }
    async function loadSeries() {
        if (!selectedMatiere)
            return;
        setLoading(true);
        try {
            const mat = matieres.find(m => m.id === selectedMatiere);
            const data = await getSeries({ matiere: mat?.code, matiere_id: selectedMatiere });
            setSeries(data.series ?? []);
        }
        catch (err) {
            showToast('❌ ' + err.message);
        }
        finally {
            setLoading(false);
        }
    }
    function showToast(msg) { setToast(msg); setTimeout(() => setToast(''), 3000); }
    async function handleCreate(e) {
        e.preventDefault();
        try {
            const data = await createSerie({ ...form, matiere_id: form.matiere_id || selectedMatiere, numero: form.numero ? parseInt(form.numero) : undefined });
            showToast(`✅ Série "${form.titre}" créée !`);
            setShowCreate(false);
            setForm({ titre: '', matiere_id: '', numero: '', niveau: 'INTERMEDIAIRE', duree_minutes: '15' });
            loadSeries();
        }
        catch (err) {
            showToast('❌ ' + err.message);
        }
    }
    async function handleAutoGenerate() {
        if (!selectedMatiere) {
            showToast('⚠️ Sélectionner une matière d\'abord');
            return;
        }
        if (!confirm('Créer une série automatique de 20 questions pour cette matière ?'))
            return;
        try {
            const data = await autoGenerateSerie(selectedMatiere, 20);
            showToast(`✅ Série auto créée: ${data.questions_used} questions assignées`);
            loadSeries();
        }
        catch (err) {
            showToast('❌ ' + err.message);
        }
    }
    async function handleDelete(id) {
        if (!confirm('Supprimer cette série ? (les questions ne seront pas supprimées)'))
            return;
        try {
            await deleteSerie(id, 'keep');
            showToast('✅ Série supprimée.');
            setSeries(s => s.filter(x => x.id !== id));
        }
        catch (err) {
            showToast('❌ ' + err.message);
        }
    }
    async function handleToggle(s) {
        try {
            await updateSerie(s.id, { actif: !s.actif });
            setSeries(prev => prev.map(x => x.id === s.id ? { ...x, actif: !s.actif } : x));
            showToast(s.actif ? '✅ Série masquée' : '✅ Série publiée');
        }
        catch (err) {
            showToast('❌ ' + err.message);
        }
    }
    return (<div>
      {toast && <Toast message={toast}/>}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>📚 Gestion des séries</h2>
          <p style={{ color: '#64748b', fontSize: 13 }}>{series.length} séries {selectedMatiere ? 'pour cette matière' : ''}</p>
        </div>
        <div style={{ display: 'flex', gap: 10 }}>
          <button onClick={handleAutoGenerate} disabled={!selectedMatiere} style={{ padding: '8px 14px', background: selectedMatiere ? '#3b82f6' : '#334155', border: 'none', borderRadius: 8, color: 'white', cursor: selectedMatiere ? 'pointer' : 'not-allowed', fontSize: 14 }}>
            🤖 Série auto (20Q)
          </button>
          <button onClick={() => setShowCreate(true)} style={{ padding: '8px 14px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontSize: 14, fontWeight: 600 }}>
            ✚ Créer série
          </button>
        </div>
      </div>

      {/* Filtre matière */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 16, marginBottom: 20, border: '1px solid #334155' }}>
        <label style={{ color: '#94a3b8', fontSize: 13, display: 'block', marginBottom: 8 }}>Filtrer par matière</label>
        <select value={selectedMatiere} onChange={e => setSelectedMatiere(e.target.value)} style={{ padding: '8px 12px', background: '#0f172a', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, minWidth: 250 }}>
          <option value="">Sélectionner une matière...</option>
          {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
        </select>
      </div>

      {/* Formulaire création */}
      {showCreate && (<div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #1A5C38', marginBottom: 20 }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 16 }}>✚ Créer une série</h3>
          <form onSubmit={handleCreate}>
            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 12, marginBottom: 12 }}>
              <div>
                <label style={lbl}>Titre *</label>
                <input value={form.titre} onChange={e => setForm(f => ({ ...f, titre: e.target.value }))} placeholder="Série 1 — Actualité Internationale" required style={{ ...inp, width: '100%' }}/>
              </div>
              <div>
                <label style={lbl}>Matière *</label>
                <select value={form.matiere_id || selectedMatiere} onChange={e => setForm(f => ({ ...f, matiere_id: e.target.value }))} required style={{ ...sel, width: '100%' }}>
                  <option value="">Sélectionner...</option>
                  {matieres.map(m => <option key={m.id} value={m.id}>{m.nom}</option>)}
                </select>
              </div>
              <div>
                <label style={lbl}>Numéro (auto si vide)</label>
                <input type="number" value={form.numero} onChange={e => setForm(f => ({ ...f, numero: e.target.value }))} placeholder="Auto" min="1" style={{ ...inp, width: '100%' }}/>
              </div>
              <div>
                <label style={lbl}>Durée (min)</label>
                <input type="number" value={form.duree_minutes} onChange={e => setForm(f => ({ ...f, duree_minutes: e.target.value }))} min="5" style={{ ...inp, width: '100%' }}/>
              </div>
            </div>
            <div style={{ display: 'flex', gap: 10 }}>
              <button type="submit" style={{ padding: '8px 20px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 600 }}>✅ Créer</button>
              <button type="button" onClick={() => setShowCreate(false)} style={{ padding: '8px 16px', background: '#334155', border: 'none', borderRadius: 8, color: '#94a3b8', cursor: 'pointer' }}>Annuler</button>
            </div>
          </form>
        </div>)}

      {/* Liste des séries */}
      {loading ? (<div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>) : !selectedMatiere ? (<div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>📚</div>
          <div style={{ color: '#64748b' }}>Sélectionner une matière pour voir ses séries</div>
        </div>) : series.length === 0 ? (<div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>📭</div>
          <div style={{ color: '#64748b', marginBottom: 12 }}>Aucune série pour cette matière</div>
          <button onClick={handleAutoGenerate} style={{ background: '#3b82f6', border: 'none', color: 'white', padding: '8px 16px', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}>
            🤖 Créer série auto
          </button>
        </div>) : (<div style={{ background: '#1e293b', borderRadius: 12, border: '1px solid #334155', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#0f172a' }}>
                {['N°', 'Titre', 'Questions', 'Niveau', 'Durée', 'Statut', 'Actions'].map(h => (<th key={h} style={{ padding: '10px 12px', color: '#64748b', fontSize: 12, fontWeight: 600, textAlign: 'left', textTransform: 'uppercase' }}>{h}</th>))}
              </tr>
            </thead>
            <tbody>
              {series.map((s, idx) => (<tr key={s.id} style={{ borderTop: '1px solid #334155', background: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.02)' }}>
                  <td style={{ padding: '10px 12px', color: '#D4A017', fontWeight: 700 }}>#{s.numero}</td>
                  <td style={{ padding: '10px 12px', color: '#e2e8f0', fontSize: 13 }}>{s.titre}</td>
                  <td style={{ padding: '10px 12px', color: '#4ade80', fontSize: 13, fontWeight: 600 }}>{s.nb_questions} Q</td>
                  <td style={{ padding: '10px 12px', color: '#64748b', fontSize: 12 }}>{s.niveau}</td>
                  <td style={{ padding: '10px 12px', color: '#64748b', fontSize: 12 }}>{s.duree_minutes} min</td>
                  <td style={{ padding: '10px 12px' }}>
                    <button onClick={() => handleToggle(s)} style={{
                    background: s.actif ? 'rgba(74,222,128,0.1)' : 'rgba(239,68,68,0.1)',
                    border: 'none', color: s.actif ? '#4ade80' : '#ef4444',
                    padding: '2px 10px', borderRadius: 10, cursor: 'pointer', fontSize: 12,
                }}>
                      {s.actif ? '✅ Active' : '❌ Masquée'}
                    </button>
                  </td>
                  <td style={{ padding: '10px 12px' }}>
                    <div style={{ display: 'flex', gap: 6 }}>
                      <button onClick={() => handleDelete(s.id)} title="Supprimer" style={{ background: 'none', border: 'none', cursor: 'pointer', fontSize: 16, padding: '2px 4px', borderRadius: 4 }}>🗑️</button>
                    </div>
                  </td>
                </tr>))}
            </tbody>
          </table>
        </div>)}
    </div>);
}
const lbl = { display: 'block', color: '#94a3b8', fontSize: 12, marginBottom: 4 };
const inp = { padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
const sel = { padding: '8px 10px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 14 };
function Toast({ message }) {
    return <div style={{ position: 'fixed', top: 70, right: 20, padding: '10px 16px', background: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14, zIndex: 1000 }}>{message}</div>;
}
