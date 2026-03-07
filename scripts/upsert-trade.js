#!/usr/bin/env node
const fs = require('fs');
const path = require('path');

const fp = path.resolve(__dirname, '..', 'data', 'trades.json');
const input = process.argv[2];
if (!input) {
console.error('Usage: node scripts/upsert-trade.js \'{"id":"...","date":"YYYY-MM-DD",...}\'');
process.exit(1);
}
const trade = JSON.parse(input);

let db = { source:'canonical', generatedAt:'', trades:[], journal:[] };
if (fs.existsSync(fp)) db = JSON.parse(fs.readFileSync(fp, 'utf8'));

db.trades = Array.isArray(db.trades) ? db.trades : [];
const id = trade.id || `MAN-${Date.now()}`;
trade.id = id;

const idx = db.trades.findIndex(t => t.id === id);
if (idx >= 0) db.trades[idx] = { ...db.trades[idx], ...trade };
else db.trades.push(trade);

db.generatedAt = new Date().toISOString();
fs.writeFileSync(fp, JSON.stringify(db, null, 2));
console.log(`upserted trade ${id}`);
