from pathlib import Path
import difflib,hashlib,html,json,re
import markdown

H=Path(__file__).resolve().parent;R=H.parents[3]
A='AdvancedLaboratory_Lab_Equipment_Simulation';S='PostCrisis_Synthesis'
relative=H.relative_to(R).as_posix()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def render(s):return markdown.markdown(s,extensions=['fenced_code','footnotes'])
def old(m):return (H/'before/commons/maps'/m/'final.md').read_text(encoding='utf-8')
def current(m):return (R/'commons/maps'/m/'final.md').read_text(encoding='utf-8')
checks=[]
def check(name,passed):checks.append(dict(check=name,passed=bool(passed)))
for original in (H/'before').rglob('*'):
    if not original.is_file():continue
    rel=original.relative_to(H/'before');now=R/rel
    target='__'.join(rel.parts)+'.diff'
    (H/target).write_text(''.join(difflib.unified_diff(original.read_text(encoding='utf-8').splitlines(True),now.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+rel.as_posix(),tofile='current/'+rel.as_posix())),encoding='utf-8')
chapters=[]
roles=read(R/'commons/data/artifact_roles.json');core=read(R/'commons/data/museum_core_encounters.json')['rooms']
for m,label in [(A,'Assembly'),(S,'Synthesis')]:
    d=read(R/'commons/maps'/m/'map_data.json');baseline=read(H/'before/commons/maps'/m/'map_data.json')
    check(m+' floor unchanged',d['layers']['structure']==baseline['layers']['structure'])
    check(m+' all artifact placements preserved',d['layers']['interactables']==baseline['layers']['interactables'])
    check(m+' book order matches roles',re.findall(r'<!-- @([A-Za-z_]+) -->',current(m))==roles['order'][m]['primary'])
    for key,f in [('text_sha256','final.md'),('map_sha256','map_data.json')]:
        check(m+' '+f+' hash current',core[m][key]==hashlib.sha256((R/'commons/maps'/m/f).read_bytes()).hexdigest())
    check(m+' not marked learner verified',core[m]['learner_verified'] is False)
    diff=f'commons__maps__{m}__final.md.diff'
    chapters.append(f'<section id="{m}"><h2 class="chapter-label">{label}</h2><nav><a href="{diff}">Exact text diff</a><a href="/compose/sources?map={m}&amp;doc=final">Read and comment</a></nav><div class="reading">'+render(current(m))+'</div><details><summary>Original beside revision</summary><div class="compare"><article><div class="eyebrow">Before this continuation</div>'+render(old(m))+'</article><article><div class="eyebrow">Current text</div>'+render(current(m))+'</article></div></details></section>')
runtime=read(H/'museum-runtime.json');synthesis=read(H/'synthesis/museum-runtime.json')
check('Assembly behaviour checks pass',runtime['passed'] and len(runtime['checks'])==53 and all(c['ok'] for c in runtime['checks']))
check('Continuous Assembly route passes',len(runtime['walks'])==10 and all(c['passed'] for c in runtime['walks']))
check('Actual Synthesis reconstruction checks pass',synthesis['passed'] and len(synthesis['checks'])==7 and all(c['ok'] for c in synthesis['checks']))
for folder in [H,H/'synthesis']:
    check(str(folder.relative_to(H) or '.')+' no script errors','SCRIPT ERROR' not in (folder/'museum-process.log').read_text(encoding='utf-8'))
images=[('museum-body-before.png','Before: all thirteen points in their starting places, with twelve connections.'),('museum-body-after.png','After moving only the turquoise collar to the head: the hand is isolated and a loop has appeared. No joint moved.'),('synthesis/museum-return.png','In the final hall, the two bodies use the same coordinates. The turquoise edge shows the altered relation in the kept body.'),('synthesis/museum-ledger.png','The same record distinguishes zero displaced joints from one rerouted connection.')]
figures=''
for name,caption in images:
    check(name+' exists',(H/name).stat().st_size>10000)
    figures+=f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" width="1800" height="1200" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>'
implementation='\n'.join((R/p).read_text(encoding='utf-8') for p in ['algorithms/computationalbiology/molecular_framework/Part.gd','algorithms/computationalbiology/molecular_framework/AssemblyBodyStudy.gd','algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd'])
compact=re.sub(r'\s+','',implementation).replace('#Springforcetowardtarget','')
check('Book code excerpts come from source',all(re.sub(r'\s+','',block) in compact for m in [A,S] for block in re.findall(r'```gdscript\n(.*?)```',current(m),re.S)))
check('Opening encounter retained',current(A).split('Across the floor')[0]==old(A).split('Across the floor')[0])
check('Ending retained',current(S).rstrip().endswith('The clock is still running. There is something you wanted to make.'))
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
assert all(c['passed'] for c in checks),[c for c in checks if not c['passed']]
style=(R/'doc/book/iterations/2026-09-21-assembly-immersion/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Assembly — move a connection</title><style>'''+style+''' .chapter-label{margin-top:60px;border-top:1px solid #b9c6b7;padding-top:30px}</style><main><div class="eyebrow">Ada Research · Assembly and its return · 21 September 2026</div><h1>Same points. Another relation.</h1><p class="intro">The hand stays where it was. The connection leaves it.</p><p>A turquoise collar makes one relation available to the visitor's hand. Move its end to another joint; the points stay put. The original and altered graphs are kept separately, so the final hall can return the difference.</p><nav><a href="#'''+A+'''">Read Assembly</a><a href="#'''+S+'''">Read Synthesis</a><a href="SUMMARY.md">Construction and checks</a><a href="../2026-09-21-full-book/index.html">Earlier frozen manuscript for Claude</a></nav><div class="gallery">'''+figures+'''</div><p class="note">Actual Godot museum captures, before and after a controlled connection release within the same new implementation. The final-hall images reconstruct that recorded change in a private probe file. Desktop pickup and the synthetic XRTools grab path pass; these are not headset observations or a record of Palle’s choices.</p>'''+''.join(chapters)+'''</main></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
inputs=['commons/maps/'+m+'/'+f for m in [A,S] for f in ['final.md','map_data.json','technical.md','critical.md']]+['algorithms/computationalbiology/molecular_framework/'+f for f in ['AssemblyBodyStudy.gd','AssemblyBondEnd.gd','AssemblyPoseRecord.gd','AssemblyJoint.gd','assemblies.json']]+['commons/artifacts/assembly_return/assembly_return.gd','commons/artifacts/accountability_ledger/accountability_ledger.gd']
(H/'current-inputs.json').write_text(json.dumps({p:hashlib.sha256((R/p).read_bytes()).hexdigest() for p in inputs},indent=2)+'\n',encoding='utf-8')
p=R/'doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json';d=read(p);title='Assembly: move a connection'
d['items']=[i for i in d['items'] if i.get('title')!=title]
d['items'].append(dict(title=title,description='A turquoise collar reroutes one existing connection while the gold joints stay still. The same thirteen points and twelve edges can now form two connected groups. Original and altered graphs survive into Synthesis.',images=[relative+'/'+images[0][0],relative+'/'+images[1][0]],captions=[images[0][1],images[1][1]],image_note='Actual Godot museum views of the same new implementation before and after a controlled release. No headset or learner claim.',text_kind='Direct connection editing and narrow chapter revisions — 21 September',before='The body began with thirteen joints and twelve connections. Those connections remain when you stretch it. You have changed its geometry; you have not yet given it another way to connect.',after='The line that used to end at the hand now ends at the head. The body still has thirteen joints and twelve connections. Not one point needed to move.',report=relative+'/index.html',report_label='Compare both chapters and the actual before/after views'))
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Published two chapter comparisons, four museum views and',len(checks),'content checks.')
