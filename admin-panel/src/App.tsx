import { useState, useEffect, createContext, useContext } from 'react';
import { getToken, clearToken } from './api';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import QuestionsPage from './pages/QuestionsPage';
import CreateQuestionPage from './pages/CreateQuestionPage';
import BulkImportPage from './pages/BulkImportPage';
import SeriesPage from './pages/SeriesPage';
import SimulationsPage from './pages/SimulationsPage';
import FlagsPage from './pages/FlagsPage';
import AuditLogPage from './pages/AuditLogPage';
import AnnoncesPage from './pages/AnnoncesPage';
import ExamGeneratorPage from './pages/ExamGeneratorPage';
import ChangePasswordPage from './pages/ChangePasswordPage';
import EntraidePage from './pages/EntraidePage';
import {
  LayoutDashboard, FileQuestion, Upload, BookOpen, Target,
  Flag, History, LogOut, Menu, X, Newspaper, Layers, KeyRound,
  CreditCard, MessageCircle
} from 'lucide-react';

// ── Context Auth ─────────────────────────────────────────────
interface AuthContextType { user: any; setUser: (u: any) => void; logout: () => void; }
const AuthContext = createContext<AuthContextType>({ user: null, setUser: () => {}, logout: () => {} });
export const useAuth = () => useContext(AuthContext);

export type Page =
  | 'dashboard' | 'questions' | 'create-question' | 'edit-question'
  | 'bulk-import' | 'series' | 'simulations' | 'flags' | 'audit-log'
  | 'annonces' | 'exam-generator' | 'change-password' | 'paiements' | 'entraide';

export default function App() {
  const [user, setUser] = useState<any>(() => {
    try { return JSON.parse(localStorage.getItem('admin_user') ?? 'null'); } catch { return null; }
  });
  const [currentPage, setCurrentPage] = useState<Page>('dashboard');
  const [editQuestionId, setEditQuestionId] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const logout = () => { clearToken(); setUser(null); };

  useEffect(() => { if (!getToken()) setUser(null); }, []);

  if (!user || !getToken()) {
    return (
      <AuthContext.Provider value={{ user, setUser, logout }}>
        <LoginPage onLogin={(u) => { setUser(u); localStorage.setItem('admin_user', JSON.stringify(u)); }} />
      </AuthContext.Provider>
    );
  }

  const navigate = (page: Page, questionId?: string) => {
    setCurrentPage(page);
    if (questionId) setEditQuestionId(questionId);
    if (window.innerWidth < 768) setSidebarOpen(false);
  };

  return (
    <AuthContext.Provider value={{ user, setUser, logout }}>
      <div style={{ display: 'flex', minHeight: '100vh', background: '#0f172a' }}>
        {sidebarOpen && window.innerWidth < 768 && (
          <div onClick={() => setSidebarOpen(false)}
            style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 40 }} />
        )}

        {/* Sidebar */}
        <div style={{
          position: 'fixed', left: sidebarOpen ? 0 : '-260px', top: 0, bottom: 0,
          width: 260, zIndex: 50, transition: 'left 0.3s ease',
          background: 'linear-gradient(180deg, #1e293b 0%, #0f172a 100%)',
          borderRight: '1px solid #334155', display: 'flex', flexDirection: 'column', overflowY: 'auto',
        }}>
          {/* Logo */}
          <div style={{ padding: '18px 16px', borderBottom: '1px solid #334155', flexShrink: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 42, height: 42, borderRadius: 10,
                background: 'linear-gradient(135deg, #1A5C38, #D4A017)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontWeight: 'bold', fontSize: 15, color: 'white', flexShrink: 0,
              }}>EF</div>
              <div>
                <div style={{ fontWeight: 700, color: '#f1f5f9', fontSize: 14 }}>EF-FORT.BF</div>
                <div style={{ color: '#64748b', fontSize: 11 }}>Panel Administration v8.0</div>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav style={{ flex: 1, padding: '10px 8px' }}>
            <NavItem icon={<LayoutDashboard size={18} />} label="Tableau de bord" active={currentPage === 'dashboard'} onClick={() => navigate('dashboard')} />

            <NavSection label="Paiements & Abonnements" />
            <NavItem icon={<CreditCard size={18} />} label="Valider les paiements" active={currentPage === 'paiements'} onClick={() => navigate('paiements')} badge="!" />

            <NavSection label="Contenu QCM" />
            <NavItem icon={<FileQuestion size={18} />} label="Gérer les Questions" active={currentPage === 'questions'} onClick={() => navigate('questions')} />
            <NavItem icon={<Upload size={18} />} label="Import QCM (txt/MD/PDF)" active={currentPage === 'bulk-import'} onClick={() => navigate('bulk-import')} />
            <NavItem icon={<BookOpen size={18} />} label="Séries & Matières" active={currentPage === 'series'} onClick={() => navigate('series')} />
            <NavItem icon={<Target size={18} />} label="Simulations & Examens" active={currentPage === 'simulations'} onClick={() => navigate('simulations')} />
            <NavItem icon={<Layers size={18} />} label="Générateur d'Examens" active={currentPage === 'exam-generator'} onClick={() => navigate('exam-generator')} />

            <NavSection label="Communication" />
            <NavItem icon={<Newspaper size={18} />} label="Publier une Annonce" active={currentPage === 'annonces'} onClick={() => navigate('annonces')} />
            <NavItem icon={<MessageCircle size={18} />} label="Entraide — Répondre" active={currentPage === 'entraide'} onClick={() => navigate('entraide')} />

            <NavSection label="Modération & Audit" />
            <NavItem icon={<Flag size={18} />} label="Signalements" active={currentPage === 'flags'} onClick={() => navigate('flags')} />
            <NavItem icon={<History size={18} />} label="Audit Log" active={currentPage === 'audit-log'} onClick={() => navigate('audit-log')} />

            <NavSection label="Compte" />
            <NavItem icon={<KeyRound size={18} />} label="Changer mot de passe" active={currentPage === 'change-password'} onClick={() => navigate('change-password')} />
          </nav>

          {/* User footer */}
          <div style={{ padding: 12, borderTop: '1px solid #334155', flexShrink: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 34, height: 34, borderRadius: '50%',
                background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'white', fontSize: 13, fontWeight: 700, flexShrink: 0,
              }}>{user?.prenom?.[0]?.toUpperCase() ?? 'A'}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#e2e8f0', fontSize: 13, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {user?.prenom} {user?.nom}
                </div>
                <div style={{ color: '#64748b', fontSize: 11 }}>Administrateur</div>
              </div>
              <button onClick={logout} title="Déconnexion" style={{ background: 'none', border: 'none', cursor: 'pointer', color: '#ef4444', padding: 4, borderRadius: 4, display: 'flex' }}>
                <LogOut size={16} />
              </button>
            </div>
          </div>
        </div>

        {/* Main Content */}
        <div style={{ flex: 1, marginLeft: sidebarOpen ? 260 : 0, transition: 'margin-left 0.3s ease', minWidth: 0 }}>
          {/* Top Bar */}
          <div style={{
            height: 56, background: '#1e293b', borderBottom: '1px solid #334155',
            display: 'flex', alignItems: 'center', padding: '0 16px', gap: 12,
            position: 'sticky', top: 0, zIndex: 30,
          }}>
            <button onClick={() => setSidebarOpen(!sidebarOpen)} style={{
              background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8',
              padding: 6, borderRadius: 6, display: 'flex', alignItems: 'center',
            }}>
              {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
            </button>
            <div style={{ flex: 1, color: '#94a3b8', fontSize: 13 }}>{getPageTitle(currentPage)}</div>
            <div style={{ color: '#4ade80', fontSize: 12, fontWeight: 600 }}>🟢 LIVE</div>
          </div>

          {/* Page Content */}
          <div style={{ padding: 24, maxWidth: 1400 }}>
            {currentPage === 'dashboard' && <DashboardPage onNavigate={navigate} />}
            {currentPage === 'paiements' && <PaiementsPage onNavigate={navigate} />}
            {currentPage === 'questions' && <QuestionsPage onNavigate={navigate} onEdit={(id) => { setEditQuestionId(id); navigate('edit-question'); }} />}
            {(currentPage === 'create-question' || currentPage === 'edit-question') && <CreateQuestionPage questionId={currentPage === 'edit-question' ? editQuestionId : null} onNavigate={navigate} />}
            {currentPage === 'bulk-import' && <BulkImportPage onNavigate={navigate} />}
            {currentPage === 'series' && <SeriesPage onNavigate={navigate} />}
            {currentPage === 'simulations' && <SimulationsPage onNavigate={navigate} />}
            {currentPage === 'exam-generator' && <ExamGeneratorPage onNavigate={navigate} />}
            {currentPage === 'flags' && <FlagsPage onNavigate={navigate} />}
            {currentPage === 'audit-log' && <AuditLogPage onNavigate={navigate} />}
            {currentPage === 'annonces' && <AnnoncesPage onNavigate={navigate} />}
            {currentPage === 'entraide' && <EntraidePage onNavigate={navigate} />}
            {currentPage === 'change-password' && <ChangePasswordPage onNavigate={navigate} />}
          </div>
        </div>
      </div>
    </AuthContext.Provider>
  );
}

function NavSection({ label }: { label: string }) {
  return <div style={{ color: '#475569', fontSize: 10, fontWeight: 700, padding: '10px 8px 3px', textTransform: 'uppercase', letterSpacing: '0.08em' }}>{label}</div>;
}

function NavItem({ icon, label, active, onClick, badge }: { icon: React.ReactNode; label: string; active: boolean; onClick: () => void; badge?: string }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 10,
      padding: '8px 12px', borderRadius: 8, border: 'none', cursor: 'pointer',
      background: active ? 'rgba(26,92,56,0.25)' : 'transparent',
      color: active ? '#4ade80' : '#94a3b8',
      fontSize: 13, fontWeight: active ? 600 : 400,
      transition: 'all 0.15s', marginBottom: 2,
      borderLeft: active ? '2px solid #1A5C38' : '2px solid transparent',
    }}
    onMouseEnter={e => { if (!active) (e.currentTarget as HTMLElement).style.background = 'rgba(255,255,255,0.05)'; }}
    onMouseLeave={e => { if (!active) (e.currentTarget as HTMLElement).style.background = 'transparent'; }}
    >
      {icon}
      <span style={{ flex: 1, textAlign: 'left' }}>{label}</span>
      {badge && <span style={{ background: '#ef4444', color: 'white', fontSize: 10, fontWeight: 700, width: 18, height: 18, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>{badge}</span>}
    </button>
  );
}

function getPageTitle(page: Page): string {
  const titles: Record<Page, string> = {
    'dashboard': '📊 Tableau de bord',
    'paiements': '💳 Validation des paiements',
    'questions': '❓ Gestion des questions QCM',
    'create-question': '✚ Créer une question',
    'edit-question': '✏️ Modifier la question',
    'bulk-import': '📤 Import QCM en masse (txt / MD / PDF)',
    'series': '📚 Séries & Matières',
    'simulations': '🎯 Simulations & Examens Types',
    'exam-generator': '🧩 Générateur d\'Examens Composites',
    'flags': '🚨 Signalements',
    'audit-log': '📜 Audit & Historique',
    'annonces': '📢 Publier une annonce',
    'entraide': '🤝 Entraide — Répondre aux Questions',
    'change-password': '🔑 Changer le mot de passe',
  };
  return titles[page] ?? 'Admin';
}

// ── Page Paiements (inline) ───────────────────────────────────
import { getAdminStats } from './api';
function PaiementsPage({ onNavigate: _n }: { onNavigate: (p: Page) => void }) {
  const [demandes, setDemandes] = useState<any[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<'EN_ATTENTE' | 'VALIDE' | 'TOUS'>('EN_ATTENTE');

  const BASE_URL = window.location.hostname === 'localhost'
    ? 'http://localhost:8787'
    : 'https://ef-fort-bf.yembuaro29.workers.dev';

  async function load() {
    setLoading(true);
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/admin/demandes-abonnement`, {
        headers: { Authorization: `Bearer ${token}` }
      });
      const d = await res.json();
      setDemandes(d.demandes ?? d ?? []);
    } catch { setDemandes([]); } finally { setLoading(false); }
  }

  async function valider(id: string) {
    const token = getToken();
    await fetch(`${BASE_URL}/api/admin/valider-abonnement/${id}`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ statut: 'VALIDE' }),
    });
    load();
  }

  async function rejeter(id: string) {
    const token = getToken();
    await fetch(`${BASE_URL}/api/admin/valider-abonnement/${id}`, {
      method: 'POST', headers: { Authorization: `Bearer ${token}`, 'Content-Type': 'application/json' },
      body: JSON.stringify({ statut: 'REJETE' }),
    });
    load();
  }

  useEffect(() => { load(); }, []);

  const filtered = filter === 'TOUS' ? demandes : demandes.filter(d => d.statut === filter);
  const enAttente = demandes.filter(d => d.statut === 'EN_ATTENTE').length;

  return (
    <div>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: 24 }}>
        <div>
          <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700, margin: 0 }}>💳 Validation des Paiements</h2>
          <p style={{ color: '#64748b', fontSize: 14, marginTop: 4 }}>
            {enAttente > 0 ? <span style={{ color: '#f59e0b' }}>⚠️ {enAttente} demande(s) en attente de validation</span> : '✅ Aucune demande en attente'}
          </p>
        </div>
        <button onClick={load} style={{ background: '#1A5C38', color: 'white', border: 'none', padding: '8px 16px', borderRadius: 8, cursor: 'pointer', fontWeight: 600 }}>
          🔄 Rafraîchir
        </button>
      </div>

      {/* Filtres */}
      <div style={{ display: 'flex', gap: 8, marginBottom: 20 }}>
        {(['EN_ATTENTE', 'VALIDE', 'TOUS'] as const).map(f => (
          <button key={f} onClick={() => setFilter(f)} style={{
            padding: '6px 16px', borderRadius: 20, border: 'none', cursor: 'pointer', fontWeight: 600, fontSize: 13,
            background: filter === f ? (f === 'EN_ATTENTE' ? '#f59e0b' : f === 'VALIDE' ? '#22c55e' : '#3b82f6') : '#1e293b',
            color: filter === f ? 'white' : '#64748b',
          }}>
            {f === 'EN_ATTENTE' ? '⏳ En attente' : f === 'VALIDE' ? '✅ Validés' : '📋 Tous'}
            {f === 'EN_ATTENTE' && enAttente > 0 && <span style={{ marginLeft: 6, background: '#ef4444', color: 'white', borderRadius: '50%', padding: '1px 6px', fontSize: 11 }}>{enAttente}</span>}
          </button>
        ))}
      </div>

      {loading ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#64748b' }}>Chargement...</div>
      ) : filtered.length === 0 ? (
        <div style={{ textAlign: 'center', padding: 60, color: '#64748b', background: '#1e293b', borderRadius: 12 }}>
          <div style={{ fontSize: 48, marginBottom: 16 }}>📭</div>
          <div>Aucune demande {filter !== 'TOUS' ? `avec statut "${filter}"` : ''}</div>
        </div>
      ) : (
        <div style={{ display: 'flex', flexDirection: 'column', gap: 12 }}>
          {filtered.map((d: any) => (
            <div key={d.id} style={{
              background: '#1e293b', borderRadius: 12, padding: '16px 20px',
              border: d.statut === 'EN_ATTENTE' ? '1px solid #f59e0b44' : '1px solid #334155',
              display: 'flex', alignItems: 'center', gap: 16, flexWrap: 'wrap',
            }}>
              <div style={{
                width: 44, height: 44, borderRadius: '50%', flexShrink: 0,
                background: d.statut === 'EN_ATTENTE' ? 'rgba(245,158,11,0.15)' : 'rgba(34,197,94,0.15)',
                display: 'flex', alignItems: 'center', justifyContent: 'center', fontSize: 20,
              }}>
                {d.statut === 'EN_ATTENTE' ? '⏳' : '✅'}
              </div>
              <div style={{ flex: 1, minWidth: 200 }}>
                <div style={{ color: '#f1f5f9', fontWeight: 700, fontSize: 15 }}>{d.nom_complet ?? `${d.prenom ?? ''} ${d.nom ?? ''}`}</div>
                <div style={{ color: '#94a3b8', fontSize: 13, marginTop: 2 }}>📞 {d.telephone}</div>
                <div style={{ color: '#64748b', fontSize: 12, marginTop: 2 }}>
                  💳 {d.moyen_paiement} · {d.created_at ? new Date(d.created_at).toLocaleDateString('fr-FR', { day: '2-digit', month: '2-digit', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : ''}
                </div>
              </div>
              <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
                <span style={{
                  padding: '4px 12px', borderRadius: 20, fontSize: 12, fontWeight: 700,
                  background: d.statut === 'EN_ATTENTE' ? 'rgba(245,158,11,0.2)' : d.statut === 'VALIDE' ? 'rgba(34,197,94,0.2)' : 'rgba(239,68,68,0.2)',
                  color: d.statut === 'EN_ATTENTE' ? '#f59e0b' : d.statut === 'VALIDE' ? '#22c55e' : '#ef4444',
                }}>
                  {d.statut}
                </span>
                {d.statut === 'EN_ATTENTE' && (
                  <>
                    <button onClick={() => valider(d.id)} style={{
                      background: '#22c55e', color: 'white', border: 'none', padding: '7px 16px',
                      borderRadius: 8, cursor: 'pointer', fontWeight: 700, fontSize: 13,
                    }}>✅ Valider</button>
                    <button onClick={() => rejeter(d.id)} style={{
                      background: '#ef4444', color: 'white', border: 'none', padding: '7px 14px',
                      borderRadius: 8, cursor: 'pointer', fontWeight: 700, fontSize: 13,
                    }}>❌ Rejeter</button>
                  </>
                )}
              </div>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
