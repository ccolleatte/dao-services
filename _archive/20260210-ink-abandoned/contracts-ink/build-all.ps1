#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Build all ink! contracts

.DESCRIPTION
    Compile tous les contrats ink! du workspace et génère les fichiers .contract

.PARAMETER Release
    Build en mode release (optimisé)

.PARAMETER Test
    Run tests après build

.EXAMPLE
    .\build-all.ps1
    # Build en mode debug

.EXAMPLE
    .\build-all.ps1 -Release -Test
    # Build release + tests
#>

param(
    [switch]$Release,
    [switch]$Test
)

$ErrorActionPreference = "Stop"

# Colors
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }

Write-Info "=== Building ink! Contracts ==="

# Check cargo-contract
if (-not (Get-Command cargo-contract -ErrorAction SilentlyContinue)) {
    Write-Error "cargo-contract not found. Install with:"
    Write-Host "  cargo install cargo-contract --force"
    exit 1
}

$contracts = @(
    "dao-membership",
    "dao-governor",
    "dao-treasury"
)

$buildMode = if ($Release) { "--release" } else { "" }

foreach ($contract in $contracts) {
    $manifestPath = Join-Path $PSScriptRoot "$contract\Cargo.toml"

    if (-not (Test-Path $manifestPath)) {
        Write-Info "[SKIP] $contract (not implemented yet)"
        continue
    }

    Write-Info "`n[BUILD] $contract"
    try {
        $cmd = "cargo contract build --manifest-path $manifestPath $buildMode"
        Invoke-Expression $cmd

        if ($LASTEXITCODE -eq 0) {
            Write-Success "[OK] $contract built successfully"
        } else {
            Write-Error "[FAIL] $contract build failed"
            exit 1
        }
    } catch {
        Write-Error "[FAIL] $contract build error: $_"
        exit 1
    }
}

# Run tests if requested
if ($Test) {
    Write-Info "`n=== Running Tests ==="

    try {
        cargo test --all
        if ($LASTEXITCODE -eq 0) {
            Write-Success "[OK] All tests passed"
        } else {
            Write-Error "[FAIL] Some tests failed"
            exit 1
        }
    } catch {
        Write-Error "[FAIL] Test error: $_"
        exit 1
    }
}

Write-Success "`n✅ Build complete!"
Write-Info "Artifacts: contracts-ink/target/ink/*.contract"
