from pathlib import Path
import json, shutil, html
ROOT=Path(__file__).resolve().parents[4];HERE=Path(__file__).parent
sections=[
('Point_One','01 · Point One','The second point can be crossed. The third adds a collider. Both small podiums are gone; the large final pedestal remains.',['visible','solid']),
('Point_Lines','02 · Point Lines','Twelve small pairing points → black measurement monolith → ten tape barriers → ×/+ passage → remaining line studies.',['pairing-points','measurement-monolith','queue','consequence-passage','line-gallery']),
('Point_Triangle_Context','03 · Triangle','Twelve small triangular pieces on an accessible table. Lift and turn them into a pyramid or an open form. They stay where released; this is an assembly model.',['triangle-table','triangle-pyramid']),
('Primitives_Polythedra','04 · First solids','Align the tetrahedron, then the wedge. Each completed solid falls and becomes grabbable. A larger tetrahedron changes a corner; equal wedges lead up to one platform. Descend towards a floored basin. The rock box is in a side room. No cube exhibit.',['tetrahedron-unfinished','tetrahedron-complete','wedge-unfinished','wedge-complete','corner-tetrahedron','wedge-palace','basin-and-rock-room'])]
reports=[];parts=[]
for name,title,description,shots in sections:
 run=ROOT/f'ada_run/encounter_pilot/{name}/primitives-v3'
 report=json.loads((run/'report.json').read_text(encoding='utf-8'))
 assert report['passed'],(name,report['failures'])
 report['scope']='Installed Godot museum; supplied desktop/XR-driver interactions and physics checks. No human headset acceptance claim.'
 dest=HERE/'native'/name;dest.mkdir(parents=True,exist_ok=True)
 (dest/'report.json').write_text(json.dumps(report,indent=2),encoding='utf-8')
 shutil.copy2(run/'source_manifest.json',dest/'source_manifest.json')
 reports.append(report)
 figures=[]
 for shot in shots:
  src=run/f'{shot}.png'
  if name=='Point_Lines' and shot=='line-gallery':src=ROOT/f'ada_run/encounter_pilot/{name}/primitives-floor/{shot}.png'
  shutil.copy2(src,dest/src.name)
  caption=shot.replace('-',' ').capitalize()
  if shot=='triangle-pyramid':caption+=' · supplied test placement; not a visitor observation'
  figures.append(f'<figure><a href="native/{name}/{src.name}"><img loading="lazy" src="native/{name}/{src.name}" alt="{caption}"></a><figcaption>{caption}</figcaption></figure>')
 parts.append(f'<section id="{name}"><p class="eyebrow">{html.escape(title)}</p><h2>{html.escape(description.split(".")[0])}</h2><p>{html.escape(description)}</p><p class="links"><a href="/long-museum/writing-wall?map={name}">Writing wall</a> · <a href="/book?map={name}&section=final">Current text</a> · <a href="native/{name}/report.json">{len(report["checks"])} passing checks</a></p><div class="images">'+''.join(figures)+'</div></section>')
floor=ROOT/'ada_run/encounter_pilot/Point_Lines/primitives-floor/report.json'
extra=json.loads(floor.read_text(encoding='utf-8'));assert extra['passed'];reports.append(extra)
shutil.copy2(floor,HERE/'native/Point_Lines/floor-report.json')
total=sum(len(r['checks']) for r in reports)
(HERE/'verification.json').write_text(json.dumps({'passed':True,'checks':total,'rooms':[{'map':r['room'],'checks':len(r['checks'])} for r in reports],'limits':['Supplied interactions; no wearer comfort or learner discovery trial.','Grid pathfinder: all four maps pass, with legacy edge-teleport warnings and the deliberately enclosed rock-spawner warning.','Sequence-wide verifier: 14 pre-existing missing title fields; not a clean whole-sequence audit.','Point One existing exit-support fallback warning remains.'],'plan_scope':'Only Point_Lines, Point_Triangle_Context and Primitives_Polythedra plan rows changed; all other rows and plan sections equal the pre-edit snapshot.'},indent=2),encoding='utf-8')
page='''<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Primitive encounters · Ada Research</title><style>
*{box-sizing:border-box}body{margin:0;background:#f4f0e9;color:#27212d;font:18px/1.6 system-ui,sans-serif}main{max-width:1440px;margin:auto;padding:48px 5vw}header{max-width:870px;padding:20px 0 40px}h1{font:clamp(38px,5vw,70px)/1.07 Georgia,serif;margin:12px 0 24px}h2{font:32px/1.25 Georgia,serif;max-width:1000px}a{color:#63375b;text-underline-offset:4px}.eyebrow{font-size:13px;letter-spacing:.13em;text-transform:uppercase;color:#80526d}nav{display:flex;gap:12px;flex-wrap:wrap}nav a{padding:8px 13px;border:1px solid #c6b5bd;border-radius:4px}.status{padding:18px 24px;border-left:4px solid #80526d;background:#e9e2e8;max-width:950px}section{border-top:1px solid #c6b5bd;padding:35px 0 50px;margin-top:30px}section>p{max-width:900px}.images{display:grid;grid-template-columns:repeat(2,minmax(0,1fr));gap:22px}figure{margin:0}img{display:block;width:100%;height:auto;border:1px solid #bdb2bd}figcaption{font-size:14px;padding:7px 0}.links{font-size:15px}footer{max-width:950px;margin-top:30px;font-size:16px}@media(max-width:760px){main{padding:24px}.images{grid-template-columns:1fr}}
</style></head><body><main><header><p class="eyebrow">Ada Research · 17 October 2026 · installed museum trial</p><h1>Let the primitive change what a body can do.</h1><p>Four maps revised from Palle’s walking notes. An action begins each comparison; the next object changes its conditions.</p><nav>'''
page+=''.join(f'<a href="#{n}">{t}</a>' for n,t,_,_ in sections)
page+=f'</nav></header><p class="status">{total} supplied runtime checks pass, including grab/release, completion and gravity, the queue’s blocked shortcut, the full zigzag, both platform approaches and its descent. Images below are native Godot captures. Headset comfort and visitor understanding remain to be tested.</p>'
page+=''.join(parts)
page+='''<footer><h2>A method to keep testing</h2><p>Start with an action. Change one consequential condition. Remove supports that hide the difference. Let the geometry alter a hand’s or a walking body’s possibilities. Give the consequence room before introducing the next encounter. Offer pieces with which another construction can be tried.</p><p>The result need not be the same layout each time: a pass-through comparison, an open field of connections, a prescribed route, a table for assembly, or a slope that supports a body.</p><p>Desktop: right-click to pick up and release. For the new triangle pieces, Q/E rolls and R/F tilts while held. VR uses the existing grab gesture. Re-enter the solids hall to begin a fresh alignment trial.</p><p>Known wider-project checks: the sequence validator still reports 14 existing missing title fields. Grid checks retain legacy edge-teleport warnings, and Point One retains an existing exit-support fallback warning. These are recorded separately from the passing encounter tests.</p><p><a href="verification.json">Verification receipt</a> · <a href="notes.md">Task plan and improvement principle</a></p></footer></main></body></html>'''
(HERE/'index.html').write_text(page,encoding='utf-8')
print(f'Published review with {total} passing checks.')
