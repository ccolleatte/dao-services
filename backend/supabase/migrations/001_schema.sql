-- Migration 001: Core Schema for DAO Marketplace
-- Version: 1.0.0
-- Date: 2026-02-09

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ============================================================================
-- PROFILES (Off-chain member data)
-- ============================================================================
CREATE TABLE profiles (
  wallet_address TEXT PRIMARY KEY,
  on_chain_rank SMALLINT DEFAULT 0 CHECK (on_chain_rank BETWEEN 0 AND 4),
  github_handle TEXT,
  linkedin_url TEXT,
  hourly_rate_daos DECIMAL(18,2),
  skills TEXT[] DEFAULT '{}',
  bio TEXT,
  avatar_url TEXT,
  reputation_score DECIMAL(5,2) DEFAULT 0,
  total_missions_completed INT DEFAULT 0,
  total_missions_as_client INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_profiles_rank ON profiles(on_chain_rank);
CREATE INDEX idx_profiles_reputation ON profiles(reputation_score DESC);

-- ============================================================================
-- MISSIONS (Marketplace jobs)
-- ============================================================================
CREATE TYPE mission_status AS ENUM ('draft', 'active', 'on_hold', 'disputed', 'completed', 'cancelled');

CREATE TABLE missions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  on_chain_mission_id BIGINT UNIQUE, -- NULL until blockchain confirm
  client_wallet TEXT NOT NULL REFERENCES profiles(wallet_address) ON DELETE CASCADE,
  title TEXT NOT NULL CHECK (char_length(title) BETWEEN 5 AND 200),
  description TEXT NOT NULL CHECK (char_length(description) BETWEEN 50 AND 5000),
  budget_max_daos DECIMAL(18,2) NOT NULL CHECK (budget_max_daos > 0),
  budget_locked_daos DECIMAL(18,2) DEFAULT 0,
  min_rank SMALLINT DEFAULT 0 CHECK (min_rank BETWEEN 0 AND 4),
  required_skills TEXT[] DEFAULT '{}',
  estimated_duration_days INT,
  status mission_status DEFAULT 'draft',
  selected_consultant_wallet TEXT REFERENCES profiles(wallet_address) ON DELETE SET NULL,
  visibility TEXT DEFAULT 'public' CHECK (visibility IN ('public', 'private', 'invite_only')),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  published_at TIMESTAMPTZ,
  completed_at TIMESTAMPTZ
);

CREATE INDEX idx_missions_status ON missions(status);
CREATE INDEX idx_missions_client ON missions(client_wallet);
CREATE INDEX idx_missions_consultant ON missions(selected_consultant_wallet);
CREATE INDEX idx_missions_created ON missions(created_at DESC);
CREATE INDEX idx_missions_skills ON missions USING GIN(required_skills);

-- ============================================================================
-- MISSION_APPLICATIONS (Consultant applications)
-- ============================================================================
CREATE TABLE mission_applications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  consultant_wallet TEXT NOT NULL REFERENCES profiles(wallet_address) ON DELETE CASCADE,
  proposal_text TEXT NOT NULL CHECK (char_length(proposal_text) BETWEEN 100 AND 5000),
  proposal_ipfs_hash TEXT, -- IPFS link for attachments
  proposed_budget_daos DECIMAL(18,2) NOT NULL CHECK (proposed_budget_daos > 0),
  estimated_delivery_days INT,
  match_score INT CHECK (match_score BETWEEN 0 AND 100), -- From on-chain algorithm
  status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'shortlisted', 'rejected', 'selected')),
  submitted_at TIMESTAMPTZ DEFAULT NOW(),
  reviewed_at TIMESTAMPTZ,
  UNIQUE(mission_id, consultant_wallet) -- One application per consultant per mission
);

CREATE INDEX idx_applications_mission ON mission_applications(mission_id);
CREATE INDEX idx_applications_consultant ON mission_applications(consultant_wallet);
CREATE INDEX idx_applications_score ON mission_applications(match_score DESC);

-- ============================================================================
-- MILESTONES (Escrow milestones)
-- ============================================================================
CREATE TYPE milestone_status AS ENUM ('pending', 'submitted', 'approved', 'rejected', 'disputed');

CREATE TABLE milestones (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  on_chain_milestone_id INT, -- Index in smart contract
  sequence_order INT NOT NULL, -- 0, 1, 2...
  description TEXT NOT NULL CHECK (char_length(description) BETWEEN 10 AND 1000),
  amount_daos DECIMAL(18,2) NOT NULL CHECK (amount_daos > 0),
  deadline TIMESTAMPTZ NOT NULL,
  status milestone_status DEFAULT 'pending',
  deliverable_ipfs_hash TEXT, -- IPFS hash when submitted
  submitted_at TIMESTAMPTZ,
  approved_at TIMESTAMPTZ,
  rejected_at TIMESTAMPTZ,
  rejection_reason TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(mission_id, sequence_order)
);

CREATE INDEX idx_milestones_mission ON milestones(mission_id, sequence_order);
CREATE INDEX idx_milestones_status ON milestones(status);

-- ============================================================================
-- DISPUTES (Milestone disputes)
-- ============================================================================
CREATE TYPE dispute_status AS ENUM ('open', 'voting', 'resolved');

CREATE TABLE disputes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  on_chain_dispute_id BIGINT UNIQUE,
  milestone_id UUID NOT NULL REFERENCES milestones(id) ON DELETE CASCADE,
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  initiator_wallet TEXT NOT NULL REFERENCES profiles(wallet_address),
  reason TEXT NOT NULL CHECK (char_length(reason) BETWEEN 50 AND 2000),
  consultant_response TEXT,
  jurors TEXT[] DEFAULT '{}', -- 5 wallet addresses
  votes_for INT DEFAULT 0, -- For consultant
  votes_against INT DEFAULT 0, -- For client
  status dispute_status DEFAULT 'open',
  winner_wallet TEXT REFERENCES profiles(wallet_address) ON DELETE SET NULL,
  deposit_daos DECIMAL(18,2) DEFAULT 100, -- 100 DAOS deposit
  created_at TIMESTAMPTZ DEFAULT NOW(),
  voting_deadline TIMESTAMPTZ, -- 72 hours from creation
  resolved_at TIMESTAMPTZ
);

CREATE INDEX idx_disputes_milestone ON disputes(milestone_id);
CREATE INDEX idx_disputes_mission ON disputes(mission_id);
CREATE INDEX idx_disputes_status ON disputes(status);

-- ============================================================================
-- DISPUTE_VOTES (Individual juror votes)
-- ============================================================================
CREATE TABLE dispute_votes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  dispute_id UUID NOT NULL REFERENCES disputes(id) ON DELETE CASCADE,
  juror_wallet TEXT NOT NULL REFERENCES profiles(wallet_address),
  favor_consultant BOOLEAN NOT NULL, -- TRUE = for consultant, FALSE = for client
  voted_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(dispute_id, juror_wallet)
);

CREATE INDEX idx_dispute_votes_dispute ON dispute_votes(dispute_id);

-- ============================================================================
-- CONTRIBUTORS (Hybrid mission contributors)
-- ============================================================================
CREATE TYPE contributor_type AS ENUM ('human', 'ai', 'compute');

CREATE TABLE contributors (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  account_identifier TEXT NOT NULL, -- Wallet (human) or API key hash (AI/compute)
  contributor_type contributor_type NOT NULL,
  percentage_bps INT NOT NULL CHECK (percentage_bps BETWEEN 0 AND 10000), -- Basis points (10000 = 100%)
  total_earned_daos DECIMAL(18,2) DEFAULT 0,
  added_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(mission_id, account_identifier, contributor_type)
);

CREATE INDEX idx_contributors_mission ON contributors(mission_id);
CREATE INDEX idx_contributors_type ON contributors(contributor_type);

-- ============================================================================
-- USAGE_LOGS (AI + Compute metering)
-- ============================================================================
CREATE TYPE usage_log_type AS ENUM ('ai_tokens', 'compute_hours');

CREATE TABLE usage_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  contributor_id UUID NOT NULL REFERENCES contributors(id) ON DELETE CASCADE,
  log_type usage_log_type NOT NULL,
  amount DECIMAL(18,6) NOT NULL CHECK (amount >= 0), -- Tokens (millions) or GPU-hours
  cost_daos DECIMAL(18,2) NOT NULL CHECK (cost_daos >= 0),
  metadata JSONB DEFAULT '{}'::jsonb, -- Model name, GPU type, etc.
  logged_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_usage_logs_mission ON usage_logs(mission_id);
CREATE INDEX idx_usage_logs_contributor ON usage_logs(contributor_id);
CREATE INDEX idx_usage_logs_type ON usage_logs(log_type);
CREATE INDEX idx_usage_logs_date ON usage_logs(logged_at DESC);

-- ============================================================================
-- PAYMENTS (Payment distributions)
-- ============================================================================
CREATE TABLE payments (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  recipient_wallet TEXT NOT NULL REFERENCES profiles(wallet_address),
  amount_daos DECIMAL(18,2) NOT NULL CHECK (amount_daos > 0),
  contributor_type contributor_type NOT NULL,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL, -- NULL if final payment
  transaction_hash TEXT UNIQUE, -- Blockchain transaction hash
  paid_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_payments_mission ON payments(mission_id);
CREATE INDEX idx_payments_recipient ON payments(recipient_wallet);
CREATE INDEX idx_payments_date ON payments(paid_at DESC);

-- ============================================================================
-- TRANSACTIONS (All blockchain transactions log)
-- ============================================================================
CREATE TYPE transaction_type AS ENUM (
  'mission_created',
  'application_submitted',
  'consultant_selected',
  'milestone_submitted',
  'milestone_approved',
  'milestone_rejected',
  'dispute_raised',
  'dispute_voted',
  'dispute_resolved',
  'payment_distributed',
  'usage_reported',
  'pricing_updated'
);

CREATE TABLE transactions (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transaction_hash TEXT UNIQUE NOT NULL,
  block_number BIGINT NOT NULL,
  transaction_type transaction_type NOT NULL,
  contract_address TEXT NOT NULL,
  event_name TEXT NOT NULL,
  event_data JSONB NOT NULL DEFAULT '{}'::jsonb,
  mission_id UUID REFERENCES missions(id) ON DELETE SET NULL,
  milestone_id UUID REFERENCES milestones(id) ON DELETE SET NULL,
  dispute_id UUID REFERENCES disputes(id) ON DELETE SET NULL,
  synced_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transactions_hash ON transactions(transaction_hash);
CREATE INDEX idx_transactions_block ON transactions(block_number DESC);
CREATE INDEX idx_transactions_type ON transactions(transaction_type);
CREATE INDEX idx_transactions_mission ON transactions(mission_id);

-- ============================================================================
-- NOTIFICATIONS (User notifications)
-- ============================================================================
CREATE TYPE notification_type AS ENUM (
  'mission_published',
  'application_received',
  'application_shortlisted',
  'application_rejected',
  'consultant_selected',
  'milestone_submitted',
  'milestone_approved',
  'milestone_rejected',
  'dispute_raised',
  'dispute_resolved',
  'payment_received',
  'jury_selected'
);

CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  recipient_wallet TEXT NOT NULL REFERENCES profiles(wallet_address) ON DELETE CASCADE,
  notification_type notification_type NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  link_url TEXT, -- Deep link to relevant page
  metadata JSONB DEFAULT '{}'::jsonb,
  read_at TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_wallet, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(recipient_wallet, read_at) WHERE read_at IS NULL;

-- ============================================================================
-- RATINGS (Mission ratings + reviews)
-- ============================================================================
CREATE TABLE ratings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  rater_wallet TEXT NOT NULL REFERENCES profiles(wallet_address),
  rated_wallet TEXT NOT NULL REFERENCES profiles(wallet_address),
  rating INT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  review_text TEXT CHECK (char_length(review_text) <= 2000),
  created_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(mission_id, rater_wallet, rated_wallet)
);

CREATE INDEX idx_ratings_mission ON ratings(mission_id);
CREATE INDEX idx_ratings_rated ON ratings(rated_wallet);

-- ============================================================================
-- MATCH_SCORES (Cached match scores for analytics)
-- ============================================================================
CREATE TABLE match_scores (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  consultant_wallet TEXT NOT NULL REFERENCES profiles(wallet_address) ON DELETE CASCADE,
  total_score INT NOT NULL CHECK (total_score BETWEEN 0 AND 100),
  rank_score INT CHECK (rank_score BETWEEN 0 AND 25),
  skills_score INT CHECK (skills_score BETWEEN 0 AND 25),
  budget_score INT CHECK (budget_score BETWEEN 0 AND 20),
  track_record_score INT CHECK (track_record_score BETWEEN 0 AND 15),
  responsiveness_score INT CHECK (responsiveness_score BETWEEN 0 AND 15),
  calculated_at TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(mission_id, consultant_wallet)
);

CREATE INDEX idx_match_scores_mission ON match_scores(mission_id, total_score DESC);
CREATE INDEX idx_match_scores_consultant ON match_scores(consultant_wallet);

-- ============================================================================
-- PRICING_HISTORY (Usage pricing history)
-- ============================================================================
CREATE TABLE pricing_history (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  mission_id UUID NOT NULL REFERENCES missions(id) ON DELETE CASCADE,
  price_per_m_token_llm DECIMAL(18,2) NOT NULL, -- DAOS per 1M tokens
  price_per_gpu_hour DECIMAL(18,2) NOT NULL, -- DAOS per GPU-hour
  effective_from TIMESTAMPTZ NOT NULL,
  effective_until TIMESTAMPTZ,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_pricing_history_mission ON pricing_history(mission_id, effective_from DESC);

-- ============================================================================
-- WEBHOOK_LOGS (Webhook delivery logs)
-- ============================================================================
CREATE TABLE webhook_logs (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  webhook_url TEXT NOT NULL,
  event_type TEXT NOT NULL,
  payload JSONB NOT NULL,
  response_status INT,
  response_body TEXT,
  delivered_at TIMESTAMPTZ,
  failed_at TIMESTAMPTZ,
  retry_count INT DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_webhook_logs_event ON webhook_logs(event_type, created_at DESC);
CREATE INDEX idx_webhook_logs_failed ON webhook_logs(failed_at) WHERE failed_at IS NOT NULL;

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE missions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mission_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE milestones ENABLE ROW LEVEL SECURITY;
ALTER TABLE disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE dispute_votes ENABLE ROW LEVEL SECURITY;
ALTER TABLE contributors ENABLE ROW LEVEL SECURITY;
ALTER TABLE usage_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE ratings ENABLE ROW LEVEL SECURITY;

-- Profiles: Public read, own update
CREATE POLICY profiles_public_read ON profiles FOR SELECT USING (TRUE);
CREATE POLICY profiles_own_update ON profiles FOR UPDATE
  USING (wallet_address = current_setting('request.jwt.claim.wallet_address', true));
CREATE POLICY profiles_own_insert ON profiles FOR INSERT
  WITH CHECK (wallet_address = current_setting('request.jwt.claim.wallet_address', true));

-- Missions: Public if visibility=public, own if client/consultant
CREATE POLICY missions_public_read ON missions FOR SELECT
  USING (
    visibility = 'public' OR
    client_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
    selected_consultant_wallet = current_setting('request.jwt.claim.wallet_address', true)
  );
CREATE POLICY missions_own_write ON missions FOR ALL
  USING (client_wallet = current_setting('request.jwt.claim.wallet_address', true));

-- Mission Applications: Visible to client + own consultant
CREATE POLICY applications_visibility ON mission_applications FOR SELECT
  USING (
    consultant_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
    EXISTS (
      SELECT 1 FROM missions m
      WHERE m.id = mission_applications.mission_id
      AND m.client_wallet = current_setting('request.jwt.claim.wallet_address', true)
    )
  );
CREATE POLICY applications_own_insert ON mission_applications FOR INSERT
  WITH CHECK (consultant_wallet = current_setting('request.jwt.claim.wallet_address', true));

-- Milestones: Visible to mission participants
CREATE POLICY milestones_visibility ON milestones FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM missions m
      WHERE m.id = milestones.mission_id
      AND (
        m.client_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
        m.selected_consultant_wallet = current_setting('request.jwt.claim.wallet_address', true)
      )
    )
  );

-- Disputes: Visible to mission participants + jurors
CREATE POLICY disputes_visibility ON disputes FOR SELECT
  USING (
    initiator_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
    current_setting('request.jwt.claim.wallet_address', true) = ANY(jurors) OR
    EXISTS (
      SELECT 1 FROM missions m
      WHERE m.id = disputes.mission_id
      AND (
        m.client_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
        m.selected_consultant_wallet = current_setting('request.jwt.claim.wallet_address', true)
      )
    )
  );

-- Notifications: Own only
CREATE POLICY notifications_own_read ON notifications FOR SELECT
  USING (recipient_wallet = current_setting('request.jwt.claim.wallet_address', true));
CREATE POLICY notifications_own_update ON notifications FOR UPDATE
  USING (recipient_wallet = current_setting('request.jwt.claim.wallet_address', true));

-- Payments: Visible to recipient + mission client
CREATE POLICY payments_visibility ON payments FOR SELECT
  USING (
    recipient_wallet = current_setting('request.jwt.claim.wallet_address', true) OR
    EXISTS (
      SELECT 1 FROM missions m
      WHERE m.id = payments.mission_id
      AND m.client_wallet = current_setting('request.jwt.claim.wallet_address', true)
    )
  );

-- Ratings: Public read for rated profiles
CREATE POLICY ratings_public_read ON ratings FOR SELECT USING (TRUE);
CREATE POLICY ratings_own_insert ON ratings FOR INSERT
  WITH CHECK (rater_wallet = current_setting('request.jwt.claim.wallet_address', true));

-- ============================================================================
-- FUNCTIONS & TRIGGERS
-- ============================================================================

-- Update updated_at timestamp automatically
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_profiles_updated_at BEFORE UPDATE ON profiles
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_missions_updated_at BEFORE UPDATE ON missions
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Calculate average rating on new rating insertion
CREATE OR REPLACE FUNCTION update_profile_reputation()
RETURNS TRIGGER AS $$
BEGIN
  UPDATE profiles
  SET reputation_score = (
    SELECT AVG(rating)::DECIMAL(5,2)
    FROM ratings
    WHERE rated_wallet = NEW.rated_wallet
  )
  WHERE wallet_address = NEW.rated_wallet;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_reputation_on_new_rating AFTER INSERT ON ratings
  FOR EACH ROW EXECUTE FUNCTION update_profile_reputation();

-- Increment completed missions count on mission completion
CREATE OR REPLACE FUNCTION increment_completed_missions()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Increment for client
    UPDATE profiles
    SET total_missions_as_client = total_missions_as_client + 1
    WHERE wallet_address = NEW.client_wallet;

    -- Increment for consultant
    IF NEW.selected_consultant_wallet IS NOT NULL THEN
      UPDATE profiles
      SET total_missions_completed = total_missions_completed + 1
      WHERE wallet_address = NEW.selected_consultant_wallet;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER increment_missions_on_completion AFTER UPDATE ON missions
  FOR EACH ROW EXECUTE FUNCTION increment_completed_missions();

-- ============================================================================
-- COMMENTS (Documentation)
-- ============================================================================

COMMENT ON TABLE profiles IS 'Off-chain user profiles with reputation and skills';
COMMENT ON TABLE missions IS 'Marketplace missions/jobs with budget and requirements';
COMMENT ON TABLE mission_applications IS 'Consultant applications to missions';
COMMENT ON TABLE milestones IS 'Sequential milestone definitions with escrow';
COMMENT ON TABLE disputes IS 'Milestone disputes with DAO jury resolution';
COMMENT ON TABLE contributors IS 'Hybrid mission contributors (Human/AI/Compute)';
COMMENT ON TABLE usage_logs IS 'AI/Compute usage metering logs';
COMMENT ON TABLE payments IS 'Payment distribution history';
COMMENT ON TABLE transactions IS 'All blockchain transaction logs';
COMMENT ON TABLE notifications IS 'User notification queue';
COMMENT ON TABLE ratings IS 'Mission completion ratings and reviews';
COMMENT ON TABLE match_scores IS 'Cached on-chain match scores for analytics';
COMMENT ON TABLE pricing_history IS 'Historical usage pricing for missions';
COMMENT ON TABLE webhook_logs IS 'Webhook delivery logs for debugging';

-- ============================================================================
-- SEED DATA (Demo purposes)
-- ============================================================================

-- Insert test profiles (commented out - uncomment for local testing)
-- INSERT INTO profiles (wallet_address, on_chain_rank, github_handle, hourly_rate_daos, skills, reputation_score)
-- VALUES
--   ('0xClient1...', 2, 'client1', NULL, ARRAY['product-management'], 4.5),
--   ('0xConsultant1...', 3, 'consultant1', 50.00, ARRAY['solidity', 'rust', 'security'], 4.8),
--   ('0xConsultant2...', 2, 'consultant2', 35.00, ARRAY['frontend', 'react', 'ui-ux'], 4.2);
