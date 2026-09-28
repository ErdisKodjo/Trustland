import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import api from '../api/client'
import { useAuth } from '../context/AuthContext'
import logo from '../assets/logo.jpg'

export default function Register() {
  const navigate  = useNavigate()
  const { login } = useAuth()
  const [form, setForm] = useState({
    username: '', email: '', password: '', confirm: '', role: 'proprietaire',
  })
  const [error, setError] = useState(null)
  const [busy, setBusy]   = useState(false)

  function field(name) {
    return { value: form[name], onChange: e => setForm({ ...form, [name]: e.target.value }) }
  }

  async function handleSubmit(e) {
    e.preventDefault()
    setError(null)

    if (form.password !== form.confirm) {
      setError('Les mots de passe ne correspondent pas.')
      return
    }

    setBusy(true)
    try {
      const { username, email, password, role } = form
      await api.post('/api/users/register/', { username, email, password, role })
    } catch (err) {
      const data = err.response?.data
      if (data && typeof data === 'object') {
        const msgs = Object.entries(data)
          .flatMap(([k, v]) => (Array.isArray(v) ? v : [v]).map(m => `${k} : ${m}`))
        setError(msgs.join(' '))
      } else {
        setError("Erreur lors de l'inscription. Veuillez réessayer.")
      }
      setBusy(false)
      return
    }
    try {
      await login(form.username, form.password)
      navigate('/')
    } catch {
      // Inscription réussie mais connexion auto échouée — rediriger vers login
      navigate('/login')
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="auth-page">
      <aside className="auth-aside">
        <div>
          <p className="auth-aside-quote">Votre dossier foncier, suivi de bout en bout.</p>
          <p className="auth-aside-sub">
            Créez votre compte pour consulter le registre, suivre vos parcelles
            et recevoir les alertes liées à vos dossiers.
          </p>
        </div>
        <p className="auth-aside-footer">TrustLand · QuadraTech — TCCHackDefend 2026</p>
      </aside>

      <div className="auth-panel">
        <div className="auth-card">
          <img src={logo} alt="TrustLand" className="auth-logo" />
          <h1 className="auth-title">Créer un compte</h1>
          <p className="auth-sub">Rejoignez le registre foncier numérique</p>

          {error && <div className="alert alert-error">{error}</div>}

        <form onSubmit={handleSubmit}>
          <div className="form-group">
            <label className="form-label" htmlFor="reg-username">Nom d'utilisateur</label>
            <input id="reg-username" className="form-control" {...field('username')} required autoFocus autoComplete="username" />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="reg-email">Email</label>
            <input id="reg-email" type="email" className="form-control" {...field('email')} autoComplete="email" />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="reg-password">Mot de passe</label>
            <input id="reg-password" type="password" className="form-control" {...field('password')} required autoComplete="new-password" />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="reg-confirm">Confirmer le mot de passe</label>
            <input id="reg-confirm" type="password" className="form-control" {...field('confirm')} required autoComplete="new-password" />
          </div>
          <div className="form-group">
            <label className="form-label" htmlFor="reg-role">Rôle</label>
            <select id="reg-role" className="form-control" {...field('role')}>
              <option value="proprietaire">Propriétaire</option>
            </select>
          </div>
          <button className="btn btn-primary w-full" disabled={busy}>
            {busy ? 'Création…' : 'Créer le compte'}
          </button>
        </form>

        <p className="auth-footer">
          Déjà un compte ? <Link to="/login">Se connecter</Link>
        </p>
        </div>
      </div>
    </div>
  )
}
