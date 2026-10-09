from pathlib import Path
import json,urllib.request,hashlib
from concurrent.futures import ThreadPoolExecutor

H=Path(__file__).resolve().parent
R=H.parents[3]
M='SpeculativeComputation_Rhizome_Network'
p=R/'doc/book/iterations/WORKING.md'
t=p.read_text(encoding='utf-8')
old=next(v for v in t.split('\n\n') if v.startswith('**Completed:**'))
new='''**Completed:** [Rhizome Network](2026-09-20-rhizome-review/SUMMARY.md). Its enlarged grower now holds the same sampled points while LINKS compares one and three earlier neighbours. NODE exposes birth order and degree; CUT temporarily removes a point and its incident links, and REPLAY retains the sample sequence. The captured cut splits the one-link forest from two components into four; the same cut under three links leaves one component. The manuscript preserves no-root versus equal-influence and distinguishes surviving a loss from repair and restoration. Four central platform cells become floor, spawn faces the encounter and a dressing exclusion clears the exit approach. Both authored artifacts remain and instantiate. 36 runtime checks, seven walking segments and 81 content checks pass; Godot exits 0. Six actual states and exact diffs are published. Headset, Quest, cave traversal and learner verification remain open. No live restart, live bake replacement or commit.

Earlier [Collective Knowledge](2026-09-20-collective-review/SUMMARY.md) remains intact: sources survive geometric revision, dispute does not automatically settle, and current/lifetime counts remain distinct. Its 39 runtime checks, seven selected walking segments, 79 content checks and six views remain the evidence. Supporting lookup restoration remains a separate task.'''
t=t.replace(old,new)
old=next(v for v in t.split('\n\n') if v.startswith('**Next bounded pass:'))
t=t.replace(old,'**Next bounded pass: Post-Crisis — AdvancedLaboratory_Lab_Equipment_Simulation.** Read the assembly manuscript and MolecularDesigner source. Which bodies does its catalogue permit, and where is the target arrangement decided? Preserve mature work, then strengthen the encounter where a useful comparison is missing. Only this hall and PostCrisis_Synthesis remain in this pass through the spine. Both retain their pre-pass maps and manuscripts. Keep the QFEP/Self-Q distinction between a score, its observable and authority to revise it.')
p.write_text(t,encoding='utf-8')
paths=[R/'doc/book/iterations/2026-09-19-review-comparison/index.html']+[H/n for n in ['SUMMARY.md','final.diff','content-checks.json',M+'-runtime.json']]+sorted(H.glob('rhizome-*.png'))
def verify(path):
 rel=path.relative_to(R).as_posix()
 url='http://localhost:3003/book-review/'+rel
 try:
  with urllib.request.urlopen(url,timeout=20) as response:
   body=response.read()
   return dict(path=rel,status=response.status,bytes=len(body),identical=body==path.read_bytes(),sha256=hashlib.sha256(body).hexdigest())
 except Exception as e:return dict(path=rel,error=str(e),identical=False)
with ThreadPoolExecutor(max_workers=4) as pool: results=list(pool.map(verify,paths))
(H/'http-checks.json').write_text(json.dumps(results,indent=2)+'\n',encoding='utf-8')
print(json.dumps({'resources':len(results),'all_identical':all(v['identical'] for v in results),'failures':[v for v in results if not v['identical']]}))
raise SystemExit(not all(v['identical'] for v in results))
