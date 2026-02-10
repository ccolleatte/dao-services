# Lentille : Specs (Spécifications Négatives - Blockchain)

**Purpose** : Protéger code existant via spécifications négatives pour smart contracts Solidity.

## Règles Absolues Blockchain

### 1. Security Patterns (CRITICAL)

**NE DOIT PAS** :
- ❌ Reentrancy attacks : Calls externes avant state updates
- ❌ Integer overflow/underflow : Arithmetic sans SafeMath (Solidity <0.8) ou checked math
- ❌ Unchecked external calls : `.call()`, `.delegatecall()` sans vérifier return value
- ❌ tx.origin pour auth : Utiliser `msg.sender` uniquement
- ❌ Block timestamp manipulation : `block.timestamp` pour randomness
- ❌ Uninitialized storage pointers : Variables storage non initialisées
- ❌ Delegate call to untrusted contract : `delegatecall` sur adresses non whitelistées

**DOIT** :
- ✅ Checks-Effects-Interactions pattern : Vérifications → Changements état → Appels externes
- ✅ ReentrancyGuard : Toutes fonctions avec external calls
- ✅ Access control : Roles explicites (OpenZeppelin AccessControl)
- ✅ Input validation : `require()` sur tous paramètres utilisateur
- ✅ Event emission : Emit events pour toutes state changes
- ✅ Pausable : Emergency pause mechanism pour contracts critiques

---

### 2. Gas Optimization Patterns

**NE DOIT PAS** :
- ❌ Unbounded loops : `for(uint i=0; i<array.length; i++)` sur arrays dynamiques
- ❌ Storage reads in loops : Lire storage variable à chaque itération
- ❌ String concatenation : `string.concat()` multiple fois
- ❌ Redundant storage writes : Écrire même valeur multiple fois
- ❌ Large structs in memory : Passer structs entiers par value

**DOIT** :
- ✅ Cache storage reads : `uint256 cachedValue = storageVar;` avant loop
- ✅ Pack storage variables : Group `uint128` + `uint128` = 1 slot
- ✅ Use calldata : `calldata` au lieu de `memory` pour read-only arrays
- ✅ Short-circuit evaluation : `&&` et `||` pour skip expensive checks
- ✅ Immutable/constant : Variables qui ne changent jamais

**Example Gas Optimization** :
```solidity
// ❌ WRONG - Storage reads in loop
for (uint i = 0; i < missions.length; i++) {
    if (missions[i].status == MissionStatus.Active) {
        // Storage read each iteration
    }
}

// ✅ CORRECT - Cache storage read
uint256 length = missions.length;
for (uint i = 0; i < length; i++) {
    Mission memory mission = missions[i]; // Read once
    if (mission.status == MissionStatus.Active) {
        // Use memory copy
    }
}
```

---

### 3. Governance Patterns (OpenGov-inspired)

**NE DOIT PAS** :
- ❌ Single-signature governance : Admin avec pouvoir absolu
- ❌ No timelock : Exécution propositions sans délai
- ❌ Hardcoded quorums : Quorums non configurables
- ❌ Unlimited voting power : Aucun cap sur vote weight
- ❌ No proposal expiration : Propositions ouvertes indéfiniment

**DOIT** :
- ✅ Role-based access : Ranks/roles pour propositions
- ✅ TimelockController : 24-48h delay avant execution
- ✅ Track-specific quorums : Technical (66%), Treasury (51%), Membership (75%)
- ✅ Voting periods : 7-14 jours selon track
- ✅ Proposal expiration : Auto-expire après X jours si pas exécutée

---

### 4. Economic Security Patterns

**NE DOIT PAS** :
- ❌ No spending limits : Aucun cap sur single transaction
- ❌ Unlimited treasury withdrawal : Admin peut vider treasury
- ❌ No daily limits : Pas de rate limiting sur withdrawals
- ❌ Flash loan exploits : Borrow-manipulate-repay dans 1 transaction
- ❌ Price oracle manipulation : Single source pour price feeds

**DOIT** :
- ✅ Spending limits : Max 100 ETH single transaction
- ✅ Daily limits : Max 500 ETH par jour
- ✅ Multi-signature : 2/3 ou 3/5 signers pour large amounts
- ✅ Cooldown periods : 24h entre withdrawals >10 ETH
- ✅ Oracle redundancy : Chainlink + fallback price sources

---

### 5. State Management Patterns

**NE DOIT PAS** :
- ❌ Direct array deletions : `delete array[i]` laisse gaps
- ❌ Unbounded storage growth : Arrays sans size limits
- ❌ Mutable external state : Dépendre de state externe non-immutable
- ❌ Implicit storage layout : Structs sans explicit packing
- ❌ Uninitialized variables : Variables utilisées sans init

**DOIT** :
- ✅ Bounded collections : Max 100 missions per user, etc.
- ✅ Pagination : `getMissions(uint256 offset, uint256 limit)`
- ✅ Swap-and-pop : Supprimer élément array sans gaps
- ✅ Explicit storage packing : Documenter layout avec comments
- ✅ Defensive initialization : Init toutes variables à valeur safe

**Example Bounded Collections** :
```solidity
// ❌ WRONG - Unbounded array
mapping(address => uint256[]) public userMissions;

function addMission(uint256 missionId) external {
    userMissions[msg.sender].push(missionId); // Can grow infinitely
}

// ✅ CORRECT - Bounded with explicit limit
uint256 public constant MAX_MISSIONS_PER_USER = 100;

function addMission(uint256 missionId) external {
    require(
        userMissions[msg.sender].length < MAX_MISSIONS_PER_USER,
        "Mission limit reached"
    );
    userMissions[msg.sender].push(missionId);
}
```

---

### 6. Testing & Verification Patterns

**NE DOIT PAS** :
- ❌ Deploy sans tests : 0 tests = non-deployable
- ❌ Missing edge cases : Happy path uniquement
- ❌ No gas profiling : Pas de gas snapshots
- ❌ Manual verification : Verification scripts absents
- ❌ No integration tests : Unit tests uniquement

**DOIT** :
- ✅ TDD strict : Tests avant code
- ✅ 80%+ coverage : Lines + branches
- ✅ Edge case coverage : 0 values, max values, revert cases
- ✅ Gas snapshots : `forge snapshot` pour track gas changes
- ✅ Integration tests : End-to-end workflows (vote → execute)

---

### 7. Upgradeability Patterns

**NE DOIT PAS** :
- ❌ Direct contract replacement : Changer address sans migration
- ❌ Storage layout changes : Modifier ordre variables en proxy
- ❌ Constructor logic in upgradeable : Use `initialize()` pattern
- ❌ selfdestruct : Deprecated et dangereux
- ❌ No upgrade path : Locked contracts forever

**DOIT** :
- ✅ Proxy pattern : TransparentProxy ou UUPS (OpenZeppelin)
- ✅ Initialize function : Replace constructor pour upgradeable
- ✅ Storage gap : `uint256[50] __gap;` pour future variables
- ✅ Versioning : `uint256 public version = 1;`
- ✅ Timelock upgrades : 48h delay avant upgrade execution

---

## Integration Lean Swarm Modes

### MODE ANALYTIQUE : Security Analysis

**Question** : "Quelles vulnérabilités potentielles dans ce pattern ?"

**Checklist** :
- Reentrancy possible ? (External calls avant state updates)
- Integer overflow/underflow ? (Arithmetic sur user input)
- Access control correct ? (Roles vérifiés)
- Gas DoS possible ? (Unbounded loops)

---

### MODE CONTEXTUEL : Pattern Inventory

**Question** : "Ce pattern existe déjà dans DAOMembership/Governor/Treasury ?"

**Action** :
1. Grep pattern dans contracts existants
2. Identifier helper functions réutilisables
3. Vérifier OpenZeppelin libraries disponibles

**Example** :
```bash
# Chercher patterns reentrancy guard
grep -r "ReentrancyGuard" contracts/src/

# Chercher patterns access control
grep -r "onlyRole" contracts/src/
```

---

### MODE GÉNÉRATIF : Secure Implementation

**Question** : "Générer implémentation respectant specs négatives"

**Workflow** :
1. Vérifier specs négatives applicables
2. Utiliser OpenZeppelin battle-tested libraries
3. Ajouter explicit checks (`require`, `revert`)
4. Emit events pour toutes state changes
5. Ajouter NatSpec comments

---

### MODE ÉVALUATIF : Gas + Security Audit

**Question** : "Gas efficient ? Secure ?"

**Checks** :
1. `forge snapshot` - Gas costs acceptables ?
2. `forge coverage` - Coverage ≥80% ?
3. Manual review - Reentrancy/overflow/access control OK ?
4. Slither static analysis - 0 HIGH/MEDIUM findings ?

**Tools** :
```bash
# Gas profiling
forge test --gas-report

# Coverage
forge coverage --report summary

# Static analysis (if available)
slither contracts/src/
```

---

### MODE ABDUCTIF : Economic/Governance Effects

**Question** : "Effets de second ordre ?"

**Analysis** :
- Economic : Flash loan attacks ? Price manipulation ?
- Governance : Vote buying ? Griefing ?
- Composability : Integration avec autres protocols safe ?

**Example** :
```solidity
// Mission creation fee = anti-spam
// Second-order effect: Could price out legitimate users if fee too high
function createMission(...) external payable {
    require(msg.value >= CREATION_FEE, "Fee required");
    // ...
}
```

---

## Validation Workflow

**AVANT Write/Edit smart contract** :
1. ✅ Lire specs négatives pertinentes (Security, Gas, Governance)
2. ✅ Grep patterns existants (OpenZeppelin, contracts/)
3. ✅ Vérifier OpenZeppelin libraries disponibles
4. ✅ Confirmer tests existent ou seront créés

**APRÈS Implementation** :
1. ✅ `forge test -vv` - 100% passing
2. ✅ `forge coverage` - ≥80% coverage
3. ✅ `forge snapshot --check` - Gas acceptable
4. ✅ Manual security review - 0 HIGH findings

---

## Metrics Tracking

**Dashboard** :
```json
{
  "contracts": {
    "total": 3,
    "coverage": 75,
    "tests_passing": 59,
    "gas_snapshots": ["baseline-20260210.txt"]
  },
  "security": {
    "reentrancy_guards": 3,
    "access_control_checks": 12,
    "input_validations": 18
  },
  "violations": {
    "unbounded_loops": 0,
    "missing_events": 0,
    "no_reentrancy_guard": 0
  }
}
```

---

## Related Contracts

- **DAOMembership.sol** : Ranks, vote weights, member management
- **DAOGovernor.sol** : 3-track governance, voting, execution
- **DAOTreasury.sol** : Spending proposals, budget allocation
- **OpenZeppelin** : AccessControl, ReentrancyGuard, Pausable, Governor

---

**Confidence** : 92% (Blockchain patterns well-established)
**Domain** : Smart contracts Solidity 0.8+
**Security Level** : CRITICAL (financial contracts)
