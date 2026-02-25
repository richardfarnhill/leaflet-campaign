-- ============================================================
-- LEAFLET CAMPAIGN - NEW DATABASE SCHEMA
-- Run this SQL in Supabase SQL Editor
-- ============================================================

-- ============================================================
-- CAMPAIGN CONFIGURATION TABLES
-- ============================================================

-- Singleton config table
CREATE TABLE campaign_config (
    id INTEGER PRIMARY KEY DEFAULT 1,
    total_leaflets INTEGER NOT NULL DEFAULT 30000,
    default_case_value DECIMAL(10,2) NOT NULL DEFAULT 294.42,
    response_rate_conservative DECIMAL(5,4) NOT NULL DEFAULT 0.0025,
    response_rate_target DECIMAL(5,4) NOT NULL DEFAULT 0.0050,
    response_rate_optimistic DECIMAL(5,4) NOT NULL DEFAULT 0.0075,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert default config
INSERT INTO campaign_config (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- Team members
CREATE TABLE team_members (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Insert current team
INSERT INTO team_members (name) VALUES 
    ('Richard'), 
    ('Josh'), 
    ('Dan'), 
    ('Cahner'),
    ('Orla')
ON CONFLICT (name) DO NOTHING;

-- ============================================================
-- TARGET AREAS (Door chunks - ~1000 sections)
-- NOT linked to dates
-- ============================================================

CREATE TABLE target_areas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    area_name TEXT NOT NULL,
    postcode TEXT NOT NULL,
    streets TEXT[] NOT NULL DEFAULT '{}',
    house_count INTEGER NOT NULL DEFAULT 0,
    gps_bounds JSONB,
    google_maps_link TEXT,
    status TEXT NOT NULL DEFAULT 'available' CHECK (status IN ('available', 'reserved', 'completed')),
    sort_order INTEGER,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_target_areas_status ON target_areas(status);
CREATE INDEX idx_target_areas_postcode ON target_areas(postcode);

-- ============================================================
-- RESERVATIONS (Users reserve card + date)
-- ============================================================

CREATE TABLE reservations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_area_id UUID NOT NULL REFERENCES target_areas(id) ON DELETE CASCADE,
    team_member_1_id UUID NOT NULL REFERENCES team_members(id),
    team_member_2_id UUID REFERENCES team_members(id),
    delivery_date DATE NOT NULL,
    reserved_at TIMESTAMPTZ DEFAULT NOW(),
    status TEXT NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'cancelled', 'completed')),
    notes TEXT
);

-- Indexes
CREATE INDEX idx_reservations_delivery_date ON reservations(delivery_date);
CREATE INDEX idx_reservations_status ON reservations(status);

-- ============================================================
-- DELIVERIES (Record completion)
-- ============================================================

CREATE TABLE deliveries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    target_area_id UUID NOT NULL REFERENCES target_areas(id) ON DELETE CASCADE,
    team_member_1_id UUID NOT NULL REFERENCES team_members(id),
    team_member_2_id UUID REFERENCES team_members(id),
    delivery_date DATE NOT NULL,
    leaflets_delivered INTEGER NOT NULL,
    gps_track JSONB,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes
CREATE INDEX idx_deliveries_delivery_date ON deliveries(delivery_date);

-- ============================================================
-- ENQUIRIES (Date-stamped)
-- ============================================================

CREATE TABLE enquiries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enquiry_date DATE NOT NULL,
    source TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_enquiries_enquiry_date ON enquiries(enquiry_date);

-- ============================================================
-- CASES (Date-stamped)
-- ============================================================

CREATE TABLE cases (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    enquiry_id UUID REFERENCES enquiries(id) ON DELETE SET NULL,
    instruction_date DATE NOT NULL,
    instruction_value DECIMAL(10,2) NOT NULL,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_cases_instruction_date ON cases(instruction_date);

-- ============================================================
-- VIEWS FOR ANALYTICS
-- ============================================================

-- Campaign Status View
CREATE OR REPLACE VIEW v_campaign_status AS
SELECT 
    cc.total_leaflets,
    COALESCE(SUM(d.leaflets_delivered), 0) AS total_delivered,
    cc.total_leaflets - COALESCE(SUM(d.leaflets_delivered), 0) AS remaining,
    COUNT(DISTINCT d.id) AS completed_chunks,
    (SELECT COUNT(*) FROM target_areas WHERE status = 'available') AS available_chunks,
    (SELECT COUNT(*) FROM target_areas WHERE status = 'reserved') AS reserved_chunks
FROM campaign_config cc
LEFT JOIN deliveries d ON true;

-- Deliveries Over Time
CREATE OR REPLACE VIEW v_deliveries_over_time AS
SELECT 
    delivery_date,
    COUNT(*) AS sessions_that_day,
    SUM(leaflets_delivered) AS leaflets_that_day
FROM deliveries
GROUP BY delivery_date
ORDER BY delivery_date;

-- Enquiries Over Time
CREATE OR REPLACE VIEW v_enquiries_over_time AS
SELECT 
    enquiry_date,
    COUNT(*) AS enquiries_that_day
FROM enquiries
GROUP BY enquiry_date
ORDER BY enquiry_date;

-- Revenue Over Time
CREATE OR REPLACE VIEW v_revenue_over_time AS
SELECT 
    instruction_date,
    COUNT(*) AS cases_that_day,
    SUM(instruction_value) AS revenue_that_day
FROM cases
GROUP BY instruction_date
ORDER BY instruction_date;
