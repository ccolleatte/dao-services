# Note stratégique : Modèle juridique SAS-DAO

**Date** : 2026-02-16
**Axe** : Structuration juridique hybride SAS + Association loi 1901
**Horizon** : M0 -> M24

---

## 1. Contexte et enjeux

Les DAOs n'ont pas de statut juridique reconnu en France en 2026. Le Haut Comité Juridique de la Place Financière (HCJP) a publié un rapport explorant des pistes réglementaires post-MiCA, mais aucune loi spécifique n'est adoptée. La solution pragmatique documentée par les praticiens du droit est la structure duale SAS + Association loi 1901.

**Sources** :
- [Banque de France — Rapport 64 DAOs](https://www.banque-france.fr/fr/system/files/2024-07/Rapport_64_F.pdf)
- [Village de la Justice — Structuration juridique DAO](https://www.village-justice.com/articles/structuration-juridique-des-dao,51326.html)
- [Cryptoast — DAO et droit français](https://cryptoast.fr/structuration-dao-droit-francais-quels-enjeux-juridiques/)

---

## 2. Architecture juridique recommandée

```
+------------------------------------------------------+
|         ASSOCIATION LOI 1901 "DAO Conseil"            |
|                                                        |
|  - Héberge le protocole de gouvernance DAO             |
|  - Détient la trésorerie commune (Gnosis Safe)         |
|  - Membres = tous consultants (cotisation = REP)       |
|  - Assemblée générale = votes DAO on-chain             |
|  - Fonctionnement démocratique natif                   |
|  - Faibles contraintes administratives                 |
|                                                        |
|              +---------------+                         |
|              | Mandat de     |                         |
|              | gestion       |                         |
|              +-------+-------+                         |
|                      |                                 |
+----------------------|------ --------------------------+
                       v
+------------------------------------------------------+
|           SAS "Cabinet Conseil"                       |
|                                                        |
|  - Entité commerciale (facturation, contrats)          |
|  - Responsabilité limitée des associés                 |
|  - Président = élu par vote DAO (mandat 2 ans)         |
|  - Statuts intègrent clause de gouvernance DAO         |
|  - Signe les contrats clients                          |
|  - Emploie/contractualise les consultants              |
+------------------------------------------------------+
```

### Répartition des responsabilités

| Fonction | Entité porteur | Justification juridique |
|----------|---------------|------------------------|
| **Signature contrats clients** | SAS | Responsabilité limitée, crédibilité commerciale |
| **Facturation et encaissement** | SAS | Cadre fiscal classique (IS, TVA) |
| **Votes stratégiques** | Association (DAO) | Fonctionnement démocratique natif de la loi 1901 |
| **Trésorerie commune** | Association (Gnosis Safe) | Transparence totale, multi-sig |
| **Nomination dirigeants SAS** | Association (vote DAO) | Démocratisation de la gouvernance exécutive |
| **Propriété intellectuelle** | Association | Mutualisation, pas de capture par un associé |
| **Contrats consultants** | SAS (salariés) ou portage (indépendants) | Conformité droit du travail |

### Clause de gouvernance DAO dans les statuts SAS

La SAS permet une souplesse statutaire exceptionnelle permettant aux associés d'organiser librement leur gouvernance.

**Article type** :

> "Les décisions relevant de l'article L. 227-9 du Code de commerce sont soumises au vote des membres de l'Association [Nom], selon le protocole de vote décentralisé défini dans le règlement intérieur annexé. Le résultat du vote, horodaté et enregistré sur la blockchain [Polygon], fait foi entre les parties. Le Président de la SAS est tenu d'exécuter les décisions adoptées par vote qualifié (>=66% des tokens de gouvernance exprimés)."

**Sources** :
- [Ethereum France — Forme juridique DAO](https://www.ethereum-france.com/quelle-forme-juridique-pour-une-dao/)
- [ADH Avocats — Révolution juridique DAO](https://www.adh-avocats.fr/dao-la-revolution-juridique-de-la-gouvernance-decentralisee/)

### Traitement fiscal et réglementaire

| Enjeu | Solution | Référence |
|-------|----------|-----------|
| **Tokens REP = titre financier ?** | Non : soulbound, non transférable, non monétisable -> hors périmètre MiCA | ADH Avocats |
| **Tokens CRED = instrument de paiement ?** | Non : utilitaire interne, détruit à la consommation, pas de marché secondaire | Avis juridique à obtenir (P0) |
| **TVA sur missions** | Classique : SAS facture HT, reverse charge UE | Cadre SAS standard |
| **Imposition bénéfices** | IS sur SAS, Association exonérée si non lucrative | Bueder Avocat |
| **Statut consultants** | CDI (SAS) ou portage salarial (indépendants) | Conformité droit du travail français |

---

## 3. Priorités opérationnelles

| Priorité | Action | Effort | Prérequis |
|----------|--------|--------|-----------|
| **P0** | Consultation avocat spécialisé Web3 (avis sur qualification tokens + structuration) | 3-5 jours, budget 3-5K EUR | Spécification tokenomics |
| **P0** | Rédaction statuts SAS avec clause gouvernance DAO | 2-3 semaines (avec avocat) | Avis juridique tokens validé |
| **P0** | Création Association loi 1901 (règlement intérieur intégrant protocole vote) | 1-2 semaines | Statuts SAS finalisés |
| **P1** | Convention de mandat Association -> SAS (gestion opérationnelle) | 1 semaine | Deux entités créées |
| **P1** | Règlement intérieur Association (protocole de vote on-chain, quorum, délais) | 1 semaine | Framework technique choisi |
| **P2** | Police d'assurance RC Pro couvrant le modèle hybride | 2-3 semaines | Statuts et convention signés |
| **P3** | Veille réglementaire HCJP / législation DAO France | Continue | Abonnement alerte juridique |

---

## 4. Quick wins

| Quick win | Horizon | Impact | Coût |
|-----------|---------|--------|------|
| **Consultation flash avocat Web3** (2h) pour valider la faisabilité SAS + Asso + tokens non financiers | Semaine 1 | Sécurisation juridique du modèle avant tout investissement technique | 500-800 EUR |
| **Création Association loi 1901** (dépôt préfecture) | Semaine 2-3 | Entité légale pour héberger la gouvernance DAO, cotisation = 0 EUR | 0 EUR (gratuit) |
| **Statuts SAS avec clause de renvoi** au règlement intérieur de l'Association pour les décisions stratégiques | Semaine 4-6 | Pont juridique SAS <-> DAO opérationnel | Budget avocat inclus |

---

## 5. Horizon temporel par maturité

| Phase | Maturité juridique | Risque résiduel |
|-------|-------------------|-----------------|
| **M0-M3** | SAS créée + Association créée + Convention signée | Moyen : avis juridique tokens en cours |
| **M3-M6** | Tokens qualifiés juridiquement + règlement intérieur adopté | Faible : cadre stabilisé |
| **M6-M12** | Premier contrat client signé via SAS avec clause DAO | Faible : jurisprudence à construire |
| **M12-M18** | Retour d'expérience juridique, ajustements si nécessaire | Très faible : modèle éprouvé |
| **M18-M24** | Veille adaptation législation DAO France (si adoptée) | Opportunité de simplification |
