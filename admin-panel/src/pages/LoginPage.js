import { useState } from 'react';
import { login } from '../api';
export default function LoginPage({ onLogin }) {
    const [telephone, setTelephone] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const handleSubmit = async (e) => {
        e.preventDefault();
        setLoading(true);
        setError('');
        try {
            const data = await login(telephone, password);
            // Stocker token
            localStorage.setItem('admin_token', data.token);
            onLogin(data.user);
        }
        catch (err) {
            setError(err.message ?? 'Erreur de connexion');
        }
        finally {
            setLoading(false);
        }
    };
    return (<div style={{
            minHeight: '100vh', display: 'flex', alignItems: 'center', justifyContent: 'center',
            background: 'linear-gradient(135deg, #0f172a 0%, #1e293b 50%, #0f172a 100%)',
        }}>
      <div style={{
            width: '100%', maxWidth: 400, padding: 40,
            background: '#1e293b', borderRadius: 16,
            border: '1px solid #334155',
            boxShadow: '0 25px 50px rgba(0,0,0,0.5)',
        }}>
        {/* Logo */}
        <div style={{ textAlign: 'center', marginBottom: 32 }}>
          <div style={{
            width: 64, height: 64, borderRadius: 16,
            background: 'linear-gradient(135deg, #1A5C38, #D4A017)',
            display: 'flex', alignItems: 'center', justifyContent: 'center',
            margin: '0 auto 16px', fontSize: 24, fontWeight: 900, color: 'white',
        }}>EF</div>
          <h1 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700 }}>EF-FORT.BF Admin</h1>
          <p style={{ color: '#64748b', fontSize: 13, marginTop: 4 }}>Content Management System v6.0</p>
        </div>

        <form onSubmit={handleSubmit}>
          <div style={{ marginBottom: 16 }}>
            <label style={{ display: 'block', color: '#94a3b8', fontSize: 13, marginBottom: 6, fontWeight: 500 }}>
              Téléphone / Identifiant
            </label>
            <input type="text" value={telephone} onChange={e => setTelephone(e.target.value)} placeholder="ex: 72662161" required autoFocus style={{
            width: '100%', padding: '10px 14px', background: '#0f172a',
            border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0',
            fontSize: 14, outline: 'none',
        }}/>
          </div>

          <div style={{ marginBottom: 24 }}>
            <label style={{ display: 'block', color: '#94a3b8', fontSize: 13, marginBottom: 6, fontWeight: 500 }}>
              Mot de passe
            </label>
            <input type="password" value={password} onChange={e => setPassword(e.target.value)} placeholder="••••••••" required style={{
            width: '100%', padding: '10px 14px', background: '#0f172a',
            border: '1px solid #334155', borderRadius: 8, color: '#e2e8f0',
            fontSize: 14, outline: 'none',
        }}/>
          </div>

          {error && (<div style={{
                background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)',
                borderRadius: 8, padding: '10px 14px', color: '#ef4444', fontSize: 13, marginBottom: 16,
            }}>
              ⚠️ {error}
            </div>)}

          <button type="submit" disabled={loading} style={{
            width: '100%', padding: '12px', background: loading ? '#334155' : 'linear-gradient(135deg, #1A5C38, #2d9966)',
            border: 'none', borderRadius: 8, color: 'white', fontSize: 15, fontWeight: 600,
            cursor: loading ? 'not-allowed' : 'pointer', transition: 'all 0.2s',
        }}>
            {loading ? '⏳ Connexion...' : '🔐 Se connecter'}
          </button>
        </form>

        <p style={{ color: '#475569', fontSize: 12, textAlign: 'center', marginTop: 24 }}>
          Accès réservé aux administrateurs EF-FORT.BF
        </p>
      </div>
    </div>);
}
