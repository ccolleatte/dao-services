# Système de Quality Assurance - Guide Utilisateur

> **Garantir que ce qui est livré correspond à ce qui a été commandé**

## 🎯 Pourquoi ce système ?

Dans un marketplace de services, la confiance est essentielle. Notre système garantit :

- ✅ **Protection clients** : Vous payez uniquement pour des livrables conformes
- ✅ **Protection consultants** : Vos livrables sont évalués de manière équitable
- ✅ **Transparence totale** : Critères définis à l'avance, validation collective
- ✅ **Résolution rapide** : Arbitrage en 7 jours maximum (vs. mois en justice)

---

## 📋 Les 3 piliers du système

### 1. Conformité légale (KYC)

**Pour qui ?** Tous les consultants

**Pourquoi ?** Garantir que les consultants respectent les obligations légales (sécurité sociale, fiscalité, autorisation de travail).

**Comment ça marche ?**
- Avant de postuler à certaines missions, vous devez fournir des attestations vérifiées
- Les documents sont stockés de manière sécurisée (seul le hash est on-chain, conformité GDPR)
- Les attestations ont une durée de validité (3 mois pour KBIS, 6 mois pour URSSAF, etc.)

**Attestations courantes** :
- 🇫🇷 **France** : KBIS (<3 mois), URSSAF (<6 mois), RC Pro
- 🇨🇦 **Québec** : NEQ, Relevé Revenu Québec, Assurance responsabilité
- 🇨🇭 **Suisse** : Extrait RC, Attestation AVS, Assurance RC

---

### 2. Escrow avec Milestones

**Pour qui ?** Clients et consultants

**Pourquoi ?** Paiement progressif basé sur des livrables vérifiables.

#### Comment créer une mission avec milestones (Client)

**Étape 1 : Définir les milestones**

Décomposez votre projet en étapes mesurables avec critères d'acceptation clairs.

**Exemple** : Développement site web (Budget total : 10 000 €)

| Milestone | Description | Critères d'acceptation | Budget |
|-----------|-------------|------------------------|--------|
| **Phase 1** | Maquettes design | Wireframes desktop + mobile + charte graphique validée | 30% (3 000 €) |
| **Phase 2** | Développement frontend | Homepage + 5 pages principales fonctionnelles, responsive, tests cross-browser | 40% (4 000 €) |
| **Phase 3** | Tests & déploiement | Site en production, 0 bug bloquant, performances >90/100 Lighthouse | 30% (3 000 €) |

**Étape 2 : Verrouiller les fonds**

Lors de la création de la mission, le budget total (10 000 €) est verrouillé en escrow. Vous ne pouvez plus retirer ces fonds, mais ils ne sont pas encore payés au consultant.

**Étape 3 : Validation progressive**

Pour chaque milestone :
1. Le consultant soumet le livrable (lien IPFS vers fichiers/docs)
2. Vous avez 7 jours pour valider ou rejeter
3. Si validation ✅ → Paiement automatique de la tranche (ex: 3 000 €)
4. Si rejet ❌ → Le consultant peut corriger OU initier une dispute

#### Comment soumettre un livrable (Consultant)

**Étape 1 : Préparer votre livrable**

- Créez un package complet (fichiers, documentation, tests)
- Uploadez sur IPFS (stockage décentralisé permanent)
- Obtenez le hash IPFS (ex: `QmX1234...`)

**Étape 2 : Soumettre**

- Cliquez "Soumettre livrable" pour le milestone
- Collez le hash IPFS
- Ajoutez un commentaire expliquant ce qui a été livré

**Étape 3 : Attendre validation**

- Le client a 7 jours pour valider
- Si validation ✅ → Vous recevez le paiement automatiquement
- Si rejet ❌ → Vous recevez les raisons du rejet

---

### 3. Arbitrage en cas de dispute

**Pour qui ?** Consultants (si rejet injustifié)

**Pourquoi ?** Un tiers neutre décide si le livrable est conforme.

#### Processus d'arbitrage (7 jours)

**Étape 1 : Initier la dispute** (Consultant)

Si vous pensez que le rejet est injustifié :
1. Cliquez "Contester le rejet"
2. Expliquez pourquoi vous avez respecté les critères d'acceptation
3. Fournissez des preuves (screenshots, tests, documentation)

**Coût** : Gratuit pour initier. Si vous perdez, votre score de reputation est impacté.

**Étape 2 : Sélection des arbitres** (Automatique)

- 3 arbitres sont sélectionnés parmi les membres DAO avec **rank ≥3**
- Les arbitres ont une expertise reconnue (≥5 missions réussies, reputation >80%)
- Sélection aléatoire pour éviter les conflits d'intérêts

**Étape 3 : Vote des arbitres** (7 jours)

Chaque arbitre étudie :
- Les critères d'acceptation initiaux
- Le livrable soumis
- Les arguments du client et du consultant

Vote binaire :
- ✅ **Accepter** : Le livrable respecte les critères
- ❌ **Rejeter** : Le livrable ne respecte pas les critères

**Étape 4 : Résolution** (Automatique)

- **Majorité 2/3** : Si 2 arbitres votent "Accepter" → Le consultant gagne
- **Égalité ou majorité rejet** : Le client gagne (bénéfice du doute)

**Résultat si consultant gagne** :
- ✅ Paiement automatique du milestone
- ✅ Reputation +1 (dispute gagnée)
- ✅ Le client perd 1 point de reputation

**Résultat si client gagne** :
- ❌ Pas de paiement
- ❌ Reputation -1 (dispute perdue)
- ✅ Le consultant peut corriger et resoumettre

---

## 📊 Système de Reputation

**Pour qui ?** Tous (consultants ET clients)

**Pourquoi ?** La reputation impacte votre visibilité et vos opportunités futures.

### Score de reputation (Consultant)

Votre score est calculé sur :
- ✅ **Missions réussies** : +10 points par mission
- ✅ **Disputes gagnées** : +5 points
- ❌ **Disputes perdues** : -10 points
- ❌ **Taux de perte** : Pénalité si >20% disputes perdues

**Impact** :
- **Score >90%** : Priorité dans le matching automatique
- **Score 70-90%** : Matching normal
- **Score <70%** : Pénalité -30% dans l'algorithme de matching

### Score de reputation (Client)

Votre score est calculé sur :
- ✅ **Missions complétées sans dispute** : +5 points
- ❌ **Disputes perdues** : -10 points (rejet injustifié)
- ❌ **Taux de rejet élevé** : Pénalité si >30% rejets

**Impact** :
- **Score >90%** : Badge "Client fiable"
- **Score <70%** : Alerte "Client difficile" visible par consultants

---

## ❓ FAQ - Questions fréquentes

### Pour les clients

**Q : Puis-je annuler une mission après avoir verrouillé les fonds ?**
R : Oui, AVANT de sélectionner un consultant. Vous récupérez 100% de vos fonds. Après sélection, vous devez passer par les milestones.

**Q : Que se passe-t-il si je ne valide pas dans les 7 jours ?**
R : Pour l'instant, rien (pas d'auto-validation). Mais le consultant peut vous relancer et éventuellement initier une dispute pour blocage abusif.

**Q : Puis-je modifier les critères d'acceptation après création de la mission ?**
R : Non, pour éviter les abus. Les critères sont verrouillés lors de la création de la mission. Vous pouvez annuler et recréer la mission si nécessaire.

**Q : Combien coûte l'arbitrage ?**
R : 2% du montant du milestone disputé. Exemple : Milestone de 3 000 € → 60 € de frais. Ces frais sont distribués aux 3 arbitres (20 € chacun).

### Pour les consultants

**Q : Dois-je obligatoirement fournir des attestations ?**
R : Seulement pour les missions qui l'exigent. Les missions marquées "Compliance requise" affichent les attestations nécessaires.

**Q : Combien de temps sont valides mes attestations ?**
R : Dépend du type :
- KBIS (France) : 3 mois
- URSSAF (France) : 6 mois
- RC Pro : 1 an
- Tax Clearance : 1 an

**Q : Puis-je retirer une dispute après l'avoir initiée ?**
R : Oui, tant que les arbitres n'ont pas encore voté. Utile si vous trouvez un accord amiable avec le client.

**Q : Comment devenir arbitre ?**
R : Conditions :
- Rank ≥3 dans le DAO (nécessite ≥5 missions réussies)
- Reputation >80%
- Formation arbitrage (2h en ligne)
- Vote d'approbation par la communauté

### Pour tous

**Q : Mes données personnelles sont-elles sécurisées ?**
R : Oui, conformité GDPR stricte :
- Seuls les **hash** des documents sont on-chain (pas les documents eux-mêmes)
- Documents stockés de manière chiffrée sur IPFS
- Droit à l'oubli : Vous pouvez demander la révocation de vos attestations

**Q : Que se passe-t-il en cas de litige complexe ?**
R : L'arbitrage DAO couvre 95% des cas. Pour les 5% restants (litiges juridiques complexes), vous pouvez escalader vers la justice traditionnelle. Le vote des arbitres peut servir de preuve.

**Q : Puis-je voir l'historique des disputes d'un utilisateur ?**
R : Non, pour protéger la vie privée. Vous voyez uniquement :
- Le score de reputation global (ex: 87%)
- Le taux de disputes (ex: 2 disputes sur 10 missions = 20%)
- Les badges (ex: "Client fiable", "Consultant expert")

---

## 🚀 Prochaines étapes

### Pour commencer (Client)

1. **Créez votre mission** avec critères d'acceptation clairs
2. **Définissez vos milestones** (30/40/30 ou 50/50 recommandé)
3. **Verrouillez les fonds** en escrow
4. **Sélectionnez un consultant** qualifié
5. **Validez les livrables** au fur et à mesure

### Pour commencer (Consultant)

1. **Complétez votre profil** avec attestations si nécessaire
2. **Postulez aux missions** correspondant à vos compétences
3. **Soumettez des livrables de qualité** conformes aux critères
4. **Construisez votre reputation** mission après mission

---

## 📞 Support

**Besoin d'aide ?**
- 📚 Documentation technique : `docs/technical/`
- 💬 Discord : `#support-quality-assurance`
- 📧 Email : support@dao-services.example

**Signaler un abus** :
- 🚨 Arbitre partial : `#report-arbiter`
- 🚨 Client/Consultant malveillant : `#report-abuse`

---

**Dernière mise à jour** : 16 février 2026
**Version** : 1.0.0 (Phase 1 KYC + Phase 2 Escrow/Dispute)
