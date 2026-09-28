import { useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import api from '../api/client'
import { IconMap, IconChain, IconDoc, IconQr, IconShield, IconScale } from '../components/icons'
import heroCadastre from '../assets/hero-cadastre.png'

const FEATURES = [
  {
    Icon: IconMap,
    title: 'Registre foncier numérique',
    desc: 'Enregistrement officiel de chaque parcelle avec coordonnées GPS, statut juridique et historique complet des propriétaires successifs.',
  },
  {
    Icon: IconChain,
    title: 'Chaîne de blocs immuable',
    desc: "Chaque transfert de propriété est horodaté et ancré dans une blockchain locale — aucune modification rétroactive n'est possible.",
  },
  {
    Icon: IconDoc,
    title: 'Archivage documentaire',
    desc: 'Titres fonciers, actes notariaux et contrats de vente sont archivés numériquement et associés à chaque dossier parcellaire.',
  },
  {
    Icon: IconQr,
    title: 'Identification par QR Code',
    desc: 'Chaque parcelle est identifiée par un QR Code unique permettant un accès instantané à la fiche officielle depuis le terrain.',
  },
  {
    Icon: IconShield,
    title: 'Détection des irrégularités',
    desc: 'Analyse automatique des transactions : double vente, cession répétée suspecte et vente simultanée sont signalées en temps réel.',
  },
  {
    Icon: IconScale,
    title: 'Suivi des contentieux',
    desc: "Déclaration et instruction des litiges fonciers avec suivi de l'état d'avancement jusqu'à la clôture du dossier.",
  },
]

const STEPS = [
  {
    title: 'Enregistrement',
    desc: "L'agent foncier crée la parcelle : délimitation GPS, identité du propriétaire, pièces justificatives numérisées.",
  },
  {
    title: 'Certification',
    desc: 'Le système vérifie la cohérence du dossier, génère le titre PDF et ancre son empreinte dans la blockchain locale.',
  },
  {
    title: 'Vérification',
    desc: 'Le QR Code de la parcelle donne accès à sa fiche officielle — à tout moment, depuis le terrain ou le bureau.',
  },
]

export default function Home() {
  const [stats, setStats] = useState({ terrains: null, transactions: null })

  useEffect(() => {
    Promise.allSettled([
      api.get('/api/terrains/'),
      api.get('/api/transactions/'),
    ]).then(([tRes, txRes]) => {
      setStats({
        terrains:     tRes.status === 'fulfilled'  ? (tRes.value.data.count  ?? tRes.value.data.length  ?? 0) : 0,
        transactions: txRes.status === 'fulfilled' ? (txRes.value.data.count ?? txRes.value.data.length ?? 0) : 0,
      })
    })
  }, [])

  return (
    <div>
      {/* Hero — contenu à gauche, plan cadastral à droite */}
      <section className="home-hero">
        <div className="home-hero-inner">
          <div>
            <div className="home-hero-badge">Registre foncier numérique · République Togolaise</div>
            <h1 className="home-hero-title">
              Sécurité. Confiance. <span className="accent">Traçabilité.</span>
            </h1>
            <p className="home-hero-sub">
              TrustLand numérise l'enregistrement des terrains, les transactions et la
              détection de fraude — certifiés par blockchain et QR code.
            </p>
            <div className="home-hero-actions">
              <Link to="/terrains" className="btn btn-primary">
                Consulter le registre
              </Link>
              <Link to="/register" className="btn btn-outline">
                Créer un compte
              </Link>
            </div>
          </div>

          <div className="home-hero-visual">
            <div className="home-hero-visual-frame">
              <img
                src={heroCadastre}
                alt="Plan cadastral illustré de parcelles enregistrées"
                width="1152" height="864"
              />
            </div>
            <div className="home-hero-visual-caption">
              <span className="dot" aria-hidden="true" />
              Chaque parcelle, un dossier certifié
            </div>
          </div>
        </div>
      </section>

      {/* Statistiques */}
      <section className="home-stats-bar">
        <div className="home-stats-inner">
          <div className="home-stat">
            <span className="home-stat-value">
              {stats.terrains === null ? '—' : stats.terrains.toLocaleString('fr-FR')}
            </span>
            <span className="home-stat-label">Parcelles enregistrées</span>
          </div>
          <div className="home-stat-divider" aria-hidden="true" />
          <div className="home-stat">
            <span className="home-stat-value">
              {stats.transactions === null ? '—' : stats.transactions.toLocaleString('fr-FR')}
            </span>
            <span className="home-stat-label">Transactions validées</span>
          </div>
          <div className="home-stat-divider" aria-hidden="true" />
          <div className="home-stat">
            <span className="home-stat-value home-stat-active">Actif</span>
            <span className="home-stat-label">Réseau blockchain</span>
          </div>
        </div>
      </section>

      {/* Fonctionnalités — grille 3×2 à fonds variés */}
      <section className="home-features-section">
        <div className="home-section-inner">
          <h2 className="home-section-title">Fonctionnalités principales</h2>
          <p className="home-section-sub">
            Un système intégré couvrant l'ensemble du cycle de vie d'un dossier foncier.
          </p>
          <div className="home-features-grid">
            {FEATURES.map(f => (
              <div key={f.title} className="home-feature-card">
                <div className="home-feature-icon">
                  <f.Icon />
                </div>
                <h3 className="home-feature-title">{f.title}</h3>
                <p className="home-feature-desc">{f.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Comment ça marche — étapes numérotées (autre famille de mise en page) */}
      <section className="home-steps-section">
        <div className="home-section-inner">
          <h2 className="home-section-title">Comment ça marche</h2>
          <p className="home-section-sub">
            Du relevé terrain à la certification : trois étapes, une piste d'audit complète.
          </p>
          <div className="home-steps-grid">
            {STEPS.map(s => (
              <div key={s.title} className="home-step">
                <span className="home-step-num" aria-hidden="true" />
                <h3 className="home-step-title">{s.title}</h3>
                <p className="home-step-desc">{s.desc}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* Bandeau d'action final */}
      <section className="home-cta-section">
        <div className="home-cta-inner">
          <div>
            <h2 className="home-cta-title">Un patrimoine foncier traçable, du relevé au titre.</h2>
            <p className="home-cta-sub">
              Créez votre compte pour accéder au registre, déclarer une transaction ou suivre un dossier.
            </p>
          </div>
          <div className="home-cta-actions">
            <Link to="/register" className="btn home-btn-light">Créer un compte</Link>
            <Link to="/terrains" className="btn btn-outline">Voir les terrains</Link>
          </div>
        </div>
      </section>
    </div>
  )
}
