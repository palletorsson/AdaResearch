from pathlib import Path
import hashlib,json,shutil,difflib,re
from PIL import Image,ImageDraw,ImageFont
R=Path.cwd();H=R/'doc/book/iterations/2026-09-28-foundry-a-mark-in-the-room';RUN=R/'ada_run/encounter_pilot/Pattern_Foundry_reading_return'
read=lambda p:p.read_text(encoding='utf-8-sig')
write=lambda p,s:p.write_bytes(s.encode('utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
report=json.loads(read(RUN/'report.json'));assert report['passed']
for f in ['report.json','stdout.log','source_manifest.json']+[p.name for p in RUN.glob('*.png')]:shutil.copy2(RUN/f,H/f)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',28)
def pair(out,a,b,la,lb):
 ims=[Image.open(H/a).convert('RGB'),Image.open(H/b).convert('RGB')]
 canvas=Image.new('RGB',(2880,1020),'#f2f0e9');d=ImageDraw.Draw(canvas)
 for i,(im,label) in enumerate(zip(ims,[la,lb])):
  canvas.paste(im,(i*1440,60));d.text((i*1440+24,14),label,font=font,fill='#202020')
 canvas.save(H/out)
pair('room-pair.png','room-one-mark.png','room-two-moments.png','Wall and floor follow the studio','The wall changes; the floor keeps its image')
pair('floor-repair.png','before-runtime/room-one-mark.png','room-one-mark.png','Before: the hall-wide print covers the room floor','Now: the room floor can receive its own pattern')
pair('sample-pair.png','samples-marked.png','curve-keeps-a-mark.png','Both samples accept the source mark','The flat sample follows; the curve keeps that mark')
pair('floor-pair.png','floor-before.png','floor-one-mark.png','The source before one cell is changed','The same floor after that source edit')
source_paths=[p.relative_to(H/'before').as_posix() for p in (H/'before/commons').rglob('*') if p.is_file() and (p.suffix=='.gd' or p.name=='map_data.json')]
source_paths+=['commons/resourses/shaders/wallpaper_tile.gdshader','commons/patterns/pattern_loader.gd']
(H/'after').mkdir(exist_ok=True);write(H/'after/.gdignore','')
manifest={'scope':'Two production fixes restore visible local ground; map and remaining recorded encounter sources are unchanged. Shader and loader captured as current dependencies.','sources':{f:sha(R/f) for f in source_paths},'changed':[]}
for f in source_paths:
 dest=H/'after'/f;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/f,dest)
 before=H/'before'/f
 if before.exists() and before.read_bytes()!=(R/f).read_bytes():
  manifest['changed'].append(f)
  write(H/(Path(f).stem+'.diff'),''.join(difflib.unified_diff(read(before).splitlines(True),read(R/f).splitlines(True),fromfile='before/'+f,tofile=f)))
write(H/'encounter-sources.json',json.dumps(manifest,indent=2))
old=read(H/'before/commons/maps/Pattern_Foundry/final.md');new=read(R/'commons/maps/Pattern_Foundry/final.md')
write(H/'Pattern_Foundry.current.md',new)
write(H/'Pattern_Foundry.diff',''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Pattern_Foundry/final.md',tofile='commons/maps/Pattern_Foundry/final.md')))
a=old.split('\n\n');b=new.split('\n\n');chunks=[]
for tag,i,j,k,l in difflib.SequenceMatcher(a=a,b=b,autojunk=False).get_opcodes():
 if tag!='equal':chunks.append({'before':'\n\n'.join(a[i:j]),'after':'\n\n'.join(b[k:l])})
write(H/'changes.json',json.dumps(chunks,ensure_ascii=False,indent=2))
core=R/'commons/data/museum_core_encounters.json';raw=read(core);data=json.loads(raw);row=data['rooms']['Pattern_Foundry']
newhash=sha(R/'commons/maps/Pattern_Foundry/final.md');newreview='doc/book/iterations/'+H.name+'/index.html#reading'
# Preserve every other byte and all other hall entries.
start=raw.index('"Pattern_Foundry":');end=raw.index('\n    }',start);block=raw[start:end]
block=block.replace('"text_sha256": "'+row['text_sha256']+'"','"text_sha256": "'+newhash+'"').replace('"local_review": "'+row['local_review']+'"','"local_review": "'+newreview+'"')
write(core,raw[:start]+block+raw[end:])
note=R/'commons/maps/Pattern_Foundry/field_notes.md'
with note.open('a',encoding='utf-8',newline='\n') as f:f.write('''\n\n## 2026-09-28 — A mark in the room\n\nThe writing now follows one source decision into repeated marks, compares flat and bent receiving sheets, then enters the curved studio room. Its wall and floor start connected to the studio. Holding the floor lets the wall carry another edit while the ground retains an earlier image. Detailed source ownership, saved state, offsets and whole-hall controls remain in the return-visit section.\n\nNative photographs exposed a hidden-floor defect that texture-state checks missed: the architectural print inherited the controller stand's height and covered the room floor. Subtracting the complete grid-local position keeps that print at the museum floor; the local printed disc sits above it. Collision and map placement remain unchanged. The final probe passes 39 checks, including visible-pixel change, visible held-floor persistence, ordinary-controller entry/sideways motion/return, relink and undo. A source edit changes 633,747 sampled floor bytes; the held floor changes zero bytes during the next edit. No source recipe was saved. Headset reach/comfort, performance and learner response remain untested.\n\nReview, exact text/source diffs, frozen before/after sources and native images: `doc/book/iterations/2026-09-28-foundry-a-mark-in-the-room/index.html`.\n''')
for n in ['final.md','intent.md','tutorial.md','technical.md','critical.md','field_notes.md']:
 dest=H/'after/commons/maps/Pattern_Foundry'/n;dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/'commons/maps/Pattern_Foundry'/n,dest)
print('Paired native figures, source diffs, chapter diff and catalogue saved.')
print(manifest['changed'])
