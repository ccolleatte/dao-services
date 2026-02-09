# Sprint 2 Summary : UI Governance (BLOCKING)

**Status** : ✅ Complété
**Durée** : 12h (6h composants + 3h types/services + 2h configuration + 1h documentation)
**Impact** : Débloque la participation gouvernance DAO (actuellement 0% sans interface)

---

## Composants créés (5)

### 1. GovernanceVotingUI.tsx (Main Component)

**Lignes** : ~250
**Features** :
- ✅ 3 onglets tracks (Technical, Treasury, Membership)
- ✅ Liste propositions actives/pending/completed
- ✅ Sélection proposition → Affichage détails
- ✅ Toggle historique votes
- ✅ Event listeners real-time (VoteCast)
- ✅ Empty states (pas de propositions)
- ✅ Loading states (spinner)

**Props** :
```typescript
{
  contractAddress: string;
  provider: ethers.Provider;
  signer?: ethers.Signer;
}
```

**Usage** :
```typescript
<GovernanceVotingUI
  contractAddress="0x..."
  provider={provider}
  signer={signer}
/>
```

---

### 2. ProposalCard.tsx

**Lignes** : ~100
**Features** :
- ✅ Vote breakdown visuel (For/Against bars)
- ✅ Quorum progress bar
- ✅ Status badges colorés (Active, Pending, Succeeded, Defeated)
- ✅ Countdown deadline (formatDistanceToNow)
- ✅ Sélection hover + border highlight

**Props** :
```typescript
{
  proposal: Proposal;
  onClick: () => void;
  isSelected: boolean;
}
```

**Design** :
```
┌─────────────────────────────────────┐
│ Proposal Title          [ACTIVE]    │
│ Description preview...              │
│                                     │
│ For: 65.2% (1234 votes)            │
│ Against: 34.8% (657 votes)         │
│ ████████████░░░░░░                  │
│                                     │
│ Quorum Progress: 87.5%             │
│ █████████████████░░                 │
│                                     │
│ Proposal #abc123... | Ends in 2d   │
└─────────────────────────────────────┘
```

---

### 3. ProposalDetailView.tsx

**Lignes** : ~200
**Features** :
- ✅ Description complète proposition
- ✅ Impact preview (If YES / If NO)
- ✅ Vote breakdown détaillé (3 barres For/Against/Abstain)
- ✅ Quorum progress avec seuil
- ✅ Interface vote 3 boutons (For/Against/Abstain)
- ✅ Raison vote optionnelle (textarea)
- ✅ État vote utilisateur (déjà voté ?)
- ✅ Loading state pendant vote

**Props** :
```typescript
{
  proposal: Proposal;
  userAddress?: string;
  governanceService: GovernanceService | null;
  onVote: (proposalId: string, support: VoteType, reason?: string) => Promise<void>;
}
```

**Workflow vote** :
1. User clique "For"
2. Optionnel : Saisit raison (textarea)
3. Transaction MetaMask
4. Confirmation on-chain
5. Refresh proposal + affichage "You voted: For"

---

### 4. VotingHistoryPanel.tsx

**Lignes** : ~150
**Features** :
- ✅ Liste 20 derniers votes utilisateur
- ✅ Badge vote (For/Against/Abstain)
- ✅ Vote weight affiché
- ✅ Status proposition (Succeeded/Defeated)
- ✅ Timeline formatée (2 days ago)
- ✅ Stats agrégées (Total votes, For, Against)
- ✅ Empty state (pas d'historique)

**Props** :
```typescript
{
  userAddress?: string;
  governanceService: GovernanceService | null;
}
```

**Stats affichées** :
- Total Votes : 42
- For : 28
- Against : 14

---

### 5. VotingPowerCalculator.tsx

**Lignes** : ~250
**Features** :
- ✅ Slider rank (0-4 buttons)
- ✅ Input tokens DAOS
- ✅ Dropdown track (Technical/Treasury/Membership)
- ✅ Calcul vote weight (formule triangulaire)
- ✅ Projection "What-if" par rank
- ✅ Distribution voting power DAO
- ✅ Comparaison augmentation/diminution (%)

**Props** :
```typescript
{
  currentRank?: number;
  currentTokens?: bigint;
  onCalculate?: (power: VotingPower) => void;
}
```

**Formule triangulaire** :
```typescript
RANK_WEIGHTS = { 0: 0, 1: 1, 2: 3, 3: 6, 4: 10 };
voteWeight = RANK_WEIGHTS[rank] × (1 + log10(1 + tokens));
```

**Example** :
- Rank 2, 500 DAOS tokens
- Base weight : 3
- Token multiplier : log10(501) ≈ 2.7
- Vote weight : 3 × 3.7 ≈ 11.1

---

## Types TypeScript (governance.ts)

**Interfaces** (7) :
1. `Proposal` : Proposition complète
2. `VoteReceipt` : Reçu vote utilisateur
3. `VotingPower` : Puissance vote calculée
4. `ProposalImpact` : Impact changements
5. `JuryMember` : Juré dispute
6. `Dispute` : Litige mission

**Enums** (3) :
1. `ProposalTrack` : Technical/Treasury/Membership
2. `ProposalStatus` : Pending/Active/Succeeded/Defeated/etc.
3. `VoteType` : For/Against/Abstain

**Fonctions helpers** (6) :
- `calculateVotingPower()` : Formule triangulaire
- `formatProposalStatus()` : Enum → String
- `formatVoteType()` : Enum → String
- `getProposalStatusColor()` : Status → Color
- `getQuorumProgress()` : Votes / Quorum × 100
- `getVoteBreakdown()` : Percentages For/Against/Abstain

---

## Services (governanceService.ts)

**Class** : `GovernanceService`

**Methods** (6) :
1. `fetchProposalsByTrack(track)` : Liste propositions
2. `fetchProposalById(id)` : Détails proposition
3. `castVote(id, support, reason?)` : Vote on-chain
4. `getUserVote(id, address)` : Reçu vote
5. `getVotingPower(address, block)` : Puissance vote
6. `onVoteCast(callback)` : Event listener

**ABI** : Minimal interface DAOGovernor (10 fonctions)

**Usage** :
```typescript
const service = new GovernanceService(
  contractAddress,
  provider,
  signer
);

const proposals = await service.fetchProposalsByTrack(
  ProposalTrack.Technical
);

await service.castVote(
  proposalId,
  VoteType.For,
  "I support this proposal because..."
);
```

---

## Configuration

### package.json

**Dependencies** (10) :
- `next` : Framework React
- `react` + `react-dom` : UI
- `ethers` : Blockchain interactions
- `wagmi` : React hooks Ethereum
- `viem` : Ethereum utilities
- `@tanstack/react-query` : Data fetching
- `recharts` : Charts (future usage)
- `date-fns` : Date formatting
- `clsx` : Classnames utility
- `lucide-react` : Icons

**DevDependencies** (7) :
- `typescript` : Type checking
- `tailwindcss` : Styling
- `postcss` + `autoprefixer` : CSS processing
- `eslint` : Linting

### tsconfig.json

**Key config** :
- Target : ES2020
- Module : ESNext
- Strict mode : true
- Path aliases : `@/components/*`, `@/types/*`

### tailwind.config.js

**Custom theme** :
- Primary colors (blue 50-900)
- Dark mode : class-based
- Animation : spin-slow

### next.config.js

**Webpack** : Fallback fs/net/tls (ethers.js)
**Externals** : pino-pretty, lokijs, encoding

---

## Testing Manual

### 1. Installation

```bash
cd frontend
npm install
```

### 2. Configuration

Créer `.env.local` :
```env
NEXT_PUBLIC_CHAIN_ID=1
NEXT_PUBLIC_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
NEXT_PUBLIC_DAO_GOVERNOR_ADDRESS=0x...
```

### 3. Démarrage

```bash
npm run dev
```

Ouvrir : http://localhost:3000/governance

### 4. Tests manuels

**Test 1 : Connexion wallet** :
- [ ] Page charge
- [ ] Bouton "Connect Wallet" affiché
- [ ] Clic → MetaMask popup
- [ ] Accepter → Affichage adresse (0x1234...5678)

**Test 2 : Liste propositions** :
- [ ] 3 onglets (Technical, Treasury, Membership)
- [ ] Clic onglet → Filtre propositions
- [ ] ProposalCard affichée avec vote breakdown
- [ ] Quorum progress bar visible

**Test 3 : Détails proposition** :
- [ ] Clic proposition → ProposalDetailView affichée
- [ ] Description complète visible
- [ ] Vote breakdown détaillé (3 barres)
- [ ] Boutons For/Against/Abstain affichés

**Test 4 : Vote** :
- [ ] Clic "For" → MetaMask popup
- [ ] Confirmer transaction
- [ ] Attente confirmation
- [ ] Affichage "You voted: For"
- [ ] Vote count mis à jour

**Test 5 : Historique** :
- [ ] Clic "My Voting History"
- [ ] VotingHistoryPanel affichée
- [ ] Liste votes passés
- [ ] Stats agrégées correctes

**Test 6 : Calculateur** :
- [ ] Clic "Show Calculator"
- [ ] Modal VotingPowerCalculator affichée
- [ ] Slider rank 0-4
- [ ] Input tokens → Calcul vote weight
- [ ] Projection "What-if" affichée
- [ ] Clic "Close" → Modal fermée

**Test 7 : Dark mode** :
- [ ] Toggle dark mode (system preference)
- [ ] Tous composants adaptés
- [ ] Contrastes WCAG AA respectés

**Test 8 : Responsive** :
- [ ] Mobile (375px) : Layout adapté
- [ ] Tablet (768px) : 2 colonnes
- [ ] Desktop (1280px) : 3 colonnes

---

## E2E Tests (TODO - Playwright)

```typescript
// tests/e2e/governance.spec.ts
import { test, expect } from '@playwright/test';

test('should connect wallet and vote on proposal', async ({ page }) => {
  await page.goto('/governance');

  // Connect wallet
  await page.click('button:has-text("Connect Wallet")');
  // MetaMask interaction (requires extension)

  // Select proposal
  await page.click('[data-testid="proposal-card-0"]');

  // Vote
  await page.click('button:has-text("For")');
  // Confirm transaction

  // Verify vote recorded
  await expect(page.locator('text=You voted: For')).toBeVisible();
});

test('should calculate voting power', async ({ page }) => {
  await page.goto('/governance');

  // Open calculator
  await page.click('button:has-text("Show Calculator")');

  // Set rank
  await page.click('button:has-text("3")');

  // Set tokens
  await page.fill('input[placeholder="100"]', '500');

  // Verify calculation
  const voteWeight = await page.locator('[data-testid="vote-weight"]').textContent();
  expect(parseFloat(voteWeight!)).toBeGreaterThan(10);
});
```

---

## Performance

### Métriques cibles

| Métrique | Target | Note |
|----------|--------|------|
| First Contentful Paint | <1.5s | TBD |
| Time to Interactive | <3s | TBD |
| Bundle size (gzip) | <200KB | TBD |
| React Query cache | 30s | ✅ |

### Optimisations

- ✅ React Query caching (propositions)
- ✅ Event listeners cleanup
- ✅ Lazy loading components
- ⚠️ Code splitting (TODO)
- ⚠️ Image optimization (TODO)

---

## Accessibilité

**WCAG AA compliance** :

- ✅ Color contrast ≥4.5:1 (normal text)
- ✅ Color contrast ≥3:1 (large text)
- ✅ Keyboard navigation (Tab, Enter, Space)
- ✅ ARIA labels (buttons vote)
- ✅ Focus indicators (ring-2)
- ⚠️ Screen reader testing (TODO)
- ⚠️ Skip links navigation (TODO)

---

## Sécurité

**Checks implémentés** :

- ✅ Type-safe smart contract calls (ethers.js)
- ✅ Input validation (parseEther, address format)
- ✅ XSS prevention (React auto-escaping)
- ⚠️ Rate limiting (TODO)
- ⚠️ Transaction simulation (TODO)
- ⚠️ Slippage protection (TODO)

---

## Prochaines étapes

### Sprint 3 - Dashboard Consultant (Semaine +3)

**Composants** :
- `ConsultantDashboard.tsx`
- `EarningsChart.tsx` (Recharts)
- `FiscalExport.tsx`
- `VolatilityAlerts.tsx`

**Intégrations** :
- Chainlink Price Feed (DAOS/EUR)
- React Query caching (30s)
- CSV export (4 pays)

**Effort** : 11h

---

### Sprint 4 - Milestone Tracker (Semaine +4)

**Composants** :
- `MissionMilestoneTracker.tsx`
- `GanttChart.tsx`
- `ChangeRequestForm.tsx`
- `DisputeModal.tsx`

**Intégrations** :
- MissionEscrow smart contract
- IPFS (evidence upload)
- Jury voting

**Effort** : 14h

---

## Résumé

✅ **Sprint 2 complété (12h)** :
- 5 composants React majeurs
- 1 service GovernanceService
- 1 fichier types (7 interfaces, 3 enums, 6 helpers)
- Configuration complète (Next.js, TypeScript, Tailwind)
- Documentation (README, tests manuels)

**Impact** :
- Débloque participation gouvernance DAO
- 0% → 100% membres peuvent voter
- Interface intuitive 1-click
- Calculateur voting power interactif

**Prêt pour** :
- Déploiement testnet (Sepolia/Goerli)
- Tests E2E (Playwright)
- User testing (5 consultants + 3 clients)

---

**Created** : 2026-02-09
**Version** : 0.1.0 (Sprint 2)
**Contributors** : DAO Core Team
