/**
 * Webhook Service
 * Version: 1.0.0
 * Purpose: Send notifications to external services (Discord, Slack, webhooks)
 */

import axios from 'axios';
import { createClient } from '@supabase/supabase-js';

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// ============================================================================
// WEBHOOK TYPES
// ============================================================================

interface WebhookPayload {
  event_type: string;
  timestamp: string;
  data: Record<string, any>;
}

interface DiscordWebhook {
  username?: string;
  avatar_url?: string;
  content?: string;
  embeds?: Array<{
    title?: string;
    description?: string;
    color?: number;
    fields?: Array<{
      name: string;
      value: string;
      inline?: boolean;
    }>;
    timestamp?: string;
  }>;
}

// ============================================================================
// WEBHOOK DELIVERY
// ============================================================================

/**
 * Send webhook to external URL
 * With retry logic and logging
 */
async function sendWebhook(
  url: string,
  payload: WebhookPayload,
  retries: number = 3
): Promise<void> {
  let lastError: Error | null = null;
  let attempt = 0;

  while (attempt < retries) {
    try {
      attempt++;

      const response = await axios.post(url, payload, {
        headers: {
          'Content-Type': 'application/json',
          'User-Agent': 'DAO-Marketplace-Webhook/1.0',
        },
        timeout: 10000, // 10 seconds
      });

      // Log successful delivery
      await supabase.from('webhook_logs').insert({
        webhook_url: url,
        event_type: payload.event_type,
        payload: payload as any,
        response_status: response.status,
        response_body: JSON.stringify(response.data),
        delivered_at: new Date().toISOString(),
        retry_count: attempt - 1,
      });

      console.log(`[Webhook] Delivered to ${url} (attempt ${attempt}/${retries})`);
      return;
    } catch (error: any) {
      lastError = error;
      console.error(`[Webhook] Delivery failed to ${url} (attempt ${attempt}/${retries}):`, error.message);

      if (attempt >= retries) {
        // Log failed delivery
        await supabase.from('webhook_logs').insert({
          webhook_url: url,
          event_type: payload.event_type,
          payload: payload as any,
          response_status: error.response?.status || null,
          response_body: error.message,
          failed_at: new Date().toISOString(),
          retry_count: attempt - 1,
        });

        throw lastError;
      }

      // Exponential backoff
      await new Promise((resolve) => setTimeout(resolve, Math.pow(2, attempt) * 1000));
    }
  }
}

/**
 * Send Discord webhook
 * Format payload for Discord API
 */
async function sendDiscordWebhook(url: string, embed: DiscordWebhook): Promise<void> {
  try {
    await axios.post(url, embed, {
      headers: {
        'Content-Type': 'application/json',
      },
      timeout: 10000,
    });

    console.log('[Webhook] Discord webhook sent successfully');
  } catch (error) {
    console.error('[Webhook] Discord webhook error:', error);
    throw error;
  }
}

// ============================================================================
// EVENT-SPECIFIC WEBHOOKS
// ============================================================================

/**
 * Mission published webhook
 */
export async function sendMissionPublishedWebhook(mission: {
  id: string;
  title: string;
  budget_max_daos: string;
  client_wallet: string;
}): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_MISSION_PUBLISHED;
  if (!webhookUrl) return;

  const payload: WebhookPayload = {
    event_type: 'mission.published',
    timestamp: new Date().toISOString(),
    data: {
      mission_id: mission.id,
      title: mission.title,
      budget_max_daos: mission.budget_max_daos,
      client_wallet: mission.client_wallet,
      link: `${process.env.FRONTEND_URL}/missions/${mission.id}`,
    },
  };

  await sendWebhook(webhookUrl, payload);

  // Discord notification
  const discordUrl = process.env.DISCORD_WEBHOOK_URL;
  if (discordUrl) {
    await sendDiscordWebhook(discordUrl, {
      username: 'DAO Marketplace',
      embeds: [
        {
          title: '📢 New Mission Published',
          description: mission.title,
          color: 0x5865f2, // Blurple
          fields: [
            {
              name: 'Budget',
              value: `${mission.budget_max_daos} DAOS`,
              inline: true,
            },
            {
              name: 'Client',
              value: `${mission.client_wallet.slice(0, 6)}...${mission.client_wallet.slice(-4)}`,
              inline: true,
            },
          ],
          timestamp: new Date().toISOString(),
        },
      ],
    });
  }
}

/**
 * Consultant selected webhook
 */
export async function sendConsultantSelectedWebhook(data: {
  mission_id: string;
  consultant_wallet: string;
  match_score: number;
}): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_CONSULTANT_SELECTED;
  if (!webhookUrl) return;

  const payload: WebhookPayload = {
    event_type: 'consultant.selected',
    timestamp: new Date().toISOString(),
    data: {
      mission_id: data.mission_id,
      consultant_wallet: data.consultant_wallet,
      match_score: data.match_score,
      link: `${process.env.FRONTEND_URL}/missions/${data.mission_id}`,
    },
  };

  await sendWebhook(webhookUrl, payload);

  // Discord notification
  const discordUrl = process.env.DISCORD_WEBHOOK_URL;
  if (discordUrl) {
    await sendDiscordWebhook(discordUrl, {
      username: 'DAO Marketplace',
      embeds: [
        {
          title: '🤝 Consultant Selected',
          description: `Consultant selected with match score ${data.match_score}/100`,
          color: 0x57f287, // Green
          fields: [
            {
              name: 'Consultant',
              value: `${data.consultant_wallet.slice(0, 6)}...${data.consultant_wallet.slice(-4)}`,
              inline: true,
            },
            {
              name: 'Match Score',
              value: `${data.match_score}/100`,
              inline: true,
            },
          ],
          timestamp: new Date().toISOString(),
        },
      ],
    });
  }
}

/**
 * Milestone approved webhook
 */
export async function sendMilestoneApprovedWebhook(data: {
  mission_id: string;
  milestone_id: string;
  amount_daos: string;
  consultant_wallet: string;
}): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_MILESTONE_APPROVED;
  if (!webhookUrl) return;

  const payload: WebhookPayload = {
    event_type: 'milestone.approved',
    timestamp: new Date().toISOString(),
    data: {
      mission_id: data.mission_id,
      milestone_id: data.milestone_id,
      amount_daos: data.amount_daos,
      consultant_wallet: data.consultant_wallet,
      link: `${process.env.FRONTEND_URL}/missions/${data.mission_id}`,
    },
  };

  await sendWebhook(webhookUrl, payload);

  // Discord notification
  const discordUrl = process.env.DISCORD_WEBHOOK_URL;
  if (discordUrl) {
    await sendDiscordWebhook(discordUrl, {
      username: 'DAO Marketplace',
      embeds: [
        {
          title: '✅ Milestone Approved',
          description: `Payment of ${data.amount_daos} DAOS released`,
          color: 0x57f287, // Green
          fields: [
            {
              name: 'Amount',
              value: `${data.amount_daos} DAOS`,
              inline: true,
            },
            {
              name: 'Recipient',
              value: `${data.consultant_wallet.slice(0, 6)}...${data.consultant_wallet.slice(-4)}`,
              inline: true,
            },
          ],
          timestamp: new Date().toISOString(),
        },
      ],
    });
  }
}

/**
 * Dispute raised webhook
 */
export async function sendDisputeRaisedWebhook(data: {
  mission_id: string;
  milestone_id: string;
  dispute_id: string;
  initiator_wallet: string;
  reason: string;
}): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_DISPUTE_RAISED;
  if (!webhookUrl) return;

  const payload: WebhookPayload = {
    event_type: 'dispute.raised',
    timestamp: new Date().toISOString(),
    data: {
      mission_id: data.mission_id,
      milestone_id: data.milestone_id,
      dispute_id: data.dispute_id,
      initiator_wallet: data.initiator_wallet,
      reason: data.reason,
      link: `${process.env.FRONTEND_URL}/disputes/${data.dispute_id}`,
    },
  };

  await sendWebhook(webhookUrl, payload);

  // Discord notification (high priority)
  const discordUrl = process.env.DISCORD_WEBHOOK_URL;
  if (discordUrl) {
    await sendDiscordWebhook(discordUrl, {
      username: 'DAO Marketplace',
      embeds: [
        {
          title: '⚠️ Dispute Raised',
          description: data.reason,
          color: 0xed4245, // Red
          fields: [
            {
              name: 'Initiator',
              value: `${data.initiator_wallet.slice(0, 6)}...${data.initiator_wallet.slice(-4)}`,
              inline: true,
            },
            {
              name: 'Mission',
              value: data.mission_id.slice(0, 8),
              inline: true,
            },
          ],
          timestamp: new Date().toISOString(),
        },
      ],
    });
  }
}

/**
 * Dispute resolved webhook
 */
export async function sendDisputeResolvedWebhook(data: {
  dispute_id: string;
  winner_wallet: string;
  votes_for: number;
  votes_against: number;
}): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_DISPUTE_RESOLVED;
  if (!webhookUrl) return;

  const payload: WebhookPayload = {
    event_type: 'dispute.resolved',
    timestamp: new Date().toISOString(),
    data: {
      dispute_id: data.dispute_id,
      winner_wallet: data.winner_wallet,
      votes_for: data.votes_for,
      votes_against: data.votes_against,
      link: `${process.env.FRONTEND_URL}/disputes/${data.dispute_id}`,
    },
  };

  await sendWebhook(webhookUrl, payload);

  // Discord notification
  const discordUrl = process.env.DISCORD_WEBHOOK_URL;
  if (discordUrl) {
    await sendDiscordWebhook(discordUrl, {
      username: 'DAO Marketplace',
      embeds: [
        {
          title: '⚖️ Dispute Resolved',
          description: `Jury voted ${data.votes_for} for consultant, ${data.votes_against} for client`,
          color: 0xfee75c, // Yellow
          fields: [
            {
              name: 'Winner',
              value: `${data.winner_wallet.slice(0, 6)}...${data.winner_wallet.slice(-4)}`,
              inline: true,
            },
            {
              name: 'Vote Result',
              value: `${data.votes_for}-${data.votes_against}`,
              inline: true,
            },
          ],
          timestamp: new Date().toISOString(),
        },
      ],
    });
  }
}

/**
 * Payment distributed webhook (hybrid contributors)
 */
export async function sendPaymentDistributedWebhook(data: {
  mission_id: string;
  recipients: Array<{
    wallet: string;
    amount_daos: string;
    contributor_type: string;
  }>;
  total_amount_daos: string;
}): Promise<void> {
  const webhookUrl = process.env.WEBHOOK_PAYMENT_DISTRIBUTED;
  if (!webhookUrl) return;

  const payload: WebhookPayload = {
    event_type: 'payment.distributed',
    timestamp: new Date().toISOString(),
    data: {
      mission_id: data.mission_id,
      recipients: data.recipients,
      total_amount_daos: data.total_amount_daos,
      link: `${process.env.FRONTEND_URL}/missions/${data.mission_id}`,
    },
  };

  await sendWebhook(webhookUrl, payload);

  // Discord notification
  const discordUrl = process.env.DISCORD_WEBHOOK_URL;
  if (discordUrl) {
    const fields = data.recipients.map((r) => ({
      name: `${r.contributor_type.toUpperCase()}`,
      value: `${r.amount_daos} DAOS`,
      inline: true,
    }));

    await sendDiscordWebhook(discordUrl, {
      username: 'DAO Marketplace',
      embeds: [
        {
          title: '💰 Payment Distributed',
          description: `Total: ${data.total_amount_daos} DAOS`,
          color: 0x57f287, // Green
          fields,
          timestamp: new Date().toISOString(),
        },
      ],
    });
  }
}

// ============================================================================
// WEBHOOK TRIGGER FROM DATABASE (Supabase Function)
// ============================================================================

/**
 * Listen to database changes and trigger webhooks
 * This should be run as a separate worker or via Supabase Edge Functions
 */
export async function startWebhookListener() {
  console.log('[Webhooks] Starting webhook listener...');

  // Listen to notifications table insertions
  const channel = supabase
    .channel('notifications')
    .on(
      'postgres_changes',
      {
        event: 'INSERT',
        schema: 'public',
        table: 'notifications',
      },
      async (payload) => {
        const notification = payload.new as any;

        // Trigger appropriate webhook based on notification_type
        switch (notification.notification_type) {
          case 'mission_published':
            // Fetch mission details
            const { data: mission } = await supabase
              .from('missions')
              .select('*')
              .eq('id', notification.metadata.mission_id)
              .single();
            if (mission) {
              await sendMissionPublishedWebhook(mission);
            }
            break;

          case 'consultant_selected':
            await sendConsultantSelectedWebhook(notification.metadata);
            break;

          case 'milestone_approved':
            await sendMilestoneApprovedWebhook(notification.metadata);
            break;

          // Add other cases as needed
        }
      }
    )
    .subscribe();

  console.log('[Webhooks] Webhook listener started');
}
