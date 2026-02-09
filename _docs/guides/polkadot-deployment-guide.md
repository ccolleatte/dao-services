# Polkadot Deployment Guide

**Date** : 2026-02-10
**Projet** : DAO Services IA/Humains
**Version** : 1.0.0

---

## Vue d'ensemble

Ce guide couvre le déploiement du projet DAO Services sur l'écosystème Polkadot, du testnet à la mainnet.

---

## 1. Testnets Polkadot

### Options

| Testnet | Purpose | Faucet | Use Case DAO |
|---------|---------|--------|--------------|
| **Paseo** | Public testnet (recommandé) | ✅ | MVP deployment, stress testing |
| **Rococo** | Parachain testing | ✅ | XCM integration, parachain candidate |
| **Westend** | Governance testing | ✅ | OpenGov proposals, conviction voting |

**Recommandation** : **Paseo** pour Phase 3 MVP (Solidity deployment + stress testing).

### Paseo Testnet Setup

**Faucet** : https://faucet.polkadot.io/

**RPC Endpoints** :
- Public : `wss://paseo-rpc.polkadot.io`
- Fallback : `wss://paseo.rpc.amforc.com`

**Explorer** :
- Paseo Subscan : https://paseo.subscan.io/

---

## 2. Deployment Solidity (Current Path)

### Phase 3 MVP : Polkadot Hub (EVM-Compatible)

**Architecture** :

```
Solidity Contracts
      ↓
  Foundry Build
      ↓
Deploy to Polkadot Hub (Paseo)
      ↓
Verify Contracts (Blockscout)
      ↓
Integration Tests (Forge)
```

### Setup Foundry

```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Initialize project (if not done)
forge init --force

# Install dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std
```

### Configure Paseo RPC

**Create `.env` file** :

```bash
# .env
RPC_URL="https://paseo-rpc.polkadot.io"
PRIVATE_KEY="0x..." # NEVER commit this
ETHERSCAN_API_KEY="" # For Blockscout verification
```

**Load environment** :

```bash
# PowerShell
Get-Content .env | ForEach-Object {
    $name, $value = $_.Split('=')
    Set-Item -Path "Env:$name" -Value $value
}
```

### Get Testnet Tokens

**Faucet** :
1. Visit https://faucet.polkadot.io/
2. Connect wallet (MetaMask configured for Paseo)
3. Request tokens (1 PAS = testnet DOT)

**Add Paseo Network to MetaMask** :

```json
{
  "chainId": "0x...", // Paseo chain ID (check docs)
  "chainName": "Paseo Testnet",
  "rpcUrls": ["https://paseo-rpc.polkadot.io"],
  "nativeCurrency": {
    "name": "Paseo",
    "symbol": "PAS",
    "decimals": 18
  },
  "blockExplorerUrls": ["https://paseo.subscan.io/"]
}
```

### Deploy Contracts

**Create deployment script** (`script/DeployGovernance.s.sol`) :

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../contracts/DAOGovernance.sol";
import "../contracts/DAOMembership.sol";
import "../contracts/DAOTreasury.sol";
import "../contracts/DAOMarketplace.sol";

contract DeployGovernance is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. Deploy Membership
        DAOMembership membership = new DAOMembership();
        console.log("DAOMembership deployed at:", address(membership));

        // 2. Deploy Treasury
        DAOTreasury treasury = new DAOTreasury(address(membership));
        console.log("DAOTreasury deployed at:", address(treasury));

        // 3. Deploy Governance
        DAOGovernance governance = new DAOGovernance(
            address(membership),
            address(treasury)
        );
        console.log("DAOGovernance deployed at:", address(governance));

        // 4. Deploy Marketplace
        DAOMarketplace marketplace = new DAOMarketplace(
            address(membership),
            address(treasury)
        );
        console.log("DAOMarketplace deployed at:", address(marketplace));

        // 5. Setup roles
        membership.grantRole(membership.GOVERNOR_ROLE(), address(governance));
        treasury.grantRole(treasury.SPENDER_ROLE(), address(marketplace));

        console.log("Deployment complete!");

        vm.stopBroadcast();
    }
}
```

**Run deployment** :

```bash
# Dry run (simulation)
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $Env:RPC_URL \
    --private-key $Env:PRIVATE_KEY

# Real deployment
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $Env:RPC_URL \
    --private-key $Env:PRIVATE_KEY \
    --broadcast \
    --verify \
    --etherscan-api-key $Env:ETHERSCAN_API_KEY

# Save deployment addresses
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $Env:RPC_URL \
    --private-key $Env:PRIVATE_KEY \
    --broadcast \
    --json > deployments/paseo-deployment.json
```

### Verify Deployment

```bash
# Verify contract on Blockscout (Paseo explorer)
forge verify-contract \
    --chain-id <PASEO_CHAIN_ID> \
    --rpc-url $Env:RPC_URL \
    --etherscan-api-key $Env:ETHERSCAN_API_KEY \
    <CONTRACT_ADDRESS> \
    contracts/DAOGovernance.sol:DAOGovernance

# Check deployment
cast call <CONTRACT_ADDRESS> "name()(string)" --rpc-url $Env:RPC_URL
cast call <CONTRACT_ADDRESS> "version()(string)" --rpc-url $Env:RPC_URL
```

### Integration Tests

**Run E2E tests on Paseo** :

```bash
# Set RPC for tests
export FORK_URL=$Env:RPC_URL

# Run integration tests
forge test --fork-url $FORK_URL --match-contract Integration

# Run specific test
forge test --fork-url $FORK_URL --match-test testCreateMissionE2E -vvv
```

---

## 3. Deployment Substrate Runtime (Future Path)

### Architecture

```
Cargo Build Runtime
      ↓
Generate Chain Spec
      ↓
Deploy Collator Node (Paseo)
      ↓
Register Parachain
      ↓
Connect to Relay Chain
```

### Build Runtime

**Prerequisites** :

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add WASM target
rustup target add wasm32-unknown-unknown

# Install Substrate dependencies
# (Windows: use WSL or Docker)
```

**Build** :

```bash
# Build runtime (release mode)
cargo build --release --package dao-runtime

# Build node (collator)
cargo build --release --package dao-node

# Verify build
./target/release/dao-node --version
```

### Generate Chain Spec

**Local spec** (development) :

```bash
# Generate local chain spec
./target/release/dao-node build-spec --chain local > chain-spec.json

# Convert to raw format (WASM runtime embedded)
./target/release/dao-node build-spec \
    --chain chain-spec.json \
    --raw \
    > chain-spec-raw.json
```

**Paseo spec** (testnet) :

```json
// chain-spec.json
{
  "name": "DAO Services Testnet",
  "id": "dao_paseo",
  "chainType": "Live",
  "bootNodes": [],
  "telemetryEndpoints": null,
  "protocolId": "dao",
  "properties": {
    "tokenSymbol": "DAO",
    "tokenDecimals": 12,
    "ss58Format": 42
  },
  "relay_chain": "paseo",
  "para_id": 2000, // Assigned by Paseo
  "genesis": {
    // Genesis state
  }
}
```

### Start Local Node

```bash
# Start local development node
./target/release/dao-node --dev --tmp

# Or persistent storage
./target/release/dao-node \
    --dev \
    --base-path ./data \
    --rpc-port 9944 \
    --rpc-cors all
```

**Access** :
- Polkadot.js Apps : https://polkadot.js.org/apps/?rpc=ws://localhost:9944

### Deploy to Paseo (Collator)

**Requirements** :
- Para ID assigned (register via governance proposal)
- Genesis state exported
- WASM runtime compiled

**Run collator** :

```bash
./target/release/dao-node \
    --collator \
    --chain chain-spec-raw.json \
    --base-path ./data \
    --rpc-port 9944 \
    --rpc-cors all \
    --ws-port 9945 \
    --port 30333 \
    -- \
    --chain paseo \
    --port 30334
```

**Register Parachain** :

```bash
# Via Polkadot.js Apps (Paseo Relay Chain)
# 1. Go to Developer > Sudo
# 2. Call: parasSudoWrapper.sudoScheduleParaInitialize
#    - id: 2000 (Para ID)
#    - genesis: <genesis_state>
#    - validation: <validation_code>
#    - paraKind: true (parachain, not parathread)
```

---

## 4. Mainnet Deployment Checklist

### Pre-Deployment

**Security** :
- [ ] Security audit completed (Trail of Bits, Oak Security)
- [ ] Audit findings remediated
- [ ] Bug bounty program launched

**Testing** :
- [ ] Testnet deployed (Paseo) for 2+ weeks
- [ ] Stress testing : 1000+ transactions
- [ ] Gas optimization : <50k gas per mission
- [ ] E2E workflows validated (create → match → payment)

**Governance** :
- [ ] Governance proposal for mainnet deployment
- [ ] Treasury allocation approved (initial liquidity)
- [ ] Emergency pause mechanism tested

**Infrastructure** :
- [ ] Monitoring : Subscan, Polkadot.js
- [ ] Alerts : PagerDuty, Opsgenie
- [ ] Backup collator nodes (if parachain)

### Deployment Steps

**Solidity Path** :

```bash
# 1. Final audit
# (External auditor review)

# 2. Deploy to Polkadot Hub mainnet
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url <POLKADOT_HUB_MAINNET_RPC> \
    --private-key $Env:PRIVATE_KEY \
    --broadcast \
    --verify

# 3. Verify contracts
forge verify-contract <CONTRACT_ADDRESS> ...

# 4. Initialize governance
cast send <GOVERNANCE_ADDRESS> \
    "initialize(address,address)" \
    <MEMBERSHIP_ADDRESS> \
    <TREASURY_ADDRESS> \
    --rpc-url <MAINNET_RPC> \
    --private-key $Env:PRIVATE_KEY

# 5. Fund treasury
cast send <TREASURY_ADDRESS> \
    "deposit()" \
    --value 100000000000000000000 \ # 100 DOT
    --rpc-url <MAINNET_RPC> \
    --private-key $Env:PRIVATE_KEY
```

**Substrate Path** :

```bash
# 1. Build production runtime
cargo build --release --package dao-runtime

# 2. Generate mainnet chain spec
./target/release/dao-node build-spec \
    --chain polkadot \
    --raw \
    > mainnet-chain-spec-raw.json

# 3. Start collator nodes (3+ for redundancy)
./target/release/dao-node \
    --collator \
    --chain mainnet-chain-spec-raw.json \
    --base-path /data/collator1 \
    -- \
    --chain polkadot

# 4. Register parachain via governance
# (OpenGov proposal on Polkadot Relay Chain)
```

### Post-Deployment

**Monitoring** :

```bash
# Setup Prometheus metrics
./target/release/dao-node \
    --prometheus-external \
    --prometheus-port 9615

# Grafana dashboard
# Import: https://grafana.com/grafana/dashboards/13840
```

**Alerts** :

```yaml
# alerts.yml
groups:
  - name: dao_parachain
    rules:
      - alert: CollatorDown
        expr: up{job="dao-collator"} == 0
        for: 5m
        annotations:
          summary: "Collator node down"

      - alert: HighTxFees
        expr: avg_tx_fee > 0.1
        for: 10m
        annotations:
          summary: "Transaction fees above 0.1 DOT"
```

**Incident Response** :

| Severity | Response Time | Actions |
|----------|---------------|---------|
| **P0 (Critical)** | <15 min | Emergency pause, rollback runtime |
| **P1 (High)** | <1 hour | Hotfix, deploy patch |
| **P2 (Medium)** | <4 hours | Schedule fix, notify users |
| **P3 (Low)** | <24 hours | Backlog, plan fix |

---

## 5. Parachain Path (Phase 5)

### When to Become Parachain

**Conditions** :
- ✅ Throughput > 100 missions/day constant
- ✅ User base > 1000 active users
- ✅ Treasury > 500k DOT (or crowdloan capability)
- ✅ Governance proposal approved

**Benefits** :
- Native XCM integration (no bridges)
- Lower fees (no Agile Coretime costs)
- Dedicated blockspace (predictable performance)

**Costs** :
- ~2M DOT parachain slot (48-week lease)
- Collator infrastructure (3+ nodes)
- Ongoing maintenance

### Crowdloan Strategy

**Target** : 2M DOT (100k contributors × 20 DOT average)

**Rewards** :
- DAO tokens distributed pro-rata
- Early bird bonus (first 1000 contributors: +20%)
- Referral program (5% bonus)

**Timeline** :
- Week 1-4 : Marketing campaign
- Week 5-8 : Crowdloan live
- Week 9-12 : Auction bidding
- Week 13+ : Parachain onboarding

**Crowdloan Pallet Integration** :

```rust
// Use pallet_crowdloan built-in
impl pallet_crowdloan::Config for Runtime {
    type RuntimeEvent = RuntimeEvent;
    type PalletId = CrowdloanPalletId;
    type SubmissionDeposit = SubmissionDeposit;
    type MinContribution = MinContribution;
    type RemoveKeysLimit = RemoveKeysLimit;
    // ...
}
```

### Alternative : Agile Coretime Long-Term

**If throughput < 100 missions/day** :
- ✅ Stay on Agile Coretime (cheaper)
- ✅ Rent cores on-demand (peak usage)
- ❌ Avoid parachain slot (capital lock)

**Cost comparison** (1 year) :

| Model | Upfront Cost | Monthly Cost | Total (1 year) |
|-------|--------------|--------------|----------------|
| **Parachain** | 2M DOT | 0 DOT | 2M DOT (locked) |
| **Agile Coretime** | 0 DOT | 10k DOT (avg) | 120k DOT |

**Breakeven** : 120k DOT / 10k DOT/month = **12 months**

**Decision** : Agile Coretime if <12 months expected usage at current scale.

---

## 6. Rollback & Emergency Procedures

### Runtime Upgrade Rollback

**Scenario** : New runtime version causes issues.

**Procedure** :

```bash
# 1. Prepare rollback runtime (previous version)
cargo build --release --package dao-runtime

# 2. Generate WASM
./target/release/dao-node export-genesis-wasm \
    --chain previous-chain-spec.json \
    > previous-runtime.wasm

# 3. Submit rollback proposal
# (Via governance - emergency track)
polkadot-js-api tx.system.setCode \
    --ws wss://dao-parachain-rpc.io \
    --sudo \
    previous-runtime.wasm

# 4. Fast-track vote (emergency conviction)
```

### Emergency Pause

**Solidity Contracts** :

```solidity
// contracts/Pausable.sol
import "@openzeppelin/contracts/security/Pausable.sol";

contract DAOMarketplace is Pausable {
    function createMission(...) external whenNotPaused {
        // ...
    }

    function emergencyPause() external onlyRole(EMERGENCY_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(DEFAULT_ADMIN_ROLE) {
        _unpause();
    }
}
```

**Substrate Runtime** :

```rust
#[pallet::call]
impl<T: Config> Pallet<T> {
    #[pallet::weight(10_000)]
    pub fn emergency_pause(origin: OriginFor<T>) -> DispatchResult {
        T::EmergencyOrigin::ensure_origin(origin)?;

        EmergencyPaused::<T>::put(true);

        Self::deposit_event(Event::EmergencyPaused);

        Ok(())
    }
}
```

### Data Backup

```bash
# Backup chain state (every 24h)
./target/release/dao-node export-state \
    --chain mainnet-chain-spec-raw.json \
    --pruning archive \
    > backup-$(date +%Y%m%d).json

# Compress
gzip backup-$(date +%Y%m%d).json

# Upload to S3/IPFS
aws s3 cp backup-$(date +%Y%m%d).json.gz s3://dao-backups/
```

---

## 7. Cost Estimation

### Solidity Deployment (Paseo)

| Item | Cost (Testnet) | Cost (Mainnet) |
|------|----------------|----------------|
| **Deployment gas** | 0 PAS (free) | ~10 DOT |
| **Contract verification** | Free | Free |
| **Initial treasury** | 100 PAS | 1000 DOT |
| **Faucet tokens** | Free | N/A |

**Total Testnet** : Free (faucet tokens)
**Total Mainnet** : ~1010 DOT (~$7k USD at $7/DOT)

### Substrate Deployment (Paseo)

| Item | Cost (Testnet) | Cost (Mainnet) |
|------|----------------|----------------|
| **Para ID registration** | 0 PAS (governance) | 50 DOT (deposit) |
| **Collator infrastructure** | $100/month (VPS) | $500/month (dedicated) |
| **Monitoring** | Free (self-hosted) | $100/month (Datadog) |

**Total Testnet** : ~$100/month
**Total Mainnet** : ~$600/month + 50 DOT deposit

---

## Références

**Official Documentation** :
- [Paseo Testnet Guide](https://wiki.polkadot.network/docs/build-networks#paseo-testnet)
- [Parachain Deployment](https://docs.substrate.io/deploy/prepare-to-deploy/)
- [Polkadot.js Apps](https://polkadot.js.org/apps/)

**Tools** :
- [Foundry Book](https://book.getfoundry.sh/)
- [Chopsticks (Forking Tool)](https://github.com/AcalaNetwork/chopsticks)
- [Subscan Explorer](https://paseo.subscan.io/)

**Auditors** :
- [Trail of Bits](https://www.trailofbits.com/)
- [Oak Security](https://www.oaksecurity.io/)
- [Zellic](https://www.zellic.io/)
- [OpenZeppelin Defender](https://defender.openzeppelin.com/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
