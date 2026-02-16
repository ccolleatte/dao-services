// @ts-nocheck
/**
 * Mission Applications API Routes
 * Version: 1.0.0
 * Purpose: Consultant application management
 */

import { Router } from 'express';
import { createClient } from '@supabase/supabase-js';
import { z } from 'zod';

const router = Router();

// Initialize Supabase client
const supabase = createClient(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_SERVICE_ROLE_KEY!
);

// ============================================================================
// VALIDATION SCHEMAS
// ============================================================================

const CreateApplicationSchema = z.object({
  mission_id: z.string().uuid(),
  proposal_text: z.string().min(100).max(5000),
  proposal_ipfs_hash: z.string().optional(),
  proposed_budget_daos: z.number().positive(),
  estimated_delivery_days: z.number().int().positive().optional(),
});

const UpdateApplicationSchema = z.object({
  proposal_text: z.string().min(100).max(5000).optional(),
  proposal_ipfs_hash: z.string().optional(),
  proposed_budget_daos: z.number().positive().optional(),
  estimated_delivery_days: z.number().int().positive().optional(),
});

// ============================================================================
// ROUTES
// ============================================================================

/**
 * GET /api/applications
 * List consultant's own applications
 */
router.get('/', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { status } = req.query;

    let query = supabase
      .from('mission_applications')
      .select(`
        *,
        missions(*)
      `)
      .eq('consultant_wallet', wallet)
      .order('submitted_at', { ascending: false });

    if (status) {
      query = query.eq('status', status);
    }

    const { data, error } = await query;

    if (error) throw error;

    return res.json({
      success: true,
      data: data || [],
    });
  } catch (error: any) {
    console.error('[Applications API] List error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to list applications',
    });
  }
});

/**
 * GET /api/applications/:id
 * Get application details
 */
router.get('/:id', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { id } = req.params;

    const { data, error } = await supabase
      .from('mission_applications')
      .select(`
        *,
        missions(*)
      `)
      .eq('id', id)
      .single();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Application not found',
      });
    }

    // Verify access (own consultant or mission client)
    if (
      data.consultant_wallet !== wallet &&
      data.missions?.client_wallet !== wallet
    ) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not authorized to view this application',
      });
    }

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Applications API] Get error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to get application',
    });
  }
});

/**
 * POST /api/applications
 * Create new application (consultant only)
 */
router.post('/', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const body = CreateApplicationSchema.parse(req.body);

    // Verify mission exists and is active
    const { data: mission } = await supabase
      .from('missions')
      .select('status, budget_max_daos, min_rank, client_wallet')
      .eq('id', body.mission_id)
      .single();

    if (!mission) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    if (mission.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: 'Mission is not active',
      });
    }

    if (mission.client_wallet === wallet) {
      return res.status(400).json({
        success: false,
        error: 'Cannot apply to own mission',
      });
    }

    if (body.proposed_budget_daos > mission.budget_max_daos) {
      return res.status(400).json({
        success: false,
        error: 'Proposed budget exceeds mission max budget',
      });
    }

    // Verify consultant rank (TODO: Call membership contract)
    const { data: profile } = await supabase
      .from('profiles')
      .select('on_chain_rank')
      .eq('wallet_address', wallet)
      .single();

    if (!profile || profile.on_chain_rank < mission.min_rank) {
      return res.status(403).json({
        success: false,
        error: `Insufficient rank (required: ${mission.min_rank})`,
      });
    }

    // Check if already applied
    const { data: existing } = await supabase
      .from('mission_applications')
      .select('id')
      .eq('mission_id', body.mission_id)
      .eq('consultant_wallet', wallet)
      .single();

    if (existing) {
      return res.status(400).json({
        success: false,
        error: 'Already applied to this mission',
      });
    }

    // Create application
    const { data, error } = await supabase
      .from('mission_applications')
      .insert({
        consultant_wallet: wallet,
        ...body,
      })
      .select()
      .single();

    if (error) throw error;

    // Create notification for client
    await supabase.from('notifications').insert({
      recipient_wallet: mission.client_wallet,
      notification_type: 'application_received',
      title: 'New Application Received',
      message: 'A consultant has applied to your mission',
      link_url: `/missions/${body.mission_id}/applications`,
      metadata: {
        mission_id: body.mission_id,
        consultant_wallet: wallet,
      },
    });

    return res.status(201).json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Applications API] Create error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to create application',
    });
  }
});

/**
 * PATCH /api/applications/:id
 * Update application (consultant only, before reviewed)
 */
router.patch('/:id', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { id } = req.params;
    const body = UpdateApplicationSchema.parse(req.body);

    // Verify ownership and status
    const { data: application } = await supabase
      .from('mission_applications')
      .select('consultant_wallet, status')
      .eq('id', id)
      .single();

    if (!application) {
      return res.status(404).json({
        success: false,
        error: 'Application not found',
      });
    }

    if (application.consultant_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not application owner',
      });
    }

    if (application.status !== 'pending') {
      return res.status(400).json({
        success: false,
        error: 'Cannot update application after review',
      });
    }

    const { data, error } = await supabase
      .from('mission_applications')
      .update(body)
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Applications API] Update error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to update application',
    });
  }
});

/**
 * DELETE /api/applications/:id
 * Withdraw application (consultant only)
 */
router.delete('/:id', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { id } = req.params;

    // Verify ownership and status
    const { data: application } = await supabase
      .from('mission_applications')
      .select('consultant_wallet, status, mission_id')
      .eq('id', id)
      .single();

    if (!application) {
      return res.status(404).json({
        success: false,
        error: 'Application not found',
      });
    }

    if (application.consultant_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not application owner',
      });
    }

    if (application.status === 'selected') {
      return res.status(400).json({
        success: false,
        error: 'Cannot withdraw selected application',
      });
    }

    const { error } = await supabase
      .from('mission_applications')
      .delete()
      .eq('id', id);

    if (error) throw error;

    return res.json({
      success: true,
      message: 'Application withdrawn successfully',
    });
  } catch (error: any) {
    console.error('[Applications API] Delete error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to withdraw application',
    });
  }
});

/**
 * POST /api/applications/:id/calculate-match-score
 * Calculate on-chain match score (admin/cron only)
 * TODO: Call smart contract calculateMatchScore function
 */
router.post('/:id/calculate-match-score', async (req, res) => {
  try {
    const { id } = req.params;

    const { data: application } = await supabase
      .from('mission_applications')
      .select('mission_id, consultant_wallet, proposed_budget_daos')
      .eq('id', id)
      .single();

    if (!application) {
      return res.status(404).json({
        success: false,
        error: 'Application not found',
      });
    }

    // TODO: Call smart contract ServiceMarketplace.calculateMatchScore()
    // For now, use mock score
    const mockScore = Math.floor(Math.random() * 40) + 60; // 60-100

    const { data, error } = await supabase
      .from('mission_applications')
      .update({ match_score: mockScore })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // Cache in match_scores table for analytics
    await supabase.from('match_scores').upsert({
      mission_id: application.mission_id,
      consultant_wallet: application.consultant_wallet,
      total_score: mockScore,
      // TODO: Add breakdown scores from smart contract
    });

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Applications API] Calculate match score error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to calculate match score',
    });
  }
});

export default router;
