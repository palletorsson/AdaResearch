"""Publish the tensile application, native museum comparisons and making return."""
from pathlib import Path
import html, json, hashlib, re
import markdown
from tension_study import REVIEW, READINGS, EDITS, REFERENCE

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations'/REVIEW
BASE=ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine'
HALL='SoftBodies_Cloth_Physics'
OUT.mkdir(parents=True,exist_ok=True)
E=html.escape
ref_title,ref_url,ref_note=REFERENCE
making='''### Pull, wait, release

This return follows the hanging strips: those changed the fixed points. Here the four corner points stay pinned. The pink bead is one additional prescribed point only while you hold it. Desktop: right-click the bead, move your view, then right-click to release. XR uses the ordinary pickup grip. HOLD A PULL supplies the same target each time; RELEASE lets it move again. Release a hand-held bead before using the preset or RESET.

Start unloaded, use HOLD A PULL, then RELEASE. Watch the bead and the centre height. LOAD selects the next downward load: 0, 1, 3, then 0 kg. Compare one load at a time. MORE / LESS GIVE changes the links' compliance independently of that load. RESET restores the unloaded, settled starting configuration and the firmer setting.

The bead and black load marker are representations. The solver distributes the additional downward force over nine central nodes; there is no separate falling rigid weight. The remaining mesh is visual, not a barrier to the player. The four supports and the museum floor are solid. A bounded grip target and floor limit keep the small study in its space.

### The next close reading

Begin with the single array edit above. The supplied solver keeps three arrays: current positions, previous positions and rest positions. Gravity changes the free points. Distance links share the displacement between their ends; four indices are excluded from movement. A held bead temporarily adds another exclusion. Releasing it removes that exclusion without replacing its current position with its rest position.

`compliance` controls the distance links' response; `damping` removes motion over time. They do different jobs. A softer response may settle lower, while greater damping makes the journey quieter. Neither creates wear or a remembered injury. The rest lengths remain unchanged.
'''
technical='''### Implementation and limits

`tension_score.gd` contains a 25 by 9 network (225 nodes), four pinned corners, horizontal/vertical/diagonal distance links and eight compliant-constraint iterations per step. The fixed step is 1/120 second, with at most eight steps per physics update; under sustained overload simulation time slows instead of integrating an unstable large step. The initial five simulated seconds are settled before the handle is exposed. `tension_membrane.gd` fabricates the supports, rebuilds the displayed triangle surface and routes controls. `tension_handle.gd` uses the project's XRToolsPickable and desktop grab callbacks.

The model has units but no calibration against nylon. It has no self-collision, tearing, plasticity or contact against the visitor. The shader suggests a weave on an opaque surface. The added load is force distributed over a central patch, not added inertial mass. Pin positions and the original rest lengths survive every comparison. No claim of physical headset testing or Quest performance is made.
'''
for name in ['tutorial.md','technical.md','critical.md']:
    p=ROOT/'commons/maps'/HALL/name
    text=p.read_text(encoding='utf-8-sig')
    marker='<!-- tension-reference -->'
    text=text.split(marker)[0].rstrip()
    if name=='tutorial.md':
        text=text.replace('Geometry controls wait until the exhibit is clear. RESET returns the original comparison.','Release the pink handle before RESET or the preset pull. The four supports stay fixed throughout.')
        text+='\n\n'+marker+'\n\n'+making
    elif name=='technical.md': text+='\n\n'+marker+'\n\n'+technical
    else: text+='\n\n'+marker+'\n\nThe difference between elastic recovery and demanded resilience is the critical question of this response. A returning mesh cannot establish what a person can bear. The fixed anchors and intact rest lengths make the model’s promise of restoration inspectable.\n'
    text+='\n\n### Reference\n\n'+ref_note+'\n\n['+ref_title+']('+ref_url+').\n'
    p.write_text(text,encoding='utf-8')

css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#eeeae3;color:#302830;font:17px/1.65 system-ui}header,main,footer{max-width:1180px;margin:auto;padding:42px 30px}h1{font:clamp(58px,8vw,100px)/1.02 Georgia;margin:24px 0}h2{font:38px/1.2 Georgia}a{color:#873c59;text-underline-offset:4px}nav{display:flex;gap:25px;flex-wrap:wrap}.eyebrow{font-size:12px;letter-spacing:.14em;text-transform:uppercase}.lead{font:26px/1.45 Georgia;max-width:770px}.reading{font:24px/1.65 Georgia;max-width:760px;margin:65px auto}.reading p{margin:0 0 28px}section{padding:32px 0;scroll-margin-top:25px}figure{margin:25px 0}img{width:100%;display:block}figcaption,.small{font-size:13px;color:#71636a}details{background:#e4dcd5;padding:22px;margin:25px 0}summary{cursor:pointer;font-weight:600}pre{background:#2a242b;color:#ffe0ed;padding:22px;white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 Consolas,monospace}.states input{position:absolute;opacity:0}.states label{display:inline-block;cursor:pointer;padding:10px 20px;border:1px solid #9c8190;margin:0 7px 10px 0}.states input:focus-visible+label{outline:3px solid #ad5178}.states figure{display:none}.states #rest:checked~.rest,.states #pull:checked~.pull,.states #loaded:checked~.loaded{display:block}.states input:checked+label{background:#853b58;color:white}.note{border-left:3px solid #b66584;padding:5px 23px}code{font-size:.9em}@media(max-width:650px){header,main,footer{padding:28px 17px}.reading{font-size:21px}}'''
sources={}
for source in ['tension_score.gd','tension_membrane.gd','tension_handle.gd','tension_fabric.gdshader']:
    p=ROOT/'commons/artifacts/spine_studies'/source
    raw=p.read_bytes(); sources[p.relative_to(ROOT).as_posix()]=hashlib.sha256(raw).hexdigest()
    (OUT/(source+'.html')).write_text('<!doctype html><html lang="en"><meta charset="utf-8"><title>'+E(source)+'</title><style>'+css+'</style><main><a href="index.html#making">Back to the study</a><h1>'+E(source)+'</h1><pre>'+E(raw.decode())+'</pre></main></html>',encoding='utf-8')
raw=(ROOT/'commons/maps'/HALL/'tutorial.md').read_bytes()
(OUT/'making.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="source-sha256" content="'+hashlib.sha256(raw).hexdigest()+'"><title>A little give / making</title><style>'+css+'</style><main><a href="index.html">Back to the encounter</a>'+markdown.markdown(raw.decode(),extensions=['fenced_code','tables','footnotes'])+'</main></html>',encoding='utf-8')
report_path=BASE/'figures'/f'{HALL}-report.json'
report=json.loads(report_path.read_text()) if report_path.exists() else {'passed':False,'checks':[]}
(OUT/'evidence.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(OUT/'sources.json').write_text(json.dumps(sources,indent=2)+'\n',encoding='utf-8')
controls=''.join(f'<input type="radio" name="state" id="{s}" '+('checked ' if i==0 else '')+f'><label for="{s}">{label}</label>' for i,(s,label) in enumerate([('rest','01 / Released'),('pull','02 / Held pull'),('loaded','03 / Released + load')]))
figures=''.join(f'<figure class="{s}"><img src="../2026-10-02-studies-in-the-spine/figures/tension-{s}.png" alt="{caption}"><figcaption>{caption} Same camera inside the actual endless museum.</figcaption></figure>' for s,caption in [('rest','Settled without added load.'),('pull','The same material with one point held forward.'),('loaded','Released again, now carrying an additional 3 kg downward load.')])
reading=''.join('<p>'+E(p)+'</p>' for p in READINGS['tension_membrane'].split('\n\n'))
source,code,instruction=EDITS['tension_membrane']
passed=sum(c['passed'] for c in report['checks'])
page=f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>A little give — Ada / Nengudi</title><style>{css}</style><header><div class="eyebrow">Ada / Soft Bodies / 2 October 2026</div><h1>A little give.</h1><p class="lead">A hand changes the shape. A load changes what it has to carry. Four anchors keep their places.</p><p>Original Ada encounter in relation to Senga Nengudi’s stretched hosiery. Installed after the hanging strips and falling bodies in the Cloth hall.</p><nav><a href="#museum">In the museum</a><a href="#reading">Reading</a><a href="#making">Making</a><a href="#evidence">Checks</a></nav></header><main><section id="museum"><h2>Pull. Wait. Release.</h2><p>Pick up the pink bead. The membrane follows; on release it continues moving. The console supplies a repeatable pull, added load and a separate change in compliance.</p><div class="states">{controls}{figures}</div></section><section id="reading" class="reading">{reading}</section><section id="making"><h2>One change we can follow</h2><div class="note"><p><strong>Lineage:</strong> positions → connected points → forces → fixed attachments → a deforming surface.</p><p>The Cloth hall first changes the pins. This return keeps them fixed while comparing load and material response. The full solver is supplied.</p></div><p>{E(instruction)}</p><pre><code>{E(code)}</code></pre><p><a href="making.html">The current Cloth tutorial</a> · <a href="tension_score.gd.html">Solver source</a> · <a href="tension_membrane.gd.html">Artifact source</a> · <a href="/tutorial-lineage#hall={HALL}">Capability lineage</a></p><details><summary>Reference and what this model leaves out</summary><p>{E(ref_note)}</p><p><a href="{ref_url}">{E(ref_title)}</a></p><p><a href="tension_handle.gd.html">Handle source</a> · <a href="tension_fabric.gdshader.html">Surface shader</a></p></details></section><section id="evidence"><h2>What was checked</h2><p>{passed} / {len(report['checks'])} native checks pass. These cover the actual museum placement, changing load and compliance, fixed anchors, release, reset, XR pickup callbacks with a supplied hand, desktop ray/grab/drop and the side routes. Physical XR and Quest performance remain untested.</p><p><a href="evidence.json">Native results</a> · <a href="sources.json">Source hashes</a></p></section></main><footer><a href="../2026-10-02-studies-in-the-spine/index.html#tension_membrane">All installed artist applications</a></footer></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'README.md').write_text('# A little give\n\nOriginal Nengudi-related tensile application in SoftBodies_Cloth_Physics.\n\nReproduce: publish_tension_study.py, publish_spine_studies.py, capture_spine_studies.py SoftBodies_Cloth_Physics, then republish the two pages and export the softbodies book / tutorial-lineage. Native images are direct Godot viewport output in an isolated runtime copy of the production museum. Sources and test limits are linked on the review.\n',encoding='utf-8')
print(f'Published {REVIEW}: {passed}/{len(report["checks"])} native checks.')
