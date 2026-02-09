# Architecture de Gouvernance DAO

**Version** : 1.0.0
**Date** : 2026-02-09
**Status** : Implémenté (Phase 3)

---

## Vue d'Ensemble

Le système de gouvernance de la DAO suit le modèle **OpenGov de Polkadot** avec 3 tracks spécialisés. L'architecture combine :

- **DAOMembership** : Système de rangs hiérarchiques (0-4) avec vote weights triangulaires
- **DAOGovernor** : Gouvernance multi-track avec intégration OpenZeppelin Governor
- **DAOTreasury** : Gestion des fonds avec spending proposals milestone-based
- **TimelockController** : Délai de sécurité avant exécution des propositions

---

## Composants Architecture

### 1. DAOMembership (Déjà Implémenté)

**Responsabilité** : Gestion des membres et calcul des vote weights

**Fonctionnalités** :
- Système de rangs 0-4 (Observateur → Fondateur)
- Durées minimales par rang (Rank 1: 30j, Rank 2: 90j, Rank 3: 180j, Rank 4: 365j)
- Calcul vote weights selon triangular numbers (Rank 0: 0, Rank 1: 1, Rank 2: 3, Rank 3: 6, Rank 4: 10)
- Promote/demote avec vérification durée
- Membres actifs/inactifs

**Tests** : 22/22 passing ✓

---

### 2. DAOGovernor (Nouveau - Implémenté)

**Responsabilité** : Gouvernance multi-track inspirée d'OpenGov Polkadot

#### Tracks Disponibles

| Track | Min Rank | Voting Period | Quorum | Use Cases |
|-------|----------|---------------|--------|-----------|
| **Technical** | Rank 2+ | 7 jours | 66% | Architecture, stack tech, security fixes, audits |
| **Treasury** | Rank 1+ | 14 jours | 51% | Budget allocation, spending proposals, revenue distribution |
| **Membership** | Rank 3+ | 7 jours | 75% | Promote/demote members, rank durations, suspensions |

#### Intégration OpenZeppelin

Le DAOGovernor hérite de :
- `Governor` : Core governance logic
- `GovernorSettings` : Configurable delays/periods
- `GovernorCountingSimple` : For/Against/Abstain voting
- `GovernorVotes` : Integration with vote weights
- `GovernorVotesQuorumFraction` : Quorum percentage-based
- `GovernorTimelockControl` : Security delay before execution

#### Workflow Gouvernance

```
1. Proposal Creation (proposeWithTrack)
   ↓
   Vérification : Proposer rank ≥ Track.minRank
   ↓
2. Voting Delay (1 jour par défaut)
   ↓
3. Voting Period (7-14 jours selon track)
   ↓
   Vote weights calculés via DAOMembership
   ↓
4. Quorum Check (51%-75% selon track)
   ↓
5. Timelock Delay (1 jour)
   ↓
6. Execution (si approuvé)
```

#### Calcul Vote Weights

```solidity
function _getVotes(address account, uint256 blockNumber, bytes memory params)
    internal view override returns (uint256)
{
    // Extract proposal ID and track
    uint256 proposalId = abi.decode(params, (uint256));
    Track track = proposalTrack[proposalId];
    TrackConfig memory config = trackConfigs[track];

    // Get member rank
    uint8 memberRank = membership.getMemberRank(account);

    // Filter: Only members meeting minRank can vote
    if (memberRank < config.minRank) {
        return 0;
    }

    // Return triangular vote weight from DAOMembership
    return membership.calculateVoteWeight(account);
}
```

**Tests** : 11 tests implémentés couvrant :
- Constructor et track configs
- Propose avec vérification rang
- Vote weights rank-based
- Track-specific permissions
- Proposal state flow

---

### 3. DAOTreasury (Nouveau - Implémenté)

**Responsabilité** : Gestion des fonds de la DAO avec spending proposals milestone-based

#### Spending Proposal Workflow

```
1. Create Proposal (createProposal)
   ↓
   Vérification : msg.sender est membre DAO
   Budget check (si catégorie fournie)
   ↓
2. Approval (approveProposal)
   ↓
   Vérification : TREASURER_ROLE
   Max spend limit check (100 ETH par défaut)
   ↓
3. Execution (executeProposal)
   ↓
   Vérifications :
   - Treasury balance suffisant
   - Daily spend limit (500 ETH par défaut)
   - Budget category (si applicable)
   ↓
4. Transfer ETH to beneficiary
```

#### Spending Limits

| Limite | Valeur Par Défaut | Configurable Via |
|--------|-------------------|------------------|
| **Max Single Spend** | 100 ETH | Admin only |
| **Daily Spend Limit** | 500 ETH | Admin only |
| **Budget Category** | Illimité par défaut | Treasurer allocation |

#### Budget Management

```solidity
struct Budget {
    uint256 allocated;  // Total budget alloué
    uint256 spent;      // Montant dépensé
    bool active;        // Budget actif
}
```

**Catégories budgets** : "marketing", "development", "operations", etc.

#### Roles & Permissions

| Role | Capabilities |
|------|-------------|
| **DEFAULT_ADMIN_ROLE** | Grant/revoke roles, update limits |
| **TREASURER_ROLE** | Approve proposals, allocate budgets |
| **SPENDER_ROLE** | Execute approved proposals |
| **DAO Member** | Create spending proposals |

**Tests** : 20 tests implémentés couvrant :
- Proposal creation/approval/execution
- Spending limits (max single, daily)
- Budget allocation/tracking
- Role permissions
- Edge cases (insufficient funds, unauthorized access)

---

### 4. TimelockController (OpenZeppelin)

**Responsabilité** : Délai de sécurité avant exécution des propositions

**Configuration** :
- `minDelay` : 1 jour (86400 secondes)
- `proposers` : [DAOGovernor contract]
- `executors` : [Anyone - after timelock]
- `admin` : Deployer (puis peut être transféré à DAO)

**Avantages** :
- Protection contre propositions malveillantes (24h pour réagir)
- Compatibilité multi-sig externe
- Audit trail complet (events)

---

## Diagramme Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                         DAO GOVERNANCE                       │
└─────────────────────────────────────────────────────────────┘

┌──────────────────┐        ┌──────────────────┐
│  DAOMembership   │◄───────│   DAOGovernor    │
│                  │        │                  │
│  - Ranks 0-4     │        │  - 3 Tracks      │
│  - Vote weights  │        │  - Proposals     │
│  - Active status │        │  - Voting        │
└──────────────────┘        └──────────────────┘
                                     │
                                     │ Queues actions
                                     ▼
                            ┌──────────────────┐
                            │ TimelockController│
                            │                  │
                            │  - 1 day delay   │
                            │  - Security      │
                            └──────────────────┘
                                     │
                                     │ Executes after delay
                                     ▼
                            ┌──────────────────┐
                            │   DAOTreasury    │
                            │                  │
                            │  - Spending      │
                            │  - Budgets       │
                            │  - Limits        │
                            └──────────────────┘
```

---

## Flux de Données

### Création Proposal Technical

```
1. Member (Rank 2+) → DAOGovernor.proposeWithTrack()
   - Target: ServiceMarketplace contract
   - Action: Update fee percentage
   - Track: Technical

2. DAOGovernor vérifie :
   - proposer.rank ≥ 2 ✓
   - Creates proposalId
   - Sets track: Technical

3. Voting delay (1 jour)

4. Voting period (7 jours)
   - Members Rank 2+ vote
   - Vote weights : Rank 2 = 3, Rank 3 = 6, Rank 4 = 10

5. Quorum check : 66% des vote weights

6. IF approved → Timelock (1 jour)

7. Execution → ServiceMarketplace.setFeePercentage()
```

### Spending Proposal Treasury

```
1. Member (Rank 1+) → DAOTreasury.createProposal()
   - Beneficiary: 0xABC...
   - Amount: 50 ETH
   - Category: "development"

2. Treasury vérifie :
   - msg.sender is member ✓
   - Budget "development" : 100 ETH allocated, 30 ETH spent
   - 50 ETH within budget ✓

3. Treasurer → DAOTreasury.approveProposal()
   - Checks maxSingleSpend: 50 ≤ 100 ✓

4. Spender → DAOTreasury.executeProposal()
   - Checks treasury balance ✓
   - Checks daily limit: 400 ETH remaining ✓
   - Updates budget: 30 + 50 = 80 ETH spent
   - Transfers 50 ETH to beneficiary

5. Budget updated :
   - "development": 80/100 ETH spent (80%)
```

---

## Sécurité

### Protections Implémentées

| Protection | Mécanisme |
|------------|-----------|
| **Rank-based permissions** | Technical/Membership tracks limités Rank 2+/3+ |
| **Timelock delay** | 1 jour avant exécution (annulation possible) |
| **Spending limits** | Max single 100 ETH, daily 500 ETH |
| **Budget tracking** | Overspending prevention par catégorie |
| **Reentrancy guard** | Treasury uses OpenZeppelin ReentrancyGuard |
| **Role-based access** | AccessControl pour Treasury operations |
| **Vote weight verification** | Members below minRank cannot vote on track |

### Vecteurs d'Attaque Mitigés

| Attaque | Mitigation |
|---------|------------|
| **Flash loan vote manipulation** | Vote weights basés sur rangs durables (30j-365j min) |
| **Treasury drainage** | Daily limits + max single spend + budget categories |
| **Governance takeover** | High quorums (66%-75%) + Timelock delay |
| **Unauthorized spending** | Role-based access (TREASURER + SPENDER roles) |
| **Rank manipulation** | Promote/demote requires Rank 3+ (Membership track 75% quorum) |

---

## Configuration Déploiement

### Étapes Déploiement

```bash
# 1. Setup environment
export PRIVATE_KEY="0x..."
export RPC_URL="https://paseo-rpc.polkadot.io"

# 2. Deploy contracts
forge script script/DeployGovernance.s.sol:DeployGovernance \
    --rpc-url $RPC_URL \
    --broadcast \
    --verify

# 3. Verify deployment
forge verify-contract <MEMBERSHIP_ADDRESS> DAOMembership \
    --constructor-args $(cast abi-encode "constructor(address)" $DEPLOYER)
```

### Adresses Déployées (Testnet Paseo)

```
DAOMembership:        0x... (À DÉPLOYER)
TimelockController:   0x... (À DÉPLOYER)
DAOGovernor:          0x... (À DÉPLOYER)
DAOTreasury:          0x... (À DÉPLOYER)
```

---

## Tests & Coverage

### Test Suite

| Contract | Tests | Status |
|----------|-------|--------|
| **DAOMembership** | 22 | ✅ 100% passing |
| **DAOGovernor** | 11 | ✅ Implémentés |
| **DAOTreasury** | 20 | ✅ Implémentés |
| **Integration** | - | 🔜 À faire |

### Coverage Objectifs

- **Lignes** : ≥80%
- **Branches** : ≥70%
- **Fonctions** : ≥90%

### Exécution Tests

```bash
# Tests unitaires
forge test --match-path "test/DAOMembership.t.sol" -vv
forge test --match-path "test/DAOGovernor.t.sol" -vv
forge test --match-path "test/DAOTreasury.t.sol" -vv

# Tests intégration (à créer)
forge test --match-path "test/Integration.t.sol" -vv

# Coverage report
forge coverage --report summary
```

---

## Prochaines Étapes

### Phase 3 (En cours - 50% → 100%)

**Semaine actuelle** :
- [x] Implémenter DAOGovernor.sol (3 tracks)
- [x] Implémenter DAOTreasury.sol (spending proposals)
- [x] Tests unitaires Governor + Treasury (31 tests)
- [ ] Tests intégration (DAOMembership ↔ Governor ↔ Treasury)
- [ ] Coverage report + fixes (target ≥80%)
- [ ] Déploiement testnet Paseo

**Semaine prochaine** :
- [ ] ServiceMarketplace.sol (missions, matching)
- [ ] MissionEscrow.sol (milestone payments)
- [ ] HybridPaymentSplitter.sol (AI/humain/compute)
- [ ] Tests marketplace (30 tests)

### Phase 4 (1-3 mois)

- AI Governance Assistant (proposal analysis)
- Compute Marketplace (GPU/CPU metering)
- Identity Integration (GitHub OAuth + KYC optionnel)
- Analytics Dashboard (Grafana + Prometheus)

---

## Références

### Standards OpenZeppelin

- [Governor Documentation](https://docs.openzeppelin.com/contracts/4.x/governance)
- [TimelockController](https://docs.openzeppelin.com/contracts/4.x/api/governance#TimelockController)
- [AccessControl](https://docs.openzeppelin.com/contracts/4.x/api/access#AccessControl)

### Polkadot OpenGov

- [OpenGov Overview](https://wiki.polkadot.network/docs/learn-opengov)
- [Fellowship Model](https://wiki.polkadot.network/docs/learn-polkadot-technical-fellowship)
- [Conviction Voting](https://wiki.polkadot.network/docs/learn-governance#conviction-voting)

### Codebase

- DAOMembership : `contracts/src/DAOMembership.sol`
- DAOGovernor : `contracts/src/DAOGovernor.sol`
- DAOTreasury : `contracts/src/DAOTreasury.sol`
- Tests : `contracts/test/*.t.sol`
- Deploy : `contracts/script/DeployGovernance.s.sol`

---

**Auteur** : Architecture DAO Team
**Révision** : 2026-02-09
**Prochaine révision** : Post Phase 3 completion (2-4 semaines)
