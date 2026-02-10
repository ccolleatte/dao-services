# Scripts DAO

Scripts utilitaires pour le projet DAO.

## Setup

### setup-skills-junction.ps1

Configure la junction Windows pour accéder aux skills Claude Code workspace-wide.

**Usage** :
```powershell
# Première installation
_scripts/setup/setup-skills-junction.ps1

# Réparer une junction corrompue
_scripts/setup/setup-skills-junction.ps1 -Force
```

**Quand utiliser** :
- Après clone initial du projet
- Si les skills `/xxx` ne sont plus reconnus
- Après un `git clean -fdx` qui aurait supprimé la junction

**Diagnostic** :
```powershell
# Vérifier si la junction existe
Test-Path .claude/skills

# Vérifier le nombre de skills disponibles
(Get-ChildItem .claude/skills -Directory).Count
```

## Validation

Scripts de validation pour CI/CD (à venir).
