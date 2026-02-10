# DAOMembership - Business Logic Specification

**Version** : 1.0.0
**Date** : 2026-02-10
**Source** : DAOMembership.sol (368 lines)

---

## Purpose

Gestion des membres de la DAO avec système de rangs hiérarchiques (0-4), calcul des poids de vote triangulaires, et interface de vote compatible avec le système de gouvernance.

---

## Rank System

### Rank Levels

| Rank | Label | Description |
|------|-------|-------------|
| 0 | Junior | Membres débutants, accès limité |
| 1 | Consultant | Contributeurs actifs confirmés |
| 2 | Senior | Experts avec responsabilités techniques |
| 3 | Manager | Leadership avec responsabilités d'équipe |
| 4 | Partner | Niveau le plus élevé, décisions stratégiques |

### Rank Progression Rules

**Minimum Durations** (avant promotion possible) :
- Rank 0 → 1 : 0 jours (immédiat)
- Rank 1 → 2 : 90 jours
- Rank 2 → 3 : 180 jours
- Rank 3 → 4 : 365 jours
- Rank 4 (max) : 547 jours minimum depuis adhésion

**Promotion Constraints** :
- Ne peut promouvoir que si durée minimale respectée
- Promotion +1 rank seulement (pas de saut de rangs)
- Autorisation requise : rôle MEMBER_MANAGER uniquement

**Demotion Constraints** :
- Demotion -1 rank seulement
- Autorisation requise : rôle MEMBER_MANAGER uniquement

---

## Member Data Model

### Member Attributes

| Attribute | Type | Constraints | Description |
|-----------|------|-------------|-------------|
| `account` | Address | Unique, non-null | Adresse blockchain du membre |
| `rank` | Integer | 0-4 | Rang actuel du membre |
| `joinedAt` | Timestamp | Non-null | Date d'adhésion initiale |
| `lastPromotedAt` | Timestamp | Non-null | Date de dernière promotion |
| `githubHandle` | String | Optional, max 100 chars | Identifiant GitHub (optionnel) |
| `active` | Boolean | Non-null | Statut actif/suspendu |

### Member Lifecycle States

```
[Non-Member] --addMember()--> [Active Member] --suspendMember()--> [Suspended Member]
                                     |                                        |
                                     +<------resumeMember()------------------+
                                     |
                                     +--removeMember()--> [Removed]
```

---

## Vote Weight Calculation

### Formula : Triangular Number

**Standard Formula** :
```
weight(r) = r × (r + 1) / 2
```

**Examples** :
- Rank 0 : weight = 0 × 1 / 2 = **0**
- Rank 1 : weight = 1 × 2 / 2 = **1**
- Rank 2 : weight = 2 × 3 / 2 = **3**
- Rank 3 : weight = 3 × 4 / 2 = **6**
- Rank 4 : weight = 4 × 5 / 2 = **10**

### Adjusted Weight with Minimum Rank Filter

Pour les propositions avec rang minimum requis (`minRank`) :

**Rules** :
1. Si `member.rank < minRank` → **weight = 0** (exclusion)
2. Si `member.rank >= minRank` ET `member.active == true` → **weight = triangular(member.rank)**
3. Si `member.active == false` → **weight = 0** (suspension)

**Note** : Pas d'ajustement du rang dans le calcul (formule triangulaire absolue sur le rang réel)

### Total Vote Weight Calculation

Pour calculer le poids total de vote disponible dans la DAO pour un rang minimum donné :

```
totalWeight(minRank) = SUM(weight(m.rank)) for all members m WHERE m.active == true AND m.rank >= minRank
```

**Example** : Proposition Technical Track (minRank = 2)
- Member A (rank 1, active) → excluded (rank < 2)
- Member B (rank 2, active) → weight = 3
- Member C (rank 3, active) → weight = 6
- Member D (rank 4, active) → weight = 10
- **Total** : 3 + 6 + 10 = **19**

---

## Core Operations

### 1. Add Member

**Preconditions** :
- Caller has MEMBER_MANAGER_ROLE
- Account not already a member
- Initial rank provided (0-4)
- GitHub handle max 100 characters

**Effects** :
- Create new member record
- Set `joinedAt` = current timestamp
- Set `lastPromotedAt` = current timestamp (même si rank 0)
- Set `active` = true
- Add account to internal member list

**Post-conditions** :
- `isMember(account) == true`
- Member appears in `getActiveMembersByRank(rank)` results

---

### 2. Remove Member

**Preconditions** :
- Caller has MEMBER_MANAGER_ROLE
- Account is a current member

**Effects** :
- Delete member record
- Remove account from internal member list

**Post-conditions** :
- `isMember(account) == false`
- Member does NOT appear in any rank queries
- Historical votes remain valid (vote weight snapshot)

---

### 3. Promote Member

**Preconditions** :
- Caller has MEMBER_MANAGER_ROLE
- Account is an active member
- Current rank < 4 (max rank)
- `(currentTimestamp - member.lastPromotedAt) >= minimumDuration[currentRank]`

**Effects** :
- Increment `rank` by 1
- Set `lastPromotedAt` = current timestamp

**Post-conditions** :
- Vote weight updated for future votes
- Member appears in new rank queries

---

### 4. Demote Member

**Preconditions** :
- Caller has MEMBER_MANAGER_ROLE
- Account is an active member
- Current rank > 0

**Effects** :
- Decrement `rank` by 1
- Set `lastPromotedAt` = current timestamp (reset progression timer)

**Post-conditions** :
- Vote weight reduced for future votes
- Member removed from previous rank queries

---

### 5. Suspend Member

**Preconditions** :
- Caller has MEMBER_MANAGER_ROLE
- Account is an active member

**Effects** :
- Set `active` = false

**Post-conditions** :
- `isMember(account) == true` (still exists)
- Vote weight = 0 for all future votes
- Member does NOT appear in `getActiveMembersByRank()` results

---

### 6. Resume Member

**Preconditions** :
- Caller has MEMBER_MANAGER_ROLE
- Account is a suspended member

**Effects** :
- Set `active` = true

**Post-conditions** :
- Vote weight restored based on current rank
- Member reappears in `getActiveMembersByRank()` results

---

## Query Operations

### Get Active Members by Rank

**Input** :
- `rank` : Integer (0-4)
- `offset` : Integer (pagination offset, default 0)
- `limit` : Integer (pagination limit, max 100)

**Output** :
- Array of member accounts matching rank filter
- Total count of matching members

**Filter Rules** :
1. Filter by `member.rank == rank`
2. Filter by `member.active == true`
3. Apply pagination (offset + limit)

**Performance** :
- MUST support pagination to prevent DoS with >1000 members
- Max 100 results per query

---

### Get Member Info

**Input** :
- `account` : Address

**Output** :
- Member struct (rank, joinedAt, lastPromotedAt, githubHandle, active)
- Or null if not a member

---

### Get Member Count

**Output** :
- Integer count of total members (active + suspended)

---

## Access Control

### Roles Required

| Operation | Role Required | Notes |
|-----------|--------------|-------|
| `addMember` | MEMBER_MANAGER_ROLE | Admin only |
| `removeMember` | MEMBER_MANAGER_ROLE | Admin only |
| `promoteMember` | MEMBER_MANAGER_ROLE | Admin only |
| `demoteMember` | MEMBER_MANAGER_ROLE | Admin only |
| `suspendMember` | MEMBER_MANAGER_ROLE | Admin only |
| `resumeMember` | MEMBER_MANAGER_ROLE | Admin only |
| `isMember` | PUBLIC | Read-only, no restrictions |
| `calculateVoteWeight` | PUBLIC | Read-only, no restrictions |
| `getActiveMembersByRank` | PUBLIC | Read-only, no restrictions |

---

## Integration Requirements

### Governor Integration

**IVotes Interface** : Le système de membership doit exposer une interface compatible avec le Governor :

1. **`clock()`** : Retourne le numéro de bloc actuel (pour timestamping des votes)
2. **`CLOCK_MODE()`** : Retourne "mode=blocknumber&from=default"
3. **`getPastTotalSupply(timepoint)`** : Retourne le poids total de vote à un bloc donné
4. **`getPastVotes(account, timepoint)`** : Retourne le poids de vote d'un compte à un bloc donné

**Note** : Dans l'implémentation Solidity actuelle, ces fonctions retournent les valeurs actuelles (pas de snapshots historiques). Pour Substrate, utiliser `frame_support::traits::VoteTally` ou équivalent.

---

## Security Considerations

### Emergency Pause

**Requirement** : DOIT implémenter un mécanisme de pause d'urgence pour toutes les opérations critiques (add/remove/promote/demote/suspend/resume).

**Triggers** :
- Security incident détecté
- Smart contract bug découvert
- Governance attack en cours

**Effects** :
- Bloquer toutes opérations de modification (add/remove/promote/demote/suspend/resume)
- Autoriser opérations de lecture (isMember, calculateVoteWeight, queries)

---

### DoS Prevention

**Unbounded Arrays** :
- ⚠️ **Risk** : Requêtes `getActiveMembersByRank()` itèrent tous membres → DoS avec >1000 membres
- ✅ **Mitigation** : Pagination obligatoire (offset + limit, max 100 par requête)

---

### Rank Manipulation Attacks

**Attack Vector** : Promotion/demotion rapide pour manipulation de vote weights

**Mitigation** :
- Minimum durations enforced strictement
- Un seul changement de rang par transaction (+1 ou -1, pas de sauts)
- Promotion/demotion nécessite `lastPromotedAt` + durée minimale

---

## Constants

| Constant | Value | Description |
|----------|-------|-------------|
| `MAX_RANK` | 4 | Rang maximum possible |
| `MIN_DURATION_RANK_0_TO_1` | 0 days | Promotion immédiate possible |
| `MIN_DURATION_RANK_1_TO_2` | 90 days | 3 mois minimum |
| `MIN_DURATION_RANK_2_TO_3` | 180 days | 6 mois minimum |
| `MIN_DURATION_RANK_3_TO_4` | 365 days | 1 an minimum |
| `MAX_GITHUB_HANDLE_LENGTH` | 100 characters | Limite taille identifiant |
| `PAGINATION_MAX_LIMIT` | 100 | Max résultats par requête |

---

## Migration Notes (Substrate)

### Pallet Mapping

Ce contrat sera migré vers un **custom pallet `pallet-dao-membership`** car :
- Système de rangs unique (0-4 avec durées minimales)
- Formule de vote weight triangulaire spécifique
- Pas de pallet existant dans l'écosystème Polkadot

### Storage Considerations

**Bounded Types** :
- `githubHandle` : `BoundedVec<u8, ConstU32<100>>`
- Pagination results : `BoundedVec<AccountId, ConstU32<100>>`

**Weight Benchmarking** :
- Opérations add/remove/promote/demote : Benchmarking requis
- Query `getActiveMembersByRank` : Poids proportionnel à `limit` (not total members)

---

## Related Specifications

- **DAOGovernor-specification.md** : Utilise `calculateVoteWeight()` et `calculateTotalVoteWeight()` pour calcul quorums
- **ServiceMarketplace-specification.md** : Utilise `rank` pour filtrage missions (minRank requirement)
- **MissionEscrow-specification.md** : Utilise `rank >= 3` pour sélection jury disputes

---

**Version** : 1.0.0
**Date** : 2026-02-10
