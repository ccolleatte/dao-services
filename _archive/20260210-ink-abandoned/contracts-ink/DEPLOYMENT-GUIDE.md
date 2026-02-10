# Deployment Guide - Polkadot 2.0 Native (ink!)

Guide rapide pour déployer les contrats ink! sur différents environnements.

---

## 🎯 Environnements Disponibles

| Environnement | RPC Endpoint | Purpose | Faucet |
|---------------|--------------|---------|--------|
| **Local** | `ws://127.0.0.1:9944` | Development | Built-in |
| **Paseo Testnet** | `wss://paseo-rpc.polkadot.io` | Staging | [faucet.polkadot.io](https://faucet.polkadot.io/) |
| **Rococo Contracts** | `wss://rococo-contracts-rpc.polkadot.io` | Testing | [Rococo Faucet](https://paritytech.github.io/polkadot-testnet-faucet/) |
| **Asset Hub (Future)** | `wss://polkadot-asset-hub-rpc.polkadot.io` | Production | - |

---

## 🛠️ Prerequisites

### 1. Install Rust Toolchain

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add wasm target
rustup target add wasm32-unknown-unknown

# Update toolchain
rustup update stable
```

### 2. Install cargo-contract

```bash
cargo install cargo-contract --force --locked
```

### 3. Install Substrate Contracts Node (Local Development)

```bash
cargo install contracts-node --git https://github.com/paritytech/substrate-contracts-node.git --force --locked
```

### 4. Verify Installation

```bash
cargo contract --version
# Expected: cargo-contract-contract 4.x.x

substrate-contracts-node --version
# Expected: substrate-contracts-node 0.x.x
```

---

## 🚀 Déploiement Local (Development)

### Step 1 : Start Local Node

```bash
# Terminal 1 : Start substrate-contracts-node
substrate-contracts-node --dev --tmp

# Output :
# 2024-02-09 23:00:00 Substrate Contracts Node
# 2024-02-09 23:00:00 ✨ version 0.40.0
# 2024-02-09 23:00:00 🏷  Chain specification: Development
# 2024-02-09 23:00:00 🏦 Ready for connections on ws://127.0.0.1:9944
```

### Step 2 : Build Contracts

```bash
# Terminal 2 : Build all contracts
cd contracts-ink

# Build DAOMembership
cargo contract build --manifest-path dao-membership/Cargo.toml --release

# Build DAOGovernor
cargo contract build --manifest-path dao-governor/Cargo.toml --release

# Build DAOTreasury
cargo contract build --manifest-path dao-treasury/Cargo.toml --release
```

**Output** : Bundles `.contract` dans `target/ink/`

### Step 3 : Deploy DAOMembership

```bash
# Upload + Instantiate DAOMembership
cargo contract instantiate \
    dao-membership/target/ink/dao_membership.contract \
    --suri //Alice \
    --execute \
    --skip-confirm

# Output :
#   Contract address: 5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty
#   Gas required: 2,000,000,000
```

**⚠️ IMPORTANT** : Sauvegarder l'adresse du contrat DAOMembership !

### Step 4 : Deploy DAOGovernor

```bash
# Instantiate DAOGovernor (needs DAOMembership address)
cargo contract instantiate \
    dao-governor/target/ink/dao_governor.contract \
    --suri //Alice \
    --args "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty" \
    --execute \
    --skip-confirm

# Output :
#   Contract address: 5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY
```

### Step 5 : Deploy DAOTreasury

```bash
# Instantiate DAOTreasury
cargo contract instantiate \
    dao-treasury/target/ink/dao_treasury.contract \
    --suri //Alice \
    --args "5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty" \
    --execute \
    --skip-confirm

# Output :
#   Contract address: 5CiPPseXPECbkjWCa6MnjNokrgYjMqmKndv2rSnekmSK2DjL
```

---

## 🌐 Déploiement Testnet (Paseo)

### Step 1 : Get Testnet Tokens

1. Visit [https://faucet.polkadot.io/](https://faucet.polkadot.io/)
2. Select **Paseo** network
3. Enter your account address
4. Request tokens (receive ~10 PAS)

### Step 2 : Create Deployment Account

```bash
# Generate new account
subkey generate

# Output :
# Secret seed:       0x1234...
# Public key (hex):  0xabcd...
# SS58 Address:      5Abc...
```

**⚠️ SAVE YOUR SEED PHRASE SECURELY !**

### Step 3 : Deploy to Paseo

```bash
# Deploy DAOMembership to Paseo
cargo contract instantiate \
    dao-membership/target/ink/dao_membership.contract \
    --url wss://paseo-rpc.polkadot.io \
    --suri "YOUR_SEED_PHRASE" \
    --execute \
    --skip-confirm

# Wait for confirmation (~12s block time)
```

### Step 4 : Verify Deployment

```bash
# Query contract info
cargo contract info \
    --url wss://paseo-rpc.polkadot.io \
    --contract 5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty

# Output :
#   Code hash: 0x1234...
#   Storage deposit: 0.1 PAS
#   Contract size: 42 KB
```

---

## 🔍 Interact with Contracts

### Via cargo-contract CLI

```bash
# Call read-only function
cargo contract call \
    --contract 5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty \
    --message get_member_count \
    --suri //Alice \
    --dry-run

# Call state-changing function
cargo contract call \
    --contract 5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty \
    --message add_member \
    --args "5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY" 1 "bob_github" \
    --suri //Alice \
    --execute
```

### Via Polkadot.js Apps

1. Visit [https://polkadot.js.org/apps/](https://polkadot.js.org/apps/)
2. Connect to **Local Node** ou **Paseo**
3. Developer → Contracts
4. Add Existing Contract (paste contract address)
5. Upload ABI (from `target/ink/*.json`)
6. Call functions via UI

---

## 📝 Post-Deployment Setup

### 1. Add Initial Members

```bash
# Add founder (Rank 4)
cargo contract call \
    --contract <MEMBERSHIP_ADDRESS> \
    --message add_member \
    --args "<FOUNDER_ADDRESS>" 4 "founder_github" \
    --suri //Alice \
    --execute

# Add senior members (Rank 2)
cargo contract call \
    --contract <MEMBERSHIP_ADDRESS> \
    --message add_member \
    --args "<MEMBER_ADDRESS>" 2 "member_github" \
    --suri //Alice \
    --execute
```

### 2. Fund Treasury

```bash
# Send 100 tokens to Treasury
cargo contract call \
    --contract <TREASURY_ADDRESS> \
    --message deposit \
    --value 100000000000000000000 \
    --suri //Alice \
    --execute
```

### 3. Create First Proposal

```bash
# Create governance proposal
cargo contract call \
    --contract <GOVERNOR_ADDRESS> \
    --message propose \
    --args 0 "Upgrade protocol to v2" null "0x" \
    --suri //Alice \
    --execute
```

---

## 🐛 Troubleshooting

### Error : "OutOfGas"

**Solution** : Increase gas limit
```bash
cargo contract call \
    --gas 50000000000 \
    ... other args
```

### Error : "Module: Contracts, Error: CodeNotFound"

**Solution** : Upload code first
```bash
cargo contract upload dao-membership/target/ink/dao_membership.contract --suri //Alice
```

### Error : "Connection refused"

**Solution** : Verify node is running
```bash
# Check if substrate-contracts-node is running
ps aux | grep substrate-contracts-node

# Check RPC endpoint
curl -H "Content-Type: application/json" -d '{"id":1, "jsonrpc":"2.0", "method": "system_chain"}' http://127.0.0.1:9944
```

---

## 📊 Gas Costs Estimation

| Operation | Gas Estimate | Cost (PAS @ 0.001) |
|-----------|--------------|-------------------|
| **Deploy DAOMembership** | ~2,000,000,000 | ~0.002 PAS |
| **Deploy DAOGovernor** | ~3,000,000,000 | ~0.003 PAS |
| **Deploy DAOTreasury** | ~2,500,000,000 | ~0.0025 PAS |
| **Add Member** | ~500,000,000 | ~0.0005 PAS |
| **Create Proposal** | ~800,000,000 | ~0.0008 PAS |
| **Cast Vote** | ~600,000,000 | ~0.0006 PAS |
| **Execute Proposal** | ~1,000,000,000 | ~0.001 PAS |

**Total deployment** : ~0.0075 PAS (~$0.01 @ $1/PAS)

---

## 🔐 Security Checklist

- [ ] Seed phrases stored in password manager (NEVER commit to git)
- [ ] Environment variables for prod seeds (not hardcoded)
- [ ] Contract addresses saved in secure location
- [ ] Admin keys rotated after initial setup
- [ ] Testnet deployment validated before mainnet
- [ ] Code audit completed (for production)
- [ ] Backup deployment scripts + ABIs

---

## 📚 Next Steps

1. ✅ Deploy all 3 contracts
2. ✅ Add initial members (minimum 3)
3. ✅ Fund treasury (100+ tokens)
4. 🔜 Test governance workflow (create → vote → execute)
5. 🔜 Frontend integration (Polkadot.js API)
6. 🔜 Monitoring setup (events indexing)

---

**Questions** ? Check [README.md](./README.md) or ink! docs at [use.ink](https://use.ink/)
