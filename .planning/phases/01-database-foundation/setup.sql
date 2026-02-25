-- ============================================================
-- PHASE 1: DATABASE FOUNDATION
-- Run this in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- STEP 1: Enable PostGIS (for spatial queries)
-- ============================================================
CREATE EXTENSION IF NOT EXISTS postgis;

-- Verify it's enabled
-- SELECT postgis_full_version();

-- ============================================================
-- STEP 2: Create new tables
-- ============================================================

-- Campaigns table
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

-- Team members
CREATE TABLE IF NOT EXISTS team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

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

-- Reservations
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

-- Deliveries
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

-- Cases
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
-- STEP 3: Insert seed data
-- ============================================================

-- Insert first campaign
INSERT INTO campaigns (name, target_leaflets, is_active) 
VALUES ('Current Campaign', 30000, true)
ON CONFLICT DO NOTHING;

-- Insert team members
INSERT INTO team_members (name) VALUES 
    ('Richard'), ('Josh'), ('Dan'), ('Cahner'), ('Orla')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- STEP 4: Create indexes
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
-- STEP 5: Enable RLS (optional - can be done later)
-- ============================================================

-- Uncomment when ready to enable security:
-- ALTER TABLE campaigns ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE team_members ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE target_areas ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE reservations ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE deliveries ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE enquiries ENABLE ROW LEVEL SECURITY;
-- ALTER TABLE cases ENABLE ROW LEVEL SECURITY;

-- ============================================================
-- VERIFICATION: Check tables created
-- ============================================================
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' ORDER BY table_name;
