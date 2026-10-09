from pathlib import Path
import json,hashlib
base=Path(__file__).parent
rows=[]
for folder,name in [('rejected-replay-1','gravity'),('before','gravity'),('after','gravity'),('arena-before','arena'),('arena-after','arena'),('arena-after-clean','arena')]:
 run=json.loads((base/folder/(name+'-run.json')).read_text(encoding='utf-8'))
 report_path=base/folder/(name+'_relations_probe.json')
 report=json.loads(report_path.read_text(encoding='utf-8')) if report_path.exists() else {}
 row={'folder':folder,'pid':run['pid'],'returncode':run['returncode'],'seconds':run['seconds'],
      'recorded_checks':report.get('checks'),'recorded_failures':report.get('failures'),
      'watched_sources_stable':run['source_sha256_before']==run['source_sha256_after'],
      'clean_process_pass':run['returncode']==0 and report.get('checks',0)>0 and not report.get('failures')}
 if name=='arena':
  row['authored_placement_count']=sum(report['inventory']['expected'].values())
  row['instantiated_authored_placement_count']=len(report['inventory']['placements'])
  row['missing_tokens']=report['inventory']['missing']
 rows.append(row)
(base/'runtime-summary.json').write_text(json.dumps(rows,indent=2),encoding='utf-8')
hashes={str(p.relative_to(base)).replace('\\','/'):hashlib.sha256(p.read_bytes()).hexdigest() for p in base.rglob('*') if p.is_file() and p.name!='evidence-sha256.json'}
(base/'evidence-sha256.json').write_text(json.dumps(hashes,indent=2),encoding='utf-8')
print(json.dumps([{k:r[k] for k in ['folder','returncode','recorded_checks','clean_process_pass']} for r in rows],indent=2))
