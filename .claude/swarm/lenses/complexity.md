# Lentille Active : Mesure de Complexite Cognitive

## Declenchement
- Sur tout code produit depassant 50 lignes
- Sur tout changement touchant > 2 modules
- Quand le Noyau doute de la lisibilite d'une solution

## Mandat
Mesurer la charge cognitive reelle du code produit — pas le volume, mais l'effort mental qu'un developpeur doit fournir pour comprendre, modifier, et supprimer ce code.

## Metriques

### 1. Complexite Cognitive (Sonar-style)
Increments :
- +1 par if, else if, else, switch case
- +1 par boucle (for, while, do-while, comprehensions)
- +1 par catch, try avec logique conditionnelle
- +1 par operateur logique combine (&& ou || dans une condition)
- +1 par niveau d'imbrication (facteur le plus penalisant)
- +1 par rupture de flux lineaire (break, continue, return anticipe dans boucle)

Seuils :
- 0-5 : Simple — comprehension immediate
- 6-10 : Modere — acceptable si bien structure
- 11-15 : Complexe — envisager un decoupage
- 16+ : Trop complexe — refactoring obligatoire

### 2. Densite Conceptuelle
Nombre de concepts distincts qu'un lecteur doit garder en memoire simultanement.

Compter : variables actives, types references, effets de bord, callbacks/closures, branches ouvertes.

Seuils :
- 1-3 : Memoire de travail confortable
- 4-5 : Limite de la memoire de travail
- 6+ : Surcharge — decouper

### 3. Distance au Pattern
Le code suit-il un pattern reconnaissable par un developpeur du projet ?
- 0.0 : Pattern identique a l'existant
- 0.3 : Variation mineure d'un pattern connu
- 0.6 : Pattern reconnaissable mais implementation inhabituelle
- 1.0 : Pattern totalement nouveau

Seuil : > 0.6 necessite justification explicite.

### 4. Supprimabilite
Effort pour retirer proprement ce code du codebase.
- trivial : 1 fichier, 0 effet collateral
- moderate : 2-3 fichiers, ajustements mineurs
- surgical : 4-8 fichiers, necessite comprehension du graphe
- archeological : 9+ fichiers, risque de casser des choses non evidentes

### 5. Ratio Signal / Ceremonie
```
signal = lignes de logique metier / comportement
ceremonie = imports, boilerplate, types evidents, wrapping, plumbing
ratio = signal / (signal + ceremonie)
```
- > 0.7 : Code expressif
- 0.5-0.7 : Acceptable pour du code d'infrastructure
- 0.3-0.5 : Trop de ceremonie
- < 0.3 : Le boilerplate domine — probleme structurel

## Format de Sortie

```
### Mesure de Complexite — [fichier/fonction]

| Metrique | Valeur | Seuil | Verdict |
|---|---|---|---|
| Complexite cognitive | N | <=10 | OK/KO |
| Densite conceptuelle | N | <=5 | OK/KO |
| Distance au pattern | 0.N | <=0.6 | OK/KO |
| Supprimabilite | [echelle] | <=moderate | OK/KO |
| Signal/Ceremonie | 0.N | >=0.5 | OK/KO |

Temps de comprehension estime : N minutes
Verdict global : ship | simplify | redesign | abandon
Suggestions de simplification : [si applicable]
```

## Commandes d'Analyse

```bash
# Complexite avec ESLint
npx eslint src/MODULE --rule '{"complexity": ["warn", 10]}' 2>&1

# Comptage heuristique
grep -c "if\|else\|for\|while\|switch\|catch\|&&\|||" src/fichier.ts

# Profondeur d'imbrication maximale
awk '{indent=0; for(i=1;i<=length($0);i++){if(substr($0,i,1)==" ")indent++;else break}; if(indent>max)max=indent} END{print "Max indentation:", max/2, "levels"}' src/fichier.ts
```

> La complexite que tu mesures est celle que tu peux reduire. La complexite que tu ignores est celle qui te tue a 2h du matin.
