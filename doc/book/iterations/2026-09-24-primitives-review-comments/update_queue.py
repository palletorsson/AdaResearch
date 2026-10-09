from pathlib import Path
import json,urllib.request,hashlib,collections,datetime
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-primitives-review-comments'
D=json.loads((out/'decisions.json').read_text(encoding='utf-8'))
verification=json.loads((out/'verification.json').read_text(encoding='utf-8'))
assert all(c['passed'] for c in verification['checks'])
api='http://localhost:3003/api/book-tasks'
with urllib.request.urlopen(api,timeout=20) as r: data=json.load(r)
goal=next(g for g in data['goals'] if g['goal_id']=='book_primitives')
original={t['id']:t for t in goal['tasks']}
other={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'doc/tasks').glob('book_*.json') if p.name!='book_primitives.json'}
# Save the exact current state before touching review statuses.
(out/'queue-before-update.json').write_text(json.dumps(goal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for task_id,d in D.items():
 old=original[task_id].get('notes','')
 note=(old+'\n\n' if old else '')+'Codex review — 24 September 2026\n'+d['decision']+'\n\nDetails and exact diffs: /book-review/doc/book/iterations/2026-09-24-primitives-review-comments/index.html'
 payload={'goal_id':'book_primitives','task_id':task_id,'triage':d['triage'],'status':d['status'],'notes':note}
 if d['status']=='done':payload['claimed_by']='codex'
 request=urllib.request.Request(api,data=json.dumps(payload,ensure_ascii=False).encode('utf-8'),headers={'Content-Type':'application/json'},method='PATCH')
 with urllib.request.urlopen(request,timeout=20) as r:
  result=json.load(r)['task'];assert result['id']==task_id and result['status']==d['status']
with urllib.request.urlopen(api,timeout=20) as r:data=json.load(r)
current=next(g for g in data['goals'] if g['goal_id']=='book_primitives')
allowed={'notes','status','triage','triaged_at','done_at','claimed_by','updated_at'}
for t in current['tasks']:
 old=original[t['id']]
 assert {k:v for k,v in t.items() if k not in allowed}=={k:v for k,v in old.items() if k not in allowed},t['id']
 if old.get('notes'):assert t['notes'].startswith(old['notes']+'\n\n')
 assert t['status']==D[t['id']]['status']
changes=json.loads((out/'changed-files.json').read_text(encoding='utf-8'));rel='doc/tasks/book_primitives.json'
if rel not in changes:changes.append(rel)
p=root/'doc/book/iterations/WORKING.md';s=p.read_text(encoding='utf-8-sig');first,rest=s.split('\n',1)
entry='''

**24 September — Primitives review comments.** Author chose the annotated comments and Primitives first. [Live review queue](http://localhost:3003/book-tasks/review?seq=primitives&map=Point_One) · [41 decisions and exact text differences](2026-09-24-primitives-review-comments/index.html). 36 items resolved (including duplicates/author decisions), 3 broad rewrites declined, 2 follow-ups open: native three-recorder Trace illustration and publication commit. Original author notes and review claims preserved. Retained the shared arrival, secondary Fontana point and four filmed line studies; made targeted canonical prose fixes, restored the triangle plate marker, and gave six native figures stable byte-identical publication copies. Sequence content now matches its ten maps. Added numeric discovery handling to the grid parser; moved Achilles from (5,5) to (8,8), clear of the ring panel. Twenty production-code assertions pass; Godot then crashes on teardown (3221225477), so this is no clean process-exit/full-room/headset claim. Source-map change requires hall rebuild; no active bake replacement, restart or commit. Ten manuscript hashes and the current Primitives capture refreshed. Concurrent Randomness metadata preserved. Earlier sequential writing paused at Kinetic Forces when the user redirected to the review queue.
'''
p.write_text(first+entry+rest,encoding='utf-8');rel='doc/book/iterations/WORKING.md'
if rel not in changes:changes.append(rel)
(out/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
for rel in ['doc/tasks/book_primitives.json','doc/book/iterations/WORKING.md']:
 dest=out/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes((root/rel).read_bytes())
counts=dict(collections.Counter(t['status'] for t in current['tasks']))
report={'counts':counts,'original_comments_and_author_notes_preserved':True,'review_fields_changed_only':True,'other_queue_files_unchanged':all(hashlib.sha256((root/'doc/tasks'/name).read_bytes()).hexdigest()==h for name,h in other.items())}
(out/'queue-verification.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
print(json.dumps(report,indent=2))
