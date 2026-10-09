"""Render an object-lineage proposal against the live spine, without changing it."""
from pathlib import Path
from html import escape
import hashlib
import json

import markdown

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
read = lambda p: json.loads(p.read_text(encoding='utf-8'))
spine_file = ROOT / 'commons/maps/curriculum_spine.json'
spine = sorted(read(spine_file)['spine']['sequences'], key=lambda s: s['order'])
objects = read(HERE / 'objects.json')
assert [o['sequence'] for o in objects] == [s['name'] for s in spine]
sources = [spine_file]
cards, table_rows, md = [], [], []
missing_tutorials = []
hall_count = 0
for entry, obj in zip(spine, objects):
    seq_file = ROOT / f"commons/maps/sequences/{entry['name']}.json"
    sources.append(seq_file)
    seq = read(seq_file)['sequences'][entry['name']]
    hall_count += len(seq['maps'])
    assert len(set(obj['maps'])) == len(obj['maps'])
    assert all(m in seq['maps'] for m in obj['maps']), obj['sequence']
    for hall in seq['maps']:
        if not (ROOT / f'commons/maps/{hall}/tutorial.md').exists():
            missing_tutorials.append(hall)
    number, key, title = entry['order'], entry['name'], seq['name']
    table_rows.append(f'<tr><td><a href="#{key}">{number:02d} · {escape(title.split(":")[0])}</a></td><td>{escape(obj["object"])}</td><td>{escape(obj["development"])}</td></tr>')
    hall_links = ' → '.join(f'<a href="http://localhost:3003/tutorial-cards?map={hall}">{escape(hall)}</a>' for hall in obj['maps'])
    cards.append(f'''<article id="{key}"><p class="eyebrow">{number:02d} / {escape(title)} / Proposed object</p><h2>{escape(obj['object'])}</h2><p>{escape(obj['development'])}</p><p><strong>What continues.</strong> {escape(obj['carry'])}</p><p><strong>Where to branch.</strong> {escape(obj['branch'])}</p><details><summary>Relevant halls · {len(obj['maps'])} selected from {len(seq['maps'])}</summary><p class="halls">{hall_links}</p></details><a class="back" href="#overview">Back to overview ↑</a></article>''')
    md.append(f"## {number}. {title}\n\n**Possible object:** {obj['object']}\n\n{obj['development']}\n\n**What continues:** {obj['carry']}\n\n**Where to branch:** {obj['branch']}\n\nSelected halls: " + ' → '.join(f'`{h}`' for h in obj['maps']) + '\n')

for name in ['opening', 'early', 'growth', 'later']:
    sources.append(ROOT / f'doc/book/course/storyboards/{name}.json')
for name in ['lineage-opening', 'lineage-middle', 'lineage-later']:
    sources.append(ROOT / f'doc/book/course/hall-cards/{name}.json')
approach = (HERE / 'APPROACH.md').read_text(encoding='utf-8')
(HERE / 'OBJECTS.md').write_text(approach + '\n\n---\n\n' + '\n'.join(md), encoding='utf-8')
intro = markdown.markdown(approach, extensions=['extra'])
css = '''
:root{color-scheme:light;--paper:#f6f3ed;--ink:#282d2a;--muted:#646c64;--accent:#84445d;--line:#d7d4ca}
*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.75 system-ui,sans-serif}
header,footer{padding:20px 4vw;border-bottom:1px solid var(--line);font-size:12px}header{display:flex;justify-content:space-between;gap:18px;flex-wrap:wrap}nav{display:flex;gap:22px;flex-wrap:wrap}
main{max-width:1200px;margin:50px auto;padding:0 26px}h1,h2{font-family:Georgia,serif;font-weight:400;line-height:1.13}h1{font-size:clamp(42px,6vw,76px);letter-spacing:-.035em}h2{font-size:30px;margin-top:18px}
.intro{max-width:790px}.intro p{margin:22px 0}.intro>p:first-of-type,.eyebrow{font-size:12px;color:var(--muted)}.status{background:#e9e7dc;padding:18px 22px;border-left:3px solid #8b8e70}
a{color:var(--accent);text-underline-offset:4px}a:focus-visible,summary:focus-visible{outline:2px solid var(--accent);outline-offset:4px}
#overview{scroll-margin-top:25px;margin-top:70px}.table-wrap{overflow:auto}table{border-collapse:collapse;width:100%;font-size:14px}th,td{text-align:left;vertical-align:top;border-bottom:1px solid var(--line);padding:16px 14px}th{font-size:11px;text-transform:uppercase;letter-spacing:.07em}td:first-child{width:22%}td:nth-child(2){width:29%;font-weight:600}tbody tr:hover{background:#eee7e1}
.cards{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:24px;margin:60px 0}article{scroll-margin-top:25px;border:1px solid var(--line);background:#fffdf8;padding:28px}article p{font-size:15px}.eyebrow{letter-spacing:.04em}.halls{overflow-wrap:anywhere;font:12px/2 Consolas,monospace}summary{cursor:pointer;color:var(--accent);font-size:13px}.back{display:inline-block;margin-top:15px;font-size:12px}
pre{overflow:auto;padding:20px;background:#eae6de;font-size:13px}code{font-family:Consolas,monospace}footer{border-top:1px solid var(--line);border-bottom:0}li{margin:12px 0}
@media(max-width:760px){main{padding:0 19px}.cards{grid-template-columns:1fr}article{padding:23px}table{min-width:690px}h2{font-size:28px}}
@media print{body{background:white;font-size:10pt}header,footer,.back{display:none}main{margin:0;padding:0;max-width:none}.cards{display:block}article{break-inside:avoid;margin:16px 0}h1{font-size:32pt}table{font-size:9pt}th,td{padding:9px}a{color:inherit}.table-wrap{overflow:visible}}
'''
page = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Objects that continue | Endless Museum</title><style>{css}</style></head><body><header><span>ADA / TUTORIAL LINEAGE / PROPOSAL</span><nav><a href="#overview">25 sequences</a><a href="OBJECTS.md">Full text</a><a href="objects.json">Editable candidates</a><a href="../2026-10-05-the-tutorial-must-run/index.html">The tutorial must run</a></nav></header><main><div class="intro">{intro}</div><section id="overview"><h2>Possible objects, in the current spine order</h2><p class="status">{len(spine)} sequences · {hall_count} live halls. These are candidate student builds. The tested Point One → Coordinates → Lines → Trace chain is the current example; the later journeys are proposals.</p><div class="table-wrap"><table><thead><tr><th>Sequence</th><th>Possible student object</th><th>How it develops</th></tr></thead><tbody>{''.join(table_rows)}</tbody></table></div></section><div class="cards">{''.join(cards)}</div></main><footer>5 October 2026 · Read against live sequence definitions, authored storyboards and tutorial subjects. No lessons, game logic or sequence order changed. This report does not establish implemented transfer or learner mastery.</footer></body></html>'''
(HERE / 'index.html').write_text(page, encoding='utf-8')
evidence = {'date':'2026-10-05','status':'proposal','sequences':len(spine),'live_halls':hall_count,'selected_hall_references':sum(len(o['maps']) for o in objects),'all_references_in_their_live_sequence':True,'native_tests_run':False,'missing_tutorial_files_in_live_spine':missing_tutorials,'sources':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in sources},'objects_sha256':hashlib.sha256((HERE/'objects.json').read_bytes()).hexdigest(),'approach_sha256':hashlib.sha256((HERE/'APPROACH.md').read_bytes()).hexdigest()}
(HERE / 'source-checks.json').write_text(json.dumps(evidence,indent=2)+'\n',encoding='utf-8')
print(json.dumps({k:v for k,v in evidence.items() if k!='sources'}))
