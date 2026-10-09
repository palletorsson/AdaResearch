from pathlib import Path
import re,json,hashlib,shutil,difflib,html
R=Path(__file__).resolve().parents[4];H=Path(__file__).resolve().parent
read=lambda p:p.read_text(encoding='utf-8-sig')
load=lambda p:json.loads(read(p))
checks=[]
def check(name,ok):
 checks.append({'name':name,'passed':bool(ok)})
 if not ok:raise AssertionError(name)
a=load(H/'before/commons/maps/Noise_6_Wall/map_data.json');b=load(R/'commons/maps/Noise_6_Wall/map_data.json')
a['layers']['interactables'][2][9]='';a['layers']['interactables'][4][6]='shader_noise_space#stand:panel'
check('only the two intended placement cells changed',a==b)
check('three placements retained',sum(bool(x.strip()) for row in b['layers']['interactables'] for x in row)==3)
for name in ['noiseroom.gd','noiseroom.tscn','WallNoiseShader.gdshader','QueerNoiseShader.gdshader']:
 rel=Path('algorithms/randomness/shadernoisespace')/name
 check('implementation unchanged: '+name,(H/'before'/rel).read_bytes()==(R/rel).read_bytes())
for rel in ['commons/maps/sequences/noise.json','commons/maps/Noise_6_Wall/critical.md']:
 check('preserved '+rel,(H/'before'/rel).read_bytes()==(R/rel).read_bytes())
check('no new artifact role override',(not (R/'commons/maps/Noise_6_Wall/artifact_roles.json').exists()))
core=load(R/'commons/data/museum_core_encounters.json');oldcore=load(H/'before/commons/data/museum_core_encounters.json')
strip=lambda d:{k:v for k,v in d.items() if k not in ['text_sha256','map_sha256','local_review']}
check('primary selection and all other target metadata retained',strip(core['rooms']['Noise_6_Wall'])==strip(oldcore['rooms']['Noise_6_Wall']))
for key,name in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
 check('current hash '+name,core['rooms']['Noise_6_Wall'][key]==hashlib.sha256((R/'commons/maps/Noise_6_Wall'/name).read_bytes()).hexdigest())
old=read(H/'before/commons/maps/Noise_6_Wall/final.md');new=read(R/'commons/maps/Noise_6_Wall/final.md')
check('all code excerpts retained',re.findall(r'```.*?```',old,re.S)==re.findall(r'```.*?```',new,re.S))
check('encounter anchors and order retained',re.findall(r'<!-- @.*?-->',old)==re.findall(r'<!-- @.*?-->',new))
check('original opening retained',old.split('Keep that question')[0]==new.split('Keep that question')[0])
check('critical seam, orb and closing retained',old[old.index('Each wall piece starts'):]==new[new.index('Each wall piece starts'):])
check('all other original paragraphs retained',all(p in new for i,p in enumerate(old.split('\n\n')) if not p.startswith(('Keep that question','Press DRESS, then enter','Take this knowledge inside'))))
check('current notes keep dark orb supporting','second primary' not in read(R/'commons/maps/Noise_6_Wall/artifacts.md') and 'supporting' in read(R/'commons/maps/Noise_6_Wall/summary.md'))
for part in ['museum-runtime.json','before-view/museum-runtime.json']:
 d=load(H/part);check('passing native run '+part,d['passed'] and not d['failures'])
runtime=load(H/'museum-runtime.json')
check('37 focused native assertions',len(runtime['checks'])==37 and all(x['passed'] for x in runtime['checks']))
for row in runtime['walks']:check('real body route: '+row['tag'],row['passed'])
for row in runtime['rays']:check('floor ray: '+row['tag'],row['passed'])
check('12 synthetic mouse clicks through actual museum pointer',len(runtime['desktop_input'])==12 and all(r['emissions']==1 and r['hover_matches'] and r['clear_to_button'] for r in runtime['desktop_input']))
check('no script or shader compile errors',not re.search('SCRIPT ERROR|SHADER ERROR|String formatting error|Failed to load script',read(H/'museum-process.log')))
check('published image is byte-identical to native capture',(R/'doc/book/figures/Noise_6_Wall/inside-controls.png').read_bytes()==(H/'inside.png').read_bytes())
manifest=[];patch=[]
for p in sorted((H/'before').rglob('*')):
 if not p.is_file():continue
 rel=p.relative_to(H/'before');after=H/'after'/rel;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(R/rel,after)
 manifest.append({'path':rel.as_posix(),'before_sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'after_sha256':hashlib.sha256(after.read_bytes()).hexdigest()})
 aa=read(p);bb=read(after)
 if rel.as_posix()=='commons/data/museum_core_encounters.json':aa=json.dumps(load(p)['rooms']['Noise_6_Wall'],ensure_ascii=False,indent=2)+'\n';bb=json.dumps(load(after)['rooms']['Noise_6_Wall'],ensure_ascii=False,indent=2)+'\n'
 if aa!=bb:patch.extend(difflib.unified_diff(aa.splitlines(True),bb.splitlines(True),fromfile='before/'+rel.as_posix(),tofile='after/'+rel.as_posix()))
(H/'source-manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
(H/'changes.diff').write_text(''.join(patch),encoding='utf-8')
css='body{margin:30px;background:#f5f1e9;color:#25332f;font:17px/1.6 system-ui}table.diff{width:100%;font:13px/1.5 ui-monospace}td{vertical-align:top;white-space:pre-wrap!important;overflow-wrap:anywhere}.diff_add{background:#d4f0d4}.diff_sub{background:#f7d6da}.diff_chg{background:#ffe7aa}.diff_header{background:#e4e4dc}'
diff=difflib.HtmlDiff(wrapcolumn=64).make_table(old.splitlines(),new.splitlines(),'Before: leave the enclosure to change it','Now: stay inside',context=True,numlines=3)
(H/'text-diff.html').write_text('<!doctype html><meta charset="utf-8"><title>Noise 6 Wall — text comparison</title><style>'+css+'</style><p><a href="index.html">Back to review</a></p><h1>Stay inside while the room changes</h1>'+diff,encoding='utf-8')
(H/'text.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/final.md',tofile='after/final.md')),encoding='utf-8')
(H/'verification.json').write_text(json.dumps({'passed':True,'checks':checks,'engine_warnings':[l for l in read(H/'museum-process.log').splitlines() if 'WARNING' in l or 'ERROR' in l],'other_core_records_changed_concurrently':[k for k,v in oldcore['rooms'].items() if k!='Noise_6_Wall' and core['rooms'].get(k)!=v],'scope':runtime['scope']},indent=2)+'\n',encoding='utf-8')
print(len(checks),'preservation/publication checks passed')
