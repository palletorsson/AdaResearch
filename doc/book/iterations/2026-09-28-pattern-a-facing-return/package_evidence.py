from pathlib import Path
from PIL import Image,ImageDraw,ImageFont
import json,shutil,hashlib,difflib
R=Path.cwd();H=R/'doc/book/iterations/2026-09-28-pattern-a-facing-return';N=R/'ada_run/encounter_pilot/Tutorial_Pattern_facing_return';M=R/'commons/maps/Tutorial_Pattern'
read=lambda p:p.read_text(encoding='utf-8-sig')
write=lambda p,s:p.write_bytes(s.encode('utf-8'))
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
report=json.loads(read(N/'report.json'));assert report['passed']
for f in ['report.json','stdout.log','source_manifest.json']+[p.name for p in N.glob('*.png')]:shutil.copy2(N/f,H/f)
font=ImageFont.truetype('C:/Windows/Fonts/segoeui.ttf',26)
def pair(name,a,b,labels,crop=None):
 ims=[Image.open(H/(n+'.png')).convert('RGB') for n in [a,b]]
 if crop:ims=[im.crop(crop) for im in ims]
 w,h=ims[0].size;board=Image.new('RGB',(w*2,h+60),'#f2efe6');d=ImageDraw.Draw(board)
 for i,im in enumerate(ims):board.paste(im,(w*i,60));d.text((w*i+20,15),labels[i],font=font,fill='#242424')
 board.save(H/name)
pair('source-pair.png','two-fixed-fields','source-flipped',['The original source in two fixed rules','FLIP X changes the source; both fields respond'],(285,290,1165,655))
pair('floor-pair.png','floor-p1','floor-pm',['P1: the same facing returns','PM: alternate columns reverse the source address'])
pair('interruption-pair.png','two-fixed-fields','an-interruption-repeated',['Before one source cell is painted','The new mark becomes regular too'],(285,290,1165,655))
files=[f.relative_to(H/'before').as_posix() for f in (H/'before/commons').rglob('*') if f.is_file() and (f.suffix in ['.gd','.gdshader','.tscn'] or f.name=='map_data.json')]
manifest={'scope':'Production artifact, shader, scene and map unchanged in this reading pass. Fresh native screenshots and interactions use these sources.','sources':{f:sha(R/f) for f in files}}
assert all((H/'before'/f).read_bytes()==(R/f).read_bytes() for f in files)
write(H/'encounter-sources.json',json.dumps(manifest,indent=2))
old=read(H/'before/commons/maps/Tutorial_Pattern/final.md');new=read(M/'final.md')
write(H/'Tutorial_Pattern.current.md',new)
write(H/'Tutorial_Pattern.diff',''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/Tutorial_Pattern/final.md',tofile='commons/maps/Tutorial_Pattern/final.md')))
a=old.split('\n\n');b=new.split('\n\n');chunks=[]
for tag,i,j,k,l in difflib.SequenceMatcher(a=a,b=b,autojunk=False).get_opcodes():
 if tag!='equal':chunks.append({'before':'\n\n'.join(a[i:j]),'after':'\n\n'.join(b[k:l])})
write(H/'changes.json',json.dumps(chunks,ensure_ascii=False,indent=2))
core=R/'commons/data/museum_core_encounters.json';raw=read(core);data=json.loads(raw);row=data['rooms']['Tutorial_Pattern']
start=raw.index('"Tutorial_Pattern":');end=raw.index('\n    }',start);block=raw[start:end]
block=block.replace('"text_sha256": "'+row['text_sha256']+'"','"text_sha256": "'+sha(M/'final.md')+'"').replace('"local_review": "'+row['local_review']+'"','"local_review": "doc/book/iterations/'+H.name+'/index.html#reading"')
write(core,raw[:start]+block+raw[end:])
with (M/'field_notes.md').open('a',encoding='utf-8',newline='\n') as f:f.write('''\n\n## 2026-09-28 — A mark faces back\n\nLight reading pass. The existing encounter and critical argument are strong: a source interruption acquires a schedule. The reader now tries the floor-rule switch and source flip before the code distinguishes their locations. All three exact code excerpts, source-edit returns, the forty-centimetre motif span and the closing limits remain. A square that turns without seeming to move quietly recalls Transformation. Summary now correctly identifies the third Patterns hall.\n\nProduction map, scene, artifact scripts and shader are unchanged. A fresh isolated museum run passes 40 checks using real pointer callbacks, source bytes, rendered floor/reference comparisons and ordinary-controller approach/sideways movement/return. Switching the floor rule changes visible floor pixels but no source cells; the fixed panel pixels stay unchanged. Source flip and painting reach the reference images. Two flips, four turns, undo and undoable reset retain their stated behaviour. The initial reference-image sample accidentally included the changing centre status label; narrowed it to the two printed fields.\n\nNative photographs are taken from inside the museum at standing height. Book comparisons crop the same-camera images to the panels and place them side by side; full native frames remain available. No source recipe saved or shared runtime output replaced. Headset reach/comfort, performance and learner response remain untested. Review and exact diff: `doc/book/iterations/2026-09-28-pattern-a-facing-return/index.html`.\n''')
print('Evidence packaged, chapter reference updated. Changes confined to reading and supporting notes.')
