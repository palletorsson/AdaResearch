from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=Path(__file__).parent;H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
figs=[]
for source,name,m,needle,alt in [
 ('space-final/cellular-field.png','cellular-field-uncovered','Random_Space','\n<!-- @shannon_entropy_meter -->','A blue cellular field on its low stand, clear of the pale random ground around it.'),
 ('game/waiting-and-seeing.png','waiting-and-seeing','Random_Game','\nEach panel joins seventeen heights.','The waiting podium and its five receding profiles, photographed from inside the museum.')]:
 src=o/source;dst=r/'doc/book/figures/randomness'/(name+'.png');shutil.copy2(src,dst)
 f={'source':src.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':H(dst),'capture':'Original native Godot museum PNG; controlled desktop camera at 1.7 m. No image editing; not headset evidence.'};figs.append(f)
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8');assert s.count(needle)==1
 image='\n![%s](/book-review/%s)\n'%(alt,f['canonical']);assert image not in s
 p.write_text(s.replace(needle,image+needle),encoding='utf-8')
(o/'figure-provenance.json').write_text(json.dumps(figs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
maps=json.loads((o/'baseline.json').read_text())['maps']
p=r/'commons/data/museum_core_encounters.json';raw=p.read_text(encoding='utf-8-sig');(o/'core-before-update.json').write_text(raw,encoding='utf-8');d=json.loads(raw)
for m in maps:
 room=d['rooms'][m];room['text_sha256']=H(r/'commons/maps'/m/'final.md');room['map_sha256']=H(r/'commons/maps'/m/'map_data.json');room['local_review']=o.relative_to(r).as_posix()+'/DECISIONS.md'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');(o/'figures-before-update.md').write_text(s,encoding='utf-8')
s+='\n\n## Randomness: fields and consequences — 25 September 2026\n\nTwo original museum photographs: the cellular field raised clear of the uneven ground, and the waiting podium beside its five profiles. [Reading and native comparisons](../iterations/2026-09-25-randomness-fields-and-consequences/index.html); [PNG provenance](../iterations/2026-09-25-randomness-fields-and-consequences/figure-provenance.json). Controlled desktop views; headset acceptance remains open.\n'
p.write_text(s,encoding='utf-8')
D={}
def decision(n,text,status='done',triage='fix'):D[f'book_randomness.{n:03d}']={'decision':text,'status':status,'triage':triage}
decision(1,'The malformed source grid is real: all six tokens now stand in the existing floored second chamber, all layers are 12 by 24, and the pathfinder counts all six. However, the loaded museum already used a separately stamped necklace: its bench stands at (3.5,0,19.5), supported at all three checked standing positions before and after. Retain that placement authority. A local sculpture exclusion clears the unrelated generated sculpture from its approach. Added a brief arrival sentence. No global plan regeneration: it would replace unrelated work and is not needed for this map read. Column/console contrast under the hall lighting remains a visual follow-up; do not read this as headset acceptance.')
decision(4,'Removed the desktop-carry exception and the platform label. The act of holding a mushroom close to the face remains in the chapter; no new claim about tracked-hand acceptance is made.')
decision(5,'Removed the desktop-carry aside at the podium. The passage follows holding, release and waiting; platform differences belong in implementation notes.')
decision(6,'Retain the existing chapter unchanged. The review read script defaults (five walkers, 30%) but the placed pheromone_terrain.tscn overrides them with four walkers and 40%. The native museum confirms four and 0.4. An initial diagnostic and tentative edit used the review values; the failed assertion led back to the scene, and the chapter was restored byte for byte.',triage='comment')
decision(9,'Added the waiting_profile encounter anchor before the last podium. The five profiles remain part of this encounter. Also corrected a separate timing claim: equal rates mean equal expected attempt counts, not identical hourly totals; the podium draws uniform waits rather than using the described Bernoulli tick rule.')
decision(10,'The exit now carries the question about decisions and disclosure through the Randomness biome ladder before Noise Types. No sequence order changed.')
decision(11,'Changed “Four works have returned” to “Four works share”. The gallery can introduce these works without requiring the reader to have visited them previously.')
decision(12,'Added the cellular field’s nearest/next-nearest distance comparison and the entropy gauge’s limitation: it counts its own symbols, not the surrounding textures. Both keep their existing roles. Native photographs showed the ground crossing them; only these placements now use 0.35 m and 1.05 m supports. A native cellular-field photograph enters the chapter.')
decision(27,'Specimen staging removes the authored demo PrismMesh, Camera3D and FillLight before building the bed. The opt-in stand:specimen path alone changes; the original standalone scene still contains all three. Native SIZE checks preserve specimen positions, types, yaw and ground, then restore the original sizes.')
decision(34,'This museum dartboard opts into keyboard:off so SPACE, D and R cannot operate AUTO/THROW/RESET while the visitor uses walking keys. Direct native input checks preserve count and AUTO; throwing still works. Standalone shortcuts remain enabled by default and repeated key events are ignored.')
decision(28,'Still open. The retained random ground remains physically visible and its separate sampler is described accurately. This pass lifts two obscured exhibits, but does not repair the shared walker’s broad-bounds classification or establish a complete route over that ground. Keep that navigation task separate from the text repair.','open','comment')
decision(29,'Still open. Native views confirm the mixer, lifted cellular field and lifted entropy gauge coexist. This is not the requested headset approach and knob-reading test.','open','comment')
decision(30,'Still open. The native field confirms the scene’s four walkers and 40% guidance, and advances 100 supplied steps. No tracked-pointer ATTRACT/AVOID/REPLAY test was performed. The captured view also shows the terrain close to the end wall and gate; investigate its full exposed footprint before headset acceptance.','open','comment')
(o/'decisions.json').write_text(json.dumps(D,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Two original figures, six current chapter references and thirteen review decisions prepared.')
