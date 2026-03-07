#!/usr/bin/env node
const mode = process.argv[2];
const raw = process.argv[3];
if (!mode || !raw) {
  console.error('usage: node scripts/validate-entry.js <trade|journal> <json>');
  process.exit(2);
}

let obj;
try { obj = JSON.parse(raw); } catch {
  console.error('invalid JSON payload');
  process.exit(2);
}

function fail(msg){ console.error(msg); process.exit(1); }

if (mode === 'trade') {
  const required = ['id','date','symbol','side'];
  for (const k of required) if (!obj[k]) fail(`trade missing required field: ${k}`);
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(obj.date))) fail('trade.date must be YYYY-MM-DD');

  const side = String(obj.side).toUpperCase();
  if (!['LONG','SHORT'].includes(side)) fail('trade.side must be LONG or SHORT');
  obj.side = side;

  const nums = ['entry','stop','target','exit','qty','pnl','commission','r'];
  for (const k of nums) {
    if (obj[k] !== undefined && obj[k] !== null && obj[k] !== '') {
      const n = Number(obj[k]);
      if (!Number.isFinite(n)) fail(`trade.${k} must be numeric`);
      obj[k] = n;
    }
  }

  if (obj.qty !== undefined && obj.qty <= 0) fail('trade.qty must be > 0');
  console.log(JSON.stringify(obj));
  process.exit(0);
}

if (mode === 'journal') {
  if (!obj.date) fail('journal missing required field: date');
  if (!/^\d{4}-\d{2}-\d{2}$/.test(String(obj.date))) fail('journal.date must be YYYY-MM-DD');

  if (obj.mood !== undefined && obj.mood !== null && obj.mood !== '') {
    const m = String(obj.mood).trim();
    if (!/^\d{1,2}(\/10)?$/.test(m)) fail('journal.mood must look like 7/10 or 7');
    obj.mood = m.includes('/') ? m : `${m}/10`;
  }

  console.log(JSON.stringify(obj));
  process.exit(0);
}

fail('mode must be trade or journal');
