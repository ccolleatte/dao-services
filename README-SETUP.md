# Setup Environnement MVP - DAO Services IA

> **Stack choisi** : Solidity 0.8.19+ sur Polkadot Hub (testnet Paseo)
>
> **⚠️ Important** : ink! (Rust) est en maintenance mode depuis janvier 2026. Ce projet utilise Solidity via Revive/PolkaVM.

---

## 🛠️ Prérequis

### 1. Node.js et npm

**Version requise** : Node.js ≥18.0

```powershell
# Vérifier version
node --version

# Si absent, télécharger : https://nodejs.org/
```

### 2. Foundry

**Framework Solidity** : Compilation, tests, déploiement

```powershell
# Installation (Windows - via Foundryup)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Vérifier installation
forge --version
```

Si problème Windows, alternative :
```powershell
# Installer via binaires précompilés
# Télécharger : https://github.com/foundry-rs/foundry/releases
# Extraire dans C:\Program Files\Foundry
# Ajouter au PATH
```

### 3. Pop CLI (Optionnel - pour déploiement Polkadot)

```powershell
# Installation via cargo
cargo install pop-cli

# Vérifier
pop --version
```

### 4. MetaMask (Wallet)

**Extension navigateur** : https://metamask.io/download

**Configuration Polkadot Hub Paseo** :
- Réseau : Polkadot Hub Paseo Testnet
- RPC URL : `https://paseo-rpc.polkadot.io`
- Chain ID : `1000` (Polkadot Hub testnet)
- Symbole : `PAS`
- Explorateur : `https://paseo.subscan.io/`

---

## 📦 Installation Dépendances

### 1. Installer dépendances Node.js

```powershell
cd C:\dev\DAO
npm install
```

Ceci installe :
- `@openzeppelin/contracts` (librairies Governor, AccessControl, etc.)
- `solhint` (linter Solidity)

### 2. Installer dépendances Forge

```powershell
forge install OpenZeppelin/openzeppelin-contracts@v4.9.3
```

---

## 🔨 Compilation

### Compiler tous les contracts

```powershell
npm run build

# Ou directement
forge build
```

**Output** : `contracts/out/` (ABIs et bytecode compilés)

### Vérifier compilation réussie

```powershell
# Doit afficher "Compiled X files successfully"
forge build --force
```

---

## ✅ Tests Unitaires

### Exécuter tous les tests

```powershell
npm test

# Ou directement
forge test
```

### Tests avec verbosité

```powershell
forge test -vv

# Afficher tous les logs (traces)
forge test -vvvv
```

### Tests spécifiques

```powershell
# Tester un seul contrat
forge test --match-contract DAOMembershipTest

# Tester une seule fonction
forge test --match-test test_AddMember
```

### Coverage (couverture)

```powershell
npm run test:coverage

# Ou directement
forge coverage
```

**Objectifs coverage** :
- Lignes : ≥80%
- Branches : ≥70%

---

## 🚀 Déploiement

### 1. Obtenir tokens testnet (PAS)

**Faucet Polkadot Paseo** : https://faucet.polkadot.io/

1. Connecter MetaMask (Paseo)
2. Copier votre adresse
3. Demander 10 PAS (suffisant pour déploiement)

### 2. Configuration variables d'environnement

Créer `.env` à la racine :

```env
PRIVATE_KEY=<votre_clé_privée_MetaMask>
POLKADOT_HUB_PASEO_RPC=https://paseo-rpc.polkadot.io
ETHERSCAN_API_KEY=<optionnel_pour_verification>
```

**⚠️ Sécurité** : JAMAIS commit `.env` ! Vérifié dans `.gitignore`.

### 3. Créer script de déploiement

**Fichier** : `contracts/script/Deploy.s.sol`

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/DAOMembership.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        DAOMembership membership = new DAOMembership();
        console.log("DAOMembership deployed at:", address(membership));

        vm.stopBroadcast();
    }
}
```

### 4. Déployer sur testnet

```powershell
npm run deploy:testnet

# Ou directement
forge script contracts/script/Deploy.s.sol --rpc-url polkadot_hub_paseo --broadcast
```

**Output** : Adresse du contrat déployé + transaction hash

---

## 📋 Checklist Post-Installation

- [ ] `node --version` affiche ≥18.0
- [ ] `forge --version` fonctionne
- [ ] `npm install` réussi (0 erreurs)
- [ ] `forge build` compile sans erreurs
- [ ] `forge test` passe tous les tests (100%)
- [ ] MetaMask configuré avec Paseo testnet
- [ ] Faucet obtenu (≥1 PAS dans wallet)
- [ ] `.env` créé avec PRIVATE_KEY
- [ ] Déploiement testnet réussi

---

## 🔗 Ressources Utiles

### Documentation

- **Foundry Book** : https://book.getfoundry.sh/
- **OpenZeppelin Contracts** : https://docs.openzeppelin.com/contracts/
- **Polkadot Hub** : https://docs.polkadot.com/reference/polkadot-hub/smart-contracts/
- **Pop CLI** : https://learn.onpop.io/

### Explorateurs Blockchain

- **Paseo Subscan** : https://paseo.subscan.io/
- **Polkadot.js Apps** : https://polkadot.js.org/apps/?rpc=wss://paseo-rpc.polkadot.io

### Faucets

- **Paseo Faucet** : https://faucet.polkadot.io/

---

## 🐛 Troubleshooting

### Erreur : "forge: command not found"

**Solution** : Ajouter Foundry au PATH

```powershell
$env:Path += ";C:\Users\<user>\.foundry\bin"

# Permanent (PowerShell profile)
Add-Content $PROFILE '$env:Path += ";C:\Users\<user>\.foundry\bin"'
```

### Erreur : "Failed to resolve import @openzeppelin"

**Solution** : Vérifier `remappings.txt` existe

```powershell
# Doit contenir :
@openzeppelin/contracts/=node_modules/@openzeppelin/contracts/
```

### Erreur : "Compilation failed"

**Solution** : Clean cache et rebuild

```powershell
forge clean
forge build --force
```

### Erreur : "Insufficient funds for gas"

**Solution** : Demander plus de tokens au faucet
- Minimum 1 PAS requis pour déploiement
- 5 PAS recommandé pour tester plusieurs contrats

---

## 📝 Next Steps

**Après setup réussi** :

1. ✅ **Tests passing** → Continuer Phase 3
2. 🏗️ **Smart contracts additionnels** :
   - `Governor.sol` (propositions et votes)
   - `Treasury.sol` (gestion fonds)
   - `ServiceMarketplace.sol` (missions)
3. 🎨 **Frontend** : Next.js + ethers.js
4. 🚀 **Déploiement production** : Polkadot Hub mainnet (Phase 5)

---

**Version** : 0.1.0-alpha
**Dernière mise à jour** : 2026-02-08
