from pathlib import Path
import json,urllib.request,hashlib,collections,difflib
root=Path.cwd();out=root/'doc/book/iterations/2026-09-24-transformation-review-comments'
D=json.loads((out/'decisions.json').read_text(encoding='utf-8'));verification=json.loads((out/'verification.json').read_text(encoding='utf-8'));assert all(c['passed'] for c in verification['checks'])
api='http://localhost:3003/api/book-tasks'
def read_goal():
 with urllib.request.urlopen(api,timeout=20) as r:data=json.load(r)
 return next(g for g in data['goals'] if g['goal_id']=='book_transformation')
goal=read_goal();original={t['id']:t for t in goal['tasks']}
other={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (root/'doc/tasks').glob('book_*.json') if p.name!='book_transformation.json'}
(out/'queue-before-update.json').write_text(json.dumps(goal,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
for task_id,d in D.items():
 # Re-read current canonical notes immediately before updating each item.
 live=json.loads((root/'doc/tasks/book_transformation.json').read_text(encoding='utf-8-sig'))
 task=next(t for t in live['tasks'] if t['id']==task_id);original[task_id]=task;old=task.get('notes','')
 marker='Codex review — 24 September 2026\n'+d['decision']
 note=(old+'\n\n' if old else '')+marker+'\n\nDetails and exact diffs: /book-review/doc/book/iterations/2026-09-24-transformation-review-comments/index.html'
 assert len(note)<4000
 payload={'goal_id':'book_transformation','task_id':task_id,'triage':d['triage'],'status':d['status'],'notes':note,'claimed_by':'codex'}
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
entry='''

**24 September — Transformation review comments.** Continued the review queue after Primitives. [16 resolved comments and exact differences](2026-09-24-transformation-review-comments/index.html) · [live queue](http://localhost:3003/book-tasks/review?seq=transformation&map=Trans_Introduction). Seven mature halls received targeted reading corrections; code excerpts, encounter anchors and critical arguments preserved. Three duplicate pairs cover the same repairs (13 distinct findings). Removed all 28 obsolete Trans_Pit fire utilities, including the middle and side observation floor; all other grid cells and artifacts unchanged. Updated current companion notes while retaining historical drafts. Added the existing fixed-camera bank pair to Introduction; replaced the stale grower figure with two new native photographs. Four unmodified PNGs have stable book paths and provenance. Isolated production Godot passed 72 checks with exit 0, including 21 floor rays, three observation walks and the original grower/door study. Not headset or learner acceptance. All 134 preservation/publication checks passed. Original reviewer fields and author notes retained; other 23 queue files unchanged. Seven canonical final.md hashes and current Transformation capture refreshed; concurrent room metadata preserved. Active museum bake not replaced; source map changes require hall rebuild. Next in the review queue: Array. Earlier sequential writing remains paused at Kinetic Forces.
'''
p.write_text(first+entry+rest,encoding='utf-8')
changes=json.loads((out/'changed-files.json').read_text(encoding='utf-8'))
for rel in ['doc/tasks/book_transformation.json','doc/book/iterations/WORKING.md']:
 if rel not in changes:changes.append(rel)
 p=root/rel;dest=out/'after'/rel;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(p.read_bytes())
 a=(out/'before'/rel).read_text(encoding='utf-8-sig');b=p.read_text(encoding='utf-8-sig')
 dest=out/'diffs'/(rel+'.diff');dest.parent.mkdir(parents=True,exist_ok=True);dest.write_text(''.join(difflib.unified_diff(a.splitlines(True),b.splitlines(True),fromfile='before/'+rel,tofile=rel)),encoding='utf-8')
(out/'changed-files.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
with urllib.request.urlopen('http://localhost:3003/book-review/doc/book/iterations/2026-09-24-transformation-review-comments/index.html',timeout=20) as r:
 assert r.status==200 and b'Transformation' in r.read()
print(json.dumps(report,indent=2))
