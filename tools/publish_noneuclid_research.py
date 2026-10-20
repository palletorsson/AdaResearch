"""Publish the research, editable encounter plan and bounded feasibility evidence."""
from pathlib import Path
from html import escape
from datetime import datetime, timezone
import hashlib,json,shutil,zipfile
from publish_euclid_lesson import md

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-noneuclid-deeper-spaces'
STUDY=ROOT/'doc/book/studies/noneuclid-research'
CSS='''
:root{color-scheme:light;--paper:#f1efe8;--ink:#222626;--muted:#5a6263;--pink:#b34369}
*{box-sizing:border-box}body{margin:0;background:var(--paper);color:var(--ink);font:17px/1.6 system-ui,sans-serif}
main{max-width:1260px;margin:auto;padding:40px 30px 90px}a{color:#8c2c50;text-underline-offset:4px}nav{display:flex;gap:20px;flex-wrap:wrap;padding:16px 0;border-block:1px solid #c9cac2}
h1{font:500 clamp(48px,7vw,90px)/1.04 Georgia,serif;letter-spacing:-.04em;max-width:970px;margin:40px 0 25px}h2{font:500 34px/1.2 Georgia,serif;margin:45px 0 18px}h3{font:500 28px/1.25 Georgia,serif;margin:14px 0}
.eyebrow,.tag{font-size:12px;letter-spacing:.1em;text-transform:uppercase}.lead{font-size:24px;line-height:1.45;max-width:930px}.status{border-left:4px solid var(--pink);padding:14px 22px;background:#e9e5dd}
.cards{display:grid;grid-template-columns:1fr 1fr;gap:26px}.card{border:1px solid #c6c9c2;background:#faf9f5;padding:24px;scroll-margin-top:20px}.card img{width:100%;display:block;aspect-ratio:1.6;object-fit:contain;background:#080d0f}.card .summary{font-size:18px}
.card.wide{grid-column:1/-1}.pair{display:grid;grid-template-columns:1fr 1fr;gap:26px}.card dl{margin:0}.card dt{font-weight:650;margin-top:16px}.card dd{margin:5px 0;color:#414a4c}.card details{border-top:1px solid #ccc;margin-top:18px;padding-top:12px}summary{cursor:pointer;color:#8c2c50;font-weight:600}
figure{margin:22px 0}img{max-width:100%;height:auto}figcaption{font-size:14px;line-height:1.5;color:var(--muted);margin:10px 0 20px}.route{display:flex;gap:10px;flex-wrap:wrap;margin:24px 0}.route a{display:block;padding:10px 15px;border:1px solid #bdc3bd;text-decoration:none;background:white}
table{border-collapse:collapse;width:100%;margin:24px 0;font-size:16px}td,th{padding:14px;border:1px solid #c5c9c3;text-align:left;vertical-align:top}th{background:#e6e7df}code{background:#e5e5dc;padding:2px 5px;overflow-wrap:anywhere}pre{overflow:auto;padding:22px;background:#e5e5dc}pre code{padding:0}.reading{max-width:960px}.reading p,.reading li{line-height:1.7}.number{font:italic 38px Georgia;color:#a85170}.pill{font-size:13px;background:#e7ece5;padding:6px 10px;border-radius:20px}.gallery{display:grid;grid-template-columns:1fr 1fr;gap:22px}.concept{background:#192226;padding:28px;color:#eff0ea;min-height:240px;display:flex;flex-direction:column;justify-content:center;font:28px/1.35 Georgia}.concept small{font:14px/1.5 system-ui;color:#bac4c8;margin-top:14px}footer{border-top:1px solid #bbc3bd;margin-top:45px;padding-top:24px;font-size:14px;color:var(--muted)}
@media(max-width:780px){main{padding:24px 18px}.cards,.pair,.gallery{grid-template-columns:1fr}.card.wide{grid-column:auto}table{font-size:14px;display:block;overflow:auto}.card{padding:18px}h1{font-size:54px}.lead{font-size:20px}}
'''

def page(title,body,reading=False):
    return f'''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{escape(title)} · Endless Museum</title><style>{CSS}</style></head><body><main class="{'reading' if reading else ''}"><p class="eyebrow">Endless Museum / Non-Euclidean spaces / Research / 11 October 2026</p><nav><a href="index.html">Seven encounters</a><a href="research.html">Full research</a><a href="evidence.html">Code & evidence</a><a href="BUILD-PLAN.json">Editable plan</a><a href="noneuclid-research.zip">Research ZIP</a></nav>{body}<footer>Research and original Godot feasibility instruments. Existing museum lesson preserved. Headset interaction and completed new rooms are not claimed.</footer></main></body></html>'''

def main():
    plan=json.loads((OUT/'BUILD-PLAN.json').read_text(encoding='utf-8'))
    latest=json.loads((STUDY/'latest-run.json').read_text())
    assert latest['passed']
    run=ROOT/latest['directory']
    for name,expected in latest['source_sha256'].items():
        assert hashlib.sha256((STUDY/name).read_bytes()).hexdigest()==expected,name
    receipts=OUT/'evidence'
    receipts.mkdir(exist_ok=True)
    for p in run.iterdir():
        shutil.copy2(p,(OUT if p.suffix=='.png' else receipts)/p.name)
    source_copy=OUT/'probe-project'
    source_copy.mkdir(exist_ok=True)
    for p in STUDY.iterdir():
        if p.is_file() and p.suffix in ['.gd','.tscn','.godot','.md']: shutil.copy2(p,source_copy/p.name)
    old=ROOT/'ada_run/encounter_pilot/NonEuclidean_Spaces/surface-lesson-raised'
    for name in ['above','sphere']: shutil.copy2(old/(name+'.png'),OUT/('museum-'+name+'.png'))
    body='''<h1>Carry the point.<br>Change the world.</h1><p class="lead">Seven encounters: impossible interiors, returning corridors, changed directions, an unreachable boundary, a hyperbolic gallery, a curved volume and a shot along a geodesic.</p>
<p class="status"><strong>Research + working feasibility probes.</strong> The new museum encounters are designed, not installed. Godot 4.6 passes 74 geometry checks and 12 desktop stencil checks across three renderers. Five geometry views run and render.</p>
<div class="pair"><figure><img src="museum-sphere.png" alt="Existing carried-point spherical triangle study in the actual Endless Museum"><figcaption>Current museum: the tested plane/sphere lesson remains the starting point.</figcaption></figure><figure><img src="museum-above.png" alt="Existing NonEuclidean Spaces hall viewed from above"><figcaption>Actual hall from above. Reach larger chambers through thresholds; do not pack seven demonstrations around the existing table.</figcaption></figure></div>
<h2>One object, seven encounters</h2><p>The point keeps its identity. Its line becomes a geodesic; its trace becomes a route; its arrow makes transport visible; its catalyst action tests the geometry.</p>'''
    body+='<div class="route">'+''.join(f'<a href="#{x["id"]}">{i+1:02d} / {escape(x["title"])}</a>' for i,x in enumerate(plan['encounters']))+'</div><div class="cards">'
    for i,x in enumerate(plan['encounters']):
        body+=f'<article class="card" id="{x["id"]}"><span class="number">{i+1:02d}</span><p class="tag">{escape(x["kind"])}</p><h3>{escape(x["title"])}</h3>'
        if x['image']:
            body+=f'<figure><a href="{x["image"]}"><img loading="lazy" src="{x["image"]}" alt="{escape(x["image_caption"])}"></a><figcaption>{escape(x["image_caption"])}</figcaption></figure>'
        else:
            idea='Leave → return → find the same point' if i==1 else 'Predict → aim → release → compare'
            body+=f'<div class="concept">{idea}<small>Encounter design. No completed game screenshot yet.</small></div>'
        body+=f'<p class="summary">{escape(x["summary"])}</p><dl><dt>With your hands</dt><dd>{escape(x["hand"])}</dd><dt>Learning elements</dt><dd>{escape(x["concept"])}</dd><dt>What travels onward</dt><dd>{escape(x["carry"])}</dd></dl><details><summary>Implementation and tests</summary><dl><dt>Build</dt><dd>{escape(x["build"])}</dd><dt>Acceptance</dt><dd>{escape(x["test"])}</dd><dt>Evidence now</dt><dd>{escape(x["evidence"])}</dd><dt>Reflection</dt><dd>{escape(x["reflection"])}</dd></dl></details></article>'
    body+='''</div><h2>Looking at a model / looking from inside</h2><p>These are actual Godot renders of the same finite H³ scaffold. The first is an external diagram; the second recentres the world at its observer before projection. Neither is a completed VR hall.</p><div class="pair"><figure><img loading="lazy" src="geometry-ball.png" alt="External Poincare model of the H3 scaffold"><figcaption>External model. The curved appearance of a line depends on this display.</figcaption></figure><figure><img loading="lazy" src="geometry-inside.png" alt="Central first-person projection in H3"><figcaption>Inhabitant view. Geodesics project as straight image lines from this observer; full stereo and body handling are still required.</figcaption></figure></div><h2>What we build first</h2><p>One real doorway carrying the familiar sphere, then a return corridor and exact curved paths. The first inhabited chamber uses H² × R. Full H³ gets its own body, rendering and collision tests. This expansion stays inside the museum's lineage.</p><p><a href="research.html">Read the technical research, local audit and staged build contract →</a></p>'''
    (OUT/'index.html').write_text(page('Carry the point. Change the world.',body),encoding='utf-8')
    (OUT/'research.html').write_text(page('Non-Euclidean spaces / deep research',md((OUT/'RESEARCH.md').read_text(encoding='utf-8')),True),encoding='utf-8')
    evidence='''<h1>What actually ran.</h1><p class="lead">A geometry kernel, a native GPU stencil experiment and five geometry views. These are author feasibility tests, not a ghost-student reconstruction or headset verification.</p><p><a href="probe-project/README.md">Run instructions and scope</a> · <a href="evidence/run.json">Commands, receipts and source hashes</a></p><table><tr><th>Probe</th><th>Result</th><th>What remains outside the claim</th></tr><tr><td>Geometry kernel</td><td>74 / 74 assertions</td><td>Unbounded numerical stability, full collision, full lesson reconstruction</td></tr><tr><td>Stencil / Compatibility</td><td>4 / 4 pixel checks</td><td>Quest / XR, crossing, recursive views and lighting</td></tr><tr><td>Stencil / Mobile</td><td>4 / 4 pixel checks</td><td>Same; desktop Vulkan on RTX 3070</td></tr><tr><td>Stencil / Forward+</td><td>4 / 4 pixel checks</td><td>Same; desktop Vulkan on RTX 3070</td></tr><tr><td>Five geometry views</td><td>Run, captured and visually inspected</td><td>Image creation is not proof of physical interaction or learning</td></tr></table><figure><img src="stencil-gl_compatibility.png" alt="Actual stencil mask test showing blue only inside a framed opening and occluded by a dark rectangle"><figcaption>Native Godot 4.6 capture. No image generation. The blue receiver extends beyond the doorway, but stencil hides those pixels.</figcaption></figure><h2>Scope and reproducibility</h2>'''
    evidence+=md((STUDY/'README.md').read_text(encoding='utf-8'))
    evidence+='<h2>Native views</h2><div class="gallery">'+''.join(f'<figure><a href="geometry-{m}.png"><img src="geometry-{m}.png" alt="Godot research view: {m}"></a><figcaption>{m} / original executable probe</figcaption></figure>' for m in ['disk','sphere','ball','product','inside'])+'</div>'
    (OUT/'evidence.html').write_text(page('Non-Euclidean spaces / feasibility evidence',evidence),encoding='utf-8')
    manifest={'published_utc':datetime.now(timezone.utc).isoformat(),'plan_sha256':hashlib.sha256((OUT/'BUILD-PLAN.json').read_bytes()).hexdigest(),'research_sha256':hashlib.sha256((OUT/'RESEARCH.md').read_bytes()).hexdigest(),'evidence_run':latest,'canonical_lesson_changed':False,'museum_placements_changed':False,'new_encounters_installed':0}
    (OUT/'manifest.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
    zip_path=OUT/'noneuclid-research.zip'
    with zipfile.ZipFile(zip_path,'w',zipfile.ZIP_DEFLATED) as z:
        for p in OUT.rglob('*'):
            if p.is_file() and p!=zip_path and '.godot' not in p.parts: z.write(p,p.relative_to(OUT))
    print('Published',OUT,'ZIP bytes',zip_path.stat().st_size)

if __name__=='__main__': main()
