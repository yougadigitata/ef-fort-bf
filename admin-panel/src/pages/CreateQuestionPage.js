import { useState, useEffect } from 'react';
import { createQuestion, updateQuestion, getQuestion, getMatieres, getSeries } from '../api';
const DIFFICULTES = ['FACILE', 'MOYEN', 'DIFFICILE'];
export default function CreateQuestionPage({ questionId, onNavigate }) {
    const isEdit = !!questionId;
    const [loading, setLoading] = useState(false);
    const [saving, setSaving] = useState(false);
    const [toast, setToast] = useState({ msg: '', type: 'success' });
    const [matieres, setMatieres] = useState([]);
    const [series, setSeries] = useState([]);
    const [form, setForm] = useState({
        enonce: '', option_a: '', option_b: '', option_c: '', option_d: '', option_e: '',
        bonne_reponse: 'A', explication: '', difficulte: 'MOYEN',
        matiere_id: '', serie_id: '', pieges: '', sources: '',
    });
    useEffect(() => { loadMatieres(); if (isEdit && questionId)
        loadQuestion(questionId); }, []);
    async function loadMatieres() {
        try {
            const data = await getMatieres();
            setMatieres(data.matieres ?? []);
        }
        catch (_) { }
    }
    async function loadSeriesForMatiere(matiereId) {
        if (!matiereId) {
            setSeries([]);
            return;
        }
        // Trouver le code de la matière
        const mat = matieres.find(m => m.id === matiereId);
        if (!mat)
            return;
        try {
            const data = await getSeries({ matiere_id: matiereId });
            setSeries(data.series ?? []);
        }
        catch (_) { }
    }
    async function loadQuestion(id) {
        setLoading(true);
        try {
            const data = await getQuestion(id);
            const q = data.question;
            setForm({
                enonce: q.enonce ?? '', option_a: q.option_a ?? '', option_b: q.option_b ?? '',
                option_c: q.option_c ?? '', option_d: q.option_d ?? '', option_e: q.option_e ?? '',
                bonne_reponse: q.bonne_reponse ?? 'A', explication: q.explication ?? '',
                difficulte: q.difficulte ?? 'MOYEN', matiere_id: q.matiere_id ?? '',
                serie_id: q.serie_id ?? '', pieges: q.pieges ?? '', sources: q.sources ?? '',
            });
            if (q.matiere_id)
                await loadSeriesForMatiere(q.matiere_id);
        }
        catch (err) {
            showToast('❌ Erreur: ' + err.message, 'error');
        }
        finally {
            setLoading(false);
        }
    }
    function showToast(msg, type = 'success') {
        setToast({ msg, type });
        setTimeout(() => setToast({ msg: '', type: 'success' }), 4000);
    }
    function validate() {
        if (!form.enonce.trim())
            return 'L\'énoncé est requis.';
        if (!form.option_a.trim())
            return 'L\'option A est requise.';
        if (!form.option_b.trim())
            return 'L\'option B est requise.';
        if (!form.matiere_id)
            return 'La matière est requise.';
        if (!form.bonne_reponse)
            return 'La bonne réponse est requise.';
        return null;
    }
    async function handleSubmit(e) {
        e.preventDefault();
        const err = validate();
        if (err) {
            showToast('⚠️ ' + err, 'error');
            return;
        }
        setSaving(true);
        try {
            if (isEdit && questionId) {
                await updateQuestion(questionId, form);
                showToast('✅ Question modifiée et mise en ligne instantanément !');
            }
            else {
                const data = await createQuestion(form);
                showToast(`✅ Question créée (ID: ${data.question_id?.substring(0, 8)}...) — Visible immédiatement !`);
                // Réinitialiser le formulaire
                setForm(f => ({ ...f, enonce: '', option_a: '', option_b: '', option_c: '', option_d: '', option_e: '', explication: '', pieges: '', sources: '' }));
            }
        }
        catch (err) {
            showToast('❌ ' + err.message, 'error');
        }
        finally {
            setSaving(false);
        }
    }
    const setField = (field, value) => setForm(f => ({ ...f, [field]: value }));
    if (loading)
        return <div style={{ color: '#64748b', padding: 40, textAlign: 'center' }}>⏳ Chargement...</div>;
    return (<div style={{ maxWidth: 800 }}>
      {toast.msg && (<div style={{
                position: 'fixed', top: 70, right: 20, padding: '12px 18px',
                background: toast.type === 'success' ? 'rgba(26,92,56,0.95)' : 'rgba(239,68,68,0.95)',
                border: `1px solid ${toast.type === 'success' ? '#1A5C38' : '#ef4444'}`,
                borderRadius: 8, color: 'white', fontSize: 14, zIndex: 1000,
                boxShadow: '0 10px 30px rgba(0,0,0,0.4)',
            }}>
          {toast.msg}
        </div>)}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>
            {isEdit ? '✏️ Modifier la question' : '✚ Créer une question'}
          </h2>
          {isEdit && <p style={{ color: '#64748b', fontSize: 13 }}>Les modifications sont appliquées LIVE à tous les utilisateurs</p>}
        </div>
        <button onClick={() => onNavigate('questions')} style={{ background: '#334155', border: 'none', color: '#94a3b8', padding: '8px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 14 }}>
          ← Retour liste
        </button>
      </div>

      <form onSubmit={handleSubmit}>
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 16 }}>
          <h3 style={{ color: '#94a3b8', fontSize: 13, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 20 }}>Informations générales</h3>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16, marginBottom: 16 }}>
            <div>
              <label style={lbl}>Matière *</label>
              <select value={form.matiere_id} onChange={e => { setField('matiere_id', e.target.value); loadSeriesForMatiere(e.target.value); }} required style={sel}>
                <option value="">Sélectionner une matière...</option>
                {matieres.map(m => <option key={m.id} value={m.id}>{m.icone} {m.nom}</option>)}
              </select>
            </div>
            <div>
              <label style={lbl}>Difficulté</label>
              <div style={{ display: 'flex', gap: 8 }}>
                {DIFFICULTES.map(d => (<button key={d} type="button" onClick={() => setField('difficulte', d)} style={{
                flex: 1, padding: '8px 4px', border: 'none', borderRadius: 8, cursor: 'pointer',
                fontSize: 12, fontWeight: 600,
                background: form.difficulte === d ? diffColors[d].bg : '#0f172a',
                color: form.difficulte === d ? diffColors[d].color : '#64748b',
                outline: form.difficulte === d ? `2px solid ${diffColors[d].color}` : 'none',
            }}>{d}</button>))}
              </div>
            </div>
          </div>

          <div style={{ marginBottom: 16 }}>
            <label style={lbl}>Énoncé de la question *</label>
            <textarea value={form.enonce} onChange={e => setField('enonce', e.target.value)} placeholder="Tapez l'énoncé de la question..." required rows={3} style={{ ...inp, width: '100%', resize: 'vertical' }}/>
          </div>
        </div>

        {/* Propositions */}
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 16 }}>
          <h3 style={{ color: '#94a3b8', fontSize: 13, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 20 }}>
            Propositions — cocher la bonne réponse
          </h3>

          {['A', 'B', 'C', 'D', 'E'].map(letter => (<div key={letter} style={{ display: 'flex', alignItems: 'center', gap: 12, marginBottom: 10 }}>
              <button type="button" onClick={() => setField('bonne_reponse', letter)} style={{
                width: 36, height: 36, borderRadius: '50%', border: 'none', cursor: 'pointer', fontWeight: 700, fontSize: 14,
                flexShrink: 0, transition: 'all 0.2s',
                background: form.bonne_reponse === letter ? '#1A5C38' : '#334155',
                color: form.bonne_reponse === letter ? 'white' : '#64748b',
                boxShadow: form.bonne_reponse === letter ? '0 0 0 3px rgba(26,92,56,0.4)' : 'none',
            }}>{letter}</button>
              <input type="text" value={form[`option_${letter.toLowerCase()}`]} onChange={e => setField(`option_${letter.toLowerCase()}`, e.target.value)} placeholder={`Proposition ${letter}${letter === 'A' || letter === 'B' ? ' (requise)' : ' (optionnelle)'}`} required={letter === 'A' || letter === 'B'} style={{ ...inp, flex: 1 }}/>
              {form.bonne_reponse === letter && (<span style={{ color: '#4ade80', fontSize: 20, flexShrink: 0 }}>✅</span>)}
            </div>))}
          <p style={{ color: '#475569', fontSize: 12, marginTop: 8 }}>
            Cliquez sur la lettre (A/B/C/D/E) pour définir la bonne réponse
          </p>
        </div>

        {/* Explications */}
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 24, border: '1px solid #334155', marginBottom: 16 }}>
          <h3 style={{ color: '#94a3b8', fontSize: 13, fontWeight: 600, textTransform: 'uppercase', letterSpacing: '0.1em', marginBottom: 20 }}>Informations complémentaires</h3>

          <div style={{ marginBottom: 16 }}>
            <label style={lbl}>Explication détaillée</label>
            <textarea value={form.explication} onChange={e => setField('explication', e.target.value)} placeholder="Explication de la réponse correcte..." rows={3} style={{ ...inp, width: '100%', resize: 'vertical' }}/>
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: 16 }}>
            <div>
              <label style={lbl}>Pièges courants</label>
              <textarea value={form.pieges} onChange={e => setField('pieges', e.target.value)} placeholder="Erreurs fréquentes des candidats..." rows={2} style={{ ...inp, width: '100%', resize: 'vertical' }}/>
            </div>
            <div>
              <label style={lbl}>Source</label>
              <input type="text" value={form.sources} onChange={e => setField('sources', e.target.value)} placeholder="ex: Journal officiel 2026..." style={{ ...inp, width: '100%' }}/>
            </div>
          </div>
        </div>

        {/* Actions */}
        <div style={{ display: 'flex', gap: 12, justifyContent: 'flex-end' }}>
          <button type="button" onClick={() => onNavigate('questions')} style={{
            padding: '12px 24px', background: '#334155', border: 'none', borderRadius: 8,
            color: '#94a3b8', cursor: 'pointer', fontSize: 15, fontWeight: 500,
        }}>
            Annuler
          </button>
          <button type="submit" disabled={saving} style={{
            padding: '12px 32px', background: saving ? '#334155' : 'linear-gradient(135deg, #1A5C38, #2d9966)',
            border: 'none', borderRadius: 8, color: 'white',
            cursor: saving ? 'not-allowed' : 'pointer', fontSize: 15, fontWeight: 600,
        }}>
            {saving ? '⏳ Sauvegarde...' : isEdit ? '💾 Sauvegarder & Publier LIVE' : '🚀 Créer & Publier LIVE'}
          </button>
        </div>

        {/* Validation en temps réel */}
        <div style={{ marginTop: 12, padding: '10px 14px', background: '#0f172a', borderRadius: 8, fontSize: 12, color: '#64748b' }}>
          <span style={{ color: form.enonce ? '#4ade80' : '#ef4444' }}>{form.enonce ? '✅' : '❌'}</span> Énoncé &nbsp;
          <span style={{ color: form.option_a ? '#4ade80' : '#ef4444' }}>{form.option_a ? '✅' : '❌'}</span> Option A &nbsp;
          <span style={{ color: form.option_b ? '#4ade80' : '#ef4444' }}>{form.option_b ? '✅' : '❌'}</span> Option B &nbsp;
          <span style={{ color: form.matiere_id ? '#4ade80' : '#ef4444' }}>{form.matiere_id ? '✅' : '❌'}</span> Matière &nbsp;
          <span style={{ color: form.bonne_reponse ? '#4ade80' : '#ef4444' }}>{form.bonne_reponse ? '✅' : '❌'}</span> Bonne réponse
          &nbsp;— {isEdit ? '✏️ Modification live (zéro rebuild)' : '🆕 Publication instantanée'}
        </div>
      </form>
    </div>);
}
const lbl = { display: 'block', color: '#94a3b8', fontSize: 13, marginBottom: 6, fontWeight: 500 };
const sel = { width: '100%', padding: '10px 12px', background: '#0f172a', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14 };
const inp = { padding: '10px 12px', background: '#0f172a', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 14 };
const diffColors = {
    FACILE: { bg: 'rgba(74,222,128,0.15)', color: '#4ade80' },
    MOYEN: { bg: 'rgba(251,191,36,0.15)', color: '#fbbf24' },
    DIFFICILE: { bg: 'rgba(239,68,68,0.15)', color: '#ef4444' },
};
