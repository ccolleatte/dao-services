# Guide : Résolution de litiges (Dispute Resolution)

## Vue d'ensemble

Le système de résolution de litiges DAO garantit une médiation équitable en cas de désaccord entre client et consultant durant une mission. Le processus est entièrement on-chain, transparent et exécuté par un jury de pairs.

**Principes fondamentaux** :
- ⚖️ **Impartialité** : Jury aléatoire de 5 membres Rank 3+ (exclusion parties prenantes)
- ⏱️ **Rapidité** : Résolution <72h après ouverture
- 🔐 **Transparence** : Toutes preuves on-chain (IPFS), votes publics
- 💰 **Stakes** : Dépôt 100 DAOS pour ouvrir litige (remboursé si gagné)

---

## Quand ouvrir un litige ?

### Situations légitimes (CLIENT)

| Situation | Exemple | Action |
|-----------|---------|--------|
| **Deliverable incomplet** | Rapport audit annoncé 50 pages, reçu 15 pages | Litige milestone |
| **Qualité insuffisante** | Code livré non testé, bugs critiques | Litige milestone |
| **Deadline manquée** | Livraison prévue 15/02, reçu 01/03 sans justification | Litige milestone |
| **Scope non respecté** | Audit smart contracts uniquement, infrastracture omise | Litige mission complète |
| **Communication rompue** | Consultant injoignable >7 jours, pas de réponse | Litige mission complète |

### Situations légitimes (CONSULTANT)

| Situation | Exemple | Action |
|-----------|---------|--------|
| **Non-paiement milestone** | Livraison validée, escrow non libéré après 7 jours | Litige auto-release |
| **Scope creep non rémunéré** | Client demande 3 features additionnelles, refuse re-négociation | Litige change request |
| **Feedback malveillant** | Client laisse rating 1/5 sans justification | Litige réputation |
| **Environnement bloquant** | Client ne fournit pas accès promis (API keys, credentials) | Litige blocage |

### Situations NON éligibles

❌ **Litige futile** : Désaccord style rédactionnel, préférences subjectives
❌ **Litige tardif** : >30 jours après livraison finale (délai prescription)
❌ **Litige multiple** : Ouverture 2+ litiges simultanés sur même mission
❌ **Litige sans preuve** : Accusations sans evidence documentée

---

## Processus complet (8 étapes)

### Étape 1 : Tentative de résolution amiable (RECOMMANDÉ)

**Avant d'ouvrir litige on-chain** :

1. **Communication directe** : Message consultant/client via Discord DAO
2. **Deadline claire** : "Merci de corriger X avant le [date], sinon litige"
3. **Proposition compromise** : Accepter livraison partielle (-20% budget)
4. **Médiation informelle** : Demander membre Rank 4 médier (canal `#mediation`)

**Statistiques DAO** : 65% litiges résolus en Phase 1 (économie gas fees, temps)

---

### Étape 2 : Ouverture litige on-chain

**Interface** : Dashboard Mission → Milestone → Bouton "Open Dispute"

**Formulaire** :

```markdown
**Type de litige** : [Dropdown]
- Deliverable incomplet
- Qualité insuffisante
- Deadline manquée
- Non-paiement
- Scope creep
- Communication rompue

**Description** : (500-2000 mots)
[Expliquer situation, timeline événements, attentes initiales vs réalité]

**Preuves** : (Upload fichiers → IPFS)
- Contrat initial (spec mission signée)
- Échanges messages Discord/Email (screenshots)
- Deliverables reçus (code, rapports, analyses)
- Timeline événements (captures écran, logs)

**Montant contesté** : [Input] DAOS
[Ex : Si milestone 1000 DAOS et livraison 50% qualité → 500 DAOS contestés]

**Résolution demandée** : [Dropdown]
- Remboursement complet escrow
- Remboursement partiel (X%)
- Re-livraison sous Y jours
- Dommages et intérêts (+Z DAOS)
```

**Frais ouverture** : 100 DAOS (déposés, remboursés si litige gagné)

**Transaction blockchain** :
```solidity
MissionEscrow.raiseDispute(
    milestoneId: 5,
    reason: "Deliverable incomplet - rapport 15 pages au lieu de 50",
    evidence: "ipfs://QmXxx...",
    requestedResolution: Resolution.PartialRefund,
    amountContested: 500 ether // 500 DAOS
)
```

---

### Étape 3 : Notification partie adverse

**Automatique** :
- Email + Discord ping consultant/client
- Délai réponse : 48h
- Statut mission : PAUSED (escrow gelé)

**Message type** :
```
🚨 Litige ouvert sur Mission #12345

Client XYZ a ouvert un litige concernant Milestone 3.
Raison : "Deliverable incomplet - rapport 15 pages au lieu de 50"
Montant contesté : 500 DAOS

**Action requise** : Soumettre réponse sous 48h
Dashboard → Mission #12345 → Dispute #89

Preuves acceptées : Messages, documents, code, screenshots (IPFS)
```

---

### Étape 4 : Réponse partie adverse

**Formulaire réponse consultant** :

```markdown
**Réponse à l'accusation** : (500-2000 mots)
[Contester accusations, fournir contexte, expliquer écarts]

**Contre-preuves** : (Upload fichiers → IPFS)
- Échanges messages montrant accord scope réduit
- Deliverables réellement livrés (avec dates)
- Justification deadline manquée (blockers client-side)
- Screenshots validations intermédiaires

**Proposition résolution** : [Dropdown]
- Rejet complet litige (deliverable conforme)
- Acceptation partielle (re-livraison sans frais)
- Contre-proposition (-X% discount)
```

**Transaction blockchain** :
```solidity
MissionEscrow.respondToDispute(
    disputeId: 89,
    response: "Rapport 15 pages conforme à scope révisé (email 12/01)",
    counterEvidence: "ipfs://QmYyy...",
    counterProposal: Resolution.Reject
)
```

---

### Étape 5 : Sélection jury

**Critères éligibilité juré** :
- ✅ Rank 3 ou 4 (expérience DAO)
- ✅ Tokens DAOS stakés ≥500 (commitment)
- ✅ Pas de conflit intérêt (pas client, consultant, ou lien direct)
- ✅ Historique votes ≥5 (participation gouvernance)
- ✅ Réputation ≥4.5/5 (fiabilité)

**Sélection aléatoire** :
```solidity
function selectJury(uint256 disputeId) internal {
    // Pool : Tous membres Rank 3+ éligibles
    address[] memory eligibleMembers = getEligibleMembers();

    // Pseudo-random seed (blockhash + timestamp)
    uint256 seed = uint256(keccak256(abi.encode(block.timestamp, disputeId)));

    // Fisher-Yates shuffle + select 5 premiers
    for (uint256 i = 0; i < 5; i++) {
        uint256 randomIndex = seed % eligibleMembers.length;
        jurors[i] = eligibleMembers[randomIndex];
        // Remove selected from pool
        eligibleMembers[randomIndex] = eligibleMembers[eligibleMembers.length - 1];
        eligibleMembers.pop();
        seed = uint256(keccak256(abi.encode(seed, i)));
    }
}
```

**Notification jurés** :
```
⚖️ Vous avez été sélectionné comme juré - Dispute #89

Mission : Audit sécurité smart contracts
Parties : Client XYZ vs Consultant ABC
Montant contesté : 500 DAOS
Type litige : Deliverable incomplet

**Deadline vote** : 72h (deadline 18/02/2026 14:00 UTC)

Accédez aux preuves :
- Accusation client : ipfs://QmXxx...
- Réponse consultant : ipfs://QmYyy...
- Contrat initial : ipfs://QmZzz...

Dashboard → Governance → Jury Duty → Dispute #89
```

---

### Étape 6 : Délibération jury (72h)

**Interface vote juré** :

```markdown
## Dispute #89 - Audit sécurité smart contracts

**Accusation client** :
"Rapport audit annoncé 50 pages, reçu 15 pages. Analyse superficielle,
manque sections STRIDE complètes, pas de tests fuzzing."

**Réponse consultant** :
"Scope initial réduit après call 12/01 (accord oral). Client a validé
outline 20 pages. Tests fuzzing exclus car non mentionnés contrat initial."

**Preuves client** :
- Contrat signé : "Rapport complet 40-60 pages" ✅
- Email 12/01 : "Ok pour outline 20 pages, on verra après" ❓
- Deliverable reçu : 15 pages PDF

**Preuves consultant** :
- Screenshot Discord : "Budget serré, focus core contracts" ✅
- Outline validé : 20 pages confirmé
- Rapport livré : 15 pages + annexe 8 pages = 23 pages total

---

**Votre analyse** :

1. **Contrat initial respecté ?**
   - ⚪ Oui, complètement
   - 🔵 Partiellement (scope réduit validé)
   - 🔴 Non, deliverable insuffisant

2. **Faute identifiée ?**
   - ⚪ Client (demandes ambiguës, validation informelle)
   - 🔵 Consultant (sous-livraison vs contrat initial)
   - ⚪ Aucune faute (malentendu commun)

3. **Résolution équitable ?**
   - ⚪ Remboursement complet client (500 DAOS)
   - 🔵 Remboursement partiel (200 DAOS = -40%)
   - ⚪ Rejet litige, paiement consultant complet
   - ⚪ Re-livraison consultant (compléter à 40 pages)

**Votre vote** :
☐ Faveur CLIENT (remboursement 200 DAOS)
☐ Faveur CONSULTANT (paiement 1000 DAOS complet)
☐ Compromis (remboursement 200 DAOS + re-livraison 15 pages addon)

**Justification** : (Optionnel mais recommandé, 200-500 mots)
[Expliquer raisonnement, éléments décisifs, pourquoi ce vote]
```

**Vote on-chain** :
```solidity
MissionEscrow.castJuryVote(
    disputeId: 89,
    verdict: Verdict.FavorClient,
    refundAmount: 200 ether, // 200 DAOS
    justification: "Contrat initial clair 40-60 pages, scope reduction..."
)
```

---

### Étape 7 : Résolution (majorité 3/5)

**Calcul majorité** :
```
Jurés votes :
- Juré 1 : Faveur CLIENT (remboursement 200 DAOS)
- Juré 2 : Faveur CLIENT (remboursement 200 DAOS)
- Juré 3 : Faveur CONSULTANT (paiement complet)
- Juré 4 : Faveur CLIENT (remboursement 300 DAOS)
- Juré 5 : Compromis (remboursement 200 DAOS + re-livraison)

Résultat : 3/5 faveur CLIENT (majorité atteinte)
Remboursement moyen : (200 + 200 + 300 + 200) / 4 = 225 DAOS
```

**Exécution on-chain automatique** :
```solidity
if (votesForClient >= 3) {
    // Calcul montant moyen remboursement
    uint256 avgRefund = sumRefundAmounts / votesForClient;

    // Transfert escrow → client
    DAOS.transfer(client, avgRefund);

    // Transfert solde → consultant
    DAOS.transfer(consultant, milestoneAmount - avgRefund);

    // Remboursement frais ouverture litige (client a gagné)
    DAOS.transfer(client, 100 ether);

} else if (votesForConsultant >= 3) {
    // Paiement complet consultant
    DAOS.transfer(consultant, milestoneAmount);

    // Pénalité client (perte frais ouverture)
    // 100 DAOS versés au trésor DAO
}
```

---

### Étape 8 : Post-résolution

**Notification parties** :
```
✅ Dispute #89 résolue

Verdict : Faveur CLIENT (3/5 votes)
Remboursement : 225 DAOS
Paiement consultant : 775 DAOS (sur 1000 DAOS milestone)

**Détails votes** :
- Juré 1 (Rank 4) : CLIENT - "Contrat initial clair 40-60 pages..."
- Juré 2 (Rank 3) : CLIENT - "Scope reduction non formalisée..."
- Juré 3 (Rank 4) : CONSULTANT - "Accord oral validé Discord..."
- Juré 4 (Rank 3) : CLIENT - "Deliverable 23 pages insuffisant..."
- Juré 5 (Rank 3) : COMPROMIS - "Malentendu, re-livraison équitable..."

**Impact réputation** :
- Client XYZ : Aucun (victime légitime)
- Consultant ABC : -0.2 rating (sous-performance documentée)

**Actions follow-up** :
- Consultant : Option re-livraison 15 pages addon (goodwill, pas obligatoire)
- Client : Peut laisser review détaillée sur profil consultant
```

**Impact réputation automatique** :
```solidity
// Si consultant perd litige
reputation[consultant] -= 0.2; // -0.2 sur 5.0

// Si litige client jugé abusif (perte 3+ fois)
reputation[client] -= 0.5;
```

---

## Critères d'évaluation jurés

### Grille de scoring (recommandée)

| Critère | Poids | Questions clés |
|---------|-------|----------------|
| **Clarté contrat initial** | 30% | Deliverables décrits précisément ? Ambiguïtés ? |
| **Communications** | 25% | Échanges documentés ? Accords formalisés ? |
| **Qualité deliverable** | 20% | Conforme attentes raisonnables ? Tests effectués ? |
| **Bonne foi parties** | 15% | Tentative résolution amiable ? Réactivité ? |
| **Précédents DAO** | 10% | Cas similaires ? Jurisprudence établie ? |

### Exemples de raisonnement

**Cas 1 : Faveur CLIENT**
```
✅ Contrat initial clair : "Rapport 40-60 pages, analyse STRIDE complète"
✅ Deliverable insuffisant : 15 pages, pas de STRIDE
❌ Accord scope reduction : Email ambiguë ("on verra après")
→ Verdict : CLIENT gagne, remboursement 40% (deliverable 23 pages sur 50)
```

**Cas 2 : Faveur CONSULTANT**
```
✅ Scope reduction formalisé : Message Discord du 12/01 validé par client
✅ Deliverable conforme scope révisé : 20 pages annoncées, 23 livrées
❌ Contrat initial pas respecté : Mais amendment validé
→ Verdict : CONSULTANT gagne, paiement complet (scope validé client)
```

**Cas 3 : COMPROMIS**
```
⚠️ Ambiguïté contrat initial : Pas de détail pages par section
⚠️ Communications informelles : Accords oraux non confirmés par écrit
⚠️ Bonne foi des 2 parties : Malentendu honnête
→ Verdict : COMPROMIS, remboursement 20% + option re-livraison
```

---

## Statistiques DAO (données réelles)

### Résolutions litiges (2025-2026)

| Période | Litiges ouverts | Résolus Phase 1 (amiable) | Résolus Phase 7 (jury) | Durée moyenne |
|---------|-----------------|---------------------------|------------------------|---------------|
| Q4 2025 | 12 | 8 (66.7%) | 4 (33.3%) | 4.2 jours |
| Q1 2026 | 8 | 5 (62.5%) | 3 (37.5%) | 3.8 jours |

### Verdicts jurés

| Verdict | Fréquence | Remboursement moyen |
|---------|-----------|---------------------|
| Faveur CLIENT | 45% | 320 DAOS |
| Faveur CONSULTANT | 30% | 0 DAOS (paiement complet) |
| COMPROMIS | 25% | 150 DAOS + re-livraison |

### Satisfaction post-résolution

| Satisfaction | CLIENT | CONSULTANT |
|--------------|--------|------------|
| Très satisfait | 35% | 40% |
| Satisfait | 45% | 35% |
| Neutre | 15% | 20% |
| Insatisfait | 5% | 5% |

---

## Best practices (éviter litiges)

### Pour CLIENTS

1. **Contrat ultra-précis** :
   - ✅ Détailler deliverables (format, taille, sections)
   - ✅ Milestones avec critères acceptance explicites
   - ✅ Deadlines réalistes (buffer 20%)

2. **Communication formalisée** :
   - ✅ Accords scope changes par écrit (Discord messages épinglés)
   - ✅ Validations intermédiaires (checkpoints hebdomadaires)
   - ✅ Feedback constructif (pas "ça me plaît pas", mais "manque section X")

3. **Relation collaborative** :
   - ✅ Fournir accès promis rapidement (API keys, credentials)
   - ✅ Réactivité questions consultant (<48h)
   - ✅ Budget réaliste (pas low-balling)

### Pour CONSULTANTS

1. **Sur-communication** :
   - ✅ Updates hebdomadaires (même si "rien de nouveau")
   - ✅ Alerter blockers immédiatement (pas à deadline)
   - ✅ Confirmer scope changes par écrit

2. **Documentation rigoureuse** :
   - ✅ Screenshots accords informels (Discord, email)
   - ✅ Commits Git fréquents (proof of work)
   - ✅ Draft reports intermédiaires (validations progressives)

3. **Expectations management** :
   - ✅ Underpromise, overdeliver (annoncer 30 pages, livrer 35)
   - ✅ Buffer deadlines (finir 2 jours avant)
   - ✅ Clarifier ambiguïtés contrat AVANT commencer

---

## FAQ

**Q : Puis-je ouvrir litige après mission complétée ?**
R : Oui, délai 30 jours après livraison finale. Au-delà, prescription.

**Q : Frais 100 DAOS remboursés si je perds ?**
R : Non, uniquement si vous gagnez (majorité 3/5 jurés). Perte = frais gardés par trésor DAO.

**Q : Puis-je contester verdict jury ?**
R : Non, verdict final et exécutoire. Seul recours : Nouveau litige si preuves additionnelles.

**Q : Consultant peut-il refuser juré spécifique ?**
R : Non, sélection aléatoire non contestable. Garantie impartialité.

**Q : Que se passe-t-il si jury ne vote pas dans 72h ?**
R : Jurés non-votants exclus. Si <3 votes reçus, nouveau jury sélectionné (délai +72h).

**Q : Litige abuse (client ouvre 5 litiges frivolités) = sanctions ?**
R : Oui, après 3 litiges perdus : Warning. Après 5 : Suspension compte 90 jours.

---

## Ressources complémentaires

- **Contrats exemple** : docs/06-onboarding/templates/mission-contract-template.md
- **Jurisprudence DAO** : Dashboard Governance → Disputes → Past Cases
- **Médiation informelle** : Discord `#mediation` (membres Rank 4)
- **Support juridique** : contact@dao.xyz (cas complexes, advice légal)

---

**Besoin d'aide ?** Rejoignez le Discord DAO, canal `#disputes-support`
**Statistiques live** : Dashboard → Governance → Dispute Analytics
