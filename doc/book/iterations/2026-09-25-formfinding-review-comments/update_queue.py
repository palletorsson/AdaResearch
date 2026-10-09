from pathlib import Path
import json,urllib.request,hashlib,collections,difflib
root=Path.cwd();out=root/'doc/book/iterations/2026-09-25-formfinding-review-comments'
D=json.loads((out/'decisions.json').read_text(encoding='utf-8'));verification=json.loads((out/'verification.json').read_text(encoding='utf-8'));assert all(c['passed'] for c in verification['checks'])
api='http://localhost:3003/api/book-tasks'
def read_goal():
 with urllib.request.urlopen(api,timeout=20) as r:data=json.load(r)
 return next(g for g in data['goals'] if g['goal_id']=='book_formfinding')
goal=read_goal();original={t['id']:t for t in goal['tasks']}
other={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'doc/tasks').glob('book_*.json') if p.name!='book_formfinding.json'}
(out/'queue-before-update.json').write_text(json.dumps(goal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for task_id,d in D.items():
 # Re-read current canonical notes immediately before updating each item.
 live=json.loads((root/'doc/tasks/book_formfinding.json').read_text(encoding='utf-8-sig'))
 task=next(t for t in live['tasks'] if t['id']==task_id);original[task_id]=task;old=task.get('notes','')
 marker='Codex review — 25 September 2026\n'+d['decision']
 note=(old+'\n\n' if old else '')+marker+'\n\nDetails and exact diffs: /book-review/doc/book/iterations/2026-09-25-formfinding-review-comments/index.html'
 assert len(note)<4000
 payload={'goal_id':'book_formfinding','task_id':task_id,'triage':d['triage'],'status':d['status'],'notes':note,'claimed_by':'codex'}
 request=urllib.request.Request(api,data=json.dumps(payload,ensure_ascii=False).encode('utf-8'),headers={'Content-Type':'application/json'},method='PATCH')
 with urllib.request.urlopen(request,timeout=20) as r:
  result=json.load(r)['task'];assert result['id']==task_id and result['status']==d['status']
current=read_goal();allowed={'notes','status','triage','triaged_at','done_at','claimed_by','updated_at'}
for t in current['tasks']:
 old=original[t['id']]
 assert {k:v for k,v in t.items() if k not in allowed}=={k:v for k,v in old.items() if k not in allowed},t['id']
 if old.get('notes'):assert t['notes'].startswith(old['notes']+'\n\n')
 assert t['status']==D[t['id']]['status']
report={'counts':dict(collections.Counter(t['status'] for t in current['tasks'])),'original_comments_and_author_notes_preserved':True,'review_fields_changed_only':True,'other_queue_files_unchanged':all(hashlib.sha256((root/'doc/tasks'/name).read_bytes()).hexdigest()==h for name,h in other.items())}
assert report['other_queue_files_unchanged']
(out/'queue-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')


p=root/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');first,rest=s.split('\n',1)
entry="""

**25 September — Form Finding review comments: how did this form arrive?** [Reading, exact diffs and native museum pairs](2026-09-25-formfinding-review-comments/index.html) · [queue](http://localhost:3003/book-tasks/review?seq=formfinding). 18 records addressed, including four duplicates. Six canonical final.md chapters revised. Existing self_shaping_forge restored as a third primary: its 180 points and MAX Q bar follow an authored destination and a clock, compared with the physical puzzle and local optimiser. Descent's five supporting works receive short encounters; the current glowing well really reports loss, contrary to the review's older portrait-only reading. Corrected the glass vessel's obsolete walk-through claim; existing two-sided collider retained. Cloth comparison now names WIND off, the PASSES cycle, and step 420; actual one/four-pass mean and worst errors reproduce. Removed maker-facing asides, recalled Gaudi instead of reintroducing him, corrected the bowl formula and grammar, added four titles and a short sequence close. One artifact fix: well normals follow their profile; native vertex/index hashes, transforms and bounds identical before/after. Three unmodified standing museum photographs enter the book. 51 final native checks across four loaded halls and 68 publication/preservation checks pass. Processes exit 0, no GDScript errors; existing UID, registry, GL warnings and Relaxation ObjectDB leak remain. Supplied control/clock/step/ray evidence, not tracked-hand or headset traversal. All six placements, sequence order, wall-card JSON and companion manuscripts retained. Current capture refreshed; shared core/role edits scoped, original queue text preserved. No live museum bake/save replaced. Reload for corrected shading. Next sequence: Wavefunctions; parallel Noise work independent.
"""
p.write_text(first+entry+rest,encoding='utf-8')
changes=json.loads((out/'changed-files.json').read_text(encoding='utf-8'))
for rel in ['doc/tasks/book_formfinding.json','doc/book/iterations/WORKING.md']:
 if rel not in changes:changes.append(rel)
 p=root/rel;dest=out/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
 a=(out/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 dest=out/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
with urllib.request.urlopen('http://localhost:3003/book-review/doc/book/iterations/2026-09-25-formfinding-review-comments/index.html',timeout=20) as response:
 assert response.status==200 and b'How did this form arrive?' in response.read()
print(json.dumps(report,indent=2))
