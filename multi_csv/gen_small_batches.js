const fs = require('fs');
const path = require('path');
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

// Output all rows as a JSON array for programmatic use
fs.writeFileSync(
  'C:/Users/richa/Dev Projects/projects/leaflet-campaign/leaflet-campaign/multi_csv/wf_rows.json',
  JSON.stringify(rows)
);
console.log('Written wf_rows.json');
