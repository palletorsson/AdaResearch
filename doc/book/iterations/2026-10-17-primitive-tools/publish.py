from pathlib import Path
import json,shutil,html,re
import markdown
HERE=Path(__file__).parent;ROOT=HERE.parents[3]
RUNS={'Point_Trace':'tools-v3','Point_Line_Grid':'tools-v2','Point_Animatedcube':'tools-v3','Primitives_Melencolia':'tools-v2'}
IMAGES={
 'Point_Trace':[('glass-front','Pens meet the transparent pane. The supplied stroke is visible; empty pixels remain clear.'),('spatial-beads','Three held points and fixed readouts. A supplied gesture tests recording and transfer.')],
 'Point_Line_Grid':[('selected-trace','Source entry 3 and its snapped counterpart, marked on the two representations.'),('selected-row','The selected source row stays linked to the numbered point. Display and source coordinates are distinguished.')],
 'Point_Animatedcube':[('cube-baseline','Baseline: identical local corners, opposite front-face diagonals.'),('cube-fold','The same 25 cm corner displacement on both cubes produces different front surfaces.')],
 'Primitives_Melencolia':[('skull-detail','An original stylised skull with carved sockets and separate teeth.'),('tableau','The skull replaces the main seated figure. The smaller figure, dog, stone and tools remain.')]
}
TITLES={'Point_Trace':'A pen meets glass. A point leaves a trail.','Point_Line_Grid':'Find the same entry in two forms.','Point_Animatedcube':'Same corners. Different surfaces.','Primitives_Melencolia':'A skull among the tools.'}
CSS='''*{box-sizing:border-box}body{margin:0;background:#f5f2eb;color:#282832;font:18px/1.6 system-ui,sans-serif}main{max-width:1500px;margin:auto;padding:40px 5vw 80px}header{max-width:1000px}h1,h2{font-family:Georgia,serif;line-height:1.15}h1{font-size:clamp(36px,4.5vw,64px);margin:16px 0}h2{font-size:34px}h3{font-size:20px}a{color:#65456d;text-underline-offset:4px}nav{display:flex;flex-wrap:wrap;gap:10px;margin:25px 0}nav a,.pill{padding:7px 12px;border:1px solid #c3b5c3;border-radius:4px;font-size:14px;text-decoration:none}.eyebrow{font-size:13px;letter-spacing:.13em;text-transform:uppercase;color:#69516d}.summary{max-width:1100px;margin:40px 0}li{margin:12px 0}section{border-top:1px solid #c7bdc7;padding-top:22px;margin-top:55px;scroll-margin-top:20px}.pair{display:grid;grid-template-columns:1fr 1fr;gap:20px}.pair>*{min-width:0}figure{margin:0}img{width:100%;height:auto;display:block;border-radius:5px;background:#d8d2ce}figcaption{font-size:14px;margin:10px 0 22px;color:#4f4b53}details{background:#ebe5ee;padding:14px 20px;margin:20px 0;border-radius:5px}summary{cursor:pointer;font-weight:600}.receipt{font-size:15px}code,pre{font-size:.85em;background:#ece7df;overflow:auto}pre{padding:18px}table{border-collapse:collapse;font-size:15px}td,th{padding:7px;border-bottom:1px solid #c7bdc7;text-align:left}footer{font-size:14px;margin:45px 0}.text{background:#fffdfa;padding:24px;overflow-wrap:anywhere}.text h1{font-size:33px}.text h2{font-size:27px}.text h3{font-size:22px}.text img{width:100%}.small{font-size:15px}.badge{color:#335f4d;background:#dce9e1;display:inline-block;padding:6px 12px;border-radius:4px}@media(max-width:850px){main{padding:25px 20px}.pair{grid-template-columns:1fr}.text{padding:18px}}'''
def page(title,body):return '<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>'+html.escape(title)+'</title><style>'+CSS+'</style></head><body><main>'+body+'</main></body></html>'
def md(text):return markdown.markdown(text,extensions=['fenced_code','tables','footnotes'])
reports={};total=0
for name,tag in RUNS.items():
 src=ROOT/'ada_run/encounter_pilot'/name/tag;dst=HERE/'native'/name;dst.mkdir(parents=True,exist_ok=True)
 report=json.loads((src/'report.json').read_text(encoding='utf-8-sig'))
 assert report['passed'],name
 reports[name]=report;total+=len(report['checks'])
 for filename in ['report.json','engine.log','source_manifest.json']:
  if (src/filename).exists():shutil.copy2(src/filename,dst/filename)
 for image,_ in IMAGES[name]:shutil.copy2(src/(image+'.png'),dst/(image+'.png'))
 for section in ['final','tutorial','technical','summary','artifacts']:
  current=ROOT/'commons/maps'/name/(section+'.md');snap=HERE/'after'/name/(section+'.md');snap.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(current,snap)
 before=(HERE/'before/commons/maps'/name/'final.md').read_text(encoding='utf-8-sig')
 after=(HERE/'after'/name/'final.md').read_text(encoding='utf-8-sig')
 body=f'<p class="eyebrow">{html.escape(name)} · text comparison</p><h1>Before and current reading</h1><p><a href="index.html#{name}">Back to the installation</a></p><div class="pair"><article class="text"><h2>Before this implementation</h2>{md(before)}</article><article class="text"><h2>Current local version</h2>{md(after)}</article></div>'
 (HERE/(name+'-compare.html')).write_text(page(name+' · readings',body),encoding='utf-8')
summary=(HERE/'summary.md').read_text(encoding='utf-8')
body='<header><p class="eyebrow">Ada Research · 17 October 2026 · Installed locally</p><h1>Tools that fit<br>the encounter.</h1><p>Glass, a spatial trace, a shared corner and a skull. Four proposals have become working installations, with their readings kept beside them.</p>'
body+=f'<p class="badge">{total}/{total} supplied runtime checks pass</p><p class="small">Includes interaction, geometry, trace transfer, captures and walking routes. Human headset comfort and discovery remain to be tested.</p></header>'
body+='<nav>'+''.join(f'<a href="#{name}">{name.replace("Point_", "").replace("Primitives_", "")}</a>' for name in RUNS)+'<a href="summary.md">Download summary</a></nav>'
body+='<div class="summary">'+md(summary.replace('# Four primitive maps — implemented for the next encounter','## The changes to read'))+'</div>'
for name in RUNS:
 count=len(reports[name]['checks'])
 body+=f'<section id="{name}"><p class="eyebrow">{name}</p><h2>{TITLES[name]}</h2><div class="pair">'
 for image,caption in IMAGES[name]:
  image_url=f'native/{name}/{image}.png'
  body+=f'<figure><a href="{image_url}"><img src="{image_url}" width="1800" height="1200" alt="{html.escape(caption)}" loading="lazy"></a><figcaption>{caption} Native Godot capture.</figcaption></figure>'
 body+='</div>'
 body+=f'<nav><a href="{name}-compare.html">Read original and revised final</a><a href="after/{name}/tutorial.md">Tutorial</a><a href="after/{name}/technical.md">Implementation reference</a></nav>'
 body+=f'<details><summary>{count} supplied checks · see evidence</summary><ul class="receipt">'+''.join('<li>'+html.escape(c['name'])+'</li>' for c in reports[name]['checks'])+'</ul>'
 body+=f'<p class="small"><a href="native/{name}/report.json">Raw report</a> · <a href="native/{name}/engine.log">Engine log</a></p></details></section>'
body+='''<section><h2>What remains an experiment</h2><p>The geometry and controls respond in supplied desktop/XRTools driver trials. This does not establish headset reach, comfort, Quest performance, or that a visitor discovers the comparison unaided.</p><p>The layout checker passes all four maps, with legacy edge-teleporter warnings. Melencolia also reports a resource still in use during shutdown; its scene loads and its checks pass, but this is not a clean-exit claim. The other three final engine logs have no script errors.</p><p>The older report harness uses a generic slider/reset scope label. The named checks above describe the actual supplied inputs in this pass: grip/release, coordinate selection, geometry changes and walks.</p><p><strong>Keep the correction:</strong> a pen meets a surface; a spatial point gives movement a visible trail. Both belong in the room.</p></section><footer><a href="../2026-10-17-primitive-reverse-brief/index.html">Original proposal</a> · <a href="../2026-10-17-primitive-encounters/index.html">Earlier primitive improvements</a><p>Local changes. No commit or push. Screenshots show supplied test states, not a visitor study.</p></footer>'''
(HERE/'index.html').write_text(page('Primitive tools · implemented encounters',body),encoding='utf-8')
(HERE/'verification.json').write_text(json.dumps({'checks':total,'passing':total,'maps':{n:len(r['checks']) for n,r in reports.items()},'limits':['No human headset trial','Melencolia shutdown resource warning','Legacy edge-teleporter warnings']},indent=2),encoding='utf-8')
print(f'Review written: {total} passing checks; 8 native images; 4 full-text comparisons.')
