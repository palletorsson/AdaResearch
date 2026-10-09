from pathlib import Path
import difflib, json, shutil

out = Path(__file__).resolve().parent
root = out.parents[3]
run = root/'ada_run/encounter_pilot/Point_Trace'
report = json.loads((run/'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and report['observations']['capture_complete']
panels = report['observations']['readouts']
assert len(panels) == 5
assert all(abs(p['scale'][0]-.7)<.001 and p['front'][2]<-.8 for p in panels)
before = json.loads((out/'map-before.json').read_text(encoding='utf-8-sig'))
after = json.loads((root/'commons/maps/Point_Trace/map_data.json').read_text(encoding='utf-8-sig'))
assert before['layers']['structure'] == after['layers']['structure']
assert before['layers']['utilities'] == after['layers']['utilities']
for a,b in zip(before['layers']['interactables'],after['layers']['interactables']):
    assert all(y.split('#data_table_scale:')[0]==x for x,y in zip(a,b))
for name in ['report.json','source_manifest.json','before-from-entry.png','after-from-entry.png','readout-close.png']:
    shutil.copy2(run/name,out/name)
for old,new,rel in [('draw_dot-before.gd','draw_dot-after.gd','commons/primitives/point/draw_dot.gd'),('map-before.json','map-after.json','commons/maps/Point_Trace/map_data.json')]:
    shutil.copy2(root/rel,out/new)
    diff=''.join(difflib.unified_diff((out/old).read_text(encoding='utf-8-sig').splitlines(True),(out/new).read_text(encoding='utf-8-sig').splitlines(True),fromfile=old,tofile=new))
    (out/(new+'.diff')).write_text(diff,encoding='utf-8')
(out/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Trace · read from the entrance</title><style>body{margin:0;background:#f3eee8;color:#29232c;font:20px/1.65 Georgia,serif}main{max-width:1200px;margin:auto;padding:45px 24px}h1{font-size:52px;line-height:1.1;font-weight:400}img{width:100%;display:block}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}figure{margin:25px 0}figcaption,footer{font:14px/1.6 system-ui,sans-serif;color:#635864}a{color:#774765}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style><main><p>ADA · POINT TRACE</p><h1>Read from the entrance.</h1><p>The four drawing dots and the drawing stick now have smaller readouts, turned 180° towards the arriving visitor. Each screen is 70% of its earlier size, about 64 × 50 cm, and keeps its upward tilt.</p><div class="pair"><figure><a href="before-from-entry.png"><img src="before-from-entry.png" alt="Earlier larger readouts facing away from the entrance."></a><figcaption>Previous size and heading, shown on the same instruments.</figcaption></figure><figure><a href="after-from-entry.png"><img src="after-from-entry.png" alt="Five smaller readouts facing the entrance."></a><figcaption>Now: the reading faces turn towards the approach, with space between them.</figcaption></figure></div><figure><img src="readout-close.png" alt="The smaller red drawing readout showing its point count and world positions."><figcaption>A closer view of the red dot's complete count and coordinate table.</figcaption></figure><footer><p>Actual Godot museum captures with supplied short drawing gestures to expose the panels. Five live readouts verified at 0.7 scale, facing entranceward. No headset legibility trial. Only this collection opts into the new size and heading; drawing coordinates and map layout are unchanged.</p><p><a href="report.json">Capture observations</a> · <a href="draw_dot-after.gd.diff">Display change</a> · <a href="map-after.json.diff">Placement settings</a></p></footer></main></html>''',encoding='utf-8')
print('Published five smaller entrance-facing readouts; layout preserved.')
