from pathlib import Path
import ast,difflib,hashlib,html,json,re
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
MAPS=['Vectors_Act3_FieldsAndMotion']
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
 core['rooms'][m]['local_review']='doc/book/iterations/2026-09-24-field-and-receiver/index.html#reading-'+m
for m,record in core_before['rooms'].items():
 if m not in MAPS:assert core['rooms'][m]==record
corepath.write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
notes={MAPS[0]:'The same centre becomes somewhere to approach and somewhere to cross. Follow the two bodies before uncovering how one replaces velocity and the other carries it into the next step.'}
labels={MAPS[0]:'The arrow does not decide'}
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
 companion=companion.replace(f'../../../doc/book/iterations/2026-09-24-field-and-receiver/before/commons/maps/{m}/final.md',m+'.before.md').replace('[chapter](final.md)',f'[chapter]({m}.after.md)')
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
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Fields and Motion — the arrow does not decide</title><style>'''+css+'''</style></head><body><main><header class="hero"><p class="eyebrow">Ada Research · Forces · 24 September 2026</p><h1>One field.<br>Two ways to move.</h1><p class="intro">Cyan approaches the centre. Pink crosses it. The field is shared; what each body can carry into the next moment differs.</p></header><p class="status">Applied to <strong>Vectors_Act3_FieldsAndMotion/final.md</strong>. The existing encounter carries the chapter. Its three update equations remain, with operating details in the tutorial companion.</p><nav><a href="#reading">Read the chapter</a><a href="#Vectors_Act3_FieldsAndMotion">Compare the versions</a><a href="#chamber">See the existing encounter</a><a href="DECISIONS.md">Decisions and scope</a><a href="capture/forces-book.md">Current Forces capture</a></nav><div id="reading"></div>'''+''.join(sections)+'''<section id="chamber"><header class="chapter"><p class="eyebrow">Existing native view</p><h2>The crossing is visible</h2></header><figure style="margin:24px 0"><a href="images/field_receivers_inside.png"><img style="width:100%;height:auto;display:block" loading="lazy" src="images/field_receivers_inside.png" alt="Native field chamber paused at four model seconds: cyan approaches the centre while pink's trail extends beyond it on the wall plan"><figcaption>At four model seconds in SINK, cyan is still short of the centre and pink has crossed it. The crossing is visible in the trace. Return travel over the same line requires another way of reading time.</figcaption></a></figure><p class="note">Earlier native capture from the existing chamber documentation, visually inspected and reused unchanged. This is a reference view with the rule revealed, not a new runtime test or a visual change made in this writing pass.</p></section><footer><p>The primary encounter, supporting works, maps, roles, source and sequence order are preserved. The other twelve Forces chapters are unchanged.</p><p>Next: Kinetic Forces — air, water and honey, then a return that does not undo the journey.</p></footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'word-counts.json').write_text(json.dumps(counts,indent=2)+'\n',encoding='utf-8')
(OUT/'preserved.json').write_text(json.dumps(protected,indent=2)+'\n',encoding='utf-8')
(OUT/'capture').mkdir(exist_ok=True)
for item in (ROOT/'doc/book/captures/forces').glob('forces-book.*'):(OUT/'capture'/item.name).write_bytes(item.read_bytes())
print(json.dumps({'chapters':counts,'protected_inputs_unchanged':len(protected),'encounter_anchors':'same tokens and order','core_updates':'one text hash and one local review link'},indent=2))
