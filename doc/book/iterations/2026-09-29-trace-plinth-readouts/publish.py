from pathlib import Path
import difflib, json, shutil

out=Path(__file__).resolve().parent
root=out.parents[3]
run=root/'ada_run/encounter_pilot/Point_Trace'
report=json.loads((run/'report.json').read_text(encoding='utf-8-sig'))
assert report['passed'] and report['observations']['capture_complete'] and report['observations']['clear_keeps_mount']
assert len(report['observations']['readouts'])==5
for panel in report['observations']['readouts']:
    assert panel['mounted'] and panel['visible'] and panel['empty_count']=='0 POINTS'
    assert abs(panel['bounds_min'][1]-panel['support'][1])<.005
for name in ['report.json','source_manifest.json','on-the-plinths.png','empty-and-on.png','drawing-and-reading.png','readout-close.png']:
    shutil.copy2(run/name,out/name)
shutil.copy2(out.parent/'2026-09-29-trace-entry-readouts/after-from-entry.png',out/'previous.png')
for old,new,rel in [('draw_dot-before.gd','draw_dot-after.gd','commons/primitives/point/draw_dot.gd'),('map-before.json','map-after.json','commons/maps/Point_Trace/map_data.json')]:
    shutil.copy2(root/rel,out/new)
    diff=''.join(difflib.unified_diff((out/old).read_text(encoding='utf-8-sig').splitlines(True),(out/new).read_text(encoding='utf-8-sig').splitlines(True),fromfile=old,tofile=new))
    (out/(new+'.diff')).write_text(diff,encoding='utf-8')
before=json.loads((out/'map-before.json').read_text(encoding='utf-8-sig'))
after=json.loads((out/'map-after.json').read_text(encoding='utf-8-sig'))
assert before['layers']['structure']==after['layers']['structure'] and before['layers']['utilities']==after['layers']['utilities']
(out/'index.html').write_text('''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Trace · on the plinth</title><style>body{margin:0;background:#f3eee8;color:#29232c;font:20px/1.65 Georgia,serif}main{max-width:1200px;margin:auto;padding:45px 24px}h1{font-size:54px;line-height:1.1;font-weight:400}img{display:block;width:100%}figure{margin:30px 0}figcaption,footer{font:14px/1.6 system-ui,sans-serif;color:#635864}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}a{color:#774765}@media(max-width:700px){.pair{grid-template-columns:1fr}}</style><main><p>ADA · POINT TRACE</p><h1>On the plinth.</h1><p>Smaller again, tilted back and centred on each support. The readout is already on when you arrive: zero points, ready for the hand.</p><figure><img src="on-the-plinths.png" alt="Five smaller readouts seated on the drawing collection's white plinths, facing the entrance."><figcaption>Actual museum view before drawing. Every casing rests at the 90 cm plinth top.</figcaption></figure><div class="pair"><figure><img src="previous.png" alt="Previous readouts, offset beside the plinths."><figcaption>Earlier: the first drawn point determined where the display floated.</figcaption></figure><figure><img src="drawing-and-reading.png" alt="Mounted readouts stay on their plinths while drawn loops appear above them."><figcaption>Now: each display stays on its own plinth while the drawing grows.</figcaption></figure></div><figure><img src="readout-close.png" alt="The red recorder's small, tilted screen with a complete coordinate table and its lower edge resting on the plinth."><figcaption>Screen face approximately 51 × 40 cm, with a 56 cm-wide casing. Tilted back 50° from vertical, still facing the entrance.</figcaption></figure><footer><p>Five native support contacts inspected; all displays begin visibly at “0 POINTS.” Clearing a trace keeps the screen on and in place. Supplied drawing gestures for the filled views; no headset legibility trial.</p><p><a href="report.json">Mount observations</a> · <a href="draw_dot-after.gd.diff">Display change</a> · <a href="map-after.json.diff">Hall settings</a></p></footer></main></html>''',encoding='utf-8')
print('Published five seated, always-on readouts. Structure and utilities preserved.')
