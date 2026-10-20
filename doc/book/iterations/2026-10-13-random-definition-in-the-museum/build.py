"""Publish the revised reflection from draft.md and real Godot captures."""
import hashlib
import html
import json
import re
import shutil
from pathlib import Path

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
IMAGES = HERE / 'images'
IMAGES.mkdir(exist_ok=True)
paragraphs = (HERE/'draft.md').read_text(encoding='utf-8').strip().split('\n\n')
assert len(paragraphs) == 12
canonical = (ROOT/'commons/maps/Random_Definition/final.md').read_text(encoding='utf-8')
body = canonical.split('\n\n',1)[1].split('\n[^rand-1955]:',1)[0]
body = re.sub(r'<!--.*?-->\s*', '', body).replace('[^rand-1955]','').strip()
assert body == '\n\n'.join(paragraphs), 'Canonical reflection and illustrated draft differ.'

run = ROOT / 'ada_run/encounter_pilot'
captures = {
    'seed-before':run/'Random_Definition/four-by-four-20261013/seed-before.png',
    'seed-after':run/'Random_Definition/four-by-four-20261013/seed-after.png',
    'number-page':run/'Random_Definition/random-return-20261013/number-page.png',
    'sphere-centre':run/'Random_Definition/random-return-photos-20261013/sphere-centre.png',
    'sphere-out':run/'Random_Definition/random-return-photos-20261013/sphere-out.png',
    'textiles-in-ten-print':run/'Randomness_10_PRINT_Algorithm/textiles-moved-20261013/textiles-in-ten-print.png',
}
captions = {
    'seed-before':'Four by four. Same seed, same requests: both grids recover the same arrangement.',
    'seed-after':'Sixteen cells per panel. Same seed, one discarded draw: the left grid stays; the right assigns the stream differently.',
    'number-page':'The museum’s number page and passage to Entropy. Touch can hold a cell; other digits fall. This still image shows the installation, not that passage of time or the historical book.',
    'sphere-centre':'Centre: the start and end of each excursion. The sphere is paused for this photograph.',
    'sphere-out':'Destination: direction and distance vary. This second paused state locates the journey; carrying and release are behaviours checked separately.',
    'textiles-in-ten-print':'Later, in 10 PRINT: the same seeded draws become large/small blocks, upright/horizontal bars and diagonals. Entropy and Remove come first.',
}
for name,path in captures.items():
    assert path.exists(),path
    shutil.copyfile(path,IMAGES/(name+'.png'))

reports = {}
for name,path in {
    'ride':run/'Random_Definition/random-return-20261013/report.json',
    'photos':run/'Random_Definition/random-return-photos-20261013/report.json',
    'textiles':run/'Randomness_10_PRINT_Algorithm/textiles-moved-20261013/report.json',
    'four_by_four':run/'Random_Definition/four-by-four-20261013/report.json',
}.items():
    report = json.loads(path.read_text(encoding='utf-8'))
    assert report['passed'], report
    reports[name] = report
(HERE/'checks.json').write_text(json.dumps(reports,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
receipt = {'date':'2026-10-13','renderer':'Godot 4.6 / actual Endless Museum / desktop gl_compatibility',
           'scope':'Current halls, camera placed for publication. Sphere motion paused for the two photographs. No headset session claimed.',
           'text':'Revised ball-first reflection, 13 October. The canonical Random Definition final and illustrated edition share the same 12 prose paragraphs. Screenshots are existing captures; no new capture or headset session is claimed.',
           'captures':[{ 'file':'images/'+k+'.png','source':str(v.relative_to(ROOT)),
                        'sha256':hashlib.sha256(v.read_bytes()).hexdigest(),'caption':captions[k]} for k,v in captures.items()]}
(HERE/'captures.json').write_text(json.dumps(receipt,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def inline(text):
    return re.sub(r'\*([^*]+)\*',r'<em>\1</em>',html.escape(text))
def prose(indices):
    return ''.join('<p>'+inline(paragraphs[i])+'</p>' for i in indices)
def figure(name):
    return f'<figure><a href="images/{name}.png"><img src="images/{name}.png" width="1800" height="1200" alt="{html.escape(captions[name],quote=True)}" loading="lazy"></a><figcaption>{html.escape(captions[name])}</figcaption></figure>'

count = len(re.findall(r"\b[\w]+(?:[’'-][\w]+)*\b",' '.join(paragraphs)))
content = '<div class="prose" id="sphere">'+prose([0,1])+'</div>'
content += '<div class="pair">'+figure('sphere-centre')+figure('sphere-out')+'</div>'
content += '<div class="prose">'+prose([2,3,4])+'</div>'
content += '<div class="pair">'+figure('seed-before')+figure('seed-after')+'</div>'
content += '<section class="history"><div class="prose">'+prose([5,6,7])+'</div>'+figure('number-page')+'</section>'
content += '<div class="prose">'+prose([8,9,10,11])+'</div>'
content += '<p class="source prose">Historical account: <a href="https://www.rand.org/pubs/monograph_reports/MR1418.html">RAND’s introduction and production account</a>. The sleeve remains a possible extension.</p>'
content += '<section class="relocated" id="textiles"><p class="eyebrow">Appendix / later in the sequence: 10 PRINT</p><h2>The same choices, different figures</h2><p class="caption-intro">The textile comparison is in 10 PRINT. The route is Definition → Entropy → Remove → 10 PRINT. This photograph looks ahead; the reflection hands over to Entropy.</p>'+figure('textiles-in-ten-print')+'</section>'

page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A pattern that returns · in the museum</title><style>
:root{--paper:#f7f4ed;--ink:#282c29;--muted:#6b716b;--line:#d8d8ce;--accent:#276458}*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink)}a{color:var(--accent);text-underline-offset:3px}nav{display:flex;gap:22px;flex-wrap:wrap;font:13px/1.5 system-ui,sans-serif}header,main,footer{max-width:1280px;margin:auto;padding:28px 32px}header{padding-bottom:36px}.eyebrow{text-transform:uppercase;letter-spacing:.15em;font:11px/1.5 system-ui,sans-serif;color:var(--accent);margin:40px 0 12px}h1{font:normal clamp(40px,6vw,76px)/1.05 Georgia,serif;letter-spacing:-.035em;margin:0 0 18px}h2{font:normal 38px/1.15 Georgia,serif;margin:0 0 15px}.deck{max-width:760px;font:17px/1.6 system-ui,sans-serif;color:#545e55}.status{font:12px/1.5 system-ui,sans-serif;color:var(--muted)}main{padding-top:0}.prose{max-width:710px;margin:0 auto;font:21px/1.75 Georgia,serif}.prose p{margin:0 0 1.35em}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px;margin:38px 0 70px}figure{margin:0}img{display:block;width:100%;height:auto;border:1px solid var(--line)}figcaption{font:13px/1.6 system-ui,sans-serif;color:var(--muted);padding:12px 2px;max-width:690px}.history{display:grid;grid-template-columns:1fr 1fr;gap:42px;align-items:center;margin-bottom:45px}.history .prose{font-size:19px;line-height:1.75}.source{font:13px/1.6 system-ui,sans-serif;margin-top:32px}.relocated{border-top:1px solid var(--line);margin-top:70px;padding-top:14px}.relocated figure{max-width:940px;margin:30px auto}.caption-intro{font:16px/1.6 system-ui,sans-serif;max-width:700px}.relocated .eyebrow{margin-top:20px}footer{border-top:1px solid var(--line);font:13px/1.6 system-ui,sans-serif;color:var(--muted);padding-bottom:60px}summary{cursor:pointer;color:var(--ink)}footer li{margin:7px 0}a:focus-visible,summary:focus-visible{outline:3px solid #c08c3e;outline-offset:4px}@media(max-width:800px){header,main,footer{padding-left:20px;padding-right:20px}.pair,.history{grid-template-columns:1fr}.prose{font-size:19px}.pair{gap:25px;margin-bottom:40px}.history{gap:20px}}@media print{nav,footer{display:none}body{background:white}img{max-height:95mm;width:auto;max-width:100%;margin:auto}.pair,.history{break-inside:avoid}.prose{font-size:12pt;line-height:1.55}h1{font-size:32pt}}
</style></head><body><header><nav><a href="../2026-10-13-random-definition-two-routes/index.html">← Earlier A / B comparison</a><a href="#sphere">The carried sphere</a><a href="#textiles">Textiles in 10 PRINT</a><a href="final-illustrated.md">Illustrated Markdown</a><a href="random-definition-illustrated.pdf">PDF</a><a href="revision.md">Revision &amp; grade</a></nav><p class="eyebrow">Endless Museum / Random Definition / Illustrated reading</p><h1>A pattern that returns</h1><p class="deck">Hold the ball. Follow what returns through the colour bench, a book of chance, and a picture imagined as something to wear.</p><p class="status">13 October 2026 · __WORDS__ words · actual Godot screenshots · revised reflection</p></header><main>__CONTENT__</main><footer><details><summary>What changed, and what was checked</summary><ul><li>The revised reflection opens with two paragraphs at the sphere. RAND enters through the problem of recovering chance; an imagined pull gives the sleeve its beginning. The canonical final shares this prose. Earlier drafts and the previous plan are preserved.</li><li>The seed comparison starts at 4 × 4, with 48 colour draws per panel. The MATRIX slider still selects 2 × 2 through 16 × 16. Its new capture and runtime report are recorded separately.</li><li>The new sphere extends PointBody, chooses one direction and distance per excursion, returns to its centre, and carries the player only while held. Its seed is independent of the colour bench.</li><li>Hold the grip in VR. On desktop, right-click to hold or release. REPLAY repeats destinations; NEXT SEED changes them. Release before resetting.</li><li>Previously recorded runtime assertions covered 100 bounded, repeatable destinations; desktop grab and release; an actual museum player travelling out and back; wall collision; XR Tools grab ownership; and ordinary desktop props retaining their behaviour. These are existing reports, not fresh test runs for this prose edit. A physical headset test remains outstanding.</li><li>The 10 PRINT hall is deeper to accommodate the relocated textile comparison. Its approach has floor. Its existing CodeDisplay reported missing source paths, and shutdown reported a retained resource; these are not failures of the textile assertions.</li><li>Images are unaltered Godot renders. The camera and paused capture states are documented in the probe scripts. Room geometry, spheres and displays are the current project.</li></ul><p><a href="checks.json">Assertion reports</a> · <a href="captures.json">Image provenance</a> · <a href="README.md">Files and reproduction</a></p></details></footer></body></html>'''
(HERE/'index.html').write_text(page.replace('__WORDS__',str(count)).replace('__CONTENT__',content),encoding='utf-8')

lines = ['# A pattern that returns','', '> Revised reflective text, 13 October 2026. The same prose appears in Random Definition/final.md. The sleeve is an imagined extension.','']
for i,p in enumerate(paragraphs):
    lines += [p,'']
    names = {1:['sphere-centre','sphere-out'],4:['seed-before','seed-after'],7:['number-page']}.get(i,[])
    for name in names: lines += [f'![{captions[name]}](images/{name}.png)','',captions[name],'']
lines += ['Historical source: [RAND’s production account](https://www.rand.org/pubs/monograph_reports/MR1418.html).','','## Appendix — later in the sequence: 10 PRINT','','Definition → Entropy → Remove → 10 PRINT.','',f'![{captions["textiles-in-ten-print"]}](images/textiles-in-ten-print.png)','',captions['textiles-in-ten-print'],'']
(HERE/'final-illustrated.md').write_text('\n'.join(lines),encoding='utf-8')
(HERE/'README.md').write_text('''# Random Definition — in the museum

[Open the illustrated reading](index.html) · [Text with images](final-illustrated.md)

Actual museum screenshots and a new carried PointBody. The textiles move to an extended 10 PRINT hall. Canonical final.md files now describe those placements; their tutorial.md files keep their existing printed constructions.

The revised reflection has 12 paragraphs and 622 body words. It opens at the sphere and matches commons/maps/Random_Definition/final.md. The tutorial is unchanged by this revision. Earlier prose, the old plan and builders are preserved in before-ball-opening/. The original user-supplied consolidation remains source-draft.md. Read revision.md for the editorial assessment.

Revise draft.md and the canonical final together, retaining canonical artifact markers and the RAND footnote. Run build.py to verify their agreement and regenerate HTML and illustrated Markdown. Run export_pdf.py with the bundled Python runtime for the PDF and its review-page copy. The paired grid photographs now show the 13 October four-by-four revision.

Runtime commands (from repository root):

```powershell
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-random-definition-in-the-museum/ride_probe.gd --output-tag random-return-20261013
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-random-definition-in-the-museum/photo_probe.gd --output-tag random-return-photos-20261013
python tools/run_encounter_probe.py Randomness_10_PRINT_Algorithm --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-random-definition-in-the-museum/ride_probe.gd --output-tag textiles-moved-20261013
python tools/run_encounter_probe.py Random_Definition --sequence randomness --render --no-bridges --probe doc/book/iterations/2026-10-13-four-by-four-seed/museum_probe.gd --output-tag four-by-four-20261013
python doc/book/iterations/2026-10-13-random-definition-in-the-museum/build.py
```

Read checks.json for previously recorded runtime results and captures.json for image provenance. These are not new engine runs for the prose revision. The assertions are runtime checks; headset comfort, reach and tracking remain a human test. The 10 PRINT launch has an existing CodeDisplay source-path warning and a shutdown resource warning recorded in its engine log.

The initial capture.gd records the pre-move room and is retained as process history. It expects the old placements. Use ride_probe.gd and photo_probe.gd for the current room. place.py records the placement migration; it is not part of the museum runtime.
''',encoding='utf-8')
print(json.dumps({'words':count,'images':len(captures),'assertions':sum(len(r['checks']) for r in reports.values()),'output':str(HERE/'index.html')}))
