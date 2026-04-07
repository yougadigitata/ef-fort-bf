import { useState, useEffect, useCallback } from 'react';
import { getQuestions, getMatieres, getSeries, deleteQuestion, duplicateQuestion } from '../api';
import type { Page } from '../App';

export default function QuestionsPage({ onNavigate, onEdit }: { onNavigate: (page: Page) => void; onEdit: (id: string) => void }) {
  const [questions, setQuestions] = useState<any[]>([]);
  const [matieres, setMatieres] = useState<any[]>([]);
  const [series, setSeries] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [total, setTotal] = useState(0);
  const [page, setPage] = useState(1);
  const [pages, setPages] = useState(1);
  const [toast, setToast] = useState('');

  const [filters, setFilters] = useState({
    matiere: '', serie_id: '', difficulte: 'TOUS', search: '', limit: 20,
  });

  useEffect(() => { loadMatieres(); }, []);
  useEffect(() => { loadQuestions(); }, [page, filters.matiere, filters.serie_id, filters.difficulte]);

  async function loadMatieres() {
    try {
      const data = await getMatieres();
      setMatieres(data.matieres ?? []);
    } catch (_) {}
  }

  async function loadSeriesForMatiere(matiereCode: string) {
    if (!matiereCode) { setSeries([]); return; }
    try {
      const data = await getSeries({ matiere: matiereCode });
      setSeries(data.series ?? []);
    } catch (_) {}
  }

  async function loadQuestions() {
    setLoading(true);
    try {
      const data = await getQuestions({
        matiere: filters.matiere || undefined,
        serie_id: filters.serie_id || undefined,
        difficulte: filters.difficulte !== 'TOUS' ? filters.difficulte : undefined,
        search: filters.search || undefined,
        page, limit: filters.limit,
      });
      setQuestions(data.questions ?? []);
      setTotal(data.total ?? 0);
      setPages(data.pages ?? 1);
    } catch (err: any) {
      showToast('❌ Erreur: ' + err.message);
    } finally {
      setLoading(false);
    }
  }

  function showToast(msg: string) {
    setToast(msg);
    setTimeout(() => setToast(''), 3000);
  }

  async function handleDelete(id: string, soft = false) {
    if (!confirm(soft ? 'Masquer cette question ?' : 'Supprimer définitivement cette question ?')) return;
    try {
      await deleteQuestion(id, soft);
      showToast(soft ? '✅ Question masquée.' : '✅ Question supprimée.');
      loadQuestions();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  async function handleDuplicate(id: string) {
    try {
      const data = await duplicateQuestion(id);
      showToast('✅ Question dupliquée (ID: ' + data.new_question_id?.substring(0, 8) + ')');
      loadQuestions();
    } catch (err: any) { showToast('❌ ' + err.message); }
  }

  function handleSearchKeyDown(e: React.KeyboardEvent) {
    if (e.key === 'Enter') { setPage(1); loadQuestions(); }
  }

  const matiereChange = (code: string) => {
    setFilters(f => ({ ...f, matiere: code, serie_id: '' }));
    setPage(1);
    loadSeriesForMatiere(code);
  };

  return (
    <div>
      {toast && <Toast message={toast} />}

      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 20 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>Gestion des questions</h2>
          <p style={{ color: '#64748b', fontSize: 16 }}>{total.toLocaleString()} questions au total</p>
        </div>
        <button onClick={() => onNavigate('create-question')} style={{
          background: '#1A5C38', border: 'none', color: 'white', padding: '10px 18px',
          borderRadius: 8, cursor: 'pointer', fontWeight: 600, fontSize: 17, display: 'flex', alignItems: 'center', gap: 6,
        }}>
          ✚ Créer question
        </button>
      </div>

      {/* Filtres */}
      <div style={{
        background: '#1e293b', borderRadius: 12, padding: 16, marginBottom: 20,
        border: '1px solid #334155', display: 'flex', gap: 12, flexWrap: 'wrap', alignItems: 'flex-end',
      }}>
        <div style={{ flex: '1 1 160px' }}>
          <label style={labelStyle}>Matière</label>
          <select value={filters.matiere} onChange={e => matiereChange(e.target.value)} style={selectStyle}>
            <option value="">Toutes les matières</option>
            {matieres.map(m => <option key={m.id} value={m.code}>{m.nom}</option>)}
          </select>
        </div>
        <div style={{ flex: '1 1 140px' }}>
          <label style={labelStyle}>Série</label>
          <select value={filters.serie_id} onChange={e => { setFilters(f => ({ ...f, serie_id: e.target.value })); setPage(1); }} style={selectStyle}>
            <option value="">Toutes les séries</option>
            {series.map(s => <option key={s.id} value={s.id}>Série {s.numero}</option>)}
          </select>
        </div>
        <div style={{ flex: '1 1 120px' }}>
          <label style={labelStyle}>Difficulté</label>
          <select value={filters.difficulte} onChange={e => { setFilters(f => ({ ...f, difficulte: e.target.value })); setPage(1); }} style={selectStyle}>
            <option value="TOUS">Toutes</option>
            <option value="FACILE">Facile</option>
            <option value="MOYEN">Moyen</option>
            <option value="DIFFICILE">Difficile</option>
          </select>
        </div>
        <div style={{ flex: '2 1 220px' }}>
          <label style={labelStyle}>Recherche</label>
          <input
            type="text" value={filters.search}
            onChange={e => setFilters(f => ({ ...f, search: e.target.value }))}
            onKeyDown={handleSearchKeyDown}
            placeholder="Taper pour rechercher... (Entrée)"
            style={{ ...inputStyle, width: '100%' }}
          />
        </div>
        <button onClick={() => { setPage(1); loadQuestions(); }} style={{ padding: '8px 16px', background: '#1A5C38', border: 'none', borderRadius: 8, color: 'white', cursor: 'pointer', fontWeight: 600, fontSize: 17 }}>
          🔍 Filtrer
        </button>
      </div>

      {/* Tableau */}
      <div style={{ background: '#1e293b', borderRadius: 12, border: '1px solid #334155', overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>
        ) : questions.length === 0 ? (
          <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>
            <div style={{ fontSize: 32, marginBottom: 8 }}>📭</div>
            <div>Aucune question trouvée</div>
            <button onClick={() => onNavigate('bulk-import')} style={{ marginTop: 12, background: '#1A5C38', border: 'none', color: 'white', padding: '8px 16px', borderRadius: 8, cursor: 'pointer' }}>
              📤 Importer des questions
            </button>
          </div>
        ) : (
          <>
            <table style={{ width: '100%', borderCollapse: 'collapse' }}>
              <thead>
                <tr style={{ background: '#0f172a' }}>
                  {['#', 'Question', 'Matière', 'Série', 'Diff.', 'Rép.', 'Statut', 'Actions'].map(h => (
                    <th key={h} style={{ padding: '12px 14px', color: '#64748b', fontSize: 16, fontWeight: 600, textAlign: 'left', textTransform: 'uppercase', letterSpacing: '0.05em', whiteSpace: 'nowrap' }}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {questions.map((q, idx) => (
                  <tr key={q.id} style={{
                    borderTop: '1px solid #334155',
                    background: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.02)',
                    opacity: q.published === false ? 0.5 : 1,
                  }}>
                    <td style={{ padding: '12px 14px', color: '#475569', fontSize: 16 }}>
                      {(page - 1) * filters.limit + idx + 1}
                    </td>
                    <td style={{ padding: '10px 12px', maxWidth: 300 }}>
                      <div style={{ color: '#e2e8f0', fontSize: 17, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                        {q.enonce}
                      </div>
                      {q.sources && <div style={{ color: '#475569', fontSize: 15 }}>📌 {q.sources}</div>}
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <MatiereChip matiereId={q.matiere_id} matieres={matieres} />
                    </td>
                    <td style={{ padding: '12px 14px', color: '#64748b', fontSize: 16, whiteSpace: 'nowrap' }}>
                      {q.numero_serie ? `Série ${q.numero_serie}` : '—'}
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <DiffBadge diff={q.difficulte} />
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <span style={{
                        display: 'inline-block', width: 26, height: 26, borderRadius: '50%',
                        background: '#1A5C38', color: 'white', fontSize: 15, fontWeight: 700,
                        textAlign: 'center', lineHeight: '26px',
                      }}>
                        {q.bonne_reponse}
                      </span>
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      {q.published === false ? (
                        <span style={{ background: 'rgba(239,68,68,0.1)', color: '#ef4444', padding: '3px 10px', borderRadius: 10, fontSize: 15 }}>Masqué</span>
                      ) : (
                        <span style={{ background: 'rgba(74,222,128,0.1)', color: '#4ade80', padding: '3px 10px', borderRadius: 10, fontSize: 15 }}>Publié</span>
                      )}
                    </td>
                    <td style={{ padding: '10px 12px' }}>
                      <div style={{ display: 'flex', gap: 6 }}>
                        <ActionBtn title="Modifier" onClick={() => onEdit(q.id)}>✏️</ActionBtn>
                        <ActionBtn title="Dupliquer" onClick={() => handleDuplicate(q.id)}>📋</ActionBtn>
                        <ActionBtn title="Masquer" onClick={() => handleDelete(q.id, true)} color="#fbbf24">👁️</ActionBtn>
                        <ActionBtn title="Supprimer" onClick={() => handleDelete(q.id, false)} color="#ef4444">🗑️</ActionBtn>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>

            {/* Pagination */}
            <div style={{ padding: '12px 16px', borderTop: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div style={{ color: '#64748b', fontSize: 16 }}>
                Page {page} / {pages} — {total.toLocaleString()} questions
              </div>
              <div style={{ display: 'flex', gap: 8 }}>
                <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} style={{ ...paginationBtn, opacity: page <= 1 ? 0.4 : 1 }}>◀ Précédent</button>
                <button disabled={page >= pages} onClick={() => setPage(p => p + 1)} style={{ ...paginationBtn, opacity: page >= pages ? 0.4 : 1 }}>Suivant ▶</button>
              </div>
            </div>
          </>
        )}
      </div>
    </div>
  );
}

const labelStyle: React.CSSProperties = { display: 'block', color: '#94a3b8', fontSize: 16, marginBottom: 4, fontWeight: 500 };
const selectStyle: React.CSSProperties = { width: '100%', padding: '10px 12px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 18 };
const inputStyle: React.CSSProperties = { padding: '10px 12px', background: '#0f172a', border: '1px solid #334155', borderRadius: 6, color: '#e2e8f0', fontSize: 18 };
const paginationBtn: React.CSSProperties = { padding: '8px 16px', background: '#334155', border: 'none', borderRadius: 6, color: '#e2e8f0', cursor: 'pointer', fontSize: 17 };

function MatiereChip({ matiereId, matieres }: { matiereId: string; matieres: any[] }) {
  const m = matieres.find(m => m.id === matiereId);
  if (!m) return <span style={{ color: '#475569', fontSize: 16 }}>—</span>;
  return <span style={{ background: 'rgba(26,92,56,0.2)', color: '#4ade80', padding: '3px 10px', borderRadius: 10, fontSize: 15, whiteSpace: 'nowrap' }}>{m.code}</span>;
}

function DiffBadge({ diff }: { diff: string }) {
  const colors: Record<string, any> = {
    FACILE: { bg: 'rgba(74,222,128,0.1)', color: '#4ade80' },
    MOYEN: { bg: 'rgba(251,191,36,0.1)', color: '#fbbf24' },
    DIFFICILE: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444' },
  };
  const c = colors[diff ?? 'MOYEN'] ?? colors.MOYEN;
  return <span style={{ background: c.bg, color: c.color, padding: '3px 10px', borderRadius: 10, fontSize: 15 }}>{diff ?? 'MOYEN'}</span>;
}

function ActionBtn({ children, title, onClick, color = '#94a3b8' }: any) {
  return (
    <button onClick={onClick} title={title} style={{
      background: 'none', border: 'none', cursor: 'pointer', fontSize: 17,
      padding: '2px 4px', borderRadius: 4, transition: 'background 0.15s',
    }}
    onMouseEnter={e => (e.currentTarget.style.background = '#334155')}
    onMouseLeave={e => (e.currentTarget.style.background = 'none')}
    >{children}</button>
  );
}

function Toast({ message }: { message: string }) {
  return (
    <div style={{
      position: 'fixed', top: 70, right: 20, background: '#1e293b',
      border: '1px solid #334155', borderRadius: 8, padding: '10px 16px',
      color: '#e2e8f0', fontSize: 17, zIndex: 1000,
      boxShadow: '0 10px 30px rgba(0,0,0,0.4)',
    }}>
      {message}
    </div>
  );
}
