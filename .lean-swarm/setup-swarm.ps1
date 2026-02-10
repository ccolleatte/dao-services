# Lean Swarm Setup Script - DAO Services (Blockchain)
# Version: 0.5.0 (Phase 0.5 - Blockchain Adaptation)
# Context: Solidity, Foundry, Polkadot Hub

param(
    [string]$TargetPath = "C:\dev\dao",
    [switch]$SkipValidation
)

$ErrorActionPreference = "Stop"
$startTime = Get-Date

Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Lean Swarm Setup - DAO Services AI" -ForegroundColor Cyan
Write-Host "  Context: Blockchain (Solidity + Foundry)" -ForegroundColor Cyan
Write-Host "========================================`n" -ForegroundColor Cyan

# Step 1: Verify target path exists
Write-Host "[1/7] Verifying target path..." -ForegroundColor Yellow
if (-not (Test-Path $TargetPath)) {
    Write-Host "[ERROR] Target path not found: $TargetPath" -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Target path exists: $TargetPath`n" -ForegroundColor Green

# Step 2: Verify Foundry installation
Write-Host "[2/7] Checking Foundry installation..." -ForegroundColor Yellow
try {
    $forgeVersion = forge --version 2>$null
    if ($forgeVersion) {
        Write-Host "[OK] Foundry installed: $($forgeVersion.Split("`n")[0])`n" -ForegroundColor Green
    } else {
        Write-Host "[WARNING] Foundry not found. Install: https://book.getfoundry.sh/getting-started/installation" -ForegroundColor Yellow
        Write-Host "          Command: curl -L https://foundry.paradigm.xyz | bash`n" -ForegroundColor Yellow
    }
} catch {
    Write-Host "[WARNING] Foundry check failed. Continuing...`n" -ForegroundColor Yellow
}

# Step 3: Create .lean-swarm directory structure
Write-Host "[3/7] Creating directory structure..." -ForegroundColor Yellow
$leanSwarmPath = Join-Path $TargetPath ".lean-swarm"
$lensesPath = Join-Path $leanSwarmPath "lenses"
$metricsPath = Join-Path $leanSwarmPath "metrics"

@($leanSwarmPath, $lensesPath, $metricsPath) | ForEach-Object {
    if (-not (Test-Path $_)) {
        New-Item -ItemType Directory -Path $_ -Force | Out-Null
        Write-Host "  [+] Created: $_" -ForegroundColor Gray
    } else {
        Write-Host "  [OK] Exists: $_" -ForegroundColor Gray
    }
}
Write-Host "[OK] Directory structure ready`n" -ForegroundColor Green

# Step 4: Verify lenses files exist
Write-Host "[4/7] Verifying lenses..." -ForegroundColor Yellow
$lensFiles = @("config.yaml", "lenses\specs.md", "lenses\complexity.md", "lenses\sandbox.md")
$allLensesExist = $true

foreach ($lens in $lensFiles) {
    $lensPath = Join-Path $leanSwarmPath $lens
    if (Test-Path $lensPath) {
        $fileSize = (Get-Item $lensPath).Length
        Write-Host "  [OK] $lens ($fileSize bytes)" -ForegroundColor Gray
    } else {
        Write-Host "  [MISSING] $lens" -ForegroundColor Red
        $allLensesExist = $false
    }
}

if ($allLensesExist) {
    Write-Host "[OK] All lenses present`n" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Missing lenses. Run /architect to generate missing files.`n" -ForegroundColor Red
    if (-not $SkipValidation) {
        exit 1
    }
}

# Step 5: Verify Foundry project structure
Write-Host "[5/7] Verifying Foundry project..." -ForegroundColor Yellow
$foundryToml = Join-Path $TargetPath "foundry.toml"
$contractsPath = Join-Path $TargetPath "contracts\src"
$testsPath = Join-Path $TargetPath "contracts\test"

if (Test-Path $foundryToml) {
    Write-Host "  [OK] foundry.toml found" -ForegroundColor Gray
} else {
    Write-Host "  [WARNING] foundry.toml not found (run: forge init)" -ForegroundColor Yellow
}

if (Test-Path $contractsPath) {
    $contractCount = (Get-ChildItem -Path $contractsPath -Filter "*.sol" -Recurse).Count
    Write-Host "  [OK] contracts/src/ found ($contractCount .sol files)" -ForegroundColor Gray
} else {
    Write-Host "  [WARNING] contracts/src/ not found" -ForegroundColor Yellow
}

if (Test-Path $testsPath) {
    $testCount = (Get-ChildItem -Path $testsPath -Filter "*.t.sol" -Recurse).Count
    Write-Host "  [OK] contracts/test/ found ($testCount test files)" -ForegroundColor Gray
} else {
    Write-Host "  [WARNING] contracts/test/ not found" -ForegroundColor Yellow
}
Write-Host "[OK] Foundry project structure verified`n" -ForegroundColor Green

# Step 6: Run initial validation (if not skipped)
if (-not $SkipValidation) {
    Write-Host "[6/7] Running initial validation..." -ForegroundColor Yellow

    # Test compilation
    Write-Host "  Testing forge build..." -ForegroundColor Gray
    Push-Location $TargetPath
    try {
        $buildOutput = forge build 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Host "  [OK] Contracts compile successfully" -ForegroundColor Gray
        } else {
            Write-Host "  [WARNING] Compilation warnings/errors detected" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARNING] forge build failed: $_" -ForegroundColor Yellow
    }

    # Test suite
    Write-Host "  Testing forge test..." -ForegroundColor Gray
    try {
        $testOutput = forge test --summary 2>&1
        if ($LASTEXITCODE -eq 0) {
            # Extract test count
            $testLine = $testOutput | Select-String "tests passed"
            if ($testLine) {
                Write-Host "  [OK] Tests: $testLine" -ForegroundColor Gray
            } else {
                Write-Host "  [OK] Tests executed" -ForegroundColor Gray
            }
        } else {
            Write-Host "  [WARNING] Some tests failed" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "  [WARNING] forge test failed: $_" -ForegroundColor Yellow
    }

    Pop-Location
    Write-Host "[OK] Initial validation complete`n" -ForegroundColor Green
} else {
    Write-Host "[6/7] Skipping validation (--SkipValidation flag)`n" -ForegroundColor Yellow
}

# Step 7: Setup complete summary
$endTime = Get-Date
$duration = ($endTime - $startTime).TotalSeconds

Write-Host "[7/7] Setup complete!" -ForegroundColor Yellow
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "  Lean Swarm Phase 0.5 - READY" -ForegroundColor Green
Write-Host "========================================`n" -ForegroundColor Cyan

Write-Host "Setup duration: $([math]::Round($duration, 2))s`n" -ForegroundColor Cyan

Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "  1. Validate contracts against lenses:" -ForegroundColor White
Write-Host "     - DAOMembership.sol (310 lines)" -ForegroundColor Gray
Write-Host "     - DAOGovernor.sol (350 lines)" -ForegroundColor Gray
Write-Host "     - DAOTreasury.sol (280 lines)" -ForegroundColor Gray
Write-Host "`n  2. Run Foundry validation commands:" -ForegroundColor White
Write-Host "     forge test -vv" -ForegroundColor Gray
Write-Host "     forge coverage --report summary" -ForegroundColor Gray
Write-Host "     forge snapshot" -ForegroundColor Gray
Write-Host "`n  3. Generate ROI report:" -ForegroundColor White
Write-Host "     Compare with Unrest deployment results" -ForegroundColor Gray
Write-Host ""

# Return setup metrics
return @{
    Duration = $duration
    TargetPath = $TargetPath
    LensesPath = $lensesPath
    MetricsPath = $metricsPath
    FoundryDetected = ($forgeVersion -ne $null)
    ValidationRun = (-not $SkipValidation)
}
