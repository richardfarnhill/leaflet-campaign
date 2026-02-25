-- ============================================================
-- PHASE 1: DATA MIGRATION
-- Run this AFTER phase1-setup.sql has completed
-- ============================================================

-- ============================================================
-- STEP 1: Get the campaign ID (for linking data)
-- ============================================================
-- Let's assume we have one campaign with id = 'current-campaign-id'
-- You'll need to update the campaign_id in the queries below

-- ============================================================
-- STEP 2: Migrate session_log to target_areas + deliveries
-- ============================================================

-- First, let's insert the existing sessions as target areas
-- This maps the old session-based data to new area-based structure
INSERT INTO target_areas (campaign_id, area_name, postcode, house_count, status, notes)
SELECT 
    (SELECT id FROM campaigns LIMIT 1),  -- Use first campaign
    area,
    postcode,
    target,
    CASE 
        WHEN delivered IS NOT NULL AND delivered > 0 THEN 'completed'
        WHEN went_out = true THEN 'reserved'
        ELSE 'available'
    END,
    briefing
FROM (
    VALUES
    (1, 'Wilmslow — Dean Row (kickoff)', 'SK9 2BY', 500),
    (2, 'Wilmslow — Dean Row (continued)', 'SK9 2BY', 1000),
    (3, 'Wilmslow → Lacey Green (transition)', 'SK9 5BP', 1000),
    (4, 'Wilmslow — Lacey Green', 'SK9 5BP', 1000),
    (5, 'Knutsford — Mobberley Village', 'WA16 7HE', 1000),
    (6, 'Knutsford — Cross Town (Manor Park)', 'WA16 8DB', 1000),
    (7, 'Knutsford — Cross Town (completion)', 'WA16 8DB', 1000),
    (8, 'Lymm — Booths Hill', 'WA13 0DL', 1000),
    (9, 'Lymm — Booths Hill to Statham', 'WA13 9BP', 1000)
) AS sessions(id, area_name, postcode, house_count, briefing)
WHERE id IN (SELECT id FROM session_log WHERE went_out = true);

-- ============================================================
-- STEP 3: Migrate delivered sessions to deliveries table
-- ============================================================

-- Insert deliveries for completed sessions
INSERT INTO deliveries (campaign_id, target_area_id, team_member_1_id, team_member_2_id, delivery_date, leaflets_delivered, notes)
SELECT 
    (SELECT id FROM campaigns LIMIT 1),
    ta.id,
    tm1.id,
    tm2.id,
    sl.updated_at::DATE,
    COALESCE(sl.delivered, ta.house_count),
    sl.comment
FROM session_log sl
LEFT JOIN target_areas ta ON ta.area_name LIKE sl.area || '%'
LEFT JOIN team_members tm1 ON tm1.name = sl.staff1
LEFT JOIN team_members tm2 ON tm2.name = sl.staff2
WHERE sl.delivered IS NOT NULL AND sl.delivered > 0;

-- ============================================================
-- STEP 4: Verify migration
-- ============================================================

-- Check target areas
-- SELECT * FROM target_areas;

-- Check deliveries
-- SELECT d.*, ta.area_name, tm1.name as team_member_1
-- FROM deliveries d
-- JOIN target_areas ta ON d.target_area_id = ta.id
-- LEFT JOIN team_members tm1 ON d.team_member_1_id = tm1.id;

-- Check counts
-- SELECT 
--     (SELECT COUNT(*) FROM target_areas) as target_areas_count,
--     (SELECT COUNT(*) FROM deliveries) as deliveries_count,
--     (SELECT COUNT(*) FROM team_members) as team_members_count,
--     (SELECT COUNT(*) FROM campaigns) as campaigns_count;

-- ============================================================
-- STEP 5: Keep old tables as backup (DO NOT DROP)
-- ============================================================
-- session_log, finance_actuals, rescheduled_sessions remain as backup
-- Can be dropped after verifying migration is successful

-- ============================================================
-- ROLLBACK (if needed)
-- ============================================================
-- DROP TABLE IF EXISTS cases CASCADE;
-- DROP TABLE IF EXISTS enquiries CASCADE;
-- DROP TABLE IF EXISTS deliveries CASCADE;
-- DROP TABLE IF EXISTS reservations CASCADE;
-- DROP TABLE IF EXISTS target_areas CASCADE;
-- DROP TABLE IF EXISTS team_members CASCADE;
-- DROP TABLE IF EXISTS campaigns CASCADE;
