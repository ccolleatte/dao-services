# Contract Validation Script - DAO Solidity
# Version: 1.0.0
# Date: 2026-02-10
# Purpose: Automated validation of Solidity contracts against Phase 0.5 criteria

param(
    [switch]$Quick,           # Quick validation (tests only)
    [switch]$Coverage,        # Include coverage analysis
    [switch]$Security,        # Include Slither security scan
    [switch]$Gas,             # Include gas profiling
    [switch]$Full,            # Full validation (all checks)
    [switch]$CI               # CI mode (strict thresholds)
)

$ErrorActionPreference = "Continue"
$startTime = Get-Date

# Color helpers
function Write-Success { param($msg) Write-Host $msg -ForegroundColor Green }
function Write-Warning { param($msg) Write-Host $msg -ForegroundColor Yellow }
function Write-Error { param($msg) Write-Host $msg -ForegroundColor Red }
function Write-Info { param($msg) Write-Host $msg -ForegroundColor Cyan }

Write-Info "`n=========================================="
Write-Info "  DAO Contract Validation"
Write-Info "==========================================`n"

# Navigate to contracts directory
Push-Location "$PSScriptRoot\..\..\contracts"

# Validation results
$results = @{
    TestsPassed = $false
    CoverageLines = 0
    CoverageBranches = 0
    GasSnapshot = $false
    SlitherHigh = 0
    SlitherMedium = 0
    Violations = @()
}

# ============================================
# STEP 1: Foundry Tests
# ============================================

if ($Quick -or $Full -or -not ($Coverage -or $Security -or $Gas)) {
    Write-Info "[Step 1/4] Running Foundry tests..."

    try {
        $testOutput = forge test 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            Write-Success "  [OK] All tests passed"
            $results.TestsPassed = $true

            # Extract test count
            if ($testOutput -match "(\d+) tests passed") {
                $testCount = $matches[1]
                Write-Success "  [OK] $testCount tests passed"
            }
        } else {
            Write-Error "  [FAIL] Tests failed"
            $results.Violations += "Tests failed"
            Write-Host $testOutput
        }
    } catch {
        Write-Error "  [ERROR] Failed to run tests: $_"
        $results.Violations += "Test execution error"
    }

    Write-Host ""
}

# ============================================
# STEP 2: Coverage Analysis
# ============================================

if ($Coverage -or $Full) {
    Write-Info "[Step 2/4] Analyzing coverage..."

    try {
        $coverageOutput = forge coverage --report summary 2>&1 | Out-String

        # Parse coverage metrics
        if ($coverageOutput -match "Lines.*?(\d+\.\d+)%") {
            $results.CoverageLines = [double]$matches[1]
        }

        if ($coverageOutput -match "Branches.*?(\d+\.\d+)%") {
            $results.CoverageBranches = [double]$matches[1]
        }

        # Check thresholds
        $linesTarget = 80
        $branchesTarget = 70

        if ($results.CoverageLines -ge $linesTarget) {
            Write-Success "  [OK] Lines coverage: $($results.CoverageLines)% (target: $linesTarget%)"
        } else {
            Write-Warning "  [WARN] Lines coverage: $($results.CoverageLines)% (target: $linesTarget%)"
            $results.Violations += "Coverage lines below target"
        }

        if ($results.CoverageBranches -ge $branchesTarget) {
            Write-Success "  [OK] Branches coverage: $($results.CoverageBranches)% (target: $branchesTarget%)"
        } else {
            Write-Warning "  [WARN] Branches coverage: $($results.CoverageBranches)% (target: $branchesTarget%)"
            $results.Violations += "Coverage branches below target"
        }

        # Generate detailed report
        if ($Full) {
            Write-Info "  Generating detailed coverage report..."
            forge coverage --report lcov | Out-Null
            Write-Success "  [OK] Coverage report: coverage/lcov.info"
        }
    } catch {
        Write-Error "  [ERROR] Failed to analyze coverage: $_"
        $results.Violations += "Coverage analysis error"
    }

    Write-Host ""
}

# ============================================
# STEP 3: Gas Profiling
# ============================================

if ($Gas -or $Full) {
    Write-Info "[Step 3/4] Gas profiling..."

    try {
        # Generate gas snapshot
        $gasOutput = forge snapshot 2>&1 | Out-String

        if ($LASTEXITCODE -eq 0) {
            Write-Success "  [OK] Gas snapshot generated"
            $results.GasSnapshot = $true

            # Check for regressions
            if (Test-Path ".gas-snapshot") {
                $diffOutput = forge snapshot --diff .gas-snapshot 2>&1 | Out-String

                if ($diffOutput -match "regression") {
                    Write-Warning "  [WARN] Gas regressions detected"
                    $results.Violations += "Gas regressions detected"
                } else {
                    Write-Success "  [OK] No gas regressions"
                }
            }
        } else {
            Write-Warning "  [WARN] Gas snapshot failed"
        }

        # Gas report
        if ($Full) {
            Write-Info "  Generating gas report..."
            forge test --gas-report | Out-File "gas-report.txt"
            Write-Success "  [OK] Gas report: gas-report.txt"
        }
    } catch {
        Write-Error "  [ERROR] Failed to profile gas: $_"
        $results.Violations += "Gas profiling error"
    }

    Write-Host ""
}

# ============================================
# STEP 4: Security Analysis (Slither)
# ============================================

if ($Security -or $Full) {
    Write-Info "[Step 4/4] Security analysis (Slither)..."

    try {
        # Check if Slither is installed
        $slitherVersion = slither --version 2>&1

        if ($LASTEXITCODE -eq 0) {
            # Run Slither
            $slitherOutput = slither . --filter-paths "lib/" --exclude-dependencies --json slither-report.json 2>&1 | Out-String

            # Parse JSON report
            if (Test-Path "slither-report.json") {
                $slitherData = Get-Content "slither-report.json" | ConvertFrom-Json

                $results.SlitherHigh = ($slitherData.results | Where-Object {$_.severity -eq "high"}).Count
                $results.SlitherMedium = ($slitherData.results | Where-Object {$_.severity -eq "medium"}).Count

                if ($results.SlitherHigh -eq 0) {
                    Write-Success "  [OK] Slither High: 0"
                } else {
                    Write-Error "  [FAIL] Slither High: $($results.SlitherHigh)"
                    $results.Violations += "Slither high severity issues"
                }

                if ($results.SlitherMedium -eq 0) {
                    Write-Success "  [OK] Slither Medium: 0"
                } else {
                    Write-Warning "  [WARN] Slither Medium: $($results.SlitherMedium)"
                    $results.Violations += "Slither medium severity issues"
                }

                Write-Success "  [OK] Slither report: slither-report.json"
            }
        } else {
            Write-Warning "  [SKIP] Slither not installed (pip install slither-analyzer)"
        }
    } catch {
        Write-Warning "  [WARN] Failed to run Slither: $_"
    }

    Write-Host ""
}

# ============================================
# SUMMARY
# ============================================

$duration = (Get-Date) - $startTime
Write-Info "=========================================="
Write-Info "  Validation Summary"
Write-Info "==========================================`n"

# Tests
if ($results.TestsPassed) {
    Write-Success "[✓] Tests: PASSED"
} else {
    Write-Error "[✗] Tests: FAILED"
}

# Coverage
if ($Coverage -or $Full) {
    $coverageStatus = if ($results.CoverageLines -ge 80 -and $results.CoverageBranches -ge 70) { "✓" } else { "✗" }
    $coverageColor = if ($results.CoverageLines -ge 80 -and $results.CoverageBranches -ge 70) { "Green" } else { "Yellow" }

    Write-Host "[$coverageStatus] Coverage: Lines $($results.CoverageLines)% | Branches $($results.CoverageBranches)%" -ForegroundColor $coverageColor
}

# Gas
if ($Gas -or $Full) {
    if ($results.GasSnapshot) {
        Write-Success "[✓] Gas: Snapshot generated"
    } else {
        Write-Warning "[!] Gas: Snapshot failed"
    }
}

# Security
if ($Security -or $Full) {
    if ($results.SlitherHigh -eq 0 -and $results.SlitherMedium -eq 0) {
        Write-Success "[✓] Security: No issues"
    } else {
        Write-Warning "[!] Security: $($results.SlitherHigh) high, $($results.SlitherMedium) medium"
    }
}

Write-Host ""
Write-Info "Duration: $([math]::Round($duration.TotalSeconds, 1))s"

# Violations
if ($results.Violations.Count -gt 0) {
    Write-Host ""
    Write-Warning "Violations detected:"
    foreach ($violation in $results.Violations) {
        Write-Warning "  - $violation"
    }
}

# CI mode exit code
if ($CI) {
    if ($results.Violations.Count -gt 0 -or -not $results.TestsPassed) {
        Write-Error "`n[CI] Validation FAILED"
        Pop-Location
        exit 1
    } else {
        Write-Success "`n[CI] Validation PASSED"
        Pop-Location
        exit 0
    }
}

Pop-Location

Write-Host ""
Write-Info "==========================================`n"

# Return results object
return $results
