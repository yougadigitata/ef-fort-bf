// ════════════════════════════════════════════════════════════════
// PAIEMENTS PAGE v3.0 — Validation abonnements + recherche tel
// ════════════════════════════════════════════════════════════════
import { useState, useEffect } from 'react';
import { getPaiements, validerPaiement, getAdminStats } from '../api';
import { getToken } from '../api';
import type { Page } from '../App';

const S = {
  bg: '#0f172a', card: '#1e293b', border: '#334155', text: '#e2e8f0',
  muted: '#64748b', green: '#1A5C38', gold: '#D4A017', blue: '#3b82f6',
  red: '#ef4444', purple: '#8b5cf6', success: '#4ade80', warning: '#fbbf24',
};

const BASE_URL = typeof window !== 'undefined'
  ? (window.location.hostname === 'localhost'
      ? 'http://localhost:8787'
      : 'https://ef-fort-bf.yembuaro29.workers.dev')
  : 'https://ef-fort-bf.yembuaro29.workers.dev';

export default function PaiementsPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [demandes, setDemandes] = useState<any[]>([]);
  const [stats, setStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [toast, setToast] = useState('');
  const [toastType, setToastType] = useState<'success' | 'error'>('success');
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<'all' | 'EN_ATTENTE' | 'VALIDE' | 'REJETE'>('EN_ATTENTE');
  const [processingId, setProcessingId] = useState<string | null>(null);

  useEffect(() => { loadData(); }, []);

  async function loadData() {
    setLoading(true);
    try {
      const [payRes, statsRes] = await Promise.allSettled([getPaiements(), getAdminStats()]);
      if (payRes.status === 'fulfilled') {
        const data = payRes.value;
        setDemandes(data.demandes ?? data.abonnements ?? data.paiements ?? []);
      }
      if (statsRes.status === 'fulfilled') setStats(statsRes.value.stats ?? statsRes.value);
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setLoading(false); }
  }

  function showToast(msg: string, type: 'success' | 'error' = 'success') {
    setToast(msg); setToastType(type);
    setTimeout(() => setToast(''), 4000);
  }

  async function handleValider(id: string, nom: string) {
    if (!confirm(`Valider l'abonnement de "${nom}" ?`)) return;
    setProcessingId(id);
    try {
      await validerPaiement(id);
      showToast(`✅ Abonnement de "${nom}" validé !`);
      loadData();
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setProcessingId(null); }
  }

  async function handleRejeter(id: string, nom: string) {
    if (!confirm(`Rejeter la demande de "${nom}" ?`)) return;
    setProcessingId(id);
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/admin/valider-abonnement/${id}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ statut: 'REJETE' }),
      });
      if (!res.ok) throw new Error('Erreur rejet');
      showToast(`⛔ Demande de "${nom}" rejetée`);
      loadData();
    } catch (e: any) { showToast('❌ ' + e.message, 'error'); }
    finally { setProcessingId(null); }
  }

  // Filtrage
  const filtered = demandes.filter(d => {
    const matchSearch = !search ||
      (d.telephone ?? d.user?.telephone ?? '').includes(search) ||
      (d.prenom ?? d.user?.prenom ?? '').toLowerCase().includes(search.toLowerCase()) ||
      (d.nom ?? d.user?.nom ?? '').toLowerCase().includes(search.toLowerCase());
    const matchFilter = filter === 'all' || (d.statut ?? d.status) === filter;
    return matchSearch && matchFilter;
  });

  const countByStatut = (s: string) => demandes.filter(d => (d.statut ?? d.status) === s).length;

  function formatDate(d: string) {
    if (!d) return '—';
    return new Date(d).toLocaleDateString('fr-FR', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
  }

  return (
    <div style={{ minHeight: '100vh' }}>
      {toast && (
        <div style={{
          position: 'fixed', top: 70, right: 20, padding: '12px 20px',
          background: toastType === 'success' ? '#065f46' : '#7f1d1d',
          border: `1px solid ${toastType === 'success' ? S.success : S.red}`,
          borderRadius: 10, color: '#fff', fontSize: 14, zIndex: 9999,
          boxShadow: '0 4px 20px rgba(0,0,0,0.4)',
        }}>{toast}</div>
      )}

      {/* Header */}
      <div style={{ marginBottom: 20 }}>
        <h2 style={{ color: S.text, fontSize: 22, fontWeight: 700, marginBottom: 4 }}>💳 Gestion des Paiements</h2>
        <p style={{ color: S.muted, fontSize: 13 }}>Validation des abonnements, historique et statistiques</p>
      </div>

      {/* Stats rapides */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(4, 1fr)', gap: 12, marginBottom: 24 }}>
        {[
          { label: 'Total inscrit(s)', value: stats?.totalUsers ?? stats?.total_users ?? demandes.length, color: S.blue, icon: '👥' },
          { label: 'Abonnés actifs', value: stats?.abonnes ?? stats?.total_abonnes ?? countByStatut('VALIDE'), color: S.green, icon: '⭐' },
          { label: 'En attente', value: countByStatut('EN_ATTENTE'), color: S.warning, icon: '⏳' },
          { label: 'Rejetés', value: countByStatut('REJETE'), color: S.red, icon: '❌' },
        ].map((s, i) => (
          <div key={i} style={{ background: S.card, borderRadius: 10, padding: '14px 16px', border: `1px solid ${S.border}` }}>
            <div style={{ fontSize: 22, marginBottom: 6 }}>{s.icon}</div>
            <div style={{ color: s.color, fontSize: 22, fontWeight: 800 }}>{s.value}</div>
            <div style={{ color: S.muted, fontSize: 12 }}>{s.label}</div>
          </div>
        ))}
      </div>

      {/* Filtres + Recherche */}
      <div style={{ display: 'flex', gap: 12, marginBottom: 16, flexWrap: 'wrap', alignItems: 'center' }}>
        <input
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="🔍 Rechercher par téléphone, prénom ou nom…"
          style={{ ...inputStyle, flex: 1, minWidth: 240 }}
        />
        <div style={{ display: 'flex', gap: 6 }}>
          {[
            { key: 'EN_ATTENTE', label: `⏳ Attente (${countByStatut('EN_ATTENTE')})` },
            { key: 'VALIDE', label: `✅ Validés (${countByStatut('VALIDE')})` },
            { key: 'REJETE', label: `❌ Rejetés (${countByStatut('REJETE')})` },
            { key: 'all', label: `📋 Tous (${demandes.length})` },
          ].map(f => (
            <button key={f.key} onClick={() => setFilter(f.key as any)} style={{
              padding: '7px 12px', borderRadius: 7, border: `1px solid ${filter === f.key ? S.green : S.border}`,
              background: filter === f.key ? `${S.green}30` : S.card,
              color: filter === f.key ? S.success : S.muted,
              fontSize: 12, cursor: 'pointer', fontWeight: filter === f.key ? 700 : 400,
              whiteSpace: 'nowrap',
            }}>{f.label}</button>
          ))}
        </div>
        <button onClick={loadData} style={{ background: S.card, border: `1px solid ${S.border}`, color: S.text, borderRadius: 7, padding: '7px 14px', fontSize: 12, cursor: 'pointer' }}>
          🔄 Actualiser
        </button>
      </div>

      {/* Tableau */}
      {loading ? (
        <div style={{ padding: 40, textAlign: 'center', color: S.muted }}>⏳ Chargement…</div>
      ) : filtered.length === 0 ? (
        <div style={{ background: S.card, borderRadius: 12, padding: 40, textAlign: 'center', border: `1px solid ${S.border}` }}>
          <div style={{ fontSize: 36, marginBottom: 12 }}>💳</div>
          <div style={{ color: S.muted }}>Aucune demande trouvée</div>
        </div>
      ) : (
        <div style={{ background: S.card, borderRadius: 12, border: `1px solid ${S.border}`, overflow: 'hidden' }}>
          <table style={{ width: '100%', borderCollapse: 'collapse' }}>
            <thead>
              <tr style={{ background: '#0f172a' }}>
                {['Utilisateur', 'Téléphone', 'Montant', 'Méthode', 'Date demande', 'Statut', 'Actions'].map(h => (
                  <th key={h} style={{ padding: '10px 14px', textAlign: 'left', color: S.muted, fontSize: 11, fontWeight: 700, textTransform: 'uppercase', letterSpacing: 0.5 }}>{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {filtered.map((d, i) => {
                const statut = d.statut ?? d.status ?? 'EN_ATTENTE';
                const statutColors: Record<string, { bg: string; color: string }> = {
                  VALIDE: { bg: '#065f46', color: S.success },
                  EN_ATTENTE: { bg: '#451a03', color: S.warning },
                  REJETE: { bg: '#7f1d1d', color: S.red },
                };
                const sc = statutColors[statut] ?? { bg: '#1e293b', color: S.muted };
                const prenom = d.prenom ?? d.user?.prenom ?? d.profiles?.prenom ?? '?';
                const nom = d.nom ?? d.user?.nom ?? d.profiles?.nom ?? '';
                const tel = d.telephone ?? d.user?.telephone ?? d.profiles?.telephone ?? '—';
                const montant = d.montant ?? d.amount ?? '—';
                const methode = d.methode_paiement ?? d.method ?? d.payment_method ?? '—';

                return (
                  <tr key={d.id} style={{ borderBottom: `1px solid #1e293b`, background: i % 2 === 0 ? 'transparent' : '#0f172a20' }}>
                    <td style={{ padding: '10px 14px', color: S.text, fontSize: 13, fontWeight: 600 }}>
                      {prenom} {nom}
                    </td>
                    <td style={{ padding: '10px 14px', color: S.cyan ?? '#06b6d4', fontSize: 13, fontFamily: 'monospace' }}>
                      {tel}
                    </td>
                    <td style={{ padding: '10px 14px', color: S.gold, fontSize: 13, fontWeight: 700 }}>
                      {montant !== '—' ? `${montant} FCFA` : '—'}
                    </td>
                    <td style={{ padding: '10px 14px', color: S.muted, fontSize: 12 }}>{methode}</td>
                    <td style={{ padding: '10px 14px', color: S.muted, fontSize: 11 }}>
                      {formatDate(d.created_at ?? d.date_demande)}
                    </td>
                    <td style={{ padding: '10px 14px' }}>
                      <span style={{ background: sc.bg, color: sc.color, padding: '3px 8px', borderRadius: 5, fontSize: 11, fontWeight: 700 }}>
                        {statut === 'VALIDE' ? '✅ Validé' : statut === 'REJETE' ? '❌ Rejeté' : '⏳ En attente'}
                      </span>
                    </td>
                    <td style={{ padding: '10px 14px' }}>
                      {statut === 'EN_ATTENTE' && (
                        <div style={{ display: 'flex', gap: 6 }}>
                          <button
                            onClick={() => handleValider(d.id, `${prenom} ${nom}`)}
                            disabled={processingId === d.id}
                            style={{ background: S.green, color: '#fff', border: 'none', borderRadius: 5, padding: '4px 10px', fontSize: 11, cursor: 'pointer', fontWeight: 700 }}>
                            {processingId === d.id ? '⏳' : '✅ Valider'}
                          </button>
                          <button
                            onClick={() => handleRejeter(d.id, `${prenom} ${nom}`)}
                            disabled={processingId === d.id}
                            style={{ background: '#7f1d1d', color: '#fff', border: 'none', borderRadius: 5, padding: '4px 10px', fontSize: 11, cursor: 'pointer' }}>
                            {processingId === d.id ? '⏳' : '❌'}
                          </button>
                        </div>
                      )}
                      {statut !== 'EN_ATTENTE' && (
                        <span style={{ color: S.muted, fontSize: 11 }}>
                          {formatDate(d.updated_at ?? d.date_validation ?? '')}
                        </span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
      )}
    </div>
  );
}

const inputStyle: React.CSSProperties = {
  padding: '8px 12px', background: '#1e293b',
  border: '1px solid #334155', borderRadius: 7, color: '#e2e8f0',
  fontSize: 13, boxSizing: 'border-box' as const,
};
