from pathlib import Path
import json,urllib.request,hashlib,collections,difflib
root=Path.cwd();out=root/'doc/book/iterations/2026-09-25-change-review-comments'
D=json.loads((out/'decisions.json').read_text(encoding='utf-8'));verification=json.loads((out/'verification.json').read_text(encoding='utf-8'));assert all(c['passed'] for c in verification['checks'])
api='http://localhost:3003/api/book-tasks'
def read_goal():
 with urllib.request.urlopen(api,timeout=20) as r:data=json.load(r)
 return next(g for g in data['goals'] if g['goal_id']=='book_change')
goal=read_goal();original={t['id']:t for t in goal['tasks']}
other={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'doc/tasks').glob('book_*.json') if p.name!='book_change.json'}
(out/'queue-before-update.json').write_text(json.dumps(goal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for task_id,d in D.items():
 # Re-read current canonical notes immediately before updating each item.
 live=json.loads((root/'doc/tasks/book_change.json').read_text(encoding='utf-8-sig'))
 task=next(t for t in live['tasks'] if t['id']==task_id);original[task_id]=task;old=task.get('notes','')
 marker='Codex review — 25 September 2026\n'+d['decision']
 note=(old+'\n\n' if old else '')+marker+'\n\nDetails and exact diffs: /book-review/doc/book/iterations/2026-09-25-change-review-comments/index.html'
 assert len(note)<4000
 payload={'goal_id':'book_change','task_id':task_id,'triage':d['triage'],'status':d['status'],'notes':note,'claimed_by':'codex'}
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

**25 September — Change review comments, with native museum photographs.** [Read the comparison](2026-09-25-change-review-comments/index.html) · [live queue](http://localhost:3003/book-tasks/review?seq=change). Eleven comments resolved; the console-readability headset check stays open. Two canonical final.md chapters now locate the slope plot above the curve and FIELD HELD beyond the canvas, name Point_Lines and the three sampling choices, follow the bridge into the field and reserve the persistent push for later in Forces. Existing supporting works return as invitations to compare; no artifact or role removed. The review's arrow-length-equals-speed sentence was amended: the source uses change per track angle, scaling and a clamp, not speed-calibrated length. The Tiling clock concern was already fixed in the preceding pass. Three unmodified native museum photographs enter final.md; exact text diffs, same-camera interval pair, held/live sums, field boundary strokes and console views are published. 15 intro + 12 flow native checks pass, exit 0, no GDScript errors; existing renderer/UID/registry warnings retained. The initial distant field overview is preserved; a closer standing side view shows the trails without changing the room. No headset legibility, reach, comfort or performance acceptance claimed. Both chapters' other .md files, code excerpts, anchors, map bytes and sequence retained. Current Change capture refreshed; unrelated shared core records and queue comments preserved. Next review sequence: Forces. Parallel Noise work is independent and remains intact.
"""
p.write_text(first+entry+rest,encoding='utf-8')
changes=json.loads((out/'changed-files.json').read_text(encoding='utf-8'))
for rel in ['doc/tasks/book_change.json','doc/book/iterations/WORKING.md']:
 if rel not in changes:changes.append(rel)
 p=root/rel;dest=out/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
 a=(out/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 dest=out/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
with urllib.request.urlopen('http://localhost:3003/book-review/doc/book/iterations/2026-09-25-change-review-comments/index.html',timeout=20) as response:
 assert response.status==200 and b'What a reading keeps' in response.read()
print(json.dumps(report,indent=2))
