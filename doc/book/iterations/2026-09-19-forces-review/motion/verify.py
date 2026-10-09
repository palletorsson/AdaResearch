from pathlib import Path
import json,hashlib,re,difflib,collections
ROOT=Path.cwd();BASE=Path(__file__).resolve().parent
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
read=lambda p:json.loads(p.read_text(encoding='utf8'))
checks={}
def check(name,ok):
 checks[name]=bool(ok)
 if not ok:raise AssertionError(name)
maps=['VFM_03_Motion','Vectors_Act3_FieldsAndMotion','Vectors_Act4a_KineticForces','Vectors_Act4b_Oscillation','Change_Choreography']
for m in maps:
 rel=Path('commons/maps')/m
 check(m+' final byte unchanged',(ROOT/rel/'final.md').read_bytes()==(BASE/'before-source'/rel/'final.md').read_bytes())
 old=read(BASE/'before-source'/rel/'map_data.json');new=read(ROOT/rel/'map_data.json')
 if m!='Vectors_Act4a_KineticForces':check(m+' all map layers unchanged',old['layers']==new['layers'])
 else:
  check('Kinetic other layers unchanged',all(old['layers'][k]==new['layers'][k] for k in old['layers'] if k!='interactables'))
  flat=lambda d:[v for row in d['layers']['interactables'] for v in row if v.strip()]
  check('Kinetic all8 full artifact tokens retained',collections.Counter(flat(old))==collections.Counter(flat(new)) and len(flat(new))==8)
  moves=[(x,z,a,b) for z,(r1,r2) in enumerate(zip(old['layers']['interactables'],new['layers']['interactables'])) for x,(a,b) in enumerate(zip(r1,r2)) if a!=b]
  check('Kinetic exactly4 changed cells',len(moves)==4)
  check('Kinetic requested layout',new['layers']['interactables'][24][9]=='force_mower' and new['layers']['interactables'][37][8].startswith('centrifuge_ring') and new['layers']['interactables'][37][21]=='sisyphus_mower')
src=Path('algorithms/vectors/10_vector_field_flow/field_receivers.gd')
a=(BASE/'before-source'/src).read_text(encoding='utf8');b=(ROOT/src).read_text(encoding='utf8')
def fn(s,name):return re.search(r'^func '+name+r'\(.*?(?=^func |\Z)',s,re.M|re.S).group()
for name in ['field_at','advance','reset_run','act','bank','refresh_field','draw_trails','update_markers']:
 check('Field '+name+' unchanged',fn(a,name)==fn(b,name))
runtime={}
for phase,name,file in [('preserved-headless','motion','motion_chamber_probe.json'),('preserved-headless','spring','restoring_forces_probe.json'),('preserved-headless','timing','timing_probe.json'),('before-field-final','field','field_receivers_probe.json'),('before-runtime','staging','staging-checks.json'),('after-field-final','field','field_receivers_probe.json'),('after-runtime','staging','staging-checks.json'),('after-headless','kinetic','kinetic_forces_probe.json')]:
 report=read(BASE/phase/file);run=read(BASE/phase/(name+'-run.json'))
 check(phase+'/'+name+' passed',not report['failures'] and run['returncode']==0)
 check(phase+'/'+name+' source stable during run',run['source_sha256_before']==run['source_sha256_after'])
 runtime[phase+'/'+name]={'checks':report['checks'],'failures':report['failures'],'returncode':run['returncode']}
for suffix in ['kinetic-plan','kinetic-approach','field-observe','field-rule']:
 before_phase,after_phase=('before-field-final','after-field-final') if suffix.startswith('field') else ('before-runtime','after-runtime')
 check(suffix+' camera and model state match',read(BASE/before_phase/(suffix+'-camera.json'))==read(BASE/after_phase/(suffix+'-camera.json')))
for name in ['field','staging']:
 before_phase,after_phase=('before-field-final','after-field-final') if name=='field' else ('before-runtime','after-runtime')
 before=read(BASE/before_phase/(name+'-run.json'));after=read(BASE/after_phase/(name+'-run.json'))
 for shared in ['commons/scenes/endless_museum.gd','commons/scenes/em/em_detail.gd']:
  check(name+' paired '+shared+' identical',before['source_sha256_after'][shared]==after['source_sha256_before'][shared])
images={str(p.relative_to(BASE)):sha(p) for phase in ['before-runtime','after-runtime','before-field-final','after-field-final'] for p in (BASE/phase).glob('*.png')}
result={'checks':checks,'runtime':runtime,'images_sha256':images,'headset_tested':False,'learner_verified':False}
(BASE/'verification.json').write_text(json.dumps(result,indent=2),encoding='utf8');print(json.dumps({'checks':len(checks),'all_pass':all(checks.values()),'runtime':runtime},indent=2))
