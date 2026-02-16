// @ts-nocheck
/**
 * Missions API Routes
 * Version: 1.0.0
 * Purpose: CRUD endpoints for marketplace missions
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

const CreateMissionSchema = z.object({
  title: z.string().min(5).max(200),
  description: z.string().min(50).max(5000),
  budget_max_daos: z.number().positive(),
  min_rank: z.number().int().min(0).max(4).default(0),
  required_skills: z.array(z.string()).default([]),
  estimated_duration_days: z.number().int().positive().optional(),
  visibility: z.enum(['public', 'private', 'invite_only']).default('public'),
});

const UpdateMissionSchema = z.object({
  title: z.string().min(5).max(200).optional(),
  description: z.string().min(50).max(5000).optional(),
  required_skills: z.array(z.string()).optional(),
  estimated_duration_days: z.number().int().positive().optional(),
  visibility: z.enum(['public', 'private', 'invite_only']).optional(),
});

const QueryMissionsSchema = z.object({
  status: z.enum(['draft', 'active', 'on_hold', 'disputed', 'completed', 'cancelled']).optional(),
  skills: z.array(z.string()).optional(),
  min_budget: z.number().positive().optional(),
  max_budget: z.number().positive().optional(),
  min_rank: z.number().int().min(0).max(4).optional(),
  page: z.number().int().positive().default(1),
  limit: z.number().int().positive().max(100).default(20),
});

// ============================================================================
// ROUTES
// ============================================================================

/**
 * GET /api/missions
 * List missions with filters and pagination
 */
router.get('/', async (req, res) => {
  try {
    const query = QueryMissionsSchema.parse(req.query);
    const wallet = req.user?.wallet_address; // From auth middleware

    let supabaseQuery = supabase
      .from('missions')
      .select('*, profiles!client_wallet(*), mission_applications(count)', { count: 'exact' });

    // Apply filters
    if (query.status) {
      supabaseQuery = supabaseQuery.eq('status', query.status);
    }

    if (query.skills && query.skills.length > 0) {
      supabaseQuery = supabaseQuery.contains('required_skills', query.skills);
    }

    if (query.min_budget) {
      supabaseQuery = supabaseQuery.gte('budget_max_daos', query.min_budget);
    }

    if (query.max_budget) {
      supabaseQuery = supabaseQuery.lte('budget_max_daos', query.max_budget);
    }

    if (query.min_rank !== undefined) {
      supabaseQuery = supabaseQuery.gte('min_rank', query.min_rank);
    }

    // RLS will handle visibility (public or own missions)
    // Pagination
    const from = (query.page - 1) * query.limit;
    supabaseQuery = supabaseQuery
      .range(from, from + query.limit - 1)
      .order('created_at', { ascending: false });

    const { data, error, count } = await supabaseQuery;

    if (error) throw error;

    return res.json({
      success: true,
      data: data || [],
      pagination: {
        page: query.page,
        limit: query.limit,
        total: count || 0,
        pages: Math.ceil((count || 0) / query.limit),
      },
    });
  } catch (error: any) {
    console.error('[Missions API] List error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to list missions',
    });
  }
});

/**
 * GET /api/missions/:id
 * Get mission details by ID
 */
router.get('/:id', async (req, res) => {
  try {
    const { id } = req.params;

    const { data, error } = await supabase
      .from('missions')
      .select(`
        *,
        profiles!client_wallet(*),
        profiles!selected_consultant_wallet(*),
        mission_applications(
          *,
          profiles!consultant_wallet(*)
        ),
        milestones(*),
        contributors(*)
      `)
      .eq('id', id)
      .single();

    if (error) throw error;

    if (!data) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Missions API] Get error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to get mission',
    });
  }
});

/**
 * POST /api/missions
 * Create new mission (client only)
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

    const body = CreateMissionSchema.parse(req.body);

    const { data, error } = await supabase
      .from('missions')
      .insert({
        client_wallet: wallet,
        ...body,
      })
      .select()
      .single();

    if (error) throw error;

    return res.status(201).json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Missions API] Create error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to create mission',
    });
  }
});

/**
 * PATCH /api/missions/:id
 * Update mission (client only, before published)
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
    const body = UpdateMissionSchema.parse(req.body);

    // Verify ownership
    const { data: mission } = await supabase
      .from('missions')
      .select('client_wallet, status')
      .eq('id', id)
      .single();

    if (!mission) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    if (mission.client_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not mission owner',
      });
    }

    if (mission.status !== 'draft' && mission.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: 'Cannot update mission in current status',
      });
    }

    const { data, error } = await supabase
      .from('missions')
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
    console.error('[Missions API] Update error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to update mission',
    });
  }
});

/**
 * POST /api/missions/:id/publish
 * Publish mission (make visible to consultants)
 */
router.post('/:id/publish', async (req, res) => {
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
    const { data: mission } = await supabase
      .from('missions')
      .select('client_wallet, status')
      .eq('id', id)
      .single();

    if (!mission) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    if (mission.client_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not mission owner',
      });
    }

    if (mission.status !== 'draft') {
      return res.status(400).json({
        success: false,
        error: 'Mission already published',
      });
    }

    const { data, error } = await supabase
      .from('missions')
      .update({
        status: 'active',
        published_at: new Date().toISOString(),
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Missions API] Publish error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to publish mission',
    });
  }
});

/**
 * POST /api/missions/:id/cancel
 * Cancel mission (client only)
 */
router.post('/:id/cancel', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { id } = req.params;
    const { reason } = req.body;

    // Verify ownership
    const { data: mission } = await supabase
      .from('missions')
      .select('client_wallet, status, selected_consultant_wallet')
      .eq('id', id)
      .single();

    if (!mission) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    if (mission.client_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not mission owner',
      });
    }

    if (mission.status === 'completed' || mission.status === 'cancelled') {
      return res.status(400).json({
        success: false,
        error: 'Mission already completed or cancelled',
      });
    }

    const { data, error } = await supabase
      .from('missions')
      .update({
        status: 'cancelled',
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // GitHub issue #19: Create notification for consultant if selected
    if (mission.selected_consultant_wallet) {
      await supabase.from('notifications').insert({
        recipient_wallet: mission.selected_consultant_wallet,
        notification_type: 'mission_published', // GitHub issue #19: Add 'mission_cancelled' type
        title: 'Mission Cancelled',
        message: `Mission has been cancelled by the client${reason ? ': ' + reason : ''}`,
        link_url: `/missions/${id}`,
        metadata: { mission_id: id, reason },
      });
    }

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Missions API] Cancel error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to cancel mission',
    });
  }
});

/**
 * GET /api/missions/:id/applications
 * Get applications for a mission (client only)
 */
router.get('/:id/applications', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { id } = req.params;

    // Verify ownership
    const { data: mission } = await supabase
      .from('missions')
      .select('client_wallet')
      .eq('id', id)
      .single();

    if (!mission) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    if (mission.client_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not mission owner',
      });
    }

    const { data, error } = await supabase
      .from('mission_applications')
      .select(`
        *,
        profiles!consultant_wallet(*)
      `)
      .eq('mission_id', id)
      .order('match_score', { ascending: false });

    if (error) throw error;

    return res.json({
      success: true,
      data: data || [],
    });
  } catch (error: any) {
    console.error('[Missions API] Get applications error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to get applications',
    });
  }
});

/**
 * POST /api/missions/:id/select-consultant
 * Select consultant for mission (client only)
 */
router.post('/:id/select-consultant', async (req, res) => {
  try {
    const wallet = req.user?.wallet_address;
    if (!wallet) {
      return res.status(401).json({
        success: false,
        error: 'Unauthorized - wallet required',
      });
    }

    const { id } = req.params;
    const { consultant_wallet } = req.body;

    if (!consultant_wallet) {
      return res.status(400).json({
        success: false,
        error: 'consultant_wallet required',
      });
    }

    // Verify ownership
    const { data: mission } = await supabase
      .from('missions')
      .select('client_wallet, status')
      .eq('id', id)
      .single();

    if (!mission) {
      return res.status(404).json({
        success: false,
        error: 'Mission not found',
      });
    }

    if (mission.client_wallet !== wallet) {
      return res.status(403).json({
        success: false,
        error: 'Forbidden - not mission owner',
      });
    }

    if (mission.status !== 'active') {
      return res.status(400).json({
        success: false,
        error: 'Mission not active',
      });
    }

    // Verify application exists
    const { data: application } = await supabase
      .from('mission_applications')
      .select('id')
      .eq('mission_id', id)
      .eq('consultant_wallet', consultant_wallet)
      .single();

    if (!application) {
      return res.status(400).json({
        success: false,
        error: 'Application not found for this consultant',
      });
    }

    // Update mission
    const { data, error } = await supabase
      .from('missions')
      .update({
        selected_consultant_wallet: consultant_wallet,
        status: 'on_hold', // Wait for escrow creation
      })
      .eq('id', id)
      .select()
      .single();

    if (error) throw error;

    // Update application status
    await supabase
      .from('mission_applications')
      .update({ status: 'selected' })
      .eq('id', application.id);

    // Reject other applications
    await supabase
      .from('mission_applications')
      .update({ status: 'rejected' })
      .eq('mission_id', id)
      .neq('consultant_wallet', consultant_wallet);

    // Create notification
    await supabase.from('notifications').insert({
      recipient_wallet: consultant_wallet,
      notification_type: 'consultant_selected',
      title: 'You were selected!',
      message: 'A client has selected you for their mission',
      link_url: `/missions/${id}`,
      metadata: { mission_id: id },
    });

    return res.json({
      success: true,
      data,
    });
  } catch (error: any) {
    console.error('[Missions API] Select consultant error:', error);
    return res.status(400).json({
      success: false,
      error: error.message || 'Failed to select consultant',
    });
  }
});

export default router;
