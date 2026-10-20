"""Capture source inventory and render the authored, dated audit. No Godot execution."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib
import html
import json
import re
import sys
from urllib.parse import urlparse, unquote

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
sys.path.insert(0, str(ROOT / "tools"))
import museum_connections


def receipt(relative):
    path = ROOT / relative
    if not path.is_file():
        return {"path": relative, "exists": False, "sha256": None}
    raw = path.read_bytes()
    text = raw.decode("utf-8-sig")
    return {"path": relative, "exists": True, "sha256": hashlib.sha256(raw).hexdigest(),
            "words": len(text.split())}


route = museum_connections.route(ROOT)
inventory = {"captured_at": datetime.now(timezone.utc).isoformat(),
             "method": "Source inventory, 24 boundary readings and selected close comparisons. No new Godot/headset test. Word counts are not quality scores.",
             "route_sources": [receipt("commons/maps/curriculum_spine.json")],
             "sequences": []}
for seq in route:
    inventory["route_sources"].append(receipt(seq["source"]))
    inventory["sequences"].append({"id": seq["id"], "halls": [
        {"map": sid[4:], "sources": {kind: receipt(f"commons/maps/{sid[4:]}/{kind}")
                                    for kind in ("tutorial.md", "final.md", "map_data.json")}}
        for sid in seq["halls"]]})
inventory["sequence_count"] = len(route)
inventory["hall_count"] = sum(len(s["halls"]) for s in route)
text = (HERE / "REPORT.md").read_text(encoding="utf-8")
body = markdown.markdown(text, extensions=["tables", "toc", "fenced_code"])
for href in re.findall(r'href="([^"]+)"', body):
    parsed = urlparse(html.unescape(href))
    if not parsed.scheme and parsed.path:
        target = (HERE / unquote(parsed.path)).resolve()
        if not target.exists():
            raise SystemExit(f"Broken local report link: {href}")
assert inventory["sequence_count"] == 25 and inventory["hall_count"] == 206
assert body.count("<tbody>") == 1
body = body.replace("<table>", '<div class="table-wrap"><table>')
body = body.replace("</table>", "</table></div>")
page = """<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>Whole-spine connections · Endless Museum</title>
<style>
:root{color-scheme:light;--paper:#f6f3ee;--ink:#242525;--muted:#59615e;--line:#d4d6ce;--pink:#a32e59}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}
header{padding:1rem clamp(1.2rem,5vw,5rem);border-bottom:1px solid var(--line);display:flex;gap:1.5rem;flex-wrap:wrap;align-items:center}
header b{letter-spacing:.13em;font-size:.8rem;margin-right:auto}a{color:#783451;text-underline-offset:3px}a:hover{color:#3b1425}
main{max-width:1180px;margin:auto;padding:2.5rem 2rem 5rem}h1{font:500 clamp(2.2rem,5vw,3.8rem)/1.13 Georgia,serif;max-width:950px;letter-spacing:-.025em}
h2{font:500 2rem/1.2 Georgia,serif;border-top:1px solid var(--line);padding-top:2rem;margin-top:3rem;scroll-margin-top:1rem}
h3{font-size:1.3rem;line-height:1.4;margin-top:2rem}p,li{max-width:850px}main>p:nth-of-type(1){color:var(--muted);font-size:.9rem}
code{font-size:.84em;overflow-wrap:anywhere;background:#eae7e1;padding:.1em .25em;border-radius:3px}
.stats{display:flex;gap:.6rem;flex-wrap:wrap;margin:1.2rem 0 2rem}.stats span{padding:.4rem .7rem;border:1px solid var(--line);border-radius:4px;font-size:.84rem}
.toc-nav{display:flex;gap:.7rem;flex-wrap:wrap;margin-bottom:2rem}.toc-nav a,button{font:inherit;font-size:.88rem;padding:.5rem .8rem;border:1px solid var(--line);background:transparent;border-radius:5px}
button{cursor:pointer;color:var(--ink)}button[aria-pressed=true]{background:var(--ink);color:var(--paper)}.filters{display:flex;gap:.5rem;margin:1rem 0}.table-wrap{overflow:auto;border:1px solid var(--line);border-radius:6px}
table{border-collapse:collapse;width:100%;font-size:.88rem;line-height:1.55}th,td{text-align:left;vertical-align:top;padding:1rem;border-bottom:1px solid var(--line)}th{background:#e7e8df}td:first-child{min-width:155px;font-weight:650}td:nth-child(2){min-width:280px}td:nth-child(3){min-width:280px}tr[data-priority=true]{background:#f5e7e7}tr[hidden]{display:none}
.status{display:block;font-weight:400;font-size:.72rem;color:var(--pink);margin-top:.3rem}footer{max-width:1180px;margin:auto;padding:0 2rem 3rem;color:var(--muted);font-size:.85rem}
@media(max-width:700px){main{padding:1.4rem 1rem 3rem}h2{font-size:1.65rem}header{padding:1rem}header a{font-size:.85rem}}
@media print{body{background:white;font-size:10pt}header,.toc-nav,.filters{display:none}main{padding:0;max-width:none}h1{font-size:25pt}h2{font-size:18pt}h3{break-after:avoid}tr{break-inside:avoid}table{font-size:9pt}tr[hidden]{display:table-row}.table-wrap{overflow:visible}a{color:inherit}footer{display:none}}
</style></head><body><header><b>ENDLESS MUSEUM / READING THE WHOLE</b>
<a href="http://localhost:3003/museum-memory?scope=project&amp;view=overview">Museum Memory</a>
<a href="http://localhost:3003/project-memory?scope=project">Findings &amp; notes</a>
<a href="REPORT.md">Markdown report</a><a href="inventory.json">Source inventory</a></header><main>
<nav class="toc-nav" aria-label="Report sections"><a href="#what-to-improve-first">Priorities</a><a href="#all-25-sequences-in-the-live-order">All 25 sequences</a><a href="#three-connections-worth-making-unmistakable">Cross-domain threads</a><a href="#the-next-pass">Next pass</a></nav>
BODY
</main><footer>Read-only audit of the museum and book. Findings are proposals. No lesson, reflection, map, artifact or spine order was changed.</footer>
<script>
const priority=new Set(['Transformation','Arrays','Colour','Change','Form Finding','Noise','Isosurfaces','Boolean Surfaces','QFEP Laboratory','Post-foundations']);
const rows=[...document.querySelectorAll('tbody tr')];
rows.forEach(row=>{const name=row.cells[0].textContent.split(' · ')[0];row.dataset.priority=String(priority.has(name));if(priority.has(name)){const label=document.createElement('span');label.className='status';label.textContent='Making-track gap or mismatch';row.cells[0].append(label)}});
const panel=document.createElement('div');panel.className='filters';panel.setAttribute('role','group');panel.setAttribute('aria-label','Filter sequence reading');
['All sequences','Priority gaps'].forEach((label,i)=>{const b=document.createElement('button');b.textContent=label;b.type='button';b.setAttribute('aria-pressed',String(i===0));b.onclick=()=>{panel.querySelectorAll('button').forEach(x=>x.setAttribute('aria-pressed',String(x===b)));rows.forEach(r=>r.hidden=i===1&&r.dataset.priority!=='true')};panel.append(b)});
document.querySelector('.table-wrap').before(panel);
</script></body></html>""".replace("BODY", body)
(HERE / "inventory.json").write_text(json.dumps(inventory,ensure_ascii=False,indent=2)+"\n",encoding="utf-8")
(HERE / "index.html").write_text(page,encoding="utf-8")
missing=[h["map"]+"/"+k for s in inventory["sequences"] for h in s["halls"] for k,v in h["sources"].items() if not v["exists"]]
print(json.dumps({"sequences":len(route),"halls":inventory["hall_count"],"missing":missing,"report_words":len(text.split()),"local_links":"all resolve"}))
