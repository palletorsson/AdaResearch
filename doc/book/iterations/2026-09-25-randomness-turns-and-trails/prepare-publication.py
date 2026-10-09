from pathlib import Path
import hashlib,json,shutil
r=Path.cwd();o=Path(__file__).parent;H=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
figs=[]
for source,name,m,needle,alt in [
 ('rotation-after/tilt-field.png','tilt-field-contained','Random_Rotate_Random_XYZ','\n<!-- @ -->\n\nHere each piece','Twenty-five cubes, level at both ends and tilted through the middle, fit behind the changing stacks.'),
 ('gaussian-after/sampler-overview.png','sampler-visible-record','Random_Gaussian','\nCLEAR empties the display','The sampler’s numerical record stands beside its histogram, above the compact controls.')]:
 src=o/source;dst=r/'doc/book/figures/randomness'/(name+'.png');shutil.copy2(src,dst)
 fig={'source':src.relative_to(r).as_posix(),'canonical':dst.relative_to(r).as_posix(),'sha256':H(dst),'capture':'Original native Godot museum PNG; controlled eye-height camera. No image editing; not headset evidence.'};figs.append(fig)
 p=r/'commons/maps'/m/'final.md';s=p.read_text();assert s.count(needle)==1
 image='\n![%s](/book-review/%s)\n'%(alt,fig['canonical'])
 assert image not in s;p.write_text(s.replace(needle,image+needle),encoding='utf-8')
(o/'figure-provenance.json').write_text(json.dumps(figs,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
maps=json.loads((o/'baseline.json').read_text())['maps']
p=r/'commons/data/museum_core_encounters.json';raw=p.read_text(encoding='utf-8-sig');(o/'core-before-update.json').write_text(raw,encoding='utf-8');d=json.loads(raw)
for m in maps:
 room=d['rooms'][m];room['text_sha256']=H(r/'commons/maps'/m/'final.md');room['map_sha256']=H(r/'commons/maps'/m/'map_data.json');room['local_review']=o.relative_to(r).as_posix()+'/DECISIONS.md'
p.write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
p=r/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8-sig');(o/'figures-before-update.md').write_text(s,encoding='utf-8')
s+='\n\n## Randomness: turns and trails — 25 September 2026\n\nTwo original photographs from inside the museum: the complete tilt field and the sampler with its visible record. [Before/after and reading](../iterations/2026-09-25-randomness-turns-and-trails/index.html); [PNG provenance](../iterations/2026-09-25-randomness-turns-and-trails/figure-provenance.json). Controlled desktop camera views; headset work remains open.\n';p.write_text(s,encoding='utf-8')
D={}
def decision(n,text,status='done',triage='fix'):D[f'book_randomness.{n:03d}']={'decision':text,'status':status,'triage':triage}
decision(3,'Removed the two desktop-specific asides. Keep the die’s possibility of rocking and the distinctions between release, orientation and reward; moving platform limitations out of the chapter does not resolve the headset task.')
decision(7,'The review read the script default but missed animate_slope=false in SlopeGradientCubes.tscn. The native baseline and revised hall both remain still after a supplied update. Replaced “begins to tilt” with a spatial progression through the whole half-sine field; no clock is claimed.',triage='comment')
decision(8,'Added the pixel_cloud encounter anchor and located it on the visitor’s right, between cabinet and basin. Reopened the terrarium anchor for its following logbook paragraph so those paragraphs remain attached to the right work.')
decision(14,'Named the Point Trace room and its drawing dot explicitly; retained the distinction between a hand’s gesture and a accumulated random offset.')
decision(16,'Retain the current chapter. It already carries the reward policy, level versus tilted release, lost order in the histogram, and the newer paired-dice / continuing-die studies. An older rewrite would lose those newer encounters. Only the two desktop asides were removed.',triage='comment')
decision(18,'Still open. This pass did not perform the requested sixteen tracked-hand throws of the die and coin. Desktop photographs and supplied signals cannot establish headset reading or reward-rain safety.','open','comment')
decision(19,'Leave physics unchanged pending headset throws. The report itself found no single setting that fixes hopping without changing throws across 22 maps; the prose still permits rocking. This is a deferred tuning question, not a repaired simulation.','open','comment')
decision(20,'Still open. The native museum field is now contained and visible, but the complete matched-stack approach, comparison and exit have not been walked in a headset.','open','comment')
decision(21,'This placement opts into study:compact: a 5×5 field of 0.6 m cubes on 0.75 m spacing, covering the complete level / 30-degree / level progression. Moved from cell (3,11) to (6,11), with local cube lift clear of the floor. All 25 bounds fit the interior. Other placements retain the authored 7×30 scene.')
decision(26,'Confirmed visually from the marked standing position: the console concealed the old record. This hall opts into readout:wing, moving and enlarging the same record beside the histogram on a stem, keeping the compact controls. Native BINS retains the 300 values; WIDTH changes spread and clears them. Legacy cabinets retain their old plate. A look toward the wing now exposes all six lines; headset comfort remains untested.')
decision(33,'Removed the mid-chapter “A hand with company” heading; the random_draw_dot anchor and its prose stay in place.')
(o/'decisions.json').write_text(json.dumps(D,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Two museum figures, four current room references, and eleven explicit review decisions prepared.')
