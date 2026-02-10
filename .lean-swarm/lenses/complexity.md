# Lentille : Complexity (Gestion Complexité - Blockchain)

**Purpose** : Limiter complexité cognitive pour smart contracts Solidity sécurisés et maintenables.

## Règles Absolues Blockchain

### 1. Function Length Limits (STRICTER)

**NE DOIT PAS** :
- ❌ Fonctions >50 lignes (vs 80 TypeScript)
- ❌ Constructeurs >30 lignes
- ❌ Modifiers >20 lignes
- ❌ Fallback/receive >10 lignes

**DOIT** :
- ✅ Fonctions <50 lignes (target <30)
- ✅ Une responsabilité par fonction
- ✅ Extraire logique complexe en helpers internes

**Rationale** :
- Security audits : Code court = review facile
- Gas optimization : Fonctions courtes = inline candidates
- Bug surface : -60% bugs dans fonctions <30 lignes

**Example** :
```solidity
// ❌ WRONG - God Function (85 lignes)
function createProposal(
    string memory description,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    ProposalType proposalType
) public returns (uint256) {
    // Validation (15 lignes)
    require(msg.sender != address(0), "Invalid sender");
    require(bytes(description).length > 0, "Empty description");
    require(targets.length > 0, "No targets");
    require(targets.length == values.length, "Length mismatch");
    require(targets.length == calldatas.length, "Length mismatch");
    require(targets.length <= 10, "Too many actions");

    // Check proposer rank (10 lignes)
    uint256 proposerRank = membership.getRank(msg.sender);
    uint256 requiredRank = _getRequiredRank(proposalType);
    require(proposerRank >= requiredRank, "Insufficient rank");

    // Generate proposal ID (5 lignes)
    uint256 proposalId = uint256(keccak256(
        abi.encodePacked(description, block.timestamp, msg.sender)
    ));
    require(proposals[proposalId].startTime == 0, "Proposal exists");

    // Calculate quorum (15 lignes)
    uint256 totalVotingPower = membership.getTotalVotingPower();
    uint256 quorum;
    if (proposalType == ProposalType.Technical) {
        quorum = (totalVotingPower * 66) / 100; // 66%
    } else if (proposalType == ProposalType.Treasury) {
        quorum = (totalVotingPower * 51) / 100; // 51%
    } else {
        quorum = (totalVotingPower * 75) / 100; // 75%
    }

    // Store proposal (20 lignes)
    proposals[proposalId] = Proposal({
        id: proposalId,
        proposer: msg.sender,
        description: description,
        targets: targets,
        values: values,
        calldatas: calldatas,
        proposalType: proposalType,
        startTime: block.timestamp,
        endTime: block.timestamp + votingPeriod,
        quorum: quorum,
        forVotes: 0,
        againstVotes: 0,
        abstainVotes: 0,
        executed: false,
        cancelled: false
    });

    // Emit events (10 lignes)
    emit ProposalCreated(
        proposalId,
        msg.sender,
        description,
        proposalType,
        block.timestamp,
        block.timestamp + votingPeriod
    );

    return proposalId;
}

// ✅ CORRECT - Extracted Helpers (<50 lignes chacune)
function createProposal(
    string memory description,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas,
    ProposalType proposalType
) public returns (uint256) {
    _validateProposalInputs(description, targets, values, calldatas);
    _checkProposerPermissions(proposalType);

    uint256 proposalId = _generateProposalId(description);
    uint256 quorum = _calculateQuorum(proposalType);

    _storeProposal(proposalId, description, targets, values, calldatas, proposalType, quorum);
    _emitProposalCreatedEvent(proposalId, proposalType);

    return proposalId;
}

function _validateProposalInputs(
    string memory description,
    address[] memory targets,
    uint256[] memory values,
    bytes[] memory calldatas
) private pure {
    require(bytes(description).length > 0, "Empty description");
    require(targets.length > 0, "No targets");
    require(targets.length == values.length, "Length mismatch");
    require(targets.length == calldatas.length, "Length mismatch");
    require(targets.length <= 10, "Too many actions");
}

function _checkProposerPermissions(ProposalType proposalType) private view {
    uint256 proposerRank = membership.getRank(msg.sender);
    uint256 requiredRank = _getRequiredRank(proposalType);
    require(proposerRank >= requiredRank, "Insufficient rank");
}

// ... autres helpers <30 lignes chacun
```

---

### 2. Cyclomatic Complexity (STRICTER)

**NE DOIT PAS** :
- ❌ Complexity >4 (vs 6 TypeScript)
- ❌ Nested if >2 levels
- ❌ Switch >5 cases
- ❌ For loops avec logique conditionnelle complexe

**DOIT** :
- ✅ Complexity <4 (target 2-3)
- ✅ Early returns pour simplifier
- ✅ Guard clauses au lieu de nested if
- ✅ Mapping lookups au lieu de switch

**Example** :
```solidity
// ❌ WRONG - Complexity 7
function getQuorum(ProposalType pType, uint256 totalPower) public pure returns (uint256) {
    if (pType == ProposalType.Technical) {
        if (totalPower > 1000) {
            return (totalPower * 70) / 100;
        } else {
            return (totalPower * 66) / 100;
        }
    } else if (pType == ProposalType.Treasury) {
        if (totalPower > 1000) {
            return (totalPower * 55) / 100;
        } else {
            return (totalPower * 51) / 100;
        }
    } else {
        return (totalPower * 75) / 100;
    }
}

// ✅ CORRECT - Complexity 2 (mapping lookup)
mapping(ProposalType => uint256) public baseQuorumPercentage;

constructor() {
    baseQuorumPercentage[ProposalType.Technical] = 66;
    baseQuorumPercentage[ProposalType.Treasury] = 51;
    baseQuorumPercentage[ProposalType.Membership] = 75;
}

function getQuorum(ProposalType pType, uint256 totalPower) public view returns (uint256) {
    uint256 percentage = baseQuorumPercentage[pType];
    return (totalPower * percentage) / 100;
}
```

---

### 3. Contract Responsibilities (SINGLE RESPONSIBILITY)

**NE DOIT PAS** :
- ❌ >3 responsabilités par contract (vs 5 TypeScript)
- ❌ Mélanger business logic + access control + events
- ❌ God contracts >500 lignes
- ❌ Contracts sans séparation concerns

**DOIT** :
- ✅ 1-3 responsabilités MAX par contract
- ✅ Séparation : Storage / Logic / Interface
- ✅ Composition via interfaces au lieu d'héritage multiple
- ✅ Libraries pour logique réutilisable

**Example** :
```solidity
// ❌ WRONG - God Contract (5 responsabilités)
contract DAOMarketplace {
    // Responsibility 1: Member management
    mapping(address => Member) public members;
    function addMember(...) public { }

    // Responsibility 2: Mission management
    mapping(uint256 => Mission) public missions;
    function createMission(...) public { }

    // Responsibility 3: Payment handling
    function processMissionPayment(...) public { }

    // Responsibility 4: Reputation scoring
    function updateReputation(...) public { }

    // Responsibility 5: Treasury management
    function withdrawFromTreasury(...) public { }
}

// ✅ CORRECT - Separated Contracts (1-2 responsabilités chacun)
contract DAOMembership {
    // Responsibility: Member lifecycle + ranks
    mapping(address => Member) public members;
    function addMember(...) public { }
    function promoteToRank(...) public { }
}

contract DAOMissions {
    // Responsibility: Mission lifecycle
    mapping(uint256 => Mission) public missions;
    function createMission(...) public { }
    function completeMission(...) public { }
}

contract DAOTreasury {
    // Responsibility: Treasury operations
    function processMissionPayment(...) public { }
    function withdrawFromTreasury(...) public { }
}
```

---

### 4. DRY Violations (STRICTER)

**NE DOIT PAS** :
- ❌ Code dupliqué ≥2 fois (vs 3 TypeScript)
- ❌ Magic numbers répétés
- ❌ Validation logic dupliquée
- ❌ Event emission patterns répétés

**DOIT** :
- ✅ Extraire en constants si utilisé 2×
- ✅ Modifiers pour validations répétées
- ✅ Internal functions pour logique commune
- ✅ Libraries pour patterns cross-contracts

**Example** :
```solidity
// ❌ WRONG - Magic Numbers Duplicated (3 endroits)
function validateProposal() public {
    require(proposalVotes >= (totalVotes * 66) / 100, "Quorum not met");
}

function executeProposal() public {
    require(proposalVotes >= (totalVotes * 66) / 100, "Quorum not met");
}

function checkQuorumReached() public view returns (bool) {
    return proposalVotes >= (totalVotes * 66) / 100;
}

// ✅ CORRECT - Extracted Constant
uint256 public constant TECHNICAL_QUORUM_PERCENTAGE = 66;

function validateProposal() public {
    require(_meetsQuorum(proposalVotes), "Quorum not met");
}

function executeProposal() public {
    require(_meetsQuorum(proposalVotes), "Quorum not met");
}

function _meetsQuorum(uint256 votes) private view returns (bool) {
    return votes >= (totalVotes * TECHNICAL_QUORUM_PERCENTAGE) / 100;
}
```

---

### 5. Gas Optimization Complexity

**NE DOIT PAS** :
- ❌ Storage reads dans loops
- ❌ String concatenation multiple
- ❌ Redundant SLOAD (re-read storage)
- ❌ Large structs passed by value

**DOIT** :
- ✅ Cache storage variables avant loop
- ✅ Pack storage variables (uint128 + uint128 = 1 slot)
- ✅ Use calldata pour read-only arrays
- ✅ Immutable/constant pour valeurs fixes

**Example** :
```solidity
// ❌ WRONG - Storage Read in Loop (complexity + gas)
function countActiveMissions() public view returns (uint256) {
    uint256 count = 0;
    for (uint256 i = 0; i < missions.length; i++) {
        if (missions[i].status == MissionStatus.Active) { // SLOAD chaque iteration
            count++;
        }
    }
    return count;
}

// ✅ CORRECT - Cached Storage Read
function countActiveMissions() public view returns (uint256) {
    uint256 count = 0;
    uint256 length = missions.length; // Cache length
    for (uint256 i = 0; i < length; i++) {
        Mission memory mission = missions[i]; // Read once en memory
        if (mission.status == MissionStatus.Active) {
            count++;
        }
    }
    return count;
}
```

---

### 6. State Variable Complexity

**NE DOIT PAS** :
- ❌ >15 state variables par contract
- ❌ Unbounded arrays (DoS attack vector)
- ❌ Nested mappings >2 levels
- ❌ Public arrays sans pagination

**DOIT** :
- ✅ Group related state en structs
- ✅ Bound all collections (MAX_MISSIONS = 100)
- ✅ Pagination pour arrays publics
- ✅ Use EnumerableSet pour iteration safe

**Example** :
```solidity
// ❌ WRONG - Unbounded Array (DoS vulnerability)
uint256[] public allMissionIds;

function getAllMissions() public view returns (uint256[] memory) {
    return allMissionIds; // Can grow infinitely, DoS attack
}

// ✅ CORRECT - Bounded + Pagination
uint256[] public allMissionIds;
uint256 public constant MAX_MISSIONS = 1000;

function addMission(uint256 missionId) public {
    require(allMissionIds.length < MAX_MISSIONS, "Mission limit reached");
    allMissionIds.push(missionId);
}

function getMissions(uint256 offset, uint256 limit) public view returns (uint256[] memory) {
    require(offset < allMissionIds.length, "Invalid offset");

    uint256 end = offset + limit;
    if (end > allMissionIds.length) {
        end = allMissionIds.length;
    }

    uint256[] memory result = new uint256[](end - offset);
    for (uint256 i = offset; i < end; i++) {
        result[i - offset] = allMissionIds[i];
    }

    return result;
}
```

---

## Integration Lean Swarm Modes

### MODE ANALYTIQUE : Identify Complexity Hotspots

**Question** : "Cette fonction dépasse-t-elle les seuils ?"

**Checklist** :
- Lines > 50 ?
- Cyclomatic complexity > 4 ?
- Responsabilités > 3 ?
- Code dupliqué ≥2× ?

---

### MODE CONTEXTUEL : Find Existing Helpers

**Question** : "Cette logique existe-t-elle déjà ?"

**Action** :
1. Grep pattern dans contracts/
2. Chercher OpenZeppelin libraries
3. Identifier helpers réutilisables

**Example** :
```bash
# Chercher validation patterns existants
grep -r "require.*length" contracts/src/

# Chercher OpenZeppelin utilities
grep -r "import.*AccessControl" contracts/src/
```

---

### MODE GÉNÉRATIF : Extract & Simplify

**Question** : "Comment réduire complexité sans changer behavior ?"

**Workflow** :
1. Identifier sections >10 lignes
2. Extraire en internal functions
3. Renommer pour clarté
4. Ajouter NatSpec comments

---

### MODE ÉVALUATIF : Measure Complexity

**Question** : "Complexité mesurable ?"

**Tools** :
```bash
# Lines per function
forge fmt --check | grep "function"

# Gas snapshot (complexity proxy)
forge snapshot

# Coverage (test complexity)
forge coverage --report summary
```

---

### MODE ABDUCTIF : Complexity Impact

**Question** : "Effets de second ordre ?"

**Analysis** :
- Audit cost : Functions >50L = +30% audit time
- Gas cost : Complexity 7 = +40% gas vs complexity 3
- Bug surface : Nested if >2 = +200% bug probability

---

## Validation Workflow

**AVANT Write/Edit smart contract** :
1. ✅ Check function length <50 lignes
2. ✅ Check cyclomatic complexity <4
3. ✅ Check responsibilities <3 per contract
4. ✅ Grep duplicate code patterns

**APRÈS Implementation** :
1. ✅ `forge build` - Compilation success
2. ✅ `forge test -vv` - Tests pass
3. ✅ Manual review - Complexity thresholds respected

---

## Metrics Tracking

**Dashboard** :
```json
{
  "contracts": {
    "DAOMembership.sol": {
      "lines": 310,
      "functions": 15,
      "avg_function_length": 20,
      "max_function_length": 45,
      "avg_complexity": 3,
      "max_complexity": 4,
      "state_variables": 8
    },
    "DAOGovernor.sol": {
      "lines": 350,
      "functions": 18,
      "avg_function_length": 19,
      "max_function_length": 48,
      "avg_complexity": 3,
      "max_complexity": 5,
      "state_variables": 12
    }
  },
  "violations": {
    "functions_over_50_lines": 0,
    "complexity_over_4": 1,
    "contracts_over_3_responsibilities": 0
  }
}
```

---

## Related Contracts

- **DAOMembership.sol** : Member lifecycle (complexity target: <3)
- **DAOGovernor.sol** : Governance logic (complexity target: <3)
- **DAOTreasury.sol** : Treasury operations (complexity target: <2)

---

**Confidence** : 95% (Blockchain patterns well-established)
**Domain** : Smart contracts Solidity 0.8+
**Complexity Level** : STRICTER than TypeScript (security-critical)
