import { useState, useEffect, createContext, useContext } from 'react';
import { getToken, clearToken } from './api';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import MatieresPage from './pages/MatieresPage';
import ExamensTypesPage from './pages/ExamensTypesPage';
import ImportExportPage from './pages/ImportExportPage';
import PaiementsPage from './pages/PaiementsPage';
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
  LayoutDashboard, BookOpen, Target, Upload,
  FileQuestion, Flag, History, LogOut, Menu, X,
  Newspaper, Layers, KeyRound, CreditCard, MessageCircle, Shield,
  FileUp, ArrowUpDown
} from 'lucide-react';

// ── Context Auth ─────────────────────────────────────────────
interface AuthContextType { user: any; setUser: (u: any) => void; logout: () => void; }
const AuthContext = createContext<AuthContextType>({ user: null, setUser: () => {}, logout: () => {} });
export const useAuth = () => useContext(AuthContext);

export type Page =
  | 'dashboard'
  | 'matieres'
  | 'examens-types'
  | 'import-export'
  | 'paiements'
  | 'annonces'
  | 'entraide'
  | 'flags'
  | 'audit-log'
  // Pages héritées (accessibles via navigation avancée)
  | 'questions' | 'create-question' | 'edit-question'
  | 'bulk-import' | 'series' | 'simulations' | 'exam-generator'
  | 'change-password';

export default function App() {
  const [user, setUser] = useState<any>(() => {
    try { return JSON.parse(localStorage.getItem('admin_user') ?? 'null'); } catch { return null; }
  });
  const [currentPage, setCurrentPage] = useState<Page>('dashboard');
  const [editQuestionId, setEditQuestionId] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);
  const [lastActivity, setLastActivity] = useState(Date.now());

  const logout = () => {
    clearToken();
    localStorage.removeItem('admin_user');
    setUser(null);
  };

  useEffect(() => { if (!getToken()) setUser(null); }, []);

  // Auto-logout après 2h d'inactivité
  useEffect(() => {
    const TIMEOUT = 2 * 60 * 60 * 1000; // 2h
    const handler = () => setLastActivity(Date.now());
    window.addEventListener('mousemove', handler);
    window.addEventListener('keydown', handler);
    window.addEventListener('click', handler);
    const check = setInterval(() => {
      if (Date.now() - lastActivity > TIMEOUT) logout();
    }, 60000);
    return () => {
      window.removeEventListener('mousemove', handler);
      window.removeEventListener('keydown', handler);
      window.removeEventListener('click', handler);
      clearInterval(check);
    };
  }, [lastActivity]);

  // Page de connexion
  if (!user || !getToken() || !user.is_admin) {
    return (
      <AuthContext.Provider value={{ user, setUser, logout }}>
        <LoginPage onLogin={(u) => {
          if (!u.is_admin) { clearToken(); return; }
          setUser(u);
          localStorage.setItem('admin_user', JSON.stringify(u));
        }} />
      </AuthContext.Provider>
    );
  }

  const navigate = (page: Page, questionId?: string) => {
    setCurrentPage(page);
    if (questionId) setEditQuestionId(questionId);
    if (window.innerWidth < 768) setSidebarOpen(false);
  };

  // ── Navigation principale (onglets demandés) ────────────────
  const mainNav = [
    { page: 'dashboard' as Page, icon: <LayoutDashboard size={17} />, label: 'Tableau de bord', section: null },
    // Séparateur
    { page: 'matieres' as Page, icon: <BookOpen size={17} />, label: 'Matières & QCM', section: 'Contenu pédagogique' },
    { page: 'examens-types' as Page, icon: <Target size={17} />, label: 'Examens Types', section: null },
    { page: 'import-export' as Page, icon: <ArrowUpDown size={17} />, label: 'Import / Export', section: null },
    // Séparateur
    { page: 'paiements' as Page, icon: <CreditCard size={17} />, label: 'Paiements', section: 'Communauté', badge: true },
    { page: 'annonces' as Page, icon: <Newspaper size={17} />, label: 'Annonces', section: null },
    { page: 'entraide' as Page, icon: <MessageCircle size={17} />, label: 'Modération Entraide', section: null },
    // Séparateur
    { page: 'flags' as Page, icon: <Flag size={17} />, label: 'Signalements', section: 'Sécurité' },
    { page: 'audit-log' as Page, icon: <History size={17} />, label: 'Logs des actions', section: null },
    // Séparateur
    { page: 'questions' as Page, icon: <FileQuestion size={17} />, label: 'Toutes les questions', section: 'Outils avancés' },
    { page: 'bulk-import' as Page, icon: <Upload size={17} />, label: 'Import QCM avancé', section: null },
    { page: 'series' as Page, icon: <Layers size={17} />, label: 'Séries avancées', section: null },
    { page: 'simulations' as Page, icon: <Target size={17} />, label: 'Simulations', section: null },
    { page: 'exam-generator' as Page, icon: <FileUp size={17} />, label: 'Générateur d\'examens', section: null },
    // Compte
    { page: 'change-password' as Page, icon: <KeyRound size={17} />, label: 'Changer mot de passe', section: 'Compte' },
  ];

  return (
    <AuthContext.Provider value={{ user, setUser, logout }}>
      <div style={{ display: 'flex', minHeight: '100vh', background: '#0f172a' }}>
        {/* Overlay mobile */}
        {sidebarOpen && window.innerWidth < 768 && (
          <div onClick={() => setSidebarOpen(false)}
            style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 40 }} />
        )}

        {/* ════════════════ SIDEBAR ══════════════════════════ */}
        <div style={{
          position: 'fixed', left: sidebarOpen ? 0 : '-260px', top: 0, bottom: 0,
          width: 260, zIndex: 50, transition: 'left 0.3s ease',
          background: 'linear-gradient(180deg, #1e293b 0%, #0f172a 100%)',
          borderRight: '1px solid #334155', display: 'flex', flexDirection: 'column', overflowY: 'auto',
        }}>
          {/* Logo */}
          <div style={{ padding: '16px 14px', borderBottom: '1px solid #334155', flexShrink: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10,
                background: 'linear-gradient(135deg, #1A5C38, #D4A017)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontWeight: 'bold', fontSize: 17, color: 'white', flexShrink: 0,
              }}>EF</div>
              <div>
                <div style={{ fontWeight: 700, color: '#f1f5f9', fontSize: 17 }}>EF-FORT.BF</div>
                <div style={{ color: '#4ade80', fontSize: 14, fontWeight: 600 }}>🔐 Panel Admin CMS</div>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav style={{ flex: 1, padding: '8px 6px', overflowY: 'auto' }}>
            {(() => {
              let lastSection: string | null = undefined as any;
              return mainNav.map((item, idx) => {
                const sectionChanged = item.section !== undefined && item.section !== lastSection;
                if (sectionChanged) lastSection = item.section;
                return (
                  <div key={item.page + idx}>
                    {sectionChanged && item.section && (
                      <div style={{ color: '#475569', fontSize: 13, fontWeight: 700, padding: '12px 8px 4px', textTransform: 'uppercase', letterSpacing: '0.08em' }}>
                        {item.section}
                      </div>
                    )}
                    <NavItem
                      icon={item.icon}
                      label={item.label}
                      active={currentPage === item.page}
                      onClick={() => navigate(item.page)}
                      badge={item.badge}
                    />
                  </div>
                );
              });
            })()}
          </nav>

          {/* User footer */}
          <div style={{ padding: 12, borderTop: '1px solid #334155', flexShrink: 0 }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 34, height: 34, borderRadius: '50%',
                background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'white', fontSize: 16, fontWeight: 700, flexShrink: 0,
              }}>{user?.prenom?.[0]?.toUpperCase() ?? 'A'}</div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#e2e8f0', fontSize: 17, fontWeight: 600, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                  {user?.prenom} {user?.nom}
                </div>
                <div style={{ color: '#4ade80', fontSize: 14, display: 'flex', alignItems: 'center', gap: 3 }}>
                  <Shield size={9} /> Administrateur
                </div>
              </div>
              <button onClick={logout} title="Déconnexion" style={{
                background: 'none', border: 'none', cursor: 'pointer',
                color: '#ef4444', padding: 6, borderRadius: 6, display: 'flex',
              }}>
                <LogOut size={16} />
              </button>
            </div>
          </div>
        </div>

        {/* ════════════════ MAIN ═════════════════════════════ */}
        <div style={{ flex: 1, marginLeft: sidebarOpen ? 260 : 0, transition: 'margin-left 0.3s ease', minWidth: 0 }}>
          {/* Top Bar */}
          <div style={{
            height: 54, background: '#1e293b', borderBottom: '1px solid #334155',
            display: 'flex', alignItems: 'center', padding: '0 16px', gap: 12,
            position: 'sticky', top: 0, zIndex: 30,
          }}>
            <button onClick={() => setSidebarOpen(!sidebarOpen)} style={{
              background: 'none', border: 'none', cursor: 'pointer', color: '#94a3b8',
              padding: 6, borderRadius: 6, display: 'flex', alignItems: 'center',
            }}>
              {sidebarOpen ? <X size={20} /> : <Menu size={20} />}
            </button>

            <div style={{ flex: 1, color: '#94a3b8', fontSize: 17 }}>{getPageTitle(currentPage)}</div>

            {/* Badges top */}
            <div style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
              <div style={{
                background: '#065f46', color: '#4ade80', fontSize: 14, fontWeight: 700,
                padding: '3px 10px', borderRadius: 20, display: 'flex', alignItems: 'center', gap: 4,
              }}>
                <Shield size={11} /> SÉCURISÉ
              </div>
            </div>
          </div>

          {/* ═══ Pages ════════════════════════════════════════ */}
          <div style={{ padding: 24, maxWidth: 1500 }}>
            {currentPage === 'dashboard'     && <DashboardPage onNavigate={navigate} />}
            {currentPage === 'matieres'      && <MatieresPage onNavigate={navigate} />}
            {currentPage === 'examens-types' && <ExamensTypesPage onNavigate={navigate} />}
            {currentPage === 'import-export' && <ImportExportPage onNavigate={navigate} />}
            {currentPage === 'paiements'     && <PaiementsPage onNavigate={navigate} />}
            {currentPage === 'annonces'      && <AnnoncesPage onNavigate={navigate} />}
            {currentPage === 'entraide'      && <EntraidePage onNavigate={navigate} />}
            {currentPage === 'flags'         && <FlagsPage onNavigate={navigate} />}
            {currentPage === 'audit-log'     && <AuditLogPage onNavigate={navigate} />}
            {/* Outils avancés */}
            {currentPage === 'questions'     && <QuestionsPage onNavigate={navigate} onEdit={(id) => { setEditQuestionId(id); navigate('edit-question'); }} />}
            {(currentPage === 'create-question' || currentPage === 'edit-question') && (
              <CreateQuestionPage questionId={currentPage === 'edit-question' ? editQuestionId : null} onNavigate={navigate} />
            )}
            {currentPage === 'bulk-import'   && <BulkImportPage onNavigate={navigate} />}
            {currentPage === 'series'        && <SeriesPage onNavigate={navigate} />}
            {currentPage === 'simulations'   && <SimulationsPage onNavigate={navigate} />}
            {currentPage === 'exam-generator'&& <ExamGeneratorPage onNavigate={navigate} />}
            {currentPage === 'change-password'&&<ChangePasswordPage onNavigate={navigate} />}
          </div>
        </div>
      </div>
    </AuthContext.Provider>
  );
}

// ── Composants navigation ───────────────────────────────────────
function NavItem({ icon, label, active, onClick, badge }: {
  icon: React.ReactNode; label: string; active: boolean;
  onClick: () => void; badge?: boolean;
}) {
  return (
    <button onClick={onClick} style={{
              width: '100%', display: 'flex', alignItems: 'center', gap: 9,
      padding: '9px 10px', borderRadius: 7, border: 'none', cursor: 'pointer',
      background: active ? 'rgba(26,92,56,0.3)' : 'transparent',
      color: active ? '#4ade80' : '#94a3b8',
      fontSize: 17, fontWeight: active ? 600 : 400,
      transition: 'all 0.15s', marginBottom: 1,
      borderLeft: active ? '2px solid #1A5C38' : '2px solid transparent',
      textAlign: 'left',
    }}
    onMouseEnter={e => { if (!active) (e.currentTarget as HTMLElement).style.background = 'rgba(255,255,255,0.05)'; }}
    onMouseLeave={e => { if (!active) (e.currentTarget as HTMLElement).style.background = 'transparent'; }}
    >
      <span style={{ flexShrink: 0, opacity: active ? 1 : 0.7 }}>{icon}</span>
      <span style={{ flex: 1, textAlign: 'left', lineHeight: 1.2 }}>{label}</span>
      {badge && (
        <span style={{ background: '#f59e0b', color: '#000', fontSize: 13, fontWeight: 800, width: 16, height: 16, borderRadius: '50%', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>!</span>
      )}
    </button>
  );
}

// ── Titres des pages ────────────────────────────────────────────
function getPageTitle(page: Page): string {
  const titles: Record<Page, string> = {
    'dashboard': '📊 Tableau de bord — Vue globale',
    'matieres': '📚 Matières & Séries QCM — Gestion du contenu',
    'examens-types': '🎯 Examens Types — Création et gestion',
    'import-export': '📤 Import / Export — Gestion en masse',
    'paiements': '💳 Paiements & Abonnements',
    'annonces': '📢 Annonces officielles',
    'entraide': '🤝 Modération de l\'Entraide',
    'flags': '🚨 Signalements & Modération',
    'audit-log': '📜 Journal des actions administratives',
    'questions': '❓ Toutes les questions (vue avancée)',
    'create-question': '✚ Créer une question',
    'edit-question': '✏️ Modifier une question',
    'bulk-import': '📤 Import QCM avancé',
    'series': '📋 Séries — Gestion avancée',
    'simulations': '🎯 Simulations & Examens',
    'exam-generator': '🧩 Générateur d\'Examens composites',
    'change-password': '🔑 Changer le mot de passe',
  };
  return titles[page] ?? 'Admin';
}
