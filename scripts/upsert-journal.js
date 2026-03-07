#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const fp = path.resolve(__dirname, '..', 'data', 'journal.json');
const input = process.argv[2];
if (!input) {
console.error('Usage: node scripts/upsert-journal.js \'{"date":"YYYY-MM-DD","text":"..."}\'');
process.exit(1);
}
const entry = JSON.parse(input);
if (!entry.date) {
console.error('journal entry requires date');
process.exit(1);
}

let db = { source:'canonical', generatedAt:'', entries:[] };
if (fs.existsSync(fp)) db = JSON.parse(fs.readFileSync(fp, 'utf8'));

db.entries = Array.isArray(db.entries) ? db.entries : [];
const idx = db.entries.findIndex(e => e.date === entry.date);
if (idx >= 0) db.entries[idx] = { ...db.entries[idx], ...entry };
else db.entries.push(entry);

db.generatedAt = new Date().toISOString();
fs.writeFileSync(fp, JSON.stringify(db, null, 2));
console.log(`upserted journal ${entry.date}`);
