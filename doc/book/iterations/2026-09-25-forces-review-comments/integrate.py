from pathlib import Path
import json,hashlib,shutil
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-forces-review-comments';H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();base=json.loads((o/'baseline.json').read_text())
figdir=r/'doc/book/figures/forces';figdir.mkdir(parents=True,exist_ok=True);figs=[]
for name,sub in [('inside-the-passage','drag'),('two-crossings','place')]:
 src=o/sub/(name+'.png');dst=figdir/(name+'-museum.png');shutil.copyfile(src,dst)
 figs.append({'source':src.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':H(src),'kind':'Unmodified Godot viewport PNG from the loaded museum; standing camera, existing architecture/materials; GL compatibility renderer.','evidence':(o/sub/'source_manifest.json').relative_to(r).as_posix()})
(o/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
def figure(m,needle,content):
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');assert s.count(needle)==1 and content not in s;s=s.replace(needle,needle+'\n\n'+content);p.write_text(s,encoding='utf-8')
figure('Vectors_Act4a_KineticForces','One visible medium contains two implementations. The fact that both seem slower is a beginning for comparison, not proof that they share a mechanism.','![Standing inside the coloured walking passage in the Kinetic Forces hall](/book-review/doc/book/figures/forces/inside-the-passage-museum.png)\n\n*The cubes cross the strips; the walking passage runs through them. A cube receives a force. The stick receives a change to its requested speed.*')
figure('Vectors_Act5_ForceAsPlace','Five metres of air, marked by a cage. The thin edges are visible; they are not walls. A solid plank remains through the gap. Look along it, then into the air beside it. What would have to change for both to carry you?','![The plank and the outlined carrying field seen from inside the museum](/book-review/doc/book/figures/forces/two-crossings-museum.png)\n\n*The plank keeps a route through the gap. Beside it, the outline marks where another rule can carry you.*')
p=r/'commons/data/museum_core_encounters.json';raw=p.read_bytes();(o/'core-before-update.json').write_bytes(raw);core=json.loads(raw.decode('utf-8-sig'))
for m in base['maps']:
 for kind,fn in [('text','final.md'),('map','map_data.json')]:core['rooms'][m][kind+'_sha256']=H(r/'commons/maps'/m/fn)
 core['rooms'][m]['local_review']='doc/book/iterations/2026-09-25-forces-review-comments/index.html#'+m
p.write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');s+='\n\n## Forces — native museum views, 25 September 2026\n\nTwo unmodified Godot viewport captures from standing cameras inside the actual halls: the coloured drag passage and the plank beside the carrying field. Architecture, materials and neighbouring works remain as loaded. Desktop GL compatibility renders, not tracked-headset screenshots. [Evidence and hashes](../iterations/2026-09-25-forces-review-comments/figure-provenance.json).\n';p.write_text(s,encoding='utf-8')
print('Two native museum figures added; five core records refreshed.')
