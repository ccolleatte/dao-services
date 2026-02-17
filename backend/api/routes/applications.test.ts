/**
 * Applications API Routes Tests
 * Critical Path Coverage: Application CRUD, match score calculation
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import applicationsRouter from './applications.js';

// Mock Supabase
vi.mock('@supabase/supabase-js', () => ({
  createClient: vi.fn(() => ({
    from: vi.fn(() => ({
      select: vi.fn().mockReturnThis(),
      insert: vi.fn().mockReturnThis(),
      update: vi.fn().mockReturnThis(),
      delete: vi.fn().mockReturnThis(),
      eq: vi.fn().mockReturnThis(),
      neq: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      single: vi.fn(),
    })),
  })),
}));

// Setup Express app with applications router
const app = express();
app.use(express.json());

// Mock auth middleware
app.use((req, res, next) => {
  req.user = { wallet_address: '0x1234567890abcdef' };
  next();
});

app.use('/api/applications', applicationsRouter);

describe('Applications API - Critical Paths', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('GET /api/applications', () => {
    it('should list consultant applications', async () => {
      const response = await request(app)
        .get('/api/applications')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('data');
      expect(Array.isArray(response.body.data)).toBe(true);
    });

    it('should filter applications by status', async () => {
      const response = await request(app)
        .get('/api/applications?status=pending')
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should require authentication', async () => {
      const appNoAuth = express();
      appNoAuth.use(express.json());
      appNoAuth.use('/api/applications', applicationsRouter);

      const response = await request(appNoAuth)
        .get('/api/applications')
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  describe('POST /api/applications', () => {
    it('should create application with valid data', async () => {
      const newApplication = {
        mission_id: 'test-mission-uuid',
        proposal_text: 'I have 5 years experience building React dashboards with D3.js and TypeScript. I can deliver this in 2 weeks with daily progress updates.',
        proposed_budget_daos: 4500,
        estimated_delivery_days: 14,
      };

      const response = await request(app)
        .post('/api/applications')
        .send(newApplication)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
    });

    it('should reject application with short proposal (<100 chars)', async () => {
      const invalidApplication = {
        mission_id: 'test-mission-uuid',
        proposal_text: 'Short proposal',
        proposed_budget_daos: 1000,
      };

      const response = await request(app)
        .post('/api/applications')
        .send(invalidApplication)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject application exceeding mission budget', async () => {
      const overBudgetApplication = {
        mission_id: 'low-budget-mission-uuid',
        proposal_text: 'Valid proposal text that is long enough to pass validation requirements for minimum character count',
        proposed_budget_daos: 999999, // Way over budget
      };

      const response = await request(app)
        .post('/api/applications')
        .send(overBudgetApplication);

      expect([400, 404]).toContain(response.status);
    });

    it('should reject application to non-active mission', async () => {
      const response = await request(app)
        .post('/api/applications')
        .send({
          mission_id: 'draft-mission-uuid',
          proposal_text: 'Valid proposal text with sufficient length for testing validation',
          proposed_budget_daos: 1000,
        });

      expect([400, 404]).toContain(response.status);
    });
  });

  describe('PATCH /api/applications/:id', () => {
    it('should update pending application', async () => {
      const updates = {
        proposal_text: 'Updated proposal with more details and sufficient length for validation',
        proposed_budget_daos: 4000,
      };

      const response = await request(app)
        .patch('/api/applications/test-app-id')
        .send(updates)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject updates on reviewed applications', async () => {
      const response = await request(app)
        .patch('/api/applications/selected-app-id')
        .send({
          proposal_text: 'Updated text with sufficient length',
        });

      expect([400, 404]).toContain(response.status);
    });
  });

  describe('DELETE /api/applications/:id', () => {
    it('should withdraw pending application', async () => {
      const response = await request(app)
        .delete('/api/applications/pending-app-id')
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject withdrawing selected application', async () => {
      const response = await request(app)
        .delete('/api/applications/selected-app-id');

      expect([400, 404]).toContain(response.status);
    });
  });

  describe('POST /api/applications/:id/calculate-match-score', () => {
    it('should calculate match score (mock)', async () => {
      const response = await request(app)
        .post('/api/applications/test-app-id/calculate-match-score')
        .expect(200);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toHaveProperty('match_score');
    });

    it('should reject calculation for non-existent application', async () => {
      const response = await request(app)
        .post('/api/applications/non-existent-id/calculate-match-score')
        .expect(404);

      expect(response.body.success).toBe(false);
    });
  });
});
