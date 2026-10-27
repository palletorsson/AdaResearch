"""Package explicitly inspected native/editor evidence for the two CA additions."""
import hashlib,json,shutil
from pathlib import Path
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-spatial-02';DOC=ROOT/'doc/book/iterations/2026-10-23-ca-spatial-receivers'
def read(p):return json.loads(p.read_text(encoding='utf8'))
receipts={key:read(OUT/name) for key,name in [('desktop','native-desktop.json'),('synthetic_xr','native-xr.json'),('editor','editor-checks.json'),('publish','publish.json'),('export','export.json')]}
assert all(r['passed'] for r in receipts.values())
for mode in ['desktop','xr']:
 engine=read(OUT/f'engine-{mode}.json');assert engine['engine_exit']==0 and not engine['errors']
DOC.mkdir(exist_ok=True,parents=True)
photos=['ca-104-three-slices','ca-104-witness','ca-107-closed','ca-107-open']
for name in photos:shutil.copy2(OUT/(name+'.png'),DOC/(name+'.png'))
sources=['commons/void/ca_neighbour_slice.gd','commons/void/ca_health_canopy.gd','commons/void/ca_receiver_source.gd','commons/void/ca_state_controls.gd','commons/void/floor_content.gd','commons/void/rooms.json','commons/void/catalog.json','tools/probes/ca_spatial_02.gd']
report={'passed':True,'scope':'104 and107 only; continuation of the43-original CA curation.','evidence':receipts,'source_sha256':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources}}
(OUT/'review.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf8')
desktop=len(receipts['desktop']['checks']);xr=len(receipts['synthetic_xr']['checks'])
review=f'''# CA / the same state changes the room

Main floors 104 and 107, continuation of the prior eight-floor CA pass. Nine
existing occurrences on these two floors are retained with their source scenes,
algorithm configurations, scale and placement. Four source-linked objects added:
three neighbourhood slices and one suspended canopy. All other main floors,
including floor109's earlier history wall, preserved through a fresh API merge.

- 104: three physical steel frames expose the real 27-address neighbourhood as
 three 3×3 depth slices. Empty addresses keep their outlines; the central witness
 keeps its gold frame. Same original 50³ solver, STEP, VIEW, REPLAY and carried
 point. Those existing controls face the source and enlarged outputs from the
 south operating position. No independent state or animation.
- 107: 80 overhead louvers read the existing 16×5 proximity bridge. Aperture is
 `80*(1-health)` degrees; white closes, pink opens. The source alone samples
 proximity, calculates recovery and changes support. A depleted interior does
 not immediately heal when the probe withdraws: neighbour recovery starts at
 its surviving edges. The receiver preserves that behaviour. Its swept panels
 stay above 4.3 m. Moving leaves/rims/axles use three MultiMesh batches rather than
 320 separate moving mesh draws. No physical-headset performance claim.

Validation inspected: {desktop} desktop and {xr} synthetic-XR assertions, real
STEP/VIEW/REPLAY or RESTORE input, actual point grab/trigger after remounting,
exact 27-address and 80-health equality, original support loss and basin landing,
negative-floor bounds, open shaft centres, moved/rotated source association and
solid frame, and actual desktop walking around the centre frame. No engine
errors in the final runs. Original 9 occurrences plus 4 receivers have 13 actual
GLBs. All 13 move/rotate/copy through production editor functions and validate
without changing the saved user layout.

Earlier failed runs are archived: attempt01 omitted the required station field;
attempt02 assumed immediate recovery of the depleted witness. The latter was a
test expectation error, not permission to change the original algorithm. Final
receipts do not claim either failed run passed.

Production validation is valid, with broad 2D footprint warnings: floor 104's
existing work light intersects a checkpoint access footprint, while floor 107's
new overhead receiver shares the bridge's footprint intentionally. Actual arrival,
shaft and circulation checks are recorded separately. Original basins remain
below slab level. Generated cells/louvers are editable as whole source-backed
objects; they are not separate editor parts. A receiver requires its configured
source on the same floor; copying it alone to another floor does not copy the
solver or reassign its source. The live editor shows actual static
geometry snapshots; Godot runs the algorithms. Physical headset comfort and
performance remain untested. No chapter/final.md changes or other sequence claims.

Evidence: ada_run/ca-spatial-02/review.json and its referenced native, engine,
export, publish and editor receipts. Source fingerprints are recorded there.
'''
(DOC/'REVIEW.md').write_text(review,encoding='utf8')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>CA / the same state changes the room</title><style>body{margin:0;background:#15191e;color:#efeae5;font:17px/1.5 system-ui}main{max-width:1400px;margin:auto;padding:36px 28px}a{color:#ff95c8}header{max-width:980px;margin:30px 0 48px}h1{font-size:clamp(34px,5vw,68px);line-height:1.05;font-weight:550;margin:12px 0 28px}h2{font-size:26px}p{max-width:950px;color:#c7c3c4}.eyebrow{color:#f18dbb;font:13px monospace}img{width:100%;display:block}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:30px 0}figcaption{padding:12px 0;color:#c7c3c4}footer{border-top:1px solid #4a4e54;margin-top:48px;padding-top:20px}@media(max-width:800px){.pair{grid-template-columns:1fr}}</style><main><header><div class="eyebrow">ADA / VOID / CELLULAR AUTOMATA / 23 OCTOBER 2026</div><h1>The same state<br>changes the room.</h1><p>Two more CA rooms strengthened with architectural outputs. The original algorithms drive every change: no second solver or decorative animation.</p><p><a href="/lab-editor?mode=void&amp;floor=104">104 / unfold the neighbourhood →</a> · <a href="/lab-editor?mode=void&amp;floor=107">107 / health opens the ceiling →</a></p></header><h2>104 / twenty-seven addresses, three depth slices</h2><figure><img src="ca-104-three-slices.png" alt="The original three-state sculpture and its three enlarged neighbourhood slices"><figcaption>The original controls and handheld point face the shared outputs. Pink is active, green is fading; outlined addresses persist after a cell becomes empty.</figcaption></figure><figure><img src="ca-104-witness.png" alt="Gold outline locates the witness among nine neighbourhood addresses"><figcaption>The gold centre is the same witness in the original sculpture and the middle slice. Its neighbours can now be counted without occlusion.</figcaption></figure><h2>107 / health beneath the body, aperture above it</h2><div class="pair"><figure><img src="ca-107-closed.png" alt="Healthy bridge and closed white canopy louvers"><figcaption>Full health: white leaves close above the original bridge.</figcaption></figure><figure><img src="ca-107-open.png" alt="Pink louvers open over depleted bridge cells"><figcaption>Depleted health: the same addresses open overhead and withdraw support below. Recovery still depends on the original healthy neighbours.</figcaption></figure></div><footer><p>Four separately editable source-linked objects added; all originals and other floors retained. Native desktop input, synthetic tracked VR, actual geometry, circulation and editor save validation checked. Physical-headset comfort/performance remain untested. Editor models are static snapshots; Godot runs the live behaviour.</p><p><a href="../2026-10-23-ca-curation/index.html">Previous CA pass →</a> · <a href="REVIEW.md">Review and limitations →</a></p></footer></main></html>'''
(DOC/'index.html').write_text(html,encoding='utf8');print('Packaged inspected CA continuation:',DOC)
