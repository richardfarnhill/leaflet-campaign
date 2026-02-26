const fs = require('fs');
const content = fs.readFileSync('C:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/multi_csv/ONSPD_NOV_2025_UK_WF.csv', 'utf8');
const lines = content.split('\n');
const pcds_idx = 2, ctry_idx = 16, oa_idx = 49;

function parseCSVLine(line) {
  const result = [];
  let current = '';
  let inQuotes = false;
  for (let i = 0; i < line.length; i++) {
    const c = line[i];
    if (c === '"') { inQuotes = !inQuotes; }
    else if (c === ',' && !inQuotes) { result.push(current); current = ''; }
    else { current += c; }
  }
  result.push(current);
  return result;
}

const rows = [];
for (let i = 1; i < lines.length; i++) {
  if (!lines[i].trim()) continue;
  const cols = parseCSVLine(lines[i]);
  const ctry = cols[ctry_idx];
  if (ctry === 'E92000001' || ctry === 'W92000004') {
    rows.push([cols[pcds_idx].trim(), cols[oa_idx].trim()]);
  }
}
console.log('Filtered rows:', rows.length);

const BATCH_SIZE = 2000;
for (let i = 0; i < rows.length; i += BATCH_SIZE) {
  const batch = rows.slice(i, i + BATCH_SIZE);
  const vals = batch.map(r => {
    const pc = r[0].replace(/'/g, "''");
    const oa = r[1].replace(/'/g, "''");
    return "('" + pc + "','" + oa + "')";
  }).join(',');
  const sql = "INSERT INTO postcode_oa_lookup (postcode, oa21_code) VALUES " + vals + " ON CONFLICT (postcode) DO NOTHING;";
  const batchNum = Math.floor(i / BATCH_SIZE);
  fs.writeFileSync('/tmp/wf_batch_' + batchNum + '.sql', sql);
  console.log('Wrote batch', batchNum, 'with', batch.length, 'rows');
}
