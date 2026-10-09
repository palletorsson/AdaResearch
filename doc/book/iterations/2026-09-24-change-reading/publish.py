from pathlib import Path
import difflib,hashlib,html,json,re
import markdown
OUT=Path(__file__).resolve().parent
ROOT=OUT.parents[3]
MAPS=['Change_Intro','Flow_Field']
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
base=json.loads((OUT/'baseline.json').read_text(encoding='utf-8'))
changed={f'commons/maps/{m}/{name}' for m in MAPS for name in ['final.md','intent.md','tutorial.md','walked.md']}
protected={p:h for p,h in base.items() if p not in changed and p not in ['commons/data/museum_core_encounters.json','doc/book/iterations/WORKING.md'] and not p.startswith('doc/book/captures/')}
for p,h in protected.items():assert sha(ROOT/p)==h,'Protected input changed: '+p
corepath=ROOT/'commons/data/museum_core_encounters.json'
core=json.loads(corepath.read_text(encoding='utf-8-sig'))
oldcore=json.loads((OUT/'before/commons/data/museum_core_encounters.json').read_text(encoding='utf-8-sig'))
for m in MAPS:
 current={k:v for k,v in core['rooms'][m].items() if k not in ['text_sha256','local_review']}
 previous={k:v for k,v in oldcore['rooms'][m].items() if k not in ['text_sha256','local_review']}
 assert current==previous, 'Concurrent record edit: '+m
 core['rooms'][m]['text_sha256']=sha(ROOT/f'commons/maps/{m}/final.md')
 core['rooms'][m]['local_review']='doc/book/iterations/2026-09-24-change-reading/index.html#reading-'+m
corepath.write_text(json.dumps(core,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
notes={'Change_Intro':'A falling line and a rising curve begin the investigation. The same curve then supplies rectangles; a new arch lets rises and falls cancel. The mathematical distinctions stay, while settings and display bookkeeping move beside the reading.','Flow_Field':'Follow one particle before naming the rule. The held field, changing field and returning edge become three successive encounters. The ending stays with neighbours that never have to make room for one another.'}
labels={'Change_Intro':'Change and accumulation','Flow_Field':'A path made by its next step'}
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
 companion=companion.replace(f'../../../doc/book/iterations/2026-09-24-change-reading/before/commons/maps/{m}/final.md',m+'.before.md')
 (OUT/(m+'.notes.md')).write_text(companion,encoding='utf-8')
 for suffix,text in [('before',before),('after',after)]:(OUT/(m+'.'+suffix+'.md')).write_text(text,encoding='utf-8')
 sections.append(f'''<section id="{m}"><header class="chapter"><p class="eyebrow">{m.replace('_',' ')}</p><h2>{labels[m]}</h2><p>{notes[m]}</p><nav><a href="#reading-{m}">Read the revision</a><a href="/compose/sources?map={m}&amp;doc=final">Read and comment</a><a href="{m}.diff">Exact diff</a><a href="{m}.notes.md">Companion details</a></nav></header><details><summary>Original and revision, side by side</summary><p class="note">{count['before_words']:,} → {count['after_words']:,} words, including code. This is a frozen comparison; the comment link opens the live manuscript.</p><div class="comparison"><article><h3>Before</h3>{render(before,m+'-before')}</article><article><h3>Revised</h3>{render(after,m+'-after')}</article></div></details><article class="reading" id="reading-{m}">{render(after,m+'-reading')}</article></section>''')
for rel in sorted(changed):
 before=(OUT/'before'/rel).read_text(encoding='utf-8-sig');after=(ROOT/rel).read_text(encoding='utf-8-sig')
 dest=OUT/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes((ROOT/rel).read_bytes())
 diff=''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+rel,tofile=rel))
 dest=OUT/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(diff,encoding='utf-8')
 if rel.endswith('/final.md'):(OUT/(Path(rel).parent.name+'.diff')).write_text(diff,encoding='utf-8')
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f4f0e8;color:#292c30;font:17px/1.65 system-ui,sans-serif}main{max-width:1240px;margin:auto;padding:54px 32px 90px}a{color:#00666d;text-underline-offset:3px}nav{display:flex;gap:12px 22px;flex-wrap:wrap;font-size:14px;margin:22px 0}h1,h2,h3{line-height:1.15}header.hero{max-width:790px}header.hero h1{font:clamp(42px,6vw,76px)/1.06 Georgia,serif;letter-spacing:-.035em;margin:20px 0}.intro{font-size:21px;line-height:1.65}.eyebrow{font-size:12px;text-transform:uppercase;letter-spacing:.14em;color:#626d70}.status{border-left:3px solid #9b4a42;padding-left:16px;max-width:870px}.chapter{max-width:820px}.chapter h2{font:34px/1.2 Georgia,serif}section{border-top:1px solid #cfc8bd;margin-top:48px;padding-top:24px}details{background:#ebe7df;border:1px solid #d0cabe;border-radius:9px;padding:18px 22px;margin:26px 0}summary{cursor:pointer;font-weight:600}.comparison{display:grid;grid-template-columns:1fr 1fr;gap:34px;align-items:start}.comparison article{min-width:0;font:17px/1.7 Georgia,serif}.comparison h3{font:13px system-ui,sans-serif;text-transform:uppercase;letter-spacing:.1em;color:#526568}.reading{max-width:720px;margin:56px auto 74px;font:21px/1.78 Georgia,serif;scroll-margin-top:30px}.reading h1{font-size:38px;line-height:1.15;margin-bottom:35px}.reading h2{font-size:29px;margin-top:2.3em;line-height:1.25}.reading p{margin:1.15em 0}code{font-size:.82em}pre{background:#e7ebe7;border-left:3px solid #3b7d77;padding:18px;overflow:auto;line-height:1.55;font:14px/1.6 Consolas,monospace;tab-size:4}pre code{font-size:inherit}.note,figcaption{font-size:14px;color:#606a70}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.pair figure{margin:0}.pair img{display:block;width:100%;border-radius:6px}.pair figcaption{margin-top:10px}footer{max-width:790px;margin-top:50px}blockquote{border-left:2px solid #a45a52;padding-left:22px;margin-left:0}@media(max-width:800px){main{padding:28px 18px 60px}.comparison,.pair{grid-template-columns:1fr}.reading{font-size:19px}.reading h1{font-size:33px}.chapter h2{font-size:29px}details{padding:14px}.intro{font-size:19px}}'''
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Change — the curve keeps going</title><style>'''+css+'''</style></head><body><main><header class="hero"><p class="eyebrow">Ada Research · Change · 24 September 2026</p><h1>The curve<br>keeps going.</h1><p class="intro">The line between two samples falls. The curve is rising at the first. Begin with what the two readings let us notice, and give the explanation time to arrive.</p></header><p class="status">Applied to both canonical <strong>final.md</strong> files. Existing encounters and their order remain. Detailed controls and numerical qualifications are retained in the tutorial companions.</p><nav><a href="#reading">Read both chapters</a><a href="#Change_Intro">Compare Change</a><a href="#Flow_Field">Compare Flow</a><a href="DECISIONS.md">Decisions and scope</a><a href="capture/change-book.md">Current sequence capture</a></nav><div id="reading"></div>'''+''.join(sections)+'''<section><header class="chapter"><p class="eyebrow">Existing encounter · dated visual reference</p><h2>The arch before and after the comparison</h2></header><div class="pair"><figure><a href="../2026-09-19-change-review/bridge/museum/museum-predict.png"><img loading="lazy" src="../2026-09-19-change-review/bridge/museum/museum-predict.png" alt="Godot museum bridge with the arch and signed strips before revealing the totals"><figcaption>The arch and signed strips, before requesting totals.</figcaption></a></figure><figure><a href="../2026-09-19-change-review/bridge/museum/museum-compared.png"><img loading="lazy" src="../2026-09-19-change-review/bridge/museum/museum-compared.png" alt="The same bridge after revealing the endpoint difference and numerical comparison"><figcaption>The same encounter with its comparison revealed.</figcaption></a></figure></div><p class="note">Native museum captures from 19 September, reused as context. These are two states of the existing artifact, not visual changes made in this reading pass.</p></section><footer><p>This pass changes writing and its publication records. No scene, source, placement or sequence order changed. Prior desktop evidence remains prior evidence; no new runtime or headset check is claimed.</p><p>Next: a selective Forces reading pass, beginning with the vector rooms and preserving their strongest bodily consequences.</p></footer></main></body></html>'''
(OUT/'index.html').write_text(page,encoding='utf-8')
(OUT/'word-counts.json').write_text(json.dumps(counts,indent=2)+'\n',encoding='utf-8')
(OUT/'preserved.json').write_text(json.dumps(protected,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'chapters':counts,'protected_inputs_unchanged':len(protected),'encounter_anchors':'same tokens and order','core_updates':'two text hashes and two local review links'},indent=2))

(OUT/'capture').mkdir(exist_ok=True)
for item in (ROOT/'doc/book/captures/change').glob('change-book.*'):(OUT/'capture'/item.name).write_bytes(item.read_bytes())
