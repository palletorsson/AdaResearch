from pathlib import Path
import html,json,hashlib,difflib,re
ROOT=Path.cwd(); OUT=ROOT/'doc/book/iterations/2026-10-06-transformation-grayscale'
rooms=json.loads((ROOT/'commons/maps/sequences/transformation.json').read_text())['sequences']['transformation']['maps']
copy={
'Trans_Pre':('A body begins to move','Black cubes and pale edges carry the four stages: still, rising, turning, swelling.'),
'Trans_Introduction':('Three ways across','The moving, growing and turning surfaces read through their outline, pose and relation to the bank.'),
'Trans_Translation':('Two permitted journeys','Left and right doors replace red and blue as the names used in the text. The traces and rails remain.'),
'Trans_Rotation':('Follow a face','Axes, the L mark, narrow and wider bodies, and left/right order keep the comparisons readable.'),
'Trans_Scale':('The room grows','The neutral room and fixed reference frame make relative size the visual question.'),
'Trans_Body':('An opening answers you','Dark slats and blocks meet the pale room. Approach and withdrawal still drive their response.'),
'Trans_Pit':('Wait for room','Pushers, turning slabs and growing blocks share the tonal palette. Their timing still governs passage.')}
sections=[];reports=[]
for i,room in enumerate(rooms,1):
 title,description=copy[room]
 d=json.loads((OUT/room/'after/report.json').read_text());assert d['passed'],room;reports.append(d)
 figures=''.join(f'<figure><a href="{room}/{mode}/{mode}.png"><img loading="lazy" src="{room}/{mode}/{mode}.png" alt="{html.escape(title)} — {mode}, captured inside the Endless Museum"></a><figcaption>{mode.capitalize()}</figcaption></figure>' for mode in ('before','after'))
 sections.append(f'<section id="{room}"><div class="heading"><span>{i:02}</span><div><h2>{title}</h2><p>{description}</p></div></div><div class="pair">{figures}</div><p class="links"><a href="/book-review/commons/maps/{room}/final.md">Reflective text</a> · <a href="/book-review/commons/maps/{room}/tutorial.md">Tutorial</a> · <a href="{room}/after/report.json">Native checks</a></p></section>')
changed=[]
for before in (OUT/'before').glob('Trans_*.md'):
 room,name=before.name.split('-',1);target=ROOT/'commons/maps'/room/name
 old=before.read_text(encoding='utf-8');new=target.read_text(encoding='utf-8')
 if old==new:continue
 assert re.findall(r'```[^\n]*\n(.*?)```',old,re.S)==re.findall(r'```[^\n]*\n(.*?)```',new,re.S),target
 diff=''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/'+before.name,tofile=target.relative_to(ROOT).as_posix()))
 (OUT/(before.stem+'.diff')).write_text(diff,encoding='utf-8');changed.append(target.relative_to(ROOT).as_posix())
old=(OUT/'before/endless_museum.gd').read_text(encoding='utf-8');new=(ROOT/'commons/scenes/endless_museum.gd').read_text(encoding='utf-8')
(OUT/'museum-hook.diff').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='before/endless_museum.gd',tofile='commons/scenes/endless_museum.gd')),encoding='utf-8')
checks={'all_seven_halls_passed':all(d['passed'] for d in reports),'printed_code_blocks_unchanged':True,'halls':[{'room':d['room'],'checks':len(d['checks']),'moving_nodes':d['moving_nodes'],'presentation_poll_median_ms':d.get('presentation_poll_median_ms')} for d in reports],'changed_manuscripts':changed,'scope':'Native desktop Compatibility rendering and material assertions. Behavioural regression reports are linked separately. Headset comfort/performance has not been verified.','sources':{}}
for rel in changed+['commons/rendering/museum_grayscale.gd','commons/scenes/endless_museum.gd','tools/probes/transformation_grayscale.gd','doc/book/studies/ada-xr-starter/studies/trans_pre/marked_cube.gd']:
 checks['sources'][rel]=hashlib.sha256((ROOT/rel).read_bytes()).hexdigest()
behaviour=[]
for p in OUT.glob('Trans_*/behaviour/report.json'):
 d=json.loads(p.read_text());assert d['passed'],p
 behaviour.append({'room':d['room'],'passed':d['passed'],'checks':len(d['checks']),'report':p.relative_to(OUT).as_posix()})
checks['interaction_regressions']=behaviour
(OUT/'checks.json').write_text(json.dumps(checks,indent=2),encoding='utf-8')
nav=''.join(f'<a href="#{r}">{i+1:02}</a>' for i,r in enumerate(rooms))
css='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#efeeeb;color:#202020;font:19px/1.65 Georgia,serif}header{padding:20px 5vw;border-bottom:1px solid #bbb;display:flex;justify-content:space-between;gap:20px;font:13px system-ui;position:sticky;top:0;background:#efeeebed;z-index:1}nav{display:flex;gap:18px}a{color:inherit;text-underline-offset:4px}main{max-width:1500px;margin:60px auto;padding:0 4vw}.intro{max-width:790px;margin-bottom:50px}.eyebrow{font:12px system-ui;letter-spacing:.16em}h1{font-weight:400;font-size:clamp(42px,7vw,82px);line-height:1.02;letter-spacing:-.045em;margin:20px 0 28px}.lead{font-size:25px;line-height:1.5}.heading{display:flex;gap:25px;align-items:baseline}.heading>span{font:14px system-ui;color:#777}.heading div{max-width:850px}h2{font-size:32px;font-weight:400;margin:0}section{border-top:1px solid #bbb;padding:40px 0 30px;scroll-margin-top:80px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:18px}figure{margin:0}img{display:block;width:100%;height:auto;background:#111}figcaption,.links{font:13px/1.6 system-ui;margin:9px 0}.links{margin-top:18px}footer{max-width:900px;margin:30px 0 70px;font:14px/1.7 system-ui}details{border:1px solid #bbb;padding:18px;margin-top:30px}summary{cursor:pointer}.hero{width:100%;margin-bottom:55px}@media(max-width:800px){.pair{grid-template-columns:1fr}.heading{gap:15px}main{margin-top:35px}h2{font-size:27px}.lead{font-size:22px}}'''
page='<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Transformation, before colour — Endless Museum</title><style>'+css+'</style></head><body><header><a href="/tutorial-plan?view=sequences&seq=transformation">ADA / ENDLESS MUSEUM</a><nav>'+nav+'</nav></header><main><div class="intro"><div class="eyebrow">6 OCTOBER 2026 · SEVEN HALLS</div><h1>Transformation,<br>before colour.</h1><p class="lead">A cube rises. A face turns away. A gap closes. Black, white and gray let those changes carry the chapter.</p><p>Colour can later arrive as a new way to act on a familiar body. Holding it back here gives that arrival more force.</p><p>The actual museum now applies a grayscale palette to Transformation’s 3D materials. These are native Godot captures, from inside its halls.</p></div><figure class="hero"><img src="Trans_Pre/after/after.png" alt="Dark cubes with pale outlines in the Transformation opening hall"><figcaption>The same family of cubes, with movement as the difference to follow.</figcaption></figure>'+''.join(sections)+'<footer><p>Before and after use matching camera positions in separate live runs. Moving objects can be at different phases; these are palette comparisons, not synchronized animation frames. The existing museum light gives neutral surfaces a cool cast. The shared sky and HUD remain part of the wider museum.</p><details><summary>What changed, and what was checked</summary><p>The palette is attached only to Transformation segments. It creates local material copies, preserves source colour for other sequences, and follows live material updates. The marked cube in the older reduced study also uses neutral gray and charcoal.</p><p>The text now identifies objects by axis, side, width and operation order. Printed code blocks are unchanged. All seven halls passed material isolation and update assertions; live motion was sampled in the five halls with automatic animation. Human headset review remains open.</p><p><a href="checks.json">Check summary and source hashes</a> · <a href="museum-hook.diff">Museum hook diff</a> · <a href="REPORT.md">Implementation notes</a></p></details></footer></main></body></html>'
if behaviour:
 evidence='<ul>'+''.join(f'<li><a href="{d["report"]}">{d["room"]}: {d["checks"]} interaction checks passed</a></li>' for d in behaviour)+'</ul>'
 page=page.replace('</details>',evidence+'</details>')
(OUT/'index.html').write_text(page,encoding='utf-8')
report='''# Transformation, before colour

The seven Transformation halls now use grayscale object materials. Form, edge marks, relative position, light and shadow carry the comparisons. This gives the later Colour sequence more room to change the reader’s attention.

The runtime change belongs to the real Endless Museum. A hall-local presentation component copies materials, neutralizes standard-material colours/textures and spatial-shader albedo/emission, and follows updates from both retained source materials and direct material overrides. Shared coloured resources are not repainted globally. Static architecture is styled once; artifact materials remain live. The module does not write transforms, dimensions, collision shapes, motion rates, progression or input logic.

Seven native before/after views and per-hall assertions are linked in index.html. Copies of changed manuscripts are kept in before/, alongside the prior museum source. The textual edits remove colour-dependent identifications and establish the grayscale intention at the start of Transformation. Executable manuscript blocks are identical. The small marked-cube study changes two RGB constants only.

The report is a desktop rendering and code/state review, not a headset acceptance test. Its material polling cost is measured in each after/report.json; that measurement excludes full rendering and is not a Quest performance claim. Shared sky illumination can tint otherwise neutral surfaces. Old colour illustrations still named as earlier studies are historical, not new screenshots.

Future tutorial pass: preserve the familiar PointBody/CubeBody lineage and teach transformations. Grayscale is the chapter’s supplied presentation; do not make material conversion a new prerequisite lesson.
'''
(OUT/'REPORT.md').write_text(report,encoding='utf-8')
print('Published',OUT/'index.html',sum(len(d['checks']) for d in reports),'checks')
