# Synthèse des Commentaires Stratégiques — Intégration dans les Livrables

**Date** : 2026-02-17
**Source** : Revue stratégique externe (3 vagues de commentaires)
**Statut** : Vague 1 intégrée / Vagues 2-3 en attente

---

## Matrice d'Impact : Vague 1

La vague 1 a identifié **7 points de fragilité** dans la proposition. Voici comment chacun a été traité dans les livrables.

### Points de Force Confirmés

| Point | Commentaire vague 1 | Statut |
|-------|---------------------|--------|
| Trilogie de parcours A/B/C | "Le point le plus solide" — adoption facile (A), rupture (B), flywheel (C) | Validé. Conservé tel quel. |
| Blockchain invisible côté client | "Web2 côté client, blockchain invisible" déjà dans la proposition | Validé. Renforcé dans le positionnement commercial. |
| Éviter les oracles enterprise au MVP | Multi-sig + NPS + timer = "pragmatique et cohérent" | Validé. Oracles → Phase 2+. |
| REP soulbound (ERC-5484) | "Bonne intuition" sur la portabilité de la réputation | Validé. Renforcé avec burn/rotation et consentement. |

### Points de Fragilité Corrigés

| # | Fragilité identifiée | Sévérité | Correction | Document modifié |
|---|---------------------|----------|------------|------------------|
| **F1** | NFT ≠ IP. Pas de cadre de licensing explicite. | CRITIQUE | 3 modèles de licence standard (L1/L2/L3) + mécanisme hybride off-chain/on-chain | `legal-workstream.md` §Cadre IP et Licensing |
| **F2** | Pas de "pacte contributeur" (confidentialité, IP, conflits d'intérêt) | CRITIQUE | Pacte en 6 sections avec clause de sous-traitance et limitation de responsabilité | `legal-workstream.md` §Pacte Contributeurs |
| **F3** | Pas de prime contractor identifié. Responsabilité diffuse. | CRITIQUE | SAS = prime contractor. Schéma de responsabilité Client↔SAS↔Contributeur | `legal-workstream.md` §Modèle Prime Contractor |
| **F4** | Pas de mécanisme de dispute resolution structuré | HAUTE | 3 niveaux : médiation curateur → arbitrage DAO → tribunal de commerce | `legal-workstream.md` §Dispute Resolution |
| **F5** | Positionnement "100% blockchain" effraie l'enterprise | HAUTE | Reframing : "cabinet d'expertise composable et productisé" + test de réalité 5 points | `client-acquisition-plan.md` §Positionnement |
| **F6** | Agent IA sans QA = risque qualité catastrophique | HAUTE | Curation gate obligatoire (auto + humain) + Agent Listing Standard | `client-acquisition-plan.md` §Curation Gate + Agent Listing |
| **F7** | Sybil, farming, capture de gouvernance non adressés | MOYENNE | Communauté fermée M0-M3, identité vérifiée, plafond voting power, pénalités | `client-acquisition-plan.md` §Anti-Sybil |

### Impact Financier des Corrections

| Correction | Coût one-shot | Coût récurrent/mois | Impact sur breakeven |
|------------|--------------|---------------------|---------------------|
| F1 : Cadre IP | 1 000-2 000 EUR | 85-170 EUR (amort.) | +1-2 semaines |
| F2 : Pacte contributeurs | 500-1 000 EUR | 0 EUR | Négligeable |
| F3 : RC Pro étendue | 500-1 000 EUR | 40-85 EUR (amort.) | Négligeable |
| F4 : Dispute (process) | 0 EUR (intégré dans CGV) | 0 EUR | Aucun |
| F5 : Reframing | 0 EUR | 0 EUR | Positif (meilleure conversion) |
| F6 : Curation | 0 EUR | 10% rev. missions IA | -5% revenus nets Parcours B |
| F7 : Anti-sybil | 0 EUR | 0 EUR | Aucun |
| **TOTAL** | **2 000-4 000 EUR** | **~250-500 EUR/mois** | **+2-3 semaines de breakeven** |

---

## Matrice de Traçabilité : Commentaires → Actions

### Vague 1 — Complète

| § Commentaire | Recommandation verbatim | Action prise | Livrable | Statut |
|---------------|------------------------|-------------|----------|--------|
| §1 Résumé | "Bascule vers vente d'outputs et équipes composables = moat crédible" | Intégré dans le positionnement commercial | `client-acquisition-plan.md` | FAIT |
| §2.1 Oracles | "Gardez oracles comme option Phase 2+" | Déjà aligné, pas de modification | — | OK |
| §2.2 REP soulbound | "Prévoir burn/rotation, minimisation données, contestation" | Question ajoutée pour l'avocat + spec ERC-5484 dans workstream juridique | `legal-workstream.md` | FAIT |
| §2.3 IP Registry | "purchaseLicense() doit être doublé d'un cadre contractuel lisible" | 3 templates licence + mécanisme hybride off-chain/on-chain | `legal-workstream.md` | FAIT |
| §3 Positionnement | "Reframing : cabinet d'expertise composable et productisé" | Nouvelle section positionnement + test de réalité enterprise | `client-acquisition-plan.md` | FAIT |
| §4.1 Qualité IA | "Curation gate obligatoire, pas optionnelle" | Pipeline de curation 2 gates (auto + humain) | `client-acquisition-plan.md` | FAIT |
| §4.2 Anti-GPT-wrapper | "Agent Listing Standard avec tests minimaux" | Fiche obligatoire 9 champs + admission par curateur | `client-acquisition-plan.md` | FAIT |
| §4.3 Dispute/responsabilité | "Prime contractor nécessaire + mécanisme de litige" | SAS = prime contractor + dispute resolution 3 niveaux | `legal-workstream.md` | FAIT |
| §5 Anti-sybil | "Communauté fermée, identité vérifiée, transparence incentives" | 3 règles anti-gaming + lancement sur invitation | `client-acquisition-plan.md` | FAIT |
| §6.A Contrat social | "Pacte contributeurs : droits, devoirs, confidentialité" | Pacte 6 sections | `legal-workstream.md` | FAIT |
| §6.B Qualité Parcours B | "Curation gate minimal obligatoire" | Cf. §4.1 ci-dessus | — | FAIT |
| §6.C IP Registry plus tôt | "MVP licence off-chain + hash on-chain" | Exactement le mécanisme choisi | `legal-workstream.md` | FAIT |
| §6.D Ne pas survendre blockchain | "Blockchain = preuve, pas religion" | Intégré dans le reframing enterprise | `client-acquisition-plan.md` | FAIT |
| §7 Test de réalité | "5 critères enterprise (SI, responsabilité, IP, qualité, UX)" | Test de réalité intégré comme filtre de qualification | `client-acquisition-plan.md` | FAIT |

---

## Questions Ouvertes (pour vagues 2-3)

| # | Question | Décision attendue |
|---|----------|-------------------|
| Q1 | Le modèle de pricing (5% client, 0% consultant) est-il le bon ? Faut-il tester 3-7% ? | Vague 2/3 ou test A/B M3 |
| Q2 | Le Parcours C (licensing) doit-il être lancé dès M4 ou attendre la validation PMF M6 ? | Vague 2/3 ou Gate 2 |
| Q3 | Quel standard REP token ? ERC-5484 strict ou implémentation custom ? | Vague 2/3 ou spec technique |
| Q4 | Faut-il un "label qualité" visible côté client (ex: "DAO Verified") ou rester invisible ? | Vague 2/3 ou test utilisateur |
| Q5 | Comment gérer le cas d'un agent IA qui outperforms les consultants humains ? Impact sur la communauté ? | Vague 2/3 ou discussion gouvernance |

---

## Versions des Livrables

| Document | v1.0 | v2.0 (vague 1) | Delta |
|----------|------|-----------------|-------|
| `legal-workstream.md` | 214 lignes | ~380 lignes | +IP licensing, pacte contributeurs, prime contractor, dispute resolution, 3 risques additionnels, budget +2-4k |
| `client-acquisition-plan.md` | 393 lignes | ~520 lignes | +positionnement enterprise, test de réalité, curation gate, Agent Listing Standard, anti-sybil |
| `financial-model.md` | 313 lignes | ~330 lignes | +3 postes de coûts, ajustement one-shot +2-4k, 3 scénarios catastrophe ajoutés |
| `REMEDIATION-PLAN.md` | — | Inchangé (vague 1 n'impactait pas le backend security) | — |

---

**En attente** : Vagues 2 et 3 de commentaires pour compléter l'analyse.

**Version** : 1.0.0
**Date** : 2026-02-17
