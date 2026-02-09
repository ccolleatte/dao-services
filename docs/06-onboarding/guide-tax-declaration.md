# Guide : Déclaration fiscale des revenus DAO

## Avertissement légal

⚠️ **Ce guide est informatif uniquement**. Les lois fiscales évoluent et varient selon les juridictions. Consultez un expert-comptable spécialisé crypto avant toute déclaration.

**Mise à jour** : Février 2026
**Scope** : France, Belgique, Suisse, Luxembourg

---

## Principe général : Tokenisation = Revenu imposable

Dans la plupart des juridictions européennes :

1. **Réception tokens DAOS** = Revenu imposable (valeur EUR au moment du paiement)
2. **Conversion tokens → EUR** = Plus-value/moins-value imposable
3. **Staking rewards** = Revenu supplémentaire imposable

**Exemple** :
```
Mission complétée : 1000 DAOS reçus le 15/01/2026
Taux DAOS/EUR ce jour : 3.50 EUR
→ Revenu imposable : 3500 EUR

Conversion le 30/06/2026 : 1000 DAOS vendus
Taux DAOS/EUR ce jour : 4.20 EUR
→ Plus-value : (4.20 - 3.50) × 1000 = +700 EUR (imposable)
```

---

## 🇫🇷 France

### Statut recommandé : Micro-entrepreneur (régime BNC)

**Avantages** :
- Déclaration simplifiée trimestrielle
- Abattement forfaitaire 34% (BNC)
- Plafonds élevés : 77 700 EUR/an (2026)
- Cotisations sociales 21.2% du CA

**Démarches** :
1. Inscription URSSAF : autoentrepreneur.urssaf.fr
2. Code APE : 7022Z (Conseil gestion entreprises)
3. Déclaration mensuelle/trimestrielle CA

### Export CSV requis

Colonnes obligatoires :
```csv
Date,Description,Montant DAOS,Taux EUR/DAOS,Montant EUR,Type opération
15/01/2026,Mission audit sécurité DAO XYZ,1000,3.50,3500,Revenu
30/06/2026,Conversion DAOS → EUR (Kraken),1000,4.20,4200,Plus-value
```

### Déclaration annuelle (formulaire 2042-C-PRO)

**Lignes à renseigner** :
- **5HQ** : Revenus non commerciaux professionnels (BNC)
- **3VG** : Plus-values crypto-monnaies (flat tax 30%)

**Documents justificatifs** :
- Export CSV transactions DAO
- Screenshots Etherscan (proof of payment)
- Contrats missions (specs signées)

### Cotisations sociales

| Tranche CA annuel | Taux cotisations |
|-------------------|------------------|
| 0 - 77 700 EUR | 21.2% |
| > 77 700 EUR | Passage régime réel (expert-comptable requis) |

**Calcul simplifié** :
```
CA annuel : 35 000 EUR
Cotisations : 35 000 × 21.2% = 7 420 EUR
Revenus nets : 35 000 - 7 420 = 27 580 EUR
Impôt sur le revenu : 27 580 × Taux marginal (11-30% selon tranche)
```

### Ressources officielles

- **URSSAF** : urssaf.fr/portail/home/independant.html
- **Impots.gouv** : impots.gouv.fr → Particuliers → Déclarer revenus
- **Expert-comptable crypto** : Waltio, Coin.ink (logiciels déclaration automatique)

---

## 🇧🇪 Belgique

### Statut recommandé : Indépendant complémentaire

**Avantages** :
- Cumulable avec emploi salarié
- Cotisations sociales réduites (année 1-3)
- Exonération TVA si CA <25 000 EUR/an

**Démarches** :
1. Inscription Banque-Carrefour Entreprises (BCE)
2. Choix caisse sociale (Xerius, Liantis, Acerta)
3. Déclaration trimestrielle revenus

### Export CSV requis

Colonnes obligatoires :
```csv
Datum,Beschrijving,Bedrag DAOS,Wisselkoers EUR/DAOS,Bedrag EUR,Type
15/01/2026,Consultancy DAO security audit,1000,3.50,3500,Inkomen
30/06/2026,Verkoop DAOS → EUR (Kraken),1000,4.20,4200,Meerwaarde
```

### Déclaration annuelle (Tax-on-Web)

**Rubriques** :
- **Code 1620** : Bénéfices professions libérales
- **Code 1440** : Plus-values crypto-actifs (33% divers revenus)

**Documents justificatifs** :
- Factures missions (BE format : TVA, n° BCE)
- Export blockchain transactions
- Contrats clients

### Cotisations sociales

| Année | Revenus nets | Cotisations trimestrielles |
|-------|--------------|----------------------------|
| Année 1 | <7 965 EUR | 88.61 EUR/trimestre |
| Année 2-3 | <14 314 EUR | Progressif |
| Année 4+ | Réel | ~20% revenus nets |

**Calcul simplifié** (année 4+) :
```
Revenus nets : 30 000 EUR
Cotisations : 30 000 × 20% = 6 000 EUR
Impôt PPR : (30 000 - 6 000) × Taux marginal (25-50%)
```

### Ressources officielles

- **BCE** : economie.fgov.be/fr/themes/entreprises/creer-une-entreprise
- **Caisses sociales** : xerius.be, liantis.be, acerta.be
- **Tax-on-Web** : myminfin.be

---

## 🇨🇭 Suisse

### Statut recommandé : Indépendant AVS

**Avantages** :
- Taux imposition faible (10-25% selon canton)
- Cotisations AVS/AI/APG ~10% revenus
- Pas de TVA si CA <100 000 CHF/an

**Démarches** :
1. Inscription caisse compensation AVS cantonale
2. Obtention numéro IDE (Identifiant Entreprise)
3. Déclaration annuelle revenus

### Export CSV requis

Colonnes obligatoires :
```csv
Datum,Beschreibung,Betrag DAOS,Wechselkurs CHF/DAOS,Betrag CHF,Typ
15.01.2026,Beratung DAO Sicherheit,1000,3.80,3800,Einkommen
30.06.2026,Umtausch DAOS → CHF (Kraken),1000,4.50,4500,Kapitalgewinn
```

### Déclaration annuelle (e-dec)

**Formulaires** :
- **Annexe revenus indépendants** : Détail bénéfices nets
- **Annexe fortune** : Détention crypto-actifs au 31/12
- **Crypto-monnaies** : Déclaration fortune (impôt fortune 0.3-1%)

**Documents justificatifs** :
- Décomptes AVS trimestriels
- Contrats missions
- Export blockchain (Etherscan, wallet)

### Cotisations AVS/AI/APG

| Revenus nets annuels | Taux cotisations |
|----------------------|------------------|
| 0 - 58 800 CHF | ~5.371% |
| 58 800+ CHF | 10.00% |

**Calcul simplifié** :
```
Revenus nets : 80 000 CHF
Cotisations AVS : 80 000 × 10% = 8 000 CHF
Impôts cantonaux : 80 000 × ~15% = 12 000 CHF (varie canton)
Impôt fédéral direct : 80 000 × ~3% = 2 400 CHF
```

### Ressources officielles

- **AVS/AI** : avs-ai.swiss
- **AFC** : estv.admin.ch (impôt fédéral)
- **Cantons** : ge.ch, zh.ch, vd.ch (sites fiscaux cantonaux)

---

## 🇱🇺 Luxembourg

### Statut recommandé : Auto-entrepreneur

**Avantages** :
- Exonération TVA si CA <35 000 EUR/an
- Abattement frais forfaitaire 30%
- Taux imposition progressif (0-42%)

**Démarches** :
1. Inscription Guichet Entreprises (guichet.lu)
2. Autorisation établissement
3. Affiliation CCSS (sécurité sociale)

### Export CSV requis

Colonnes obligatoires :
```csv
Date,Description,Montant DAOS,Taux EUR/DAOS,Montant EUR,Type opération
15/01/2026,Mission conseil DAO governance,1000,3.50,3500,Revenu
30/06/2026,Vente DAOS → EUR (Bitstamp),1000,4.20,4200,Plus-value
```

### Déclaration annuelle (ACD)

**Formulaire 100** : Déclaration impôt personne physique
- **Page 2** : Revenus profession libérale
- **Page 8** : Plus-values crypto-actifs (régime spécial)

**Documents justificatifs** :
- Factures clients (format LU : TVA si >35k EUR)
- Déclaration CCSS (cotisations sociales)
- Export transactions blockchain

### Cotisations CCSS

| Revenus annuels | Assurance maladie | Assurance pension |
|-----------------|-------------------|-------------------|
| <35 000 EUR | 6.90% | 16.00% |
| 35 000+ EUR | 6.90% | 16.00% (plafonné 150k EUR) |

**Calcul simplifié** :
```
Revenus nets : 40 000 EUR
Cotisations CCSS : 40 000 × 22.9% = 9 160 EUR
Impôt sur le revenu : (40 000 - 9 160) × Taux marginal (14-30%)
```

### Ressources officielles

- **Guichet.lu** : guichet.public.lu/fr/entreprises.html
- **ACD** : impotsdirects.public.lu
- **CCSS** : ccss.lu

---

## Outils de déclaration automatique

| Outil | Pays supportés | Prix | Fonctionnalités |
|-------|----------------|------|-----------------|
| **Waltio** | FR, BE, CH, LUX | 49-199 EUR/an | Import wallet auto, calcul plus-values, export PDF |
| **Coin.ink** | FR uniquement | 39 EUR/an | Déclaration 2042-C-PRO pré-remplie |
| **Accointing** | Tous pays EU | 79-299 USD/an | Portfolio tracking + tax reports |
| **Koinly** | Global | 99-279 USD/an | 20+ pays, intégration 500+ exchanges |

### Workflow recommandé (Waltio exemple)

1. **Connecter wallets** :
   - MetaMask (adresse Ethereum DAO)
   - Exchanges (Kraken, Binance si conversions fiat)

2. **Import automatique transactions** :
   - Etherscan API : Paiements DAOS tokens
   - Exchange API : Conversions DAOS → EUR

3. **Catégoriser opérations** :
   - Revenus missions → "Income"
   - Conversions → "Trade" (calcul plus-value auto)
   - Gas fees → "Cost" (déductible selon pays)

4. **Export fiscal** :
   - France → CSV format URSSAF + 2042-C-PRO
   - Belgique → CSV Tax-on-Web + annexe
   - Suisse → Formulaire revenus indépendants
   - Luxembourg → Formulaire 100

---

## Cas particuliers

### Staking rewards

**Traitement fiscal** :
- **FR** : Revenu imposable (BNC) au moment du claim
- **BE** : Divers revenus (code 1440) si >1000 EUR/an
- **CH** : Revenu imposable (AVS)
- **LUX** : Revenu imposable (CCSS)

**Exemple** :
```
Staking 500 DAOS → Reward 25 DAOS/an
Taux DAOS/EUR au claim : 3.50 EUR
→ Revenu imposable : 25 × 3.50 = 87.50 EUR
```

### Airdrops DAO governance tokens

**Traitement fiscal** :
- **Réception airdrop** : Pas de revenu imposable (donation)
- **Vente airdrop** : Plus-value imposable (valeur acquisition = 0 EUR)

**Exemple** :
```
Airdrop 100 GOVERNANCE reçus gratuitement
Vente 100 GOVERNANCE : 4 EUR/token = 400 EUR
→ Plus-value imposable : 400 EUR (pas de coût acquisition)
```

### Gas fees Ethereum

**Déductibilité** :
- **FR** : Oui (frais professionnels déductibles BNC)
- **BE** : Oui (frais généraux profession libérale)
- **CH** : Oui (frais d'activité indépendante)
- **LUX** : Oui (charges exploitation)

**Calcul** :
```
Gas fees annuels : 0.5 ETH × 3000 EUR/ETH = 1500 EUR
→ Déduction revenus imposables : -1500 EUR
```

---

## Checklist annuelle (toutes juridictions)

### Janvier-Février
- [ ] Export CSV transactions année N-1
- [ ] Calcul revenus DAOS (tokens reçus × taux EUR)
- [ ] Calcul plus-values (ventes - achats)
- [ ] Réunir justificatifs (contrats, factures, Etherscan)

### Mars-Avril
- [ ] Déclaration cotisations sociales (URSSAF/BCE/AVS/CCSS)
- [ ] Paiement cotisations trimestrielles
- [ ] Import données dans outil fiscal (Waltio/Coin.ink)

### Mai-Juin
- [ ] Déclaration impôt sur le revenu
- [ ] Envoi formulaires + annexes (2042-C-PRO/Tax-on-Web/e-dec/ACD)
- [ ] Archivage documents 10 ans (obligation légale)

### Juillet-Décembre
- [ ] Suivi revenus mensuels (éviter dépassement seuils)
- [ ] Provisions impôts (30-40% revenus bruts)
- [ ] Mise à jour classifications transactions

---

## Contacts experts-comptables crypto

### France
- **Waltio Experts** : experts@waltio.com (réseau 50+ comptables certifiés)
- **Coin.ink** : contact@coin.ink (déclaration assistée)

### Belgique
- **Xerius** : info@xerius.be (caisse sociale + accompagnement fiscal)
- **Liantis** : info@liantis.be

### Suisse
- **BDO Suisse** : bdo.ch (expertise crypto-actifs)
- **KPMG Suisse** : kpmg.ch/fr (audit blockchain)

### Luxembourg
- **Atoz** : atoz.lu (spécialistes fintech/crypto)
- **PwC Luxembourg** : pwc.lu (tax advisory crypto)

---

## FAQ

**Q : Dois-je déclarer si revenus <1000 EUR/an ?**
R : Oui, obligation déclaration même si revenus faibles (possibilité exonération selon pays).

**Q : Que faire si j'ai oublié de déclarer années précédentes ?**
R : Régularisation ASAP via expert-comptable (amendes réduites si volontaire).

**Q : DAOS tokens = monnaie ou actif numérique ?**
R : Actif numérique (utility token), pas de statut monnaie légale.

**Q : Puis-je déduire matériel informatique (laptop, GPU) ?**
R : Oui si usage professionnel démontré (factures, preuv utilisation missions).

**Q : Conversion DAOS → stablecoin (USDC) = fait générateur impôt ?**
R : Oui, considéré comme vente (plus-value calculée DAOS → USDC).

---

## Ressources complémentaires

- **Livre blanc fiscalité crypto France** : economie.gouv.fr (Bercy, 2025)
- **Guide fiscal crypto Belgique** : finances.belgium.be
- **Circulaire AFC Suisse** : estv.admin.ch (crypto-monnaies 2024)
- **CSSF Luxembourg** : cssf.lu (régulation crypto-actifs)

---

**Besoin d'aide ?** Rejoignez le Discord DAO, canal `#fiscal-support`
**Mise à jour** : Guide actualisé trimestriellement (prochaine : Mai 2026)
