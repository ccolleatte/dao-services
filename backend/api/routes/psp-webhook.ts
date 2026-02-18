// @ts-nocheck
/**
 * PSP Webhook Handler (Incoming)
 * Version: 1.0.0
 * Purpose: Receive and dispatch events from PSP (Mangopay/Stripe Connect)
 * ADR 2026-02-18: PSP est la source de vérité pour l'état des paiements
 *
 * Flow: PSP → POST /webhooks/psp → handler → Supabase update
 *
 * Events handled:
 *   ESCROW_CREATED     — Escrow PSP créé après sélection consultant (→ psp_escrow_id)
 *   MILESTONE_APPROVED — Jalon validé par le PSP, paiement en cours
 *   PAYMENT_RELEASED   — Paiement libéré vers le compte consultant
 *   KYC_VALIDATED      — KYC utilisateur validé par le PSP
 *   DISPUTE_RESOLVED   — Litige résolu par SLA PSP
 */

import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import * as crypto from 'crypto';

const router = Router();

const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// ============================================================================
// SIGNATURE VERIFICATION
// ============================================================================

/**
 * Verify PSP webhook signature via HMAC-SHA256
 * Mangopay: X-Mangopay-Signature header
 * Stripe Connect: Stripe-Signature header (use stripe.webhooks.constructEvent)
 *
 * TODO: Adapter la vérification au PSP retenu (Mangopay vs Stripe)
 */
function verifyPspSignature(rawBody: string, signature: string): boolean {
  const secret = process.env.PSP_WEBHOOK_SECRET;

  if (!secret) {
    // Bloquer en production si le secret n'est pas configuré
    if (process.env.NODE_ENV === 'production') {
      console.error('[PSP Webhook] PSP_WEBHOOK_SECRET non configuré — requête rejetée');
      return false;
    }
    console.warn('[PSP Webhook] PSP_WEBHOOK_SECRET absent — vérification désactivée (dev only)');
    return true;
  }

  const expected = crypto
    .createHmac('sha256', secret)
    .update(rawBody)
    .digest('hex');

  return crypto.timingSafeEqual(
    Buffer.from(signature),
    Buffer.from(expected)
  );
}

// ============================================================================
// EVENT HANDLERS
// ============================================================================

/**
 * ESCROW_CREATED — Le PSP a créé l'escrow suite à la sélection du consultant
 * Remplit le psp_escrow_id sur la mission (null après select-consultant)
 */
async function handleEscrowCreated(event: any): Promise<void> {
  const { mission_id, psp_escrow_id } = event.data;

  if (!mission_id || !psp_escrow_id) {
    throw new Error('ESCROW_CREATED: mission_id et psp_escrow_id requis');
  }

  const { error } = await supabase
    .from('missions')
    .update({ psp_escrow_id })
    .eq('id', mission_id)
    .eq('status', 'consultant_selected'); // Guard: n'applique que sur le bon statut

  if (error) throw new Error(`handleEscrowCreated: ${error.message}`);

  console.log(`[PSP Webhook] Escrow créé: mission=${mission_id} escrow=${psp_escrow_id}`);
}

/**
 * MILESTONE_APPROVED — Le PSP valide un jalon et initie le paiement
 * Associe psp_milestone_id au milestone et passe le statut à 'approved'
 */
async function handleMilestoneApproved(event: any): Promise<void> {
  const { milestone_id, psp_milestone_id, amount_eur } = event.data;

  if (!milestone_id || !psp_milestone_id) {
    throw new Error('MILESTONE_APPROVED: milestone_id et psp_milestone_id requis');
  }

  const { error } = await supabase
    .from('milestones')
    .update({
      psp_milestone_id,
      status: 'approved',
    })
    .eq('id', milestone_id);

  if (error) throw new Error(`handleMilestoneApproved: ${error.message}`);

  console.log(`[PSP Webhook] Jalon approuvé: milestone=${milestone_id} montant=${amount_eur} EUR`);
}

/**
 * PAYMENT_RELEASED — Le PSP a effectivement libéré le paiement
 * Enregistre la transaction dans la table payments et notifie le consultant
 */
async function handlePaymentReleased(event: any): Promise<void> {
  const {
    mission_id,
    milestone_id,
    psp_transaction_id,
    amount_eur,
    currency = 'EUR',
    recipient_wallet,
  } = event.data;

  if (!psp_transaction_id || !recipient_wallet) {
    throw new Error('PAYMENT_RELEASED: psp_transaction_id et recipient_wallet requis');
  }

  // Enregistrer le paiement
  const { error: paymentError } = await supabase
    .from('payments')
    .insert({
      mission_id,
      milestone_id,
      recipient_wallet,
      amount_eur,
      currency,
      psp_transaction_id,
      payment_type: 'milestone_payment',
      status: 'completed',
      paid_at: new Date().toISOString(),
    });

  if (paymentError) throw new Error(`handlePaymentReleased (insert): ${paymentError.message}`);

  // Notifier le consultant (payment_received est dans l'enum notification_type)
  await supabase.from('notifications').insert({
    recipient_wallet,
    notification_type: 'payment_received',
    title: 'Paiement reçu',
    message: `Vous avez reçu ${amount_eur} ${currency}`,
    link_url: `/missions/${mission_id}`,
    metadata: { mission_id, milestone_id, psp_transaction_id, amount_eur },
  });

  console.log(`[PSP Webhook] Paiement libéré: mission=${mission_id} montant=${amount_eur} EUR tx=${psp_transaction_id}`);
}

/**
 * KYC_VALIDATED — Le PSP a validé l'identité d'un utilisateur
 * Met à jour le profil avec le statut KYC et l'identifiant PSP utilisateur
 *
 * TODO: Ajouter les colonnes psp_kyc_validated / psp_kyc_level / psp_user_id
 *       à la table profiles (migration 003_psp_kyc.sql)
 */
async function handleKycValidated(event: any): Promise<void> {
  const { wallet_address, psp_user_id, kyc_level } = event.data;

  if (!wallet_address || !psp_user_id) {
    throw new Error('KYC_VALIDATED: wallet_address et psp_user_id requis');
  }

  // TODO: Déclencher sur migration 003 (colonnes KYC absentes du schéma actuel)
  console.log(`[PSP Webhook] KYC validé (stub): wallet=${wallet_address} level=${kyc_level}`);
  console.log('[PSP Webhook] Action DB en attente de migration 003_psp_kyc.sql');
}

/**
 * DISPUTE_RESOLVED — Le PSP a résolu un litige via sa SLA
 * Met à jour le litige avec l'identifiant PSP et la résolution
 */
async function handleDisputeResolved(event: any): Promise<void> {
  const { dispute_id, psp_dispute_id, resolution } = event.data;

  if (!dispute_id || !psp_dispute_id) {
    throw new Error('DISPUTE_RESOLVED: dispute_id et psp_dispute_id requis');
  }

  const { error } = await supabase
    .from('disputes')
    .update({
      psp_dispute_id,
      resolution_channel: 'PSP_SLA',
      status: 'resolved',
      resolution,
      resolved_at: new Date().toISOString(),
    })
    .eq('id', dispute_id);

  if (error) throw new Error(`handleDisputeResolved: ${error.message}`);

  console.log(`[PSP Webhook] Litige résolu: dispute=${dispute_id} résolution=${resolution}`);
}

// ============================================================================
// ROUTE PRINCIPALE
// ============================================================================

/**
 * POST /webhooks/psp
 * Point d'entrée unique pour tous les événements PSP entrants
 * Le PSP attend un 200 rapide — la logique lourde doit être async (queue)
 *
 * TODO: Passer les événements dans une queue (BullMQ / Supabase Edge Queue)
 *       pour garantir le traitement même en cas de timeout backend
 */
router.post('/', async (req, res) => {
  try {
    // Vérification de signature (en-tête PSP-specific)
    const signature =
      (req.headers['x-mangopay-signature'] as string) ||
      (req.headers['stripe-signature'] as string) ||
      '';

    const rawBody = JSON.stringify(req.body);

    if (!verifyPspSignature(rawBody, signature)) {
      return res.status(401).json({ success: false, error: 'Signature PSP invalide' });
    }

    const event = req.body;
    const { event_type } = event;

    if (!event_type) {
      return res.status(400).json({ success: false, error: 'event_type manquant' });
    }

    console.log(`[PSP Webhook] Événement reçu: ${event_type}`);

    switch (event_type) {
      case 'ESCROW_CREATED':
        await handleEscrowCreated(event);
        break;
      case 'MILESTONE_APPROVED':
        await handleMilestoneApproved(event);
        break;
      case 'PAYMENT_RELEASED':
        await handlePaymentReleased(event);
        break;
      case 'KYC_VALIDATED':
        await handleKycValidated(event);
        break;
      case 'DISPUTE_RESOLVED':
        await handleDisputeResolved(event);
        break;
      default:
        // Accusé de réception sans erreur pour événements non gérés
        console.warn(`[PSP Webhook] Événement non géré: ${event_type}`);
    }

    // Accusé de réception immédiat — le PSP retentera si 5xx
    return res.json({ success: true, event_type });
  } catch (error: any) {
    console.error('[PSP Webhook] Erreur handler:', error);
    // 500 → le PSP retentera l'événement (comportement attendu)
    return res.status(500).json({
      success: false,
      error: error.message || 'Erreur traitement webhook',
    });
  }
});

export default router;
