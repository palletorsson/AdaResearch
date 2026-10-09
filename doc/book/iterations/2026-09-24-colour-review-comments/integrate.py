from pathlib import Path
import json,shutil,hashlib
r=Path.cwd();o=r/'doc/book/iterations/2026-09-24-colour-review-comments';base=json.loads((o/'baseline.json').read_text(encoding='utf-8'));changed=json.loads((o/'changed-files.json').read_text(encoding='utf-8'))
def snap(rel):
 p=r/rel;q=o/'before'/rel
 if not q.exists():q.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,q);base[rel]=hashlib.sha256(p.read_bytes()).hexdigest()
def write(rel,text):
 snap(rel);(r/rel).write_text(text,encoding='utf-8')
 if rel not in changed:changed.append(rel)
for m,sub in [('Array','array-museum'),('Color_Context_Placed','columns'),('Color_Nails','nails')]:
 d=o/sub;d.mkdir(exist_ok=True)
 for f in ['report.json','source_manifest.json','stdout.log','spec.json']:shutil.copy2(r/'ada_run/encounter_pilot'/m/f,d/f)
 report=json.loads((d/'report.json').read_text(encoding='utf-8'));assert report['passed'] and not report['failures'];(d/'process.json').write_text(json.dumps({'exit_code':0,'passed_checks':len(report['checks'])},indent=2)+'\n',encoding='utf-8')
figs=[]
shots=[('Array','museum-approach','museum-approach'),('Array','the-written-floor','museum-floor-changed'),('Array','floor-restored','museum-floor-restored'),('Color_Context_Placed','colour-hall','colour-hall'),('Color_Context_Placed','among-the-columns','among-the-columns'),('Color_Context_Placed','rainbow-column','rainbow-column'),('Color_Nails','salon-red','salon-red'),('Color_Nails','salon-violet','salon-violet')]
for m,source,name in shots:
 p=r/'ada_run/encounter_pilot'/m/(source+'.png');q=o/(name+'.png');shutil.copy2(p,q)
 dst=r/'doc/book/figures'/m/(name+'.png');dst.parent.mkdir(parents=True,exist_ok=True);assert not dst.exists(),dst;shutil.copy2(p,dst)
 figs.append({'map':m,'source':q.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':hashlib.sha256(q.read_bytes()).hexdigest(),'scope':'Standing camera within the loaded production museum; original hall, geometry, materials and illumination retained. Scripted camera/controls, not a headset photograph.'})
rel='commons/maps/Color_Context_Placed/final.md';s=(r/rel).read_text(encoding='utf-8');anchor='You can go back to the first column.\n';assert s.count(anchor)==1;s=s.replace(anchor,anchor+'\n![The columns seen from the entrance aisle inside the museum.](/book-review/doc/book/figures/Color_Context_Placed/colour-hall.png)\n');write(rel,s)
rel='commons/maps/Color_Nails/final.md';s=(r/rel).read_text(encoding='utf-8');a='![The same selected nail and skin colours on the giant hand and the petite hand. The petite view is a close-up; labels give their different heights.](/book-review/doc/book/iterations/2026-09-23-nails-the-choosing-hand/same-choice-two-scales.png)';assert a in s;s=s.replace(a,'![The giant hand and the petite hand on the manicure table, seen from inside the museum salon.](/book-review/doc/book/figures/Color_Nails/salon-red.png)');write(rel,s)
rel='commons/maps/Array/final.md';snap(rel);s=(r/rel).read_text(encoding='utf-8');s=s.replace('/figures/Array/the-written-floor.png','/figures/Array/museum-floor-changed.png').replace('/figures/Array/floor-restored.png','/figures/Array/museum-floor-restored.png').replace('*The same part of the working museum before and after RESTORE FLOOR.','*The same part of the working museum, seen from standing height before and after RESTORE FLOOR.');write(rel,s)
rel='doc/book/iterations/2026-09-24-arrays-review-comments/index.html';s=(r/rel).read_text(encoding='utf-8');s=s.replace('src="the-written-floor.png"','src="/book-review/doc/book/figures/Array/museum-floor-changed.png"').replace('src="floor-restored.png"','src="/book-review/doc/book/figures/Array/museum-floor-restored.png"')
anchor='<h2>The same place, changed and restored</h2>';assert anchor in s;s=s.replace(anchor,'<h2>From inside the museum</h2><img src="/book-review/doc/book/figures/Array/museum-approach.png" alt="The approach to the Array room from the museum passage"><p>Array currently embeds an exposed wireframe room within the museum. These new entrance and standing views retain that architecture and its materials. The closer views below keep the surrounding exhibits in sight. <a href="../2026-09-24-colour-review-comments/array-museum/report.json">Current museum capture and 27 checks</a>; the original floor-test evidence remains below.</p>'+anchor);write(rel,s)
rel='commons/data/museum_core_encounters.json';d=json.loads((r/rel).read_text(encoding='utf-8-sig'));(o/'core-before-update.json').write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
maps=json.loads((r/'commons/maps/sequences/color.json').read_text(encoding='utf-8-sig'))['sequences']['color']['maps']
for m in maps+['Array']:
 room=d['rooms'][m];room['text_sha256']=hashlib.sha256((r/'commons/maps'/m/'final.md').read_bytes()).hexdigest();room['map_sha256']=hashlib.sha256((r/'commons/maps'/m/'map_data.json').read_bytes()).hexdigest()
 if m!='Array':room['local_review']='doc/book/iterations/2026-09-24-colour-review-comments/index.html'
write(rel,json.dumps(d,ensure_ascii=False,indent=2)+'\n')
rel='doc/book/figures/README.md';s=(r/rel).read_text(encoding='utf-8-sig');s+='''

## Museum interiors — Colour review, 24 September 2026

The author requested views from inside the museum. `Color_Context_Placed/colour-hall.png`, `among-the-columns.png` and `rainbow-column.png` retain the loaded hall around its stacks. `Color_Nails/salon-red.png` and `salon-violet.png` retain the same standing view of the salon furniture and both display hands. The nail colour alone changes between them; source-material receivers were checked using invisible production hand fixtures, not tracked hands in these photographs.

`Array/museum-approach.png`, `museum-floor-changed.png` and `museum-floor-restored.png` replace the tight book views with the entrance and standing viewpoints. The current museum itself embeds this wireframe Array room; no material or surrounding geometry was substituted for a photograph. Earlier images and tests remain unchanged. The floor pair uses supplied mutations held for comparison.

All eight images are unmodified native Godot viewport captures. Camera positions and controls were supplied by probes. Evidence and SHA256 provenance: `doc/book/iterations/2026-09-24-colour-review-comments/`. No headset or learner observation is claimed.
''';write(rel,s)
(o/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8');(o/'baseline.json').write_text(json.dumps(base,indent=2)+'\n',encoding='utf-8');(o/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
print('Published eight native museum photographs; added hall views to Colour and replaced Array book/review cameras. Historical images preserved.')
