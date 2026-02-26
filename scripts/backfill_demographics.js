/**
 * Backfill Script: Enrich historic demographic_feedback rows with owner_occupied_pct from NOMIS
 * 
 * Usage: node scripts/backfill_demographics.js
 * 
 * Environment variables required:
 * - SUPABASE_URL: Your Supabase project URL
 * - SUPABASE_KEY: Your Supabase service role key
 * 
 * What it does:
 * 1. Fetches all demographic_feedback rows where owner_occupied_pct IS NULL AND oa21_code IS NOT NULL
 * 2. For each row, calls NOMIS API to get owner_occupied_pct
 * 3. Updates the row with the fetched percentage
 * 4. Logs progress
 */

const { createClient } = require('../node_modules/@supabase/supabase-js');

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

if (!supabaseUrl || !supabaseKey) {
  console.error('Error: SUPABASE_URL and SUPABASE_KEY environment variables required');
  console.error('Usage: SUPABASE_URL=https://xxx.supabase.co SUPABASE_KEY=xxx node scripts/backfill_demographics.js');
  process.exit(1);
}

const supabase = createClient(supabaseUrl, supabaseKey);

// Fetch owner-occupied percentage from NOMIS for a given oa21_code
async function fetchOwnerOccupiedFromNOMIS(oa21Code) {
  if (!oa21Code) return null;
  try {
    // NM_2072_1 = TS054 Tenure dataset
    // c2021_tenure_9=1001 = "Owned" (owner-occupied)
    // measures=20301 = Percentage
    const url = 'https://www.nomisweb.co.uk/api/v01/dataset/NM_2072_1.data.json' +
      '?geography=' + encodeURIComponent(oa21Code) +
      '&c2021_tenure_9=1001' +
      '&measures=20301' +
      '&select=geography_code,obs_value';
    
    const res = await fetch(url);
    if (!res.ok) return null;
    const data = await res.json();
    if (data.obs && data.obs[0] && data.obs[0].obs_value) {
      return parseFloat(data.obs[0].obs_value.value);
    }
    return null;
  } catch (e) {
    console.warn('NOMIS fetch failed for ' + oa21Code + ':', e.message);
    return null;
  }
}

async function backfill() {
  console.log('Starting demographic backfill...\n');

  // Fetch all rows needing enrichment
  const { data: rows, error: fetchError } = await supabase
    .from('demographic_feedback')
    .select('id, oa21_code')
    .is('owner_occupied_pct', null)
    .not('oa21_code', 'is', null);

  if (fetchError) {
    console.error('Error fetching rows:', fetchError);
    process.exit(1);
  }

  console.log(`Found ${rows.length} rows to backfill\n`);

  let successCount = 0;
  let failCount = 0;
  let skipCount = 0;

  for (let i = 0; i < rows.length; i++) {
    const row = rows[i];
    
    // Rate limit to avoid overwhelming NOMIS API
    if (i > 0 && i % 10 === 0) {
      console.log(`Processed ${i}/${rows.length} rows...`);
      await new Promise(resolve => setTimeout(resolve, 500)); // 500ms delay every 10 requests
    }

    const pct = await fetchOwnerOccupiedFromNOMIS(row.oa21_code);
    
    if (pct !== null) {
      const { error: updateError } = await supabase
        .from('demographic_feedback')
        .update({ owner_occupied_pct: pct })
        .eq('id', row.id);

      if (updateError) {
        console.error(`Failed to update ${row.id}:`, updateError);
        failCount++;
      } else {
        successCount++;
        if (successCount <= 5) {
          console.log(`  Updated ${row.id} (${row.oa21_code}): ${pct}% owner-occupied`);
        }
      }
    } else {
      skipCount++;
      if (skipCount <= 3) {
        console.log(`  Skipped ${row.id} (${row.oa21_code}): no data from NOMIS`);
      }
    }
  }

  console.log(`\n=== Backfill Complete ===`);
  console.log(`Total rows: ${rows.length}`);
  console.log(`Enriched: ${successCount}`);
  console.log(`Skipped (no data): ${skipCount}`);
  console.log(`Failed: ${failCount}`);

  // Final stats
  const { data: finalStats } = await supabase
    .from('demographic_feedback')
    .select('id', { count: 'exact' });
  
  const { data: enrichedStats } = await supabase
    .from('demographic_feedback')
    .select('id', { count: 'exact' })
    .not('owner_occupied_pct', 'is', null);

  console.log(`\nTotal demographic_feedback rows: ${finalStats.length}`);
  console.log(`Rows with owner_occupied_pct: ${enrichedStats.length}`);
}

backfill().catch(console.error);
