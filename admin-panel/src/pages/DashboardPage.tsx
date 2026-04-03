import { useState, useEffect } from 'react';
import { getDashboard, runMigration, getAdminStats } from '../api';
import type { Page } from '../App';

const COLORS = {
  green: '#1A5C38', gold: '#D4A017', blue: '#3b82f6',
  red: '#ef4444', purple: '#8b5cf6', cyan: '#06b6d4', orange: '#f59e0b',
};

// ══════════════════════════════════════════════════════════════
// DASHBOARD PAGE v9.0 — Stats fusionnées + Temps réel + Quick Actions
// ══════════════════════════════════════════════════════════════

export default function DashboardPage({ onNavigate }: { onNavigate: (page: Page) => void }) {
  const [stats, setStats] = useState<any>(null);
  const [adminStats, setAdminStats] = useState<any>(null);
  const [loading, setLoading] = useState(true);
  const [migrationStatus, setMigrationStatus] = useState<any>(null);
  const [migrating, setMigrating] = useState(false);
  const [lastRefresh, setLastRefresh] = useState<Date>(new Date());
  const [refreshing, setRefreshing] = useState(false);

  useEffect(() => { loadStats(); }, []);

  // Auto-refresh toutes les 30 secondes
  useEffect(() => {
    const interval = setInterval(() => {
      loadStats(false);
      setLastRefresh(new Date());
    }, 30000);
    return () => clearInterval(interval);
  }, []);

  async function loadStats(showLoader = true) {
    if (showLoader) setLoading(true);
    else setRefreshing(true);
    try {
      const [cmsData, adminData] = await Promise.allSettled([getDashboard(), getAdminStats()]);
      if (cmsData.status === 'fulfilled') setStats(cmsData.value.stats);
      if (adminData.status === 'fulfilled') setAdminStats(adminData.value.stats ?? adminData.value);
    } catch (err: any) {
      console.error(err);
    } finally {
      setLoading(false);
      setRefreshing(false);
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

  const totalUsers = stats?.total_users ?? adminStats?.totalUsers ?? adminStats?.total_users ?? 0;
  const abonnes = adminStats?.abonnes ?? adminStats?.total_abonnes ?? 0;
  const totalQuestions = stats?.total_questions ?? adminStats?.totalQuestions ?? 0;
  const totalSimulations = stats?.total_simulations_played ?? adminStats?.totalSimulations ?? 0;
  const demandesEnAttente = adminStats?.demandesEnAttente ?? adminStats?.demandes_en_attente ?? 0;
  const pendingFlags = stats?.pending_flags ?? 0;

  const cards = [
    {
      label: 'Utilisateurs inscrits',
      value: totalUsers,
      icon: '👥',
      color: COLORS.blue,
      page: null,
      trend: '+',
      sub: `${abonnes} abonné(s) actif(s)`,
    },
    {
      label: 'Abonnés actifs',
      value: abonnes,
      icon: '⭐',
      color: COLORS.gold,
      page: 'paiements' as Page,
      trend: null,
      sub: `${totalUsers > 0 ? Math.round((abonnes / totalUsers) * 100) : 0}% des inscrits`,
    },
    {
      label: 'Questions publiées',
      value: totalQuestions,
      icon: '📚',
      color: COLORS.green,
      page: 'questions' as Page,
      trend: null,
      sub: `${stats?.matiere_stats?.length ?? 0} matière(s)`,
    },
    {
      label: 'Simulations jouées',
      value: totalSimulations,
      icon: '🎯',
      color: COLORS.purple,
      page: null,
      trend: null,
      sub: 'Total cumulé',
    },
    {
      label: 'Paiements en attente',
      value: demandesEnAttente,
      icon: '💳',
      color: demandesEnAttente > 0 ? COLORS.red : '#334155',
      page: 'paiements' as Page,
      trend: demandesEnAttente > 0 ? '!' : null,
      sub: demandesEnAttente > 0 ? 'Action requise' : 'Aucune demande',
    },
    {
      label: 'Signalements actifs',
      value: pendingFlags,
      icon: '🚨',
      color: pendingFlags > 0 ? COLORS.red : '#334155',
      page: 'flags' as Page,
      trend: pendingFlags > 0 ? '!' : null,
      sub: pendingFlags > 0 ? 'À traiter' : 'Aucun signalement',
    },
  ];

  const tauxConversion = totalUsers > 0 ? ((abonnes / totalUsers) * 100).toFixed(1) : '0';
  const revenuEstime = abonnes * 12000;

  return (
    <div>
      {/* Header */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start', marginBottom: 28 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 24, fontWeight: 700, margin: 0 }}>
            📊 Tableau de bord
          </h2>
          <p style={{ color: '#64748b', fontSize: 14, marginTop: 6 }}>
            Vue consolidée EF-FORT.BF — Données temps réel
          </p>
        </div>
        <div style={{ display: 'flex', gap: 10, alignItems: 'center' }}>
          <div style={{ textAlign: 'right' }}>
            <div style={{ color: refreshing ? '#D4A017' : '#475569', fontSize: 11, marginBottom: 2 }}>
              {refreshing ? '🔄 Actualisation...' : `⏱ ${lastRefresh.toLocaleTimeString('fr-FR', { hour: '2-digit', minute: '2-digit', second: '2-digit' })}`}
            </div>
            <div style={{ color: '#334155', fontSize: 10 }}>Auto-refresh 30s</div>
          </div>
          <button
            onClick={() => { setLoading(true); loadStats(); setLastRefresh(new Date()); }}
            style={{
              background: '#1e293b', border: '1px solid #334155', color: '#94a3b8',
              padding: '8px 14px', borderRadius: 8, cursor: 'pointer', fontSize: 13,
              display: 'flex', alignItems: 'center', gap: 6,
            }}
          >
            🔄 Actualiser
          </button>
        </div>
      </div>

      {/* ── KPI Cards ───────────────────────────────────────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(210px, 1fr))', gap: 16, marginBottom: 32 }}>
        {cards.map(card => (
          <div
            key={card.label}
            onClick={() => card.page && onNavigate(card.page)}
            style={{
              background: '#1e293b', borderRadius: 14, padding: 20,
              border: `1px solid ${card.color}33`,
              cursor: card.page ? 'pointer' : 'default',
              transition: 'transform 0.2s, box-shadow 0.2s',
              boxShadow: `0 4px 20px ${card.color}11`,
              position: 'relative', overflow: 'hidden',
            }}
            onMouseEnter={e => card.page && (
              (e.currentTarget.style.transform = 'translateY(-3px)'),
              (e.currentTarget.style.boxShadow = `0 8px 30px ${card.color}33`)
            )}
            onMouseLeave={e => card.page && (
              (e.currentTarget.style.transform = 'none'),
              (e.currentTarget.style.boxShadow = `0 4px 20px ${card.color}11`)
            )}
          >
            {/* Badge urgent */}
            {card.trend === '!' && (
              <div style={{
                position: 'absolute', top: 12, right: 12,
                background: COLORS.red, color: 'white', borderRadius: '50%',
                width: 22, height: 22, display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontSize: 12, fontWeight: 900, animation: 'pulse 1.5s ease-in-out infinite',
              }}>!</div>
            )}
            <div style={{ fontSize: 30, marginBottom: 10 }}>{card.icon}</div>
            <div style={{ color: card.color, fontSize: 30, fontWeight: 800, lineHeight: 1 }}>
              {card.value.toLocaleString('fr-FR')}
            </div>
            <div style={{ color: '#e2e8f0', fontSize: 13, fontWeight: 600, marginTop: 6 }}>{card.label}</div>
            <div style={{ color: '#475569', fontSize: 11, marginTop: 4 }}>{card.sub}</div>
            {card.page && (
              <div style={{ color: card.color, fontSize: 11, marginTop: 8, opacity: 0.7 }}>
                → Cliquer pour accéder
              </div>
            )}
          </div>
        ))}
      </div>

      {/* ── Métriques avancées ─────────────────────────────────── */}
      <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(280px, 1fr))', gap: 16, marginBottom: 32 }}>
        {/* Conversion */}
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, border: '1px solid #334155' }}>
          <div style={{ color: '#64748b', fontSize: 12, fontWeight: 600, textTransform: 'uppercase', marginBottom: 14 }}>
            📈 Taux de conversion
          </div>
          <div style={{ display: 'flex', alignItems: 'baseline', gap: 6 }}>
            <div style={{ color: '#D4A017', fontSize: 36, fontWeight: 800 }}>{tauxConversion}%</div>
            <div style={{ color: '#64748b', fontSize: 13 }}>inscrits → abonnés</div>
          </div>
          <div style={{ marginTop: 12, height: 6, background: '#334155', borderRadius: 3, overflow: 'hidden' }}>
            <div style={{
              height: '100%', background: 'linear-gradient(90deg, #D4A017, #f59e0b)',
              width: `${Math.min(parseFloat(tauxConversion), 100)}%`, borderRadius: 3, transition: 'width 1s ease',
            }} />
          </div>
          <div style={{ color: '#475569', fontSize: 11, marginTop: 6 }}>
            {totalUsers - abonnes} utilisateurs non abonnés
          </div>
        </div>

        {/* Revenus estimés */}
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, border: '1px solid rgba(26,92,56,0.4)' }}>
          <div style={{ color: '#64748b', fontSize: 12, fontWeight: 600, textTransform: 'uppercase', marginBottom: 14 }}>
            💰 Revenus estimés
          </div>
          <div style={{ color: '#4ade80', fontSize: 28, fontWeight: 800 }}>
            {revenuEstime.toLocaleString('fr-FR')} FCFA
          </div>
          <div style={{ color: '#64748b', fontSize: 12, marginTop: 6 }}>
            {abonnes} × 12 000 FCFA
          </div>
          <div style={{ marginTop: 10, padding: '6px 10px', background: 'rgba(26,92,56,0.15)', borderRadius: 6, fontSize: 12, color: '#4ade80' }}>
            Accès illimité jusqu'au 31/12/2028
          </div>
        </div>

        {/* État du contenu */}
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, border: '1px solid #334155' }}>
          <div style={{ color: '#64748b', fontSize: 12, fontWeight: 600, textTransform: 'uppercase', marginBottom: 14 }}>
            📚 État du contenu
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8 }}>
            <ContentStat label="Questions publiées" value={totalQuestions} color="#4ade80" />
            <ContentStat label="Séries créées" value={stats?.total_series ?? '—'} color="#3b82f6" />
            <ContentStat label="Simulations" value={stats?.total_simulations ?? '—'} color="#8b5cf6" />
            <ContentStat label="Examens types" value={stats?.total_examens_types ?? '—'} color="#D4A017" />
          </div>
        </div>
      </div>

      {/* ── Quick Actions — PRIORITAIRES ────────────────────────── */}
      <div style={{ marginBottom: 28 }}>
        <div style={{ color: '#94a3b8', fontSize: 12, fontWeight: 700, textTransform: 'uppercase', letterSpacing: '0.08em', marginBottom: 14 }}>
          ⚡ Actions rapides
        </div>
        <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(240px, 1fr))', gap: 12 }}>
          <QuickAction
            icon="💳" title="Valider paiements"
            desc={demandesEnAttente > 0 ? `⚠️ ${demandesEnAttente} demande(s) urgente(s)` : '✅ Tout est traité'}
            color={demandesEnAttente > 0 ? COLORS.orange : COLORS.green}
            urgent={demandesEnAttente > 0}
            onClick={() => onNavigate('paiements')}
          />
          <QuickAction
            icon="📤" title="Importer des QCM"
            desc="TXT, Markdown, CSV ou PDF"
            color={COLORS.blue}
            onClick={() => onNavigate('bulk-import')}
          />
          <QuickAction
            icon="🧩" title="Générateur d'Examen"
            desc="Composer depuis plusieurs matières"
            color={COLORS.purple}
            onClick={() => onNavigate('exam-generator')}
          />
          <QuickAction
            icon="📢" title="Publier une Annonce"
            desc="Communiquer avec les candidats"
            color={COLORS.green}
            onClick={() => onNavigate('annonces')}
          />
          <QuickAction
            icon="❓" title="Gérer les Questions"
            desc="Modifier, supprimer, filtrer"
            color="#06b6d4"
            onClick={() => onNavigate('questions')}
          />
          <QuickAction
            icon="🎯" title="Simulations & Examens"
            desc="Publier ou masquer un examen"
            color="#7c3aed"
            onClick={() => onNavigate('simulations')}
          />
        </div>
      </div>

      {/* ── Répartition par matière ────────────────────────────── */}
      {stats?.matiere_stats?.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 24, marginBottom: 24, border: '1px solid #334155' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 18 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 16, fontWeight: 700, margin: 0 }}>
              📊 Questions par matière
            </h3>
            <button onClick={() => onNavigate('series')} style={{
              background: 'rgba(26,92,56,0.2)', border: '1px solid rgba(26,92,56,0.4)',
              color: '#4ade80', padding: '5px 12px', borderRadius: 6, cursor: 'pointer', fontSize: 12, fontWeight: 600,
            }}>
              Gérer les séries →
            </button>
          </div>
          <div style={{ display: 'grid', gridTemplateColumns: 'repeat(auto-fill, minmax(300px, 1fr))', gap: 10 }}>
            {stats.matiere_stats.map((m: any) => {
              const pct = totalQuestions > 0 ? Math.round((m.nb_questions / totalQuestions) * 100) : 0;
              return (
                <div key={m.id} style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
                  <div style={{ width: 160, color: '#94a3b8', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap', flexShrink: 0 }}>
                    {m.icone ?? '📚'} {m.nom}
                  </div>
                  <div style={{ flex: 1, height: 8, background: '#334155', borderRadius: 4, overflow: 'hidden' }}>
                    <div style={{
                      height: '100%',
                      background: `linear-gradient(90deg, ${COLORS.green}, #2d9966)`,
                      width: `${pct}%`, borderRadius: 4,
                      transition: 'width 0.8s ease',
                    }} />
                  </div>
                  <div style={{ color: '#4ade80', fontSize: 12, fontWeight: 700, width: 50, textAlign: 'right', flexShrink: 0 }}>
                    {m.nb_questions}
                  </div>
                </div>
              );
            })}
          </div>
        </div>
      )}

      {/* ── Signalements récents ──────────────────────────────── */}
      {stats?.recent_flags?.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, marginBottom: 24, border: '1px solid rgba(239,68,68,0.3)' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <h3 style={{ color: '#ef4444', fontSize: 15, fontWeight: 700, margin: 0 }}>🚨 Signalements récents</h3>
            <button onClick={() => onNavigate('flags')} style={{
              background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
              color: '#ef4444', padding: '5px 12px', borderRadius: 6, cursor: 'pointer', fontSize: 12, fontWeight: 600,
            }}>
              Voir tous ({pendingFlags}) →
            </button>
          </div>
          {stats.recent_flags.slice(0, 5).map((f: any) => (
            <div key={f.id} style={{ padding: '8px 0', borderBottom: '1px solid #1e293b', display: 'flex', gap: 12, alignItems: 'flex-start' }}>
              <span style={{ color: '#ef4444', fontSize: 14, flexShrink: 0 }}>⚠️</span>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#e2e8f0', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  Q#{f.question_id?.substring(0, 8)} — {f.reason}
                </div>
                <div style={{ color: '#64748b', fontSize: 11 }}>{new Date(f.created_at).toLocaleDateString('fr-FR')}</div>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Derniers imports ──────────────────────────────────── */}
      {stats?.recent_imports?.length > 0 && (
        <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, marginBottom: 24, border: '1px solid #334155' }}>
          <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 14 }}>
            <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 700, margin: 0 }}>📤 Derniers imports QCM</h3>
            <button onClick={() => onNavigate('bulk-import')} style={{
              background: 'rgba(59,130,246,0.15)', border: '1px solid rgba(59,130,246,0.4)',
              color: '#3b82f6', padding: '5px 12px', borderRadius: 6, cursor: 'pointer', fontSize: 12, fontWeight: 600,
            }}>
              Nouvel import →
            </button>
          </div>
          {stats.recent_imports.map((imp: any) => (
            <div key={imp.id} style={{ padding: '8px 0', borderBottom: '1px solid #334155', display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 12 }}>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#e2e8f0', fontSize: 13, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  📄 {imp.filename ?? 'Import'}
                </div>
                <div style={{ color: '#64748b', fontSize: 11 }}>{new Date(imp.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric' })}</div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 10, flexShrink: 0 }}>
                <span style={{ color: '#4ade80', fontSize: 13, fontWeight: 700 }}>{imp.imported_count} Q</span>
                <StatusBadge status={imp.status} />
              </div>
            </div>
          ))}
        </div>
      )}

      {/* ── Vérification CMS ──────────────────────────────────── */}
      <div style={{ background: '#1e293b', borderRadius: 14, padding: 20, border: '1px solid #334155' }}>
        <h3 style={{ color: '#f1f5f9', fontSize: 15, fontWeight: 600, marginBottom: 8 }}>🔧 Vérification des Tables CMS</h3>
        <p style={{ color: '#64748b', fontSize: 13, marginBottom: 14 }}>
          Vérifier et créer les tables CMS si nécessaire (première installation ou mise à jour)
        </p>
        <button
          onClick={handleMigration}
          disabled={migrating}
          style={{
            padding: '8px 16px',
            background: migrating ? '#334155' : '#1A5C38',
            border: 'none', borderRadius: 8, color: 'white',
            cursor: migrating ? 'not-allowed' : 'pointer',
            fontSize: 14, fontWeight: 500,
          }}
        >
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
              </div>
            )}
          </div>
        )}
      </div>

      <style>{`
        @keyframes pulse {
          0%, 100% { transform: scale(1); opacity: 1; }
          50% { transform: scale(1.1); opacity: 0.8; }
        }
      `}</style>
    </div>
  );
}

function ContentStat({ label, value, color }: { label: string; value: any; color: string }) {
  return (
    <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
      <span style={{ color: '#94a3b8', fontSize: 13 }}>{label}</span>
      <span style={{ color, fontSize: 15, fontWeight: 700 }}>{typeof value === 'number' ? value.toLocaleString('fr-FR') : value}</span>
    </div>
  );
}

function QuickAction({ icon, title, desc, color, onClick, urgent }: any) {
  return (
    <button
      onClick={onClick}
      style={{
        background: '#1e293b',
        border: `1px solid ${urgent ? color + '66' : color + '33'}`,
        borderRadius: 12, padding: '16px 18px', cursor: 'pointer', textAlign: 'left',
        transition: 'all 0.2s', display: 'flex', alignItems: 'flex-start', gap: 12,
        boxShadow: urgent ? `0 0 15px ${color}22` : 'none',
      }}
      onMouseEnter={e => {
        e.currentTarget.style.background = `${color}11`;
        e.currentTarget.style.borderColor = `${color}66`;
        e.currentTarget.style.transform = 'translateY(-2px)';
      }}
      onMouseLeave={e => {
        e.currentTarget.style.background = '#1e293b';
        e.currentTarget.style.borderColor = urgent ? `${color}66` : `${color}33`;
        e.currentTarget.style.transform = 'none';
      }}
    >
      <span style={{ fontSize: 22 }}>{icon}</span>
      <div>
        <div style={{ color: '#f1f5f9', fontSize: 14, fontWeight: 600 }}>{title}</div>
        <div style={{ color: urgent ? color : '#64748b', fontSize: 12, marginTop: 3 }}>{desc}</div>
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
    <span style={{ background: c.bg, color: c.color, padding: '2px 8px', borderRadius: 12, fontSize: 11, fontWeight: 600 }}>
      {c.label}
    </span>
  );
}

function LoadingSpinner() {
  return (
    <div style={{ display: 'flex', flexDirection: 'column', justifyContent: 'center', alignItems: 'center', height: 400, gap: 16 }}>
      <div style={{
        width: 48, height: 48, border: '3px solid #334155',
        borderTop: '3px solid #1A5C38', borderRadius: '50%',
        animation: 'spin 1s linear infinite',
      }} />
      <div style={{ color: '#64748b', fontSize: 13 }}>Chargement des statistiques...</div>
      <style>{`@keyframes spin { to { transform: rotate(360deg); } }`}</style>
    </div>
  );
}
