# Paseo Deployment Checklist

**Version** : 1.0.0
**Date** : 2026-02-10
**Testnet** : Paseo Network
**Durée estimée** : 1 semaine setup + 2-4 semaines tests

---

## Objectif

Déployer le runtime DAO Substrate sur Paseo testnet pour valider :
- ✅ Governance (3 tracks : General, Treasury, Emergency)
- ✅ Mission lifecycle (création → validation → paiement)
- ✅ Treasury milestone-based payments
- ✅ Performance sous charge (10+ utilisateurs concurrents)

**Pourquoi Paseo** : Testnet production-like, tokens PAS gratuits, coretime 2 jours (vs 7 jours Kusama) = tests 3-4× plus rapides.

---

## Phase 0 : Prérequis (1-2 jours)

### 0.1 Environnement Local Validé

**Checklist** :
- [ ] Substrate runtime compile sans erreurs : `cargo build --release`
- [ ] Tous les pallets testés localement (tests passent) : `cargo test --all`
- [ ] Benchmarks extrinsics générés : `./target/release/dao-node benchmark pallet`
- [ ] Chain spec local fonctionne : `./target/release/dao-node --chain=local --alice`
- [ ] Frontend connecté à nœud local (si applicable)

**Commandes validation** :
```bash
# Vérifier compilation
cd C:\dev\dao\substrate-runtime
cargo build --release

# Run tests
cargo test --all

# Generate benchmarks (si pas fait)
./target/release/dao-node benchmark pallet \
  --pallet pallet_marketplace \
  --extrinsic "*" \
  --output pallets/marketplace/src/weights.rs
```

**Outputs attendus** :
- ✅ Binary : `./target/release/dao-node` (~200MB)
- ✅ Tests : 100% passing
- ✅ Weights : Fichiers `weights.rs` générés par pallet

---

### 0.2 Documentation Runtime Prête

**Checklist** :
- [ ] README.md avec instructions build
- [ ] Architecture pallets documentée
- [ ] Extrinsics API reference
- [ ] Known limitations listées

**Fichiers à créer** :
- `substrate-runtime/README.md`
- `substrate-runtime/ARCHITECTURE.md`
- `substrate-runtime/pallets/*/README.md`

---

### 0.3 Outils Installés

**Checklist** :
- [ ] Rust toolchain : `rustup show` (stable ou nightly)
- [ ] Substrate target : `rustup target add wasm32-unknown-unknown`
- [ ] Polkadot.js Apps : https://polkadot.js.org/apps/
- [ ] Subkey : `cargo install --force subkey --git https://github.com/paritytech/polkadot-sdk`
- [ ] Git configuré (pour commit chain spec)

**Installation rapide** :
```bash
# Add wasm target
rustup target add wasm32-unknown-unknown

# Install subkey
cargo install --force subkey --git https://github.com/paritytech/polkadot-sdk

# Verify versions
rustup show
subkey --version
```

---

## Phase 1 : Obtenir Tokens PAS (10 min)

### 1.1 Générer Compte Paseo

**Méthode 1 : Polkadot.js Extension (recommandé)**
1. Installer extension : https://polkadot.js.org/extension/
2. Create Account → Paseo → "DAO Deployer Account"
3. Backup seed phrase (12 mots)
4. Copier adresse (format SS58 : commence par `5...`)

**Méthode 2 : Subkey CLI**
```bash
# Generate new account
subkey generate --scheme sr25519 --network paseo

# Output:
# Secret phrase: word1 word2 ... word12
# Network ID:    paseo
# Secret seed:   0x...
# Public key:    0x...
# Account ID:    0x...
# SS58 Address:  5... (YOUR_PASEO_ADDRESS)
```

**Sauvegarde** :
- ✅ Seed phrase → KeePass/1Password
- ✅ Adresse SS58 → `.env.paseo` (ne PAS commit)

---

### 1.2 Faucet PAS

**URL** : https://paritytech.github.io/polkadot-testnet-faucet/

**Steps** :
1. Coller votre adresse Paseo (5...)
2. Network : Sélectionner "Paseo"
3. Submit
4. Attendre 30-60s → 100 PAS reçus

**Vérification** :
1. Aller à https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fapi-paseo.n.dwellir.com%2F#/accounts
2. Add account (coller adresse OU importer depuis extension)
3. Vérifier balance : 100.0000 PAS

**Rate limit** : 1 requête par 24h par adresse. Si besoin de plus :
- Créer 2-3 comptes (deployer, governance, treasury)
- Request 100 PAS par compte

---

## Phase 2 : Préparer Parachain (1-2 jours)

### 2.1 Réserver Parachain ID

**URL** : https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fapi-paseo.n.dwellir.com%2F#/parachains/parathreads

**Steps** :
1. Network → Paseo (RPC : `wss://api-paseo.n.dwellir.com/`)
2. Developer → Extrinsics
3. Using account : Votre compte deployer (≥5 PAS requis)
4. Submit extrinsic :
   - Pallet : `registrar`
   - Extrinsic : `reserve()`
   - Signer avec votre compte
5. Submit Transaction
6. Attendre block confirmation (~12s)

**Vérifier ID réservé** :
1. Network → Parachains
2. Vérifier "Parathreads" section
3. Noter votre Parachain ID (ex: `2000`, `2001`, etc.)

**Backup** :
```bash
# Save parachain ID
echo "PARACHAIN_ID=2000" >> .env.paseo
```

---

### 2.2 Générer Chain Spec Custom

**Chain spec** : Configuration runtime pour Paseo relay + parachain ID

**Fichier template** : `substrate-runtime/chain-specs/paseo-local.json`

```json
{
  "name": "DAO Parachain Paseo",
  "id": "dao_paseo",
  "chainType": "Live",
  "bootNodes": [],
  "telemetryEndpoints": null,
  "protocolId": "dao",
  "properties": {
    "tokenSymbol": "DAOT",
    "tokenDecimals": 12,
    "ss58Format": 42
  },
  "relay_chain": "paseo",
  "para_id": 2000,
  "codeSubstitutes": {},
  "genesis": {
    "runtime": {
      "system": {},
      "balances": {
        "balances": [
          ["YOUR_DEPLOYER_ADDRESS", 1000000000000000]
        ]
      },
      "parachainInfo": {
        "parachainId": 2000
      },
      "collatorSelection": {
        "invulnerables": ["YOUR_COLLATOR_SESSION_KEY"],
        "candidacyBond": 1000000000000,
        "desiredCandidates": 1
      },
      "session": {
        "keys": [
          ["YOUR_COLLATOR_ADDRESS", "YOUR_COLLATOR_SESSION_KEY"]
        ]
      },
      "sudo": {
        "key": "YOUR_DEPLOYER_ADDRESS"
      }
    }
  }
}
```

**Générer session keys** :
```bash
# Generate collator session keys
subkey generate --scheme sr25519 --network paseo

# Output:
# Secret seed: 0x... (SAVE THIS!)
# Public key (hex): 0x...
# Account ID: 0x...
# SS58 Address: 5... (YOUR_COLLATOR_ADDRESS)
```

**Build chain spec raw** :
```bash
cd substrate-runtime

# Convert to raw format (required for registration)
./target/release/dao-node build-spec \
  --chain chain-specs/paseo-local.json \
  --raw \
  --disable-default-bootnode \
  > chain-specs/paseo-raw.json

# Verify raw spec
cat chain-specs/paseo-raw.json | jq '.para_id'
# Should output: 2000 (your reserved ID)
```

---

### 2.3 Exporter Wasm Runtime + Genesis State

**Wasm runtime** : Code exécutable du runtime (uploadé à relay chain)

**Genesis state** : État initial parachain (balances, sudo, collators)

**Commandes** :
```bash
cd substrate-runtime

# Export Wasm runtime
./target/release/dao-node export-genesis-wasm \
  --chain chain-specs/paseo-raw.json \
  > paseo-genesis-wasm

# Export genesis state
./target/release/dao-node export-genesis-state \
  --chain chain-specs/paseo-raw.json \
  > paseo-genesis-state

# Verify files
ls -lh paseo-genesis-*
# paseo-genesis-wasm: ~1-2MB
# paseo-genesis-state: ~50-100KB
```

**Backup fichiers** :
```bash
# Copy to safe location
mkdir -p _deployment/paseo
cp paseo-genesis-* _deployment/paseo/
cp chain-specs/paseo-raw.json _deployment/paseo/

# Commit to git (private repo)
git add _deployment/paseo/
git commit -m "feat(paseo): Add genesis artifacts for deployment"
```

---

## Phase 3 : Enregistrer Parachain (1-2 heures)

### 3.1 Uploader Genesis via Polkadot.js Apps

**URL** : https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fapi-paseo.n.dwellir.com%2F#/parachains/parathreads

**Steps** :
1. Network → Parachains → Parathreads
2. Click "+ ParaThread" (en haut à droite)
3. Formulaire :
   - **parachain ID** : `2000` (votre ID réservé)
   - **genesis head** : Upload `paseo-genesis-state`
   - **validation code** : Upload `paseo-genesis-wasm`
4. Using account : Votre deployer account
5. Submit Transaction
6. Signer transaction (≥50 PAS deposit requis)

**Attente** : 2-6 heures pour que parachain soit "registered" (processus asynchrone relay chain)

**Vérifier statut** :
1. Developer → Chain state
2. Select : `registrar` → `paras(ParaId): Option<ParaInfo>`
3. ParaId : `2000`
4. Query
5. Statut attendu : `{"manager": "0x...", "deposit": "...", "locked": false}`

---

### 3.2 Acquérir Coretime

**Coretime** : Droit de produire blocs sur relay chain (2 options)

#### Option A : Bulk Coretime (recommandé pour tests longs)

**Durée** : 2 jours (1 interlude) = ~2880 blocs (~28800s à 6s/bloc)

**URL** : https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fapi-paseo.n.dwellir.com%2F#/coretime

**Steps** :
1. Network → Coretime
2. "Purchase Coretime"
3. Formulaire :
   - **Duration** : 2 jours (1 interlude)
   - **Parachain ID** : `2000`
   - **Max price** : 10 PAS
4. Submit Transaction
5. Attendre confirmation

**Coût estimé** : 5-10 PAS pour 2 jours

---

#### Option B : On-Demand Coretime (recommandé pour tests courts)

**Durée** : Pay-per-block (~0.01 PAS par bloc)

**URL** : https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fapi-paseo.n.dwellir.com%2F#/extrinsics

**Steps** :
1. Developer → Extrinsics
2. Submit :
   - Pallet : `onDemandAssignmentProvider`
   - Extrinsic : `placeOrderAllowDeath(maxAmount, paraId)`
   - maxAmount : `1000000000000` (10 PAS)
   - paraId : `2000`
3. Submit Transaction

**Coût estimé** : ~0.01-0.05 PAS par bloc produit

---

**Vérifier coretime actif** :
1. Developer → Chain state
2. Select : `paras` → `paraLifecycles(ParaId): Option<ParaLifecycle>`
3. ParaId : `2000`
4. Query
5. Statut attendu : `"Parachain"` (pas "Parathread")

---

## Phase 4 : Lancer Collator Node (1 jour)

### 4.1 Configuration Collator

**Collator** : Nœud qui produit blocs parachain et les soumet à relay chain

**Fichier config** : `substrate-runtime/collator-config.toml`

```toml
[collator]
name = "DAO Collator Paseo"
base-path = "/var/lib/dao-collator"
chain = "chain-specs/paseo-raw.json"

[network]
listen-addr = "/ip4/0.0.0.0/tcp/30333"
public-addr = "/ip4/YOUR_PUBLIC_IP/tcp/30333"
bootnodes = []

[rpc]
port = 9944
cors = ["http://localhost:3000", "https://polkadot.js.org"]

[relay]
relay-chain-rpc-url = "wss://api-paseo.n.dwellir.com/"

[prometheus]
port = 9615
```

**Remplacer** :
- `YOUR_PUBLIC_IP` : IP publique serveur (ou localhost si local)
- `relay-chain-rpc-url` : RPC Paseo relay chain (Dwellir)

---

### 4.2 Démarrer Collator

**Commande** :
```bash
cd substrate-runtime

# Start collator (foreground, debug logs)
./target/release/dao-node \
  --collator \
  --chain chain-specs/paseo-raw.json \
  --base-path /tmp/dao-collator \
  --port 30333 \
  --rpc-port 9944 \
  --rpc-cors all \
  --name "DAO Collator Paseo" \
  --execution wasm \
  --ws-external \
  -- \
  --relay-chain-rpc-url wss://api-paseo.n.dwellir.com/

# Logs attendus:
# [Parachain] Starting collation...
# [Parachain] Produced candidate hash=0x...
# [Relaychain] Imported block #12345
```

**Daemon mode (production)** :
```bash
# Run as systemd service
sudo tee /etc/systemd/system/dao-collator.service > /dev/null <<EOF
[Unit]
Description=DAO Collator Paseo
After=network.target

[Service]
Type=simple
User=dao
WorkingDirectory=/home/dao/substrate-runtime
ExecStart=/home/dao/substrate-runtime/target/release/dao-node \
  --collator \
  --chain /home/dao/substrate-runtime/chain-specs/paseo-raw.json \
  --base-path /var/lib/dao-collator \
  --port 30333 \
  --rpc-port 9944 \
  --rpc-cors all \
  --name "DAO Collator Paseo" \
  --execution wasm \
  --ws-external \
  -- \
  --relay-chain-rpc-url wss://api-paseo.n.dwellir.com/
Restart=always
RestartSec=10

[Install]
WantedBy=multi-user.target
EOF

# Start service
sudo systemctl daemon-reload
sudo systemctl enable dao-collator
sudo systemctl start dao-collator

# Check logs
sudo journalctl -u dao-collator -f
```

---

### 4.3 Insérer Session Keys

**Session keys** : Clés utilisées par collator pour signer blocs

**Générer keys** :
```bash
# RPC call to collator
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_rotateKeys"}' \
  http://localhost:9944

# Output:
# {"jsonrpc":"2.0","result":"0x...","id":1}
# Copy 0x... (YOUR_SESSION_KEYS)
```

**Insérer via Polkadot.js Apps** :
1. https://polkadot.js.org/apps/?rpc=ws%3A%2F%2Flocalhost%3A9944#/extrinsics
2. Using account : Votre collator account
3. Submit :
   - Pallet : `session`
   - Extrinsic : `setKeys(keys, proof)`
   - keys : `YOUR_SESSION_KEYS` (0x...)
   - proof : `0x00`
4. Submit Transaction

**Vérifier keys actives** :
1. Developer → Chain state
2. Select : `session` → `nextKeys(AccountId): Option<SessionKeys>`
3. AccountId : Votre collator address
4. Query
5. Résultat : Session keys présentes

---

## Phase 5 : Validation Production-Like (2-4 semaines)

### 5.1 Tests Critiques (Semaine 1-2)

**Checklist** :

#### Governance Tests
- [ ] **Track General** : Créer proposal → Vote (3 utilisateurs) → Execute
  - Expected : Quorum ≥50%, vote duration 3 jours, approval ≥66%
- [ ] **Track Treasury** : Demande payout 100 DAOT → Vote → Transfer
  - Expected : Quorum ≥40%, 3 utilisateurs vote, funds released
- [ ] **Track Emergency** : Fast-track proposal (1 jour) → Execute
  - Expected : Super majority (≥80%), immediate execution

**Commandes validation** :
```bash
# Query governance proposals
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "state_call", "params": ["GovernanceApi_proposals", "0x"]}' \
  http://localhost:9944

# Query votes for proposal #1
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "state_call", "params": ["GovernanceApi_votes", "0x01000000"]}' \
  http://localhost:9944
```

---

#### Mission Lifecycle Tests
- [ ] **Create mission** : 10 missions (descriptions variées, budgets 10-100 DAOT)
- [ ] **Apply to mission** : 3 applicants par mission
- [ ] **Validate applicant** : Select 1 winner (via governance OR direct)
- [ ] **Complete mission** : Submit proof of work
- [ ] **Release payment** : Escrow → Winner wallet

**Metrics attendus** :
- Gas costs : <50k per operation
- Latency : <12s (1 bloc) pour confirmation
- Success rate : 100% missions payées sans bug

---

#### Treasury Tests
- [ ] **Milestone-based payout** : 3 milestones (33% each) → Validate → Pay
- [ ] **Treasury balance** : Verify funds depleted correctly
- [ ] **Concurrent payouts** : 5 missions payées simultanément

**Commandes validation** :
```bash
# Query treasury balance
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "system_account", "params": ["TREASURY_ACCOUNT_ID"]}' \
  http://localhost:9944
```

---

#### Performance Tests
- [ ] **Concurrent users** : 10 utilisateurs simultanés (create missions, vote, apply)
- [ ] **Load spike** : 50 transactions en 1 minute
- [ ] **Block time stability** : Moyenne 6s ± 0.5s sur 1000 blocs

**Monitoring** :
1. Grafana Paseo : https://grafana.paseo.site/
2. Vérifier :
   - Blocks produced : ~14400 blocs/jour (6s/bloc)
   - Transactions per block : 10-50
   - Missed blocks : <1%

---

### 5.2 Community Feedback (Semaine 2-3)

**Channels** :
- Element chat : https://matrix.to/#/#paseo:matrix.org
- Support repo : https://github.com/paseo-network/support/issues
- Reddit : r/Polkadot + r/substrate

**Feedback collecté** :
- [ ] UX governance (vote participation, clarity)
- [ ] Gas costs acceptable ?
- [ ] Mission matching flow clair ?
- [ ] Bugs découverts ?

**Document feedback** :
```markdown
# Community Feedback (Paseo Week 2-3)

## Positive
- Governance tracks clairs (3 utilisateurs testés)
- Mission matching rapide (<30s)
- Treasury payouts fiables (10/10 succès)

## Issues
- [ ] Gas costs légèrement élevés (45k vs 30k estimate) → Optimize weights
- [ ] Vote notification manquante → Add event indexer

## Suggestions
- Multi-sig support pour missions >1000 DAOT
- Reputation score pour applicants
```

---

### 5.3 Stress Testing (Semaine 3-4)

**Scenarios** :
1. **100 missions créées en 1h** : Verify no bottlenecks
2. **50 votes simultanés** : Governance quorum calculé correctement
3. **10 collators simulés** : Test network resilience (si possible)
4. **24h uptime** : Collator stable sans restart

**Metrics cibles** :
- Uptime : ≥99.5%
- Average block time : 6s ± 0.5s
- Transaction finality : ≤12s (2 blocs)
- Gas costs : <50k per operation
- Missed blocks : <0.5%

**Outils monitoring** :
- Grafana Paseo : https://grafana.paseo.site/
- Prometheus collator : http://localhost:9615/metrics
- Polkadot.js Apps : Block explorer

---

## Phase 6 : Documentation Post-Tests (1-2 jours)

### 6.1 Rapport Déploiement Paseo

**Fichier** : `_docs/paseo-deployment-report.md`

**Structure** :
```markdown
# Paseo Deployment Report

**Date** : 2026-02-XX
**Parachain ID** : 2000
**Collator** : dao-collator-paseo
**Test duration** : 3 semaines

## Summary
- Governance : 15 proposals (10 approved, 3 rejected, 2 expired)
- Missions : 45 created, 42 completed, 3 cancelled
- Treasury : 1500 DAOT distributed, 12 milestones validated
- Uptime : 99.7% (3 weeks)

## Gas Benchmarks
- Create mission : 42k gas (vs 30k estimate) → +40%
- Vote : 28k gas (vs 25k estimate) → +12%
- Release payment : 35k gas (vs 30k estimate) → +16%

## Lessons Learned
1. Weight calculations underestimated by ~15-20% → Re-benchmark
2. Quorum General track trop élevé (50%) → Lower to 40%
3. Mission cancellation flow unclear → Add UI guidance

## Next Steps
- [ ] Fix gas costs (re-benchmark weights)
- [ ] Lower General quorum 50% → 40%
- [ ] Security audit (Trail of Bits)
- [ ] Mainnet deployment (Q3 2026)
```

---

### 6.2 Gas Benchmarks Documentation

**Fichier** : `_docs/gas-benchmarks-paseo.md`

**Content** :
```markdown
# Gas Benchmarks (Paseo Testnet)

| Extrinsic | Estimate | Real (Paseo) | Diff |
|-----------|----------|--------------|------|
| `marketplace.createMission()` | 30k | 42k | +40% |
| `governance.vote()` | 25k | 28k | +12% |
| `treasury.releaseMilestone()` | 30k | 35k | +16% |
| `paymentSplitter.split()` | 20k | 22k | +10% |

## Analysis
- **Root cause** : Weight calculations based on empty storage
- **Impact** : Users pay 15-20% more gas than expected
- **Fix** : Re-run benchmarks with realistic storage state

## Re-Benchmark Commands
\```bash
./target/release/dao-node benchmark pallet \
  --pallet pallet_marketplace \
  --extrinsic "*" \
  --steps 50 \
  --repeat 20 \
  --output pallets/marketplace/src/weights.rs
\```
```

---

### 6.3 Governance Stress Test Report

**Fichier** : `_docs/governance-stress-test.md`

**Content** :
```markdown
# Governance Stress Test (Paseo)

## Test Setup
- **Accounts** : 10 utilisateurs (5 voters, 5 proposers)
- **Duration** : 2 semaines (4 governance cycles)
- **Proposals** : 15 total (General: 8, Treasury: 5, Emergency: 2)

## Results

### Participation Rate
- General track : 60% (3/5 voters participated)
- Treasury track : 80% (4/5 voters participated)
- Emergency track : 100% (5/5 voters, urgent)

### Quorum Analysis
- General (50% quorum) : 2/8 proposals failed quorum → **TOO HIGH**
- Treasury (40% quorum) : 0/5 proposals failed → **OPTIMAL**
- Emergency (80% quorum) : 0/2 proposals failed → **ACCEPTABLE**

## Recommendations
1. **Lower General quorum** : 50% → 40% (align with Treasury)
2. **Add notifications** : Email/Discord alerts when vote starts
3. **Extend vote duration** : General 3 jours → 5 jours (more participation)

## Mainnet Configuration
\```rust
pub const GeneralQuorum: Perbill = Perbill::from_percent(40); // Was 50%
pub const GeneralVoteDuration: BlockNumber = 5 * DAYS; // Was 3 days
\```
```

---

## Phase 7 : Cleanup & Next Steps (1 jour)

### 7.1 Backup Artifacts

**Fichiers à sauvegarder** :
```bash
# Create backup archive
cd C:\dev\dao
mkdir -p _deployment/paseo-backup
cp substrate-runtime/paseo-genesis-* _deployment/paseo-backup/
cp substrate-runtime/chain-specs/paseo-raw.json _deployment/paseo-backup/
cp _docs/paseo-*.md _deployment/paseo-backup/

# Compress
tar -czf paseo-deployment-backup-$(date +%Y%m%d).tar.gz _deployment/paseo-backup/

# Upload to secure storage (S3, Dropbox, etc.)
```

---

### 7.2 Arrêter Collator (si fin tests)

**Si tests terminés et déploiement mainnet planifié** :

```bash
# Stop collator service
sudo systemctl stop dao-collator

# Clean data (optional, garde genesis artifacts)
sudo rm -rf /var/lib/dao-collator/chains/

# Keep configs
sudo systemctl disable dao-collator
```

**Si tests continus (keep running)** : Laisser collator actif pour feedback communauté.

---

### 7.3 Planifier Audit Sécurité

**Timeline** :
- Paseo tests OK (3-4 semaines) → Audit (4-6 semaines) → Mainnet (Q3 2026)

**Auditors recommandés** :
1. **Trail of Bits** : $50-80k, 4-6 semaines (best reputation)
2. **Oak Security** : $30-60k, 3-5 semaines (Polkadot expert)
3. **OpenZeppelin** : $30-50k, 3-4 semaines (Solidity focus)

**Scope audit** :
- 4 pallets Substrate (~800 lines each)
- Governance logic (quorum, vote weights, tracks)
- Treasury escrow mechanism
- Mission lifecycle state machine
- Payment splitter

**Next action** :
- [ ] Contact auditors (demander devis)
- [ ] Préparer documentation technique pour audit
- [ ] Allouer budget audit ($50-80k)

---

## Troubleshooting

### Issue 1 : Parachain Pas "Registered" Après 6h

**Symptôme** : Statut reste "Parathread", pas "Parachain"

**Causes possibles** :
1. Genesis artifacts invalides (wasm/state corrompu)
2. Parachain ID incorrect (pas celui réservé)
3. Deposit insuffisant (≥50 PAS requis)

**Debug** :
```bash
# Vérifier parachain status
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "state_call", "params": ["ParasApi_lifecycle", "0x..."]}' \
  wss://api-paseo.n.dwellir.com/

# Vérifier deposit
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "query_info", "params": ["registrar", "paras"]}' \
  wss://api-paseo.n.dwellir.com/
```

**Fix** :
- Re-export genesis artifacts avec ID correct
- Re-submit registration avec deposit ≥50 PAS
- Attendre 12-24h (processus asynchrone)

---

### Issue 2 : Collator Ne Produit Pas de Blocs

**Symptôme** : Logs "Waiting for slot..." sans "Produced candidate"

**Causes possibles** :
1. Coretime non acquis (pas de droit produire blocs)
2. Session keys non insérées OU invalides
3. Collator pas dans invulnerables set

**Debug** :
```bash
# Vérifier coretime actif
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "state_call", "params": ["ParasApi_lifecycle", "0xD0070000"]}' \
  wss://api-paseo.n.dwellir.com/
# Expected: "Parachain" (not "Parathread")

# Vérifier session keys
curl -H "Content-Type: application/json" \
  -d '{"id":1, "jsonrpc":"2.0", "method": "author_hasSessionKeys", "params": ["YOUR_SESSION_KEYS"]}' \
  http://localhost:9944
# Expected: true
```

**Fix** :
- Acquérir coretime (bulk OU on-demand)
- Re-insert session keys via `session.setKeys()`
- Vérifier `collatorSelection.invulnerables` contient votre adresse

---

### Issue 3 : Gas Costs Très Élevés (>100k)

**Symptôme** : Transactions échouent avec "InsufficientFunds" ou gas >100k

**Causes possibles** :
1. Weights non benchmarkés (defaults trop élevés)
2. Storage bloat (reads/writes excessifs)
3. Logic inefficace (loops non bornés)

**Debug** :
```bash
# Benchmark weights
./target/release/dao-node benchmark pallet \
  --pallet pallet_marketplace \
  --extrinsic "*" \
  --steps 50 \
  --repeat 20 \
  --output pallets/marketplace/src/weights.rs

# Analyze worst-case extrinsic
grep -A5 "pub fn create_mission" pallets/marketplace/src/weights.rs
```

**Fix** :
- Re-benchmark avec données réalistes (pas storage vide)
- Optimiser logic (reduce storage reads/writes)
- Bound loops (use `BoundedVec`, limit iterations)

---

### Issue 4 : Faucet Rate Limit Atteint

**Symptôme** : "Rate limit exceeded. Try again in 24h"

**Workaround** :
1. Créer 2-3 comptes supplémentaires (deployer2, deployer3)
2. Request 100 PAS par compte
3. Transfer vers compte principal :
   ```bash
   # Via Polkadot.js Apps
   # Accounts → Send → To: YOUR_MAIN_ACCOUNT → Amount: 95 PAS
   ```

**Tip** : Demander PAS pour 3 comptes dès Phase 1 (anticiper)

---

## Validation Finale

**Checklist avant mainnet** :
- [ ] Paseo tests : 2-4 semaines complètes
- [ ] Governance : ≥10 proposals (80%+ approval)
- [ ] Missions : ≥30 créées, ≥90% completion rate
- [ ] Treasury : ≥10 payouts distribués, 0 bug
- [ ] Uptime : ≥99.5% sur 3 semaines
- [ ] Gas costs : <50k per operation
- [ ] Community feedback : Positif (≥80%)
- [ ] Documentation : Rapport + benchmarks + lessons learned
- [ ] Security audit : Scheduled (Trail of Bits, Oak Security)

**Si tous ✅ → Proceed to mainnet** (Q3 2026)

---

## Next Steps

1. **Maintenant** : Phase 0-1 (setup + tokens PAS)
2. **Semaine 1** : Phase 2-4 (deploy parachain + collator)
3. **Semaine 2-4** : Phase 5 (tests production-like)
4. **Semaine 5** : Phase 6 (documentation)
5. **Q2 2026** : Security audit (4-6 semaines)
6. **Q3 2026** : Mainnet deployment

**Total effort** : 5 semaines Paseo + 6 semaines audit = **11 semaines Gate 2 → Mainnet**

---

## Resources

| Ressource | URL |
|-----------|-----|
| **Paseo Site** | https://paseo.site/ |
| **Faucet** | https://paritytech.github.io/polkadot-testnet-faucet/ |
| **RPC Endpoint** | wss://api-paseo.n.dwellir.com/ |
| **Polkadot.js Apps** | https://polkadot.js.org/apps/?rpc=wss%3A%2F%2Fapi-paseo.n.dwellir.com%2F |
| **Chain Specs** | https://paseo-r2.zondax.ch/chain-specs/ |
| **Support** | https://github.com/paseo-network/support |
| **Monitoring** | https://grafana.paseo.site/ |
| **Deployment Guide** | https://docs.polkadot.com/tutorials/polkadot-sdk/parachains/zero-to-hero/deploy-to-testnet/ |

---

**Version** : 1.0.0
**Last updated** : 2026-02-10
**Maintainer** : DAO Team
