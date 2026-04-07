import { useState, useEffect } from 'react';
import { getAuditLog } from '../api';
import type { Page } from '../App';

export default function AuditLogPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [logs, setLogs] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [page, setPage] = useState(1);
  const [toast, setToast] = useState('');

  useEffect(() => { loadLogs(); }, [page]);

  async function loadLogs() {
    setLoading(true);
    try {
      const data = await getAuditLog(page);
      setLogs(data.logs ?? []);
    } catch (err: any) { showToast('❌ ' + err.message); }
    finally { setLoading(false); }
  }

  function showToast(msg: string) { setToast(msg); setTimeout(() => setToast(''), 3000); }

  const actionColors: Record<string, string> = {
    create: '#4ade80', edit: '#3b82f6', delete: '#ef4444',
    soft_delete: '#fbbf24', bulk_import: '#8b5cf6', duplicate: '#06b6d4',
    cancel_import: '#f97316', flag_resolved: '#4ade80',
  };

  return (
    <div>
      {toast && <div style={{ position: 'fixed', top: 70, right: 20, padding: '10px 16px', background: '#1e293b', border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0', fontSize: 17, zIndex: 1000 }}>{toast}</div>}

      <div style={{ marginBottom: 20 }}>
        <h2 style={{ color: '#f1f5f9', fontSize: 20, fontWeight: 700 }}>📜 Audit & Historique</h2>
        <p style={{ color: '#64748b', fontSize: 16 }}>Toutes les actions administratives tracées</p>
      </div>

      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: '#64748b' }}>⏳ Chargement...</div>
      ) : logs.length === 0 ? (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 40, textAlign: 'center', border: '1px solid #334155' }}>
          <div style={{ fontSize: 32, marginBottom: 8 }}>📋</div>
          <div style={{ color: '#64748b' }}>Aucune action enregistrée</div>
        </div>
      ) : (
        <div style={{ background: '#1e293b', borderRadius: 12, border: '1px solid #334155', overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#0f172a' }}>
                {['Date', 'Admin', 'Action', 'Type', 'ID', 'Description'].map(h => (
                  <th key={h} style={{ padding: '10px 12px', color: '#64748b', fontSize: 15, fontWeight: 600, textAlign: 'left', textTransform: 'uppercase' }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {logs.map((log, idx) => (
                <tr key={log.id} style={{ borderTop: '1px solid #334155', background: idx % 2 === 0 ? 'transparent' : 'rgba(255,255,255,0.02)' }}>
                  <td style={{ padding: '10px 12px', color: '#64748b', fontSize: 15, whiteSpace: 'nowrap' }}>
                    {new Date(log.created_at).toLocaleString('fr-FR', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' })}
                  </td>
                  <td style={{ padding: '10px 12px', color: '#94a3b8', fontSize: 15 }}>
                    {String(log.admin_id).substring(0, 8)}...
                  </td>
                  <td style={{ padding: '10px 12px' }}>
                    <span style={{
                      background: `${actionColors[log.action] ?? '#64748b'}22`,
                      color: actionColors[log.action] ?? '#64748b',
                      padding: '2px 8px', borderRadius: 10, fontSize: 14, fontWeight: 600,
                    }}>
                      {log.action}
                    </span>
                  </td>
                  <td style={{ padding: '10px 12px' }}>
                    <span style={{ background: 'rgba(59,130,246,0.1)', color: '#3b82f6', padding: '2px 8px', borderRadius: 10, fontSize: 14 }}>
                      {log.resource_type}
                    </span>
                  </td>
                  <td style={{ padding: '10px 12px', color: '#475569', fontSize: 15, fontFamily: 'monospace' }}>
                    {log.resource_id ? String(log.resource_id).substring(0, 10) : '—'}
                  </td>
                  <td style={{ padding: '10px 12px', color: '#94a3b8', fontSize: 16, maxWidth: 300, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                    {log.description ?? '—'}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>

          <div style={{ padding: '12px 16px', borderTop: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
            <div style={{ color: '#64748b', fontSize: 16 }}>Page {page}</div>
            <div style={{ display: 'flex', gap: 8 }}>
              <button disabled={page <= 1} onClick={() => setPage(p => p - 1)} style={{ padding: '6px 14px', background: page <= 1 ? '#1e293b' : '#334155', border: 'none', borderRadius: 6, color: page <= 1 ? '#475569' : '#e2e8f0', cursor: page <= 1 ? 'not-allowed' : 'pointer', fontSize: 16 }}>◀ Précédent</button>
              <button disabled={logs.length < 20} onClick={() => setPage(p => p + 1)} style={{ padding: '6px 14px', background: logs.length < 20 ? '#1e293b' : '#334155', border: 'none', borderRadius: 6, color: logs.length < 20 ? '#475569' : '#e2e8f0', cursor: logs.length < 20 ? 'not-allowed' : 'pointer', fontSize: 16 }}>Suivant ▶</button>
            </div>
          </div>
        </div>
      )}

      {/* Légende */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 16, marginTop: 16, border: '1px solid #334155' }}>
        <div style={{ color: '#64748b', fontSize: 15, marginBottom: 8 }}>Légende des actions :</div>
        <div style={{ display: 'flex', gap: 12, flexWrap: 'wrap' }}>
          {Object.entries(actionColors).map(([action, color]) => (
            <span key={action} style={{ background: `${color}22`, color, padding: '2px 8px', borderRadius: 10, fontSize: 14 }}>
              {action}
            </span>
          ))}
        </div>
      </div>
    </div>
  );
}
