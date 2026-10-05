"""Publish the paired-time encounter, its current tutorial and native evidence."""
from pathlib import Path
import hashlib, html, json, re
import markdown
from paired_time_study import REVIEW, HALL, READINGS, EDITS, REFERENCES, FOOTNOTE

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations'/REVIEW
BASE = ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine'
OUT.mkdir(parents=True, exist_ok=True)
E = html.escape
refs = '\n\n'.join(f'[{title}]({url}). {note}' for title,url,note in REFERENCES)

making = '''### Compare a rate with an offset

This encounter follows the phase rods and the conveyor in **Forces → Choreography**. The map ID retains the name `Change_Choreography`. Day Zero supplied the repeating update; Change supplied a rate and its accumulation; Oscillation and this hall supplied returning movement and phase. The two dials are an application of that existing toolbox.

Begin with RESET. Each hand makes one turn in twelve seconds. Use DRIFT RIGHT, wait thirty seconds and then reveal READING: the right hand has gained 36°. SAME RATE gives the right hand the left hand's speed while preserving both current positions. The gap stops growing. OFFSET +45° changes only the right position, immediately. ALIGN copies the left position to the right without changing either rate. If their rates still differ, alignment lasts only an instant.

HOLD / RUN pauses these two stored angles, not the player or the museum. READING reveals the current ratio and clockwise phase gap. RESET restores the original angles, equal rates, running state and hidden readout. No controls move the wall or its collider.

The one-line edit above halves the rate difference. Before running it, predict the gap after the same thirty seconds. The relative rate is `(1.02 - 1.0) / 12` turns per second. It gains 0.05 turns, or 18°. At a 4% difference the dials align every 300 seconds; at 2%, every 600 seconds. This is visual alignment modulo a turn, not recovery of a lost history.

### What the program keeps

The production score stores two angles. Each update adds its chosen rate multiplied by the same `delta`:

```gdscript
left_angle = fposmod(left_angle + TAU / PERIOD_SECONDS * delta, TAU)
right_angle = fposmod(right_angle + TAU / PERIOD_SECONDS * right_ratio * delta, TAU)
```

Changing `right_ratio` does not replace either angle. That is why changing speed has no immediate jump. `align()` assigns `right_angle = left_angle`; it has a different job. `fposmod` keeps the displayed angles within one turn. The code discards whole-turn counts, so its readout cannot tell you how many times one dial has lapped the other.

The renderer maps those angles onto identical single-hand dials; all fabrication, pointer controls and the museum player are supplied. Neither dial is a wall clock. They have no independent oscillator, battery or ageing mechanism. Engine stalls advance both through the same elapsed delta; the rate difference is authored explicitly. Full hardware clock synchronization, audio, independent oscillators and lifetime simulation are outside this first edit.
'''
technical = '''### Paired-time implementation

`paired_time_score.gd` is the state model: two scalar angles, a 12-second base period, a right-rate ratio, and a local pause flag. `advance(delta)` accepts finite positive elapsed seconds and wraps each accumulated angle within TAU. Both dials share the engine delta; no random hardware drift is claimed. `paired_time.gd` constructs two matching 1.94-metre dials with 60 marks each, above a solid display wall, and rotates only their hand nodes. Readout updates reuse the labels and meshes. The station supplies seven pointer controls; it adds no player or camera.

Tests exercise no-jump rate changes, retained phase at equal rates, alignment without rate changes, deliberate phase offset, local hold/resume, reset, equal elapsed time at 30 and 144 updates per second, invalid elapsed inputs, bounded long updates, native museum captures and side-route support. Pointer dispatch is tested; physical XR comfort and Quest frame time remain unverified.
'''
critical = '''### The shared pulse

The artist reference makes the difference between an algorithmic return and mortal time consequential. MoMA locates the paired clocks in the context of Gonzalez-Torres's partner's AIDS diagnosis. Ada exposes the exceptional guarantees of a digital pair: both receive the same update, neither ages, and disagreement is a parameter we chose. Equal rates can carry a difference indefinitely. Alignment is a separate intervention. These are inspectable relations, not equivalents for love, illness or loss. Keeping the artist's context beside the technical account prevents synchronization from exhausting what the work can mean.
'''

for name, addition in [('tutorial.md',making),('technical.md',technical),('critical.md',critical)]:
    p=ROOT/'commons/maps'/HALL/name
    text=p.read_text(encoding='utf-8-sig')
    start='<!-- paired-time-reference -->'; end='<!-- /paired-time-reference -->'
    block=start+'\n\n'+addition+'\n\n### References and model limits\n\n'+refs+'\n\n'+end
    if start in text:
        text=re.sub(re.escape(start)+r'.*?'+re.escape(end),lambda _:block,text,flags=re.S)
    else: text=text.rstrip()+'\n\n'+block+'\n'
    if name=='tutorial.md': text=text.replace('Geometry controls wait until the exhibit is clear. RESET returns the original comparison.','These controls change only the dial state. RESET restores this pair without restarting the hall.')
    p.write_text(text,encoding='utf-8')
p=ROOT/'commons/maps'/HALL/'final.md'
text=p.read_text(encoding='utf-8-sig')
if '[^paired-time]:' not in text: p.write_text(text.rstrip()+'\n\n'+FOOTNOTE+'\n',encoding='utf-8')

css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f1eee7;color:#302a31;font:17px/1.65 system-ui}header,main,footer{max-width:1160px;margin:auto;padding:42px 28px}h1{font:clamp(50px,8vw,94px)/1.02 Georgia;margin:24px 0}h2{font:36px/1.2 Georgia}a{color:#8a3f5d;text-underline-offset:4px}nav{display:flex;gap:24px;flex-wrap:wrap}.eyebrow{font-size:12px;letter-spacing:.12em;text-transform:uppercase}.lead{font:26px/1.45 Georgia;max-width:750px}.reading{font:23px/1.65 Georgia;max-width:760px;margin:55px auto}.reading p{margin:0 0 27px}section{padding:32px 0;scroll-margin-top:20px}figure{margin:25px 0}img{width:100%;display:block}figcaption,.small,.footnote{font:13px/1.6 system-ui;color:#6a5e67}details{background:#e7e0d8;padding:22px;margin:26px 0}summary{cursor:pointer;font-weight:600}pre{background:#2a252c;color:#ffe2ed;padding:22px;white-space:pre-wrap;overflow-wrap:anywhere;font:14px/1.6 Consolas,monospace}.states input{position:absolute;opacity:0}.states label{display:inline-block;cursor:pointer;padding:10px 17px;border:1px solid #9a8190;margin:0 7px 10px 0}.states input:focus-visible+label{outline:3px solid #ac4d75}.states figure{display:none}.states #together:checked~.together,.states #drift:checked~.drift,.states #same-rate:checked~.same-rate{display:block}.states input:checked+label{background:#873c59;color:white}.note{border-left:3px solid #b66888;padding:5px 23px}code{font-size:.9em}table{border-collapse:collapse;width:100%}td,th{border-bottom:1px solid #c9bec4;padding:12px;text-align:left} @media(max-width:650px){header,main,footer{padding:25px 17px}.reading{font-size:21px}.states label{font-size:14px}}'''
def page(title,body):
    return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+E(title)+'</title><style>'+css+'</style></head><body>'+body+'</body></html>'

sources={}
for source in ['paired_time_score.gd','paired_time.gd']:
    p=ROOT/'commons/artifacts/spine_studies'/source; raw=p.read_bytes()
    sources[p.relative_to(ROOT).as_posix()]=hashlib.sha256(raw).hexdigest()
    (OUT/(source+'.html')).write_text(page(source,'<main><a href="index.html#making">Back to the encounter</a><h2>'+E(source)+'</h2><pre>'+E(raw.decode())+'</pre></main>'),encoding='utf-8')
raw=(ROOT/'commons/maps'/HALL/'tutorial.md').read_bytes()
(OUT/'making.html').write_text(page('A second together / making','<meta name="source-sha256" content="'+hashlib.sha256(raw).hexdigest()+'"><main><a href="index.html#making">Back to the encounter</a>'+markdown.markdown(raw.decode(),extensions=['fenced_code','tables','footnotes'])+'</main>'),encoding='utf-8')
report_path=BASE/'figures'/f'{HALL}-report.json'
report=json.loads(report_path.read_text()) if report_path.exists() else {'passed':False,'checks':[]}
(OUT/'evidence.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
(OUT/'sources.json').write_text(json.dumps(sources,indent=2)+'\n',encoding='utf-8')
states=[('together','01 / Together','Equal rates and equal phases at the starting position.'),('drift','02 / Thirty seconds later','Right rate ×1.04. After 30 simulated seconds the right hand has gained 36°.'),('same-rate','03 / Same rate','Both rates ×1.00. Twelve further simulated seconds preserve the 36° gap. The hands return to the same pictured positions; equal speed has not closed the gap.')]
controls=''.join(f'<input type="radio" name="state" id="{s}" '+('checked ' if i==0 else '')+f'><label for="{s}">{E(label)}</label>' for i,(s,label,_) in enumerate(states))
figures=''.join(f'<figure class="{s}"><img src="../2026-10-02-studies-in-the-spine/figures/paired-time-{s}.png" alt="{E(caption)}"><figcaption>{E(caption)} Same camera inside the actual endless museum.</figcaption></figure>' for s,_,caption in states)
reading=markdown.markdown(READINGS['paired_time']+'\n\n'+FOOTNOTE,extensions=['footnotes'])
source,code,instruction=EDITS['paired_time']
reference_html=markdown.markdown(refs)
passed=sum(c['passed'] for c in report['checks'])
body=f'''<header><div class="eyebrow">Ada / Forces / Choreography / 2 October 2026</div><h1>A second together.</h1><p class="lead">The hands can share a speed and still carry a distance between them.</p><p>An original Ada study in relation to Felix Gonzalez-Torres’s paired clocks. In the museum after the phase rods and conveyor, before Gravity.</p><nav><a href="#museum">In the museum</a><a href="#reading">Reading</a><a href="#making">Making</a><a href="#evidence">Checks</a></nav></header><main><section id="museum"><h2>Same rate. Different time.</h2><p>Look first. Then change the right rate, let the difference grow, and bring the rates together again. ALIGN is a separate action.</p><div class="states">{controls}{figures}</div><details><summary>The controls in the hall</summary><figure><img loading="lazy" src="../2026-10-02-studies-in-the-spine/figures/paired_time.png" alt="Paired dials and their control console inside the endless museum"><figcaption>The installed study, with its console and clear floor around it.</figcaption></figure><p>DRIFT RIGHT · SAME RATE · OFFSET +45° · ALIGN · HOLD / RUN · READING · RESET</p></details></section><section id="reading" class="reading">{reading}</section><section id="making"><h2>One change we can follow</h2><div class="note"><p><strong>Lineage:</strong> the repeating update → rate × elapsed time → a stored angle → two processes compared.</p><p>The geometry and player controls are supplied. The first edit changes one ratio.</p></div><p>{E(instruction)}</p><pre><code>{E(code)}</code></pre><table><tr><th>Action</th><th>What changes</th><th>What stays</th></tr><tr><td>SAME RATE</td><td>Right speed</td><td>Both current angles</td></tr><tr><td>ALIGN</td><td>Right angle</td><td>Both current rates</td></tr></table><p><a href="making.html">Current hall tutorial</a> · <a href="paired_time_score.gd.html">The small timing score</a> · <a href="paired_time.gd.html">Dial fabrication</a> · <a href="/tutorial-lineage#hall={HALL}">Capability lineage</a></p><details><summary>The reference and the limits of this comparison</summary>{reference_html}<p>The clocks have been replaced by enlarged single-hand dials making a turn in twelve seconds. They share one engine update. The controls expose a chosen rate difference; this is neither hardware drift nor the passage of a life.</p></details></section><section id="evidence"><h2>What was checked</h2><p>{passed} / {len(report['checks'])} native checks pass. Actual museum assembly, pointer dispatch, rate/phase independence, elapsed-time comparison, reset, side routes and native captures. Physical headset use and Quest performance remain untested.</p><p><a href="evidence.json">Native results</a> · <a href="sources.json">Source hashes</a></p></section></main><footer><a href="../2026-10-02-studies-in-the-spine/index.html#paired_time">All installed artist applications</a></footer>'''
(OUT/'index.html').write_text(page('A second together — Ada / Gonzalez-Torres',body),encoding='utf-8')
(OUT/'README.md').write_text('''# A second together

Original Ada application in relation to Felix Gonzalez-Torres. Installed in Forces → Change_Choreography, after the existing phase rods and conveyor; sequence order and primary artifacts are retained.

Both dials share engine delta. The lesson compares accumulated rate difference with a phase offset; it does not simulate independent clock hardware, battery failure or illness. Artist/context references and model limits are linked in the review.

Reproduce: run tools/publish_spine_studies.py, tools/capture_spine_studies.py Change_Choreography, tools/publish_paired_time_study.py, then tools/publish_spine_studies.py. Export the forces book, refresh dependent making snapshots, build tutorial lineage and run tools/verify_spine_studies.py --http --refresh-provenance. The capture runs the actual endless museum with private runtime state.

Native report: evidence.json. Source snapshots: sources.json. No physical headset or learner certification is claimed. Work is saved locally and not committed.
''',encoding='utf-8')
print(f'Published {REVIEW}: {passed}/{len(report["checks"])} native checks.')
