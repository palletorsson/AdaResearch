"""Publish the three new returns with native museum images and separate making notes.

Run after publish_spine_studies.py. Images come from capture_spine_studies.py.
"""
from pathlib import Path
import hashlib, html, json, re
import markdown
from relations_studies import SPECS, READINGS, EDITS, REFERENCES, REVIEW

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations'/REVIEW
BASE = ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine'
OUT.mkdir(parents=True, exist_ok=True)
E = html.escape
css = '''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#eeeae3;color:#29252b;font:17px/1.65 system-ui,sans-serif}header,main,footer{max-width:1160px;margin:auto;padding:50px 28px}h1{font:clamp(48px,7vw,88px)/1.02 Georgia;max-width:970px;letter-spacing:-.035em}h2{font:42px/1.14 Georgia;margin:15px 0}h3{font:28px/1.2 Georgia}.lead{font:25px/1.5 Georgia;max-width:850px}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.13em;color:#8f4261}a{color:#883e5d;text-underline-offset:4px}nav{display:flex;gap:24px;flex-wrap:wrap}section{padding:60px 0;border-top:1px solid #cec5bc;scroll-margin-top:25px}figure{margin:28px 0}img{display:block;width:100%;height:auto}figcaption,.small{font-size:13px;color:#665c65}.reading{font:23px/1.65 Georgia;max-width:750px;margin:45px auto}.reading p{margin:0 0 25px}details{padding:22px;background:#e3dcd5;max-width:900px;margin:25px auto}summary{cursor:pointer;font-weight:600}pre{white-space:pre-wrap;overflow-wrap:anywhere;background:#29252b;color:#f7d4e2;padding:22px;font:14px/1.6 Consolas,monospace}.note{border-left:3px solid #b7557c;padding:5px 24px;max-width:860px}table{border-collapse:collapse;width:100%;font-size:14px}td,th{text-align:left;padding:12px;border-bottom:1px solid #c9c0b7}@media(max-width:650px){header,main,footer{padding:28px 18px}.reading{font-size:21px}h2{font-size:34px}}'''
cards = []
checks = []
source_manifest = {}
for spec in SPECS:
    key,mode,hall,seq,_,_,_,title,artist,requires,exercise,_ = spec
    source,code,instruction = EDITS[key]
    ref_title,ref_url,ref_note = REFERENCES[key]
    for filename in ['critical.md','technical.md','tutorial.md']:
        p=ROOT/'commons/maps'/hall/filename
        text=p.read_text(encoding='utf-8-sig')
        marker=f'<!-- study-reference:{key} -->'
        if marker not in text:
            text+='\n\n'+marker+'\n\n### Reference and scope\n\n'+ref_note+'\n\n['+ref_title+']('+ref_url+').\n'
        # These controls change data and appearance while the stands stay put.
        text=text.replace('Geometry controls wait until the exhibit is clear. RESET returns the original comparison.','The display stays fixed while its data, words or images change. RESET returns the original comparison.')
        text=text.replace('Earlier study and making notes','Study and making notes')
        if key=='museum_witnesses' and filename=='technical.md' and '<!-- witness-runtime -->' not in text:
            text+='''

<!-- witness-runtime -->

### Actual museum images

Three 384 × 216 SubViewports share the resident museum World3D and face its existing SituatedReadout objects. No duplicate hall or private set is rendered. Four requested exposures per second; achieved rate depends on runtime performance. The last two monitors reuse camera A. D retains actual earlier images; E retains the exposure and address selected with HOLD. The buffer is bounded at 30 images (about 9.5 MiB for RGBA8 frames); the viewport textures and displayed copies are additional. Initial delay is 3 seconds, with 1 / 3 / 6 seconds available. Timestamps are seconds since this game process started.

The screens occupy a camera-excluded visual layer, avoiding recursive screen rendering. Capture pauses outside 23 metres or when source readouts are unavailable. Resuming after a gap clears the delay buffer. Changing the viewpoint preserves an explicitly held image and its earlier source address. These are views of the resident hall, not a promise to stream unloaded distant halls. Physical XR and Quest frame budgets have not been tested.
'''
        p.write_text(text.rstrip()+'\n',encoding='utf-8')
    portable = """

<!-- witness-portable-cameras -->

### Take a view

Cameras A and B are the pink grabbable bodies beside the original readouts; C stays fixed. On desktop, right-click to pick up, look to aim, and right-click again to release. The usual XR pickup grip moves and turns the same bodies. They stay in the released pose. RETURN CAMERAS restores the current starting views; release the cameras before using return, VIEWPOINT or RESET. Returning the cameras keeps an explicitly held screen image. RESET also clears the held image.

The camera follows the physical body's transform, with its lens 0.32 metres forward. The delayed and held records retain their exposure pose and source label as well as the image and time. Moving A does not rewrite those earlier frames. This reuses coordinates and transforms; constructing the camera housing and pickup system remains supplied.
"""
    if key == 'museum_witnesses':
        for filename in ['tutorial.md','technical.md','intent.md','artifacts.md','summary.md']:
            p=ROOT/'commons/maps'/hall/filename
            text=p.read_text(encoding='utf-8-sig')
            if '<!-- witness-portable-cameras -->' not in text: p.write_text(text.rstrip()+portable,encoding='utf-8')
    # The master review serves current tutorial snapshots as well.
    raw=(ROOT/'commons/maps'/hall/'tutorial.md').read_bytes()
    tutorial_body=markdown.markdown(raw.decode('utf-8'),extensions=['fenced_code','tables','footnotes'])
    making=OUT/(key+'-making.html')
    making.write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><meta name="source-sha256" content="'+hashlib.sha256(raw).hexdigest()+'"><title>'+E(title)+' / making</title><style>'+css+'</style><main><a href="index.html#'+key+'">Back to the encounter</a>'+tutorial_body+'</main></html>',encoding='utf-8')
    # Keep all main-review links truthful following the reference addition.
    (BASE/'making'/f'{hall}.html').write_text(making.read_text(encoding='utf-8').replace('index.html#'+key,'../index.html#'+key),encoding='utf-8')
    source_manifest[source]=hashlib.sha256((ROOT/source).read_bytes()).hexdigest()
    report=json.loads((BASE/'figures'/f'{hall}-report.json').read_text(encoding='utf-8'))
    checks.extend(report['checks'])
    reading=''.join('<p>'+E(p)+'</p>' for p in READINGS[key].split('\n\n'))
    camera_figure = '<figure><img loading="lazy" src="../2026-10-02-studies-in-the-spine/figures/museum_witnesses-camera.png" alt="Pink grabbable camera in the actual museum"><figcaption>Cameras A and B can be carried and aimed. Release leaves the camera in place; RETURN CAMERAS restores the starting views. C stays fixed.</figcaption></figure>' if key == 'museum_witnesses' else ''
    cards.append(f'''<section id="{key}"><div class="eyebrow">{E(seq)} / {E(hall)}</div><h2>{E(title)}</h2><p class="small">Original Ada study in relation to {E(artist)}</p><figure><img loading="lazy" src="../2026-10-02-studies-in-the-spine/figures/{key}.png" alt="{E(title)} inside the endless museum"><figcaption>Unedited native Godot capture inside {E(hall)}.</figcaption></figure><div class="reading">{reading}</div>{camera_figure}<details><summary>Making · {E(', '.join(requires))}</summary><p>{E(instruction)}</p><pre><code>{E(code)}</code></pre><p><a href="{key}-making.html">Current tutorial</a> · <a href="../2026-10-02-studies-in-the-spine/sources/{key}.html">Study source</a> · <a href="/tutorial-lineage#hall={hall}">Capability lineage</a></p></details><p><a href="/book-review/commons/maps/{hall}/final.md">Whole current chapter</a></p><details><summary>Reference and the limits of the response</summary><p>{E(ref_note)}</p><p><a href="{ref_url}">{E(ref_title)}</a></p></details></section>''')

count=len(checks); passed=sum(c['passed'] for c in checks)
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Relations, sentences and witnesses</title><style>'''+css+'''</style><header><div class="eyebrow">Ada / 2 October 2026 / three returns in the spine</div><h1>Who gets to say<br>what happened?</h1><p class="lead">A line joins two names. A sentence occupies a wall. A monitor keeps a moment after the room has moved on. Each offers an account; each gives us something different to inspect.</p><nav><a href="#evidence_network">Lombardi / relations</a><a href="#sentence_authority">Holzer / sentences</a><a href="#museum_witnesses">Gilligan / witnesses</a><a href="#evidence">Checks</a></nav><div class="note"><p>These studies are installed in the existing Graph Theory, Foundations Crisis and Situated Computation halls. Each returns to capabilities already encountered. The critical passage stays separate from the first useful code edit.</p><p>The monitor images come from the actual endless museum. Three cameras, an earlier exposure and a held exposure share one room.</p></div></header><main>'''+''.join(cards)+f'''<section id="evidence"><h2>What holds up in the room</h2><p>{passed} / {count} native checks pass across the three actual museum assemblies. They exercise the museum pointer controls, reset, floor support, side-route clearance and each study’s distinct behaviour.</p><p>The monitor test briefly places an exposure target inside the real hall. When it changes from red to green, the live frame changes while the delayed and held images remain red. The target is removed before the published photograph. The cameras retain the main player’s view, and their frame history stays bounded. Additional checks exercise both XR pickup callbacks with supplied hand motion and the real desktop pointer: translation, rotation, release, protected return and the unchanged fixed camera.</p><p>Desktop native checks and HTTP publication checks are recorded. Physical XR, Quest performance and independent learner use remain untested.</p><p><a href="evidence.json">Native check details</a> · <a href="../2026-10-02-studies-in-the-spine/verification.json">Full integration verification</a> · <a href="README.md">Reproduce</a></p></section></main><footer><a href="../2026-10-02-studies-in-the-spine/index.html">All sixteen installed artist applications</a> · <a href="/tutorial-lineage">Tutorial lineage</a></footer></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'evidence.json').write_text(json.dumps({'passed':passed==count,'native_checks':count,'checks':checks,'source_sha256':source_manifest,'scope':'Actual museum rendering and pointer dispatch; temporary exposure target removed before photograph.'},indent=2)+'\n',encoding='utf-8')
(OUT/'README.md').write_text('''# Relations, sentences and witnesses

Three original Ada studies in dialogue with Mark Lombardi, Jenny Holzer and Melanie Gilligan, installed in the existing museum route and canonical book. Images are native captures inside endless_museum, not standalone set renders. References are linked alongside each response; no claim of historical reconstruction.

Run `python tools/publish_spine_studies.py`, `python tools/capture_spine_studies.py GT_Network_Analysis Crisis_Synthesis SpeculativeComputation_Situated_Computation`, then `python tools/publish_relations_studies.py`. Export the three affected book sequences, rebuild tutorial lineage, and run `tools/verify_spine_studies.py --http --refresh-provenance`. The master placement manifest is `doc/book/recent-studies.json`.

Existing artifacts and their positions remain. New applications occupy adjoining bays. They introduce no additional foundation capability node. Network records and sign sentences are explicitly original Ada examples. Gilligan-informed monitors use actual resident museum readouts as subjects; they do not show Gilligan films or silently substitute fabricated museum rooms.
''',encoding='utf-8')
print(f'Published three returns: {passed}/{count} native checks.')
