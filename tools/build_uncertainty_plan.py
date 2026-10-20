"""Render the editable uncertainty proposal; validate its 25 existing sequence hosts."""
from pathlib import Path
import hashlib,html,json,re,zipfile
import markdown
R=Path(__file__).resolve().parents[1];O=R/'doc/book/course/uncertainty-plan'
audit=json.loads((O/'inventory.json').read_text(encoding='utf-8'))
spine=json.loads((R/'commons/maps/curriculum_spine.json').read_text(encoding='utf-8'))['spine']['sequences']
assert len(spine)==25
assert hashlib.sha256((R/'commons/maps/curriculum_spine.json').read_bytes()).hexdigest()==audit['spine_sha256'],'Spine changed since audit; rerun inventory and review mapping.'
rows=[]
for line in (O/'SEQUENCES.md').read_text(encoding='utf-8').splitlines():
 if not re.match(r'\| \d+ ·',line):continue
 cells=[s.strip() for s in line.strip('|').split('|')];assert len(cells)==5,cells
 num=int(cells[0].split(' · ')[0]);source=next(s for s in audit['sequences'] if s['order']==num)
 hosts=[s.strip() for s in cells[1].split(';')]
 assert all(s in source['maps'] for s in hosts),(source['id'],hosts)
 rows.append({'order':num,'sequence':source['id'],'hosts':hosts,'main_subject':cells[2],'proposal':cells[3],'carry_and_check':cells[4],'status':{'randomness':'P3 built; main lesson preserved','noise':'G0 built; further returns proposed','forces':'G1 and P1 built; further returns proposed','swarmintelligence':'G2 built; further returns proposed','shaders':'Camera study and P4 built; further returns proposed'}.get(source['id'],'proposed')})
assert [r['order'] for r in rows]==list(range(1,26))
(O/'sequence-plan.json').write_text(json.dumps({'status':'G0 geometry-noise, G1 pendulum, G2 observation, P1 stepping, P3 sampling and P4 receivers installed; P2/P5/P6 remain proposed','rows':rows},ensure_ascii=False,indent=2),encoding='utf-8')
style='''*{box-sizing:border-box}html{scroll-behavior:smooth}body{margin:0;background:#f2efe7;color:#172a2e;font:18px/1.65 Georgia,serif}header,main,footer{max-width:1500px;margin:auto;padding:34px}header{padding-top:64px}h1{font-size:clamp(38px,5vw,70px);max-width:1100px;line-height:1.05}h2{margin-top:2.3em;line-height:1.2}h3{line-height:1.3}nav{display:flex;gap:20px;flex-wrap:wrap;font:14px/1.5 system-ui}a{color:#265d66;text-underline-offset:3px}.eyebrow,.tag{font:12px/1.6 system-ui;letter-spacing:.08em;text-transform:uppercase}.tag{display:inline-block;padding:5px 10px;background:#ddd5dc}.lead{font-size:25px;max-width:870px}.route{display:grid;grid-template-columns:repeat(3,minmax(0,1fr));gap:18px;margin:30px 0}.card{background:#fffcf4;border-top:5px solid #8a627f;padding:23px;min-width:0}.card h3{margin:.5em 0}.card p{font-size:17px}.card small{font:12px/1.5 system-ui;color:#526568;overflow-wrap:anywhere}.card details{border-top:1px solid #dad8ce;padding-top:12px}.card summary{cursor:pointer;font:14px/1.6 system-ui}table{border-collapse:collapse;display:block;overflow:auto;font:15px/1.5 system-ui}td,th{vertical-align:top;text-align:left;padding:12px;border-bottom:1px solid #c9c9be;min-width:130px}td:first-child{font-weight:600}tr:nth-child(even){background:#e9e8df}p,li{max-width:88ch}pre{overflow:auto;background:#1e3033;color:white;padding:18px;font:13px/1.5 Consolas}code{font-size:.85em;overflow-wrap:anywhere}footer{border-top:1px solid #bec8c6}.quick{background:#e0e8e3;padding:22px;margin:25px 0;max-width:900px}@media(max-width:1080px){.route{grid-template-columns:repeat(2,minmax(0,1fr))}}@media(max-width:700px){.route{display:block}.card{margin-bottom:20px}header,main,footer{padding:22px}}@media print{nav{display:none}body{font-size:11pt}.route{display:block}.card{break-inside:avoid}table{font-size:9pt}header,main,footer{padding:0}h1{font-size:28pt}}'''
nav='<nav><a href="index.html">Work packages</a><a href="sequences.html">25 sequences</a><a href="noise-tests.html">Noise experiments</a><a href="inventory.html">Source audit</a><a href="PLAN.md">Edit/read Markdown</a><a href="uncertainty-plan.zip">Review ZIP</a></nav>'
def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','toc'])
def page(name,title,body):
 (O/name).write_text(f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum / editable plan / updated 9 October 2026</div><h1>{html.escape(title)}</h1>{nav}</header><main>{body}</main><footer>G0, G1, G2, P1, P3 and P4 have their own native test receipts. Other work packages remain proposals. Source and host checks do not establish headset or learner evidence. No new sequence added.</footer></body></html>',encoding='utf-8')
plan=(O/'PLAN.md').read_text(encoding='utf-8')
body='<p class="lead">Let the familiar objects reveal the conditions they depend on.</p><span class="tag">25 sequences retained · G0, G1, G2, P1, P3 and P4 built · three original packages proposed</span><div class="quick"><a href="noise-tests.html">G0: The Uncertain Surface</a> is installed in the Noise opening, with <a href="../../iterations/2026-10-09-geometry-noise-test/index.html">museum images and native test receipts</a>. <a href="../../iterations/2026-10-09-pendulum-a-recorded-push/index.html">G1: The same release / a recorded push</a> is installed in the Forces oscillation hall. <a href="../../iterations/2026-10-09-navigator-an-imperfect-observation/index.html">G2: An imperfect observation</a> is installed in Agent-Based Modeling. <a href="../../iterations/2026-10-09-the-same-throw-different-steps/index.html">P1: The same throw, different steps</a> is installed beside the launch chamber. An optional <a href="../../iterations/2026-10-09-camera-image-becomes-body/index.html">ten-view camera study</a> is also installed in Patterns. <a href="../../iterations/2026-10-09-samples-and-disagreement/index.html">P3: sample budget</a> is now built on the existing dartboard. <a href="../../iterations/2026-10-09-one-record-many-readings/index.html">P4: one record, different readings</a> now extends that camera. Next original package is P2: a response returns. The <a href="sequences.html">sequence view</a> preserves each hall’s main subject.</div>'+md(plan)
page('index.html','When the rule meets its conditions',body)
cards=''
for r in rows:
 cards+=f'<article class="card" id="{r["sequence"]}"><span class="tag">{r["order"]:02d} · {html.escape(r["status"])}</span><h3>{html.escape(r["sequence"].replace("_"," "))}</h3><small>{html.escape(" · ".join(r["hosts"]))}</small><p><strong>Keep:</strong> {html.escape(r["main_subject"])}</p>'+md(r['proposal'])+'<details><summary>What travels onward / what to check</summary>'+md(r['carry_and_check'])+'</details></article>'
page('sequences.html','The thread through 25 sequences','<p class="lead">Six families, distributed returns. A hall can prepare a question without teaching its whole theory.</p><nav>'+''.join(f'<a href="#{r["sequence"]}">{r["order"]:02d}</a>' for r in rows)+'</nav><div class="route">'+cards+'</div><p>Edit <a href="SEQUENCES.md">SEQUENCES.md</a>, then run the publisher. <a href="sequence-plan.json">Structured plan</a>.</p>')
page('inventory.html','What the sources actually do',md((O/'INVENTORY.md').read_text(encoding='utf-8')))
page('noise-tests.html','Noise testing: a measured intervention',md((O/'NOISE_TESTS.md').read_text(encoding='utf-8')))
with zipfile.ZipFile(O/'uncertainty-plan.zip','w',zipfile.ZIP_DEFLATED) as z:
 for name in ['PLAN.md','SEQUENCES.md','NOISE_TESTS.md','INVENTORY.md','inventory.json','sequence-plan.json','index.html','sequences.html','noise-tests.html','inventory.html']:z.write(O/name,name)
 z.writestr('README.md','G0 geometry-noise, G1 pendulum, G2 observation, P1 stepping, P3 sampling and P4 receivers built; P2/P5/P6 remain proposed. PLAN.md: work packages. NOISE_TESTS.md: twelve intervention candidates and the built first experiment. SEQUENCES.md: actual 25-sequence route. INVENTORY.md: source findings, not blanket runtime certification. Source links and the separately packaged museum review need the repository; these reading pages and internal navigation work without it. To edit, change Markdown in doc/book/course/uncertainty-plan and run tools/build_uncertainty_plan.py.\n')
links=0
for p in O.glob('*.html'):
 for ref in re.findall(r'(?:href|src)="([^"]+)"',p.read_text(encoding='utf-8')):
  if ref.startswith(('http:','https:')):continue
  path,_,anchor=ref.partition('#');dest=p.parent/path if path else p
  assert dest.exists(),(p.name,ref)
  if anchor and dest.suffix=='.html':assert f'id="{anchor}"' in dest.read_text(encoding='utf-8'),(p.name,ref)
  links+=1
with zipfile.ZipFile(O/'uncertainty-plan.zip') as z:assert z.testzip() is None
(O/'validation.json').write_text(json.dumps({'date':'2026-10-09','sequence_rows':len(rows),'all_hosts_in_current_sequence':True,'spine_unchanged_since_audit':True,'local_links_valid':links,'zip_valid':True,'scope':'Static plan, source/host consistency, package integrity. G0/G1/G2/P1/P3/P4 runtime receipts are in their separate museum reviews; this publisher performs no runtime or browser render test.'},indent=2),encoding='utf-8')
print(json.dumps({'sequences':len(rows),'links':links,'published':str(O/'index.html')}))
