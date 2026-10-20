"""Publish the retained-state hall from native museum and numerical evidence."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT/'ada_run/encounter_pilot/Shader_10_ReactionDiffusion/state'
OUT = ROOT/'doc/book/iterations/2026-10-10-state-in-the-museum'
report = json.loads((RUN/'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = json.loads((OUT/'before/map_data.json').read_text(encoding='utf-8-sig'))
now = json.loads((ROOT/'commons/maps/Shader_10_ReactionDiffusion/map_data.json').read_text(encoding='utf-8-sig'))
def identities(data):
    return sorted(t.split(':')[0] for row in data['layers']['interactables'] for t in row if t.strip())
assert all(t in identities(now) for t in identities(before))
assert (ROOT/'commons/maps/Shader_10_ReactionDiffusion/final.md').read_bytes() == (OUT/'before/final.md').read_bytes()
assert not (ROOT/'commons/maps/Shader_10_ReactionDiffusion/tutorial.md').exists()
log = (RUN/'engine.log').read_text(encoding='utf-8-sig')
solver_log = (ROOT/'ada_run/shader_state_field.log').read_text(encoding='utf-8-sig')
for value in [log, solver_log]:
    assert 'SCRIPT ERROR:' not in value and 'SHADER ERROR:' not in value and 'FAIL ' not in value
assert 'blocked authored entry' not in log and 'blocked t exit' not in log
assert len(re.findall(r'^PASS ',solver_log,re.M)) == 3

views = [
    ('chamber','What stays when you let go?','The sixth shader setting is a quiet experiment inside Endless Museum. A 5.6 m wall, the sphere and the cube share one evolving record. All images are native Godot captures; this is the field after 6,000 updates, held for inspection.'),
    ('seed','Begin with a difference','The room starts held, with three seeded discs. CLEAR removes them. Touch the lower wall or point and press to introduce your own marks; they remain when you let go. RUN then lets neighbouring cells react and diffuse. Nothing is saved to disk; this memory lasts while the artifact remains loaded.'),
    ('console','One nearby bench','RUN/HOLD controls evolution; STEP performs one update. RESET restores the three seeds and holds them, keeping the current FEED and LOSS settings. CLEAR gives a uniform field. INK changes the display colour. The readout shows the update count and the parameters that will govern the next update.'),
    ('wall','The image receives its past','A 96×96 field stores two concentrations. Each update reads the previous state and its neighbours, then writes to a separate target. The visible cells make the finite sampling apparent. Opposite edges of the field connect.'),
    ('sphere','The point returns as a receiver','The familiar sphere reads the same retained field as the wall. Its UV coordinates wrap the image around a body. Chemistry still runs on the flat periodic grid; it does not diffuse along the sphere’s curved metric. The sphere remains solid and stationary.'),
    ('cube','Another body, the same record','The cube’s UV layout places parts of the field on its faces. Changing the receiver changes the reading without creating a second simulation. Its geometry and collision do not change with the pattern.'),
    ('ink','Colour interprets the record','The same held concentrations, with a different ink. Colour is applied after the update and never fed into the reaction rule. This carries forward Colour’s distinction between a stored value and its appearance.'),
    ('looks-like-memory','Appearance can suggest a history','The existing Memory Skin shader receives a declared, seeded noise texture. Its patches move with TIME; it stores no contact. Its name and appearance now sit beside a surface where an encounter really changes the next state.'),
    ('overview','Room to approach and compare','The hall grows from 12×10 m to 25×29 m. Walk around the bench to reach the wall, inspect the sphere and cube, or sit beside the field on existing chair prefabs. Both earlier artifacts remain, relocated beyond the main panel.'),
    ('earlier-panels','The earlier comparisons remain','Left: the original reaction shader still receives no previous image and repeats its first step. Right: the frost shader constructs a growing-looking appearance from noise and time. Its original controls remain. Full-square receivers and larger captions clarify these two cases without changing their calculations.'),
]
sources = [
    'commons/maps/Shader_10_ReactionDiffusion/map_data.json',
    'commons/artifacts/registry/shader_state_chamber.json',
    *[str(p.relative_to(ROOT)).replace('\\','/') for p in sorted((ROOT/'commons/artifacts/shader_state_chamber').iterdir()) if p.suffix in ('.gd','.gdshader','.tscn')],
    'algorithms/shaders/book_of_shaders/shader_10_reactiondiffusion.gd',
    'commons/resourses/shaders/reaction_diffusion.gdshader',
    'algorithms/shaders/book_of_shaders/dla_visual.gdshader',
    'algorithms/shaders/queer_collection_2/memory_skin.gdshader',
    'commons/primitives/chair/chair_modern.tscn',
    'commons/artifacts/jacquard_weaver/weave_geometry.gd',
    'tools/configure_shader_state_setting.py',
    'tools/probes/shader_state_field.gd',
    'tools/probes/shader_state_museum.gd',
    'tools/publish_shader_state_setting.py',
]
manifest = {'hall':'Shader_10_ReactionDiffusion','museum_checks_passed':len(report['checks']),
            'numerical_checks_passed':3,'scope':report['scope'],
            'original_artifact_identities_preserved':identities(before),
            'final_unchanged':True,'tutorial_present':False,'source_sha256':{},'image_sha256':{}}
for rel in sources:
    dst=OUT/'source'/rel;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(ROOT/rel,dst)
    manifest['source_sha256'][rel]=hashlib.sha256(dst.read_bytes()).hexdigest()
for stem,_,_ in views:
    shutil.copy2(RUN/f'{stem}.png',OUT/f'{stem}.png')
    manifest['image_sha256'][f'{stem}.png']=hashlib.sha256((OUT/f'{stem}.png').read_bytes()).hexdigest()
for name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(RUN/name,OUT/name)
shutil.copy2(ROOT/'ada_run/shader_state_field.log',OUT/'solver.log')
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
def esc(value):return html.escape(str(value),quote=True)
style=re.search(r'<style>.*?</style>',(ROOT/'doc/book/iterations/2026-10-10-shaping-in-the-museum/index.html').read_text(encoding='utf-8'),re.S).group()
figures=''.join(f'<figure id="{stem}"><a href="{stem}.png"><img src="{stem}.png" alt="{esc(title)} — native museum view" {"loading=lazy" if i else ""}></a><figcaption><h2>{esc(title)}</h2><p>{esc(caption)}</p></figcaption></figure>' for i,(stem,title,caption) in enumerate(views))
checks=''.join(f'<li>{esc(c["test"])}</li>' for c in report['checks'])
links=''.join(f'<li><a href="source/{p}">{esc(p)}</a></li>' for p in sources)
(OUT/'index.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>What stays when you let go? — Endless Museum</title>{style}
<header><div class="eyebrow">Endless Museum · Shaders / hall 6 · 10 October 2026</div><h1>What stays when you let go?</h1><p>Draw a difference. Retain it. Give the next update a past.</p><nav><a href="#chamber">The room</a><a href="#seed">Begin</a><a href="#console">Controls</a><a href="#sphere">Familiar bodies</a><a href="#earlier-panels">Comparisons</a><a href="#evidence">Evidence</a><a href="../2026-10-10-pink-in-the-museum/index.html">Previous hall</a></nav></header>
{figures}
<section class="facts"><div><h2>What returns</h2><p>The sphere and cube; coordinate lookup; stored records; the distinction between a value and its appearance. Touch or a pointer supplies a local difference.</p></div><div><h2>One primary teaching question</h2><p>What must the next update receive? Hold the field, add a mark, release, take one step, then run. Identify what was stored, what the rule changed, and what the palette merely displayed.</p></div><div><h2>What travels onward</h2><p>An explicit old-state → rule → new-state relation. This prepares Cellular Automata without requiring the learner to rebuild the GPU buffer scheduler as another lesson.</p></div></section>
<section class="evidence" id="evidence"><div class="inner"><span class="badge">{len(report['checks'])} museum checks + 3 numerical checks passed</span><h2 style="margin-top:22px">Actual state, with bounded claims</h2><p>The new shader uses a finite Gray–Scott update, a reaction–diffusion model with local concentrations, diffusion, feed and removal. This is a simplified numerical model, not a chemical experiment. <a href="https://groups.csail.mit.edu/mac/projects/amorphous/GrayScott/">MIT: Gray–Scott model</a>.</p><p>The implementation stores two 12-bit concentrations in RGB8 and alternates groups of render targets. Each requested pass renders once; the previous group stays available until the new result is complete. The active path has no GPU-to-CPU readback. <a href="https://docs.godotengine.org/en/stable/classes/class_subviewport.html">Godot: SubViewport update modes</a>.</p><p>Separate numerical tests check a uniform fixed point, compare one GPU update with an independent CPU equation at all 9,216 cells (maximum vector error 0.000157), and verify that the initial differences spread after 6,000 updates. Museum tests exercise the actual pointer and button receivers, simulated near-hand poses, parameter controls, held state, one-step updates, palette independence, reset and deterministic replay on this renderer.</p><p>The standing route is sampled every quarter metre from entrance to controls, wall and exit. Authored portals are valid; the museum reports CA_Introduction as the next map. Travel through that portal was not exercised. Both old artifact identities remain; the map and their placement change.</p><p>Godot 4.6, compatibility renderer, XR disabled. Ten inspection-camera captures, including an elevated overview. Physical headset use, VR performance, other renderers and learner reconstruction remain untested. The existing default-audio-bus UID error and renderer-feature warnings remain; no script or shader errors occurred.</p><h2>The next writing pass</h2><p>All six shader settings are now built. This hall has no tutorial.md yet. Its final.md is preserved: the earlier green-panel argument remains useful, but its closing claim that the sequence never supplies a past must now be revised around this new comparison. The next pass should reconstruct the focused examples and align both texts with the rooms. The spatial build is not a validated printed lesson.</p><p><a href="SETTING.md">Editable teaching and implementation brief</a> · <a href="report.json">Museum checks</a> · <a href="solver.log">Numerical test log</a> · <a href="engine.log">Museum log</a> · <a href="manifest.json">Source/image hashes</a> · <a href="source_manifest.json">Museum harness manifest</a></p><details><summary>Native checks</summary><ol>{checks}</ol></details><details><summary>Source snapshots and before state</summary><ul>{links}</ul><p><a href="before/map_data.json">Before: map</a> · <a href="before/final.md">Preserved reflection</a> · <a href="before/shader_10_reactiondiffusion.gd">Before: comparison host</a></p></details><details><summary>Reproduce the museum run</summary><p><code>python -X utf8 tools/run_encounter_probe.py Shader_10_ReactionDiffusion --sequence shaders --probe tools/probes/shader_state_museum.gd --render --no-bridges --output-tag state</code></p><p>The numerical probe runs in rendered Godot with <code>--script res://tools/probes/shader_state_field.gd</code>, using the compatibility renderer and XR disabled.</p></details></div></section><footer>Actual Endless Museum captures. Six settings built; focused learner reconstruction comes next.</footer></html>''',encoding='utf-8')
(OUT/'SETTING.md').write_text('''# Reaction–Diffusion — retain the encounter

Carry: familiar sphere/cube; positions → stored records → coordinate lookup → colour interpretation. Primary: one wall retains a mark after release; STEP updates once; RUN evolves; HOLD stops after the current batch. Contrast existing Memory Skin (TIME-driven noise) and the original unbound green/frost rack. Field state, input, update and display have distinct jobs. One primary tutorial operation: read the old state, compute the new state, retain it separately. GPU scheduling/packing remains declared supplied infrastructure; do not turn every implementation detail into another lesson.

Space: 25×29 m hall; 18×13 m chamber, 5.6 m square wall, sphere/cube on plinths, existing chair prefabs. Nearby FEED/LOSS plus RUN/HOLD, STEP, RESET, CLEAR, INK. Walk around the bench to touch the lower wall; pointer input can reach the rest. Near-hand samples every .05 s when entering or moving >.045 m, front side only. Marks are discs, not interpolated strokes. Both original artifact identities retained and relocated; old calculations unchanged, square UV receivers/captions/controls restaged. Authored portals accepted. Next map reported by museum: CA_Introduction; onward travel not tested.

Model: 96×96 periodic square grid; Gray–Scott dt1, Du1, Dv.5, F.055, K.062; nine-cell Laplacian weights centre -1, sides .2, corners .05. F range .02–.065; K .045–.07. Concentrations clamped [0,1] and rounded to 12 bits, packed into RGB8 without colour-space conversion. Two groups of eight SubViewports permit up to eight dependent passes per rendered frame, with immutable prior state. Target 240 model steps/s; low frame rates slow the simulation rather than trigger unlimited catch-up. These are model iterations, not calibrated physical seconds. No readback or CPU chemistry in active path; tests read GPU pixels.

Seed: three discs U=.5, V1 in background U1,V0. RESET holds and restores these while retaining current parameters. CLEAR holds a uniform U1,V0 field. A hand/pointer mark sets U=.5,V1 locally, independently of evolution. Queue bounded to32 marks. INK affects only display; colour uses V through smoothstep(.05,.30). Same flat field maps through each body's UVs; no curved-surface diffusion, shape change or collision change. State lasts while this artifact is loaded; no cross-hall or disk persistence. Memory Skin receives an explicit seed73 noise texture but stores no contacts.

Evidence: 31 native museum assertions, including actual pointer/buttons/sliders, synthetic near-hand input/front-side rejection, hold/step/reset/replay, shared receivers, valid portals and quarter-metre supported standing route. Three separate GPU numerical checks: uniform fixed point; independent one-step CPU comparison at every cell (max vector error .00015640913625); seed spreads after6000 steps (6135 of9216 cells V>.1). Ten native captures. Compatibility renderer/XR off. Teacher-authored evidence, not an independent ghost student. Headset, VR frame budget, cross-renderer reproducibility, onward traversal and learner reconstruction untested. Existing audio-bus UID/renderer warnings remain unrelated.

Text follow-up: no tutorial.md currently exists. Preserve the first five shader skills; teach retention with a minimal real update and an explicit supplied host, then test the printed code separately. final.md is unchanged. Keep its close reading of the unbound square and apparent frost; locate them as earlier comparisons. Replace its hall-wide claim that feedback is absent with the actual new wall. Keep the old 256²/.16/.08 figure identified as the older shader experiment; do not silently equate it with this96²/1/.5 implementation. Ask what evidence permits an inference about a surface's past, and how long that past actually survives. Six spatial settings now exist. Next: focused Shaping reconstruction, then align each tutorial/final pair with its setting.

References: [MIT Gray–Scott model](https://groups.csail.mit.edu/mac/projects/amorphous/GrayScott/); [Godot SubViewport](https://docs.godotengine.org/en/stable/classes/class_subviewport.html).
''',encoding='utf-8')
print(json.dumps({'page':str(OUT/'index.html'),'images':len(views),'museum_checks':len(report['checks']),'numerical_checks':3}))
