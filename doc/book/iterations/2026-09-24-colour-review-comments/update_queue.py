from pathlib import Path
import json,urllib.request,hashlib,collections,difflib
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-colour-review-comments'
D=json.loads((out/'decisions.json').read_text(encoding='utf-8'));verification=json.loads((out/'verification.json').read_text(encoding='utf-8'));assert all(c['passed'] for c in verification['checks'])
api='http://localhost:3003/api/book-tasks'
def read_goal():
 with urllib.request.urlopen(api,timeout=20) as r:data=json.load(r)
 return next(g for g in data['goals'] if g['goal_id']=='book_color')
goal=read_goal();original={t['id']:t for t in goal['tasks']}
other={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'doc/tasks').glob('book_*.json') if p.name!='book_color.json'}
(out/'queue-before-update.json').write_text(json.dumps(goal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for task_id,d in D.items():
 # Re-read current canonical notes immediately before updating each item.
 live=json.loads((root/'doc/tasks/book_color.json').read_text(encoding='utf-8-sig'))
 task=next(t for t in live['tasks'] if t['id']==task_id);original[task_id]=task;old=task.get('notes','')
 marker='Codex review — 24 September 2026\n'+d['decision']
 note=(old+'\n\n' if old else '')+marker+'\n\nDetails and exact diffs: /book-review/doc/book/iterations/2026-09-24-colour-review-comments/index.html'
 assert len(note)<4000
 payload={'goal_id':'book_color','task_id':task_id,'triage':d['triage'],'status':d['status'],'notes':note,'claimed_by':'codex'}
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

**24 September — Colour review comments, photographed inside the museum.** [Museum views and exact differences](2026-09-24-colour-review-comments/index.html) · [live queue](http://localhost:3003/book-tasks/review?seq=color). Author requests screenshots from inside the museum going forward: show the loaded hall from standing viewpoints, with architecture and nearby exhibits, rather than an isolated artifact/grid illustration. Six manuscripts receive focused changes; Flashlight and Pillar prose are retained. Eleven comments resolved, preserving their original review fields and author notes. Trimmed the name catalogue and DNA paragraph while retaining the deliberate form-grammar bridge; added qualified Kandinsky/Siedhoff-Buscher and Albers references; corrected captions, sixteen gradient samples and optional entrance offers. The striped-column plate now explains 72 cm → 6.2 m in words, with construction unchanged. Four sp score-display tokens become authored s spawns; every other map value preserved, museum arrival unchanged. New actual-museum column and salon views enter final.md. 12 column and 59 salon native checks pass with clean exits; hand-colour propagation checked using invisible production receiver fixtures, not tracked hands. Original colours restored, no save requested. Array receives new entrance/standing photographs and 27 passing checks; its exposed wireframe appearance is the current museum architecture and was not disguised. Historical images/reports retained. 327 scoped publication/preservation checks pass; Colour and Array current captures refreshed. No headset traverse, standalone arrival, recovery/comfort, learner acceptance or Quest performance claim. Live bake/save unchanged. Reload relevant halls for source-map or plate changes. Next review sequence: Tiling. Earlier sequential writing remains paused at Kinetic Forces; parallel Randomness work preserved.
"""
p.write_text(first+entry+rest,encoding='utf-8')
changes=json.loads((out/'changed-files.json').read_text(encoding='utf-8'))
for rel in ['doc/tasks/book_color.json','doc/book/iterations/WORKING.md']:
 if rel not in changes:changes.append(rel)
 p=root/rel;dest=out/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
 a=(out/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 dest=out/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
with urllib.request.urlopen('http://localhost:3003/book-review/doc/book/iterations/2026-09-24-colour-review-comments/index.html',timeout=20) as response:
 assert response.status==200 and b'from inside the museum' in response.read()
print(json.dumps(report,indent=2))
