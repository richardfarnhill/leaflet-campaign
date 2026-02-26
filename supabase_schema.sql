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
-- CURRENT STATUS: RLS is NOT enabled on any tables
-- This is a SECURITY CONCERN for production use
-- 
-- To enable RLS, run these commands in Supabase SQL Editor:
-- ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE target_areas ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cases ENABLE ROW LEVEL SECURITY;
--
-- Then create policies, e.g.:
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
