/**
 * Missions API Routes Tests
 * Critical Path Coverage: Mission CRUD, publish, cancel, consultant selection
 */

import { describe, it, expect, vi, beforeEach } from 'vitest';
import request from 'supertest';
import express from 'express';
import missionsRouter from './missions.js';

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
      gte: vi.fn().mockReturnThis(),
      lte: vi.fn().mockReturnThis(),
      contains: vi.fn().mockReturnThis(),
      is: vi.fn().mockReturnThis(),
      order: vi.fn().mockReturnThis(),
      range: vi.fn().mockReturnThis(),
      limit: vi.fn().mockReturnThis(),
      single: vi.fn(),
    })),
  })),
}));

// Setup Express app with missions router
const app = express();
app.use(express.json());

// Mock auth middleware - attach user to req
app.use((req, res, next) => {
  req.user = { wallet_address: '0x1234567890abcdef' };
  next();
});

app.use('/api/missions', missionsRouter);

describe('Missions API - Critical Paths', () => {
  beforeEach(() => {
    vi.clearAllMocks();
  });

  describe('GET /api/missions', () => {
    it('should list missions with default pagination', async () => {
      const response = await request(app)
        .get('/api/missions')
        .expect(200);

      expect(response.body).toHaveProperty('success', true);
      expect(response.body).toHaveProperty('data');
      expect(response.body).toHaveProperty('pagination');
      expect(response.body.pagination).toHaveProperty('page', 1);
      expect(response.body.pagination).toHaveProperty('limit', 20);
    });

    it('should filter missions by status', async () => {
      const response = await request(app)
        .get('/api/missions?status=active')
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should paginate missions correctly', async () => {
      const response = await request(app)
        .get('/api/missions?page=2&limit=10')
        .expect(200);

      expect(response.body.pagination.page).toBe(2);
      expect(response.body.pagination.limit).toBe(10);
    });
  });

  describe('POST /api/missions', () => {
    it('should create mission with valid data', async () => {
      const newMission = {
        title: 'Build React Dashboard',
        description: 'We need a modern dashboard with charts and real-time data visualization',
        budget_max_daos: 5000,
        min_rank: 2,
        required_skills: ['React', 'TypeScript', 'D3.js'],
        estimated_duration_days: 14,
        visibility: 'public',
      };

      const response = await request(app)
        .post('/api/missions')
        .send(newMission)
        .expect(201);

      expect(response.body.success).toBe(true);
      expect(response.body.data).toBeDefined();
    });

    it('should reject mission with invalid title (too short)', async () => {
      const invalidMission = {
        title: 'A',
        description: 'This is a valid description with more than 50 characters for testing',
        budget_max_daos: 1000,
      };

      const response = await request(app)
        .post('/api/missions')
        .send(invalidMission)
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject mission without authentication', async () => {
      // Override auth middleware for this test
      const appNoAuth = express();
      appNoAuth.use(express.json());
      appNoAuth.use('/api/missions', missionsRouter);

      const response = await request(appNoAuth)
        .post('/api/missions')
        .send({ title: 'Test', description: 'Test description' })
        .expect(401);

      expect(response.body.success).toBe(false);
    });
  });

  describe('PATCH /api/missions/:id', () => {
    it('should update mission with valid data', async () => {
      const updates = {
        title: 'Updated Mission Title',
        description: 'Updated description with sufficient length for validation',
      };

      const response = await request(app)
        .patch('/api/missions/test-mission-id')
        .send(updates)
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject updates on non-draft/non-active missions', async () => {
      // Mission status check happens in the route handler
      const response = await request(app)
        .patch('/api/missions/completed-mission-id')
        .send({ title: 'Updated Title' });

      // Either 400 (status check) or 404 (not found)
      expect([400, 404]).toContain(response.status);
    });
  });

  describe('POST /api/missions/:id/publish', () => {
    it('should publish draft mission', async () => {
      const response = await request(app)
        .post('/api/missions/draft-mission-id/publish')
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject publishing already published mission', async () => {
      const response = await request(app)
        .post('/api/missions/active-mission-id/publish');

      expect([400, 404]).toContain(response.status);
    });
  });

  describe('POST /api/missions/:id/cancel', () => {
    it('should cancel mission with reason', async () => {
      const response = await request(app)
        .post('/api/missions/active-mission-id/cancel')
        .send({ reason: 'Project scope changed' })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject cancelling completed mission', async () => {
      const response = await request(app)
        .post('/api/missions/completed-mission-id/cancel');

      expect([400, 404]).toContain(response.status);
    });
  });

  describe('POST /api/missions/:id/select-consultant', () => {
    it('should select consultant with valid application', async () => {
      const response = await request(app)
        .post('/api/missions/active-mission-id/select-consultant')
        .send({ consultant_wallet: '0xabcdef1234567890' })
        .expect(200);

      expect(response.body.success).toBe(true);
    });

    it('should reject selection without consultant_wallet', async () => {
      const response = await request(app)
        .post('/api/missions/active-mission-id/select-consultant')
        .send({})
        .expect(400);

      expect(response.body.success).toBe(false);
    });

    it('should reject selection on non-active mission', async () => {
      const response = await request(app)
        .post('/api/missions/draft-mission-id/select-consultant')
        .send({ consultant_wallet: '0xabcdef1234567890' });

      expect([400, 404]).toContain(response.status);
    });
  });
});
