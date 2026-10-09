from pathlib import Path
import json,hashlib,shutil
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-wavefunctions-review-comments';H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
# Figure creation and core refresh are run after successful final museum captures.
figs=[]
for source,name in [('circle-clear/circle-top.png','unit-circle-return-museum.png'),('synthesis/sum-returned.png','synthesis-return-museum.png')]:
 p=o/source;dst=r/'doc/book/figures/wavefunctions'/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dst)
 figs.append({'source':p.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':H(dst),'capture':'Native Godot camera inside the actual loaded museum; supplied held phase. Original PNG copied without image edits.'})
(o/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
for m,needle,figure in [
 ('WaveFunctions_Unit_Circle',"The point's vertical position rises",'![The turning point at the top of the complete circle, inside the museum.](/book-review/doc/book/figures/wavefunctions/unit-circle-return-museum.png)\n\n'),
 ('WaveFunctions_Synthesis_Lab','## Back at the bench\n\n','## Back at the bench\n\n![The five rows and their restored sum on the synthesis bench inside the museum.](/book-review/doc/book/figures/wavefunctions/synthesis-return-museum.png)\n\n')]:
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');assert s.count(needle)==1
 s=s.replace(needle,figure+needle if m=='WaveFunctions_Unit_Circle' else figure);p.write_text(s,encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');s+='\n\n## Wavefunctions — 25 September 2026\n\nTwo native museum views: the full raised unit circle with its point at the top, and the synthesis bench after restoring the held baseline. Source PNGs, production source manifests, phase/control conditions and exact hashes are in [the review](../iterations/2026-09-25-wavefunctions-review-comments/figure-provenance.json). No image edits or isolated stage renders. Desktop evidence; no headset acceptance.\n';p.write_text(s,encoding='utf-8')
base=json.loads((o/'baseline.json').read_text());p=r/'commons/data/museum_core_encounters.json';raw=p.read_text(encoding='utf-8-sig');(o/'core-before-update.json').write_text(raw,encoding='utf-8');d=json.loads(raw)
for m in base['maps']:
 room=d['rooms'][m];room['text_sha256']=H(r/'commons/maps'/m/'final.md');room['map_sha256']=H(r/'commons/maps'/m/'map_data.json');room['local_review']='doc/book/iterations/2026-09-25-wavefunctions-review-comments/DECISIONS.md'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Two book figures added; sequence core hashes refreshed, roles retained.')
