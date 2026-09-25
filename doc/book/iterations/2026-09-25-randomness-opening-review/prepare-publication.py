from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-randomness-opening-review'
H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
source=o/'entropy/ruin-waiting.png';dst=r/'doc/book/figures/randomness/ruin-waiting-museum.png'
dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(source,dst)
fig={'source':source.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':H(dst),'capture':'Native Godot museum, paused on arrival, interior camera at local eye height 1.7 m. Original PNG, no image editing.'}
(o/'figure-provenance.json').write_text(json.dumps([fig],indent=2)+'\n',encoding='utf-8')
p=r/'commons/maps/Random_Entropy/final.md';s=p.read_text(encoding='utf-8');needle='Press RUN / PAUSE to hold the scene, or ONE STONE'
assert s.count(needle)==1
image='![The four columns and their lintel wait intact, with the brick wall behind them and the controls in front.](/book-review/doc/book/figures/randomness/ruin-waiting-museum.png)\n\n'
assert image not in s;p.write_text(s.replace(needle,image+needle),encoding='utf-8')
p=r/'commons/data/museum_core_encounters.json';raw=p.read_text(encoding='utf-8-sig');(o/'core-before-update.json').write_text(raw,encoding='utf-8');d=json.loads(raw)
maps=json.loads((o/'baseline.json').read_text())['maps']
for m in maps:
 room=d['rooms'][m];room['text_sha256']=H(r/'commons/maps'/m/'final.md');room['map_sha256']=H(r/'commons/maps'/m/'map_data.json');room['local_review']='doc/book/iterations/2026-09-25-randomness-opening-review/DECISIONS.md'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');s+='\n\n## Randomness opening — 25 September 2026\n\nThe entropy ruin waits intact for its visitor. One unmodified native museum photograph enters the chapter; same-camera dismantling and removal-floor pairs, plus views from within the printed walls, are in [the review](../iterations/2026-09-25-randomness-opening-review/index.html). [Provenance](../iterations/2026-09-25-randomness-opening-review/figure-provenance.json). Desktop evidence only. The removal-floor process completes its checks but fails during shutdown; that limit is recorded in the review.\n';p.write_text(s,encoding='utf-8')
print('One original museum photograph added; four current room references refreshed.')
