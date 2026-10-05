"""Publish only observed native museum views of the procedural pipe canopy."""
from pathlib import Path
import hashlib
import html
import json
import shutil

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-02-glossy-pipe-ceiling'
FIGURES = ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine/figures'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((FIGURES/'LSystems_Grammars_And_Curves-report.json').read_text(encoding='utf-8'))
assert report['passed'] and any(c['name'] == 'thickest densest woven pipes do not intersect' and c['passed'] for c in report['checks'])
for rule in ['weave','ribs','returns']:
    shutil.copy2(FIGURES/f'tube-ceiling-{rule}.png',OUT/f'{rule}.png')
shutil.copy2(FIGURES/'tube_painting.png',OUT/'room.png')
(OUT/'evidence.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
paths = ['commons/primitives/pipes/pipe_canopy.gd','commons/primitives/pipes/pipe_layout.gd',
         'commons/primitives/pipes/swept_run.gd','commons/primitives/pipes/swept_tube.gd',
         'commons/artifacts/spine_studies/pipe_ceiling.gd','commons/artifacts/spine_studies/tube_painting.gd',
         'commons/artifacts/spine_studies/station.gd','commons/testing/pipe_ceiling_checks.gd']
hashes = {p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths}
(OUT/'sources.json').write_text(json.dumps(hashes,indent=2)+'\n',encoding='utf-8')
links = []
for p in paths:
    name = Path(p).name
    (OUT/(name+'.html')).write_text('<!doctype html><meta charset="utf-8"><title>'+html.escape(name)+'</title><style>body{margin:3rem;background:#f1ede7;color:#222}pre{white-space:pre-wrap;font:14px/1.7 monospace}</style><h1>'+html.escape(name)+'</h1><pre>'+html.escape((ROOT/p).read_text(encoding='utf-8'))+'</pre>',encoding='utf-8')
    links.append('<a href="'+name+'.html">'+name+'</a>')
page = '''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>The line becomes a ceiling — Ada</title>
<style>*{box-sizing:border-box}body{margin:0;background:#f3efe8;color:#29252a;font:19px/1.7 Georgia,serif}header,main,footer{max-width:1360px;margin:auto;padding:42px 30px}header{padding-bottom:28px}h1{font-weight:400;font-size:clamp(45px,7vw,88px);line-height:1.06;max-width:900px;margin:18px 0}h2{font-size:33px;font-weight:400;line-height:1.2}.eyebrow,nav,figcaption,.small,button,dt{font:13px/1.65 system-ui,sans-serif}.eyebrow{letter-spacing:.14em;text-transform:uppercase;color:#973e63}.lead{font-size:25px;max-width:780px}nav,.choices{display:flex;gap:12px;flex-wrap:wrap}nav{gap:28px}a{color:#953956;text-underline-offset:4px}figure{margin:0 0 42px}img{display:block;width:100%;height:auto;background:#25232b}figcaption{color:#625b62;padding:12px 0}.choices{margin-bottom:16px}button{border:1px solid #a2979f;color:#42323d;background:transparent;border-radius:40px;padding:10px 24px;font-size:15px;cursor:pointer}button[aria-pressed="true"]{background:#883958;color:#fff;border-color:#883958}button:focus-visible,a:focus-visible{outline:3px solid #cd6c97;outline-offset:4px}section{scroll-margin-top:22px;margin-bottom:58px}.columns{display:grid;grid-template-columns:1fr 1fr;gap:60px}.reading{max-width:690px;font-size:25px;line-height:1.85;margin:65px auto}dl{display:grid;grid-template-columns:120px 1fr;gap:12px 15px}dt{font-weight:650;letter-spacing:.03em}dd{margin:0;font-size:18px}.small{color:#625b62}details{border-top:1px solid #c9bdc4;padding:20px 0}summary{cursor:pointer}.sources{display:flex;gap:16px;flex-wrap:wrap}code{font-size:.8em}footer{border-top:1px solid #c9bdc4}@media(max-width:740px){.columns{grid-template-columns:1fr;gap:20px}header,main,footer{padding:25px 18px}.reading{font-size:22px}h2{font-size:29px}dl{grid-template-columns:90px 1fr}}</style></head><body>
<header><div class="eyebrow">Ada · Grammars and Curves → Architecture · 2 October 2026</div><h1>The line becomes<br>a ceiling.</h1><p class="lead">A hollow sweep, repeated at the scale of a room. Large glossy pipes weave, branch and return above the work we have already begun.</p><nav><a href="#museum">Underneath</a><a href="#controls">Change the rule</a><a href="#reading">Reading</a><a href="#making">Making</a></nav></header>
<main><section id="museum">COMPARISON
<div class="columns"><div><h2>One small rule reaches overhead.</h2><p>The same pipe builder that makes a hand-drawn run now spans the bay. A local reflection probe lets the lacquer catch the surrounding room; open mouths show the pipes’ hollow construction.</p><p>The weave alternates above and below. Ribs branch from a central run. Each return goes out, bends through a semicircle and comes back. These are three arrangements of the same surface construction.</p></div><div><h2>Use it to make space.</h2><p>This system can make ceiling canopies, suspended service runs, repeated arches and passages beneath pipework. Here it forms a canopy over the drawing and patching bay, with an open roof beyond.</p><p>Its place in the spine is the later sweep lesson, after paths, mesh, circular sampling, rotation and arrays. Architecture follows. The change in scale puts those earlier tools to work together.</p></div></div></section>
<section id="controls"><h2>Look for the small console on the left.</h2><dl><dt>RULE</dt><dd>Weave → returns → ribs. Change the arrangement while retaining the finish.</dd><dt>DIAMETER</dt><dd>0.36, 0.60 or 0.84 metres across.</dd><dt>REPEAT</dt><dd>Three, five or seven lanes or branch stations.</dd><dt>FINISH</dt><dd>Pink lacquer, pale enamel, chrome. The screenshots compare the same pink finish.</dd><dt>RESET</dt><dd>Restore the five-lane pink weave. The drawing and sound patch keep their state.</dd></dl><p>These buttons work in the museum. The three buttons above compare saved native captures.</p><figure><img loading="lazy" src="room.png" alt="The tube and cable workbench and modular synthesizer beneath the new pink pipe canopy"><figcaption>The application remains in LSystems_Grammars_And_Curves. Drawing, pipe connections and the small patch-controlled machine share the bay. Both side aisles remain open.</figcaption></figure></section>
<section id="reading" class="reading"><p>Look up. Large pink pipes pass over and under one another. Their gloss bends the room back towards us. Change the rule at the small console: the weave becomes ribs, then long returning loops.</p><p>What fitted in a hand now reaches across the bay. Repetition has given the line the scale of a ceiling. We are standing inside one of its arrangements.</p></section>
<section id="making"><h2>Keep the surface. Change the path.</h2><p><code>pipe_canopy.gd</code> generates an ordinary layout for the existing <code>PipeLayout</code>. Every run goes through <code>swept_run.gd</code> and the shared hollow mesh builder. The museum wrapper adds supports, lights and controls.</p><p>For the first comparison, keep diameter and repetition fixed. Change RULE. Only then increase the diameter: the gaps between the runs become part of the choice.</p><p><a href="../2026-10-02-tube-painting-a-line-takes-room/making.html">Read the making lesson</a> · <a href="/tutorial-lineage#node=sweep">The sweep in the capability ladder</a></p>
<details><summary>Construction and limits</summary><p>The widest, densest weave retains separation between crossing surfaces. All 27 offered layout combinations keep the pipes above 5.8 m and within the bay. Geometry rebuilds only when a layout control changes; finish changes reuse it. A freestanding frame carries the hangers.</p><p>These are visual hollow pipes. The rib joints share logical endpoints but their skins overlap; they are not welded plumbing or a fluid simulation. The canopy surface is not collidable. The support posts and console are. A once-updated local probe captures the surrounding room, so later moving figures and drawing changes are not reflected live. Settings last for the hall visit.</p><p>CHECK_COUNT native checks passed, including maximum-density mesh generation, crossing separation, real pointer colliders and dispatch, unchanged drawing/audio state, and both museum aisles. Physical Quest performance and headset comfort still need a hardware pass.</p></details>
<p class="small"><a href="evidence.json">Native results</a> · <a href="sources.json">Source snapshot</a></p><details><summary>Read the implementation</summary><div class="sources">SOURCE_LINKS</div></details></section></main>
<footer><a href="../2026-10-02-patch-and-motion/index.html#museum">A cord makes something happen</a> · <a href="../2026-10-02-tube-painting-a-line-takes-room/index.html#forms">Tube, pipe and cable forms</a></footer>
</body></html>'''
# Book-review deliberately disallows scripts. Native radios and CSS retain
# keyboard-accessible comparisons without weakening the server's policy.
captions = {'weave':'Two perpendicular families alternate their height.',
            'ribs':'Repeated branches meet a central run.',
            'returns':'Each run folds through a semicircular bend and comes back.'}
comparison = '<fieldset class="comparison"><legend class="sr">Compare ceiling rules</legend>'
for index, rule in enumerate(captions,1):
    checked = ' checked' if index == 1 else ''
    comparison += f'<input class="sr" type="radio" name="pattern" id="choice-{rule}"{checked}><label for="choice-{rule}">{index:02} · {rule.title()}</label>'
comparison += '<div class="views">'
for rule, caption in captions.items():
    comparison += f'<figure class="view view-{rule}"><img src="{rule}.png" alt="Native Godot museum view of glossy pink pipe ceiling: {rule}"><figcaption>{rule.upper()} — {caption} Native Godot capture, viewed from 1.8 m above the museum floor. Same viewpoint, finish, diameter and repetition in all three views.</figcaption></figure>'
comparison += '</div></fieldset>'
css = '''.comparison{border:0;padding:0;margin:0;min-width:0}.sr{position:absolute;width:1px;height:1px;padding:0;overflow:hidden;clip-path:inset(50%);white-space:nowrap}.comparison label{display:inline-block;font:15px/1.65 system-ui,sans-serif;border:1px solid #a2979f;border-radius:40px;padding:10px 24px;margin:0 10px 16px 0;cursor:pointer}.comparison input:checked+label{background:#883958;color:#fff;border-color:#883958}.comparison input:focus-visible+label{outline:3px solid #cd6c97;outline-offset:4px}.view{display:none}#choice-weave:checked~.views .view-weave,#choice-ribs:checked~.views .view-ribs,#choice-returns:checked~.views .view-returns{display:block}'''
page = page.replace('</style>',css+'</style>').replace('COMPARISON',comparison)
(OUT/'index.html').write_text(page.replace('CHECK_COUNT',str(len(report['checks']))).replace('SOURCE_LINKS',''.join(links)),encoding='utf-8')
(OUT/'STATUS.md').write_text('''# The line becomes a ceiling

User requested large glossy procedural ceiling pipes using the pipe/cable/tube system. Added a reusable PipeLayout canopy generator and a separately controlled application above the existing tube workbench in LSystems_Grammars_And_Curves. Three rules, three diameters, three repetition settings and three finishes. The native museum route, earlier lessons and existing drawing/patch controls remain intact.

All screenshots originate inside the actual endless museum. Automated native evidence is in evidence.json; physical Quest use is not verified. Rib joints overlap rather than Boolean-weld. No fluid or electrical flow is implied. The reflection probe captures the room once. Work remains local and uncommitted.

Reproduce: python tools/capture_spine_studies.py LSystems_Grammars_And_Curves; python tools/publish_pipe_ceiling.py; python tools/publish_spine_studies.py; python tools/publish_tube_painting.py; python tools/export_book_captures.py --sequence lsystems; python tools/verify_spine_studies.py --http --refresh-provenance.
''',encoding='utf-8')
print(f'Published {OUT}: {len(report["checks"])} native checks.')
