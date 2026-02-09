# DAO Services - Polkadot 2.0 Native (ink! Contracts)

Migration des smart contracts vers **ink!** pour un déploiement natif sur Polkadot 2.0.

## 🚀 Quick Start

### Prerequisites

```bash
# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

# Add wasm target
rustup target add wasm32-unknown-unknown

# Install cargo-contract
cargo install cargo-contract --force

# Install substrate-contracts-node (local testnet)
cargo install contracts-node --git https://github.com/paritytech/substrate-contracts-node.git
```

### Build Contracts

```bash
cd contracts-ink

# Build all contracts
cargo contract build --manifest-path dao-membership/Cargo.toml --release
cargo contract build --manifest-path dao-governor/Cargo.toml --release
cargo contract build --manifest-path dao-treasury/Cargo.toml --release
```

**Output** : `.contract` bundles dans `target/ink/`

### Run Tests

```bash
# All contracts (automated script)
.\build-all.ps1 -Test

# Individual contracts
cargo test --manifest-path dao-membership/Cargo.toml  # 22 tests
cargo test --manifest-path dao-governor/Cargo.toml    # 13 tests
cargo test --manifest-path dao-treasury/Cargo.toml    # 20 tests

# Integration tests (E2E - pending cross-contract implementation)
cargo test --features e2e-tests
```

**Test Coverage** : 55/53 tests (104% vs Solidity) ✅

### Deploy Locally

```bash
# Start local Substrate node with contracts pallet
substrate-contracts-node --dev

# In another terminal, deploy
cargo contract instantiate dao-membership/target/ink/dao_membership.contract \
    --suri //Alice \
    --execute

# Get contract address from output
```

### Deploy to Paseo Testnet

```bash
# Get testnet tokens
# Visit: https://faucet.polkadot.io/ (Paseo network)

# Deploy to Paseo
cargo contract instantiate dao-membership/target/ink/dao_membership.contract \
    --url wss://paseo-rpc.polkadot.io \
    --suri "YOUR_SEED_PHRASE" \
    --execute
```

## 📦 Contracts

### ✅ dao-membership

**Status** : Migré (310 lignes Solidity → 460 lignes Rust)

**Features** :
- Ranks system (0-4) inspiré Polkadot Fellowship
- Vote weights triangulaires (0, 1, 3, 6, 10)
- Active/inactive member status
- Minimum rank durations (90d → 547d)
- Role-based access (Admin, MemberManager)

**Tests** : 6 unit tests

### 🔜 dao-governor

**Status** : À migrer

**Solidity** : 350 lignes

**Features à implémenter** :
- 3 tracks OpenGov (Technical, Treasury, Membership)
- Rank-based proposal permissions
- Track-specific quorums
- Timelock integration

### 🔜 dao-treasury

**Status** : À migrer

**Solidity** : 280 lignes

**Features à implémenter** :
- Spending proposals workflow
- Budget allocation par catégorie
- Spending limits (max single, daily)
- Role-based access

## 🛠️ Development

### Project Structure

```
contracts-ink/
├── Cargo.toml                 # Workspace root
├── dao-membership/
│   ├── Cargo.toml
│   └── lib.rs                 # Contract code + tests
├── dao-governor/
│   ├── Cargo.toml
│   └── lib.rs
└── dao-treasury/
    ├── Cargo.toml
    └── lib.rs
```

### ink! vs Solidity Comparison

| Feature | Solidity | ink! (Rust) |
|---------|----------|-------------|
| **Language** | Solidity | Rust |
| **Compilation** | EVM bytecode | Wasm |
| **Type system** | Weak | Strong (Rust) |
| **Memory safety** | Manual | Automatic (borrow checker) |
| **Gas model** | Ethereum | Polkadot (weight-based) |
| **Storage** | `mapping`, `array` | `Mapping`, `Vec` |
| **Events** | `event` keyword | `#[ink(event)]` attribute |
| **Modifiers** | `modifier` | Rust functions |
| **Testing** | Foundry/Hardhat | Cargo test |

### Key Differences

#### Storage

```solidity
// Solidity
mapping(address => Member) public members;
address[] public memberAddresses;
```

```rust
// ink!
use ink::storage::Mapping;
use ink::prelude::vec::Vec;

members: Mapping<AccountId, Member>,
member_addresses: Vec<AccountId>,
```

#### Access Control

```solidity
// Solidity
modifier onlyRole(bytes32 role) {
    require(hasRole(role, msg.sender), "Unauthorized");
    _;
}
```

```rust
// ink!
if self.env().caller() != self.admin {
    return Err(Error::Unauthorized);
}
```

#### Events

```solidity
// Solidity
event MemberAdded(address indexed member, uint8 rank);
emit MemberAdded(_member, _rank);
```

```rust
// ink!
#[ink(event)]
pub struct MemberAdded {
    #[ink(topic)]
    member: AccountId,
    rank: u8,
}

Self::env().emit_event(MemberAdded { member, rank });
```

## 📚 Resources

- [ink! Documentation](https://use.ink/)
- [Substrate Contracts](https://docs.substrate.io/tutorials/smart-contracts/)
- [Polkadot Fellowship](https://wiki.polkadot.network/docs/learn-polkadot-technical-fellowship)
- [OpenGov](https://wiki.polkadot.network/docs/learn-polkadot-opengov)

## 🔗 Deployment Targets

### Local Development
- `substrate-contracts-node` (local testnet)

### Testnets
- **Paseo** : wss://paseo-rpc.polkadot.io
- **Rococo Contracts** : wss://rococo-contracts-rpc.polkadot.io

### Mainnet (Future)
- **Polkadot Asset Hub** : wss://polkadot-asset-hub-rpc.polkadot.io
- **Custom Parachain** : Deploy dedicated parachain with contracts pallet

## 📝 Next Steps

1. ✅ **dao-membership** : Migré et testé
2. 🔜 **dao-governor** : Migration en cours
3. 🔜 **dao-treasury** : À démarrer
4. 🔜 **Integration tests** : E2E workflows
5. 🔜 **Frontend** : Polkadot.js integration

## 🤝 Contributing

Cette migration suit strictement la logique des contrats Solidity originaux pour garantir la compatibilité fonctionnelle.

**Tests requis** :
- ✅ Unit tests (Rust)
- 🔜 Integration tests (E2E)
- 🔜 Fuzzing (cargo-fuzz)
- 🔜 Formal verification (optional)

## 📊 Migration Progress

| Contract | Solidity Lines | ink! Lines | Status | Tests |
|----------|----------------|------------|--------|-------|
| dao-membership | 310 | 460 | ✅ Complete | 6/6 passing |
| dao-governor | 350 | - | 🔜 Pending | 0/11 |
| dao-treasury | 280 | - | 🔜 Pending | 0/20 |
| **Total** | **940** | **460** | **33%** | **6/37** |

---

**Version** : 0.1.0-ink
**Last Updated** : 2026-02-09
**License** : MIT
