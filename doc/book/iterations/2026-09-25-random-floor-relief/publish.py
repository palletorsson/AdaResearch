from pathlib import Path
import json,hashlib,shutil,difflib,html,urllib.request
r=Path.cwd();o=Path(__file__).parent;H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
a=json.loads((o/'before-native/report.json').read_text());b=json.loads((o/'after-native/report.json').read_text())
assert a['passed'] and b['passed']
ga=a['observations']['ground'];gb=b['observations']['ground']
assert ga['local_mesh_sha256']==gb['local_mesh_sha256']
assert abs(gb['position'][1]-ga['position'][1]-.2)<.000001
assert gb['color']=='6b427d' and gb['lowest']>0 and gb['highest']<.38
assert H(r/'commons/context/walkgrids/random_space.tscn')==H(o/'before/commons/context/walkgrids/random_space.tscn')
for sub in ['before-native','after-native']:
 assert json.loads((o/sub/'process.json').read_text())['exit_code']==0
 assert 'SCRIPT ERROR' not in (o/sub/'stdout.log').read_text(errors='replace')
image_rel='doc/book/figures/randomness/cellular-field-violet-ground.png';src=o/'after-native/cellular-field.png';shutil.copy2(src,r/image_rel)
f={'source':src.relative_to(r).as_posix(),'canonical':image_rel,'sha256':H(src),'capture':'Original Godot museum PNG; controlled eye-height desktop camera. No image editing.'}
(o/'figure-provenance.json').write_text(json.dumps(f,indent=2)+'\n')
p=r/'commons/maps/Random_Space/final.md';assert p.read_bytes()==(o/'before/commons/maps/Random_Space/final.md').read_bytes();s=p.read_text(encoding='utf-8')
old='Look down: the pale patches breaking through the grey floor are the tops of a random surface you walk across, built another way.'
new='Look down: a violet surface rises a little above the grey floor. You can follow its unevenness across the room.'
assert s.count(old)==1;s=s.replace(old,new)
old="Where the surface rises above the floor it shows pale; where it dips below, the floor shows through, so the jagged outline of a patch is where chance heights cross the floor's level, not the edge of a feature."
new='The colour separates this ground from its surroundings; it does not explain why one corner is high and the next is low.'
assert s.count(old)==1;s=s.replace(old,new)
s=s.replace('A blue cellular field on its low stand, clear of the pale random ground around it.','A blue cellular field on its low stand above the violet random ground.').replace('doc/book/figures/randomness/cellular-field-uncovered.png',image_rel)
p.write_text(s,encoding='utf-8')
base=json.loads((o/'baseline.json').read_text())
for rel in ['commons/maps/Random_Space/blurb.md','commons/maps/Random_Space/technical.md']:
 p=r/rel;q=o/'before'/rel;q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q);base[rel]=H(p)
(o/'baseline.json').write_text(json.dumps(base,indent=2)+'\n')
p=r/'commons/maps/Random_Space/blurb.md';s=p.read_text(encoding='utf-8-sig');needle='breaking through the floor in jagged pale patches';assert s.count(needle)==1;p.write_text(s.replace(needle,'lifted clear of the floor as a violet field of small triangles'),encoding='utf-8')
p=r/'commons/maps/Random_Space/technical.md';s=p.read_text(encoding='utf-8-sig');needle='- Positioned at (6,6) height -0.3m—slightly below floor, filling upward';assert s.count(needle)==1
p.write_text(s.replace(needle,'- Map cell (6,6) retains its legacy grid height of -0.3 m. In the museum, the placement adds a 0.20 m upward offset at 1.4× scale; the actual surface lies about 0.033–0.368 m above the hall floor. This hall uses violet `surface_color:6b427d` and low `emission_strength:0.02`; its seeded vertex heights are unchanged.'),encoding='utf-8')
p=r/'commons/maps/Random_Space/intent.md';assert p.read_bytes()==(o/'before/commons/maps/Random_Space/intent.md').read_bytes();s=p.read_text(encoding='utf-8-sig');needle='independent uniform heights about +/-0.12 m, no animation;';assert s.count(needle)==1
p.write_text(s.replace(needle,'independent uniform heights about +/-0.12 m locally, no animation. The museum retains 1.4x scale and lifts the floor 0.20 m; violet colour with low emission exposes the whole existing surface. The cellular display stands on a 0.40 m support;'),encoding='utf-8')
p=r/'commons/data/museum_core_encounters.json';s=p.read_text(encoding='utf-8-sig');(o/'core-before-update.json').write_text(s,encoding='utf-8');d=json.loads(s);room=d['rooms']['Random_Space'];room['text_sha256']=H(r/'commons/maps/Random_Space/final.md');room['map_sha256']=H(r/'commons/maps/Random_Space/map_data.json');room['local_review']=o.relative_to(r).as_posix()+'/DECISIONS.md';p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');(o/'figures-before-update.md').write_text(s,encoding='utf-8');s+='\n\n## Random Space: raised violet floor — 25 September 2026\n\nThe author requested a higher, differently coloured floor. The current chapter now uses an original museum photograph with the whole random ground exposed in violet. [Same-camera comparison](../iterations/2026-09-25-random-floor-relief/index.html). Earlier figures remain in their dated reviews.\n';p.write_text(s,encoding='utf-8')
note='''# Random Space: raised violet floor

The author requested a higher noise floor and another colour. This applies to the existing `random_space` ground in Random_Space.

- Raised only this museum placement by 0.20 m using the existing per-instance offset. Its 1.4× scale, random seed, local mesh and distribution remain identical. Measured world height now ranges from 0.0326 m to 0.3678 m above the hall floor.
- The placement chooses violet `6b427d` and reduces emission from 0.42 to 0.02. The shared script now accepts its existing material exports through map config; a material-only change does not regenerate mesh or collision. Other placements retain the original defaults.
- Raised the small cellular display's support from 0.35 m to 0.40 m, keeping it above the highest part of the ground. The entropy gauge and noise mixer remain in place.
- Revised only the obsolete pale-patches description and current companion staging notes. Replaced the chapter photograph with a new native PNG; previous review evidence is retained.

Native final run: 8 checks pass, exit 0, no GDScript errors. Visible and collision triangles match. The complete local vertex hash matches the before run. Both photographs use the same eye-height camera positions. Original scene resource unchanged. Existing engine warnings remain in the logs. This does not close the separate navigation-planner or headset-route tasks.
'''
(o/'DECISIONS.md').write_text(note,encoding='utf-8')
css='body{background:#f4efe8;color:#302736;font:18px/1.6 Georgia,serif;margin:0}main{max-width:1180px;margin:auto;padding:40px 25px}h1{font-size:44px;line-height:1.15}a{color:#674277}p{max-width:76ch}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}figure{margin:20px 0}img{width:100%;height:auto}figcaption{font-size:15px}pre{overflow:auto;font:13px/1.5 monospace;background:#e7dfe9;padding:18px}details{margin:25px 0}summary{cursor:pointer}@media(max-width:750px){.pair{grid-template-columns:1fr}}'
page='<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width, initial-scale=1"><title>Random Space — a raised violet floor</title><style>'+css+'</style><main><p>Ada Research · 25 September 2026</p><h1>A raised violet floor</h1><p>The whole uneven surface is now visible. Raising it 20 cm brings its valleys above the grey floor; violet separates it from the walls and the blue cellular display. The random shape stays the same.</p><div class="pair">'
for sub,caption in [('before-native','Before: only pale peaks break through the floor.'),('after-native','Now: the same surface, raised 20 cm and coloured violet.')]:
 page+=f'<figure><a href="{sub}/floor-overview.png"><img src="{sub}/floor-overview.png" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>'
page+='</div><figure><a href="after-native/cellular-field.png"><img src="after-native/cellular-field.png" alt="Blue cellular display surrounded by the raised violet ground"></a><figcaption>The small blue display has also moved up 5 cm to stay clear.</figcaption></figure><p><a href="/compose/sources?map=Random_Space&amp;doc=final">Read the current chapter</a> · <a href="DECISIONS.md">Changes and checks</a> · <a href="after-native/report.json">Native report</a></p><details><summary>Exact chapter changes</summary><pre>'
before=(o/'before/commons/maps/Random_Space/final.md').read_text(encoding='utf-8-sig');after=(r/'commons/maps/Random_Space/final.md').read_text(encoding='utf-8')
page+=html.escape(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='Before',tofile='Current final.md')))+'</pre></details><p>The collision follows the raised surface. Eight native checks pass; the separate navigation and headset tasks remain open.</p></main></html>'
(o/'index.html').write_text(page,encoding='utf-8')
print('Published the raised floor and updated the chapter image and descriptions.')
