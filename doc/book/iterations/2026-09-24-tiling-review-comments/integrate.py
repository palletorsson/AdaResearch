from pathlib import Path
import json,hashlib,shutil
r=Path.cwd();o=r/'doc/book/iterations/2026-09-24-tiling-review-comments'
p=r/'commons/maps/Ribbon_Patterns_02/final.md';s=p.read_text(encoding='utf-8');old='Seen straight on, the squares lose their edges in the surrounding grey. They are still there; the contrast that picked them out has gone.';assert s.count(old)==1;s=s.replace(old,'Seen straight on, their faces almost disappear into the grey. The raised edges may still give them away. The contrast has gone; the little bodies remain.');p.write_text(s,encoding='utf-8')
# Preserve each run's evidence before another task can overwrite the runner folder.
for m,name in [('Symmetry_Seventeen','symmetry'),('Ribbon_Patterns_02','contrast'),('Ribbon_Patterns_03','turret')]:
 src=r/'ada_run/encounter_pilot'/m;dest=o/name;dest.mkdir(exist_ok=True)
 report=json.loads((src/'report.json').read_text(encoding='utf-8'));assert report['passed'] and not report['failures']
 for p in src.iterdir():
  if p.suffix=='.png' or p.name in ['report.json','source_manifest.json','stdout.log','engine.log','spec.json','control.json']:shutil.copyfile(p,dest/p.name)
 (dest/'process.json').write_text(json.dumps({'exit_code':0,'scope':'Native isolated museum render; supplied button signals and XR targeting contract where stated; no headset traverse.'},indent=2)+'\n',encoding='utf-8')
 for p in dest.glob('*.png'):shutil.copyfile(p,o/p.name)
figdir=r/'doc/book/figures/tiling';figdir.mkdir(exist_ok=True,parents=True);figs=[]
for name,sub in [('symmetry-p1-pg','symmetry'),('contrast-neighbours','contrast'),('contrast-equal','contrast'),('fabric-studio','turret')]:
 src=o/sub/(name+'.png');target=figdir/(name+'-museum.png');shutil.copyfile(src,target)
 figs.append({'source':src.relative_to(r).as_posix(),'canonical':target.relative_to(r).as_posix(),'sha256':hashlib.sha256(src.read_bytes()).hexdigest(),'kind':'Godot viewport PNG, unmodified; actual museum, standing camera; GL compatibility renderer.','evidence':(o/sub/'source_manifest.json').relative_to(r).as_posix()})
(o/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
def figure(m,needle,content):
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');assert s.count(needle)==1;s=s.replace(needle,needle+'\n\n'+content);p.write_text(s,encoding='utf-8')
figure('Symmetry_Seventeen','Try to describe the difference before pressing **HOLD**. This saves the current image on the left. It gives your next change somewhere to return to.', '![Held P1 and live PG in the museum side bay](/book-review/doc/book/figures/tiling/symmetry-p1-pg-museum.png)\n\n*One source, two returns. The left panel keeps P1; on the right, PG reflects alternate blocks and slips the source lookup by two rows.*')
figure('Ribbon_Patterns_02','Numerical equality is something we can inspect in the program. It does not oblige every viewer, display or viewing situation to produce the same experience.','![Equal target values against dark and light surrounds inside the museum](/book-review/doc/book/figures/tiling/contrast-neighbours-museum.png)\n\n*One grey value, two different surrounds.*\n\n![The same comparison after making both surrounds grey](/book-review/doc/book/figures/tiling/contrast-equal-museum.png)\n\n*The surrounds now match the targets. Their faces nearly disappear; the raised squares remain.*')
figure('Ribbon_Patterns_03','We still have the array we learned to read. We have given it somewhere else to arrive.','![The fabric studio and preview dress inside the museum](/book-review/doc/book/figures/tiling/fabric-studio-museum.png)\n\n*The small source reaches a flat wall and a skirt. The crown and sleeves keep the look’s own materials.*')
# Refresh only owned rooms, against a fresh core snapshot to preserve parallel work.
p=r/'commons/data/museum_core_encounters.json';raw=p.read_bytes();(o/'core-before-update.json').write_bytes(raw);core=json.loads(raw.decode('utf-8-sig'))
base=json.loads((o/'baseline.json').read_text(encoding='utf-8'))
for m in base['maps']:
 room=core['rooms'][m]
 for kind,fn in [('text','final.md'),('map','map_data.json')]:room[kind+'_sha256']=hashlib.sha256((r/'commons/maps'/m/fn).read_bytes()).hexdigest()
 room['local_review']='doc/book/iterations/2026-09-24-tiling-review-comments/index.html#'+m
p.write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');s+='\n\n## Tiling — native museum views, 24 September 2026\n\nFour unmodified Godot viewport captures from the loaded halls: held P1/live PG, unequal/equal contrast surrounds, and the fabric studio. Standing cameras preserve the actual architecture, materials and neighbouring artifacts. These are GL compatibility renders, not tracked-headset screenshots. [Provenance and hashes](../iterations/2026-09-24-tiling-review-comments/figure-provenance.json).\n';p.write_text(s,encoding='utf-8')
print('Four native figures added to canonical chapters; current owned core records refreshed.')
