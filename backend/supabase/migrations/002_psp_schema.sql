-- Migration 002: PSP Schema — Remove DAOS token dependencies
-- Version: 2.0.0
-- Date: 2026-02-18
-- ADR: 2026-02-18 — Payments via PSP (Mangopay/Stripe Connect), no on-chain escrow
--
-- Summary of changes:
--   missions           : budget_max_daos→budget_eur, drop budget_locked_daos,
--                        add psp_escrow_id/budget_usdc/currency,
--                        enum on_hold→consultant_selected
--   mission_applications: proposed_budget_daos→proposed_budget_eur
--   milestones          : amount_daos→amount_eur, add psp_milestone_id
--   payments            : amount_daos→amount_eur, add psp_transaction_id/currency,
--                         drop transaction_hash (PSP payments have no blockchain tx)
--   disputes            : drop on_chain_dispute_id, add psp_dispute_id/resolution_channel
--   notifications       : add 'mission_cancelled' to enum (bug fix B13)

-- ============================================================================
-- MISSIONS — T4
-- ============================================================================

-- 1. Rename on_hold → consultant_selected in mission_status enum
--    (PostgreSQL 10+ supports this directly)
ALTER TYPE mission_status RENAME VALUE 'on_hold' TO 'consultant_selected';

-- 2. Rename budget column: DAOS → EUR
ALTER TABLE missions
  RENAME COLUMN budget_max_daos TO budget_eur;

-- 3. Drop budget_locked_daos (no longer applicable: PSP handles escrow)
ALTER TABLE missions
  DROP COLUMN IF EXISTS budget_locked_daos;

-- 4. Add PSP-specific columns
ALTER TABLE missions
  ADD COLUMN IF NOT EXISTS budget_usdc  NUMERIC(18,6),   -- Amount in USDC (optional crypto payment)
  ADD COLUMN IF NOT EXISTS psp_escrow_id TEXT,            -- Mangopay/Stripe escrow identifier
  ADD COLUMN IF NOT EXISTS currency     TEXT DEFAULT 'EUR'
    CHECK (currency IN ('EUR', 'USDC'));                  -- Payment currency

-- 5. Add 'mission_cancelled' to notification_type enum (bug fix B13)
--    Required so missions.ts can emit the correct notification on cancellation
ALTER TYPE notification_type ADD VALUE IF NOT EXISTS 'mission_cancelled';

-- ============================================================================
-- MISSION_APPLICATIONS — T5
-- ============================================================================

ALTER TABLE mission_applications
  RENAME COLUMN proposed_budget_daos TO proposed_budget_eur;

-- ============================================================================
-- MILESTONES — T5
-- ============================================================================

ALTER TABLE milestones
  RENAME COLUMN amount_daos TO amount_eur;

ALTER TABLE milestones
  ADD COLUMN IF NOT EXISTS psp_milestone_id TEXT;   -- PSP milestone/payin identifier

-- ============================================================================
-- PAYMENTS — T5
-- ============================================================================

ALTER TABLE payments
  RENAME COLUMN amount_daos TO amount_eur;

-- PSP transactions have no blockchain tx_hash
ALTER TABLE payments
  DROP COLUMN IF EXISTS transaction_hash;

ALTER TABLE payments
  ADD COLUMN IF NOT EXISTS psp_transaction_id TEXT,
  ADD COLUMN IF NOT EXISTS currency            TEXT DEFAULT 'EUR'
    CHECK (currency IN ('EUR', 'USDC'));

-- ============================================================================
-- DISPUTES — T5 cleanup
-- ============================================================================

-- Disputes are now handled by PSP SLA, no on-chain resolution
ALTER TABLE disputes
  DROP COLUMN IF EXISTS on_chain_dispute_id;

ALTER TABLE disputes
  ADD COLUMN IF NOT EXISTS psp_dispute_id      TEXT,
  ADD COLUMN IF NOT EXISTS resolution_channel  TEXT DEFAULT 'PSP_SLA'
    CHECK (resolution_channel IN ('PSP_SLA', 'DAO_VOTE', 'MEDIATION'));

-- ============================================================================
-- UPDATE COMMENTS
-- ============================================================================

COMMENT ON COLUMN missions.budget_eur         IS 'Mission budget in EUR centimes (managed by PSP, not on-chain)';
COMMENT ON COLUMN missions.budget_usdc         IS 'Optional budget in USDC if crypto payment chosen';
COMMENT ON COLUMN missions.psp_escrow_id       IS 'Mangopay/Stripe Connect escrow ID (set after consultant selection)';
COMMENT ON COLUMN missions.currency            IS 'Payment currency: EUR (default) or USDC';
COMMENT ON COLUMN milestones.amount_eur        IS 'Milestone amount in EUR (managed by PSP)';
COMMENT ON COLUMN milestones.psp_milestone_id  IS 'PSP milestone/payin identifier';
COMMENT ON COLUMN payments.amount_eur          IS 'Payment amount in EUR';
COMMENT ON COLUMN payments.psp_transaction_id  IS 'PSP transaction identifier (no blockchain tx_hash)';
COMMENT ON COLUMN disputes.psp_dispute_id      IS 'PSP dispute identifier for SLA resolution';
COMMENT ON COLUMN disputes.resolution_channel  IS 'How the dispute is resolved: PSP_SLA (default), DAO_VOTE, or MEDIATION';

COMMENT ON TABLE payments IS 'PSP payment distribution history (Mangopay/Stripe Connect — no blockchain tx_hash)';
COMMENT ON TABLE disputes IS 'Mission disputes managed via PSP SLA (no on-chain arbitration)';
