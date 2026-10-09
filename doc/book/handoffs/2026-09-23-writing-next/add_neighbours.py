from pathlib import Path
import sys,json,re,shutil,hashlib,zipfile
ROOT=Path(__file__).resolve().parents[4];OUT=Path(__file__).resolve().parent
sys.path.insert(0,str(ROOT/'tools'));import build_sequence_review_packages as pack
spine=sorted(pack.read_json(ROOT/'commons/maps/curriculum_spine.json')['spine']['sequences'],key=lambda s:float(s['order']));names=[s['name'] for s in spine]
report=json.loads((OUT/'packages.json').read_text(encoding='utf-8'))
for item in report:
 seq=item['sequence'];folder=OUT/'packages'/seq;ix=names.index(seq);parts=['# The previous ending and the next beginning','Current neighbouring manuscripts, included so the pilot can carry the learning journey forward. These are context, not assigned edits.']
 for label,neighbour,index in [('Arriving from',names[ix-1] if ix>0 else None,-1),('Continuing to',names[ix+1] if ix+1<len(names) else None,0)]:
  if neighbour is None:continue
  m=pack.read_json(ROOT/f'commons/maps/sequences/{neighbour}.json')['sequences'][neighbour]['maps'][index]
  p=ROOT/f'commons/maps/{m}/final.md';t=p.read_text(encoding='utf-8');parts += [f'## {label}: {neighbour} / {m}',f'Source: commons/maps/{m}/final.md',t]
  dest=folder/'sources'/p.relative_to(ROOT);dest.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,dest)
 (folder/'NEIGHBOURS.md').write_text('\n\n'.join(parts)+'\n',encoding='utf-8')
 for n in ['START_HERE.md','review.md']:
  p=folder/n;s=p.read_text(encoding='utf-8');s=s.replace('Read WRITING_BRIEF.md, ASSIGNMENT.md, the complete book.md and the four reference chapters in VOICE_EXAMPLES.md.','Read WRITING_BRIEF.md, ASSIGNMENT.md, the complete book.md, NEIGHBOURS.md and the four reference chapters in VOICE_EXAMPLES.md.');p.write_text(s,encoding='utf-8')
 p=folder/'MANIFEST.json';manifest=json.loads(p.read_text(encoding='utf-8'));manifest['files']={f.relative_to(folder).as_posix():hashlib.sha256(f.read_bytes()).hexdigest() for f in sorted(folder.rglob('*')) if f.is_file() and f.name!='MANIFEST.json'};p.write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
 archive=OUT/item['zip']
 with zipfile.ZipFile(archive,'w',zipfile.ZIP_DEFLATED,compresslevel=6) as z:
  for f in sorted(folder.rglob('*')):
   if f.is_file():z.write(f,f.relative_to(folder).as_posix())
 item.update(zip_sha256=hashlib.sha256(archive.read_bytes()).hexdigest(),bytes=archive.stat().st_size,files=len(manifest['files']))
(OUT/'packages.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8');(OUT/'packages/index.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print('Included both current neighbouring hall manuscripts in every packet.')
