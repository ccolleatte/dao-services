# Sprint 6 Summary - Data Layer & Backend Infrastructure

**Durée** : 19h (estimé) | **Status** : ✅ Complété
**Cumulative Progress** : 95h/95h (100%)

---

## Deliverables Completed

| Fichier | Lignes | Purpose | Status |
|---------|--------|---------|--------|
| `backend/supabase/migrations/001_schema.sql` | ~800 | Complete database schema with 18 tables | ✅ |
| `backend/api/routes/missions.ts` | ~400 | CRUD endpoints for marketplace missions | ✅ |
| `backend/api/routes/applications.ts` | ~300 | Application management endpoints | ✅ |
| `backend/services/event-sync-worker.ts` | ~400 | Blockchain event listener + Supabase sync | ✅ |
| `backend/services/webhooks.ts` | ~400 | Discord/Slack webhook notifications | ✅ |

**Total** : ~2,300 lignes de code backend + infrastructure

---

## Database Schema (18 Tables)

### Core Tables

| Table | Purpose | Key Features |
|-------|---------|--------------|
| `profiles` | User profiles (consultants + clients) | Skills array, hourly rate, reputation score, on-chain rank sync |
| `missions` | Marketplace jobs | Status enum (draft/active/on_hold/disputed/completed/cancelled), visibility control |
| `mission_applications` | Consultant applications | Proposal text + IPFS hash, proposed budget, match score (0-100) |
| `milestones` | Sequential deliverables | Order enforcement, status tracking, deliverable IPFS hash |
| `disputes` | Arbitration cases | Jury selection, voting period, resolution outcome |
| `dispute_votes` | Jury votes | Juror wallet, vote direction (for/against), timestamp |
| `contributors` | Hybrid contributors | Human/AI/Compute types, percentage allocation, usage tracking |
| `usage_logs` | Metering records | LLM tokens, GPU-hours, cost calculation |

### Supporting Tables

| Table | Purpose |
|-------|---------|
| `payments` | Payment history |
| `transactions` | Blockchain transaction log |
| `notifications` | In-app notifications |
| `ratings` | Consultant ratings |
| `match_scores` | Match score breakdown (cache) |
| `pricing_history` | Historical pricing data |
| `webhook_logs` | Webhook delivery logs |
| `chain_events` | Blockchain event log |

### RLS Policies

**Principe** : Row Level Security appliquée sur toutes les tables pour garantir accès contrôlé.

**Examples** :
```sql
-- Missions: Public if visibility=public, own if client/consultant
CREATE POLICY missions_public_read ON missions FOR SELECT
  USING (
    visibility = 'public' OR
    client_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
    selected_consultant_wallet = current_setting('request.jwt.claim.wallet_address', true)
  );

-- Applications: Own consultant OR mission client
CREATE POLICY applications_access ON mission_applications FOR SELECT
  USING (
    consultant_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
    mission_id IN (
      SELECT id FROM missions WHERE client_wallet = current_setting('request.jwt.claim.wallet_address', true)
    )
  );
```

---

## REST API Endpoints

### Missions API (`/api/missions`)

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/api/missions` | GET | List missions with filters (status, skills, budget, rank) + pagination | Optional |
| `/api/missions/:id` | GET | Mission details with applications, milestones, contributors | Public |
| `/api/missions` | POST | Create new mission (draft status) | Required |
| `/api/missions/:id` | PATCH | Update mission (before published) | Client only |
| `/api/missions/:id/publish` | POST | Publish mission (draft → active) | Client only |
| `/api/missions/:id/cancel` | POST | Cancel mission (any status → cancelled) | Client only |
| `/api/missions/:id/applications` | GET | List applications for mission (ordered by match score) | Client only |
| `/api/missions/:id/select-consultant` | POST | Select consultant (active → on_hold, create escrow) | Client only |

**Validation** : Zod schemas pour tous endpoints (input sanitization + type safety)

**Pagination** : `page` + `limit` params (default: page 1, limit 20)

**Filters** :
- `status`: mission_status enum
- `skills`: array of strings (contains operator)
- `min_budget`, `max_budget`: decimal range
- `min_rank`: consultant rank filter (0-4)

---

### Applications API (`/api/applications`)

| Endpoint | Method | Purpose | Auth |
|----------|--------|---------|------|
| `/api/applications` | GET | List consultant's own applications (optional status filter) | Required |
| `/api/applications/:id` | GET | Application details (own consultant OR mission client) | Required |
| `/api/applications` | POST | Create application (consultant only) | Required |
| `/api/applications/:id` | PATCH | Update application (before reviewed, consultant only) | Required |
| `/api/applications/:id` | DELETE | Withdraw application (consultant only, not if selected) | Required |
| `/api/applications/:id/calculate-match-score` | POST | Calculate on-chain match score (admin/cron only) | Required |

**Validation Rules** :
- Verify mission active before applying
- Check consultant rank ≥ mission.min_rank
- Prevent duplicate applications (unique constraint mission_id + consultant_wallet)
- Budget validation: proposed_budget ≤ mission.budget_max_daos
- Cannot apply to own mission

**Match Score Calculation** (see Sprint 5 for on-chain algorithm):
- 5 criteria: Rank (25%), Skills (25%), Budget (20%), Track Record (15%), Responsiveness (15%)
- Cached in `match_scores` table for analytics
- TODO: Call smart contract `ServiceMarketplace.calculateMatchScore()` (mock for now)

---

## Event Sync Worker

### Architecture

```
Blockchain (Polkadot Hub)
       ↓ (ethers.js event listeners)
Event Sync Worker (backend/services/event-sync-worker.ts)
       ↓ (INSERT/UPDATE queries)
Supabase PostgreSQL
```

### Events Handled

| Smart Contract Event | Supabase Action | Triggered On |
|---------------------|-----------------|--------------|
| `MissionCreated` | UPDATE `missions.on_chain_mission_id` | ServiceMarketplace.createMission() |
| `ApplicationSubmitted` | UPDATE `mission_applications.on_chain_application_id` | ServiceMarketplace.applyToMission() |
| `ConsultantSelected` | INSERT `mission_contributors`, UPDATE `missions.selected_consultant_wallet` | ServiceMarketplace.selectConsultant() |
| `MilestoneApproved` | UPDATE `milestones.status`, INSERT `payments` | MissionEscrow.approveMilestone() |
| `DisputeRaised` | INSERT `disputes` | MissionEscrow.raiseDispute() |
| `DisputeResolved` | UPDATE `disputes.winner_wallet`, INSERT `payments` | MissionEscrow.resolveDispute() |
| `PaymentDistributed` | UPDATE `contributors.payment_received` | HybridPaymentSplitter.distribute() |

### Workflow

1. **Startup** : Query `chain_events` table for last synced block
2. **Historical Sync** : Fetch all events from last synced block → latest block (catch-up)
3. **Real-time Listening** : Subscribe to new events via `contract.on('EventName', handler)`
4. **Event Processing** :
   - Validate event data
   - Execute Supabase query (INSERT/UPDATE)
   - Log transaction in `transactions` table
   - Log event in `chain_events` table (idempotency)
5. **Error Handling** : Exponential backoff on Supabase errors, log failures

### Deployment

**Environment Variables** :
```bash
# Blockchain RPC
RPC_URL=wss://polkadot-hub-rpc.example.com
CHAIN_ID=1000  # Polkadot Hub chain ID

# Contract Addresses (deployed from Sprint 5)
MARKETPLACE_ADDRESS=0x...
ESCROW_FACTORY_ADDRESS=0x...
PAYMENT_SPLITTER_FACTORY_ADDRESS=0x...

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...  # Service role key for bypassing RLS
```

**Start Worker** :
```bash
cd backend
npm run event-sync  # Runs: node dist/services/event-sync-worker.js
```

**PM2 Production** :
```bash
pm2 start dist/services/event-sync-worker.js --name dao-event-sync
pm2 save
```

---

## Webhook Service

### Supported Events

| Event Type | Webhook Payload | Discord Notification |
|------------|----------------|----------------------|
| `mission.published` | Mission ID, title, budget, client wallet | 📢 New Mission Published (Blurple embed) |
| `consultant.selected` | Mission ID, consultant wallet, match score | 🤝 Consultant Selected (Green embed) |
| `milestone.approved` | Milestone ID, amount DAOS, consultant wallet | ✅ Milestone Approved (Green embed) |
| `dispute.raised` | Dispute ID, initiator, reason | ⚠️ Dispute Raised (Red embed, high priority) |
| `dispute.resolved` | Dispute ID, winner, votes for/against | ⚖️ Dispute Resolved (Yellow embed) |
| `payment.distributed` | Recipients array (wallet, amount, type), total amount | 💰 Payment Distributed (Green embed) |

### Retry Logic

**Pattern** : Exponential backoff with 3 retries

```typescript
async function sendWebhook(url: string, payload: WebhookPayload, retries: number = 3) {
  let attempt = 0;

  while (attempt < retries) {
    try {
      attempt++;
      await axios.post(url, payload, { timeout: 10000 });

      // Log success
      await supabase.from('webhook_logs').insert({
        webhook_url: url,
        event_type: payload.event_type,
        delivered_at: new Date().toISOString(),
      });
      return;
    } catch (error) {
      if (attempt >= retries) throw error;

      // Exponential backoff: 1s, 2s, 4s
      await new Promise(resolve => setTimeout(resolve, Math.pow(2, attempt) * 1000));
    }
  }
}
```

### Configuration

**Environment Variables** :
```bash
# Generic webhooks (POST JSON)
WEBHOOK_MISSION_PUBLISHED=https://your-webhook-endpoint.com/mission-published
WEBHOOK_CONSULTANT_SELECTED=https://your-webhook-endpoint.com/consultant-selected
WEBHOOK_MILESTONE_APPROVED=https://your-webhook-endpoint.com/milestone-approved
WEBHOOK_DISPUTE_RAISED=https://your-webhook-endpoint.com/dispute-raised
WEBHOOK_DISPUTE_RESOLVED=https://your-webhook-endpoint.com/dispute-resolved
WEBHOOK_PAYMENT_DISTRIBUTED=https://your-webhook-endpoint.com/payment-distributed

# Discord webhook
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/123456789/abcdefg

# Slack webhook (optional)
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXX

# Frontend URL (for notification links)
FRONTEND_URL=https://dao-marketplace.example.com
```

### Discord Embed Format

**Example** : Mission Published Notification
```typescript
{
  username: 'DAO Marketplace',
  embeds: [{
    title: '📢 New Mission Published',
    description: 'Build secure authentication system',
    color: 0x5865F2,  // Blurple
    fields: [
      { name: 'Budget', value: '5000 DAOS', inline: true },
      { name: 'Client', value: '0x1234...5678', inline: true }
    ],
    timestamp: '2026-02-09T12:00:00Z'
  }]
}
```

### Supabase Function Integration

**Alternative deployment** : Supabase Edge Functions instead of Node.js service

```sql
-- Trigger webhook on mission publication
CREATE TRIGGER mission_published_webhook
  AFTER UPDATE OF status ON missions
  FOR EACH ROW
  WHEN (NEW.status = 'active' AND OLD.status = 'draft')
  EXECUTE FUNCTION supabase_functions.invoke('send-mission-published-webhook', NEW);
```

---

## Integration Examples

### Frontend - Mission Creation Flow

```typescript
import { useState } from 'react';
import { useSupabase } from '@/hooks/useSupabase';

export function CreateMissionForm() {
  const supabase = useSupabase();
  const [formData, setFormData] = useState({
    title: '',
    description: '',
    budget_max_daos: '',
    min_rank: 0,
    required_skills: [],
  });

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault();

    // Step 1: Create mission in Supabase (draft status)
    const { data: mission, error } = await supabase
      .from('missions')
      .insert({
        client_wallet: user.wallet_address,
        title: formData.title,
        description: formData.description,
        budget_max_daos: parseFloat(formData.budget_max_daos),
        min_rank: formData.min_rank,
        required_skills: formData.required_skills,
      })
      .select()
      .single();

    if (error) {
      console.error('Mission creation failed:', error);
      return;
    }

    // Step 2: Publish mission on-chain (ServiceMarketplace.createMission)
    const tx = await marketplaceContract.createMission(
      mission.id,
      ethers.parseEther(formData.budget_max_daos),
      formData.min_rank
    );
    await tx.wait();

    // Step 3: Event sync worker will UPDATE mission.on_chain_mission_id automatically

    // Step 4: Publish mission in Supabase (draft → active)
    await supabase
      .from('missions')
      .update({ status: 'active', published_at: new Date().toISOString() })
      .eq('id', mission.id);

    // Step 5: Webhook service will send Discord notification automatically
  };

  return (
    <form onSubmit={handleSubmit}>
      {/* Form fields */}
    </form>
  );
}
```

### Backend - Realtime Subscription

```typescript
import { createClient } from '@supabase/supabase-js';

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// Listen to new applications
supabase
  .channel('applications')
  .on(
    'postgres_changes',
    {
      event: 'INSERT',
      schema: 'public',
      table: 'mission_applications',
    },
    (payload) => {
      const application = payload.new;
      console.log('New application received:', application);

      // Trigger match score calculation
      fetch(`/api/applications/${application.id}/calculate-match-score`, {
        method: 'POST',
      });
    }
  )
  .subscribe();
```

---

## Testing Checklist

### Database Schema
- [x] All 18 tables created successfully
- [x] RLS policies applied to all tables
- [x] Triggers created for auto-updates (updated_at, notifications)
- [x] Foreign key constraints enforced
- [x] Indexes created for performance (wallet_address, mission_id, status)

### REST API
- [ ] TODO: Integration tests for all endpoints (Postman collection)
- [ ] TODO: Zod validation tests (invalid inputs rejected)
- [ ] TODO: RLS enforcement tests (unauthorized access blocked)
- [ ] TODO: Pagination tests (page/limit params)

### Event Sync Worker
- [ ] TODO: Historical sync test (backfill missed events)
- [ ] TODO: Real-time sync test (new events processed immediately)
- [ ] TODO: Idempotency test (duplicate events ignored)
- [ ] TODO: Error handling test (Supabase connection failure)

### Webhook Service
- [ ] TODO: Retry logic test (3 retries with exponential backoff)
- [ ] TODO: Discord webhook test (embed formatting)
- [ ] TODO: Delivery logging test (webhook_logs table updated)

---

## Deployment Guide

### Prerequisites

1. **Polkadot Hub Node** : RPC endpoint with WebSocket support
2. **Supabase Project** : PostgreSQL database with RLS enabled
3. **Discord Webhook** (optional) : Created in Discord channel settings
4. **Node.js Backend** : Express server with TypeScript

### Step 1 - Database Setup

```bash
# Run migrations
cd backend
psql $DATABASE_URL < supabase/migrations/001_schema.sql

# Verify tables
psql $DATABASE_URL -c "\dt"  # Should list 18 tables
```

### Step 2 - Environment Variables

Create `backend/.env` :
```bash
# Blockchain
RPC_URL=wss://polkadot-hub-rpc.example.com
CHAIN_ID=1000
MARKETPLACE_ADDRESS=0x...  # From Sprint 5 deployment
ESCROW_FACTORY_ADDRESS=0x...
PAYMENT_SPLITTER_FACTORY_ADDRESS=0x...

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=eyJ...

# Webhooks (optional)
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/...
FRONTEND_URL=https://dao-marketplace.example.com

# API
PORT=3000
JWT_SECRET=your-secret-key
```

### Step 3 - Start Services

```bash
# Install dependencies
cd backend
npm install

# Build TypeScript
npm run build

# Start API server
npm run start  # Or: pm2 start dist/server.js --name dao-api

# Start event sync worker
npm run event-sync  # Or: pm2 start dist/services/event-sync-worker.js --name dao-event-sync
```

### Step 4 - Verify Integration

```bash
# Test API
curl http://localhost:3000/api/missions

# Check event sync logs
pm2 logs dao-event-sync

# Verify Supabase sync
psql $DATABASE_URL -c "SELECT COUNT(*) FROM chain_events;"
```

---

## Performance Optimizations

### Database Indexes

```sql
-- Missions table
CREATE INDEX idx_missions_client ON missions(client_wallet);
CREATE INDEX idx_missions_status ON missions(status);
CREATE INDEX idx_missions_consultant ON missions(selected_consultant_wallet);

-- Applications table
CREATE INDEX idx_applications_mission ON mission_applications(mission_id);
CREATE INDEX idx_applications_consultant ON mission_applications(consultant_wallet);
CREATE INDEX idx_applications_match_score ON mission_applications(match_score DESC);

-- Usage logs table
CREATE INDEX idx_usage_mission ON usage_logs(mission_id);
CREATE INDEX idx_usage_contributor ON usage_logs(contributor_wallet);
CREATE INDEX idx_usage_logged_at ON usage_logs(logged_at DESC);
```

### Event Sync Worker

**Batching** : Process events in batches of 100 to reduce Supabase API calls

```typescript
async function processBatchedEvents(events: ethers.Log[]) {
  const BATCH_SIZE = 100;

  for (let i = 0; i < events.length; i += BATCH_SIZE) {
    const batch = events.slice(i, i + BATCH_SIZE);
    await Promise.all(batch.map(handleEvent));
  }
}
```

**Connection Pooling** : Supabase client with connection pooling (max 10 concurrent connections)

---

## Sprint 6 Progress

| Task | Status | Duration |
|------|--------|----------|
| Database schema design | ✅ | 4h |
| RLS policies implementation | ✅ | 3h |
| REST API endpoints | ✅ | 6h |
| Event sync worker | ✅ | 4h |
| Webhook service | ✅ | 2h |

**Total** : 19h / 19h (100%)

---

## Cumulative Progress (All Sprints)

| Sprint | Focus | Duration | Status |
|--------|-------|----------|--------|
| Sprint 1 | Documentation (4 guides) | 9h | ✅ |
| Sprint 2 | UI Governance | 12h | ✅ |
| Sprint 3 | Dashboard Consultant | 11h | ✅ |
| Sprint 4 | Milestone Tracker | 14h | ✅ |
| Sprint 5 | Smart Contracts Marketplace | 30h | ✅ |
| Sprint 6 | Data Layer | 19h | ✅ |

**Total** : 95h / 95h (100%)

---

## Next Steps (Post-Sprint 6)

1. **Integration Tests** : Create comprehensive test suite for REST API + event sync worker
2. **Frontend Integration** : Implement React components using Supabase SDK + smart contract interactions
3. **Production Deployment** : Deploy to Vercel (frontend) + Railway (backend) + Supabase (database)
4. **Monitoring** : Set up Grafana dashboards for event sync metrics, webhook delivery rates, API latency
5. **Security Audit** : External audit of smart contracts + backend API (Slither, Certora, OpenZeppelin Defender)

---

**Sprint 6 completed** ✅
**Phase 3 UX implementation plan completed** ✅ (95h/95h = 100%)
