"""Render the editable Forces proposal; no museum or manuscript mutations."""
from pathlib import Path
from html import escape
from html.parser import HTMLParser
from urllib.parse import urlsplit, unquote
import hashlib
import json
import markdown

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
stages = json.loads((OUT / 'encounters.json').read_text(encoding='utf-8'))
plan = (OUT / 'PLAN.md').read_text(encoding='utf-8')
cards = []
nav = []
for i, s in enumerate(stages, 1):
    e = {k: escape(v) if isinstance(v, str) else v for k, v in s.items()}
    nav.append(f'<a href="#{e["id"]}"><span>{i:02}</span>{e["ability"]}</a>')
    media = (f'<a href="{e["image"]}"><img loading="lazy" src="{e["image"]}" alt="{e["caption"]}"></a>'
             if e['image'] else '<div class="proposal"><span class="orb"></span><span class="orb small"></span><p>PROPOSED ENCOUNTER<br>No runtime image yet</p></div>')
    cards.append(f'''<section class="encounter" id="{e['id']}">
      <figure>{media}<figcaption>{e['caption']}</figcaption></figure>
      <div class="lesson"><p class="eyebrow">{i:02} / {e['ability']}</p><h2>{e['title']}</h2>
      <p class="subject">{e['subject']}</p><p class="story">{e['story']}</p>
      <blockquote>{e['reflection']}</blockquote>
      <dl><dt>What travels onward</dt><dd>{e['carry']}</dd><dt>Learner's own move</dt><dd>{e['variation']}</dd></dl>
      <details><summary>Test obligation + short AI brief</summary><p>{e['test']}</p><pre>{e['short']}</pre><p>Acceptance criteria proposed; not yet executed.</p></details>
      </div></section>''')
body = markdown.markdown(plan, extensions=['tables', 'fenced_code', 'toc'])
style = '''
:root{--ink:#24262a;--paper:#f4f1e9;--accent:#9b3558;--muted:#64615d}*{box-sizing:border-box}html{scroll-behavior:smooth;scroll-padding-top:80px}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.65 system-ui,sans-serif}a{color:var(--accent)}header,main{max-width:1250px;margin:auto;padding:36px}header{padding-top:70px}.eyebrow{text-transform:uppercase;letter-spacing:.16em;font-size:12px;font-weight:700;color:var(--accent)}h1{font:clamp(46px,6vw,86px)/1.04 Georgia,serif;letter-spacing:-.04em;max-width:900px;margin:18px 0 24px}h2{font:35px/1.12 Georgia,serif;letter-spacing:-.02em;margin:10px 0 18px}h3{font-size:23px;margin-top:35px}.lead{font-size:23px;max-width:800px;line-height:1.5}.status{font-size:14px;max-width:880px;color:var(--muted);border-left:3px solid var(--accent);padding:10px 18px}.route{display:grid;grid-template-columns:repeat(8,1fr);gap:6px;margin:32px 0}.route a{text-decoration:none;border-top:2px solid var(--ink);font-weight:600;padding:12px 4px;font-size:14px}.route span{display:block;color:var(--muted);font-size:11px}nav{position:sticky;top:0;background:#f4f19ef5;background:rgba(244,241,233,.97);z-index:5;border-block:1px solid #d5d1c8;padding:12px 24px;display:flex;gap:24px;justify-content:center;flex-wrap:wrap;font-size:14px}nav a{text-decoration:none}.encounter{display:grid;grid-template-columns:minmax(0,1fr) minmax(0,1.1fr);gap:48px;padding:55px 0;border-bottom:1px solid #cdc8bc;scroll-margin-top:60px}figure{margin:0}img{display:block;width:100%;height:auto;border:1px solid #d5d1c8}figcaption{font-size:12px;line-height:1.5;color:var(--muted);margin-top:12px}.subject{font-size:14px;letter-spacing:.03em;color:var(--accent)}.story{font-size:18px}blockquote{font:25px/1.4 Georgia,serif;border-left:2px solid var(--accent);margin:28px 0;padding-left:20px}dt{font-size:11px;font-weight:bold;text-transform:uppercase;letter-spacing:.1em;margin-top:18px}dd{margin:5px 0;font-size:15px}details{border-top:1px solid #ccc;padding-top:16px;margin-top:22px;font-size:14px}summary{cursor:pointer;font-weight:600}pre{white-space:pre-wrap;overflow-wrap:anywhere;font-size:12px;line-height:1.6;background:#e9e5dc;padding:16px}.proposal{min-height:350px;background:#25272b;display:flex;align-items:center;justify-content:center;gap:35px;position:relative}.orb{display:block;width:104px;height:104px;border-radius:100%;background:radial-gradient(circle at 35% 25%,#bbb 0%,#333 27%,#0b0c0e 67%);box-shadow:10px 15px 30px #111}.small{width:78px;height:78px}.proposal p{position:absolute;bottom:18px;color:#d2c8bc;font-size:10px;text-align:center;letter-spacing:.13em}.report{max-width:950px;margin:80px auto}.report h1{font-size:43px}.report h2{margin-top:50px}.report table{border-collapse:collapse;font-size:14px;width:100%;display:block;overflow-x:auto}.report th,.report td{border-bottom:1px solid #d0ccbf;padding:12px;text-align:left;vertical-align:top;min-width:170px}.report code{font-size:.86em;overflow-wrap:anywhere}footer{padding:30px 0;border-top:1px solid #ccc;font-size:13px;color:var(--muted)}@media(max-width:760px){header,main{padding:24px}.route{grid-template-columns:repeat(4,1fr)}.encounter{grid-template-columns:1fr;gap:26px}.lesson{order:-1}figure{max-width:520px}nav{gap:14px}.lead{font-size:20px}}@media print{nav{position:static}details{display:block}.encounter{break-inside:avoid}a{color:inherit}}
'''
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Forces — the point gains power</title><style>{style}</style></head><body>
<header><p class="eyebrow">Endless Museum / Forces / Proposal · 6 October 2026</p><h1>The point gains power.</h1><p class="lead">First it moves. Then it moves you. The sphere returns in each room with one more capacity.</p><p class="status">Eight proposed encounters, grounded in the existing museum. No runtime, canonical tutorial or sequence-order changes in this pass. The new comic plates are concept illustrations; abilities remain proposals.</p><div class="route">{''.join(nav)}</div></header>
<nav aria-label="Report sections"><a href="#route">Eight encounters</a><a href="#the-enemies-i-would-choose">Enemies</a><a href="#what-moves-where">Existing halls</a><a href="#first-build-and-its-evidence">First build</a><a href="PLAN.md">Edit plan</a><a href="encounters.json">Edit summaries</a></nav>
<main><div id="route">{''.join(cards)}</div><article class="report" id="report">{body}</article><footer>Read the <a href="../2026-10-06-forces-current-readings/index.html">current thirteen-hall texts</a> or <a href="http://localhost:3003/illustrations?sequence=forces">all Forces illustrations</a>. Proposal generated from PLAN.md and encounters.json.</footer></main></body></html>'''
(OUT / 'index.html').write_text(html, encoding='utf-8')

class Links(HTMLParser):
    def __init__(self):
        super().__init__(); self.urls = []; self.ids = set()
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if 'id' in attrs: self.ids.add(attrs['id'])
        for key in ('href', 'src'):
            if key in attrs: self.urls.append(attrs[key])

p = Links(); p.feed(html)
for url in p.urls:
    u = urlsplit(url)
    if u.scheme: continue
    if not u.path:
        assert unquote(u.fragment) in p.ids, url
    else:
        assert (OUT / unquote(u.path)).is_file(), url
assert len(stages) == 8 and len({s['id'] for s in stages}) == 8
assert all(all(s[k] for k in ('story', 'carry', 'variation', 'test', 'short')) for s in stages)
manifest = {'kind': 'source-read design proposal; no runtime certification', 'date': '2026-10-06', 'encounters': len(stages), 'local_links_checked': True, 'files': {f: hashlib.sha256((OUT / f).read_bytes()).hexdigest() for f in ['PLAN.md', 'encounters.json', 'index.html']}}
(OUT / 'manifest.json').write_text(json.dumps(manifest, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'encounters': len(stages), 'local_links': 'pass', 'report': str(OUT / 'index.html')}))
