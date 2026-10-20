"""Publish the fourth shader setting with native captures and reproducible evidence."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil

ROOT = Path(__file__).resolve().parents[1]
RUN = ROOT / 'ada_run/encounter_pilot/Shader_09_FBM/bathhouse'
OUT = ROOT / 'doc/book/iterations/2026-10-10-water-in-the-museum'
OUT.mkdir(parents=True, exist_ok=True)
report = json.loads((RUN/'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
before = json.loads((OUT/'before/map_data.json').read_text(encoding='utf-8-sig'))
now = json.loads((ROOT/'commons/maps/Shader_09_FBM/map_data.json').read_text(encoding='utf-8-sig'))
def identities(doc):
    return sorted(t.split(':')[0].split('#')[0] for row in doc['layers']['interactables'] for t in row if t.strip())
assert identities(before) == identities(now)
assert (ROOT/'commons/maps/Shader_09_FBM/final.md').read_bytes() == (OUT/'before/final.md').read_bytes()
log = (RUN/'engine.log').read_text(encoding='utf-8-sig')
assert 'SCRIPT ERROR:' not in log and 'SHADER ERROR:' not in log
assert 'blocked authored entry' not in log and 'blocked t exit' not in log

views = [
    ('bathhouse','Water becomes a place to cross','The existing FBM hall is now a bathhouse under the museum sky: an eleven-metre square basin, a glass bridge, two familiar geometric bodies and the four original noise studies. This is a native Godot view of the actual hall.'),
    ('console','Hold one field and compare its uses','SCALES chooses one to four octaves. RELIEF sets a maximum displacement of 0–0.25 m. COLOUR, NORMAL and HEIGHT use the same field and phase. TIME moves or holds the pool; RESET returns to a held three-scale study. The supporting wall graphs retain their own animation.'),
    ('bridge','What carries you?','The bridge has fixed collision at floor height. The water lies 40 cm below it and remains below its underside even at maximum relief. Light, colour and vertex movement suggest water; there is no buoyancy, fluid simulation or water collider.'),
    ('colour','1 / Colour','The field changes pigment across a flat plane. Position, field phase and camera are held for this three-image comparison. The ordinary surface normal still participates in lighting.'),
    ('normal','2 / Normal','The same field supplies an approximate slope normal. Highlights change, while the plane remains flat. Native GPU readback confirms that this mode leaves the silhouette unchanged.'),
    ('height','3 / Height','The vertices now rise and fall using that field; the calculated normals remain. The pool edge changes silhouette. The fixed glass bridge and basin collision are unaffected.'),
    ('one-scale','One scale','A broad noise field, viewed from the side of the pool. Time is held. This is the same height operation with one octave.'),
    ('four-scales','Four scales','Each added octave doubles sampling frequency and halves its weight. The sum is normalized by total weight so RELIEF remains a bound. This differs deliberately from the unnormalized sum on the supporting FBM graph.'),
    ('graphs','The wider family remains','FBM, Ridged, Turbulence and Domain Warp retain their existing shader calculations. Their displays now use full-square UVs and their controls sit at hand height. The passage around the left end of this wall leads onward to Pink Extravaganza.'),
    ('overview','A basin with an approach and a way onward','The 26 × 29 m hall gives the pool a clear approach, routes along its sides and a crossing. The cube, sphere, existing chair prefabs and pale colonnade give the shader a setting. All three prior exhibit identities remain; their positions change to fit the new room.'),
]
sources = [
    'commons/maps/Shader_09_FBM/map_data.json',
    'commons/artifacts/basin_water/basin_water.gd',
    'commons/artifacts/basin_water/basin_water.gdshader',
    'commons/artifacts/basin_water/basin_water.tscn',
    'commons/artifacts/basin_water/water_study.gd',
    'commons/artifacts/basin_water/layered_water.gdshader',
    'algorithms/shaders/book_of_shaders/shader_09_fbm.gd',
    'algorithms/shaders/book_of_shaders/fbm_basic.gdshader',
    'algorithms/shaders/book_of_shaders/fbm_ridged.gdshader',
    'algorithms/shaders/book_of_shaders/fbm_turbulence.gdshader',
    'algorithms/shaders/book_of_shaders/fbm_domain_warp.gdshader',
    'tools/probes/shader_water_museum.gd',
    'tools/configure_shader_water_setting.py',
]
manifest = {'hall':'Shader_09_FBM', 'checks_passed':len(report['checks']), 'scope':report['scope'],
            'prior_artifact_identities_preserved':True, 'positions_changed':True,
            'final_manuscript_unchanged':True, 'source_sha256':{}, 'image_sha256':{}}
for rel in sources:
    dst=OUT/'source'/rel; dst.parent.mkdir(parents=True,exist_ok=True); shutil.copy2(ROOT/rel,dst)
    manifest['source_sha256'][rel]=hashlib.sha256(dst.read_bytes()).hexdigest()
for stem,_,_ in views:
    shutil.copy2(RUN/f'{stem}.png',OUT/f'{stem}.png')
    manifest['image_sha256'][f'{stem}.png']=hashlib.sha256((OUT/f'{stem}.png').read_bytes()).hexdigest()
for name in ['report.json','source_manifest.json','engine.log']:shutil.copy2(RUN/name,OUT/name)
(OUT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
def esc(v):return html.escape(str(v),quote=True)
style=re.search(r'<style>.*?</style>',(ROOT/'doc/book/iterations/2026-10-10-shaping-in-the-museum/index.html').read_text(encoding='utf-8'),re.S).group()
figures=''.join(f'<figure id="{stem}"><a href="{stem}.png"><img src="{stem}.png" alt="{esc(title)} — native museum view" {"loading=lazy" if i else ""}></a><figcaption><h2>{esc(title)}</h2><p>{esc(caption)}</p></figcaption></figure>' for i,(stem,title,caption) in enumerate(views))
checks=''.join(f'<li>{esc(c["test"])}</li>' for c in report['checks'])
links=''.join(f'<li><a href="source/{p}">{esc(p)}</a></li>' for p in sources)
(OUT/'index.html').write_text(f'''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Water inside Endless Museum</title>{style}
<header><div class="eyebrow">Endless Museum · Shaders / hall 4 · 10 October 2026</div><h1>What carries you over the water?</h1><p>A field acquires several scales. Its values can colour a surface, change its normals or move its vertices. You cross the result on glass.</p><nav><a href="#bathhouse">The room</a><a href="#console">Controls</a><a href="#colour">Three operations</a><a href="#one-scale">Noise scales</a><a href="#overview">Above the room</a><a href="#evidence">Evidence</a><a href="../2026-10-10-materials-in-the-museum/index.html">Previous hall</a></nav></header>
{figures}
<section class="facts"><div><h2>What returns</h2><p>Noise supplied a field. Patterns supplied sampling coordinates. Materials supplied normal/view response. The sphere and cube remain rigid beside a plane that can now change its visual height.</p></div><div><h2>One operation to learn</h2><p>Accumulate noise at several frequencies and weights. First hold time; change only the number of scales. Then compare what the same field does when used for colour, normal and vertex position.</p></div><div><h2>What travels onward</h2><p>Appearance, geometry and physical support can disagree. Pink Extravaganza can compose these choices into a stranger setting. A later retained encounter must distinguish an animated formula from a simulation that stores state.</p></div></section>
<section class="evidence" id="evidence"><div class="inner"><span class="badge">{len(report['checks'])} native checks passed</span><h2 style="margin-top:22px">What was tested</h2><p>The actual museum loads the authored hall and all three previous artifact identities. Slider and button receivers update the pool. Native GPU comparisons check octaves, frozen phase, normal response and silhouette displacement. Tests also confirm that ordinary BasinWater instances and unconfigured graph racks retain their previous defaults.</p><p>A route from the entrance, across the bridge and around the graph wall to the exit is sampled every quarter metre for floor support and standing clearance. Rays hit the glass at deck height and the basin floor 1.2 m below beside it. Both authored portal positions are accepted without a fallback; travel into the following hall was not exercised. The extra gate that blocked the entrance in the first run is disabled for this hall.</p><p>Godot 4.6, compatibility renderer, XR disabled. The screenshots use inspection cameras with the player costume disabled for capture; the production wardrobe is unchanged. Headset interaction, VR performance and learner reconstruction remain open. The existing unresolved default-audio-bus UID and renderer feature warnings appear in the log; the final run has no script or shader errors.</p><p>This completes a setting pass. The existing final.md remains unchanged and still describes the earlier small, unadjustable sine/noise pool. Its spatial details need aligning when we write the focused lesson. No tutorial.md exists in this map folder yet. These checks validate the installation, not an unwritten learner program.</p><p><a href="report.json">Checks</a> · <a href="engine.log">Engine log</a> · <a href="manifest.json">Source and image hashes</a> · <a href="source_manifest.json">Museum harness manifest</a> · <a href="SETTING.md">Editable brief</a></p><details><summary>Native checks</summary><ol>{checks}</ol></details><details><summary>Sources and before state</summary><ul>{links}</ul><p><a href="before/map_data.json">Before: map</a> · <a href="before/final.md">Unchanged reflection</a> · <a href="before/basin_water.gd">Before: water</a> · <a href="before/shader_09_fbm.gd">Before: graph rack</a></p></details><details><summary>Reproduce</summary><p><code>python -X utf8 tools/run_encounter_probe.py Shader_09_FBM --sequence shaders --probe tools/probes/shader_water_museum.gd --render --no-bridges --output-tag bathhouse</code></p></details></div></section><footer>Ten native Godot views. The overview camera is elevated; all other room cameras are at standing eye height.</footer></html>''',encoding='utf-8')
(OUT/'SETTING.md').write_text('''# FBM — a field becomes water

Carry: field sampling, normal/view response, sphere/cube. Core: accumulate noise at increasing frequency and decreasing weight. Pool uses 1–4 value-noise octaves; frequency doubles, weight halves; normalize by weight sum to bound signed height. Supporting FBM graph retains its existing unnormalized sum. Compare one held field: colour → normal → vertex height. TIME moves/holds only the pool; RESET restores 3 scales, relief .22 m, height mode, phase 0 held. Relief maximum .25 m. Mean water -.40 m; fixed bridge top 0, bottom -.06 m. No water collider, buoyancy, fluid state, depth refraction or simulated reflections.

Space: 26×29 m museum hall; 11×11 m basin, depth 1.2 m, no fire; explicit 1.8 m glass bridge; colonnade and existing chair prefabs. Original basin_water/dark_sphere/shader_09_fbm identities retained and relocated. Study is opt-in on BasinWater; other instances retain original shader. Four original graph shaders retained, full-square UV receivers, controls raised. Extra gate disabled; authored entrance/exit valid. Follow the left end of the graph wall onward to Pink Extravaganza.

Evidence: report.json, native GPU/control/route/default checks and ten captures. Compatibility renderer, XR disabled. Capture disables costume only in the isolated harness. No headset/performance/learner reconstruction/next-hall travel claim.

Text follow-up: preserve reflection's appearance/support question. Update obsolete 7×3 dimensions, whole glass lid, missing controls and sine-based pool claims. Explain the normalized study vs the supporting graph's raw sum. tutorial.md absent: reconstruct the small layered field, use supplied room/bridge/control infrastructure, one complete minimal runnable program, test printed code separately. Next spatial pass: Pink Extravaganza.
''',encoding='utf-8')
print(json.dumps({'page':str(OUT/'index.html'),'images':len(views),'checks':len(report['checks'])}))
