from pathlib import Path
import json,hashlib,shutil
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-transformation-review-comments';run=root/'ada_run/encounter_pilot/Trans_Pit'
figs=json.loads((out/'figure-provenance.json').read_text(encoding='utf-8'))
for name in ['growers-small.png','growers-large.png','rotation-observation-floor.png']:
 src=run/name;dst=out/name;shutil.copy2(src,dst)
 if name.startswith('growers-'):
  dst=root/'doc/book/figures/Trans_Pit'/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(src,dst)
  figs.append({'map':'Trans_Pit','source':(out/name).relative_to(root).as_posix(),'canonical':dst.relative_to(root).as_posix(),'sha256':hashlib.sha256(dst.read_bytes()).hexdigest(),'kind':'Unmodified native Godot capture after fire removal; fixed camera, paused size extremes.'})
for name in ['report.json','source_manifest.json','stdout.log','spec.json']:
 shutil.copy2(run/name,out/('runtime.json' if name=='report.json' else name))
(out/'runtime-process.json').write_text(json.dumps({'exit_code':0,'checks':72,'scope':'Controlled desktop Godot run in an isolated production museum; no headset or learner acceptance claim.'},indent=2)+'\n',encoding='utf-8')
(out/'figure-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
(root/'doc/book/figures/transformation-provenance.json').write_text(json.dumps(figs,indent=2)+'\n',encoding='utf-8')
p=root/'commons/maps/Trans_Pit/final.md';s=p.read_text(encoding='utf-8')
a='![A fixed view down a lane: a small green cube, then the same cube enlarged across the view.](/book-review/doc/book/iterations/2026-09-23-moving-boundary/the-room-keeps-time.png)'
b='![At its smallest, the green cube leaves the final door visible down the lane.](/book-review/doc/book/figures/Trans_Pit/growers-small.png)\n\n![At full size, the same cube fills the view from the same position.](/book-review/doc/book/figures/Trans_Pit/growers-large.png)'
assert a in s;p.write_text(s.replace(a,b),encoding='utf-8')
p=root/'doc/book/figures/README.md';s=p.read_text(encoding='utf-8')
s+='\n## Transformation\n\n`transformation-provenance.json` records two original 23 September bank photographs and two fresh 24 September grower photographs after the legacy fire utilities were removed. These are unmodified native Godot images. The pairs retain their respective fixed cameras; the before/after states are held for comparison. The new run passed 72 controlled desktop assertions and exited cleanly. This is not headset or learner acceptance. Historical review images remain unchanged.\n'
p.write_text(s,encoding='utf-8')
changed=json.loads((out/'changed-files.json').read_text(encoding='utf-8'));changed.append('doc/book/figures/README.md')
# Read fresh shared metadata and update only the seven reviewed rooms.
seq=json.loads((root/'commons/maps/sequences/transformation.json').read_text(encoding='utf-8-sig'))['sequences']['transformation']
p=root/'commons/data/museum_core_encounters.json';data=json.loads(p.read_text(encoding='utf-8-sig'))
for m in seq['maps']:
 data['rooms'][m]['text_sha256']=hashlib.sha256((root/'commons/maps'/m/'final.md').read_bytes()).hexdigest()
 data['rooms'][m]['local_review']='http://localhost:3003/book-tasks/review?seq=transformation&map='+m
 if m=='Trans_Pit':data['rooms'][m]['map_sha256']=hashlib.sha256((root/'commons/maps'/m/'map_data.json').read_bytes()).hexdigest()
p.write_text(json.dumps(data,ensure_ascii=False,indent=2)+'\n',encoding='utf-8');changed.append(p.relative_to(root).as_posix())
(out/'changed-files.json').write_text(json.dumps(changed,indent=2)+'\n',encoding='utf-8')
# Keep review proposals intact. These notes record the smaller change actually made.
D={}
def decide(ids,layer,text):
 for n in ids:D[f'book_transformation.{n:03}']={'status':'done','triage':'fix','layer':layer,'decision':text}
decide([1,14],'placement','Removed all 28 legacy h:fire cells from Trans_Pit, including the 21 cells on the rotation observation floor. Current intent, summary and tutorial already describe an optional level-floor study. Disarming Area3D detection left flame visuals in place; removing the utilities repairs the promised encounter. No other grid cell or artifact placement changed. Source and companion notes updated; new native grower photographs replace the outdated chapter pair. In the isolated production museum there are no remaining DangerZone instances, all 21 observation cells have floor support, and the actual museum body traverses the middle and both side strips. The complete run passed 72 checks and exited 0. No live bake replacement or headset claim.')
decide([2],'prose','Replaced editor-relative eastern passage with open floor along the side wall. The optional route and invitation to return and watch remain; no new left/right instruction is imposed.')
decide([3],'prose','Separated the one-metre authored mesh from the displayed cube, which starts at half a metre. Source scale_cube.gd initializes current_scale to min_scale and multiplies the unit mesh and collision by the same factor. Kept the observable growth before the implementation.')
decide([4],'prose','Located the existing stand in the still central aisle at the near end of the bands. Clarified that all four cyan bodies depart together, pink follows, and the study repeats; REPLAY starts it again. Source array_body_comparison.gd confirms that order. Kept the bodily comparison and widths.')
decide([5,15],'figure','Added the existing bank-at-crossing and bank-gap native photographs to Trans_Introduction at the loss-of-overlap passage. Both use the same camera and aligned plank pose, inspected visually and confirmed by the original capture record. Copied the original PNGs byte-for-byte to stable book figure paths; no fabricated screenshot or new control claim. Published them as two images with one comparison caption; the review page puts the pair side by side.')
decide([6],'prose','Named _t as a fraction kept by the script, so the reader does not search for a visible progress mark. The existing interpolation excerpt and timed-journey argument remain; source pusher_block.gd uses _t in the endpoint lerp.')
decide([7],'prose','Removed only No pickup count decides whether you may enter. The preceding passage already explains approach, waiting, vacancy and return. Its nearness rule is tested in the actual door; the discarded sentence answered an abandoned design question.')
decide([8],'caption','Removed existing/actual museum/live artifact provenance language from the named caption and alt-text passages across Translation, Rotation, Scale, Body and Pit. Retained useful information about standpoint, separate handle gestures, paused states and unchanged cameras. Capture provenance remains in the supporting records.')
decide([9],'prose','Introduced the smaller markers beside the moving examples as isolated operations: vertical travel, turning and size change. The map places y_translation_cube, continuous rotation_oscillation_cube and uniform_scale_marker at those three stations; the still cube has no corresponding marker.')
decide([10],'prose','Named the floor caption beyond the last row, which the source map places at (4,21). Kept the distinction between passing the blocks and leaving their measured reach.')
decide([11],'prose','Replaced Trans_Translation, Trans_Rotation and Point_Trace IDs in reader-facing handovers with next hall and trace hall. The sequence and referenced encounters are unchanged.')
decide([12],'structure','Gave the carousel its own heading, A rate instead of an angle, after the carousel anchor. This makes the shift from fixed tunnel angles to changing rates easier to follow without shortening its comparison.')
decide([13,16],'prose','Changed outwards to sideways and up and out to up and across. The shipped lift_lateral course constrains the second leg along X. The relationship between permitted movement and the recorded line remains intact.')
(out/'decisions.json').write_text(json.dumps(D,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
print('Saved 16 decisions, four figure records, runtime evidence and scoped manuscript metadata.')
