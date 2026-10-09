from pathlib import Path
import ast,difflib,hashlib,html,json,re
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
MAPS=['VFM_05_Launch','VFM_03_Motion']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=json.loads((OUT/'baseline.json').read_text(encoding='utf-8'))
changed=set(json.loads((OUT/'changed-files.json').read_text(encoding='utf-8')))
protected={p:h for p,h in base.items() if p not in changed and p not in ['commons/data/museum_core_encounters.json','doc/book/iterations/WORKING.md'] and not p.startswith('doc/book/captures/')}
for p,h in protected.items():assert sha(ROOT/p)==h,'Protected input changed: '+p
corepath=ROOT/'commons/data/museum_core_encounters.json'
core=json.loads(corepath.read_text(encoding='utf-8-sig'))
oldcore=json.loads((OUT/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
core_before=json.loads(json.dumps(core))
for m in MAPS:
 current={k:v for k,v in core['rooms'][m].items() if k not in ['text_sha256','local_review']}
 previous={k:v for k,v in oldcore['rooms'][m].items() if k not in ['text_sha256','local_review']}
 assert current==previous,'Concurrent record edit: '+m
 core['rooms'][m]['text_sha256']=sha(ROOT/f'commons/maps/{m}/final.md')
 core['rooms'][m]['local_review']='doc/book/iterations/2026-09-24-launch-and-motion/index.html#reading-'+m
for m,record in core_before['rooms'].items():
 if m not in MAPS:assert core['rooms'][m]==record
corepath.write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
notes={
 MAPS[0]:'Equal range leaves two different uses of space and time. Keep the encounter between the two flights and let the equation arrive after the body has found its place in the diagram.',
 MAPS[1]:'The push ends while the cube keeps moving. Follow the state it carries, the boundary that recognises it, and the smaller ramp whose rule can cut a movement short.'}
labels={MAPS[0]:'Stand inside the curve',MAPS[1]:'When the push ends'}
def render(s,prefix):
 s=re.sub(r'<!--\s*@([^>]*?)\s*-->',lambda m:('<span id="'+prefix+'-encounter-'+html.escape(m[1].strip(),quote=True)+'"></span>') if m[1].strip() else '',s)
 s=re.sub(r'~~([^~\n]+)~~',r'<del>\1</del>',s)
 result=markdown.markdown(s,extensions=['extra','sane_lists'])
 return result.replace('id="fn','id="'+prefix+'-fn').replace('href="#fn','href="#'+prefix+'-fn')
counts=[];sections=[]
for m in MAPS:
 rel=f'commons/maps/{m}/final.md'
 before=(OUT/'before'/rel).read_text(encoding='utf-8-sig');after=(ROOT/rel).read_text(encoding='utf-8-sig')
 anchors=lambda s:re.findall(r'<!--\s*@([^>]*?)\s*-->',s)
 assert anchors(before)==anchors(after),'Encounter routing changed: '+m
 assert [x.strip() for x in anchors(after) if x.strip()]==core['rooms'][m]['primary_tokens']
 count={'map':m,'before_words':len(before.split()),'after_words':len(after.split())};counts.append(count)
 companion=(ROOT/f'commons/maps/{m}/tutorial.md').read_text(encoding='utf-8-sig')
 companion=companion.replace(f'../../../doc/book/iterations/2026-09-24-launch-and-motion/before/commons/maps/{m}/final.md',m+'.before.md').replace('[chapter](final.md)',f'[chapter]({m}.after.md)')
 (OUT/(m+'.notes.md')).write_text(companion,encoding='utf-8')
 for suffix,text in [('before',before),('after',after)]:(OUT/(m+'.'+suffix+'.md')).write_text(text,encoding='utf-8')
 sections.append(f'''<section id="{m}"><header class="chapter"><p class="eyebrow">{m.replace('_',' ')}</p><h2>{labels[m]}</h2><p>{notes[m]}</p><nav><a href="#reading-{m}">Read the revision</a><a href="/compose/sources?map={m}&amp;doc=final">Read and comment</a><a href="{m}.diff">Exact diff</a><a href="{m}.notes.md">Companion details</a></nav></header><details><summary>Original and revision, side by side</summary><p class="note">{count['before_words']:,} → {count['after_words']:,} words, including code. Frozen comparison; the comment link opens the live manuscript.</p><div class="comparison"><article><h3>Before</h3>{render(before,m+'-before')}</article><article><h3>Revised</h3>{render(after,m+'-after')}</article></div></details><article class="reading" id="reading-{m}">{render(after,m+'-reading')}</article></section>''')
for rel in sorted(changed):
 before=(OUT/'before'/rel).read_text(encoding='utf-8-sig');after=(ROOT/rel).read_text(encoding='utf-8-sig')
 dest=OUT/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes((ROOT/rel).read_bytes())
 diff=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+rel,tofile=rel))
 dest=OUT/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(diff,encoding='utf-8')
 if rel.endswith('/final.md'):(OUT/(Path(rel).parent.name+'.diff')).write_text(diff,encoding='utf-8')
prior=ast.parse((OUT.parent/'2026-09-24-change-reading/publish.py').read_text(encoding='utf-8-sig'))
css=next(ast.literal_eval(n.value) for n in prior.body if isinstance(n,ast.Assign) and any(isinstance(t,ast.Name) and t.id=='css' for t in n.targets))
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Launch and Motion — after the first instruction</title><style>'''+css+'''</style></head><body><main><header class="hero"><p class="eyebrow">Ada Research · Forces · 24 September 2026</p><h1>After the first<br>instruction.</h1><p class="intro">One flight is down while the other is still in the air. The push has ended while the cube is still crossing the room. What continues after the beginning?</p></header><p class="status">Applied to <strong>VFM_05_Launch/final.md</strong> and <strong>VFM_03_Motion/final.md</strong>. These encounters already carry their questions; the revision gives them space and keeps detailed operating notes alongside the reading.</p><nav><a href="#reading">Read both chapters</a><a href="#VFM_05_Launch">Compare Launch</a><a href="#VFM_03_Motion">Compare Motion</a><a href="#chambers">See the existing chambers</a><a href="DECISIONS.md">Decisions and scope</a><a href="capture/forces-book.md">Current Forces capture</a></nav><div id="reading"></div>'''+''.join(sections)+'''<section id="chambers"><header class="chapter"><p class="eyebrow">Existing native views</p><h2>The diagram and the body</h2></header><div class="pair"><figure><a href="images/launch_chamber_inside.png"><img loading="lazy" src="images/launch_chamber_inside.png" alt="Native museum view from inside the launch chamber, with a glowing predicted curve and its component arrows"><figcaption>Launch, with the path, components and rule revealed. The flight is large enough to stand beside.</figcaption></a></figure><figure><a href="images/motion_chamber_inside.png"><img loading="lazy" src="images/motion_chamber_inside.png" alt="Native museum view of the motion cube inside its amber perimeter, displaying velocity, acceleration and requested force"><figcaption>Motion during a push, with velocity, acceleration and requested force visible. This image precedes the coasting comparison.</figcaption></a></figure></div><p class="note">Earlier native captures, reused unchanged from the existing chamber documentation. These show two different encounters, not visual changes made in this writing pass.</p></section><footer><p>All three primary encounters retain their order. Maps, artifact source, roles and the other eleven Forces chapters are preserved. No new runtime or headset test is claimed.</p><p>Next: Fields and Motion, where the next influence depends on where the body arrives.</p></footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'word-counts.json').write_text(json.dumps(counts,indent=2)+'\n',encoding='utf-8')
(OUT/'preserved.json').write_text(json.dumps(protected,indent=2)+'\n',encoding='utf-8')
(OUT/'capture').mkdir(exist_ok=True)
for item in (ROOT/'doc/book/captures/forces').glob('forces-book.*'):(OUT/'capture'/item.name).write_bytes(item.read_bytes())
print(json.dumps({'chapters':counts,'protected_inputs_unchanged':len(protected),'encounter_anchors':'same tokens and order','core_updates':'two text hashes and two local review links'},indent=2))
