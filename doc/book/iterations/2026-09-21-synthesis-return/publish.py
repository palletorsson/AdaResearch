from pathlib import Path
import difflib, hashlib, html, json, re
import markdown

H=Path(__file__).resolve().parent;R=H.parents[3]
M='PostCrisis_Synthesis';A='AdvancedLaboratory_Lab_Equipment_Simulation'
relative=H.relative_to(R).as_posix()
def read(p):return json.loads(p.read_text(encoding='utf-8'))
def render(s):return markdown.markdown(s,extensions=['fenced_code','footnotes'])
old=(H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
new=(R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
for original in (H/'before').rglob('*'):
    if not original.is_file():continue
    f=original.relative_to(H/'before');current=R/f
    if not current.exists():continue
    a=original.read_text(encoding='utf-8');b=current.read_text(encoding='utf-8')
    target='final.md.diff' if f==Path('commons/maps')/M/'final.md' else str(f).replace('\\','__').replace('/','__')+'.diff'
    (H/target).write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+f.as_posix(),tofile='current/'+f.as_posix())),encoding='utf-8')

images=[('museum-empty.png','Before any changed release: the starting pose stands alone. The place for a kept pose remains empty.'),('museum-return.png','After four controlled joint changes in Assembly: the final hall reconstructs the saved pose beside its starting arrangement.'),('museum-passage.png','Walk between and around the two bodies. The same connections now carry different proportions.'),('museum-ledger.png','The ledger stands to the side and reads the same saved record. Time spent waiting adds no edits.')]
figures=''.join(f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" width="1800" height="1200" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in images)
style=(R/'doc/book/iterations/2026-09-21-rhizome-immersion/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Synthesis — the body that returned</title><style>'''+style+'''</style><main>
<div class="eyebrow">Ada Research · Post-Crisis Synthesis · 21 September 2026</div>
<h1>The body that returned</h1>
<p class="intro">The hand has arrived. Your hand is missing.</p>
<p>The body you altered in Assembly now returns at standing scale in the final hall. Its starting pose stands beside it. The record keeps the destination; the gesture that found it is absent. The chapter starts with that encounter and asks what we would want to remember next.</p>
<nav><a href="#read">Read the chapter</a><a href="#compare">Original beside revision</a><a href="final.md.diff">Exact text diff</a><a href="SUMMARY.md">Construction and checks</a><a href="/compose/sources?map='''+M+'''&amp;doc=final">Read and comment</a><a href="../2026-09-21-assembly-immersion/index.html">Previous hall: Assembly</a></nav>
<div class="gallery">'''+figures+'''</div>
<p class="note">Actual Godot museum captures. The empty and kept states belong to the same new implementation; they are not old/new build images. Four controlled joint releases produced a real record in a private probe file. These are not a record of Palle’s visit. Producer teardown, disk reload and the selected continuous walk passed. Headset experience remains untested.</p>
<section class="reading" id="read">'''+render(new)+'''</section>
<details id="compare"><summary>Read the original and revision side by side</summary><div class="compare"><article><div class="eyebrow">Before this pass</div>'''+render(old)+'''</article><article><div class="eyebrow">Current chapter</div>'''+render(new)+'''</article></div></details>
<p class="note">Assembly’s chapter has one continuity edit: its closing paragraph now carries the kept pose into this hall. The earlier chapter and its images remain in the previous review; <a href="commons__maps__AdvancedLaboratory_Lab_Equipment_Simulation__final.md.diff">see that exact change</a>.</p></main></html>'''
(H/'index.html').write_text(page,encoding='utf-8')

checks=[]
def check(label,ok):checks.append(dict(check=label,passed=bool(ok)))
data=read(R/'commons/maps'/M/'map_data.json');before=read(H/'before/commons/maps'/M/'map_data.json')
tokens=lambda d:[t.split(':')[0] for row in d['layers']['interactables'] for t in row if t.strip()]
check('All six earlier artifact families retained',set(tokens(before))<=set(tokens(data)) and len(set(tokens(before)))==6)
check('Only one new artifact family',set(tokens(data))-set(tokens(before))=={'assembly_return'})
check('Authored floor preserved',data['layers']['structure']==before['layers']['structure'])
roles=read(R/'commons/data/artifact_roles.json')
check('Both primaries follow the manuscript order',re.findall(r'<!-- @([A-Za-z_]+) -->',new)==roles['order'][M]['primary']==['assembly_return','accountability_ledger'])
old_roles=read(H/'before/commons/data/artifact_roles.json')
check('Existing roles preserved',all(roles['roles'][M][t]==v for t,v in old_roles['roles'][M].items()))
check('Other rooms roles preserved',{k:v for k,v in roles['roles'].items() if k!=M}=={k:v for k,v in old_roles['roles'].items() if k!=M})
source=(R/'algorithms/computationalbiology/molecular_framework/AssemblyPoseRecord.gd').read_text(encoding='utf-8')
check('Book code is from the implementation',all(re.sub(r'\s+','',b) in re.sub(r'\s+','',source) for b in re.findall(r'```gdscript\n(.*?)```',new,re.S)))
runtime=read(H/'museum-runtime.json')
check('Runtime behaviour checks pass',runtime['passed'] and len(runtime['checks'])==27 and all(c['ok'] for c in runtime['checks']))
check('Selected continuous walking route passes',len(runtime['walks'])==10 and all(c['passed'] for c in runtime['walks']))
check('No script errors in final run','SCRIPT ERROR' not in (H/'museum-process.log').read_text(encoding='utf-8'))
for name,_ in images:check(name+' exists',(H/name).stat().st_size>10000)
core=read(R/'commons/data/museum_core_encounters.json')['rooms']
for m in [M,A]:
    for key,filename in [('map_sha256','map_data.json'),('text_sha256','final.md')]:
        check(m+'/'+filename+' encounter hash current',core[m][key]==hashlib.sha256((R/'commons/maps'/m/filename).read_bytes()).hexdigest())
    check(m+' learner status not inflated',core[m]['learner_verified'] is False)
old_plan=read(H/'before/ada_run/em_plan.json');plan=read(R/'ada_run/em_plan.json')
check('Other hall plan rows preserved',[x for x in old_plan['plans'] if x.get('map')!=M]==[x for x in plan['plans'] if x.get('map')!=M])
registry=read(R/'commons/artifacts/registry/postfoundationscrisis.json')['artifacts']['assembly_return']
check('New registry scene resolves',(R/registry['scene'].removeprefix('res://')).is_file())
book=next(x for x in read(R/'commons/data/book/postfoundationscrisis.json')['pearls'] if x['map']==M)
check('Book presentation matches primaries',book['hero']=='assembly_return' and [x['token'] for x in book['lines']]==roles['order'][M]['primary'])
for name in ['trunk_branches.json','museum/trunk_branches.json']:
    trunk=read(R/'commons/data'/name)
    pearl=next(p for t in trunk['trunk'] for p in t['pearls'] if p['map']==M)
    check(name+' agrees with new encounter',pearl['hero']=='assembly_return' and 'assembly_return' in pearl['tokens'])
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
assert all(c['passed'] for c in checks),[c for c in checks if not c['passed']]
inputs=['commons/maps/'+m+'/'+s for m in [M,A] for s in ['final.md','map_data.json','critical.md','technical.md']]+['algorithms/computationalbiology/molecular_framework/'+s for s in ['MolecularDesigner.gd','AssemblyBodyStudy.gd','AssemblyJoint.gd','AssemblyPoseRecord.gd','assemblies.json']]+['commons/artifacts/assembly_return/assembly_return.gd','commons/artifacts/accountability_ledger/accountability_ledger.gd']
(H/'current-inputs.json').write_text(json.dumps({f:hashlib.sha256((R/f).read_bytes()).hexdigest() for f in inputs},indent=2)+'\n',encoding='utf-8')
p=R/'doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json';d=read(p)
title='Synthesis: the body that returned'
d['items']=[x for x in d['items'] if x.get('title')!=title]
d['items'].append(dict(title=title,description='A changed release in Assembly keeps a local pose. The final hall reconstructs it beside its starting arrangement; the ledger reads that same record. The chapter investigates what survived and what was never retained.',images=[relative+'/museum-empty.png',relative+'/museum-return.png'],captions=[images[0][1],images[1][1]],image_note='Actual Godot views: empty state and a pose made by four controlled releases, using a private probe record. Not old/new builds and not a record of the author’s visit. No headset or learner claim.',text_kind='Book and persistent spatial comparison — 21 September',before='\n\n'.join(old.split('\n\n')[1:5]),after='\n\n'.join(new.split('\n\n')[2:6]),report=relative+'/index.html',report_label='Read the ending, exact diff and paired museum views'))
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
print('Published chapter, original/revision comparison, four images and',len(checks),'content checks.')
