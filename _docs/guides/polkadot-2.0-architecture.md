# Polkadot 2.0 Architecture Guide

**Date** : 2026-02-10
**Projet** : DAO Services IA/Humains
**Version** : 1.0.0

---

## Vue d'ensemble

Polkadot 2.0 (lancé 2024-2025) introduit des améliorations majeures de performance, flexibilité économique et scalabilité. Ce guide détaille les fonctionnalités clés pertinentes pour le projet DAO Services.

---

## 1. Async Backing (Live depuis Mai 2024)

### Principe

**Async Backing** permet la validation parallèle des blocks candidates au lieu d'une validation séquentielle, doublant le throughput du réseau.

**Impact Performance** :
- Block time : 12s → 6s (2× amélioration)
- Finality time : Réduit de 50%
- Throughput : Jusqu'à 2× transactions/seconde

### Optimisations DAO

**Pattern : Batching Transactions**
```solidity
// Grouper petites transactions pour maximiser throughput
function batchCreateMissions(
    string[] calldata descriptions,
    uint256[] calldata budgets
) external {
    require(descriptions.length == budgets.length, "Length mismatch");

    for (uint256 i = 0; i < descriptions.length; i++) {
        _createMission(descriptions[i], budgets[i]);
    }

    emit MissionsBatchCreated(descriptions.length);
}
```

**Use Case** : Créer 10 missions en un seul bloc au lieu de 10 blocs séparés (60s → 6s).

### Benchmark Target

- **Avant** : 1 mission/6s = 10 missions/min
- **Après** : 10 missions/6s = 100 missions/min (async backing + batching)

**Test sur Paseo** :
```bash
# Mesurer latency improvement
forge script script/BenchmarkAsync.s.sol \
    --rpc-url https://paseo-rpc.polkadot.io \
    --broadcast
```

---

## 2. Agile Coretime (Live depuis Q3 2024)

### Principe

**Agile Coretime** transforme le modèle économique Polkadot :
- **Avant** : Parachain slots (leases 48 semaines, ~2M DOT)
- **Après** : Pay-per-use blockspace (rent cores on-demand)

### Modèle Économique

| Modèle | Coût Initial | Coût Mensuel | Flexibilité |
|--------|--------------|--------------|-------------|
| **Parachain Lease** | 2M DOT (~$14M USD) | 0 DOT (locked) | Fixe |
| **Agile Coretime** | 0 DOT | Variable (usage-based) | Totale |

**Calcul ROI** (breakeven parachain vs coretime) :

```
Parachain cost = 2M DOT × 24 months = 83,333 DOT/month (amortized)
Coretime cost = Price per core × Usage hours

Breakeven = 83,333 DOT/month / Coretime price per core
```

**Exemple** :
- Coretime : 100 DOT/core/hour
- Usage : 24h/day × 30 days = 720 hours/month
- Cost : 72,000 DOT/month
- **Conclusion** : Coretime < Parachain jusqu'à ~1000 cores/month usage

### Décision DAO

**Phase MVP (0-12 mois)** :
- ✅ Utiliser Agile Coretime (on-demand)
- ✅ Rent cores during peak usage (mission matching, voting periods)
- ❌ Éviter parachain lease (capital lock, inflexible)

**Phase Scaling (12-24 mois)** :
- Si throughput > 100 missions/day constant → Envisager parachain
- Threshold : 1000+ transactions/day = parachain rentable

### Pattern : Peak Usage Rental

```rust
// Rent core pendant voting period (3 jours)
fn rent_core_for_voting(proposal_id: u32) {
    let voting_duration = 3 * 24; // hours
    let core_price = broker_pallet::get_core_price();

    broker_pallet::purchase_core(
        duration: voting_duration,
        max_price: core_price,
    );

    // Release after voting ends
    schedule_core_release(proposal_id, voting_duration);
}
```

---

## 3. Elastic Scaling (Live depuis Oct 2025)

### Principe

**Elastic Scaling** permet l'exécution parallèle sur multi-cores, atteignant 100k+ TPS théoriques.

**Architecture** :
```
Core 1: Process missions region EMEA
Core 2: Process missions region Americas
Core 3: Process missions region APAC
Core 4: Process payments + treasury
```

### Impact DAO

**Workflows Parallelisables** :
1. **Mission Matching** : Shard by service category (dev, design, marketing)
2. **Payment Splitting** : Process milestones en parallèle
3. **Voting** : Count votes by track simultaneously

**Pattern : Geographic Sharding**

```solidity
// Shard missions by region for parallel processing
enum Region { EMEA, Americas, APAC }

mapping(Region => uint256[]) public regionMissions;

function createMission(
    string calldata description,
    uint256 budget,
    Region region
) external {
    uint256 missionId = _nextMissionId++;
    missions[missionId] = Mission({
        client: msg.sender,
        description: description,
        budget: budget,
        region: region,
        status: Status.Open
    });

    regionMissions[region].push(missionId);
    emit MissionCreated(missionId, region);
}
```

### Weight Calculation vs Gas

**Substrate Weight Model** :
- Weight = Computational cost (ref_time) + Storage cost (proof_size)
- Target : 500ms block execution time (80% capacity)

**Conversion approximative** :
- 1 gas unit (EVM) ≈ 25,000 weight units (Substrate)
- Mission creation : ~50k gas ≈ 1.25M weight

**Benchmark Target** :
- Sequential : 100 missions/block (6s)
- Parallel (4 cores) : 400 missions/block (6s) = 4000 missions/min

### Testing Elastic Scaling

```bash
# Deploy to 4-core testnet configuration
cargo build --release --features elastic-scaling

# Benchmark parallel execution
./target/release/dao-node benchmark \
    --pallet missions \
    --extrinsic create_mission \
    --cores 4 \
    --steps 50 \
    --repeat 20
```

---

## 4. XCM v3/v4 Cross-Chain

### Principe

**XCM** (Cross-Consensus Messaging) est le protocole de communication inter-chaînes Polkadot.

**Versions** :
- **XCM v3** : Production-ready (stable)
- **XCM v4** : Latest (fee abstractions, improved security)

### Use Case DAO : Multi-Chain Treasury

**Architecture** :
```
Polkadot Asset Hub (DOT + USDT)
         ↕ XCM
DAO Parachain (Native DAO Token + Governance)
         ↕ Snowbridge
Ethereum (Liquidity Pool DAO/ETH)
```

**Pattern : Cross-Chain Asset Transfer**

```rust
// Transfer DOT from Asset Hub to DAO parachain
pub fn transfer_from_asset_hub(
    beneficiary: AccountId,
    amount: Balance,
) -> DispatchResult {
    let xcm_message = Xcm(vec![
        WithdrawAsset((Parent, amount).into()),
        BuyExecution {
            fees: (Parent, amount / 10).into(), // 10% for fees
            weight_limit: Unlimited,
        },
        DepositAsset {
            assets: All.into(),
            beneficiary: Junction::AccountId32 {
                id: beneficiary.into(),
                network: None,
            }.into(),
        },
    ]);

    send_xcm::<XcmRouter>(
        (Parent, Parachain(ASSET_HUB_ID)),
        xcm_message,
    )?;

    Ok(())
}
```

### Bridge DAO Token Ethereum ↔ Polkadot

**Options** :

1. **Snowbridge** (Recommandé pour stablecoins)
   - Native Ethereum ↔ Polkadot Asset Hub
   - Trust model : Light client verification
   - Fees : ~$5-10 per transfer

2. **Hyperbridge** (Zero-knowledge proofs)
   - Lower fees (~$1-2)
   - Higher security (ZK proofs)
   - Beta stage (Q1 2026)

**Pattern : Lock-Mint Bridge**

```solidity
// Ethereum side (lock tokens)
function lockTokensForPolkadot(uint256 amount, bytes32 polkadotAccount) external {
    daoToken.transferFrom(msg.sender, address(this), amount);

    emit TokensLocked(msg.sender, polkadotAccount, amount);
    // Snowbridge relayer processes this event
}
```

```rust
// Polkadot side (mint wrapped tokens)
pub fn mint_wrapped_tokens(
    account: AccountId,
    amount: Balance,
    ethereum_tx_hash: H256,
) -> DispatchResult {
    // Verify Ethereum lock via Snowbridge
    ensure!(
        snowbridge::verify_lock(ethereum_tx_hash, amount),
        Error::<T>::InvalidEthereumProof
    );

    // Mint wrapped DAO tokens
    T::Currency::deposit_creating(&account, amount);

    Ok(())
}
```

### Security : Trust Assumptions

| Bridge Type | Trust Model | Security Level | Cost |
|-------------|-------------|----------------|------|
| **Light Client** (Snowbridge) | Trustless (verify headers) | Haute | Moyen |
| **Multi-Sig** | Trust N/M signers | Moyenne | Faible |
| **ZK Proof** (Hyperbridge) | Cryptographic proof | Très Haute | Faible |

**Recommandation DAO** : Snowbridge pour MVP (trustless + production-ready)

---

## Performance Targets DAO

### Throughput Goals

| Metric | Current (Solidity/Paseo) | Target (Elastic Scaling) | Multiplier |
|--------|--------------------------|--------------------------|------------|
| **Missions/block** | 10 | 400 | 40× |
| **Missions/hour** | 6,000 | 240,000 | 40× |
| **Finality time** | 12s | 6s | 2× |
| **Gas cost/mission** | 50k gas | 1.25M weight (~50k gas equiv) | ~1× |

### Scalability Milestones

**Milestone 1 : MVP (Q1 2026)**
- 10 missions/block (Solidity + Async Backing)
- Paseo testnet deployment
- Single core (Agile Coretime)

**Milestone 2 : Beta (Q2-Q3 2026)**
- 50 missions/block (optimized Solidity)
- Mainnet deployment
- 2 cores (peak usage rental)

**Milestone 3 : Production (Q4 2026)**
- 200+ missions/block (Substrate runtime + Elastic Scaling)
- 4 cores permanent
- XCM integration (multi-chain treasury)

**Milestone 4 : Scale (2027)**
- 400+ missions/block (full Elastic Scaling)
- Parachain candidate (if >1000 missions/day)
- Cross-chain governance (XCM voting)

---

## Références

**Official Documentation** :
- [Polkadot 2.0 Launch](https://www.parity.io/blog/polkadot-upgrade-2025-what-you-need-to-know)
- [Async Backing Explained](https://wiki.polkadot.network/docs/learn-async-backing)
- [Agile Coretime Overview](https://wiki.polkadot.network/docs/learn-agile-coretime)
- [Elastic Scaling Guide](https://wiki.polkadot.network/docs/learn-elastic-scaling)
- [XCM Format Specification](https://github.com/paritytech/xcm-format)

**Technical Resources** :
- [GRANDPA Finality Gadget Paper](https://arxiv.org/abs/2007.01560)
- [Polkadot Whitepaper](https://polkadot.network/whitepaper/)
- [Substrate Weight Benchmarking](https://docs.substrate.io/test/benchmark/)

---

**Version** : 1.0.0
**Dernière mise à jour** : 2026-02-10
