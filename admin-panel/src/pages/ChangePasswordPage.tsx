// ChangePasswordPage.tsx — Changer le mot de passe administrateur
import { useState } from 'react';
import { getToken } from '../api';
import type { Page } from '../App';

export default function ChangePasswordPage({ onNavigate: _n }: { onNavigate: (p: Page) => void }) {
  const [currentPassword, setCurrentPassword] = useState('');
  const [newPassword, setNewPassword] = useState('');
  const [confirmPassword, setConfirmPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState('');
  const [error, setError] = useState('');
  const [showCurrent, setShowCurrent] = useState(false);
  const [showNew, setShowNew] = useState(false);
  const [showConfirm, setShowConfirm] = useState(false);

  const BASE_URL = window.location.hostname === 'localhost'
    ? 'http://localhost:8787'
    : 'https://ef-fort-bf.yembuaro29.workers.dev';

  function validatePassword(pwd: string): string | null {
    if (pwd.length < 8) return 'Au moins 8 caractères requis';
    if (!/[A-Z]/.test(pwd)) return 'Au moins une lettre majuscule requise';
    if (!/[0-9]/.test(pwd)) return 'Au moins un chiffre requis';
    return null;
  }

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError(''); setSuccess('');

    if (!currentPassword.trim()) { setError('Saisissez votre mot de passe actuel'); return; }
    const pwdError = validatePassword(newPassword);
    if (pwdError) { setError(pwdError); return; }
    if (newPassword !== confirmPassword) { setError('Les mots de passe ne correspondent pas'); return; }
    if (newPassword === currentPassword) { setError('Le nouveau mot de passe doit être différent de l\'ancien'); return; }

    setLoading(true);
    try {
      const token = getToken();
      const res = await fetch(`${BASE_URL}/api/admin/change-password`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ current_password: currentPassword, new_password: newPassword }),
      });
      const data = await res.json();
      if (!res.ok) throw new Error(data.error ?? 'Erreur lors du changement de mot de passe');
      setSuccess('✅ Mot de passe changé avec succès ! Pour des raisons de sécurité, reconnectez-vous.');
      setCurrentPassword(''); setNewPassword(''); setConfirmPassword('');
    } catch (e: any) {
      setError(e.message);
    } finally {
      setLoading(false);
    }
  }

  const strength = newPassword.length === 0 ? 0
    : newPassword.length < 6 ? 1
    : newPassword.length < 10 ? 2
    : /[A-Z]/.test(newPassword) && /[0-9]/.test(newPassword) && /[^a-zA-Z0-9]/.test(newPassword) ? 4
    : 3;

  const strengthColors = ['transparent', '#ef4444', '#f59e0b', '#22c55e', '#1A5C38'];
  const strengthLabels = ['', 'Faible', 'Moyen', 'Fort', 'Très fort'];

  return (
    <div style={{ maxWidth: 520, margin: '0 auto' }}>
      <div style={{ marginBottom: 28 }}>
        <h2 style={{ color: '#f1f5f9', fontSize: 22, fontWeight: 700, margin: 0 }}>🔑 Changer le Mot de Passe</h2>
        <p style={{ color: '#64748b', fontSize: 17, marginTop: 6 }}>
          Pour votre sécurité, changez régulièrement votre mot de passe administrateur.
        </p>
      </div>

      <div style={{ background: '#1e293b', borderRadius: 16, padding: 32, border: '1px solid #334155' }}>
        <form onSubmit={handleSubmit}>
          {/* Mot de passe actuel */}
          <PasswordField
            label="Mot de passe actuel"
            value={currentPassword}
            onChange={setCurrentPassword}
            show={showCurrent}
            onToggle={() => setShowCurrent(!showCurrent)}
            placeholder="Votre mot de passe actuel"
          />

          <div style={{ borderTop: '1px solid #334155', margin: '20px 0' }} />

          {/* Nouveau mot de passe */}
          <PasswordField
            label="Nouveau mot de passe"
            value={newPassword}
            onChange={setNewPassword}
            show={showNew}
            onToggle={() => setShowNew(!showNew)}
            placeholder="Minimum 8 caractères, 1 majuscule, 1 chiffre"
          />

          {/* Indicateur de force */}
          {newPassword.length > 0 && (
            <div style={{ marginTop: 8, marginBottom: 16 }}>
              <div style={{ display: 'flex', gap: 4, marginBottom: 4 }}>
                {[1, 2, 3, 4].map(i => (
                  <div key={i} style={{ flex: 1, height: 4, borderRadius: 2, background: i <= strength ? strengthColors[strength] : '#334155', transition: 'all 0.3s' }} />
                ))}
              </div>
              <div style={{ color: strengthColors[strength], fontSize: 15, fontWeight: 600 }}>{strengthLabels[strength]}</div>
            </div>
          )}

          {/* Confirmer */}
          <PasswordField
            label="Confirmer le nouveau mot de passe"
            value={confirmPassword}
            onChange={setConfirmPassword}
            show={showConfirm}
            onToggle={() => setShowConfirm(!showConfirm)}
            placeholder="Répétez le nouveau mot de passe"
            matchValue={newPassword}
          />

          {/* Critères */}
          <div style={{ background: '#0f172a', borderRadius: 8, padding: '12px 16px', marginTop: 4, marginBottom: 20 }}>
            <div style={{ color: '#64748b', fontSize: 15, fontWeight: 600, marginBottom: 8 }}>Critères requis :</div>
            {[
              { label: '8 caractères minimum', ok: newPassword.length >= 8 },
              { label: '1 lettre majuscule', ok: /[A-Z]/.test(newPassword) },
              { label: '1 chiffre', ok: /[0-9]/.test(newPassword) },
              { label: 'Différent de l\'actuel', ok: newPassword.length > 0 && newPassword !== currentPassword },
            ].map(c => (
              <div key={c.label} style={{ display: 'flex', alignItems: 'center', gap: 8, marginBottom: 4 }}>
                <span style={{ color: c.ok ? '#22c55e' : '#475569', fontSize: 17 }}>{c.ok ? '✓' : '○'}</span>
                <span style={{ color: c.ok ? '#94a3b8' : '#475569', fontSize: 16 }}>{c.label}</span>
              </div>
            ))}
          </div>

          {error && (
            <div style={{ background: 'rgba(239,68,68,0.1)', border: '1px solid rgba(239,68,68,0.3)', borderRadius: 8, padding: '10px 14px', color: '#ef4444', fontSize: 16, marginBottom: 16 }}>
              ❌ {error}
            </div>
          )}
          {success && (
            <div style={{ background: 'rgba(34,197,94,0.1)', border: '1px solid #22c55e44', borderRadius: 8, padding: '10px 14px', color: '#22c55e', fontSize: 16, marginBottom: 16 }}>
              {success}
            </div>
          )}

          <button type="submit" disabled={loading} style={{
            width: '100%', background: loading ? '#334155' : '#1A5C38', color: 'white', border: 'none',
            padding: '12px', borderRadius: 10, cursor: loading ? 'not-allowed' : 'pointer',
            fontWeight: 700, fontSize: 18, transition: 'all 0.2s',
          }}>
            {loading ? '⏳ Changement en cours...' : '🔑 Changer le mot de passe'}
          </button>
        </form>
      </div>

      <div style={{ background: 'rgba(212,160,23,0.1)', border: '1px solid rgba(212,160,23,0.3)', borderRadius: 12, padding: 16, marginTop: 20 }}>
        <div style={{ color: '#D4A017', fontWeight: 700, marginBottom: 6 }}>💡 Conseils de sécurité</div>
        <ul style={{ color: '#94a3b8', fontSize: 16, margin: 0, paddingLeft: 18, lineHeight: 1.8 }}>
          <li>Changez votre mot de passe après chaque déploiement</li>
          <li>N'utilisez pas votre mot de passe dans d'autres services</li>
          <li>Utilisez au moins 12 caractères avec des symboles spéciaux</li>
          <li>Ne partagez jamais votre mot de passe administrateur</li>
        </ul>
      </div>
    </div>
  );
}

function PasswordField({ label, value, onChange, show, onToggle, placeholder, matchValue }: {
  label: string; value: string; onChange: (v: string) => void; show: boolean; onToggle: () => void;
  placeholder?: string; matchValue?: string;
}) {
  const isMatch = matchValue !== undefined && value.length > 0 && value === matchValue;
  const noMatch = matchValue !== undefined && value.length > 0 && value !== matchValue;
  return (
    <div style={{ marginBottom: 16 }}>
      <label style={{ color: '#94a3b8', fontSize: 16, fontWeight: 600, display: 'block', marginBottom: 6 }}>{label}</label>
      <div style={{ position: 'relative' }}>
        <input
          type={show ? 'text' : 'password'}
          value={value}
          onChange={e => onChange(e.target.value)}
          placeholder={placeholder}
          style={{
            width: '100%', background: '#0f172a', border: `1px solid ${isMatch ? '#22c55e' : noMatch ? '#ef4444' : '#334155'}`,
            borderRadius: 8, padding: '10px 44px 10px 12px', color: '#f1f5f9', fontSize: 17, boxSizing: 'border-box',
            outline: 'none',
          }}
        />
        <button type="button" onClick={onToggle} style={{
          position: 'absolute', right: 12, top: '50%', transform: 'translateY(-50%)',
          background: 'none', border: 'none', cursor: 'pointer', color: '#64748b', fontSize: 16, padding: 2,
        }}>
          {show ? '🙈' : '👁'}
        </button>
      </div>
      {isMatch && <div style={{ color: '#22c55e', fontSize: 15, marginTop: 4 }}>✓ Les mots de passe correspondent</div>}
      {noMatch && <div style={{ color: '#ef4444', fontSize: 15, marginTop: 4 }}>✗ Les mots de passe ne correspondent pas</div>}
    </div>
  );
}
