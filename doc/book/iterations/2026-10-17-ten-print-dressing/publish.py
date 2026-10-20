"""Publish this encounter's native captures and receipts after the checks pass."""
from pathlib import Path
import difflib
import hashlib
import json
import shutil

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
RUN = ROOT / 'ada_run/encounter_pilot/Randomness_10_PRINT_Algorithm/textile-dressing'
unit = json.loads((OUT/'tests.json').read_text())
native = json.loads((RUN/'report.json').read_text())
assert unit['passed'] and native['passed']
assert 'SCRIPT ERROR' not in (RUN/'stdout.log').read_text(encoding='utf-8')
(OUT/'images').mkdir(exist_ok=True)
for path in RUN.glob('*.png'):
    shutil.copy2(path,OUT/'images'/path.name)
for name in ['report.json','source_manifest.json','engine.log']:
    shutil.copy2(RUN/name,OUT/name)
files = [
    'commons/artifacts/ten_print_textile/print_record.gd',
    'commons/artifacts/ten_print_textile/textile_studio.gd',
    'commons/artifacts/ten_print_textile/STUDIO.md',
    'commons/artifacts/randomness_space/textile_comparison.tscn',
    'commons/artifacts/garment_cutting_table/cloth_record.gd',
    'commons/artifacts/garment_cutting_table/garment_cutting_table.gd',
    'commons/artifacts/super_drag_mirror/super_drag_mirror.gd',
    'commons/artifacts/ten_print_structure/ten_print_structure.gd',
    'algorithms/randomness/generative/tenprintantmaze/ten_print_maze.gd',
    'commons/artifacts/registry/randomness.json',
    'commons/artifacts/registry/ten_print_structure.json',
    'commons/maps/Randomness_10_PRINT_Algorithm/map_data.json',
    'commons/maps/Randomness_10_PRINT_Algorithm/tutorial.md',
    'commons/maps/Randomness_10_PRINT_Algorithm/final.md',
]
hashes={}
patch=[]
for name in files:
    target=OUT/'after'/name
    target.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(ROOT/name,target)
    hashes[name]=hashlib.sha256(target.read_bytes()).hexdigest()
    before=OUT/'before'/name
    patch.extend(difflib.unified_diff(before.read_text(encoding='utf-8-sig').splitlines(True) if before.exists() else [],target.read_text(encoding='utf-8-sig').splitlines(True),fromfile='before/'+name,tofile='after/'+name))
(OUT/'after'/'.gdignore').write_text('')
(OUT/'changes.diff').write_text(''.join(patch),encoding='utf-8')
count=len(unit['checks'])+len(native['checks'])
verification={'passed':True,'checks':count,'unit_checks':len(unit['checks']),'native_hall_checks':len(native['checks']),
              'headset_tested':False,'sources':hashes,
              'limits':['Head-centred rather than per-eye mirror in XR','Fixed draped meshes and geometric garment panels, not cloth physics','Native probe reports cleanup-time ObjectDB/resource warnings; no script errors']}
(OUT/'verification.json').write_text(json.dumps(verification,indent=2),encoding='utf-8')
html='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>10 PRINT — The pattern leaves its frame</title><style>
*{box-sizing:border-box}body{margin:0;background:#f0ede6;color:#25213b;font:18px/1.55 system-ui,sans-serif}main{max-width:1320px;margin:auto;padding:50px 32px}a{color:#70365a}header{max-width:900px;margin-bottom:38px}.eyebrow{font:12px/1.5 system-ui;letter-spacing:.17em;text-transform:uppercase;color:#735c6b}h1{font:clamp(40px,5.8vw,76px)/1.04 Georgia,serif;font-weight:normal;letter-spacing:-.035em;margin:18px 0 24px}h2{font:34px/1.13 Georgia,serif;font-weight:normal;margin:0 0 18px}p{max-width:76ch}figure{margin:0}img{width:100%;display:block;background:#25213b}figcaption{font-size:14px;color:#5a535b;padding:12px 0 20px}.hero{margin-bottom:44px}.split{display:grid;grid-template-columns:1fr 1fr;gap:32px;align-items:start;margin:38px 0 48px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:24px}.instructions{background:#e3d6de;border-left:4px solid #894765;padding:24px 28px;margin:24px 0}li{margin:12px 0}small{font-size:14px}footer{margin-top:52px;border-top:1px solid #cbbfc6;padding-top:25px;font-size:14px}.tag{display:inline-block;border:1px solid #aaa1a4;padding:5px 10px;margin:4px 4px 4px 0;font-size:13px}code{font-size:.9em} @media(max-width:760px){main{padding:28px 18px}.split,.pair{grid-template-columns:1fr}h2{font-size:29px}}
</style><main><header><div class="eyebrow">Ada Research · Randomness · 17 October 2026</div><h1>The pattern<br>leaves its frame.</h1><p>The same random choices become three printed fabrics. A fabric becomes a dress. A mirror lets the moving body enter the comparison.</p><span class="tag">10 PRINT hall</span><span class="tag">252 retained draws</span><span class="tag">Three fabrics · three dress shapes</span></header>
<figure class="hero"><img src="images/three-fabrics.png" alt="Three full-height printed cloth swatches with a matching dress fitting"><figcaption>Native Godot capture. RIBBON, STITCH and PIXEL give the same 14 × 18 stored choices three different visible consequences. Pink, pale green and a dark ground form the first palette.</figcaption></figure>
<section class="split"><div><h2>From comparison<br>to dressing.</h2><p>Choose the marks, then change the palette or repeat count while keeping the draws. The fitting previews A-LINE, GOWN and PLEATED shapes.</p><p>The open changing alcove has controls on its right side and a full-length mirror. It stands on the hall floor, with space to walk in and out. The mirror sees the actual worn garment, not the fitting figure.</p><div class="instructions"><ol><li><b>RIBBON / STITCH / PIXEL</b> selects the print.</li><li><b>PALETTE / REPEAT</b> changes its reading. <b>SEED +</b> supplies different draws.</li><li><b>KEEP / REPLAY</b> saves and restores the complete fabric.</li><li><b>SHAPE / WEAR</b> selects a dress and puts it on the active visitor. Look down or in the mirror.</li><li><b>TAKE OFF</b> restores the previous outfit.</li></ol></div><p><small>Reload the <b>Randomness → 10 PRINT</b> hall to see the update. The existing <code>textile_comparison</code> placement now loads this studio.</small></p></div><figure><img src="images/worn-in-mirror.png" alt="The active visitor's patterned dress reflected in the dressing-room mirror"><figcaption>A native view through the active visitor's camera. The worn cloth is a snapshot: experimenting at the studio afterwards does not repaint it.</figcaption></figure></section>
<section><h2>A mark needs enough body to be seen.</h2><p>The three tall fields now use mesh diagonals and visible cell frames. Their frames share one draw batch per field. The floor print has low, broad strokes on separate dark cell beds, so later rows remain visible from standing height. Its choices still follow the linked screen.</p><div class="pair"><figure><img src="images/tall-mesh-characters.png" alt="A towering ten-print field with thick mesh diagonals and individual cell frames"><figcaption>The existing character form replaces hairline strokes in all three tall fields. Diagonals still change one cell at a time, and the ant's navigation still updates.</figcaption></figure><figure><img src="images/large-print-standing.png" alt="The linked ten-print floor with individually visible dark cells and coloured low strokes"><figcaption>Floor strokes are at most 4.5 cm high. A bright tile still marks the screen's next address.</figcaption></figure></div></section>
<section class="split"><div><h2>Keep the experiment small.</h2><p>Keep a seed and its samples. Change only the pair of marks. Then keep the image and change its receiving surface. Where does the same contour stretch, meet a seam, or become harder to follow?</p><p>The tutorial now connects that small reconstruction to the installed studio. The final text follows the fabric from its hanging frame to the fitting and the worn body.</p><p><a href="/book-review/commons/maps/Randomness_10_PRINT_Algorithm/tutorial.md">Tutorial</a> · <a href="/book-review/commons/maps/Randomness_10_PRINT_Algorithm/final.md">Final text</a></p></div><div><h2>What has been checked.</h2><p><b>CHECK_COUNT native checks passed.</b> They cover exact save/replay, a fresh wardrobe restoring the print, active VR wearer selection, tracked sleeve poses, mirror world/camera binding, real button contact and pointer events, walking into and out of the alcove, and the screen/floor correspondence.</p><p><small>These are supplied poses and native runtime checks, not a physical-headset acceptance test. The mirror is head-centred in VR. Fabric folds and dress panels are geometric surfaces, not a cloth or weaving simulation. The existing native harness reports cleanup-time resource warnings.</small></p><p><a href="verification.json">Verification</a> · <a href="report.json">Hall checks</a> · <a href="tests.json">Record and wardrobe checks</a> · <a href="changes.diff">Changes from this session</a></p></div></section>
<footer>Research question: when a retained pattern becomes something worn, which differences belong to the random choices, and which belong to the cut, repeat and moving body?</footer></main></html>'''.replace('CHECK_COUNT',str(count))
(OUT/'index.html').write_text(html,encoding='utf-8')
print(f'Published {count} checks and {len(list((OUT/"images").glob("*.png")))} native images: {OUT/"index.html"}')
