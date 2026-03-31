import { useState, useEffect, createContext, useContext } from 'react';
import { getToken, clearToken } from './api';
import LoginPage from './pages/LoginPage';
import DashboardPage from './pages/DashboardPage';
import QuestionsPage from './pages/QuestionsPage';
import CreateQuestionPage from './pages/CreateQuestionPage';
import BulkImportPage from './pages/BulkImportPage';
import SeriesPage from './pages/SeriesPage';
import SimulationsPage from './pages/SimulationsPage';
import ExamensImportPage from './pages/ExamensImportPage';
import FlagsPage from './pages/FlagsPage';
import AuditLogPage from './pages/AuditLogPage';
import Sidebar from './components/Sidebar';
import { LayoutDashboard, FileQuestion, Upload, BookOpen, Target, Flag, History, LogOut, Menu, X, FileText } from 'lucide-react';

// ── Context Auth ─────────────────────────────────────────────
interface AuthContextType {
  user: any;
  setUser: (u: any) => void;
  logout: () => void;
}
const AuthContext = createContext<AuthContextType>({ user: null, setUser: () => {}, logout: () => {} });
export const useAuth = () => useContext(AuthContext);

// ── Types ─────────────────────────────────────────────────────
export type Page = 'dashboard' | 'questions' | 'create-question' | 'edit-question' | 'bulk-import' | 'series' | 'simulations' | 'examens-import' | 'flags' | 'audit-log';

export default function App() {
  const [user, setUser] = useState<any>(() => {
    try { return JSON.parse(localStorage.getItem('admin_user') ?? 'null'); } catch { return null; }
  });
  const [currentPage, setCurrentPage] = useState<Page>('dashboard');
  const [editQuestionId, setEditQuestionId] = useState<string | null>(null);
  const [sidebarOpen, setSidebarOpen] = useState(true);

  const logout = () => {
    clearToken();
    setUser(null);
  };

  // Vérification token au démarrage
  useEffect(() => {
    const token = getToken();
    if (!token) setUser(null);
  }, []);

  if (!user || !getToken()) {
    return (
      <AuthContext.Provider value={{ user, setUser, logout }}>
        <LoginPage onLogin={(u) => {
          setUser(u);
          localStorage.setItem('admin_user', JSON.stringify(u));
        }} />
      </AuthContext.Provider>
    );
  }

  const navigate = (page: Page, questionId?: string) => {
    setCurrentPage(page);
    if (questionId) setEditQuestionId(questionId);
    // Fermer sidebar sur mobile
    if (window.innerWidth < 768) setSidebarOpen(false);
  };

  return (
    <AuthContext.Provider value={{ user, setUser, logout }}>
      <div style={{ display: 'flex', minHeight: '100vh', background: '#0f172a' }}>
        {/* Overlay mobile */}
        {sidebarOpen && window.innerWidth < 768 && (
          <div onClick={() => setSidebarOpen(false)}
            style={{ position: 'fixed', inset: 0, background: 'rgba(0,0,0,0.5)', zIndex: 40 }} />
        )}

        {/* Sidebar */}
        <div style={{
          position: 'fixed', left: sidebarOpen ? 0 : '-256px', top: 0, bottom: 0,
          width: 256, zIndex: 50, transition: 'left 0.3s ease',
          background: 'linear-gradient(180deg, #1e293b 0%, #0f172a 100%)',
          borderRight: '1px solid #334155', display: 'flex', flexDirection: 'column',
        }}>
          {/* Logo */}
          <div style={{ padding: '20px 16px', borderBottom: '1px solid #334155' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 12 }}>
              <div style={{
                width: 40, height: 40, borderRadius: 10,
                background: 'linear-gradient(135deg, #1A5C38, #D4A017)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                fontWeight: 'bold', fontSize: 14, color: 'white', flexShrink: 0,
              }}>EF</div>
              <div>
                <div style={{ fontWeight: 700, color: '#f1f5f9', fontSize: 14 }}>EF-FORT.BF</div>
                <div style={{ color: '#64748b', fontSize: 11 }}>Administration CMS v6.0</div>
              </div>
            </div>
          </div>

          {/* Navigation */}
          <nav style={{ flex: 1, overflowY: 'auto', padding: '12px 8px' }}>
            <NavItem icon={<LayoutDashboard size={18} />} label="Tableau de bord" active={currentPage === 'dashboard'} onClick={() => navigate('dashboard')} />
            <div style={{ color: '#475569', fontSize: 11, fontWeight: 600, padding: '12px 8px 4px', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Questions</div>
            <NavItem icon={<FileQuestion size={18} />} label="Gérer Questions" active={currentPage === 'questions'} onClick={() => navigate('questions')} />
            <NavItem icon={<span style={{ fontSize: 18 }}>✚</span>} label="Créer Question" active={currentPage === 'create-question'} onClick={() => navigate('create-question')} />
            <NavItem icon={<Upload size={18} />} label="Import en Masse" active={currentPage === 'bulk-import'} onClick={() => navigate('bulk-import')} />
            <div style={{ color: '#475569', fontSize: 11, fontWeight: 600, padding: '12px 8px 4px', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Contenu</div>
            <NavItem icon={<BookOpen size={18} />} label="Séries" active={currentPage === 'series'} onClick={() => navigate('series')} />
            <NavItem icon={<Target size={18} />} label="Simulations" active={currentPage === 'simulations'} onClick={() => navigate('simulations')} />
            <NavItem icon={<FileText size={18} />} label="Import Examens" active={currentPage === 'examens-import'} onClick={() => navigate('examens-import')} />
            <div style={{ color: '#475569', fontSize: 11, fontWeight: 600, padding: '12px 8px 4px', textTransform: 'uppercase', letterSpacing: '0.1em' }}>Modération</div>
            <NavItem icon={<Flag size={18} />} label="Signalements" active={currentPage === 'flags'} onClick={() => navigate('flags')} />
            <NavItem icon={<History size={18} />} label="Audit Log" active={currentPage === 'audit-log'} onClick={() => navigate('audit-log')} />
          </nav>

          {/* User */}
          <div style={{ padding: 12, borderTop: '1px solid #334155' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: 10 }}>
              <div style={{
                width: 32, height: 32, borderRadius: '50%',
                background: 'linear-gradient(135deg, #1A5C38, #2d9966)',
                display: 'flex', alignItems: 'center', justifyContent: 'center',
                color: 'white', fontSize: 12, fontWeight: 600, flexShrink: 0,
              }}>
                {user?.prenom?.[0]?.toUpperCase() ?? 'A'}
              </div>
              <div style={{ flex: 1, minWidth: 0 }}>
                <div style={{ color: '#e2e8f0', fontSize: 13, fontWeight: 500, overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
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
        <div style={{ flex: 1, marginLeft: sidebarOpen ? 256 : 0, transition: 'margin-left 0.3s ease', minWidth: 0 }}>
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
            <div style={{ flex: 1, color: '#94a3b8', fontSize: 13 }}>
              {getPageTitle(currentPage)}
            </div>
            <div style={{ color: '#D4A017', fontSize: 12, fontWeight: 600 }}>
              🟢 LIVE
            </div>
          </div>

          {/* Page Content */}
          <div style={{ padding: 24, maxWidth: 1400 }}>
            {currentPage === 'dashboard' && <DashboardPage onNavigate={navigate} />}
            {currentPage === 'questions' && <QuestionsPage onNavigate={navigate} onEdit={(id) => { setEditQuestionId(id); navigate('edit-question'); }} />}
            {(currentPage === 'create-question' || currentPage === 'edit-question') && <CreateQuestionPage questionId={currentPage === 'edit-question' ? editQuestionId : null} onNavigate={navigate} />}
            {currentPage === 'bulk-import' && <BulkImportPage onNavigate={navigate} />}
            {currentPage === 'series' && <SeriesPage onNavigate={navigate} />}
            {currentPage === 'simulations' && <SimulationsPage onNavigate={navigate} />}
            {currentPage === 'examens-import' && <ExamensImportPage onNavigate={navigate} />}
            {currentPage === 'flags' && <FlagsPage onNavigate={navigate} />}
            {currentPage === 'audit-log' && <AuditLogPage onNavigate={navigate} />}
          </div>
        </div>
      </div>
    </AuthContext.Provider>
  );
}

function NavItem({ icon, label, active, onClick }: { icon: React.ReactNode; label: string; active: boolean; onClick: () => void }) {
  return (
    <button onClick={onClick} style={{
      width: '100%', display: 'flex', alignItems: 'center', gap: 10,
      padding: '8px 12px', borderRadius: 8, border: 'none', cursor: 'pointer',
      background: active ? 'rgba(26,92,56,0.3)' : 'transparent',
      color: active ? '#4ade80' : '#94a3b8',
      fontSize: 14, fontWeight: active ? 600 : 400,
      transition: 'all 0.15s', marginBottom: 2,
      borderLeft: active ? '2px solid #1A5C38' : '2px solid transparent',
    }}
    onMouseEnter={e => { if (!active) (e.target as any).style.background = 'rgba(255,255,255,0.05)'; }}
    onMouseLeave={e => { if (!active) (e.target as any).style.background = 'transparent'; }}
    >
      {icon}
      {label}
    </button>
  );
}

function getPageTitle(page: Page): string {
  const titles: Record<Page, string> = {
    'dashboard': '📊 Tableau de bord',
    'questions': '❓ Gestion des questions',
    'create-question': '✚ Créer une question',
    'edit-question': '✏️ Modifier la question',
    'bulk-import': '📤 Import en masse',
    'series': '📚 Gestion des séries',
    'simulations': '🎯 Simulations d\'examen',
    'examens-import': '📝 Import Examens',
    'flags': '🚨 Signalements',
    'audit-log': '📜 Audit & Historique',
  };
  return titles[page] ?? 'Admin CMS';
}
