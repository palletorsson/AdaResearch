"""Fresh seven-hall exact printed-code regression; preserve original hall receipts."""
from pathlib import Path
from datetime import datetime, timezone
import hashlib, json, re, runpy

R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-procedural-generation-complete-readings'
CASES=[
 ('PG_Genetic_Evolution','evolution_score','evolution_score_lesson','evolution-what-the-score-reads'),
 ('PG_Space_Colonization','colonization_answer','colonization_answer_lesson','colonization-who-can-answer'),
 ('PG_Branching_Growth','branching_place','branching_place_lesson','branching-record-and-place'),
 ('PG_Percolation_Network','percolation_contact','percolation_contact_lesson','percolation-a-contact-rule'),
 ('PG_Caves_Mazes','caves_room','caves_room_lesson','caves-a-route-needs-room'),
 ('PG_Sculpted_Forms','sculpted_sample','sculpted_sample_lesson','sculpted-what-the-centres-keep'),
 ('PG_Mirrored_Patterns','mirrored_copy','mirrored_copy_lesson','mirrored-a-copy-kept')]
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def dump(p,v):p.write_text(json.dumps(v,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')

def main():
 O.mkdir(parents=True,exist_ok=True)
 stamp=datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%S%fZ')
 run=O/'runtime'/stamp;run.mkdir(parents=True)
 sequence=R/'commons/maps/sequences/proceduralgeneration.json'
 order=json.loads(sequence.read_text(encoding='utf-8'))['sequences']['proceduralgeneration']['maps']
 assert order==[c[0] for c in CASES]
 entries=[]
 for key,test,probe,prior in CASES:
  d=run/key;d.mkdir()
  hashes={}
  for kind in ['tutorial','final']:
   p=R/'commons/maps'/key/(kind+'.md');(d/p.name).write_bytes(p.read_bytes());hashes[p.relative_to(R).as_posix()]=sha(p)
  marked=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(d/'tutorial.md').read_text(encoding='utf-8'),re.S)
  files={name:hashlib.sha256((code+'\n').encode()).hexdigest() for name,code in marked}
  for name,code in marked:
   assert '$' not in code
   for dep in re.findall(r'preload\("([^\"]+)"\)',code):assert dep in files or dep.startswith('res://'),(key,name,dep)
  old='doc/book/iterations/2026-10-09-'+prior;new=d.relative_to(R).as_posix()
  testpath=R/'tools'/('test_'+test+'.py');probepath=R/'tools/probes'/(probe+'.gd')
  code=testpath.read_text(encoding='utf-8').replace('Path(__file__).resolve().parents[1]','Path('+repr(R.as_posix())+')').replace(old,new).replace('res://tools/probes/'+probe+'.gd','res://'+new+'/run.gd')
  (d/'run.py').write_text(code,encoding='utf-8')
  (d/'run.gd').write_text(probepath.read_text(encoding='utf-8').replace(old,new),encoding='utf-8')
  entries.append({'map':key,'directory':d.relative_to(O).as_posix(),'sources':hashes,'printed':files,
    'harness':testpath.relative_to(R).as_posix(),'harness_sha256':sha(testpath),'probe':probepath.relative_to(R).as_posix(),'probe_sha256':sha(probepath)})
 manifest={'date_utc':stamp,'sequence_sha256':sha(sequence),'scope':'Fresh author-led native regression of exact printed programs, guided edits, faulty variants and supplied XRTools poses. Existing assertion suites reused; no new whole-museum traversal or independent student claim.','halls':entries}
 dump(run/'manifest.json',manifest)
 dump(O/'latest-run.json',{'directory':run.relative_to(O).as_posix(),'complete':False})
 results=[]
 for entry in entries:
  d=O/entry['directory'];print('RUN '+entry['map'],flush=True)
  try:
   runpy.run_path(str(d/'run.py'),run_name='__main__')
   receipt=json.loads((d/'checks.json').read_text());assert receipt['passed']
   for name,digest in entry['printed'].items():assert sha(d/'printed'/name)==digest
   result={'map':entry['map'],'passed':True,'checks':len(receipt['checks']),'receipt':(d/'checks.json').relative_to(O).as_posix()}
  except Exception as e:result={'map':entry['map'],'passed':False,'error':repr(e)}
  results.append(result);dump(run/'results.json',{'complete':len(results)==7,'passed':all(x['passed'] for x in results),'halls':results})
  print(json.dumps(result),flush=True)
 for entry in entries:
  for path,digest in entry['sources'].items():assert sha(R/path)==digest,('changed during test',path)
 assert sha(sequence)==manifest['sequence_sha256']
 passed=all(x['passed'] for x in results)
 dump(O/'latest-run.json',{'directory':run.relative_to(O).as_posix(),'complete':True,'passed':passed})
 print(json.dumps({'passed':passed,'checks':sum(x.get('checks',0) for x in results),'files':sum(len(e['printed']) for e in entries),'run':str(run)}),flush=True)
 if not passed:raise SystemExit(1)
if __name__=='__main__':main()
