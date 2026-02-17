# Synthèse des Commentaires Stratégiques — Intégration dans les Livrables

**Date** : 2026-02-17
**Source** : Revue stratégique externe (3 vagues de commentaires)
**Statut** : 3 vagues intégrées

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

## Matrice d'Impact : Vague 2

La vague 2 a apporté **5 renforcements structurels** orientés "ETI readiness" : packaging qualité et onboarding responsable.

### Points Intégrés (Vague 2)

| # | Renforcement | Sévérité | Correction | Document modifié |
|---|-------------|----------|------------|------------------|
| **R1** | Vendre des "produits de connaissance" avec DoD explicite | HAUTE | Definition of Done par type de livrable (5 types standardisés) | `client-acquisition-plan.md` §Packaging |
| **R2** | Quality Card avec critères objectivables (avant achat) | HAUTE | 4 critères (traçabilité, clarté, adéquation, réutilisabilité) + métriques de robustesse | `client-acquisition-plan.md` §Quality Card |
| **R3** | Validation champion métier (livrables à enjeu) | HAUTE | Gate 2b ajoutée au pipeline de curation (champion valide les livrables sensibles) | `client-acquisition-plan.md` §Curation Gate |
| **R4** | Option "human refinement" systématique (Parcours B) | HAUTE | 3 niveaux de prix (IA brut / IA+humain / 100% humain) comme convertisseur ETI | `client-acquisition-plan.md` §Human Refinement |
| **R5** | Mesurer robustesse (rework, répétabilité) pas seulement beauté | MOYENNE | 4 métriques de robustesse ajoutées (taux rework, répétabilité, traçabilité, adéquation) | `client-acquisition-plan.md` §Quality Card |

---

## Matrice d'Impact : Vague 3

La vague 3 a formalisé le **modèle Guild Métier** et l'a instancié sur "Org & SI".

### Points Intégrés (Vague 3)

| # | Renforcement | Sévérité | Correction | Document modifié |
|---|-------------|----------|------------|------------------|
| **G1** | Guild Métier comme unité organisationnelle | CRITIQUE | Guild = référentiel qualité + champions + animation. Pilote "Org & SI" avec 4 lignes de produits. | `client-acquisition-plan.md` §Guild Métier |
| **G2** | Guild Quality Rubric (grille d'évaluation unique) | HAUTE | 4 critères notés 0-3 (conformité, structure, traçabilité, opérabilité). Score max 12. | `client-acquisition-plan.md` §Rubric |
| **G3** | Onboarding 3 paliers (N0 Coopté → N1 Vérifié → N2 Certifié) | HAUTE | Pipeline d'entrée avec tests standardisés par ligne de produit | `client-acquisition-plan.md` §Onboarding 3 Paliers |
| **G4** | Sponsor/Vouch avec réputation symétrique | HAUTE | Sponsor expose sa REP pendant 3 missions de l'entrant. Gains/pertes symétriques. | `client-acquisition-plan.md` §Sponsor/Vouch |
| **G5** | Guild Acceptance Board (GAB) | MOYENNE | 3-5 membres N2, valide promotions N2 + litiges + évolution rubric | `client-acquisition-plan.md` §GAB |
| **G6** | Guild Operator (animation) | MOYENNE | 1 personne : weekly review, catalogue, onboarding, scoreboard, retro | `client-acquisition-plan.md` §Guild Operator |
| **G7** | Anti-complaisance curation | MOYENNE | Audit aléatoire 1/10 livrables par le GAB | `client-acquisition-plan.md` §Anti-Gaming |

### Impact Financier des Corrections (Vagues 2+3)

| Correction | Coût one-shot | Coût récurrent/mois | Impact sur breakeven |
|------------|--------------|---------------------|---------------------|
| R1-R2 : DoD + Quality Card | 0 EUR (design) | 0 EUR | Positif (meilleure conversion ETI) |
| R3 : Champion métier | 0 EUR | Inclus dans commission curateur | Aucun |
| R4 : Human refinement | 0 EUR | 0 EUR (génère du revenu additionnel) | **Positif** (+30-50% GMV/mission convertie) |
| G1 : Guild templates | 500-1 000 EUR | 85-170 EUR (amort.) | Négligeable |
| G3-G4 : Tests onboarding | 0 EUR (temps fondateurs) | 0 EUR | Aucun |
| G6 : Guild Operator (M3+) | 0 EUR | 500-1 000 EUR | +2-4 semaines |
| **TOTAL V2+V3** | **500-1 000 EUR** | **~600-1 200 EUR/mois (M3+)** | **Net positif grâce au human refinement** |

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
| §4.1 Qualité IA | "Curation gate obligatoire, pas optionnelle" | Pipeline de curation 2 gates (auto + humain) + champion métier (Gate 2b) | `client-acquisition-plan.md` | FAIT |
| §4.2 Anti-GPT-wrapper | "Agent Listing Standard avec tests minimaux" | Fiche obligatoire 9 champs + admission par curateur | `client-acquisition-plan.md` | FAIT |
| §4.3 Dispute/responsabilité | "Prime contractor nécessaire + mécanisme de litige" | SAS = prime contractor + dispute resolution 3 niveaux | `legal-workstream.md` | FAIT |
| §5 Anti-sybil | "Communauté fermée, identité vérifiée, transparence incentives" | Modèle Guild avec 5 règles anti-gaming + audit aléatoire | `client-acquisition-plan.md` | FAIT |
| §6.A Contrat social | "Pacte contributeurs : droits, devoirs, confidentialité" | Pacte 6 sections | `legal-workstream.md` | FAIT |
| §6.B Qualité Parcours B | "Curation gate minimal obligatoire" | Cf. §4.1 + champion métier + human refinement | — | FAIT |
| §6.C IP Registry plus tôt | "MVP licence off-chain + hash on-chain" | Exactement le mécanisme choisi | `legal-workstream.md` | FAIT |
| §6.D Ne pas survendre blockchain | "Blockchain = preuve, pas religion" | Intégré dans le reframing enterprise | `client-acquisition-plan.md` | FAIT |
| §7 Test de réalité | "5 critères enterprise (SI, responsabilité, IP, qualité, UX)" | Test de réalité intégré comme filtre de qualification | `client-acquisition-plan.md` | FAIT |

### Vague 2 — Complète

| § Commentaire | Recommandation verbatim | Action prise | Livrable | Statut |
|---------------|------------------------|-------------|----------|--------|
| §A.1 Produits de connaissance | "Transformer chaque offre en produit avec DoD explicites" | DoD par type de livrable (5 types) | `client-acquisition-plan.md` | FAIT |
| §A.2 Quality Card | "Afficher critères objectivables sous forme de Quality Card" | Quality Card 4 critères + métriques de robustesse | `client-acquisition-plan.md` | FAIT |
| §A.3 Champion métier | "Double validation : auto + champion métier pour livrables à enjeu" | Gate 2b (champion) ajoutée au pipeline de curation | `client-acquisition-plan.md` | FAIT |
| §B.1 Paliers d'entrée | "Invité → Vérifié → Certifié, sans token au MVP" | 3 paliers (N0/N1/N2) avec tests standardisés | `client-acquisition-plan.md` | FAIT |
| §B.2 Sponsor/Vouch | "Sponsor met sa réputation en garantie pendant 3 missions" | Mécanisme symétrique (+5/-10 REP) avec limite de parrainage | `client-acquisition-plan.md` | FAIT |
| §B.3 REP soulbound | "S'appuyer sur ERC-5484 consensuel" | Confirmé. Abstrait côté ETI (badges, niveaux). | `client-acquisition-plan.md` | FAIT |
| §B.4 Qualif par preuves | "Challenge brief standardisé + grille objective" | Tests par ligne de produit (Diagnostic, TOM, RACI) | `client-acquisition-plan.md` | FAIT |
| §B.5 Robustesse | "Mesurer répétabilité, rework, traçabilité — pas beauté" | 4 métriques ajoutées (rework, répétabilité, traçabilité, adéquation) | `client-acquisition-plan.md` | FAIT |
| Rec. 5 | "Option human refinement systématique sur Parcours B" | 3 niveaux de prix, option convertisseur ETI | `client-acquisition-plan.md` | FAIT |

### Vague 3 — Complète

| § Commentaire | Recommandation verbatim | Action prise | Livrable | Statut |
|---------------|------------------------|-------------|----------|--------|
| §1 Guild métier | "Une guild par métier avec champions + rituels" | Guild pilote "Org & SI" avec 4 lignes de produits | `client-acquisition-plan.md` | FAIT |
| §2.1 Pipeline d'entrée | "3 niveaux : Coopté / Vérifié / Certifié Guild" | Cf. Vague 2 §B.1 (fusionné) | — | FAIT |
| §2.2 Sponsor/Vouch | "Effets réputationnels symétriques" | Cf. Vague 2 §B.2 (fusionné avec mécanisme détaillé) | — | FAIT |
| §3.1 Grille qualité | "Rubric 4 critères : conformité, structure, traçabilité, opérabilité" | Guild Quality Rubric notée 0-3 × 4 critères = score /12 | `client-acquisition-plan.md` | FAIT |
| §3.2 Champion métier | "Champion valide les 10 premiers entrants + livrables à enjeu" | Intégré dans Gate 2b + GAB | `client-acquisition-plan.md` | FAIT |
| §4 Acceptance Board | "Guild Acceptance Board (3-5 personnes)" | GAB défini : composition, attributions, quorum | `client-acquisition-plan.md` | FAIT |
| §5 Community Ops | "Guild Operator : rituels, catalogue, scoreboard" | Rôle défini : 5 rituels + coûts estimés | `client-acquisition-plan.md` | FAIT |
| §6 Mapping Parcours | "La guild renforce Parcours B (qualité) et C (curation)" | Confirmé dans la structure globale | — | FAIT |
| Pack MVP | "Démarrer avec Diagnostic SI & Gouvernance 360" | Ligne 1 identifiée comme pack de lancement | `client-acquisition-plan.md` | FAIT |

---

## Questions Ouvertes Restantes

| # | Question | Source | Décision attendue |
|---|----------|--------|-------------------|
| Q1 | Le modèle de pricing (5% client, 0% consultant) est-il le bon ? | Vague 1 | Test A/B M3 |
| Q2 | Le Parcours C (licensing) doit-il être lancé dès M4 ou attendre PMF M6 ? | Vague 1 | Gate 2 |
| Q3 | Standard REP token ? ERC-5484 strict ou custom ? | Vague 1+2 | Spec technique M2 |
| Q4 | Faut-il un "label qualité" visible côté client ? | Vague 1 | Test utilisateur M3 |
| Q5 | Comment gérer un agent IA qui outperforms les humains ? | Vague 1 | Discussion gouvernance M6+ |
| Q6 | Combien de guilds lancer en parallèle ? "Org & SI" seule ou 2 guilds M0-M3 ? | Vague 3 | Décision fondateurs |
| Q7 | Le Guild Operator est-il un rôle bénévole ou rémunéré dès M1 ? | Vague 3 | Décision budget M1 |
| Q8 | Quelle proportion de livrables IA passe par human refinement vs. brut curé ? | Vague 2 | Données terrain M3 |

---

## Versions des Livrables

| Document | v1.0 | v2.0 (vague 1) | v3.0 (vagues 1+2+3) | Delta v2→v3 |
|----------|------|-----------------|---------------------|-------------|
| `legal-workstream.md` | 214 lignes | ~380 lignes | ~380 lignes (inchangé) | Vagues 2+3 n'impactent pas le juridique |
| `client-acquisition-plan.md` | 393 lignes | ~520 lignes | ~780 lignes | +Quality Card, DoD, Guild Org&SI, Rubric, 3 Paliers, Sponsor/Vouch, GAB, Guild Operator, Human Refinement, Champion métier |
| `financial-model.md` | 313 lignes | ~330 lignes | ~340 lignes | +Guild Operator coûts, templates one-shot, human refinement en sensibilité |
| `REMEDIATION-PLAN.md` | — | Inchangé | Inchangé | — |
| `feedback-synthesis.md` | — | ~100 lignes | ~250 lignes | +matrices vagues 2+3, traçabilité complète |

---

## Verdict Global : État de la Proposition Après 3 Vagues

### Ce qui est solide

1. **Trilogie A/B/C** : confirmée par les 3 vagues comme le vrai différenciateur
2. **Blockchain invisible** : aligné avec l'exigence enterprise
3. **Modèle Guild** : transforme une "marketplace" en un "réseau d'expertise structuré"
4. **Quality Card + Rubric** : rend la qualité objectivable et comparable (clé pour ETI)
5. **Prime contractor SAS** : résout la question de responsabilité (critique pour signature)

### Ce qui reste à valider sur le terrain

1. **Le taux de conversion human refinement** : quel % de missions IA sont "upgradées" ?
2. **L'attractivité du modèle Sponsor/Vouch** : les contributeurs acceptent-ils le risque REP ?
3. **La scalabilité du Guild Operator** : 1 personne suffit-elle à M6 avec 50 missions/mois ?
4. **Le prix du Pack #1 Diagnostic** : 8-15k EUR est-il compétitif vs. cabinets classiques ?
5. **Le seuil de rubric (8/12)** : trop haut → pas assez d'entrants. Trop bas → qualité dégradée.

### Le test ultime (inchangé depuis vague 1)

> Une entreprise peut acheter un livrable/mission :
> 1. sans changer son SI
> 2. avec une responsabilité claire
> 3. avec des droits IP non ambigus
> 4. avec une qualité fiable
> 5. et avec une expérience aussi simple qu'un SaaS

Les 3 vagues ont renforcé chacun de ces 5 points. La proposition est **enterprise-ready sur le papier**. La validation terrain (Phase 0, Semaine 1-4) dira si elle l'est en pratique.

---

**Version** : 3.0.0
**Date** : 2026-02-17
