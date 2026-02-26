-- ============================================================
-- LEAFLET CAMPAIGN - ACTUAL CURRENT SCHEMA
-- Retrieved from Supabase via REST API
-- Date: 2026-02-25
-- ============================================================

-- ============================================================
-- CURRENT TABLES (IN USE)
-- ============================================================

-- Session Log (delivery tracking)
CREATE TABLE IF NOT EXISTS session_log (
    id INTEGER PRIMARY KEY,
    staff1 TEXT,
    staff2 TEXT,
    delivered INTEGER,
    comment TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    went_out BOOLEAN DEFAULT true
);

-- Finance Actual (enquiries/cases tracking)
CREATE TABLE IF NOT EXISTS finance_actuals (
    id INTEGER PRIMARY KEY DEFAULT 1,
    enquiries INTEGER DEFAULT 0,
    cases_instructed INTEGER DEFAULT 0,
    instruction_value NUMERIC(10,2) DEFAULT 0.00,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Rescheduled Sessions
CREATE TABLE IF NOT EXISTS rescheduled_sessions (
    id INTEGER PRIMARY KEY,
    original_id TEXT NOT NULL,
    date_iso TEXT NOT NULL,
    area TEXT,
    postcode TEXT,
    target INTEGER DEFAULT 1000,
    briefing TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- CURRENT DATA (as of 2026-02-25)
-- ============================================================

-- session_log contains: id 0-5 (some delivered, some pending)
-- finance_actuals: id=1, all values 0 (no enquiries/cases yet)
-- rescheduled_sessions: may contain rescheduled session data

-- ============================================================
-- MIGRATION NOTES FOR V2 SCHEMA
-- ============================================================
-- When implementing card-based system, migrate data:
-- 1. Keep session_log as backup
-- 2. Create new tables (campaigns, target_areas, reservations, deliveries, enquiries_new, cases_new)
-- 3. Migrate existing deliveries to new schema
-- 4. NEW enquiries table should have: client_name, postcode, instructed (y/n), value
-- 5. Add campaign_id to all tables for multi-campaign support
-- ============================================================

-- ============================================================
-- NEW SCHEMA (for card-based system - Phase 1 implementation)
-- ============================================================

-- Enable PostGIS
-- CREATE EXTENSION IF NOT EXISTS postgis;

-- Campaigns table (for multi-campaign support)
CREATE TABLE IF NOT EXISTS campaigns (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    start_date DATE,
    end_date DATE,
    target_leaflets INTEGER DEFAULT 30000,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert first campaign (migrate from current setup)
INSERT INTO campaigns (name, target_leaflets) 
VALUES ('Current Campaign', 30000)
ON CONFLICT DO NOTHING;

-- Team members (enhanced from current)
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert current team
INSERT INTO team_members (name) VALUES 
    ('Richard'), ('Josh'), ('Dan'), ('Cahner'), ('Orla')
ON CONFLICT (name) DO NOTHING;

-- Target Areas (card-based chunks)
CREATE TABLE IF NOT EXISTS target_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id),
    area_name TEXT NOT NULL,
    postcode TEXT NOT NULL,
    streets TEXT[] DEFAULT '{}',
    house_count INTEGER DEFAULT 0,
    gps_bounds JSONB,
    google_maps_link TEXT,
    status TEXT DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'completed')),
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Reservations (team reserves area + date)
CREATE TABLE IF NOT EXISTS reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_area_id UUID REFERENCES target_areas(id) ON DELETE CASCADE,
    team_member_1_id UUID REFERENCES team_members(id),
    team_member_2_id UUID REFERENCES team_members(id),
    delivery_date DATE NOT NULL,
    reserved_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'completed')),
    notes TEXT
);

-- Deliveries (completion records)
CREATE TABLE IF NOT EXISTS deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id),
    target_area_id UUID REFERENCES target_areas(id) ON DELETE CASCADE,
    team_member_1_id UUID REFERENCES team_members(id),
    team_member_2_id UUID REFERENCES team_members(id),
    delivery_date DATE NOT NULL,
    leaflets_delivered INTEGER NOT NULL,
    gps_track JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Enquiries (NEW robust structure)
CREATE TABLE IF NOT EXISTS enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id),
    enquiry_date DATE NOT NULL,
    client_name TEXT NOT NULL,
    postcode TEXT NOT NULL,
    instructed BOOLEAN DEFAULT false,
    instruction_value NUMERIC(10,2) DEFAULT 0,
    source TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Cases (linked to enquiries)
CREATE TABLE IF NOT EXISTS cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    campaign_id UUID REFERENCES campaigns(id),
    enquiry_id UUID REFERENCES enquiries(id) ON DELETE SET NULL,
    instruction_date DATE NOT NULL,
    instruction_value NUMERIC(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- RLS POLICIES 
-- ============================================================
-- STATUS: RLS ENABLED on all tables (2026-02-26)
-- Policies: Public read access (no Supabase Auth in use)
-- ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE target_areas ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;
--
-- Policies created:
-- CREATE POLICY "Anyone can read campaigns" ON campaigns FOR SELECT USING (true);
-- CREATE POLICY "Anyone can read target_areas" ON target_areas FOR SELECT USING (true);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_target_areas_status ON target_areas(status);
CREATE INDEX IF NOT EXISTS idx_target_areas_campaign ON target_areas(campaign_id);
CREATE INDEX IF NOT EXISTS idx_reservations_delivery_date ON reservations(delivery_date);
CREATE INDEX IF NOT EXISTS idx_deliveries_delivery_date ON deliveries(delivery_date);
CREATE INDEX IF NOT EXISTS idx_deliveries_campaign ON deliveries(campaign_id);
CREATE INDEX IF NOT EXISTS idx_enquiries_enquiry_date ON enquiries(enquiry_date);
CREATE INDEX IF NOT EXISTS idx_enquiries_campaign ON enquiries(campaign_id);
CREATE INDEX IF NOT EXISTS idx_cases_instruction_date ON cases(instruction_date);
CREATE INDEX IF NOT EXISTS idx_cases_campaign ON cases(campaign_id);

-- ============================================================
-- RPC: Delivery Stats API (Phase 8 T5)
-- Supports date filtering for monthly/quarterly reports
-- ============================================================

-- Function with all parameters
CREATE OR REPLACE FUNCTION get_delivery_stats(
  p_campaign_id UUID DEFAULT NULL,
  p_start_date DATE DEFAULT NULL,
  p_end_date DATE DEFAULT NULL
)
RETURNS JSONB
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  result JSONB;
  v_total_leaflets BIGINT;
  v_leaflets_in_period BIGINT;
  v_leaflets_last_30_days BIGINT;
  v_routes_completed_count BIGINT;
  v_active_routes_count BIGINT;
  v_total_revenue NUMERIC;
  v_revenue_in_period NUMERIC;
  v_enquiries_count BIGINT;
  v_enquiries_in_period BIGINT;
  v_cases_count BIGINT;
  v_cases_in_period BIGINT;
  v_response_rate NUMERIC;
  v_campaign_target NUMERIC;
  v_delivered_so_far NUMERIC;
  v_projected_remaining NUMERIC;
BEGIN
  -- Date filter for period calculations
  -- If start_date provided but not end_date, use start of start_date month to end of start_date month
  IF p_start_date IS NOT NULL AND p_end_date IS NULL THEN
    p_end_date := DATE_TRUNC('month', p_start_date) + INTERVAL '1 month' - INTERVAL '1 day';
  END IF;

  -- Volume metrics (all time)
  SELECT COALESCE(SUM(leaflets_delivered), 0) INTO v_total_leaflets
  FROM deliveries d
  WHERE p_campaign_id IS NULL OR d.campaign_id = p_campaign_id;

  -- Volume metrics (filtered period)
  SELECT COALESCE(SUM(leaflets_delivered), 0) INTO v_leaflets_in_period
  FROM deliveries d
  WHERE (p_campaign_id IS NULL OR d.campaign_id = p_campaign_id)
    AND (p_start_date IS NULL OR d.delivery_date >= p_start_date)
    AND (p_end_date IS NULL OR d.delivery_date <= p_end_date);

  -- Last 30 days (for backwards compatibility)
  SELECT COALESCE(SUM(leaflets_delivered), 0) INTO v_leaflets_last_30_days
  FROM deliveries d
  WHERE (p_campaign_id IS NULL OR d.campaign_id = p_campaign_id)
    AND d.delivery_date >= CURRENT_DATE - INTERVAL '30 days';

  SELECT COUNT(*) INTO v_routes_completed_count
  FROM target_areas ta
  WHERE ta.status = 'completed'
    AND (p_campaign_id IS NULL OR ta.campaign_id = p_campaign_id);

  SELECT COUNT(*) INTO v_active_routes_count
  FROM target_areas ta
  WHERE ta.status = 'reserved'
    AND (p_campaign_id IS NULL OR ta.campaign_id = p_campaign_id);

  -- Financial metrics (all time)
  SELECT COALESCE(SUM(instruction_value), 0) INTO v_total_revenue
  FROM enquiries e
  WHERE e.instructed = true
    AND (p_campaign_id IS NULL OR e.campaign_id = p_campaign_id);

  -- Financial metrics (filtered period)
  SELECT COALESCE(SUM(instruction_value), 0) INTO v_revenue_in_period
  FROM enquiries e
  WHERE e.instructed = true
    AND (p_campaign_id IS NULL OR e.campaign_id = p_campaign_id)
    AND (p_start_date IS NULL OR e.enquiry_date >= p_start_date)
    AND (p_end_date IS NULL OR e.enquiry_date <= p_end_date);

  SELECT COUNT(*) INTO v_enquiries_count
  FROM enquiries e
  WHERE (p_campaign_id IS NULL OR e.campaign_id = p_campaign_id);

  SELECT COUNT(*) INTO v_enquiries_in_period
  FROM enquiries e
  WHERE (p_campaign_id IS NULL OR e.campaign_id = p_campaign_id)
    AND (p_start_date IS NULL OR e.enquiry_date >= p_start_date)
    AND (p_end_date IS NULL OR e.enquiry_date <= p_end_date);

  SELECT COUNT(*) INTO v_cases_count
  FROM enquiries e
  WHERE e.instructed = true
    AND e.instruction_value > 0
    AND (p_campaign_id IS NULL OR e.campaign_id = p_campaign_id);

  SELECT COUNT(*) INTO v_cases_in_period
  FROM enquiries e
  WHERE e.instructed = true
    AND e.instruction_value > 0
    AND (p_campaign_id IS NULL OR e.campaign_id = p_campaign_id)
    AND (p_start_date IS NULL OR e.enquiry_date >= p_start_date)
    AND (p_end_date IS NULL OR e.enquiry_date <= p_end_date);

  -- Calculate rates
  v_response_rate := CASE WHEN v_enquiries_count > 0 THEN (v_cases_count::NUMERIC / v_enquiries_count) * 100 ELSE 0 END;

  -- Get campaign target and calculate projections
  IF p_campaign_id IS NOT NULL THEN
    SELECT c.target_leaflets INTO v_campaign_target
    FROM campaigns c WHERE c.id = p_campaign_id;
  ELSE
    SELECT COALESCE(SUM(c.target_leaflets), 0) INTO v_campaign_target
    FROM campaigns c WHERE c.is_active = true;
  END IF;

  v_delivered_so_far := v_total_leaflets;
  v_projected_remaining := CASE 
    WHEN v_campaign_target > 0 AND v_delivered_so_far > 0 
    THEN (v_campaign_target - v_delivered_so_far) * (v_total_revenue / NULLIF(v_delivered_so_far, 0))
    ELSE 0
  END;

  result := jsonb_build_object(
    'total_leaflets_all_time', v_total_leaflets,
    'leaflets_last_30_days', v_leaflets_last_30_days,
    'leaflets_in_period', v_leaflets_in_period,
    'period_start', p_start_date,
    'period_end', p_end_date,
    'routes_completed_count', v_routes_completed_count,
    'active_routes_count', v_active_routes_count,
    'total_revenue', v_total_revenue,
    'revenue_in_period', v_revenue_in_period,
    'revenue_per_100_leaflets', CASE WHEN v_total_leaflets > 0 THEN (v_total_revenue / v_total_leaflets) * 100 ELSE 0 END,
    'enquiries_count', v_enquiries_count,
    'enquiries_in_period', v_enquiries_in_period,
    'cases_count', v_cases_count,
    'cases_in_period', v_cases_in_period,
    'conversion_rate', v_response_rate,
    'average_case_value', CASE WHEN v_cases_count > 0 THEN v_total_revenue / v_cases_count ELSE 0 END,
    'campaign_target', v_campaign_target,
    'delivered_so_far', v_delivered_so_far,
    'projected_revenue_remaining', v_projected_remaining
  );

  result := jsonb_build_object(
    'total_leaflets_all_time', v_total_leaflets,
    'leaflets_last_30_days', v_leaflets_last_30_days,
    'routes_completed_count', v_routes_completed_count,
    'active_routes_count', v_active_routes_count,
    'total_revenue', v_total_revenue,
    'revenue_per_100_leaflets', CASE WHEN v_total_leaflets > 0 THEN (v_total_revenue / v_total_leaflets) * 100 ELSE 0 END,
    'enquiries_count', v_enquiries_count,
    'enquiries_last_30_days', v_enquiries_last_30_days,
    'cases_count', v_cases_count,
    'conversion_rate', v_response_rate,
    'average_case_value', CASE WHEN v_cases_count > 0 THEN v_total_revenue / v_cases_count ELSE 0 END,
    'campaign_target', v_campaign_target,
    'delivered_so_far', v_delivered_so_far,
    'projected_revenue_remaining', v_projected_remaining
  );

  RETURN result;
END;
$$;
