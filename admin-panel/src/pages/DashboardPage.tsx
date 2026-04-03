import { useState, useEffect } from 'react';
import { getDashboard, runMigration, getAdminStats } from '../api';
import type { Page } from '../App';

const COLORS = { green: '#1A5C38', gold: '#D4A017', blue: '#3b82f6', red: '#ef4444', purple: '#8b5cf6', cyan: '#06b6d4' };

export default function DashboardPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [stats, setStats] = useState<any>(null);
  const [adminStats, setAdminStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [migrationStatus, setMigrationStatus] = useState<any>(null);
  const [migrating, setMigrating] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());

  useEffect(() => { loadStats(); }, []);

  // Auto-refresh toutes les 60 secondes
  useEffect(() => {
    const interval = setInterval(() => { loadStats(); setLastRefresh(new Date()); }, 60000);
    return () => clearInterval(interval);
  }, []);

  async function loadStats() {
    try {
      const [cmsData, adminData] = await Promise.allSettled([getDashboard(), getAdminStats()]);
      if (cmsData.status === 'fulfilled') setStats(cmsData.value.stats);
      if (adminData.status === 'fulfilled') setAdminStats(adminData.value.stats ?? adminData.value);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  }

  async function handleMigration() {
    setMigrating(true);
    try {
      const result = await runMigration();
      setMigrationStatus(result);
    } catch (err: any) {
      setMigrationStatus({ error: err.message });
    } finally {
      setMigrating(false);
    }
  }

  if (loading) return <LoadingSpinner />;

  const cards = [
    { label: 'Utilisateurs', value: stats?.total_users ?? adminStats?.totalUsers ?? adminStats?.total_users ?? 0, icon: '👥', color: COLORS.blue, page: null },
    { label: 'Abonnés actifs', value: adminStats?.abonnes ?? adminStats?.total_abonnes ?? 0, icon: '⭐', color: COLORS.gold, page: null },
    { label: 'Questions publiées', value: stats?.total_questions ?? adminStats?.totalQuestions ?? 0, icon: '📚', color: COLORS.green, page: 'questions' as Page },
    { label: 'Simulations jouées', value: stats?.total_simulations_played ?? adminStats?.totalSimulations ?? 0, icon: '🎯', color: COLORS.purple, page: null },
    { label: 'Demandes en attente', value: adminStats?.demandesEnAttente ?? adminStats?.demandes_en_attente ?? 0, icon: '💳', color: (adminStats?.demandesEnAttente ?? 0) > 0 ? COLORS.red : '#334155', page: 'paiements' as Page },
    { label: 'Signalements actifs', value: stats?.pending_flags ?? 0, icon: '🚨', color: (stats?.pending_flags ?? 0) > 0 ? COLORS.red : '#334155', page: 'flags' as Page },
  ];

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>📊 Tableau de bord</h2>
          <p style={{ color: '#64748b', fontSize: 14, marginTop: 4 }}>Vue d'ensemble consolidée de la plateforme EF-FORT.BF</p>
        </div>
        <div style={{ textAlign: 'right' }}>
          <button onClick={() => { setLoading(true); loadStats(); }} style={{
            background: '#1e293b', border: '1px solid #334155', color: '#94a3b8',
            padding: '7px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 13,
          }}>🔄 Actualiser</button>
          <div style={{ color: '#475569', fontSize: 11, marginTop: 4 }}>
            Mis à jour : {lastRefresh.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit' })}
          </div>
        </div>
      </div>

      {/* Stats Cards */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(200px, 1fr))', gap: 16, marginBottom: 32 }}>
        {cards.map(card => (
          <div key={card.label}
            onClick={() => card.page && onNavigate(card.page)}
            style={{
              background: '#1e293b', borderRadius: 12, padding: 20,
              border: `1px solid ${card.color}33`,
              cursor: card.page ? 'pointer' : 'default',
              transition: 'transform 0.2s, box-shadow 0.2s',
              boxShadow: `0 4px 20px ${card.color}11`,
            }}
            onMouseEnter={e => card.page && ((e.currentTarget.style.transform = 'translateY(-2px)', e.currentTarget.style.boxShadow = `0 8px 30px ${card.color}22`))}
            onMouseLeave={e => card.page && ((e.currentTarget.style.transform = 'none', e.currentTarget.style.boxShadow = `0 4px 20px ${card.color}11`))}
          >
            <div style={{ fontSize: 28, marginBottom: 8 }}>{card.icon}</div>
            <div style={{ color: card.color, fontSize: 28, fontWeight: 800, lineHeight: 1 }}>{card.value.toLocaleString()}</div>
            <div style={{ color: '#94a3b8', fontSize: 13, marginTop: 6 }}>{card.label}</div>
          </div>
        ))}
      </div>

      {/* Quick Actions — SIMPLIFIÉES */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(230px, 1fr))', gap: 14, marginBottom: 32 }}>
        <QuickAction icon="💳" title="Valider paiements" desc={`${adminStats?.demandesEnAttente ?? 0} demande(s) en attente`} color={COLORS.gold} onClick={() => onNavigate('paiements')} />
        <QuickAction icon="📤" title="Importer des QCM" desc="Txt, Markdown ou PDF en masse" color={COLORS.blue} onClick={() => onNavigate('bulk-import')} />
        <QuickAction icon="🧩" title="Créer un examen" desc="Composer depuis plusieurs matières" color={COLORS.purple} onClick={() => onNavigate('exam-generator')} />
        <QuickAction icon="📢" title="Publier annonce" desc="Communiquer avec les utilisateurs" color={COLORS.green} onClick={() => onNavigate('annonces')} />
      </div>

      {/* Section Matières */}
      {stats?.matiere_stats?.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, marginBottom: 24, border: '1px solid #334155' }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 16 }}>📊 Questions par matière</h3>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            {stats.matiere_stats.map((m: any) => {
              const pct = stats.total_questions > 0 ? Math.round((m.nb_questions / stats.total_questions) * 100) : 0;
              return (
                <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                  <div style={{ width: 140, color: '#94a3b8', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>{m.nom}</div>
                  <div style={{ flex: 1, height: 6, background: '#334155', borderRadius: 3, overflow: 'hidden' }}>
                    <div style={{ height: '100%', background: COLORS.green, width: `${pct}%`, borderRadius: 3 }} />
                  </div>
                  <div style={{ color: '#64748b', fontSize: 12, width: 60, textAlign: 'right' }}>{m.nb_questions} Q</div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* Signalements récents */}
      {stats?.recent_flags?.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, marginBottom: 24, border: '1px solid rgba(239,68,68,0.3)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 16 }}>
            <h3 style={{ color: '#ef4444', fontSize: 16, fontWeight: 600 }}>🚨 Signalements récents</h3>
            <button onClick={() => onNavigate('flags')} style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', color: '#ef4444', padding: '4px 12px', borderRadius: 6, cursor: 'pointer', fontSize: 13 }}>
              Voir tous
            </button>
          </div>
          {stats.recent_flags.map((f: any) => (
            <div key={f.id} style={{ padding: '8px 0', borderBottom: '1px solid #334155', display: 'flex', gap: 12, alignItems: 'flex-start' }}>
              <span style={{ color: '#ef4444', fontSize: 14 }}>⚠️</span>
              <div>
                <div style={{ color: '#e2e8f0', fontSize: 13 }}>Q#{f.question_id?.substring(0, 8)}... — {f.reason}</div>
                <div style={{ color: '#64748b', fontSize: 12 }}>{new Date(f.created_at).toLocaleDateString('fr-FR')}</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Imports récents */}
      {stats?.recent_imports?.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, marginBottom: 24, border: '1px solid #334155' }}>
          <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 16 }}>📤 Derniers imports</h3>
          {stats.recent_imports.map((imp: any) => (
            <div key={imp.id} style={{ padding: '8px 0', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
              <div>
                <div style={{ color: '#e2e8f0', fontSize: 13 }}>{imp.filename ?? 'Import'}</div>
                <div style={{ color: '#64748b', fontSize: 12 }}>{new Date(imp.created_at).toLocaleDateString('fr-FR')}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
                <span style={{ color: '#4ade80', fontSize: 13 }}>{imp.imported_count} questions</span>
                <StatusBadge status={imp.status} />
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Migration */}
      <div style={{ background: '#1e293b', borderRadius: 12, padding: 20, border: '1px solid #334155' }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 600, marginBottom: 8 }}>🔧 Configuration CMS</h3>
        <p style={{ color: '#64748b', fontSize: 13, marginBottom: 16 }}>
          Vérifier et créer les tables CMS si nécessaire (première installation)
        </p>
        <button onClick={handleMigration} disabled={migrating} style={{
          padding: '8px 16px', background: migrating ? '#334155' : '#1A5C38',
          border: 'none', borderRadius: 8, color: 'white', cursor: migrating ? 'not-allowed' : 'pointer',
          fontSize: 14, fontWeight: 500,
        }}>
          {migrating ? '⏳ Vérification...' : '🔍 Vérifier les tables CMS'}
        </button>
        {migrationStatus && (
          <div style={{ marginTop: 12 }}>
            {migrationStatus.error ? (
              <div style={{ color: '#ef4444', fontSize: 13 }}>❌ {migrationStatus.error}</div>
            ) : (
              <div>
                <div style={{ color: '#4ade80', fontSize: 13, marginBottom: 8 }}>✅ Vérification terminée</div>
                <div style={{ background: '#0f172a', borderRadius: 8, padding: 12, fontSize: 12, fontFamily: 'monospace', color: '#94a3b8' }}>
                  {Object.entries(migrationStatus.tables_status ?? {}).map(([table, status]) => (
                    <div key={table}>{status === 'OK' ? '✅' : '❌'} {table}: {status as string}</div>
                  ))}
                </div>
                {migrationStatus.migration_sql && migrationStatus.tables_status && Object.values(migrationStatus.tables_status).some(s => s === 'MISSING') && (
                  <div style={{ marginTop: 12 }}>
                    <p style={{ color: '#D4A017', fontSize: 13, marginBottom: 8 }}>⚠️ Des tables manquent. Exécutez ce SQL dans Supabase Dashboard :</p>
                    <a href="https://supabase.com/dashboard/project/xqifdbgqxyrlhrkwlyir/sql/new" target="_blank"
                      style={{ color: '#3b82f6', fontSize: 13 }}>
                      → Ouvrir Supabase SQL Editor
                    </a>
                    <pre style={{ background: '#0f172a', borderRadius: 8, padding: 12, fontSize: 11, color: '#94a3b8', overflow: 'auto', maxHeight: 300, marginTop: 8 }}>
                      {migrationStatus.migration_sql}
                    </pre>
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

function QuickAction({ icon, title, desc, color, onClick }: any) {
  return (
    <button onClick={onClick} style={{
      background: '#1e293b', border: `1px solid ${color}33`,
      borderRadius: 12, padding: 20, cursor: 'pointer', textAlign: 'left',
      transition: 'all 0.2s', display: 'flex', alignItems: 'flex-start', gap: 14,
    }}
    onMouseEnter={e => { e.currentTarget.style.background = `${color}11`; e.currentTarget.style.borderColor = `${color}66`; }}
    onMouseLeave={e => { e.currentTarget.style.background = '#1e293b'; e.currentTarget.style.borderColor = `${color}33`; }}
    >
      <span style={{ fontSize: 24 }}>{icon}</span>
      <div>
        <div style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600 }}>{title}</div>
        <div style={{ color: '#64748b', fontSize: 13, marginTop: 2 }}>{desc}</div>
      </div>
    </button>
  );
}

function StatusBadge({ status }: { status: string }) {
  const colors: Record<string, any> = {
    success: { bg: 'rgba(74,222,128,0.1)', color: '#4ade80', label: '✅ Succès' },
    pending: { bg: 'rgba(251,191,36,0.1)', color: '#fbbf24', label: '⏳ En cours' },
    failed: { bg: 'rgba(239,68,68,0.1)', color: '#ef4444', label: '❌ Échoué' },
    partial_error: { bg: 'rgba(251,191,36,0.1)', color: '#fbbf24', label: '⚠️ Partiel' },
    cancelled: { bg: 'rgba(148,163,184,0.1)', color: '#94a3b8', label: '🚫 Annulé' },
  };
  const c = colors[status] ?? colors.pending;
  return (
    <span style={{ background: c.bg, color: c.color, padding: '2px 8px', borderRadius: 12, fontSize: 12 }}>
      {c.label}
    </span>
  );
}

function LoadingSpinner() {
  return (
    <div style={{ display: 'flex', justifyContent: 'center', alignItems: 'center', height: 300 }}>
      <div style={{
        width: 40, height: 40, border: '3px solid #334155',
        borderTop: '3px solid #1A5C38', borderRadius: '50%',
        animation: 'spin 1s linear infinite',
      }} />
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
