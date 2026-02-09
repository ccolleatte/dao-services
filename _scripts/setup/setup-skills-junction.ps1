#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Configure la junction Windows pour acceder aux skills workspace-wide

.DESCRIPTION
    Cree une junction `.claude\skills` pointant vers `C:\dev\.claude\skills`
    pour partager les skills entre tous les projets du workspace.

.PARAMETER Force
    Force la recreation de la junction meme si elle existe deja

.EXAMPLE
    .\setup-skills-junction.ps1
    # Cree la junction si elle n'existe pas

.EXAMPLE
    .\setup-skills-junction.ps1 -Force
    # Supprime et recree la junction

.NOTES
    Source: .claude/rules/skills-index.md - Workspace Skills Sharing pattern
#>

param(
    [switch]$Force
)

# Configuration
$projectRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$junctionPath = Join-Path $projectRoot ".claude\skills"
$targetPath = "C:\dev\.claude\skills"

Write-Host "[Setup] Configuration junction skills" -ForegroundColor Cyan
Write-Host "  Junction: $junctionPath" -ForegroundColor Gray
Write-Host "  Target:   $targetPath" -ForegroundColor Gray

# Verification 1: Target existe
if (-not (Test-Path $targetPath)) {
    Write-Host "[ERREUR] Le repertoire source n'existe pas: $targetPath" -ForegroundColor Red
    Write-Host "  Verifiez que C:\dev\.claude\skills est present" -ForegroundColor Yellow
    exit 1
}

# Verification 2: .claude/ existe
$claudeDir = Join-Path $projectRoot ".claude"
if (-not (Test-Path $claudeDir)) {
    Write-Host "[ERREUR] Le repertoire .claude n'existe pas" -ForegroundColor Red
    Write-Host "  Creez d'abord le repertoire .claude dans le projet" -ForegroundColor Yellow
    exit 1
}

# Verification 3: Junction existe deja
if (Test-Path $junctionPath) {
    $item = Get-Item $junctionPath

    # Verifier si c'est bien une junction/symlink
    if ($item.LinkType -eq "Junction" -or $item.Attributes -match "ReparsePoint") {
        if (-not $Force) {
            Write-Host "[OK] Junction deja configuree" -ForegroundColor Green
            Write-Host "  Utilisez -Force pour recreer" -ForegroundColor Gray
            exit 0
        }

        # Force mode: supprimer l'ancienne junction
        Write-Host "[INFO] Suppression de l'ancienne junction..." -ForegroundColor Yellow
        Remove-Item $junctionPath -Force -ErrorAction Stop
    } else {
        # Ce n'est pas une junction, c'est un vrai repertoire
        Write-Host "[ERREUR] $junctionPath existe mais n'est PAS une junction" -ForegroundColor Red
        Write-Host "  Supprimez manuellement ce repertoire ou utilisez -Force" -ForegroundColor Yellow
        exit 1
    }
}

# Creation de la junction
try {
    Write-Host "[INFO] Creation de la junction..." -ForegroundColor Cyan
    New-Item -ItemType Junction -Path $junctionPath -Target $targetPath -ErrorAction Stop | Out-Null

    # Verification post-creation
    if (Test-Path $junctionPath) {
        $skillCount = (Get-ChildItem $junctionPath -Directory -ErrorAction SilentlyContinue).Count
        Write-Host "[OK] Junction creee avec succes" -ForegroundColor Green
        Write-Host "  Skills disponibles: $skillCount" -ForegroundColor Gray
        exit 0
    } else {
        Write-Host "[ERREUR] Junction non creee (cause inconnue)" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "[ERREUR] Impossible de creer la junction" -ForegroundColor Red
    Write-Host "  $_" -ForegroundColor Yellow
    exit 1
}
