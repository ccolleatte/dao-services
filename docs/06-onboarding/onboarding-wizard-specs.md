# Spécifications Wizard Onboarding

> **Public** : Développeurs frontend
> **Stack** : Next.js 15, TypeScript, TailwindCSS, ethers.js
> **Temps lecture** : 20 minutes

---

## 🎯 Objectif

Créer un wizard d'onboarding interactif qui guide l'utilisateur (consultant ou client) à travers les étapes de création de compte et première action, avec une expérience pédagogique optimale.

---

## 📋 User Stories

### US-1 : En tant que consultant, je veux créer mon compte en <5 min

**Critères d'acceptation** :
- [ ] Wizard détecte automatiquement si wallet déjà connecté
- [ ] Guidage pas-à-pas création wallet si nécessaire
- [ ] Sauvegarde phrase récupération avec confirmation utilisateur
- [ ] Profil consultant minimal complété (nom, spécialité, tarif)
- [ ] Mission test proposée à la fin

### US-2 : En tant que client, je veux publier ma première mission en <10 min

**Critères d'acceptation** :
- [ ] Wizard détecte automatiquement si wallet déjà connecté
- [ ] Guidage achat tokens DAOS avec estimation coût
- [ ] Template de brief pré-rempli avec exemples
- [ ] Validation budget suffisant avant publication
- [ ] Confirmation publication avec lien vers mission

### US-3 : En tant qu'utilisateur, je veux comprendre les concepts blockchain sans jargon

**Critères d'acceptation** :
- [ ] Tooltips contextuels sur termes complexes
- [ ] Analogies monde réel intégrées
- [ ] Vidéos explicatives courtes (<2 min) optionnelles
- [ ] Quiz final optionnel avec badge de complétion

---

## 🏗️ Architecture Wizard

### Structure Components

```
components/
└── onboarding/
    ├── WizardContainer.tsx          # Container principal
    ├── ProgressBar.tsx               # Barre progression visuelle
    ├── steps/
    │   ├── ConsultantWizard/
    │   │   ├── Step1CreateWallet.tsx
    │   │   ├── Step2CompleteProfile.tsx
    │   │   ├── Step3TestMission.tsx
    │   │   └── Step4Congratulations.tsx
    │   └── ClientWizard/
    │       ├── Step1CreateWallet.tsx
    │       ├── Step2BuyTokens.tsx
    │       ├── Step3PublishMission.tsx
    │       └── Step4Congratulations.tsx
    ├── shared/
    │   ├── WalletSetup.tsx           # Component création wallet (réutilisable)
    │   ├── SeedPhraseBackup.tsx      # Component sauvegarde phrase
    │   ├── TooltipHelp.tsx           # Tooltip avec définitions
    │   └── VideoPlayer.tsx           # Player vidéos courtes
    └── utils/
        ├── wizardProgress.ts          # State management progression
        └── validations.ts             # Validations formulaires
```

### State Management (Zustand)

```typescript
// stores/onboardingStore.ts
import { create } from 'zustand';
import { persist } from 'zustand/middleware';

interface OnboardingState {
  // User type
  userType: 'consultant' | 'client' | null;
  setUserType: (type: 'consultant' | 'client') => void;

  // Wizard progress
  currentStep: number;
  completedSteps: number[];
  nextStep: () => void;
  previousStep: () => void;
  goToStep: (step: number) => void;

  // Wallet
  walletAddress: string | null;
  setWalletAddress: (address: string) => void;
  seedPhraseBackedUp: boolean;
  setSeedPhraseBackedUp: (backed: boolean) => void;

  // Consultant data
  consultantProfile: {
    name: string;
    specialty: string;
    experience: string;
    hourlyRate: number;
  } | null;
  setConsultantProfile: (profile: any) => void;

  // Client data
  clientProfile: {
    companyName: string;
    industry: string;
  } | null;
  setClientProfile: (profile: any) => void;
  tokensPurchased: boolean;
  setTokensPurchased: (purchased: boolean) => void;

  // Analytics
  startTime: number | null;
  completionTime: number | null;
  trackStart: () => void;
  trackCompletion: () => void;

  // Reset
  reset: () => void;
}

export const useOnboardingStore = create<OnboardingState>()(
  persist(
    (set, get) => ({
      userType: null,
      setUserType: (type) => set({ userType: type }),

      currentStep: 1,
      completedSteps: [],
      nextStep: () => {
        const current = get().currentStep;
        set({
          currentStep: current + 1,
          completedSteps: [...get().completedSteps, current],
        });
      },
      previousStep: () => set({ currentStep: Math.max(1, get().currentStep - 1) }),
      goToStep: (step) => set({ currentStep: step }),

      walletAddress: null,
      setWalletAddress: (address) => set({ walletAddress: address }),
      seedPhraseBackedUp: false,
      setSeedPhraseBackedUp: (backed) => set({ seedPhraseBackedUp: backed }),

      consultantProfile: null,
      setConsultantProfile: (profile) => set({ consultantProfile: profile }),

      clientProfile: null,
      setClientProfile: (profile) => set({ clientProfile: profile }),
      tokensPurchased: false,
      setTokensPurchased: (purchased) => set({ tokensPurchased: purchased }),

      startTime: null,
      completionTime: null,
      trackStart: () => set({ startTime: Date.now() }),
      trackCompletion: () => set({ completionTime: Date.now() }),

      reset: () => set({
        currentStep: 1,
        completedSteps: [],
        walletAddress: null,
        seedPhraseBackedUp: false,
        consultantProfile: null,
        clientProfile: null,
        tokensPurchased: false,
        startTime: null,
        completionTime: null,
      }),
    }),
    {
      name: 'onboarding-storage',
      partialize: (state) => ({
        // Persiste uniquement données non sensibles
        completedSteps: state.completedSteps,
        consultantProfile: state.consultantProfile,
        clientProfile: state.clientProfile,
      }),
    }
  )
);
```

---

## 🎨 UI Components Détaillés

### 1. WizardContainer

**Responsabilité** : Layout principal wizard avec barre progression

```tsx
// components/onboarding/WizardContainer.tsx
import { ReactNode } from 'react';
import { ProgressBar } from './ProgressBar';
import { useOnboardingStore } from '@/stores/onboardingStore';

interface WizardContainerProps {
  children: ReactNode;
  totalSteps: number;
  title: string;
  subtitle?: string;
}

export function WizardContainer({
  children,
  totalSteps,
  title,
  subtitle,
}: WizardContainerProps) {
  const { currentStep, completedSteps } = useOnboardingStore();

  const progress = (completedSteps.length / totalSteps) * 100;

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 to-indigo-100 flex items-center justify-center p-4">
      <div className="w-full max-w-4xl bg-white rounded-2xl shadow-2xl overflow-hidden">
        {/* Header avec progression */}
        <div className="bg-indigo-600 text-white p-6">
          <h1 className="text-3xl font-bold mb-2">{title}</h1>
          {subtitle && <p className="text-indigo-100">{subtitle}</p>}
          <ProgressBar current={currentStep} total={totalSteps} progress={progress} />
        </div>

        {/* Contenu étape actuelle */}
        <div className="p-8">
          {children}
        </div>

        {/* Footer avec aide */}
        <div className="bg-gray-50 border-t border-gray-200 p-4 text-center text-sm text-gray-600">
          Besoin d'aide ?{' '}
          <a href="/support" className="text-indigo-600 hover:underline">
            Contactez le support
          </a>
          {' ou consultez la '}
          <a href="/docs/faq" className="text-indigo-600 hover:underline">
            FAQ
          </a>
        </div>
      </div>
    </div>
  );
}
```

### 2. ProgressBar

**Responsabilité** : Affichage visuel progression utilisateur

```tsx
// components/onboarding/ProgressBar.tsx
interface ProgressBarProps {
  current: number;
  total: number;
  progress: number;
}

export function ProgressBar({ current, total, progress }: ProgressBarProps) {
  return (
    <div className="mt-4">
      {/* Steps indicators */}
      <div className="flex justify-between items-center mb-2">
        {Array.from({ length: total }, (_, i) => i + 1).map((step) => (
          <div
            key={step}
            className={`flex items-center justify-center w-10 h-10 rounded-full border-2 ${
              step < current
                ? 'bg-green-500 border-green-500 text-white'
                : step === current
                ? 'bg-white border-white text-indigo-600 font-bold'
                : 'bg-indigo-400 border-indigo-400 text-indigo-200'
            }`}
          >
            {step < current ? '✓' : step}
          </div>
        ))}
      </div>

      {/* Progress bar */}
      <div className="w-full bg-indigo-300 rounded-full h-2">
        <div
          className="bg-white rounded-full h-2 transition-all duration-300"
          style={{ width: `${progress}%` }}
        />
      </div>

      {/* Text progress */}
      <p className="text-right text-sm mt-1 text-indigo-100">
        Étape {current} sur {total}
      </p>
    </div>
  );
}
```

### 3. WalletSetup (Shared)

**Responsabilité** : Guidage création wallet MetaMask

```tsx
// components/onboarding/shared/WalletSetup.tsx
import { useState } from 'react';
import { useOnboardingStore } from '@/stores/onboardingStore';
import { ethers } from 'ethers';
import { SeedPhraseBackup } from './SeedPhraseBackup';

export function WalletSetup() {
  const { setWalletAddress, nextStep } = useOnboardingStore();
  const [hasMetaMask, setHasMetaMask] = useState(false);
  const [walletConnected, setWalletConnected] = useState(false);
  const [showSeedPhrase, setShowSeedPhrase] = useState(false);

  // Détection MetaMask
  const checkMetaMask = async () => {
    if (typeof window.ethereum !== 'undefined') {
      setHasMetaMask(true);
      // Auto-connect si déjà autorisé
      try {
        const provider = new ethers.BrowserProvider(window.ethereum);
        const accounts = await provider.listAccounts();
        if (accounts.length > 0) {
          setWalletAddress(accounts[0].address);
          setWalletConnected(true);
        }
      } catch (err) {
        console.error('Erreur connexion wallet:', err);
      }
    } else {
      setHasMetaMask(false);
    }
  };

  // Connexion wallet
  const connectWallet = async () => {
    try {
      const provider = new ethers.BrowserProvider(window.ethereum);
      const signer = await provider.getSigner();
      const address = await signer.getAddress();
      setWalletAddress(address);
      setWalletConnected(true);
    } catch (err) {
      console.error('Erreur connexion:', err);
      alert('Connexion refusée. Veuillez accepter dans MetaMask.');
    }
  };

  // Initialiser vérification au mount
  useState(() => {
    checkMetaMask();
  });

  return (
    <div className="space-y-6">
      <h2 className="text-2xl font-bold text-gray-900">
        1. Créer Votre Wallet
      </h2>

      {!hasMetaMask ? (
        // Cas : MetaMask pas installé
        <div className="bg-yellow-50 border border-yellow-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-yellow-900 mb-2">
            ⚠️ MetaMask non détecté
          </h3>
          <p className="text-yellow-800 mb-4">
            Vous devez installer l'extension MetaMask pour continuer.
          </p>
          <a
            href="https://metamask.io/download/"
            target="_blank"
            rel="noopener noreferrer"
            className="inline-block bg-orange-500 hover:bg-orange-600 text-white font-semibold py-3 px-6 rounded-lg"
          >
            Installer MetaMask →
          </a>
          <p className="text-sm text-yellow-700 mt-4">
            Après installation, rechargez cette page.
          </p>
        </div>
      ) : !walletConnected ? (
        // Cas : MetaMask installé mais pas connecté
        <div className="bg-blue-50 border border-blue-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-blue-900 mb-2">
            ✅ MetaMask détecté
          </h3>
          <p className="text-blue-800 mb-4">
            Connectez votre wallet pour continuer.
          </p>
          <button
            onClick={connectWallet}
            className="bg-indigo-600 hover:bg-indigo-700 text-white font-semibold py-3 px-6 rounded-lg"
          >
            Connecter MetaMask
          </button>

          {/* Info aide */}
          <details className="mt-4">
            <summary className="text-sm text-blue-700 cursor-pointer">
              🔍 Vous n'avez pas encore de wallet MetaMask ?
            </summary>
            <div className="mt-2 text-sm text-blue-600 space-y-2">
              <p>1. Ouvrez MetaMask (icône renard en haut à droite)</p>
              <p>2. Cliquez sur "Créer un wallet"</p>
              <p>3. Choisissez un mot de passe fort</p>
              <p>4. <strong>IMPORTANT</strong> : Notez votre phrase de 12 mots sur papier</p>
            </div>
          </details>
        </div>
      ) : !showSeedPhrase ? (
        // Cas : Wallet connecté, confirmation phrase sauvegardée
        <div className="bg-green-50 border border-green-200 rounded-lg p-6">
          <h3 className="text-lg font-semibold text-green-900 mb-2">
            ✅ Wallet connecté
          </h3>
          <p className="text-sm text-gray-600 mb-2">Adresse :</p>
          <code className="block bg-white p-2 rounded border border-gray-300 text-xs font-mono">
            {useOnboardingStore.getState().walletAddress}
          </code>

          {/* Vérification sauvegarde phrase */}
          <div className="mt-6 bg-red-50 border border-red-300 rounded-lg p-4">
            <h4 className="font-semibold text-red-900 mb-2">
              ⚠️ Vérification critique
            </h4>
            <p className="text-sm text-red-800 mb-4">
              Avez-vous bien sauvegardé votre phrase de récupération (12 ou 24 mots) ?
            </p>
            <div className="space-x-4">
              <button
                onClick={() => setShowSeedPhrase(true)}
                className="bg-red-600 hover:bg-red-700 text-white py-2 px-4 rounded"
              >
                Non, je dois la sauvegarder
              </button>
              <button
                onClick={() => {
                  useOnboardingStore.getState().setSeedPhraseBackedUp(true);
                  nextStep();
                }}
                className="bg-green-600 hover:bg-green-700 text-white py-2 px-4 rounded"
              >
                Oui, c'est fait
              </button>
            </div>
          </div>
        </div>
      ) : (
        // Cas : Afficher instructions sauvegarde phrase
        <SeedPhraseBackup onComplete={() => nextStep()} />
      )}
    </div>
  );
}
```

### 4. SeedPhraseBackup

**Responsabilité** : Guidage sauvegarde phrase récupération

```tsx
// components/onboarding/shared/SeedPhraseBackup.tsx
import { useState } from 'react';
import { useOnboardingStore } from '@/stores/onboardingStore';

interface SeedPhraseBackupProps {
  onComplete: () => void;
}

export function SeedPhraseBackup({ onComplete }: SeedPhraseBackupProps) {
  const [confirmed, setConfirmed] = useState(false);
  const { setSeedPhraseBackedUp } = useOnboardingStore();

  return (
    <div className="bg-red-50 border-2 border-red-400 rounded-lg p-6">
      <h3 className="text-xl font-bold text-red-900 mb-4">
        🔒 Sauvegarde Phrase de Récupération
      </h3>

      <div className="bg-white border border-red-300 rounded-lg p-4 mb-4">
        <h4 className="font-semibold text-gray-900 mb-2">
          Instructions (5 minutes)
        </h4>
        <ol className="list-decimal list-inside space-y-2 text-sm text-gray-700">
          <li>Ouvrez MetaMask (icône renard en haut à droite)</li>
          <li>Cliquez sur les 3 points → "Paramètres"</li>
          <li>Allez dans "Sécurité et confidentialité"</li>
          <li>Cliquez sur "Révéler la phrase de récupération secrète"</li>
          <li>Entrez votre mot de passe MetaMask</li>
          <li><strong className="text-red-600">NOTEZ LES 12 MOTS SUR PAPIER</strong> (pas de fichier numérique !)</li>
          <li>Vérifiez 2× que vous avez bien noté tous les mots dans l'ordre</li>
          <li>Conservez ce papier dans un coffre-fort ou lieu sécurisé</li>
        </ol>
      </div>

      {/* Avertissements */}
      <div className="bg-yellow-100 border border-yellow-400 rounded p-3 mb-4 text-sm">
        <p className="font-semibold text-yellow-900 mb-1">⚠️ Si vous perdez cette phrase :</p>
        <ul className="list-disc list-inside text-yellow-800 space-y-1">
          <li>Vous perdez l'accès à vos tokens DAOS</li>
          <li>Vous perdez votre profil et votre historique</li>
          <li>Personne (pas même l'équipe technique) ne peut vous aider</li>
        </ul>
      </div>

      {/* Confirmation */}
      <div className="space-y-4">
        <label className="flex items-start space-x-3">
          <input
            type="checkbox"
            checked={confirmed}
            onChange={(e) => setConfirmed(e.target.checked)}
            className="mt-1 h-5 w-5 text-indigo-600 rounded"
          />
          <span className="text-sm text-gray-700">
            Je confirme avoir noté ma phrase de récupération sur papier et l'avoir conservée
            en lieu sûr. Je comprends que personne ne peut la récupérer si je la perds.
          </span>
        </label>

        <button
          onClick={() => {
            setSeedPhraseBackedUp(true);
            onComplete();
          }}
          disabled={!confirmed}
          className={`w-full py-3 px-6 rounded-lg font-semibold ${
            confirmed
              ? 'bg-green-600 hover:bg-green-700 text-white'
              : 'bg-gray-300 text-gray-500 cursor-not-allowed'
          }`}
        >
          Continuer →
        </button>
      </div>
    </div>
  );
}
```

---

## 📊 Analytics & Tracking

### Métriques à Capturer

```typescript
// utils/analytics.ts
interface OnboardingMetrics {
  userType: 'consultant' | 'client';
  startTime: number;
  completionTime: number | null;
  stepTimings: Record<number, number>; // Temps passé par étape
  droppedAtStep: number | null; // Si abandon
  walletCreationMethod: 'existing' | 'new';
  errorCount: number;
  helpClickCount: number;
}

export function trackOnboardingEvent(
  eventName: string,
  properties: Record<string, any>
) {
  // Intégration avec analytics plateforme (ex : Mixpanel, Amplitude)
  if (typeof window !== 'undefined' && window.analytics) {
    window.analytics.track(eventName, properties);
  }
}

// Events à tracker
export const OnboardingEvents = {
  STARTED: 'onboarding_started',
  STEP_COMPLETED: 'onboarding_step_completed',
  WALLET_CONNECTED: 'wallet_connected',
  PROFILE_COMPLETED: 'profile_completed',
  MISSION_PUBLISHED: 'mission_published',
  COMPLETED: 'onboarding_completed',
  DROPPED: 'onboarding_dropped',
  HELP_CLICKED: 'onboarding_help_clicked',
};
```

### Dashboard Admin

**Métriques clés à afficher** :

| Métrique | Formule | Cible |
|----------|---------|-------|
| **Taux complétion wizard** | (Completions / Starts) × 100 | >80% |
| **Temps moyen consultant** | avg(completionTime - startTime) | <30 min |
| **Temps moyen client** | avg(completionTime - startTime) | <20 min |
| **Étape abandon max** | mode(droppedAtStep) | Identifier bottleneck |
| **Taux aide consulté** | (helpClicks / users) × 100 | <30% (clarté suffisante) |

---

## 🧪 Tests

### Tests Unitaires (Vitest + React Testing Library)

```typescript
// __tests__/WalletSetup.test.tsx
import { render, screen, waitFor } from '@testing-library/react';
import userEvent from '@testing-library/user-event';
import { WalletSetup } from '@/components/onboarding/shared/WalletSetup';

describe('WalletSetup', () => {
  it('affiche message si MetaMask non installé', () => {
    // Mock window.ethereum undefined
    (window as any).ethereum = undefined;

    render(<WalletSetup />);

    expect(screen.getByText(/MetaMask non détecté/i)).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /Installer MetaMask/i })).toBeInTheDocument();
  });

  it('permet connexion wallet si MetaMask installé', async () => {
    // Mock window.ethereum
    const mockProvider = {
      request: jest.fn().mockResolvedValue(['0x123...abc']),
    };
    (window as any).ethereum = mockProvider;

    render(<WalletSetup />);

    const connectButton = screen.getByRole('button', { name: /Connecter MetaMask/i });
    await userEvent.click(connectButton);

    await waitFor(() => {
      expect(screen.getByText(/Wallet connecté/i)).toBeInTheDocument();
    });
  });

  it('affiche vérification sauvegarde phrase après connexion', async () => {
    // ... test complet avec mock MetaMask
  });
});
```

### Tests E2E (Playwright)

```typescript
// e2e/onboarding-consultant.spec.ts
import { test, expect } from '@playwright/test';

test('Consultant peut compléter wizard onboarding', async ({ page, context }) => {
  // Install MetaMask extension (mock)
  // ...

  await page.goto('/onboarding');

  // Sélection type utilisateur
  await page.click('text=Je suis consultant');

  // Étape 1 : Wallet
  await expect(page.locator('h2:has-text("Créer Votre Wallet")')).toBeVisible();
  await page.click('button:has-text("Connecter MetaMask")');

  // Confirmer dans MetaMask (mock interaction)
  // ...

  await page.click('button:has-text("Oui, c\'est fait")'); // Phrase sauvegardée

  // Étape 2 : Profil
  await expect(page.locator('h2:has-text("Compléter Votre Profil")')).toBeVisible();
  await page.fill('input[name="name"]', 'Jean Dupont');
  await page.selectOption('select[name="specialty"]', 'Stratégie digitale');
  await page.fill('input[name="hourlyRate"]', '180');
  await page.click('button:has-text("Suivant")');

  // Étape 3 : Mission test
  await expect(page.locator('h2:has-text("Mission Test")')).toBeVisible();
  await page.fill('textarea[name="response"]', 'Ma réponse à la mission test...');
  await page.click('button:has-text("Soumettre")');

  // Étape 4 : Congratulations
  await expect(page.locator('text=Félicitations')).toBeVisible();
  await expect(page.locator('text=Badge "Ready to Consult"')).toBeVisible();

  // Vérifier analytics tracké
  const analyticsEvents = await page.evaluate(() => window.analytics?.events || []);
  expect(analyticsEvents).toContainEqual(
    expect.objectContaining({ event: 'onboarding_completed', userType: 'consultant' })
  );
});
```

---

## 🚀 Roadmap Implémentation

### Phase 1 (MVP - 2 semaines)

**Objectif** : Wizard fonctionnel basique (consultant + client)

- [ ] WizardContainer + ProgressBar
- [ ] WalletSetup component (détection MetaMask, connexion)
- [ ] ConsultantWizard (étapes 1-4)
- [ ] ClientWizard (étapes 1-4)
- [ ] State management Zustand
- [ ] Analytics basiques (completion rate)

### Phase 2 (Améliorations - 1 semaine)

**Objectif** : UX améliorée + pédagogie

- [ ] Tooltips contextuels (TooltipHelp component)
- [ ] Vidéos explicatives intégrées (VideoPlayer component)
- [ ] Animations transitions étapes (Framer Motion)
- [ ] Sauvegarde progression (local storage)
- [ ] Mode darkMode support

### Phase 3 (Gamification - 1 semaine)

**Objectif** : Engagement utilisateur

- [ ] Quiz final optionnel avec score
- [ ] Badges de progression ("Wallet Master", "Profile Complete", etc.)
- [ ] Leaderboard early adopters (temps complétion)
- [ ] Système de hints progressifs (si utilisateur bloqué >2 min)

### Phase 4 (Optimisations - 1 semaine)

**Objectif** : Performance + accessibilité

- [ ] Tests E2E complets (Playwright)
- [ ] Accessibilité WCAG 2.1 AA (ARIA labels, keyboard navigation)
- [ ] Optimisation bundle size (lazy loading steps)
- [ ] Support mobile responsive
- [ ] Tests utilisateurs (5-10 personnes)

---

## 📝 Notes Techniques

### Gestion Erreurs MetaMask

```typescript
// utils/walletErrors.ts
export enum WalletError {
  USER_REJECTED = 'USER_REJECTED',
  NETWORK_WRONG = 'NETWORK_WRONG',
  NOT_INSTALLED = 'NOT_INSTALLED',
  UNKNOWN = 'UNKNOWN',
}

export function handleWalletError(error: any): {
  type: WalletError;
  message: string;
  userMessage: string;
} {
  if (error.code === 4001) {
    return {
      type: WalletError.USER_REJECTED,
      message: 'User rejected connection',
      userMessage: 'Vous avez refusé la connexion. Veuillez accepter dans MetaMask.',
    };
  }

  if (error.code === -32002) {
    return {
      type: WalletError.USER_REJECTED,
      message: 'Request already pending',
      userMessage: 'Une demande est déjà en cours. Vérifiez MetaMask.',
    };
  }

  // Network error
  if (error.message?.includes('network')) {
    return {
      type: WalletError.NETWORK_WRONG,
      message: 'Wrong network',
      userMessage: 'Veuillez vous connecter au réseau Polkadot Hub Testnet (Paseo).',
    };
  }

  return {
    type: WalletError.UNKNOWN,
    message: error.message || 'Unknown error',
    userMessage: 'Une erreur est survenue. Veuillez réessayer.',
  };
}
```

### Validation Réseau Polkadot

```typescript
// utils/network.ts
export const NETWORKS = {
  PASEO_TESTNET: {
    chainId: 'TBD', // À compléter avec ID réel Paseo
    chainName: 'Polkadot Hub Testnet (Paseo)',
    rpcUrls: ['https://paseo.polkadot.io'],
    nativeCurrency: {
      name: 'Paseo',
      symbol: 'PAS',
      decimals: 18,
    },
    blockExplorerUrls: ['https://paseo.subscan.io'],
  },
};

export async function switchToCorrectNetwork() {
  const provider = window.ethereum;
  if (!provider) throw new Error('MetaMask not installed');

  try {
    await provider.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: NETWORKS.PASEO_TESTNET.chainId }],
    });
  } catch (switchError: any) {
    // Si réseau pas ajouté, le proposer
    if (switchError.code === 4902) {
      await provider.request({
        method: 'wallet_addEthereumChain',
        params: [NETWORKS.PASEO_TESTNET],
      });
    } else {
      throw switchError;
    }
  }
}
```

---

**Dernière mise à jour** : 2026-02-08
**Version** : 0.1.0-alpha
