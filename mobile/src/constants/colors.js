// TrustLand — palette « Forest » (alignée sur le design system web « Cadastre »)
// Source de vérité : frontend/src/index.css — ne pas introduire d'autres couleurs.
export default {
  primary:     '#1e5a31',   // vert cadastre (--green-700)
  primaryDark: '#12301c',   // vert profond (--green-900)
  bg:          '#faf9f5',   // toile os (--canvas)
  surface:     '#ffffff',
  border:      '#e4e6dc',   // --border
  text:        '#101510',   // encre (--ink)
  muted:       '#5d675e',   // --mute

  accent:      '#b45309',   // ambre (--amber-600) : alertes, mises en garde
  danger:      '#b3261e',   // --danger
  info:        '#1d5c96',   // bleu harmonisé du logo (--info)

  statut: {
    libre:          '#1e5a31',   // vert cadastre
    en_transaction: '#1d5c96',   // bleu info
    litige:         '#b3261e',   // rouge danger
  },

  statutBg: {
    libre:          '#eef5ef',   // --green-50
    en_transaction: '#e6eff8',   // --info-bg
    litige:         '#fceae8',   // --danger-bg
  },
};
