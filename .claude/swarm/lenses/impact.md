# Lentille Active : Cartographie d'Impact

## Declenchement
Cette lentille est invoquee par le Noyau quand :
- Le snapshot codebase montre un couplage fort dans la zone touchee
- Le changement impacte > 3 fichiers
- Le Noyau hesite sur la portee reelle d'une modification

## Mandat
Simuler la propagation d'un changement a travers le graphe de dependances du projet. Repondre a : "Si je modifie X, qu'est-ce qui casse ou change de comportement ?"

## Processus

### Etape 1 : Identifier la surface de changement
```bash
# Trouver les dependants directs du fichier/module modifie
grep -r "import.*from.*MODULE" --include="*.{ts,tsx,js,jsx,py}" -l .
grep -r "require.*MODULE" --include="*.js" -l .
```

### Etape 2 : Tracer la propagation transitive
Pour chaque dependant direct, identifier ses propres dependants. S'arreter a 3 niveaux de profondeur (au-dela, le signal est trop faible).

### Etape 3 : Classifier les impacts
Pour chaque fichier touche, determiner :
- Breaking : Le contrat (types, signature, comportement) est rompu — le code ne compile/fonctionne plus
- Behavioral : Le contrat est respecte mais le comportement observable change (ex : ordre, performance, effets de bord)
- Silent : Aucun impact fonctionnel mais dette technique (ex : inconsistance de style, pattern divergent)

### Etape 4 : Evaluer la reversibilite
- Le changement peut-il etre annule par un simple revert ?
- Y a-t-il des effets irreversibles (migration de donnees, changement d'API publique consommee par des tiers) ?
- Les tests existants couvrent-ils la zone d'impact ?

## Format de Sortie

```
### Cartographie d'Impact — [description du changement]

Surface directe :
- [fichier1] — [breaking/behavioral/silent] — [detail]
- [fichier2] — ...

Propagation transitive :
- Niveau 2 : [fichiers]
- Niveau 3 : [fichiers]

Changements cassants :
- [detail de chaque contrat rompu]

Tests a mettre a jour :
- [liste des fichiers de test impactes]

Scores :
- blast_radius : contained | module | cross-module | system
- reversibility : 0.0-1.0 (1.0 = trivial a annuler)
- test_coverage_of_impact : 0.0-1.0

Recommandation :
- [Proceder | Reduire la portee | Decouper en changements plus petits | Escalader en mode deliberatif]
```

## Commandes par Ecosysteme

### TypeScript/JavaScript
```bash
npx madge --circular --extensions ts,tsx src/
npx madge --depends-on src/module.ts --extensions ts,tsx src/
grep -rn "from ['\"].*MODULE" --include="*.ts" --include="*.tsx" .
```

### Python
```bash
grep -rn "from MODULE import\|import MODULE" --include="*.py" .
pydeps src/module.py --max-bacon 3  # si disponible
```

### Generique
```bash
grep -rn "SYMBOL_NAME" --include="*.{ts,tsx,js,jsx,py}" . | grep -v node_modules | grep -v __pycache__
```
