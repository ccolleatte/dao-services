# DAO Governance Frontend

Interface utilisateur Next.js pour la gouvernance DAO avec système de vote on-chain.

## Features

### Sprint 2 - UI Governance (CRITICAL)

✅ **Composants implémentés** :

1. **GovernanceVotingUI** - Interface principale de vote
   - 3 onglets (Technical, Treasury, Membership)
   - Liste propositions actives/pending/completed
   - Affichage temps réel des résultats
   - Historique votes personnel

2. **ProposalCard** - Carte résumé proposition
   - Vote breakdown (For/Against/Abstain)
   - Progress quorum
   - Status badges colorés
   - Countdown deadline

3. **ProposalDetailView** - Détails complets + vote
   - Description complète proposition
   - Impact preview (If YES / If NO)
   - Interface vote 1-click (For/Against/Abstain)
   - Raison optionnelle (on-chain)

4. **VotingHistoryPanel** - Historique personnel
   - 20 derniers votes
   - Stats agrégées (total, for, against)
   - Timeline activité

5. **VotingPowerCalculator** - Calculateur interactif
   - Slider rank (0-4)
   - Input tokens DAOS
   - Projection "What-if" par rank
   - Distribution DAO

### Types TypeScript

- `Proposal` : Proposition complète avec votes
- `VoteReceipt` : Reçu vote utilisateur
- `VotingPower` : Puissance vote calculée
- `ProposalTrack` : Enum tracks (Technical/Treasury/Membership)
- `ProposalStatus` : Enum status (Pending/Active/Succeeded/Defeated/etc.)
- `VoteType` : Enum (For/Against/Abstain)

### Services

- `GovernanceService` : Abstraction ethers.js pour DAOGovernor
  - `fetchProposalsByTrack()` : Récupération propositions
  - `castVote()` : Vote on-chain
  - `getUserVote()` : Reçu vote utilisateur
  - `getVotingPower()` : Puissance vote à un block
  - Event listeners (VoteCast)

## Installation

```bash
cd frontend
npm install
```

## Configuration

Créer `.env.local` :

```env
# Blockchain
NEXT_PUBLIC_CHAIN_ID=1
NEXT_PUBLIC_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
NEXT_PUBLIC_DAO_GOVERNOR_ADDRESS=0x...

# WalletConnect (optional)
NEXT_PUBLIC_WALLETCONNECT_PROJECT_ID=...
```

## Développement

```bash
# Start dev server
npm run dev

# Type check
npm run type-check

# Lint
npm run lint

# Build production
npm run build
npm start
```

## Architecture

```
frontend/
├── components/
│   └── governance/
│       ├── GovernanceVotingUI.tsx      # Main component
│       ├── ProposalCard.tsx            # Proposal summary
│       ├── ProposalDetailView.tsx      # Full details + vote
│       ├── VotingHistoryPanel.tsx      # User history
│       └── VotingPowerCalculator.tsx   # Calculator
├── types/
│   └── governance.ts                   # TypeScript types
├── services/
│   └── governanceService.ts            # Smart contract abstraction
├── pages/
│   └── governance.tsx                  # Main page (example)
└── styles/
    └── globals.css                     # Tailwind CSS
```

## Usage

### Example Page

```typescript
// pages/governance.tsx
import { GovernanceVotingUI } from '@/components/governance/GovernanceVotingUI';
import { ethers } from 'ethers';
import { useProvider, useSigner } from 'wagmi';

export default function GovernancePage() {
  const provider = useProvider();
  const { data: signer } = useSigner();

  return (
    <GovernanceVotingUI
      contractAddress={process.env.NEXT_PUBLIC_DAO_GOVERNOR_ADDRESS!}
      provider={provider}
      signer={signer}
    />
  );
}
```

### Voting Power Calculator Standalone

```typescript
import { VotingPowerCalculator } from '@/components/governance/VotingPowerCalculator';

export default function CalculatorPage() {
  return (
    <div className="max-w-2xl mx-auto p-6">
      <VotingPowerCalculator
        currentRank={2}
        currentTokens={ethers.parseEther('500')}
        onCalculate={(power) => console.log('Voting power:', power)}
      />
    </div>
  );
}
```

## Testing

### E2E Tests (Playwright - TODO)

```bash
# Install Playwright
npm install -D @playwright/test

# Run E2E tests
npm run test:e2e
```

**Test scenarios** :
1. Connect wallet → Vote on proposal → Verify transaction
2. View voting history → Check stats
3. Use calculator → Verify calculations
4. Filter proposals by track → Verify results
5. View proposal details → Check impact preview

### Unit Tests (Vitest - TODO)

```bash
npm install -D vitest @testing-library/react

# Run unit tests
npm run test:unit
```

## Déploiement

### Vercel (recommandé)

```bash
# Install Vercel CLI
npm install -g vercel

# Deploy
vercel --prod
```

### Configuration Vercel

- **Framework Preset** : Next.js
- **Build Command** : `npm run build`
- **Output Directory** : `.next`
- **Install Command** : `npm install`

**Environment Variables** :
- `NEXT_PUBLIC_CHAIN_ID`
- `NEXT_PUBLIC_RPC_URL`
- `NEXT_PUBLIC_DAO_GOVERNOR_ADDRESS`

## Performances

### Optimisations implémentées

- **React Query** : Cache propositions (30s)
- **Event listeners** : Subscribe/unsubscribe automatique
- **Lazy loading** : Composants détails chargés on-demand
- **Memoization** : Calculs voting power mis en cache

### Métriques cibles

| Métrique | Target | Actuel |
|----------|--------|--------|
| First Contentful Paint | <1.5s | TBD |
| Time to Interactive | <3s | TBD |
| Largest Contentful Paint | <2.5s | TBD |
| Cumulative Layout Shift | <0.1 | TBD |

## Accessibilité

- ✅ ARIA labels sur boutons vote
- ✅ Keyboard navigation (Tab, Enter, Space)
- ✅ Dark mode support
- ✅ Color contrast WCAG AA (≥4.5:1)
- ⚠️ Screen reader testing (TODO)

## Sécurité

### Bonnes pratiques

- ✅ Type-safe smart contract calls (ethers.js)
- ✅ Input validation (token amounts, addresses)
- ✅ HTTPS only (production)
- ✅ Content Security Policy headers
- ⚠️ Rate limiting (TODO)
- ⚠️ Transaction simulation (TODO)

### Audit

- [ ] Smart contract interactions review
- [ ] Dependency audit (`npm audit`)
- [ ] OWASP Top 10 compliance
- [ ] Penetration testing

## Roadmap

### Sprint 3 - Dashboard Consultant (Semaine +3)

- [ ] `ConsultantDashboard.tsx`
- [ ] Chainlink Price Feed integration (DAOS/EUR)
- [ ] Export fiscal CSV (FR/BE/CH/LUX)
- [ ] Volatility alerts (notifications push)

### Sprint 4 - Milestone Tracker (Semaine +4)

- [ ] `MissionMilestoneTracker.tsx`
- [ ] Gantt chart component
- [ ] Change request workflow
- [ ] Dispute arbitrage interface

### Sprint 5 - Smart Contracts (Semaine +5-6)

- [ ] ServiceMarketplace integration
- [ ] MissionEscrow integration
- [ ] HybridPaymentSplitter integration

## Support

- **Documentation** : `/docs`
- **Discord** : `#frontend-support`
- **Issues** : GitHub Issues
- **Contributions** : Pull Requests welcome

## License

MIT License - See LICENSE file

---

**Version** : 0.1.0 (Sprint 2 - UI Governance)
**Last Updated** : 2026-02-09
**Contributors** : DAO Core Team
