# XCM Integration Patterns

**Date** : 2026-02-10
**Projet** : DAO Services IA/Humains
**Version** : 1.0.0

---

## Vue d'ensemble

**XCM** (Cross-Consensus Messaging) est le protocole de communication inter-chaînes de Polkadot. Ce guide couvre les patterns d'intégration pour le projet DAO Services.

---

## 1. XCM Basics

### Principe

XCM est un **meta-protocol** pour communication cross-consensus (pas limité à blockchains).

**Key Concepts** :
- **Consensus Systems** : Polkadot Relay Chain, Parachains, Ethereum (via bridges)
- **Locations** : Adressage universel (`MultiLocation`)
- **Assets** : Tokens cross-chain (`MultiAsset`)
- **Instructions** : Actions à exécuter (`WithdrawAsset`, `BuyExecution`, `Transact`)

### Versioning

| Version | Status | Features |
|---------|--------|----------|
| **XCM v2** | Deprecated | Basic transfers |
| **XCM v3** | Stable (Production-ready) | Fee abstractions, better error handling |
| **XCM v4** | Latest (Q4 2025) | Improved fee mechanisms, enhanced security |

**Recommandation DAO** : Utiliser **XCM v3** pour production (stable), documenter v4 pour future upgrades.

---

## 2. Use Cases DAO

### Architecture Multi-Chain

```
┌─────────────────────────────────────────────────────┐
│              Polkadot Relay Chain                   │
│         (Consensus + Security Provider)             │
└────────────────────┬────────────────────────────────┘
                     │
        ┌────────────┴────────────┐
        │                         │
┌───────▼──────────┐    ┌────────▼─────────┐
│ Asset Hub        │    │ DAO Parachain    │
│ (DOT, USDT,      │◄──►│ (DAO Token,      │
│  stablecoins)    │XCM │  Governance,     │
└──────────────────┘    │  Marketplace)    │
                        └────────┬─────────┘
                                 │
                        ┌────────▼──────────┐
                        │ Snowbridge        │
                        │ (Ethereum Bridge) │
                        └────────┬──────────┘
                                 │
                        ┌────────▼──────────┐
                        │ Ethereum          │
                        │ (DEX Liquidity)   │
                        └───────────────────┘
```

### Use Case 1 : Multi-Chain Treasury

**Problem** : DAO needs to hold multiple assets (DOT, USDT, stablecoins) for payments.

**Solution** : Store assets on Asset Hub, use XCM for transfers.

**Benefits** :
- Asset Hub = secure, low-fee storage
- XCM = trustless transfers
- Treasury diversification (reduce DOT exposure)

---

### Use Case 2 : Cross-Chain Governance

**Problem** : Vote on proposals from any Polkadot parachain.

**Solution** : XCM `Transact` instruction to execute governance calls remotely.

**Benefits** :
- Users don't need DAO parachain tokens
- Vote with DOT/stablecoins
- Increased participation (lower friction)

---

### Use Case 3 : Bridge DAO Token to Ethereum

**Problem** : Limited liquidity on Polkadot, need Ethereum DEX pools.

**Solution** : Snowbridge or Hyperbridge to Ethereum mainnet.

**Benefits** :
- Liquidity access (Uniswap, Balancer)
- Attract Ethereum users
- Multi-chain presence

---

## 3. Pattern : Cross-Chain Asset Transfer

### From Asset Hub to DAO Parachain

**Scenario** : Transfer 1000 DOT from Asset Hub to DAO parachain treasury.

**Code** (`pallets/treasury/src/lib.rs`) :

```rust
use xcm::latest::{prelude::*, Weight as XcmWeight};
use xcm_executor::traits::WeightBounds;

impl<T: Config> Pallet<T> {
    /// Transfer DOT from Asset Hub to DAO parachain
    pub fn transfer_from_asset_hub(
        origin: OriginFor<T>,
        amount: BalanceOf<T>,
        beneficiary: T::AccountId,
    ) -> DispatchResult {
        ensure_root(origin)?; // Only governance can trigger

        // Build XCM message
        let xcm_message = Xcm(vec![
            // Withdraw DOT from Asset Hub treasury
            WithdrawAsset(
                (Parent, amount.saturated_into::<u128>()).into()
            ),

            // Buy execution time on Asset Hub (10% for fees)
            BuyExecution {
                fees: (Parent, amount.saturated_into::<u128>() / 10).into(),
                weight_limit: Unlimited,
            },

            // Deposit asset to beneficiary on DAO parachain
            DepositAsset {
                assets: All.into(),
                beneficiary: Junction::AccountId32 {
                    network: None,
                    id: beneficiary.encode().try_into().unwrap(),
                }
                .into(),
            },
        ]);

        // Send XCM to Asset Hub
        let dest = (Parent, Parachain(ASSET_HUB_PARACHAIN_ID)).into();
        T::XcmSender::send_xcm(dest, xcm_message)
            .map_err(|_| Error::<T>::XcmSendFailed)?;

        Self::deposit_event(Event::AssetTransferInitiated {
            from: "AssetHub".into(),
            to: "DAO Parachain".into(),
            amount,
        });

        Ok(())
    }
}
```

### Configuration

**runtime/src/lib.rs** :

```rust
use xcm_builder::{
    AccountId32Aliases, AllowTopLevelPaidExecutionFrom,
    CurrencyAdapter, FungiblesAdapter, IsConcrete,
    ParentIsPreset, SiblingParachainConvertsVia,
};

parameter_types! {
    pub const RelayLocation: MultiLocation = MultiLocation::parent();
    pub const AssetHubParaId: u32 = 1000;
    pub RelayNetwork: Option<NetworkId> = Some(NetworkId::Polkadot);
}

pub type LocalAssetTransactor = CurrencyAdapter<
    Balances,
    IsConcrete<RelayLocation>,
    LocationToAccountId,
    AccountId,
    (),
>;

pub struct XcmConfig;
impl xcm_executor::Config for XcmConfig {
    type RuntimeCall = RuntimeCall;
    type XcmSender = XcmRouter;
    type AssetTransactor = LocalAssetTransactor;
    type OriginConverter = XcmOriginToTransactDispatchOrigin;
    type IsReserve = NativeAsset;
    type IsTeleporter = ();
    type UniversalLocation = UniversalLocation;
    type Barrier = Barrier;
    type Weigher = FixedWeightBounds<UnitWeightCost, RuntimeCall, MaxInstructions>;
    // ... other config
}
```

---

## 4. Pattern : Cross-Chain Voting

### Remote Governance Call

**Scenario** : User on Asset Hub votes on DAO parachain proposal.

**Code** (`pallets/governance/src/lib.rs`) :

```rust
impl<T: Config> Pallet<T> {
    /// Vote on proposal via XCM (remote chain)
    pub fn vote_xcm(
        origin: OriginFor<T>,
        proposal_id: u32,
        vote: Vote,
        conviction: Conviction,
    ) -> DispatchResult {
        let voter = ensure_signed(origin)?;

        // Build governance call
        let call = RuntimeCall::Governance(GovernanceCall::vote {
            proposal_id,
            vote,
            conviction,
        });

        // Build XCM message
        let xcm_message = Xcm(vec![
            // Withdraw assets for fees (if needed)
            WithdrawAsset((Here, 100_000_000u128).into()),

            // Buy execution
            BuyExecution {
                fees: (Here, 100_000_000u128).into(),
                weight_limit: Limited(Weight::from_parts(1_000_000_000, 64 * 1024)),
            },

            // Execute governance call
            Transact {
                origin_kind: OriginKind::SovereignAccount,
                require_weight_at_most: Weight::from_parts(500_000_000, 32 * 1024),
                call: call.encode().into(),
            },
        ]);

        // Send to DAO parachain
        let dest = (Parent, Parachain(DAO_PARACHAIN_ID)).into();
        T::XcmSender::send_xcm(dest, xcm_message)
            .map_err(|_| Error::<T>::XcmSendFailed)?;

        Self::deposit_event(Event::RemoteVoteSubmitted {
            voter,
            proposal_id,
            vote,
        });

        Ok(())
    }
}
```

### Security Considerations

**Trust Model** :
- XCM `Transact` requires **SovereignAccount** origin (trusted)
- Barrier checks origin legitimacy
- Weight limits prevent DoS

**Barrier Configuration** :

```rust
pub struct Barrier;
impl ShouldExecute for Barrier {
    fn should_execute<RuntimeCall>(
        origin: &MultiLocation,
        instructions: &mut [Instruction<RuntimeCall>],
        max_weight: Weight,
        _weight_credit: &mut Weight,
    ) -> Result<(), ()> {
        // Allow only from trusted parachains
        match origin {
            MultiLocation {
                parents: 1,
                interior: X1(Parachain(id)),
            } if *id == ASSET_HUB_PARACHAIN_ID => Ok(()),
            _ => Err(()),
        }
    }
}
```

---

## 5. Bridge DAO Token Ethereum ↔ Polkadot

### Options

| Bridge | Trust Model | Fees | Status | Recommandation |
|--------|-------------|------|--------|----------------|
| **Snowbridge** | Light client (trustless) | ~$5-10 | Production (Q4 2024) | ✅ Recommandé MVP |
| **Hyperbridge** | ZK proofs (trustless) | ~$1-2 | Beta (Q1 2026) | ⏳ Future |
| **Multi-Sig** | Trust N/M signers | ~$0.50 | Deprecated | ❌ Éviter |

### Pattern : Lock-Mint Bridge (Snowbridge)

**Architecture** :

```
Ethereum (Lock DAO Token)
         ↓
    Snowbridge Relayer (monitors events)
         ↓
Polkadot Asset Hub (Mint Wrapped DAO Token)
         ↓ XCM
DAO Parachain (Use Wrapped Token)
```

**Ethereum Side** (`contracts/BridgeLock.sol`) :

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DAOTokenBridge {
    IERC20 public daoToken;
    address public snowbridgeRelayer;

    event TokensLocked(
        address indexed user,
        bytes32 indexed polkadotAccount,
        uint256 amount
    );

    event TokensUnlocked(
        address indexed user,
        uint256 amount,
        bytes32 polkadotTxHash
    );

    constructor(address _daoToken, address _snowbridgeRelayer) {
        daoToken = IERC20(_daoToken);
        snowbridgeRelayer = _snowbridgeRelayer;
    }

    /// Lock tokens for transfer to Polkadot
    function lockTokensForPolkadot(
        uint256 amount,
        bytes32 polkadotAccount
    ) external {
        require(amount > 0, "Amount must be > 0");

        // Transfer tokens to bridge
        daoToken.transferFrom(msg.sender, address(this), amount);

        emit TokensLocked(msg.sender, polkadotAccount, amount);
        // Snowbridge relayer processes this event
    }

    /// Unlock tokens (called by Snowbridge relayer)
    function unlockTokens(
        address user,
        uint256 amount,
        bytes32 polkadotTxHash
    ) external {
        require(msg.sender == snowbridgeRelayer, "Unauthorized");

        daoToken.transfer(user, amount);

        emit TokensUnlocked(user, amount, polkadotTxHash);
    }
}
```

**Polkadot Side** (`pallets/bridge/src/lib.rs`) :

```rust
impl<T: Config> Pallet<T> {
    /// Mint wrapped DAO tokens (Ethereum lock verified)
    pub fn mint_wrapped_tokens(
        origin: OriginFor<T>,
        beneficiary: T::AccountId,
        amount: BalanceOf<T>,
        ethereum_tx_hash: H256,
    ) -> DispatchResult {
        // Only Snowbridge relayer can call
        T::SnowbridgeOrigin::ensure_origin(origin)?;

        // Verify Ethereum lock event via Snowbridge
        ensure!(
            T::Snowbridge::verify_ethereum_event(
                ethereum_tx_hash,
                EthereumEvent::TokensLocked {
                    amount: amount.saturated_into(),
                },
            ),
            Error::<T>::InvalidEthereumProof
        );

        // Mint wrapped DAO tokens
        T::Currency::deposit_creating(&beneficiary, amount);

        Self::deposit_event(Event::WrappedTokensMinted {
            beneficiary,
            amount,
            ethereum_tx_hash,
        });

        Ok(())
    }

    /// Burn wrapped tokens (unlock on Ethereum)
    pub fn burn_wrapped_tokens(
        origin: OriginFor<T>,
        amount: BalanceOf<T>,
        ethereum_recipient: H160,
    ) -> DispatchResult {
        let sender = ensure_signed(origin)?;

        // Burn tokens
        T::Currency::withdraw(
            &sender,
            amount,
            WithdrawReasons::all(),
            ExistenceRequirement::KeepAlive,
        )?;

        // Send XCM to Snowbridge to unlock on Ethereum
        let xcm_message = Xcm(vec![
            UnlockEthereumTokens {
                recipient: ethereum_recipient,
                amount: amount.saturated_into(),
            },
        ]);

        T::XcmSender::send_xcm(
            (Parent, Parachain(SNOWBRIDGE_PARACHAIN_ID)).into(),
            xcm_message,
        )
        .map_err(|_| Error::<T>::XcmSendFailed)?;

        Self::deposit_event(Event::WrappedTokensBurned {
            sender,
            amount,
            ethereum_recipient,
        });

        Ok(())
    }
}
```

---

## 6. Security : Trust Assumptions

### Comparison

| Bridge Type | Trust Model | Attack Vectors | Mitigation |
|-------------|-------------|----------------|------------|
| **Light Client** (Snowbridge) | Verify Ethereum headers | Finality reorg (rare) | Wait 100+ confirmations |
| **ZK Proof** (Hyperbridge) | Cryptographic proof | Implementation bugs | Audit + formal verification |
| **Multi-Sig** | Trust N/M signers | Collusion, key theft | Deprecated (insecure) |
| **Optimistic** | Fraud proofs | Challenge period delay | 7-day withdrawal delay |

**Security Best Practices** :

1. ✅ Use Snowbridge for MVP (production-ready, trustless)
2. ✅ Wait 100+ Ethereum confirmations before minting
3. ✅ Implement withdrawal limits (max 10k DOT/day)
4. ✅ Multi-sig governance for bridge parameters
5. ⚠️ Avoid custom bridges (security risk)

### Emergency Pause

```rust
impl<T: Config> Pallet<T> {
    /// Emergency pause bridge (governance only)
    pub fn pause_bridge(origin: OriginFor<T>) -> DispatchResult {
        ensure_root(origin)?; // Or governance track

        BridgePaused::<T>::put(true);

        Self::deposit_event(Event::BridgePaused);

        Ok(())
    }

    /// Resume bridge
    pub fn resume_bridge(origin: OriginFor<T>) -> DispatchResult {
        ensure_root(origin)?;

        BridgePaused::<T>::put(false);

        Self::deposit_event(Event::BridgeResumed);

        Ok(())
    }
}
```

---

## 7. Testing XCM

### Local Testing with Chopsticks

**Setup** :

```bash
# Install Chopsticks
npm install -g @acala-network/chopsticks

# Fork Polkadot + Asset Hub + DAO parachain
chopsticks --config chopsticks.yml
```

**Config** (`chopsticks.yml`) :

```yaml
relaychain:
  endpoint: wss://rpc.polkadot.io
  runtime-log-level: 5

parachains:
  - endpoint: wss://polkadot-asset-hub-rpc.polkadot.io
    paraId: 1000

  - endpoint: ws://localhost:9944 # DAO parachain (local)
    paraId: 2000
```

**Test XCM Transfer** :

```typescript
// tests/xcm-transfer.test.ts
import { ApiPromise, WsProvider } from '@polkadot/api';

describe('XCM Transfer', () => {
  it('transfers DOT from Asset Hub to DAO parachain', async () => {
    const assetHub = await ApiPromise.create({
      provider: new WsProvider('ws://localhost:8000'), // Chopsticks Asset Hub
    });

    const daoChain = await ApiPromise.create({
      provider: new WsProvider('ws://localhost:8001'), // Chopsticks DAO chain
    });

    // Build XCM message
    const dest = { V3: { parents: 1, interior: { X1: { Parachain: 2000 } } } };
    const beneficiary = {
      V3: {
        parents: 0,
        interior: {
          X1: {
            AccountId32: {
              id: '0x1234...', // Beneficiary on DAO chain
            },
          },
        },
      },
    };
    const assets = {
      V3: [{ id: { Concrete: { parents: 1, interior: 'Here' } }, fun: { Fungible: 1_000_000_000_000 } }],
    };

    // Send XCM
    await assetHub.tx.polkadotXcm
      .limitedReserveTransferAssets(dest, beneficiary, assets, 0, 'Unlimited')
      .signAndSend(alice);

    // Wait for finalization
    await new Promise(resolve => setTimeout(resolve, 12000)); // 2 blocks

    // Verify balance on DAO chain
    const balance = await daoChain.query.system.account(beneficiary);
    expect(balance.data.free.toNumber()).toBeGreaterThan(0);
  });
});
```

---

## 8. XCM v4 Future Features

### Improvements

**XCM v4** (Q4 2025) introduces :
1. **Fee abstractions** : Pay fees in any asset
2. **Better error handling** : Detailed error reports
3. **Asset locks** : Conditional transfers
4. **Improved security** : Enhanced barrier checks

**Migration Path** :

```rust
// XCM v3 (current)
let xcm_v3 = Xcm(vec![
    WithdrawAsset((Parent, 1_000_000_000u128).into()),
    BuyExecution { fees, weight_limit: Unlimited },
    DepositAsset { assets, beneficiary },
]);

// XCM v4 (future)
let xcm_v4 = Xcm(vec![
    WithdrawAsset((Parent, 1_000_000_000u128).into()),
    PayFees { asset: (Parent, 100_000u128).into() }, // New: explicit fee payment
    DepositAsset { assets, beneficiary },
]);
```

**Recommendation** : Implement XCM v3 now, plan v4 migration for Q2 2026.

---

## Références

**Official Documentation** :
- [XCM Format Specification](https://github.com/paritytech/xcm-format)
- [Polkadot Cross-Chain Guide](https://wiki.polkadot.network/docs/learn-xcm)
- [XCM v4 Changes](https://github.com/paritytech/polkadot-sdk/pull/1234)

**Bridges** :
- [Snowbridge Documentation](https://docs.snowbridge.network/)
- [Hyperbridge Overview](https://docs.hyperbridge.network/)

**Testing** :
- [Chopsticks GitHub](https://github.com/AcalaNetwork/chopsticks)
- [XCM Simulator](https://github.com/paritytech/polkadot-sdk/tree/master/xcm/xcm-simulator)

**Production Examples** :
- [Asset Hub XCM Config](https://github.com/polkadot-fellows/runtimes/tree/main/system-parachains/asset-hubs)
- [Moonbeam XCM Integration](https://github.com/moonbeam-foundation/moonbeam/tree/master/pallets/xcm-transactor)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
