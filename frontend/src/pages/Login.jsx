import { useState } from 'react'
import { Link, useLocation, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import logo from '../assets/logo.jpg'

export default function Login() {
  const { login }  = useAuth()
  const navigate   = useNavigate()
  const location   = useLocation()
  const from       = location.state?.from ?? '/terrains'
  const [form, setForm]     = useState({ username: '', password: '' })
  const [error, setError]   = useState(null)
  const [busy, setBusy]     = useState(false)

  async function handleSubmit(e) {
    e.preventDefault()
    setError(null)
    setBusy(true)
    try {
      await login(form.username, form.password)
      navigate(from, { replace: true })
    } catch (err) {
      const d = err.response?.data
      if (d?.detail) setError(d.detail)
      else if (d) setError(Object.values(d).flat().join(' '))
      else setError('Identifiants incorrects. Vérifiez votre nom d\'utilisateur et mot de passe.')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="auth-page">
      <aside className="auth-aside">
        <div>
          <p className="auth-aside-quote">Sécurité. Confiance. Traçabilité.</p>
          <p className="auth-aside-sub">
            Le registre foncier numérique de la République Togolaise, garanti par
            une blockchain locale et un chiffrement des données sensibles.
          </p>
          <div className="auth-aside-points">
            <span className="auth-aside-point"><span className="auth-aside-point-dot" />Piste d'audit complète des transactions</span>
            <span className="auth-aside-point"><span className="auth-aside-point-dot" />Certification PDF avec QR code</span>
            <span className="auth-aside-point"><span className="auth-aside-point-dot" />Détection automatique des fraudes</span>
          </div>
        </div>
        <p className="auth-aside-footer">TrustLand · QuadraTech — TCCHackDefend 2026</p>
      </aside>

      <div className="auth-panel">
        <div className="auth-card">
          <img src={logo} alt="TrustLand" className="auth-logo" />
          <h1 className="auth-title">Connexion</h1>
          <p className="auth-sub">Accédez à votre espace TrustLand</p>

          {error && <div className="alert alert-error">{error}</div>}

          <form onSubmit={handleSubmit}>
            <div className="form-group">
              <label className="form-label" htmlFor="login-username">Nom d'utilisateur</label>
              <input
                id="login-username"
                className="form-control"
                value={form.username}
                onChange={e => setForm({ ...form, username: e.target.value })}
                required
                autoFocus
                autoComplete="username"
              />
            </div>
            <div className="form-group">
              <label className="form-label" htmlFor="login-password">Mot de passe</label>
              <input
                id="login-password"
                type="password"
                className="form-control"
                value={form.password}
                onChange={e => setForm({ ...form, password: e.target.value })}
                required
                autoComplete="current-password"
              />
            </div>
            <button className="btn btn-primary w-full" disabled={busy}>
              {busy ? 'Connexion…' : 'Se connecter'}
            </button>
          </form>

          <p className="auth-footer">
            Pas de compte ? <Link to="/register">S'inscrire</Link>
          </p>
        </div>
      </div>
    </div>
  )
}
