import { Link, NavLink, useNavigate } from 'react-router-dom'
import { useAuth } from '../context/AuthContext'
import { BrandMark } from './icons'

export default function Navbar() {
  const { user, logout } = useAuth()
  const navigate = useNavigate()
  const isAdmin = user?.role === 'admin'
  const isAgent = user?.role === 'agent'

  function handleLogout() {
    logout()
    navigate('/login')
  }

  return (
    <nav className="navbar">
      <Link to="/" className="navbar-brand" aria-label="TrustLand — accueil">
        <span className="navbar-brand-mark"><BrandMark /></span>
        <span><span className="brand-trust">Trust</span><span className="brand-land">Land</span></span>
      </Link>

      <div className="navbar-links">
        <NavLink to="/" end>Accueil</NavLink>
        <NavLink to="/terrains">Terrains</NavLink>
        {user && (
          <>
            <NavLink to="/carte">Carte</NavLink>
            {(isAdmin || isAgent) && <NavLink to="/proprietaires">Propriétaires</NavLink>}
            <NavLink to="/transactions">Transactions</NavLink>
            <NavLink to="/litiges">Litiges</NavLink>
            <NavLink to="/blockchain">Blockchain</NavLink>
            {(isAdmin || isAgent) && <NavLink to="/alertes">Alertes</NavLink>}
            <NavLink to="/verifier-document">Vérifier</NavLink>
            {isAdmin && <NavLink to="/gestion-utilisateurs">Utilisateurs</NavLink>}
          </>
        )}
      </div>

      <div className="navbar-auth">
        {user ? (
          <>
            <NavLink to="/profil" className="navbar-user">
              {user.username}
              <span className={`badge badge-role badge-${user.role}`}>{user.role}</span>
            </NavLink>
            <button className="btn btn-sm btn-outline" onClick={handleLogout}>
              Déconnexion
            </button>
          </>
        ) : (
          <>
            <Link to="/login"    className="btn btn-sm btn-outline">Connexion</Link>
            <Link to="/register" className="btn btn-sm btn-primary">S'inscrire</Link>
          </>
        )}
      </div>
    </nav>
  )
}
