# Lentille Active : Generateur de Specifications

## Declenchement
- Pour tout changement non trivial
- Quand le Noyau passe en MODE GENERATIF sans critere de completude

## Mandat
Traduire le probleme purifie en conditions de succes concretes, verifiables, minimales — AVANT toute reflexion sur l'implementation.

> Si tu ne peux pas ecrire le test en premier, tu ne comprends pas encore le probleme.

## Trois niveaux de specification

### 1. Specifications Comportementales
Format Given/When/Then minimal. Pas de prose — des assertions.

```
GIVEN [etat initial precis]
WHEN  [action declencheuse]
THEN  [resultat observable et verifiable]
```

Regles :
- Chaque spec doit etre traduisible en UN test automatise
- Pas de "should work correctly" — des valeurs concretes, des etats verifiables
- Couvrir le happy path ET les cas limites critiques (pas tous — les critiques)
- Maximum 7 specs par changement. Au-dela, le changement est trop gros — decouper.

Exemple bon :
```
GIVEN un utilisateur authentifie avec le role "editor"
WHEN  il soumet un article avec un titre de 300 caracteres
THEN  l'article est rejete avec l'erreur TITLE_TOO_LONG
  ET  aucun article n'est cree en base
```

Exemple mauvais :
```
GIVEN un utilisateur
WHEN  il soumet un article invalide
THEN  une erreur appropriee est retournee
```
(Trop vague — "invalide" comment ? "appropriee" comment ?)

### 2. Specifications Contractuelles
Types, signatures, invariants, pre/post-conditions.

```typescript
// Signature
function processOrder(order: Order): Result<ProcessedOrder, OrderError>

// Pre-conditions
// - order.items.length > 0
// - order.items.every(item => item.quantity > 0)

// Post-conditions
// - Si Ok: processedOrder.total === sum(items.price * items.quantity)
// - Si Err: l'etat de la base n'a pas change (transactionnel)

// Invariants
// - order.id est unique et immutable une fois cree
```

### 3. Specifications Negatives — CRITIQUE
Ce qui ne doit PAS changer. La partie la plus lean — elle protege l'existant.

```
NE DOIT PAS :
- Modifier la signature de l'API publique existante de OrderService
- Ajouter de nouvelle dependance externe
- Augmenter le temps de reponse moyen de GET /orders au-dela de 200ms
- Modifier le schema de la table orders (sauf ajout de colonnes nullable)
- Casser les 47 tests existants dans tests/orders/
```

Regle d'or : si le changement touche N fichiers, les specs negatives doivent couvrir au minimum les contrats publics de ces N fichiers.

### 4. Specifications de Suppression (si applicable)
Ce qui doit disparaitre. Acte de design lean explicite.

```
SUPPRIMER :
- src/utils/legacyOrderProcessor.ts (remplace par le nouveau mecanisme)
- La dependance old-order-lib de package.json
- Les 3 tests associes dans tests/legacy/

VERIFIER :
- Aucune autre reference a legacyOrderProcessor dans le codebase
- Le build passe sans ces fichiers
```

## Format de Sortie

```
### Specifications — [description du changement]

Comportementales :
1. GIVEN ... WHEN ... THEN ...
2. GIVEN ... WHEN ... THEN ...
[max 7]

Contractuelles :
- Signature : [type]
- Pre-conditions : [liste]
- Post-conditions : [liste]
- Invariants : [liste]

Negatives :
- NE DOIT PAS : [liste]

Suppressions :
- SUPPRIMER : [liste]
- VERIFIER : [assertions post-suppression]

Completude :
- Specs traduisibles en tests : N/N
- Zone protegee par specs negatives : [perimetre]
```

## Gate
Si les specifications ne sont pas claires apres 2 tentatives, le probleme est mal compris — retour en MODE ANALYTIQUE, eventuellement clarification humaine.

> Les specs sont le filet de securite. Le code est l'acrobatie. On ne monte pas sur le fil sans avoir tendu le filet.
