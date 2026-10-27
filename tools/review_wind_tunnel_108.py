"""Package the explicitly inspected floor108 native, model and editor evidence."""
import hashlib,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/wind-tunnel-108'
DOC=ROOT/'doc/book/iterations/2026-10-24-wind-tunnel'
def read(name):return json.loads((OUT/name).read_text(encoding='utf8'))
receipts={k:read(v) for k,v in {
 'desktop':'native-desktop.json','synthetic_xr':'native-xr.json',
 'editor':'editor-checks.json','editor_visual':'editor-visual.json',
 'publish':'publish.json','export':'export.json'}.items()}
assert all(r['passed'] for r in receipts.values())
for mode in ['desktop','xr']:
 e=read(f'engine-{mode}.json');assert e['engine_exit']==0 and not e['errors']
assert receipts['editor']['parsedGLBs']==6
sources=['commons/artifacts/lattice_gas_pump/wind_tunnel_study.gd','commons/artifacts/lattice_gas_pump/lattice_gas_pump.gd','commons/void/floor_content.gd','commons/void/rooms.json','tools/probes/wind_tunnel_108.gd']
report={'passed':True,'scope':'The existing wind-tunnel occurrence on main floor108 only.',
 'evidence':receipts,'source_sha256':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}}
(OUT/'review.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
DOC.mkdir(parents=True,exist_ok=True)
for name in ['01-parallel-flow','02-turned-flow','03-pink-wheel-and-boundary','04-tunnel-on-floor108']:
 shutil.copy2(OUT/(name+'.png'),DOC/(name+'.png'))
d=len(receipts['desktop']['checks']);x=len(receipts['synthetic_xr']['checks'])
review=f'''# Floor108 / turn a boundary

The existing lattice-gas occurrence now has a roughly seven-metre visible field
(44×22 cells at 0.16 m) and a reachable handwheel. The ivory plate, witness pulleys
and actual capsule-shaped solid-cell boundary read the same wheel angle, limited
to ±80°. The connecting belt is an ideal 1:1 linkage; torque and belt slip are not
simulated. The obstacle mask is discretized on the original lattice.

The original four-direction injection, opposing-pair collision and bounce/stream
methods are inherited unchanged. A separate unmodified source object reproduces
the adapter's state exactly at an equal update budget. The field colours show
density and reverse occupancy; four direction marks read actual state bits.
RUN, STEP and RESET use native input. STEP advances two original updates. RESET
repeats seed24108 with 50 settling updates, retaining the chosen obstacle angle.
The rightward-bounce count is a discrete proxy, not calibrated aerodynamic drag.
The source's horizontal wrapping is retained. This is not a continuum CFD model.

Native evidence inspected: {d} desktop and {x} synthetic-XR assertions, including
actual held mouse dragging, native grip pickup/tracked movement/release, real
mask changes, plate-angle equality, all3872 occupancy-mark slots, empty solid
cells, equal-budget angle comparisons, negative-floor moved/rotated placement,
glass collision, complete geometry bounds and open shaft centres. The actual
desktop player walks the front, both ends and rear bypass. No engine errors in
the final runs. Existing Jolt solver-bias and an unrelated Rule30 scene UID
fallback warning remain. Synthetic VR is not physical-headset acceptance;
headset comfort and performance remain untested.

The first synthetic-XR attempt is archived under attempt01-xr: the probe assumed
a fixed name for a dynamically created collision shape. That test path was
corrected; no grip implementation change was needed. An explicit vertex colour,
two-sided arrow material and thin state tiles were added for visual legibility;
final desktop screenshots and receipts are from the updated renderer.

Main108 retains all six original occurrences; only the wind-tunnel occurrence's
pose, source-backed adapter config and presentation change. The other five,
construction and other main floors are preserved by a fresh revision-checked API
merge. The machine stands in the east bay, facing west, clear of both shafts.
Its complete bounds fit the standard42×18 floor and six-metre storey. It has
concrete feet, a cabinet/glass collision and a supported low control wheel.

All six source-backed objects have actual parsed GLBs. Production editor
copy/move/rotate functions and the save validator are checked using disposable
copies; the test does not overwrite the visitor arrangement. The tunnel is a
whole coupled object in the editor; generated gas cells are not individual
parts. Copies retain the live-study config and starting angle. The editor shows
actual static snapshot geometry; Godot desktop and VR run the same rooms.json
with live behaviour. No other sequence or physical-headset acceptance is claimed.

Evidence: ada_run/wind-tunnel-108/review.json and referenced native, engine,
export, publish and editor receipts. Original source digest is unchanged.
'''
(DOC/'REVIEW.md').write_text(review,encoding='utf8')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Floor108 / turn a boundary</title><style>body{margin:0;background:#14171e;color:#f1eee5;font:17px/1.55 system-ui}main{max-width:1400px;margin:auto;padding:36px 28px}a{color:#ff94c8}header{max-width:1000px;margin:30px 0 44px}h1{font-size:clamp(36px,6vw,76px);font-weight:550;line-height:1.05}h2{font-size:26px}p,figcaption{max-width:1000px;color:#c9c8cc}img{width:100%;display:block}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:24px 0}figcaption{padding:12px 0}.eyebrow{color:#ff94c8;font:13px monospace}footer{border-top:1px solid #4d5057;margin-top:44px;padding-top:22px}@media(max-width:800px){.pair{grid-template-columns:1fr}}</style><main><header><div class="eyebrow">ADA / VOID / 108 / 24 OCTOBER 2026</div><h1>Turn a boundary.<br>Change the flow.</h1><p>A seven-metre lattice-gas field, a black steel wheel and an ivory obstacle. The pink grip turns both the visible plate and the cells that block the gas.</p><p><a href="/lab-editor?mode=void&amp;floor=108">Open floor108 in the lab editor →</a></p></header><figure><img src="03-pink-wheel-and-boundary.png" alt="Pink grip and handwheel driving an angled ivory obstacle inside a large wind tunnel"><figcaption>The low wheel relays its angle to the plate through a visible 1:1 belt. The gas uses the original four-direction collision and streaming rule.</figcaption></figure><h2>Same start. Same update budget. Different boundary.</h2><div class="pair"><figure><img src="01-parallel-flow.png" alt="Live wind-tunnel state with a horizontal obstacle"><figcaption>0° / plate aligned with the injected flow.</figcaption></figure><figure><img src="02-turned-flow.png" alt="Live wind-tunnel state with the obstacle turned seventy degrees"><figcaption>70° / a different blocking mask changes the resulting state.</figcaption></figure></div><figure><img src="04-tunnel-on-floor108.png" alt="Wind tunnel staged in the east bay on the standard skyscraper floor"><figcaption>Concrete feet and a supported wheel; room to approach, pass both ends and walk behind the cabinet. Both shafts stay open.</figcaption></figure><footer><p>Actual desktop mouse input and synthetic VR grip tests passed. Physical-headset comfort/performance remain untested. All six original floor objects remain editable. Editor geometry is a static snapshot; Godot runs the live field. The bounce count is a discrete measure, not calibrated aerodynamic drag.</p><p><a href="REVIEW.md">Evidence and limitations →</a> · <a href="../2026-10-23-ca-spatial-receivers/index.html">Previous CA rooms →</a></p></footer></main></html>'''
html=html.replace('<footer>','<h2>The same machine, editable.</h2><figure><img src="05-editor.jpg" alt="Floor108 wind tunnel selected in the live lab editor, with position and rotation controls"><figcaption>Whole work area selected in the lab editor. Move, rotate or duplicate the coupled machine; desktop and VR share the saved arrangement.</figcaption></figure><footer>')
(DOC/'index.html').write_text(html,encoding='utf8')
print('Packaged inspected wind-tunnel evidence:',DOC)
