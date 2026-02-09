# Deployment Guide - Paseo Testnet

**Network**: Paseo Testnet (Polkadot Hub)
**VM**: PolkaVM (RISC-V)
**Compiler**: Solidity → Revive → RISC-V

---

## Prerequisites

### 1. Install Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Verify installation
forge --version
cast --version
```

### 2. Setup Environment Variables

Create `.env` file in `contracts/` directory:

```bash
# Paseo Testnet RPC
RPC_URL="https://paseo-rpc.polkadot.io"

# Deployer private key (NEVER commit this!)
PRIVATE_KEY="0x..."

# Block explorer (for verification)
ETHERSCAN_API_KEY=""  # Not needed for Paseo

# Initial admin address
ADMIN_ADDRESS="0x..."
```

**Security**: Add `.env` to `.gitignore` (already done)

### 3. Get Testnet Tokens

Visit Paseo faucet: https://faucet.polkadot.io/
- Select "Paseo Testnet"
- Enter your deployer address
- Request tokens (should receive ~10 PAS)

---

## Deployment Steps

### Step 1: Verify Configuration

```bash
cd contracts

# Check RPC connectivity
cast chain-id --rpc-url $RPC_URL

# Check deployer balance
cast balance $ADMIN_ADDRESS --rpc-url $RPC_URL

# Minimum balance: 2 PAS (for gas)
```

### Step 2: Compile Contracts

```bash
# Clean previous builds
forge clean

# Compile with optimization
forge build --optimize --optimizer-runs 200

# Verify no errors
forge build --sizes
```

Expected output:
```
✓ Compiling...
✓ Solc 0.8.20 finished in 2.34s
  DAOMembership - 6.8 KB
  DAOGovernor - 12.4 KB
  DAOTreasury - 8.2 KB
```

### Step 3: Run Tests (Pre-deployment Validation)

```bash
# Run all tests
forge test -vv

# Expected: 59 tests passing (53 unit + 6 integration)
```

**CRITICAL**: All tests must pass before deployment.

### Step 4: Deploy to Paseo

```bash
# Deploy via script
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    -vvvv

# Save deployment output to file
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --broadcast \
    --verify \
    -vvvv | tee deployment-log.txt
```

**Deployment Order** (from script):
1. DAOMembership
2. TimelockController
3. DAOGovernor
4. DAOTreasury
5. Role setup (Timelock → Governor roles)
6. Initial members setup

**Estimated Gas**: ~8,000,000 gas total (~0.5-1 PAS)

### Step 5: Verify Deployment

```bash
# Extract contract addresses from deployment log
export MEMBERSHIP_ADDR="0x..."
export GOVERNOR_ADDR="0x..."
export TREASURY_ADDR="0x..."
export TIMELOCK_ADDR="0x..."

# Verify DAOMembership
cast call $MEMBERSHIP_ADDR "totalMembers()(uint256)" --rpc-url $RPC_URL
# Expected: 1 (founder)

# Verify DAOGovernor tracks
cast call $GOVERNOR_ADDR "getTrackConfig(uint8)(uint8,uint256,uint256)" 0 --rpc-url $RPC_URL
# Expected: Technical track (minRank=2, votingPeriod=50400, quorumPercentage=66)

# Verify Treasury balance
cast balance $TREASURY_ADDR --rpc-url $RPC_URL
# Expected: 0 (not funded yet)

# Verify Timelock roles
cast call $TIMELOCK_ADDR "hasRole(bytes32,address)(bool)" \
    $(cast keccak "PROPOSER_ROLE") \
    $GOVERNOR_ADDR \
    --rpc-url $RPC_URL
# Expected: true
```

### Step 6: Fund Treasury (Optional)

```bash
# Send testnet tokens to treasury
cast send $TREASURY_ADDR \
    --value 100ether \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Verify balance
cast balance $TREASURY_ADDR --rpc-url $RPC_URL
# Expected: 100000000000000000000 (100 ETH/PAS)
```

---

## Post-Deployment Configuration

### 1. Add Initial Members

```bash
# Add member with Rank 1 (Active Contributor)
cast send $MEMBERSHIP_ADDR \
    "addMember(address,uint8)" \
    0xMEMBER_ADDRESS \
    1 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Add member with Rank 2 (Mid-Level)
cast send $MEMBERSHIP_ADDR \
    "addMember(address,uint8)" \
    0xANOTHER_MEMBER \
    2 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Verify total members
cast call $MEMBERSHIP_ADDR "totalMembers()(uint256)" --rpc-url $RPC_URL
```

### 2. Allocate Treasury Budget

```bash
# Allocate 50 ETH to "development" category
cast send $TREASURY_ADDR \
    "allocateBudget(string,uint256)" \
    "development" \
    50000000000000000000 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Verify budget
cast call $TREASURY_ADDR "getBudget(string)(uint256,uint256)" \
    "development" \
    --rpc-url $RPC_URL
# Expected: (50000000000000000000, 0) - allocated, spent
```

### 3. Grant Treasury Roles

```bash
# Grant TREASURER_ROLE to timelock (for governance-approved budgets)
TREASURER_ROLE=$(cast keccak "TREASURER_ROLE")
cast send $TREASURY_ADDR \
    "grantRole(bytes32,address)" \
    $TREASURER_ROLE \
    $TIMELOCK_ADDR \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Grant SPENDER_ROLE to timelock (for governance-approved spending)
SPENDER_ROLE=$(cast keccak "SPENDER_ROLE")
cast send $TREASURY_ADDR \
    "grantRole(bytes32,address)" \
    $SPENDER_ROLE \
    $TIMELOCK_ADDR \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Verify roles
cast call $TREASURY_ADDR \
    "hasRole(bytes32,address)(bool)" \
    $TREASURER_ROLE \
    $TIMELOCK_ADDR \
    --rpc-url $RPC_URL
# Expected: true
```

---

## Smoke Tests (On-chain Validation)

### Test 1: Create Proposal (Technical Track)

```bash
# Encode proposal calldata (example: update treasury budget)
CALLDATA=$(cast calldata "allocateBudget(string,uint256)" "marketing" 20000000000000000000)

# Create proposal (as Rank 2+ member)
cast send $GOVERNOR_ADDR \
    "proposeWithTrack(address[],uint256[],bytes[],string,uint8)" \
    "[$TREASURY_ADDR]" \
    "[0]" \
    "[$CALLDATA]" \
    "Allocate 20 ETH to marketing budget" \
    0 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Get proposal ID from logs
# Expected: ProposalCreated event emitted
```

### Test 2: Vote on Proposal

```bash
# Wait for voting delay (1 block on testnet)
sleep 15

# Cast vote (1 = For, 0 = Against, 2 = Abstain)
cast send $GOVERNOR_ADDR \
    "castVote(uint256,uint8)" \
    PROPOSAL_ID \
    1 \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Check vote weight applied
cast call $GOVERNOR_ADDR \
    "hasVoted(uint256,address)(bool)" \
    PROPOSAL_ID \
    $ADMIN_ADDRESS \
    --rpc-url $RPC_URL
# Expected: true
```

### Test 3: Treasury Spending Proposal

```bash
# Create spending proposal
cast send $TREASURY_ADDR \
    "createProposal(address,uint256,string,string)" \
    0xBENEFICIARY_ADDRESS \
    5000000000000000000 \
    "Payment for consultancy services" \
    "development" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Get proposal ID from logs
# Expected: ProposalCreated event emitted

# Approve proposal (as TREASURER_ROLE)
cast send $TREASURY_ADDR \
    "approveProposal(uint256)" \
    TREASURY_PROPOSAL_ID \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Execute proposal (as SPENDER_ROLE)
cast send $TREASURY_ADDR \
    "executeProposal(uint256,string)" \
    TREASURY_PROPOSAL_ID \
    "development" \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY

# Verify beneficiary received funds
cast balance 0xBENEFICIARY_ADDRESS --rpc-url $RPC_URL
# Expected: 5000000000000000000 (5 ETH/PAS)
```

---

## Contract Addresses (Paseo Testnet)

**IMPORTANT**: Update this section after deployment

```
DAOMembership:     0x...
DAOGovernor:       0x...
DAOTreasury:       0x...
TimelockController: 0x...

Deployment Date:   YYYY-MM-DD
Deployer Address:  0x...
Transaction Hash:  0x...
```

---

## Block Explorer

**Paseo Testnet Explorer**: https://paseo.subscan.io/

- View contract: `https://paseo.subscan.io/account/{CONTRACT_ADDRESS}`
- View transaction: `https://paseo.subscan.io/extrinsic/{TX_HASH}`

---

## Troubleshooting

### Issue: "Insufficient balance"

**Solution**: Request more tokens from faucet or reduce gas limit

```bash
# Check current balance
cast balance $ADMIN_ADDRESS --rpc-url $RPC_URL

# Request more tokens
# https://faucet.polkadot.io/
```

### Issue: "Nonce too low"

**Solution**: Reset nonce or wait for pending transactions

```bash
# Get current nonce
cast nonce $ADMIN_ADDRESS --rpc-url $RPC_URL

# If stuck, manually set nonce in next transaction
--nonce <CURRENT_NONCE + 1>
```

### Issue: "Deployment script fails at role setup"

**Solution**: Verify TimelockController roles manually

```bash
# Check proposer role
cast call $TIMELOCK_ADDR \
    "hasRole(bytes32,address)(bool)" \
    $(cast keccak "PROPOSER_ROLE") \
    $GOVERNOR_ADDR \
    --rpc-url $RPC_URL

# If false, grant manually
cast send $TIMELOCK_ADDR \
    "grantRole(bytes32,address)" \
    $(cast keccak "PROPOSER_ROLE") \
    $GOVERNOR_ADDR \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY
```

### Issue: "Gas estimation failed"

**Solution**: Increase gas limit manually

```bash
# Add --gas-limit flag
--gas-limit 1000000
```

---

## Security Checklist

- [ ] `.env` file in `.gitignore` (never commit private keys)
- [ ] Deployer account secured (hardware wallet recommended for mainnet)
- [ ] All tests passing before deployment
- [ ] Contract addresses verified on block explorer
- [ ] Role setup confirmed (Timelock → Governor, Governor → Treasury)
- [ ] Initial members added with correct ranks
- [ ] Treasury funded (if needed for testing)
- [ ] Smoke tests completed successfully

---

## Next Steps After Deployment

1. **Frontend Integration** (Week +2):
   - Connect Next.js app to deployed contracts
   - Implement wallet connection (RainbowKit)
   - Build governance UI (create proposals, vote, execute)

2. **Monitoring Setup**:
   - Setup event listeners (ProposalCreated, VoteCast, ProposalExecuted)
   - Create dashboard for treasury balance and active proposals
   - Discord notifications for governance events

3. **Marketplace Contracts** (Week +1):
   - ServiceMarketplace.sol
   - MissionEscrow.sol
   - HybridPaymentSplitter.sol

---

**Deployment Target**: 2026-02-12
**Status**: Ready for deployment (all tests passing)
