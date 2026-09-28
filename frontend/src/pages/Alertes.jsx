import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import api from '../api/client'
import { STATUT_LABELS } from '../utils'

const TYPE_LABELS = {
  transaction_repetee: 'Transaction répétée',
  vendeur_suspect:     'Vendeur suspect',
  double_transaction:  'Double transaction',
}

const NIVEAU_LABELS = {
  critique: 'Critique',
  moyen:    'Moyen',
  faible:   'Faible',
}

const FILTRES = ['tout', 'critique', 'moyen', 'faible']

export default function Alertes() {
  const [items,   setItems]   = useState([])
  const [loading, setLoading] = useState(true)
  const [filtre,  setFiltre]  = useState('tout')

  useEffect(() => {
    api.get('/api/alertes/')
      .then(({ data }) => { setItems(data.results ?? data); setLoading(false) })
      .catch(() => setLoading(false))
  }, [])

  const visible = filtre === 'tout' ? items : items.filter(a => a.niveau === filtre)

  const counts = items.reduce((acc, a) => {
    acc[a.niveau] = (acc[a.niveau] ?? 0) + 1
    return acc
  }, {})

  return (
    <div className="page">
      <div className="page-header">
        <div>
          <h2>Alertes de fraude</h2>
          {!loading && (
            <p className="text-muted">
              {items.length} alerte{items.length !== 1 ? 's' : ''} au total
            </p>
          )}
        </div>

        {/* Compteurs par niveau */}
        {!loading && items.length > 0 && (
          <div className="alerte-counts">
            {(['critique', 'moyen', 'faible']).map(n => (
              counts[n] ? (
                <span key={n} className={`alerte-pill alerte-pill-${n}`}>
                  <span className="alerte-dot" />
                  {counts[n]} {NIVEAU_LABELS[n].toLowerCase()}
                </span>
              ) : null
            ))}
          </div>
        )}
      </div>

      {/* Filtres */}
      <div className="chip-group" role="group" aria-label="Filtrer par niveau">
        {FILTRES.map(f => (
          <button
            key={f}
            className={`chip${filtre === f ? ' chip-active' : ''}`}
            onClick={() => setFiltre(f)}
          >
            {f === 'tout' ? 'Toutes' : NIVEAU_LABELS[f]}
            {f !== 'tout' && counts[f] ? ` (${counts[f]})` : ''}
          </button>
        ))}
      </div>

      {loading ? (
        <div className="alerte-list" aria-label="Chargement" aria-busy="true">
          <div className="skeleton skeleton-card" />
          <div className="skeleton skeleton-card" />
        </div>
      ) : visible.length === 0 ? (
        <div className="empty-state">
          <div className="empty-icon" aria-hidden="true">
            <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="1.8" width="28" height="28">
              <path strokeLinecap="round" strokeLinejoin="round"
                d="M9 12.75L11.25 15 15 9.75M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
          </div>
          <p className="empty-title">
            {filtre === 'tout'
              ? 'Aucune alerte détectée.'
              : `Aucune alerte de niveau « ${NIVEAU_LABELS[filtre]} ».`}
          </p>
          <p className="text-muted">
            Le moteur de détection n&apos;a rien signalé — le registre est serein.
          </p>
        </div>
      ) : (
        <div className="alerte-list">
          {visible.map(a => (
            <article key={a.id} className={`alerte-card alerte-${a.niveau}`}>
              <div className="alerte-head">
                <div className="alerte-head-left">
                  <span className={`alerte-badge alerte-badge-${a.niveau}`}>
                    <span className="alerte-dot" />
                    {NIVEAU_LABELS[a.niveau] ?? a.niveau}
                  </span>
                  <span className="alerte-type">
                    {TYPE_LABELS[a.type_alerte] ?? a.type_alerte}
                  </span>
                </div>
                <time className="alerte-date">{new Date(a.date).toLocaleString('fr-FR')}</time>
              </div>

              <p className="alerte-desc">{a.description}</p>

              {a.terrain_detail && (
                <div className="alerte-terrain">
                  <span className="alerte-terrain-label">Terrain :</span>
                  <Link
                    to={`/terrains/${a.terrain_detail.id}`}
                    className="alerte-terrain-link"
                  >
                    {a.terrain_detail.adresse}
                  </Link>
                  <span className={`badge badge-${a.terrain_detail.statut}`}>
                    {STATUT_LABELS[a.terrain_detail.statut] ?? a.terrain_detail.statut}
                  </span>
                </div>
              )}
            </article>
          ))}
        </div>
      )}
    </div>
  )
}
