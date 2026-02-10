# Lentille Active : Mode Deliberatif

## Declenchement
Escalade exceptionnelle. Le Noyau l'active UNIQUEMENT quand :
- blast_radius = system (changement transversal a l'architecture)
- ET reversibilite estimee faible
- Exemples : changement de modele de donnees, nouvelle abstraction transversale, migration technique, changement d'API publique

## Mandat
Soumettre la decision a un debat contradictoire structure. Deux perspectives independantes pour eviter le biais de confirmation du raisonneur unique.

## Processus

### Etape 1 : Cadrage du debat
Formuler :
- La decision a prendre (une phrase)
- Le contexte factuel (ce qu'on sait)
- Les contraintes non negociables
- Les options identifiees (minimum 2)

### Etape 2 : Perspective ADVOCATE (Pour)

```
## ADVOCATE — En faveur de [option]

Benefices directs :
- [benefice 1 avec estimation d'impact]
- [benefice 2]

Benefices de second ordre :
- [effet positif indirect]

Pourquoi maintenant :
- [cout du report, fenetre d'opportunite]

Risques de NE PAS faire :
- [dette accumulee, cout d'opportunite]

Reponse aux objections previsibles :
- Objection : [X] -> Reponse : [Y]
```

### Etape 3 : Perspective CHALLENGER (Contre)

```
## CHALLENGER — Contre [option] / En faveur de [alternative]

Risques directs :
- [risque 1 avec probabilite et impact estimes]
- [risque 2]

Risques de second ordre :
- [effet negatif indirect, non evident]

Cout reel (pas juste le cout de dev) :
- [migration, formation, maintenance sur 2 ans]

Alternative plus simple :
- [description, ce qu'elle sacrifie vs. preserve]

Test decisif :
- [la question qui tranche — souvent : "peut-on faire le minimum pour 6 mois et reevaluer ?"]
```

### Etape 4 : Synthese et Decision

```
## DECISION

Resume du debat :
- ADVOCATE : [essence]
- CHALLENGER : [essence]

Point de convergence : [accord]
Point de divergence irreductible : [vrai desaccord]

Decision : [option choisie]
Justification : [en integrant les arguments des deux cotes]

Conditions d'annulation :
- [circonstances ou on reviendrait sur cette decision]

Plan de mitigation :
- [actions concretes pour les risques identifies par CHALLENGER]
```

## Regles du Debat

1. Independance reelle. ADVOCATE et CHALLENGER doivent produire des arguments que l'autre n'a pas anticipes. Si les deux sont des reformulations, le debat est inutile.
2. Pas de faux equilibre. Si une perspective est clairement plus forte, le reconnaitre.
3. Concret, pas abstrait. Pas de "cela pourrait poser des problemes". Quel probleme ? Dans quel fichier ? Avec quelle probabilite ?
4. Maximum 20 minutes de raisonnement. Au-dela, escalade humaine.

## Quand NE PAS utiliser
- Decisions facilement reversibles (meme a large portee)
- Decisions ou le codebase a deja un precedent clair
- Optimisations de performance (mesurer > debattre)
- Choix stylistiques (suivre les conventions > debattre)

> Les meilleures decisions sont celles ou tu peux expliquer pourquoi tu n'as PAS choisi l'alternative.
