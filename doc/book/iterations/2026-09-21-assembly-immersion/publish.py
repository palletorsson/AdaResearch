from pathlib import Path
import difflib, hashlib, html, json, re
import markdown

H=Path(__file__).resolve().parent;R=H.parents[3]
M='AdvancedLaboratory_Lab_Equipment_Simulation';relative=H.relative_to(R).as_posix()
old=(H/'before/commons/maps'/M/'final.md').read_text(encoding='utf-8')
new=(R/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
def render(s):return markdown.markdown(s,extensions=['fenced_code','footnotes'])
for f in ['commons/maps/'+M+'/final.md','commons/maps/'+M+'/technical.md','commons/maps/'+M+'/critical.md','commons/maps/'+M+'/map_data.json','algorithms/computationalbiology/molecular_framework/MolecularDesigner.gd']:
 a=(H/'before'/f).read_text(encoding='utf-8');b=(R/f).read_text(encoding='utf-8')
 (H/(Path(f).name+'.diff')).write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+f,tofile='current/'+f)),encoding='utf-8')
images=[('museum-body-before.png','Before the gesture: the thirteen joints in their authored pose.'),('museum-body-after.png','After moving four joints: connections remain, proportions and gesture change.'),('museum-pair-before.png','The automatic catalogue and the new editable body share an open floor.'),('museum-pair-after.png','The automatic body retains its description while the changed pose stays beside it.')]
figures=''.join(f'<figure><a href="{name}"><img src="{name}" alt="{html.escape(caption)}" width="1800" height="1200" loading="lazy"></a><figcaption>{html.escape(caption)}</figcaption></figure>' for name,caption in images)
style=(R/'doc/book/iterations/2026-09-21-rhizome-immersion/index.html').read_text(encoding='utf-8').split('<style>')[1].split('</style>')[0]
page='''<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<title>Assembly — where a body is expected</title><style>'''+style+'''</style><main>
<div class="eyebrow">Ada Research · Assembly Laboratory · 21 September 2026</div>
<h1>Where a body is expected</h1>
<p class="intro">Take a hand a little farther than an arm ought to reach. Let go. The body keeps your alteration.</p>
<p>The existing catalogue remains. Beside it, a body at standing scale now lets you move its joints directly. The chapter follows the gesture into a question about recognition, proportions and the relations we have not yet been allowed to change.</p>
<nav><a href="#read">Read the chapter</a><a href="#compare">Original beside revision</a><a href="final.md.diff">Exact text diff</a><a href="SUMMARY.md">Construction and checks</a><a href="/compose/sources?map='''+M+'''&amp;doc=final">Read and comment</a></nav>
<div class="gallery">'''+figures+'''</div>
<p class="note">Actual Godot museum captures. Before/after shows the same new body before and after a controlled gesture; it is not a comparison of old and new builds. The automatic reference was settled and held for the photographs. The original manuscript is preserved below. Desktop and synthetic VR grab checks passed; headset experience remains untested.</p>
<section class="reading" id="read">'''+render(new)+'''</section>
<details id="compare"><summary>Read the original and revision side by side</summary><div class="compare"><article><div class="eyebrow">Before this pass</div>'''+render(old)+'''</article><article><div class="eyebrow">Current chapter</div>'''+render(new)+'''</article></div></details></main></html>'''
(H/'index.html').write_text(page,encoding='utf-8')
p=R/'doc/book/iterations/2026-09-19-review-comparison/postfoundationscrisis.json';d=json.loads(p.read_text(encoding='utf-8'))
title='Assembly: leave a body different'
d['items']=[x for x in d['items'] if x.get('title')!=title]
d['items'].append(dict(title=title,description='The existing catalogue keeps cycling. A separate body reuses its thirteen joints and twelve connections, now grabbable at standing scale. Released joints retain their positions. The chapter begins with that intervention and asks what remains fixed.',images=[relative+'/museum-body-before.png',relative+'/museum-body-after.png'],captions=[images[0][1],images[1][1]],image_note='Actual museum views of the new body before and after a controlled gesture, not an old/new build comparison. Desktop and synthetic VR grab checks pass; no headset or learner claim.',text_kind='Book and direct manipulation — 21 September',before='\n\n'.join(old.split('\n\n')[1:5]),after='\n\n'.join(new.split('\n\n')[2:6]),report=relative+'/index.html',report_label='Read the chapter, text comparison and paired museum images'))
p.write_text(json.dumps(d,indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
checks=[]
def check(label,ok):checks.append(dict(check=label,passed=bool(ok)))
data=json.loads((R/'commons/maps'/M/'map_data.json').read_text(encoding='utf-8'))
before=json.loads((H/'before/commons/maps'/M/'map_data.json').read_text(encoding='utf-8'))
tokens=lambda d:[t.split(':')[0] for row in d['layers']['interactables'] for t in row if t.strip()]
check('Existing artifact family retained',tokens(data)==tokens(before)==['MolecularDesigner'])
check('Authored floor preserved',data['layers']['structure']==before['layers']['structure'])
check('Book primary matches role order',re.findall(r'<!-- @([A-Za-z_]+) -->',new)==json.loads((R/'commons/data/artifact_roles.json').read_text(encoding='utf-8'))['order'][M]['primary'])
part=(R/'algorithms/computationalbiology/molecular_framework/Part.gd').read_text(encoding='utf-8')
study=(R/'algorithms/computationalbiology/molecular_framework/AssemblyBodyStudy.gd').read_text(encoding='utf-8')
check('Both code excerpts come from source',all(re.sub(r'\s+','',block) in re.sub(r'\s+','',part+'\n'+study).replace('#Springforcetowardtarget','') for block in re.findall(r'```gdscript\n(.*?)```',new,re.S)))
runtime=json.loads((H/'museum-runtime.json').read_text(encoding='utf-8'))
check('Runtime interaction checks pass',runtime['passed'] and all(c['ok'] for c in runtime['checks']))
check('Continuous selected walking route passes',len(runtime['walks'])==10 and all(c['passed'] for c in runtime['walks']))
check('No script errors in final run','SCRIPT ERROR' not in (H/'museum-process.log').read_text(encoding='utf-8'))
for name,_ in images:check(name+' exists',(H/name).stat().st_size>10000)
core=json.loads((R/'commons/data/museum_core_encounters.json').read_text(encoding='utf-8'))['rooms'][M]
for key,filename in [('map_sha256','map_data.json'),('text_sha256','final.md')]:check(filename+' encounter hash current',core[key]==hashlib.sha256((R/'commons/maps'/M/filename).read_bytes()).hexdigest())
check('Learner status not inflated',core['learner_verified'] is False)
old_plan=json.loads((H/'before/ada_run/em_plan.json').read_text(encoding='utf-8'))
new_plan=json.loads((R/'ada_run/em_plan.json').read_text(encoding='utf-8'))
check('Other hall plan rows preserved',[x for x in old_plan['plans'] if x.get('map')!=M]==[x for x in new_plan['plans'] if x.get('map')!=M])
(H/'content-checks.json').write_text(json.dumps(checks,indent=2)+'\n',encoding='utf-8')
assert all(c['passed'] for c in checks),[c for c in checks if not c['passed']]
inputs=['commons/maps/'+M+'/'+s for s in ['final.md','map_data.json','critical.md','technical.md']]+['algorithms/computationalbiology/molecular_framework/'+s for s in ['MolecularDesigner.gd','AssemblyBodyStudy.gd','AssemblyJoint.gd','Part.gd','assemblies.json']]
(H/'current-inputs.json').write_text(json.dumps({f:hashlib.sha256((R/f).read_bytes()).hexdigest() for f in inputs},indent=2)+'\n',encoding='utf-8')
print('Published full chapter, paired images and',len(checks),'content checks.')
