# Deploy and Verify - Paseo Testnet
# PowerShell script to automate deployment workflow

param(
    [switch]$Deploy,
    [switch]$Verify,
    [switch]$SmokeTest,
    [switch]$All
)

$ErrorActionPreference = "Stop"

# Colors for output
function Write-Success { param($Message) Write-Host "[OK] $Message" -ForegroundColor Green }
function Write-Warning { param($Message) Write-Host "[WARNING] $Message" -ForegroundColor Yellow }
function Write-Error { param($Message) Write-Host "[ERROR] $Message" -ForegroundColor Red }
function Write-Info { param($Message) Write-Host "[INFO] $Message" -ForegroundColor Cyan }

# Check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."

    # Check Foundry installation
    try {
        $forgeVersion = forge --version 2>$null
        Write-Success "Foundry installed: $($forgeVersion.Split("`n")[0])"
    } catch {
        Write-Error "Foundry not installed. Install via: curl -L https://foundry.paradigm.xyz | bash"
        exit 1
    }

    # Check .env file
    if (-not (Test-Path ".env")) {
        Write-Error ".env file not found. Create it from .env.example"
        exit 1
    }
    Write-Success ".env file found"

    # Load environment variables
    Get-Content .env | ForEach-Object {
        if ($_ -match '^([^=]+)=(.*)$') {
            [System.Environment]::SetEnvironmentVariable($matches[1], $matches[2], "Process")
        }
    }

    # Check RPC connectivity
    try {
        $chainId = cast chain-id --rpc-url $env:RPC_URL 2>&1
        Write-Success "Connected to Paseo (Chain ID: $chainId)"
    } catch {
        Write-Error "Cannot connect to RPC: $env:RPC_URL"
        exit 1
    }

    # Check deployer balance
    $balance = cast balance $env:ADMIN_ADDRESS --rpc-url $env:RPC_URL
    $balanceEth = [decimal]$balance / 1000000000000000000

    if ($balanceEth -lt 2) {
        Write-Warning "Low balance: $balanceEth PAS (minimum 2 PAS recommended)"
        Write-Info "Get tokens from: https://faucet.polkadot.io/"
    } else {
        Write-Success "Deployer balance: $balanceEth PAS"
    }

    Write-Host ""
}

# Compile contracts
function Build-Contracts {
    Write-Info "Compiling contracts..."

    forge clean | Out-Null
    $buildOutput = forge build --optimize --optimizer-runs 200 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Compilation failed"
        Write-Host $buildOutput
        exit 1
    }

    Write-Success "Contracts compiled successfully"

    # Show contract sizes
    Write-Info "Contract sizes:"
    forge build --sizes | Select-String "DAOMembership|DAOGovernor|DAOTreasury"

    Write-Host ""
}

# Run tests
function Test-Contracts {
    Write-Info "Running tests..."

    $testOutput = forge test -vv 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Tests failed"
        Write-Host $testOutput
        exit 1
    }

    # Count passing tests
    $passCount = ($testOutput | Select-String "\[PASS\]").Count
    Write-Success "All $passCount tests passed"

    Write-Host ""
}

# Deploy contracts
function Deploy-Contracts {
    Write-Info "Deploying to Paseo testnet..."
    Write-Warning "This will use real gas. Press Ctrl+C to cancel."
    Start-Sleep -Seconds 3

    $timestamp = Get-Date -Format "yyyyMMdd-HHmmss"
    $logFile = "deployment-log-$timestamp.txt"

    Write-Info "Deployment log will be saved to: $logFile"

    # Run deployment script
    $deployOutput = forge script script/DeployGovernance.s.sol:DeployGovernance `
        --rpc-url $env:RPC_URL `
        --private-key $env:PRIVATE_KEY `
        --broadcast `
        --verify `
        -vvvv 2>&1 | Tee-Object -FilePath $logFile

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Deployment failed. Check $logFile for details."
        exit 1
    }

    Write-Success "Deployment completed. Log saved to: $logFile"

    # Extract contract addresses from log
    Write-Info "Extracting contract addresses..."

    $membershipAddr = ($deployOutput | Select-String "DAOMembership deployed at: (0x[a-fA-F0-9]{40})").Matches.Groups[1].Value
    $governorAddr = ($deployOutput | Select-String "DAOGovernor deployed at: (0x[a-fA-F0-9]{40})").Matches.Groups[1].Value
    $treasuryAddr = ($deployOutput | Select-String "DAOTreasury deployed at: (0x[a-fA-F0-9]{40})").Matches.Groups[1].Value
    $timelockAddr = ($deployOutput | Select-String "TimelockController deployed at: (0x[a-fA-F0-9]{40})").Matches.Groups[1].Value

    if ($membershipAddr -and $governorAddr -and $treasuryAddr -and $timelockAddr) {
        Write-Success "Contract addresses extracted:"
        Write-Host "  DAOMembership:     $membershipAddr"
        Write-Host "  DAOGovernor:       $governorAddr"
        Write-Host "  DAOTreasury:       $treasuryAddr"
        Write-Host "  TimelockController: $timelockAddr"

        # Save to file
        $addressesFile = "deployed-addresses-$timestamp.txt"
        @"
# Deployed Contracts - Paseo Testnet
# Deployment Date: $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")
# Deployer: $env:ADMIN_ADDRESS

DAOMembership=$membershipAddr
DAOGovernor=$governorAddr
DAOTreasury=$treasuryAddr
TimelockController=$timelockAddr

# Block Explorer
# Membership: https://paseo.subscan.io/account/$membershipAddr
# Governor: https://paseo.subscan.io/account/$governorAddr
# Treasury: https://paseo.subscan.io/account/$treasuryAddr
# Timelock: https://paseo.subscan.io/account/$timelockAddr
"@ | Out-File -FilePath $addressesFile -Encoding UTF8

        Write-Success "Addresses saved to: $addressesFile"
        Write-Info "Update script/VerifyDeployment.s.sol with these addresses"
    } else {
        Write-Warning "Could not extract all contract addresses from log"
    }

    Write-Host ""
}

# Verify deployment
function Verify-Deployment {
    Write-Info "Verifying deployment..."

    # Check if addresses are set in VerifyDeployment.s.sol
    $verifyScript = Get-Content "script/VerifyDeployment.s.sol" -Raw

    if ($verifyScript -match 'address\(0\).*TODO: Update') {
        Write-Error "Update contract addresses in script/VerifyDeployment.s.sol first"
        Write-Info "Use addresses from deployed-addresses-*.txt file"
        exit 1
    }

    # Run verification script
    $verifyOutput = forge script script/VerifyDeployment.s.sol --rpc-url $env:RPC_URL 2>&1

    if ($LASTEXITCODE -ne 0) {
        Write-Error "Verification failed"
        Write-Host $verifyOutput
        exit 1
    }

    Write-Host $verifyOutput
    Write-Success "Verification completed"

    Write-Host ""
}

# Run smoke tests
function Run-SmokeTests {
    Write-Info "Running on-chain smoke tests..."
    Write-Warning "This will use real gas. Press Ctrl+C to cancel."
    Start-Sleep -Seconds 2

    # Load deployed addresses
    $addressFiles = Get-ChildItem "deployed-addresses-*.txt" | Sort-Object LastWriteTime -Descending | Select-Object -First 1

    if (-not $addressFiles) {
        Write-Error "No deployed-addresses-*.txt file found. Deploy contracts first."
        exit 1
    }

    Write-Info "Using addresses from: $($addressFiles.Name)"
    $addresses = Get-Content $addressFiles.FullName | Where-Object { $_ -match '=' }

    $membershipAddr = ($addresses | Where-Object { $_ -match '^DAOMembership=' }).Split('=')[1]
    $governorAddr = ($addresses | Where-Object { $_ -match '^DAOGovernor=' }).Split('=')[1]
    $treasuryAddr = ($addresses | Where-Object { $_ -match '^DAOTreasury=' }).Split('=')[1]

    # Test 1: Check total members
    Write-Info "Test 1: Checking total members..."
    $totalMembers = cast call $membershipAddr "totalMembers()(uint256)" --rpc-url $env:RPC_URL
    Write-Success "Total members: $totalMembers"

    # Test 2: Check Governor track configuration
    Write-Info "Test 2: Checking Governor tracks..."
    $techTrack = cast call $governorAddr "getTrackConfig(uint8)(uint8,uint256,uint256)" 0 --rpc-url $env:RPC_URL
    Write-Success "Technical track configured: $techTrack"

    # Test 3: Check Treasury balance
    Write-Info "Test 3: Checking Treasury balance..."
    $treasuryBalance = cast balance $treasuryAddr --rpc-url $env:RPC_URL
    $treasuryBalanceEth = [decimal]$treasuryBalance / 1000000000000000000
    Write-Success "Treasury balance: $treasuryBalanceEth PAS"

    Write-Success "All smoke tests passed"
    Write-Host ""
}

# Main execution
Write-Host "=== DAO Governance Deployment - Paseo Testnet ===" -ForegroundColor Cyan
Write-Host ""

Test-Prerequisites

if ($All) {
    Build-Contracts
    Test-Contracts
    Deploy-Contracts
    Write-Info "Manual step required: Update script/VerifyDeployment.s.sol with deployed addresses"
    Write-Info "Then run: .\deploy-paseo.ps1 -Verify -SmokeTest"
} else {
    if ($Deploy) {
        Build-Contracts
        Test-Contracts
        Deploy-Contracts
    }

    if ($Verify) {
        Verify-Deployment
    }

    if ($SmokeTest) {
        Run-SmokeTests
    }
}

Write-Success "Script completed successfully"
