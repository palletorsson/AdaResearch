from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-matching-room-for-two';S=R/'doc/book/studies/graphs-through-the-hands/GT_Matching'
t=(R/'commons/maps/GT_Matching/tutorial.md').read_text(encoding='utf8');blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',t,re.S)
assert len(blocks)==5;hashes={}
for folder in ['printed','variation','fault-direction','fault-occupied','fault-parity']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='matching_model.gd':
   if folder=='variation':source=source.replace('[[0, 2], [0, 3], [1, 2]]','[[0, 2], [1, 3], [1, 2]]')
   if folder=='fault-direction':source=source.replace('neighbours[b].append(a)','pass # no path through an occupied tool')
   if folder=='fault-occupied':source=source.replace('mate[a] == -1 and mate[b] == -1','mate[a] == -1 or mate[b] == -1')
   if folder=='fault-parity':source=source.replace('range(0, path.size() - 1, 2)','range(1, path.size() - 1, 2)')
  (O/folder/name).write_text(source+'\n',encoding='utf8')
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
for name in ['point_body.gd','route.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Flow'/name).read_bytes()
# A source ledger is verifiable independently of the spatial display.
a=json.loads((R/'commons/artifacts/ada_relations/data.json').read_text(encoding='utf8'))
for rel,h in a['source_hashes'].items():assert hashlib.sha256((R/rel).read_bytes()).hexdigest()==h,rel
spine=json.loads((R/'commons/maps/curriculum_spine.json').read_text(encoding='utf8'))['spine']['sequences']
assert [n['id'] for n in a['nodes']]==[s['name'] for s in sorted(spine,key=lambda x:x['order'])]
assert len(a['nodes'])==25 and sum(len(n['maps']) for n in a['nodes'])==206
walk=[e for e in a['edges'] if e['kind']=='walk'];assert [(e['a'],e['b']) for e in walk]==[(a['nodes'][i]['id'],a['nodes'][i+1]['id']) for i in range(24)]
plan=json.loads((R/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf8'));lessons={x['id']:x for x in plan['lessons']}
for edge in a['edges']:
 for proof in edge['evidence']:
  if edge['kind']=='dependency':assert proof['from'] in lessons[proof['to']]['dependsOn']
  elif edge['kind']=='concept':assert any(x['title']==proof['topic'] and x['first']==proof['from'] and proof['to'] in x['returns'] for x in plan['topics'])
  elif edge['kind']=='shared':
   for appearance in proof['appearances']:
    md=json.loads((R/appearance['source']).read_text(encoding='utf8'));assert any(re.split('[:#]',v.strip())[0]==proof['token'] for row in md['layers']['interactables'] for v in row if isinstance(v,str) and v.strip())
for h in a['history']:assert (R/h['source']).is_dir() and Path(h['source']).name.startswith(h['date'])
receipt=O/'checks.json'
if receipt.exists():shutil.copyfile(receipt,O/'previous-checks.json');receipt.unlink()
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/graph_matching_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-45:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(started=started,finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(t.encode()).hexdigest(),carried_files_unchanged=True,atlas_sources_verified=True,atlas_data_sha256=hashlib.sha256((R/'commons/artifacts/ada_relations/data.json').read_bytes()).hexdigest(),fresh_engine_run=True)
receipt.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8');print(len(d['checks']),'checks passed; atlas evidence and source hashes verified')
