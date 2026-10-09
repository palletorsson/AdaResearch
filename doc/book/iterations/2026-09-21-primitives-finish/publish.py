from pathlib import Path
import json,re,hashlib,html
import markdown
H=Path(__file__).resolve().parent;R=H.parents[3]
MAPS=['Point_Line_Grid','Point_Triangle_Context','Primitives_Polythedra','Point_Animatedcube','Primitives_Ignorance','Trans_Pre']
LABELS=['Grid','Triangle','Polyhedra','Animated Cube','Ignorance','Into Transformation']
NOTES=[
'The glass plan equips two spatial pens in VR. Cyan samples the gesture; amber takes its horizontal addresses from this floor and preserves height. Time-domain drawing stays available for later placements.',
'The L and its spill arrive sooner. The first-vertex fan, the consequence of SHIFT START and the possibility of another use stay in the chapter; the full coordinate recipe and manual alternative move to the technical companion.',
'A generic promise of another visit gives way to a question about the barrier, the slope and whose movement you would change.',
'The crease carries the reader onward. The catalogue of other objects is removed from the closing paragraph; the objects remain in the room.',
'The final question keeps its space. One repeated deferral paragraph is removed; the sphere comparison and five-sided capsule stay.',
'Melencolia asks what survives a transformation. The opening now carries that question into the existing cube: still, moving, turning, then changing size. The rest of its chapter is preserved.'
]
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def render(s,prefix):
 s=re.sub(r'<!--\s*@[^>]*-->', '', s)
 out=markdown.markdown(s,extensions=['fenced_code','footnotes','tables'])
 out=re.sub(r'id="([^"]+)"',lambda m:'id="'+prefix+m[1]+'"',out)
 return re.sub(r'href="#([^"]+)"',lambda m:'href="#'+prefix+m[1]+'"',out)
checks=[]
def check(name,ok):
 checks.append({'check':name,'passed':bool(ok)})
 assert ok,name
concurrent=read(H/'concurrent-changes.json')
for name,digest in read(H/'preserved.json').items():
 if name in concurrent:check('Recorded concurrent change (not reverted): '+name,sha(R/name)==concurrent[name]['observed_sha256'])
 else:check('Preserved '+name,sha(R/name)==digest)
core=read(R/'commons/data/museum_core_encounters.json');oldcore=read(H/'before/commons/data/museum_core_encounters.json');roles=read(R/'commons/data/artifact_roles.json')
check('Other core records unchanged',{k:v for k,v in core['rooms'].items() if k not in MAPS}=={k:v for k,v in oldcore['rooms'].items() if k not in MAPS} and core['_meta']==oldcore['_meta'])
oldmap=read(H/'before/commons/maps/Point_Line_Grid/map_data.json');newmap=read(R/'commons/maps/Point_Line_Grid/map_data.json')
oldmap['layers']['interactables'][7][15]='plan_vitrine:0:0#pen_pair:space_grid'
check('Only one Grid placement option changed',oldmap==newmap)
parts=[];counts=[]
for m,label,note in zip(MAPS,LABELS,NOTES):
 path=Path('commons/maps')/m/'final.md';old=(H/'before'/path).read_text(encoding='utf-8');now=(R/path).read_text(encoding='utf-8')
 oldnotes=[line for line in old.splitlines() if line.startswith('[^')]
 check(m+' existing footnotes preserved',all(line in now.splitlines() for line in oldnotes))
 expected=[];order=roles['order'][m]
 for token in order['primary']:expected.extend(order['primary|'+token[1:]] if token.startswith('@') else [token])
 expected=[token for token in expected if not token.startswith('#')]
 check(m+' markers, authored roles and derived primary order agree',re.findall(r'<!-- @([A-Za-z_0-9]+) -->',now)==expected==core['rooms'][m]['primary_tokens'])
 for key,file in [('text_sha256','final.md'),('map_sha256','map_data.json')]:check(m+' '+key,core['rooms'][m][key]==sha(R/path.parent/file))
 check(m+' status preserved',core['rooms'][m]['status']==oldcore['rooms'][m]['status'] and not core['rooms'][m]['learner_verified'])
 counts.append({'map':m,'before_words':len(old.split()),'after_words':len(now.split())})
 diff=path.as_posix().replace('/','__')+'.diff'
 parts.append('<section id="'+m+'"><div class="eyebrow">'+label+'</div><h2>'+html.escape(note.split('. ')[0])+'.</h2><p>'+html.escape(note)+'</p><nav><a href="/compose/sources?map='+m+'&amp;doc=final">Read and comment</a><a href="'+diff+'">Exact diff</a><a href="/long-museum/encounters?map='+m+'">Encounter map</a></nav><details><summary>Read the revised chapter</summary><div class="reading">'+render(now,m+'-read-')+'</div></details><details><summary>Compare original and current</summary><div class="compare"><article><h3>Original</h3>'+render(old,m+'-before-')+'</article><article><h3>Current</h3>'+render(now,m+'-after-')+'</article></div></details></section>')
trans=(R/'commons/maps/Trans_Pre/final.md').read_text(encoding='utf-8');oldtrans=(H/'before/commons/maps/Trans_Pre/final.md').read_text(encoding='utf-8')
check('Trans_Pre cube encounters unchanged',trans.split('<!-- @pick_up_cube -->')[1]==oldtrans.split('<!-- @pick_up_cube -->')[1])
results=read(H/'runtime-results.json')
check('Spatial and legacy runtime probes pass',results['default_pair_pass'] and results['grid_pair_pass'] and results['capture_exit_code']==0)
check('Actual Godot image exists',(H/'grid-spatial-pair.png').stat().st_size>10000)
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
(H/'chapter-counts.json').write_text(json.dumps(counts,indent=2)+'\n',encoding='utf-8')
style=(R/'doc/book/iterations/2026-09-21-point-one-return/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
style+=' section{margin:52px 0;border-top:1px solid var(--line);padding-top:25px}summary{cursor:pointer;padding:18px 0;font-weight:600}.reading{max-width:780px;margin:auto}figure{margin:26px 0}figure img{width:100%;border-radius:12px}figcaption{font-size:14px;max-width:850px;line-height:1.6;color:var(--muted)}.compare{align-items:start}article{min-width:0}pre{overflow:auto}section h2{font-size:29px;max-width:950px}blockquote{max-width:900px}'
nav=''.join('<a href="#'+m+'">'+label+'</a>' for m,label in zip(MAPS,LABELS))
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitives — enough to continue</title><style>'+style+'</style></head><body><main><div class="eyebrow">Ada Research · focused finishing pass · 21 September 2026</div><h1>Enough to continue.</h1><p class="intro">One missing encounter in Grid, a clearer discovery in Triangle, and a few lighter endings. The mature Primitives sequence keeps its voice and its objects. Transformation takes up the question it leaves open.</p><nav>'+nav+'<a href="SUMMARY.md">Decisions and evidence</a></nav><figure><img src="grid-spatial-pair.png" alt="Actual Godot glass plan: cyan sampled circle and amber floor-addressed line above the numbered five by five floor"><figcaption>Actual Godot production artifact, 21 September. The same supplied circular motion drives both pens: cyan retains sampled positions; amber rounds the horizontal coordinates to this plan. Both remain at the same height. This isolated observation checks the rendered result and controller code; it is not a headset photograph or a full museum capture.</figcaption></figure><blockquote>The floor has entered the drawing. Its addresses reach up into the air, but they have not taken over every direction.</blockquote><p>All secondary artifacts remain. Point One, Lines and Trace retain the work already settled. Portals and Melencolia are preserved in full; their returns serve the argument about finite work and unfinished looking.</p>'+''.join(parts)+'<section id="next"><div class="eyebrow">Next · Transformation</div><h2>What survives its movement?</h2><p>The existing first cube is still collectible; the following demonstrations add vertical movement, turning and uniform scale. The next hall is Trans_Introduction, where those operations become different ways across a gap. Continue by reading the crossing and the body together.</p><nav><a href="/compose/sources?map=Trans_Pre&amp;doc=final">Read the new opening</a><a href="/compose/sources?map=Trans_Introduction&amp;doc=final">Next hall</a><a href="/book-review/doc/book/iterations/2026-09-21-lines-trace-return/index.html">Earlier Lines and Trace pass</a></nav></section><p class="note">Controlled checks: 20 spatial-pair assertions and 9 legacy-pair checks pass. The rendered run also verifies image capture. Headset feel and ease of comparison remain to be tried. The review snapshot for Claude stays frozen; current chapters are linked above.</p></main></body></html>'
(H/'index.html').write_text(page,encoding='utf-8')
print('Published finishing pass:',len(checks),'preservation/content checks.');print(json.dumps(counts))
