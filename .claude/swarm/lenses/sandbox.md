# Lentille Active : Executeur Sandbox

## Declenchement
- Apres production de code, pour valider empiriquement (tests verts)
- Pendant le cycle TDD (red -> green -> refactor)
- Pour verifier qu'une modification ne casse pas l'existant

## Mandat
Executer du code et des tests dans l'environnement reel du projet. Fermer la boucle cybernetique : hypothese -> execution -> observation -> ajustement.

## Processus

### Etape 1 : Verification pre-execution
```bash
# Verifier que le projet build (adapter selon ecosysteme)
npm run build 2>&1 | tail -20        # Node/TS
python -m py_compile fichier.py       # Python
cargo check                           # Rust
```

### Etape 2 : Execution des tests cibles
Ne pas lancer toute la suite de tests. Cibler la zone d'impact.
```bash
# TypeScript/Jest
npx jest --testPathPattern="MODULE" --verbose 2>&1

# Python/pytest
python -m pytest tests/test_MODULE.py -v 2>&1

# Avec couverture
npx jest --testPathPattern="MODULE" --coverage --collectCoverageFrom="src/MODULE/**" 2>&1
python -m pytest tests/test_MODULE.py --cov=src/MODULE -v 2>&1
```

### Etape 3 : Verification des specifications negatives
```bash
# Non-regression sur les zones adjacentes
npx jest --testPathPattern="ADJACENT_MODULE" --verbose 2>&1

# Verification de type (TS)
npx tsc --noEmit 2>&1

# Linting
npx eslint src/MODULE --quiet 2>&1
python -m ruff check src/MODULE 2>&1
```

## Format de Sortie
```
### Resultat Sandbox — [description]

Build : OK | ECHEC [detail]

Tests cibles :
- Total : N | Passes : N | Echoues : N | Ignores : N
- Detail echecs : [test_name] : [raison]

Specifications negatives :
- Non-regression : OK | ECHEC [detail]
- Types : OK | ECHEC [erreurs]
- Lint : OK | ECHEC [violations]

Couverture (zone d'impact) :
- Statements : N% | Branches : N% | Functions : N%

Verdict : ship | fix_and_retry | redesign
```

## Boucle d'Iteration
Si verdict = fix_and_retry :
1. Analyser les echecs
2. Corriger le minimum necessaire
3. Re-executer les tests echoues uniquement
4. Maximum 3 iterations — au-dela, passer en redesign

> Le code qui n'a pas ete execute n'existe pas. Un test qui n'a pas tourne est une opinion, pas une verification.
