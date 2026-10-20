"""Publish the native three-stage experiment and its exact receipts."""
from pathlib import Path
import hashlib
import json
import shutil
import markdown

ROOT = Path(__file__).resolve().parents[4]
HERE = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Random_Entropy/prefab-hybrids'
for name in ['report.json', 'hall-zero.png', 'hall-half.png', 'hall-full.png', 'hall-hybrid-detail.png', 'source_manifest.json']:
    shutil.copy2(RUN/name, HERE/('museum-report.json' if name == 'report.json' else name))
reports = [json.loads((HERE/name).read_text(encoding='utf8')) for name in ['verification.json', 'museum-report.json']]
assert all(r['passed'] for r in reports)
counts = [len(r['checks']) for r in reports]
wall = json.loads((ROOT/'commons/maps/Random_Entropy/writing_wall.json').read_text(encoding='utf8'))
assert wall['order'][:6] == ['shannon_entropy_meter', 'entropy_jar', 'entropy_compartments', 'entropy_axiom', 'entropy_ruin', 'signal_room']
registry = json.loads((ROOT/'commons/artifacts/registry/prefab_disorder.json').read_text(encoding='utf8'))
assert registry['artifacts']['prefab_disorder']['scene'] == 'res://commons/artifacts/prefab_disorder/prefab_disorder.tscn'
style = '''body{font:18px/1.55 system-ui,sans-serif;color:#213335;background:#f3f0e7;margin:0}main{max-width:1400px;margin:auto;padding:24px}h1{font:clamp(28px,4vw,44px)/1.1 Georgia,serif;margin:8px 0 14px}h2{font:28px Georgia,serif}p{max-width:84ch}a{color:#176567}nav{display:flex;gap:20px;flex-wrap:wrap}header small{letter-spacing:.12em;text-transform:uppercase;color:#56716a}figure{margin:0}img{display:block;width:100%;height:auto;max-height:72vh;object-fit:contain;background:#111d25}figcaption{padding:10px 14px;background:#e4e8df}section{margin:28px 0}.stages{padding-top:10px}.stages input{accent-color:#216b64}.stages label{display:inline-block;padding:10px 16px 10px 4px;margin-bottom:10px;cursor:pointer}.stage{display:none}#original:checked~.views .original,#parts:checked~.views .parts,#joining:checked~.views .joining,#hybrids:checked~.views .hybrids{display:block}table{border-collapse:collapse}td,th{padding:10px;text-align:left;border-bottom:1px solid #bbc9bf}code{font-size:.9em}pre{overflow:auto}.evidence{border-top:1px solid #aab8ae;padding-top:16px}'''
html = f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Originals → parts → hybrids · Ada Research</title><style>{style}</style><main>
<header><small>Ada Research / Random_Entropy / 15 October 2026</small><h1>Parts enter new relationships</h1>
<p>The slider now travels from original objects through separation into four hybrids—and back. Fifty parts remain available throughout. Each hybrid joins parts from at least three source objects.</p>
<nav><a href="#detail">Look closer</a><a href="#room">In the room</a><a href="guide.html">Experiment and reconstruction guide</a><a href="/book-review/commons/maps/Random_Entropy/tutorial.md">Updated tutorial</a></nav></header>
<div class="stages" role="group" aria-label="Native capture stages">
<input type="radio" name="stage" id="original"><label for="original">0 · Originals</label>
<input type="radio" name="stage" id="parts"><label for="parts">0.5 · Separated</label>
<input type="radio" name="stage" id="joining"><label for="joining">0.75 · Recombining</label>
<input type="radio" name="stage" id="hybrids" checked><label for="hybrids">1 · Hybrids</label>
<div class="views">
<figure class="stage original"><img src="zero.png" alt="Matching original box, monitor, stool and microscope on both tables"><figcaption>0: original assemblies. Both tables contain the same objects.</figcaption></figure>
<figure class="stage parts"><img src="parts.png" alt="Whole prefabs scattered on the left, their mesh parts separated on the right"><figcaption>0.5: whole objects scatter intact on the left; parts separate on the right.</figcaption></figure>
<figure class="stage joining"><img src="joining.png" alt="The separated parts moving between their former objects towards new assemblies"><figcaption>0.75: parts cross their former object boundaries. KEEP can preserve this intermediate state.</figcaption></figure>
<figure class="stage hybrids"><img src="hybrids.png" alt="Original objects restored on the left, four mixed-source hybrids assembled on the right"><figcaption>1: the originals return on the left; the right becomes Screen Walker, Petal Scope, Box Observatory and Viewing Perch.</figcaption></figure>
</div></div>
<p>These are native Godot captures. The live STAGE slider and ORIGINAL / PARTS / HYBRIDS presets are in the Entropy hall at grid (13, 3), near the entrance, and in the standalone <code>prefab_disorder/preview.tscn</code>.</p>
<section id="detail"><h2>What does the new form seem able to do?</h2><figure><img src="hybrid-detail.png" alt="Close view of the four hybrids, with donor labels"><figcaption>The box carries microscope optics; the monitor face borrows stool feet. Original materials stay visible. Joining rules are authored, and each completed hybrid is uniformly fitted to its pad.</figcaption></figure>
<p>Follow one recognisable part into another assembly. Where does an old relation disappear? When does a new use become imaginable? A form that stays confusing is useful evidence too.</p></section>
<section><h2>Keep a transition, then return</h2><p>Start with seed 435. Keep an intermediate position, return to ORIGINAL, change the seed, then REPLAY. Reopen the scene to reconstruct the same arrangement. Saved records include raw draws, hybrid membership, target poses and slider position. Older separation records still reproduce their previous arrangements.</p>
<p>SEED +1 changes the separated field. The four hybrid recipes stay fixed. The next research step is to revise one graft while retaining that field and compare what the changed relationship suggests.</p></section>
<section id="room"><h2>Installed in the Entropy hall</h2><figure><img src="hall-full.png" alt="The hybrid bench in the actual Entropy museum hall"><figcaption>The optional encounter keeps its entrance position. The six-stop main room/final order remains intact.</figcaption></figure></section>
<section class="evidence"><h2>Evidence and what remains open</h2><p><strong>{counts[0]} apparatus checks and {counts[1]} actual-hall checks pass.</strong> They cover every part's membership, original materials, reversible poses, floor clearance, fresh reconstruction, earlier records, physical preset callbacks and room approaches. Human recognition, independent learner reconstruction and headset comfort remain to be tested.</p>
<p>This is a geometric assembly experiment. It does not measure Shannon or Boltzmann entropy, or demonstrate spontaneous self-assembly.</p>
<nav><a href="verification.json">Apparatus receipt</a><a href="museum-report.json">Hall receipt</a><a href="kept-trial.json">Saved hybrid record</a><a href="manifest.json">Source fingerprints</a><a href="../2026-10-15-prefab-disorder/index.html">Earlier separation study</a></nav></section></main></html>'''
(HERE/'index.html').write_text(html,encoding='utf8')
guide = (ROOT/'commons/artifacts/prefab_disorder/README.md').read_text(encoding='utf8').replace('../../../doc/book/iterations/2026-10-15-prefab-hybrids/README.md', 'index.html')
shutil.copy2(ROOT/'commons/artifacts/prefab_disorder/README.md',HERE/'implementation.md')
(HERE/'guide.html').write_text('<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Hybrid experiment guide</title><style>'+style+'</style><main><a href="index.html">← Native review</a>'+markdown.markdown(guide,extensions=['tables','fenced_code'])+'</main></html>',encoding='utf8')
paths = list((ROOT/'commons/artifacts/prefab_disorder').glob('*.gd')) + list((ROOT/'commons/artifacts/prefab_disorder').glob('*.tscn'))
paths += [ROOT/'commons/artifacts/registry/prefab_disorder.json']
paths += [ROOT/'commons/maps/Random_Entropy'/name for name in ['map_data.json','writing_wall.json','tutorial.md','final.md','artifacts.md']]
for source in ['cardboard_box','computer_monitor','lab_stool','microscope']:
    paths += [ROOT/'commons/artifacts'/source/(source+suffix) for suffix in ['.gd','.tscn']]
(HERE/'manifest.json').write_text(json.dumps({'checks':counts,'main_order':wall['order'][:6],'sha256':{p.relative_to(ROOT).as_posix():hashlib.sha256(p.read_bytes()).hexdigest() for p in paths}},indent=2),encoding='utf8')
(HERE/'README.md').write_text(f'''# Originals → parts → hybrids

15 October 2026. User asks for reversible cross-object recombination in the installed prefab study.

[Visual review](index.html) · [Guide](implementation.md) · [Apparatus receipt](verification.json) · [Hall receipt](museum-report.json) · [Saved hybrid trial](kept-trial.json) · [Source fingerprints](manifest.json).

The slider now passes originals (0), separated parts (0.5), and four authored mixed-source assemblies (1), in both directions. Left stays a whole-object comparison. All fifty meshes and their materials are retained once per side; each hybrid has at least three donors. Recipes preserve selected local bundles, then fit the completed hybrid uniformly to 0.55 m. These are geometric grafts, not mechanically validated machines.

Native apparatus checks pass {counts[0]}/{counts[0]}; actual-hall checks pass {counts[1]}/{counts[1]}. Tests cover backward traversal, continuous transition, clearance throughout the path, all-part membership, materials, fresh-scene replay, invalid-record rejection, old full/fractional receipt compatibility and physical presets. Hall checks include supported/clear approaches, slider reach band, replay and the existing Shannon/Boltzmann readings. Existing Jolt solver-bias and sequence-loading warnings remain in the logs; no new script/runtime error occurred.

Run `python -X utf8 doc/book/iterations/2026-10-15-prefab-hybrids/run.py` for standalone checks; run `python -X utf8 tools/run_encounter_probe.py Random_Entropy --sequence randomness --render --no-bridges --output-tag prefab-hybrids --probe doc/book/iterations/2026-10-15-prefab-hybrids/museum_probe.gd` for actual-hall checks; then run `publish.py` here to refresh review receipts.

Tutorial, optional writing-wall magnet, registry and research plan/card now match the installed stages. The main final route remains ledger → jar → two compartments → displacement enclosure → ruin → signal room. The 48-value seed bench remains the first research pilot.

Human recognition, independent learner reconstruction, headset comfort and Quest performance are untested. Next: keep one intermediate graft, identify a part changing roles, then revise one joining rule with the separation field held fixed. The matched-base-motion refinement remains a separate proposal; current whole/part comparisons use different draw assignments. No entropy value or spontaneous self-assembly is inferred from these forms.
''',encoding='utf8')
print('Published:',HERE/'index.html',counts)
