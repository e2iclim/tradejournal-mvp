import csv, json
from datetime import datetime

csv_path = "Performance_4---a843e9fc-137f-4155-b662-9855afd80670.csv"
json_path = "data/trades.json"

def pnl_to_num(s):
s = s.strip().replace("$", "").replace(",", "")
if s.startswith("(") and s.endswith(")"):
return -float(s[1:-1])
return float(s)

with open(json_path, "r", encoding="utf-8") as f:
db = json.load(f)

trades = db.get("trades", [])
existing_fill_ids = {str(t.get("buyFillId", "")) for t in trades}

with open(csv_path, newline="", encoding="utf-8") as f:
rows = list(csv.DictReader(f))

added = 0
for r in rows:
buy_fill = str(r["buyFillId"]).strip()
if buy_fill in existing_fill_ids:
continue

dt = datetime.strptime(r["boughtTimestamp"], "%m/%d/%Y %H:%M:%S")
date = dt.strftime("%Y-%m-%d")
pnl = pnl_to_num(r["pnl"])
side = "Long" if float(r["sellPrice"]) >= float(r["buyPrice"]) else "Short"
tid = f"CSV-{date.replace('-', '')}-{buy_fill}"

trades.append({
"id": tid,
"date": date,
"symbol": r["symbol"],
"side": side,
"setup": "CSV Import",
"qty": int(float(r["qty"])),
"entry": float(r["buyPrice"]),
"exit": float(r["sellPrice"]),
"pnl": pnl,
"commission": 1,
"r": 0,
"tags": [],
"notes": r.get("duration", ""),
"buyFillId": r["buyFillId"],
"sellFillId": r["sellFillId"],
"boughtTimestamp": r["boughtTimestamp"],
"soldTimestamp": r["soldTimestamp"],
"source": "csv-manual-import"
})
added += 1

db["trades"] = trades
with open(json_path, "w", encoding="utf-8") as f:
json.dump(db, f, indent=2)
f.write("\n")

print(f"Added {added} new trades.")
