"""Publish the matrix-resolution revision without overwriting earlier test evidence."""
from pathlib import Path
import difflib, hashlib, html, json, re, shutil
import markdown
from publish_randomness_revision import ROOT, PLAN, STYLE, page, publish_plan

OUT = ROOT / 'doc/book/iterations/2026-10-09-random-matrix-size'
OLD = ROOT / 'doc/book/iterations/2026-10-09-randomness-revision/Random_Definition'


def main():
    tests=json.loads((OUT/'tests.json').read_text())
    assert all(r['passed']==r['expected_pass'] for r in tests['results'])
    run=ROOT/'ada_run/encounter_pilot/Random_Definition'
    receipt=json.loads((run/'report.json').read_text())
    assert receipt['passed'] and len(receipt['checks'])==24
    log=(run/'engine.log').read_text(encoding='utf8',errors='replace')
    assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log
    museum=OUT/'museum';museum.mkdir(exist_ok=True)
    captures={'museum-8.png','museum-16.png','student-8.png','student-16.png','student-4.png'}
    for p in run.iterdir():
        if p.name in captures or p.name in ['report.json','engine.log','source_manifest.json','spec.json']:
            shutil.copy2(p,museum/p.name)
    texts={name:(ROOT/f'commons/maps/Random_Definition/{name}.md').read_text(encoding='utf8') for name in ['tutorial','final']}
    for name,code in re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',texts['tutorial'],re.S):
        assert code+'\n'==(OUT/'extracted'/name).read_text(encoding='utf8')
        assert hashlib.sha256((OUT/'extracted'/name).read_bytes()).hexdigest()==tests['files'][name]
    report='''# Matrix size in your hands

Both matrices start at **8 × 8**. The new **MATRIX slider selects 2 × 2 through 16 × 16**. Each panel keeps its footprint; more cells make a finer matrix. There are fifteen integer choices.

## In the museum

The installed Seed Replay console now has a separate resolution slider beside its existing seed and replay controls. Drag MATRIX to change both grids together. The seed, selected extra draw and random-seed generator are retained. Returning to an earlier size reproduces its colours. The selected size also returns with the artifact's saved visit state.

The control itself survives the grid rebuild, so the hand can continue moving it. The original seed slider still controls the seed; its behaviour is unchanged.

## In the tutorial

The printed reconstruction also starts at eight by eight and includes a pink grab handle on a rail. Every mesh, collision and label is built in code. `matrix_slider.gd` is printed in full beside `01_seed_picture.gd` and the unchanged `point_body.gd`; XR Tools remains the declared Day Zero dependency.

Resizing changes the number of requests: 192 RGB draws at 8 × 8, 768 at 16 × 16, with one extra when the right grid discards a value. It preserves the prefix of the colour list, but changes the row width. This is a new arrangement of the same stream, not a zoom into the old picture.

The reflection now names the difference between the two handles: changing a seed varies the colours; changing MATRIX varies how many places can receive them. The tutorial keeps seed, request order and assignment as its focus; the rail is supplied interaction code.

## Checked

- Printed reconstruction and both colour-assignment edits pass native Godot assertions, including every slider choice, bounds, seed retention, replay and returning to the original picture.
- The track's hand-displacement calculation is checked in a rotated study, including a stationary hand not advancing the handle again.
- Both deliberately broken random-stream variants are still rejected.
- **24 checks pass in the actual museum**, including the live slider driver's signals, fixed panel width/height, saved resolution, draw counts, and agreement between the printed study and installed colours. Five of these are capture-camera checks.

Native screenshots were inspected. These checks supply control movements; they do not certify headset comfort or a physical hand/controller session. The museum log retains its existing UID and renderer warnings. No map layout or other Randomness lesson was changed.

[Tutorial and reflection](parallel.html) · [Tutorial source](tutorial.md) · [Reflection source](final.md) · [Before/after](changes.html) · [Code evidence](tests.json) · [Museum evidence](museum/report.json)
'''
    counts=[r['checks'] for r in tests['results'] if r['expected_pass']]
    report=report.replace('Printed reconstruction and both colour-assignment edits pass native Godot assertions',f'Printed reconstruction passes **{counts[0]}** native Godot checks; grayscale and swapped-channel edits pass **{counts[1]} each**')
    (OUT/'REPORT.md').write_text(report,encoding='utf8')
    nav='<a href="index.html">Images and changes</a><a href="parallel.html">Facing pages</a><a href="../2026-10-09-randomness-revision/index.html">Randomness plan</a>'
    for name,t in texts.items():
        (OUT/f'{name}.md').write_text(t,encoding='utf8')
        (OUT/f'{name}.html').write_text(page(name.title(),t,nav),encoding='utf8')
    spread=''.join(f'<article><p class="track">{label}</p>{markdown.markdown(texts[name],extensions=["extra"])}</article>' for name,label in [('tutorial','Tutorial · left'),('final','Reflection · right')])
    (OUT/'parallel.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Definition — adjustable matrices</title><style>{STYLE}main{{max-width:1650px}}.spread{{display:grid;grid-template-columns:1fr 1fr;gap:50px}}article{{min-width:0}}article h1{{font-size:36px}}.track{{font:13px system-ui;text-transform:uppercase}}@media(max-width:900px){{.spread{{grid-template-columns:1fr}}}}</style><main><nav>{nav}</nav><h1>A seed, a procedure, a matrix</h1><div class="spread">{spread}</div></main></html>',encoding='utf8')
    gallery='''<h2>Inside the museum</h2><figure><img src="museum/museum-8.png" alt="Eight by eight matrices with the new MATRIX slider"><figcaption>Default: 8 × 8, 192 draws per grid. The new slider is below SEED.</figcaption></figure><figure><img src="museum/museum-16.png" alt="Sixteen by sixteen matrices in the same panels"><figcaption>16 × 16, 768 draws per grid. The panel footprint and seed stay.</figcaption></figure><h2>The printed reconstruction</h2><p>These buttons compare recorded museum screenshots, not a live Godot session.</p><div class="choices"><button onclick="showSize(4)">4 × 4</button><button onclick="showSize(8)">8 × 8</button><button onclick="showSize(16)">16 × 16</button></div><figure><img id="study" src="museum/student-8.png" alt="The printed eight-by-eight reconstruction and pink resolution handle"><figcaption id="size-caption">8 × 8 · drag the pink handle beneath the grids.</figcaption></figure><script>function showSize(n){document.getElementById('study').src='museum/student-'+n+'.png';document.getElementById('study').alt='Printed '+n+' by '+n+' reconstruction';document.getElementById('size-caption').textContent=n+' × '+n+' · '+(n*n*3)+' draws per grid.'}</script>'''
    (OUT/'index.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Random Definition — matrix size</title><style>{STYLE}main{{max-width:1150px}}figure{{margin:30px 0}}figcaption{{font:15px/1.5 system-ui;margin:10px 0}}button{{padding:12px 24px;margin-right:10px;cursor:pointer;background:#25252c;color:white;border:0;font:16px system-ui}}</style><main><nav>{nav}</nav>{markdown.markdown(report,extensions=["extra"])}{gallery}</main></html>',encoding='utf8')
    diffs=[]
    for name in ['tutorial','final']:
        old=(OUT/f'before/commons/maps/Random_Definition/{name}.md').read_text(encoding='utf8')
        diff=''.join(difflib.unified_diff(old.splitlines(True),texts[name].splitlines(True),fromfile=f'before/{name}.md',tofile=f'after/{name}.md'))
        (OUT/f'{name}.diff').write_text(diff,encoding='utf8')
        diffs.append(f'<h2>{name}.md</h2><pre>{html.escape(diff)}</pre>')
    (OUT/'changes.html').write_text(f'<!doctype html><html lang="en"><meta charset="utf-8"><title>Matrix revision — text changes</title><style>{STYLE}</style><main><nav>{nav}</nav><h1>Text changes</h1>'+''.join(diffs)+'</main></html>',encoding='utf8')
    # Keep the earlier 4x4 evidence intact; mark it clearly and link to this revision.
    banner='<p style="padding:18px;border:2px solid #7c365b"><strong>Updated: 8 × 8 matrices with a size slider.</strong> <a href="../../2026-10-09-random-matrix-size/index.html">Open the current museum images and tutorial.</a> This page retains the earlier 4 × 4 revision and its test evidence.</p>'
    for name in ['index.html','parallel.html','tutorial.html','final.html','changes.html']:
        p=OLD/name;t=p.read_text(encoding='utf8')
        if 'Updated: 8 × 8 matrices with a size slider.' not in t:t=t.replace('<main>','<main>'+banner,1)
        p.write_text(t,encoding='utf8')
    status=json.loads((PLAN/'STATUS.json').read_text())
    status['halls'][0].update(tutorial_test=f'{counts[0]} + {counts[1]} + {counts[2]} passed; 2 faults rejected',museum_test='24 passed; adjustable 8x8 matrices; native images inspected',report='doc/book/iterations/2026-10-09-random-matrix-size/index.html')
    (PLAN/'STATUS.json').write_text(json.dumps(status,indent=2),encoding='utf8')
    p=PLAN/'PLAN.md';t=p.read_text(encoding='utf8');t=t.replace('Reconstruct two small colour grids;','Reconstruct two colour grids, initially 8 × 8 with a supplied 2–16 resolution slider;');p.write_text(t,encoding='utf8')
    publish_plan()
    print(json.dumps({'report':str(OUT/'index.html'),'code_checks':counts,'museum_checks':len(receipt['checks']),'printed_code_files':len(tests['files'])},indent=2))


if __name__=='__main__':main()
