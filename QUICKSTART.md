# Quick Start - DAO Services IA

**Setup rapide en 10 minutes** pour développeurs familiers avec Solidity/Foundry.

---

## 1. Installation (5 min)

### Prérequis

```powershell
# Node.js ≥18.0
node --version

# Foundry (si absent)
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

### Installer dépendances

```powershell
cd C:\dev\DAO
npm install
forge install OpenZeppelin/openzeppelin-contracts@v4.9.3
```

---

## 2. Compilation & Tests (3 min)

### Compiler

```powershell
forge build
```

**Output attendu** :
```
[⠊] Compiling...
[⠒] Compiling 3 files with 0.8.19
[⠢] Solc 0.8.19 finished in 1.2s
Compiler run successful!
```

### Tests

```powershell
forge test -vv
```

**Output attendu** :
```
Running 22 tests for contracts/test/DAOMembership.t.sol:DAOMembershipTest
[PASS] test_AddMember() (gas: 123456)
[PASS] test_CalculateVoteWeight_Rank0() (gas: 234567)
...
Test result: ok. 22 passed; 0 failed; finished in 1.23s
```

---

## 3. Déploiement Local (2 min)

### Démarrer nœud local (Anvil)

```powershell
# Terminal 1
anvil
```

### Déployer contrats

```powershell
# Terminal 2
forge script contracts/script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

**Output attendu** :
```
Deploying contracts with:
Deployer address: 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266

DAOMembership deployed at: 0x5FbDB2315678afecb367f032d93F642f64180aa3
Deployer added as member (Rank 4)

Deployment complete!
```

---

## 4. Interagir avec les Contrats

### Via Cast (CLI)

```powershell
# Lire infos membre
cast call <CONTRACT_ADDRESS> "getMemberInfo(address)" <MEMBER_ADDRESS> --rpc-url http://localhost:8545

# Ajouter membre (nécessite rôle MEMBER_MANAGER)
cast send <CONTRACT_ADDRESS> "addMember(address,uint8,string)" <NEW_MEMBER> 0 "github-handle" --rpc-url http://localhost:8545 --private-key <DEPLOYER_KEY>

# Calculer vote weight
cast call <CONTRACT_ADDRESS> "calculateVoteWeight(address,uint8)" <MEMBER_ADDRESS> 0 --rpc-url http://localhost:8545
```

### Via Foundry Console

```powershell
forge console --rpc-url http://localhost:8545

# Dans la console
> DAOMembership membership = DAOMembership(0x5FbDB...);
> membership.isMember(address(this))
true
> membership.getMemberCount()
1
```

---

## 5. Workflow Développement

### Cycle Red-Green-Refactor (TDD)

```powershell
# 1. Écrire test (RED)
# Éditer contracts/test/DAOMembership.t.sol

# 2. Vérifier test échoue
forge test --match-test test_NewFeature

# 3. Implémenter feature (GREEN)
# Éditer contracts/src/DAOMembership.sol

# 4. Vérifier test passe
forge test --match-test test_NewFeature

# 5. Refactorer si besoin
forge fmt
```

### Coverage

```powershell
forge coverage

# Générer rapport HTML
forge coverage --report lcov
genhtml lcov.info -o coverage/
```

**Objectifs** :
- Lignes : ≥80%
- Branches : ≥70%

---

## 6. Déploiement Testnet Paseo

### Prérequis

```powershell
# 1. Obtenir tokens PAS (faucet)
# https://faucet.polkadot.io/

# 2. Créer .env
echo "PRIVATE_KEY=<votre_clé_privée>" > .env
```

### Déployer

```powershell
forge script contracts/script/Deploy.s.sol --rpc-url polkadot_hub_paseo --broadcast --verify
```

### Vérifier déploiement

```powershell
# Vérifier contrat sur explorateur
# https://paseo.subscan.io/

# Tester interaction
cast call <CONTRACT_ADDRESS> "getMemberCount()" --rpc-url https://paseo-rpc.polkadot.io
```

---

## 7. Commandes Utiles

### Build & Test

| Commande | Action |
|----------|--------|
| `forge build` | Compiler contracts |
| `forge test` | Exécuter tous tests |
| `forge test -vvvv` | Tests avec traces complètes |
| `forge test --match-contract DAOMembership` | Tests d'un seul contrat |
| `forge test --match-test test_AddMember` | Test d'une seule fonction |
| `forge coverage` | Rapport coverage |
| `forge fmt` | Formatter code Solidity |

### Deploy & Interact

| Commande | Action |
|----------|--------|
| `anvil` | Démarrer nœud local |
| `forge script contracts/script/Deploy.s.sol --broadcast` | Déployer contrats |
| `cast call <addr> "func()"` | Appel lecture (view/pure) |
| `cast send <addr> "func()" --private-key` | Appel écriture (transaction) |
| `cast block-number` | Dernier block |

### Debug

| Commande | Action |
|----------|--------|
| `forge test --debug test_Name` | Debugger interactif |
| `forge inspect <Contract> abi` | Afficher ABI |
| `forge inspect <Contract> storage` | Afficher layout storage |
| `cast 4byte <selector>` | Trouver signature fonction |

---

## 8. Structure Projet

```
C:\dev\DAO/
├── contracts/
│   ├── src/
│   │   └── DAOMembership.sol       # Contrat core membres
│   ├── test/
│   │   └── DAOMembership.t.sol     # Tests unitaires
│   └── script/
│       └── Deploy.s.sol            # Script déploiement
├── docs/                           # Documentation phases 1-2
├── foundry.toml                    # Config Foundry
├── package.json                    # Dépendances Node.js
├── remappings.txt                  # Imports OpenZeppelin
├── README.md                       # Vue d'ensemble projet
├── README-SETUP.md                 # Setup détaillé (⭐ À LIRE)
├── PROGRESS.md                     # Progression phases
└── QUICKSTART.md                   # Ce fichier
```

---

## 9. Prochaines Étapes

**Après avoir complété ce Quick Start** :

1. ✅ **Lire documentation Phase 1-2** :
   - `docs/01-fundamentals/` - Architecture Polkadot
   - `docs/04-design/` - Design DAO base
   - `docs/05-extensions/` - Tokenomics + Marketplace

2. 🏗️ **Implémenter contrats suivants** :
   - `Governor.sol` (propositions, votes)
   - `Treasury.sol` (gestion fonds)
   - `ServiceMarketplace.sol` (missions)

3. 🎨 **Frontend** :
   - Setup Next.js 15
   - Intégration ethers.js
   - Interface DAOMembership

---

## 10. Support

**Documentation complète** : [README-SETUP.md](./README-SETUP.md)
**Progression projet** : [PROGRESS.md](./PROGRESS.md)

**Ressources externes** :
- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Docs](https://docs.openzeppelin.com/contracts/)
- [Polkadot Hub](https://docs.polkadot.com/reference/polkadot-hub/smart-contracts/)

---

**Temps total** : ~10 minutes
**Niveau** : Développeur Solidity intermédiaire

**Prêt à développer !** 🚀
