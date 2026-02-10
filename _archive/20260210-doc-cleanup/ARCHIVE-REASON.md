# Archive : Nettoyage Documentation Redondante

**Date archivage** : 2026-02-10
**Taille totale** : ~510 lignes

---

## Fichiers Archivés

### QUICKSTART-DEV.md (509 lignes)

**Raison** : Redondance avec QUICKSTART.md

- QUICKSTART.md (283 lignes) : Setup rapide général pour devs Solidity/Foundry
- QUICKSTART-DEV.md (509 lignes) : Guide développeur détaillé (overlap ~80%)

**Décision** : Garder QUICKSTART.md (plus concis, suffit pour quick start). Archiver QUICKSTART-DEV.md.

**Alternative** : Si besoin guide développeur détaillé → Créer DEVELOPER-GUIDE.md consolidé ultérieurement.

---

## Fichiers Temporaires Supprimés

### build-log.txt

**Raison** : Log de compilation Rust (substrate-runtime build) temporaire, peut être régénéré.

**Contenu** : Output compilation `cargo build` avec liste packages compilés.

---

## Fichiers CONSERVÉS (Décisions)

### substrate-runtime/ (3.1GB)

**Raison** : POC Substrate Runtime pour évaluation "Gate 1" (mois 3).

**Statut** :
- Code : pallets/, runtime/, node/ (architecture complète)
- Build artifacts : target/ exclu via .gitignore (3.1GB non versionné)
- Documentation : README-SUBSTRATE.md (400 lignes, architecture)

**Décision stratégique** : Garder pour évaluation comparative Solidity vs Substrate au mois 3 (voir `_docs/guides/ink-vs-substrate-decision.md`).

---

### _docs/guides/polkadot-*.md (7 fichiers, ~150KB)

**Fichiers** :
- ink-vs-substrate-decision.md (14KB) - Décision stratégique
- polkadot-2.0-architecture.md (9.7KB) - Async Backing, Agile Coretime
- polkadot-2.0-migration-plan.md (45KB) - Roadmap 12 mois
- polkadot-best-practices.md (19KB) - Patterns sécurité/performance
- polkadot-deployment-guide.md (16KB) - Testnets/mainnet
- polkadot-project-management.md (14KB) - Treasury proposals
- substrate-pallet-patterns.md (28KB) - Développement pallets

**Raison** : Documentation stratégique pour décisions architecturales futures (Gate 1, parachain evaluation).

**Décision** : Garder comme référence technique, non obsolète.

---

### VALIDATION-QUICKSTART.md

**Raison** : Guide spécifique validation contrats (Slither, critères Phase 0.5), usage différent de QUICKSTART.md.

**Décision** : Garder (pas de redondance).

---

### IMPLEMENTATION-REPORT.md (493 lignes)

**Raison** : Rapport Phase 3 governance (DAOGovernor, DAOTreasury), documente travail actuel Solidity.

**Décision** : Garder (pertinent, Phase 3 en cours 60%).

---

## Impact Nettoyage

**Espace libéré** : ~5KB (build-log.txt + QUICKSTART-DEV.md archivé)

**Clarté améliorée** :
- Moins de confusion entre multiples guides quick start
- Documentation stratégique clairement séparée (Polkadot guides)

**Espace NON libéré** : substrate-runtime/ (3.1GB) conservé pour Gate 1 evaluation.

---

## Références

- **Décision stratégique** : `_docs/guides/ink-vs-substrate-decision.md`
- **Roadmap** : `_docs/guides/polkadot-2.0-migration-plan.md`
- **Progress tracking** : `PROGRESS.md`

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
