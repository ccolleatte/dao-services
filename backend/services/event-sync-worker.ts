/**
 * Blockchain Event Sync Worker
 * Version: 1.0.0
 * Purpose: Listen to smart contract events and sync to Supabase in real-time
 */

import { ethers } from 'ethers';
import { createClient } from '@supabase/supabase-js';

// ============================================================================
// CONFIGURATION
// ============================================================================

const PASEO_RPC_URL = process.env.PASEO_RPC_URL || 'https://paseo.rpc.amforc.com';
const SUPABASE_URL = process.env.SUPABASE_URL!;
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY!;

const SERVICE_MARKETPLACE_ADDRESS = process.env.SERVICE_MARKETPLACE_ADDRESS!;
const MISSION_ESCROW_FACTORY_ADDRESS = process.env.MISSION_ESCROW_FACTORY_ADDRESS!;
const HYBRID_PAYMENT_SPLITTER_FACTORY_ADDRESS = process.env.HYBRID_PAYMENT_SPLITTER_FACTORY_ADDRESS!;

// Initialize clients
const provider = new ethers.JsonRpcProvider(PASEO_RPC_URL);
const supabase = createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY);

// ============================================================================
// CONTRACT ABIs (Event signatures only)
// ============================================================================

const SERVICE_MARKETPLACE_ABI = [
  'event MissionCreated(uint256 indexed missionId, address indexed client, uint256 budget)',
  'event ApplicationSubmitted(uint256 indexed applicationId, uint256 indexed missionId, address indexed consultant)',
  'event ConsultantSelected(uint256 indexed missionId, address indexed consultant, uint256 matchScore)',
  'event MissionStatusUpdated(uint256 indexed missionId, uint8 newStatus)',
];

const MISSION_ESCROW_ABI = [
  'event MilestoneAdded(uint256 indexed milestoneId, string description, uint256 amount, uint256 deadline)',
  'event MilestoneSubmitted(uint256 indexed milestoneId, string deliverable)',
  'event MilestoneApproved(uint256 indexed milestoneId, uint256 amountReleased)',
  'event MilestoneRejected(uint256 indexed milestoneId, string reason)',
  'event DisputeRaised(uint256 indexed disputeId, uint256 indexed milestoneId, address initiator)',
  'event DisputeVoteCast(uint256 indexed disputeId, address indexed juror, bool favorConsultant)',
  'event DisputeResolved(uint256 indexed disputeId, address winner, uint256 amountAwarded)',
];

const HYBRID_PAYMENT_SPLITTER_ABI = [
  'event ContributorAdded(address indexed account, uint8 contributorType, uint256 percentageBps)',
  'event UsageReported(uint256 llmTokens, uint256 gpuHours)',
  'event PaymentDistributed(address indexed recipient, uint256 amount, uint8 contributorType)',
  'event PricingUpdated(uint256 pricePerMTokenLLM, uint256 pricePerGPUHour)',
];

// ============================================================================
// CONTRACT INSTANCES
// ============================================================================

const marketplaceContract = new ethers.Contract(
  SERVICE_MARKETPLACE_ADDRESS,
  SERVICE_MARKETPLACE_ABI,
  provider
);

// Note: Escrow and PaymentSplitter contracts are created dynamically per mission
// We'll listen to factory events to track new instances

// ============================================================================
// EVENT HANDLERS
// ============================================================================

/**
 * Handle MissionCreated event
 * Sync on-chain mission ID to Supabase
 */
async function handleMissionCreated(
  missionId: bigint,
  client: string,
  budget: bigint,
  event: ethers.Log
) {
  try {
    console.log(`[EventSync] MissionCreated: missionId=${missionId}, client=${client}`);

    // Find mission in Supabase by client + budget (match off-chain creation)
    const { data: mission } = await supabase
      .from('missions')
      .select('id')
      .eq('client_wallet', client.toLowerCase())
      .eq('budget_max_daos', ethers.formatEther(budget))
      .is('on_chain_mission_id', null)
      .order('created_at', { ascending: false })
      .limit(1)
      .single();

    if (mission) {
      await supabase
        .from('missions')
        .update({
          on_chain_mission_id: missionId.toString(),
          budget_locked_daos: ethers.formatEther(budget),
        })
        .eq('id', mission.id);

      console.log(`[EventSync] Mission synced: ${mission.id} -> on-chain ID ${missionId}`);
    } else {
      console.warn(`[EventSync] No matching mission found for on-chain ID ${missionId}`);
    }

    // Log transaction
    await logTransaction({
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      transaction_type: 'mission_created',
      contract_address: SERVICE_MARKETPLACE_ADDRESS,
      event_name: 'MissionCreated',
      event_data: {
        missionId: missionId.toString(),
        client,
        budget: ethers.formatEther(budget),
      },
      mission_id: mission?.id,
    });
  } catch (error) {
    console.error('[EventSync] MissionCreated error:', error);
  }
}

/**
 * Handle ApplicationSubmitted event
 * Update application with on-chain data
 */
async function handleApplicationSubmitted(
  applicationId: bigint,
  missionId: bigint,
  consultant: string,
  event: ethers.Log
) {
  try {
    console.log(`[EventSync] ApplicationSubmitted: appId=${applicationId}, missionId=${missionId}`);

    // Find mission in Supabase
    const { data: mission } = await supabase
      .from('missions')
      .select('id')
      .eq('on_chain_mission_id', missionId.toString())
      .single();

    if (mission) {
      // Find application
      const { data: application } = await supabase
        .from('mission_applications')
        .select('id')
        .eq('mission_id', mission.id)
        .eq('consultant_wallet', consultant.toLowerCase())
        .single();

      if (application) {
        console.log(`[EventSync] Application synced: ${application.id}`);
      }

      // Log transaction
      await logTransaction({
        transaction_hash: event.transactionHash,
        block_number: event.blockNumber,
        transaction_type: 'application_submitted',
        contract_address: SERVICE_MARKETPLACE_ADDRESS,
        event_name: 'ApplicationSubmitted',
        event_data: {
          applicationId: applicationId.toString(),
          missionId: missionId.toString(),
          consultant,
        },
        mission_id: mission.id,
      });
    }
  } catch (error) {
    console.error('[EventSync] ApplicationSubmitted error:', error);
  }
}

/**
 * Handle ConsultantSelected event
 * Update mission status to on_hold
 */
async function handleConsultantSelected(
  missionId: bigint,
  consultant: string,
  matchScore: bigint,
  event: ethers.Log
) {
  try {
    console.log(`[EventSync] ConsultantSelected: missionId=${missionId}, consultant=${consultant}`);

    const { data: mission } = await supabase
      .from('missions')
      .select('id')
      .eq('on_chain_mission_id', missionId.toString())
      .single();

    if (mission) {
      await supabase
        .from('missions')
        .update({
          selected_consultant_wallet: consultant.toLowerCase(),
          status: 'on_hold',
        })
        .eq('id', mission.id);

      // Update application status
      await supabase
        .from('mission_applications')
        .update({ status: 'selected' })
        .eq('mission_id', mission.id)
        .eq('consultant_wallet', consultant.toLowerCase());

      // Create notification
      await supabase.from('notifications').insert({
        recipient_wallet: consultant.toLowerCase(),
        notification_type: 'consultant_selected',
        title: 'You were selected!',
        message: 'A client has selected you for their mission',
        link_url: `/missions/${mission.id}`,
        metadata: { mission_id: mission.id, match_score: matchScore.toString() },
      });

      console.log(`[EventSync] Consultant selected: ${consultant} for mission ${mission.id}`);
    }

    // Log transaction
    await logTransaction({
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      transaction_type: 'consultant_selected',
      contract_address: SERVICE_MARKETPLACE_ADDRESS,
      event_name: 'ConsultantSelected',
      event_data: {
        missionId: missionId.toString(),
        consultant,
        matchScore: matchScore.toString(),
      },
      mission_id: mission?.id,
    });
  } catch (error) {
    console.error('[EventSync] ConsultantSelected error:', error);
  }
}

/**
 * Handle MilestoneApproved event
 * Update milestone status and create payment record
 */
async function handleMilestoneApproved(
  milestoneId: bigint,
  amountReleased: bigint,
  event: ethers.Log,
  escrowAddress: string
) {
  try {
    console.log(`[EventSync] MilestoneApproved: milestoneId=${milestoneId}, amount=${ethers.formatEther(amountReleased)}`);

    // Find milestone in Supabase
    const { data: milestone } = await supabase
      .from('milestones')
      .select('id, mission_id, missions!inner(selected_consultant_wallet)')
      .eq('on_chain_milestone_id', milestoneId.toString())
      .single();

    if (milestone) {
      // Update milestone status
      await supabase
        .from('milestones')
        .update({
          status: 'approved',
          approved_at: new Date().toISOString(),
        })
        .eq('id', milestone.id);

      // Create payment record
      await supabase.from('payments').insert({
        mission_id: milestone.mission_id,
        recipient_wallet: milestone.missions.selected_consultant_wallet,
        amount_daos: ethers.formatEther(amountReleased),
        contributor_type: 'human', // Default (can be updated if hybrid contributors)
        milestone_id: milestone.id,
        transaction_hash: event.transactionHash,
      });

      // Create notification
      await supabase.from('notifications').insert({
        recipient_wallet: milestone.missions.selected_consultant_wallet,
        notification_type: 'milestone_approved',
        title: 'Milestone Approved',
        message: `Payment of ${ethers.formatEther(amountReleased)} DAOS released`,
        link_url: `/missions/${milestone.mission_id}`,
        metadata: { milestone_id: milestone.id },
      });

      console.log(`[EventSync] Milestone approved: ${milestone.id}`);
    }

    // Log transaction
    await logTransaction({
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      transaction_type: 'milestone_approved',
      contract_address: escrowAddress,
      event_name: 'MilestoneApproved',
      event_data: {
        milestoneId: milestoneId.toString(),
        amountReleased: ethers.formatEther(amountReleased),
      },
      milestone_id: milestone?.id,
    });
  } catch (error) {
    console.error('[EventSync] MilestoneApproved error:', error);
  }
}

/**
 * Handle DisputeRaised event
 * Create dispute record
 */
async function handleDisputeRaised(
  disputeId: bigint,
  milestoneId: bigint,
  initiator: string,
  event: ethers.Log,
  escrowAddress: string
) {
  try {
    console.log(`[EventSync] DisputeRaised: disputeId=${disputeId}, milestoneId=${milestoneId}`);

    // Find milestone
    const { data: milestone } = await supabase
      .from('milestones')
      .select('id, mission_id')
      .eq('on_chain_milestone_id', milestoneId.toString())
      .single();

    if (milestone) {
      // Create dispute record
      await supabase.from('disputes').insert({
        on_chain_dispute_id: disputeId.toString(),
        milestone_id: milestone.id,
        mission_id: milestone.mission_id,
        initiator_wallet: initiator.toLowerCase(),
        reason: 'Dispute raised on-chain', // TODO: Fetch from contract
        status: 'voting',
        voting_deadline: new Date(Date.now() + 72 * 60 * 60 * 1000).toISOString(), // 72h
      });

      console.log(`[EventSync] Dispute created for milestone ${milestone.id}`);
    }

    // Log transaction
    await logTransaction({
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      transaction_type: 'dispute_raised',
      contract_address: escrowAddress,
      event_name: 'DisputeRaised',
      event_data: {
        disputeId: disputeId.toString(),
        milestoneId: milestoneId.toString(),
        initiator,
      },
      milestone_id: milestone?.id,
    });
  } catch (error) {
    console.error('[EventSync] DisputeRaised error:', error);
  }
}

/**
 * Handle PaymentDistributed event (HybridPaymentSplitter)
 * Create payment records for contributors
 */
async function handlePaymentDistributed(
  recipient: string,
  amount: bigint,
  contributorType: number,
  event: ethers.Log,
  splitterAddress: string
) {
  try {
    console.log(`[EventSync] PaymentDistributed: recipient=${recipient}, amount=${ethers.formatEther(amount)}`);

    const contributorTypeMap = ['human', 'ai', 'compute'];

    // TODO: Find mission associated with this splitter contract
    // For now, we'll skip mission_id (can be NULL)

    await supabase.from('payments').insert({
      mission_id: null, // TODO: Resolve from splitter contract
      recipient_wallet: recipient.toLowerCase(),
      amount_daos: ethers.formatEther(amount),
      contributor_type: contributorTypeMap[contributorType] || 'human',
      transaction_hash: event.transactionHash,
    });

    // Log transaction
    await logTransaction({
      transaction_hash: event.transactionHash,
      block_number: event.blockNumber,
      transaction_type: 'payment_distributed',
      contract_address: splitterAddress,
      event_name: 'PaymentDistributed',
      event_data: {
        recipient,
        amount: ethers.formatEther(amount),
        contributorType,
      },
    });
  } catch (error) {
    console.error('[EventSync] PaymentDistributed error:', error);
  }
}

/**
 * Log transaction to Supabase
 */
async function logTransaction(data: {
  transaction_hash: string;
  block_number: number;
  transaction_type: string;
  contract_address: string;
  event_name: string;
  event_data: Record<string, any>;
  mission_id?: string;
  milestone_id?: string;
  dispute_id?: string;
}) {
  try {
    await supabase.from('transactions').insert({
      ...data,
      event_data: data.event_data as any,
    });
  } catch (error) {
    console.error('[EventSync] Log transaction error:', error);
  }
}

// ============================================================================
// EVENT LISTENERS
// ============================================================================

/**
 * Start event sync worker
 */
export async function startEventSyncWorker() {
  console.log('[EventSync] Starting worker...');

  // Get last synced block from Supabase
  const { data: lastTx } = await supabase
    .from('transactions')
    .select('block_number')
    .order('block_number', { ascending: false })
    .limit(1)
    .single();

  const fromBlock = lastTx?.block_number ? lastTx.block_number + 1 : 'latest';

  console.log(`[EventSync] Listening from block ${fromBlock}`);

  // ServiceMarketplace events
  marketplaceContract.on(
    marketplaceContract.filters.MissionCreated(),
    (missionId, client, budget, event) => {
      handleMissionCreated(missionId, client, budget, event);
    }
  );

  marketplaceContract.on(
    marketplaceContract.filters.ApplicationSubmitted(),
    (applicationId, missionId, consultant, event) => {
      handleApplicationSubmitted(applicationId, missionId, consultant, event);
    }
  );

  marketplaceContract.on(
    marketplaceContract.filters.ConsultantSelected(),
    (missionId, consultant, matchScore, event) => {
      handleConsultantSelected(missionId, consultant, matchScore, event);
    }
  );

  // TODO: Listen to MissionEscrow and HybridPaymentSplitter events
  // Requires tracking contract addresses dynamically (via factory events)

  console.log('[EventSync] Worker started successfully');
}

/**
 * Stop event sync worker
 */
export async function stopEventSyncWorker() {
  console.log('[EventSync] Stopping worker...');
  marketplaceContract.removeAllListeners();
  console.log('[EventSync] Worker stopped');
}

// ============================================================================
// HISTORICAL SYNC (One-time catchup)
// ============================================================================

/**
 * Sync historical events from blockchain
 * Run this once to backfill missed events
 */
export async function syncHistoricalEvents(fromBlock: number, toBlock: number | 'latest' = 'latest') {
  console.log(`[EventSync] Syncing historical events from block ${fromBlock} to ${toBlock}...`);

  const eventNames = [
    'MissionCreated',
    'ApplicationSubmitted',
    'ConsultantSelected',
    'MissionStatusUpdated',
  ];

  for (const eventName of eventNames) {
    const filter = marketplaceContract.filters[eventName]();
    const events = await marketplaceContract.queryFilter(filter, fromBlock, toBlock);

    console.log(`[EventSync] Found ${events.length} ${eventName} events`);

    for (const event of events) {
      // Process event based on type
      if (eventName === 'MissionCreated') {
        const [missionId, client, budget] = event.args!;
        await handleMissionCreated(missionId, client, budget, event as any);
      } else if (eventName === 'ApplicationSubmitted') {
        const [applicationId, missionId, consultant] = event.args!;
        await handleApplicationSubmitted(applicationId, missionId, consultant, event as any);
      } else if (eventName === 'ConsultantSelected') {
        const [missionId, consultant, matchScore] = event.args!;
        await handleConsultantSelected(missionId, consultant, matchScore, event as any);
      }
    }
  }

  console.log('[EventSync] Historical sync complete');
}

// ============================================================================
// MAIN
// ============================================================================

if (require.main === module) {
  startEventSyncWorker().catch((error) => {
    console.error('[EventSync] Fatal error:', error);
    process.exit(1);
  });

  // Graceful shutdown
  process.on('SIGINT', async () => {
    await stopEventSyncWorker();
    process.exit(0);
  });

  process.on('SIGTERM', async () => {
    await stopEventSyncWorker();
    process.exit(0);
  });
}
