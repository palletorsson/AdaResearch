from pathlib import Path
import hashlib,json,difflib
base=Path(__file__).parent
root=Path.cwd()
owned=[
 'commons/artifacts/orbital_mechanics_demo/gravity_relations.gd',
 'commons/hazards/octapod_crawler/four_leg_critter.gd',
 'commons/artifacts/vector_machine/vector_machine.gd',
 'commons/artifacts/force_field_zone/force_field_zone.gd']
def sha(p):return hashlib.sha256(p.read_bytes()).hexdigest()
def code(s):return '\n'.join(x for x in s.splitlines() if x.strip() and not x.lstrip().startswith('#'))
manifest={'files':{},'checks':{}}
for rel in owned:
 b=base/'before-source'/rel
 a=root/rel
 before=b.read_text(encoding='utf-8')
 after=a.read_text(encoding='utf-8')
 out=base/'after-source'/rel
 out.parent.mkdir(parents=True,exist_ok=True)
 out.write_bytes(a.read_bytes())
 manifest['files'][rel]={'before_sha256':sha(b),'after_sha256':sha(a)}
 (base/(Path(rel).stem+'.diff')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='before/'+rel,tofile='after/'+rel)),encoding='utf-8')
 if rel.endswith('gravity_relations.gd'):
  # update_text is the final function; all dynamics and geometry precede it.
  ok=before.split('func update_text()')[0]==after.split('func update_text()')[0]
  manifest['checks']['gravity_outside_update_text_unchanged']=ok
 else:
  ok=code(before)==code(after)
  manifest['checks'][Path(rel).stem+'_executable_lines_unchanged']=ok
 assert ok,rel
for phase in ['before','after']:
 run=json.loads((base/phase/'gravity-run.json').read_text(encoding='utf-8'))
 report=json.loads((base/phase/'gravity_relations_probe.json').read_text(encoding='utf-8'))
 ok=run['returncode']==0 and not report['failures'] and run['source_sha256_before']==run['source_sha256_after']
 assert ok,phase
 manifest['checks'][phase+'_gravity_58_checks_stable']=ok
manifest['checks']['paired_overview_cameras_identical']=(base/'before/orbit-initial-camera.json').read_bytes()==(base/'after/orbit-initial-camera.json').read_bytes()
assert manifest['checks']['paired_overview_cameras_identical']
manifest['checks']['four_second_measurement_identical']=json.loads((base/'before/gravity_relations_probe.json').read_text())['measurement']==json.loads((base/'after/gravity_relations_probe.json').read_text())['measurement']
assert manifest['checks']['four_second_measurement_identical']
(base/'changes.json').write_text(json.dumps(manifest,indent=2),encoding='utf-8')
read_paths=json.loads((base/'before-source-sha256.json').read_text(encoding='utf-8'))
(base/'after-source-sha256.json').write_text(json.dumps({rel:sha(root/rel) for rel in read_paths},indent=2),encoding='utf-8')
print(json.dumps(manifest['checks'],indent=2))
