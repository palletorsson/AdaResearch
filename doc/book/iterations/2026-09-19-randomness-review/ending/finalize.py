from pathlib import Path
import json,hashlib,difflib,re,subprocess
B=Path(__file__).parent
OWN=[
 'algorithms/randomness/perlin_noise_bridge/perlin_noise_bridge.gd',
 'commons/artifacts/noise_mixer/noise_mixer.gd',
 'algorithms/randomness/monte_carlo_dartboard/monte_carlo_dartboard.gd',
 'algorithms/randomness/proceduralrandomness/particlerandomness/extrem_randomness.gd',
 'algorithms/randomness/pheromone_terrain/pheromone_terrain.gd']
sha=lambda b:hashlib.sha256(b).hexdigest()
changes=[]
for s in OWN:
 old=(B/'before-source'/s).read_bytes();new=Path(s).read_bytes()
 dest=B/'after-source'/s;dest.parent.mkdir(parents=True,exist_ok=True);dest.write_bytes(new)
 diff=''.join(difflib.unified_diff(old.decode().splitlines(True),new.decode().splitlines(True),fromfile='before/'+s,tofile='after/'+s))
 dp=B/'diffs'/(Path(s).stem+'.diff');dp.parent.mkdir(exist_ok=True);dp.write_text(diff,encoding='utf-8')
 changes.append({'path':s,'before_sha256':sha(old),'after_sha256':sha(new),'diff':str(dp).replace('\\','/'),'after_snapshot':str(dest).replace('\\','/')})
(B/'changes.json').write_text(json.dumps(changes,indent=2),encoding='utf-8')
def uncomment(s):
 return '\n'.join(l for l in s.splitlines() if l.strip() and not l.lstrip().startswith('#'))
identity={s:uncomment((B/'before-source'/s).read_text(encoding='utf-8'))==uncomment(Path(s).read_text(encoding='utf-8')) for s in OWN[:3]}
def body(s,name):
 m=re.search(r'^func '+name+r'\(.*?(?=^func |\Z)',s,re.S|re.M)
 return uncomment(re.sub(r'""".*?"""','',m.group(),flags=re.S))
p=OWN[-1];old=(B/'before-source'/p).read_text(encoding='utf-8');new=Path(p).read_text(encoding='utf-8')
core={n:body(old,n)==body(new,n) for n in ['_decay_pheromones','_walk_step','_choose_next_position','_initialize_grids','_create_walkers','_update_mesh']}
runs=[]
for rp in sorted(B.glob('*/*/run.json')):
 d=json.loads(rp.read_text(encoding='utf-8'));out=rp.parent;result={}
 for n in ['focused.json','museum.json','feasibility.json']:
  if (out/n).exists():result=json.loads((out/n).read_text(encoding='utf-8'));break
 checks=result.get('checks',[])
 runs.append({'path':str(out).replace('\\','/'),'returncode':d['returncode'],'checks':len(checks),'passed':sum(c['ok'] for c in checks),'failed':[c['message'] for c in checks if not c['ok']],'seconds':d['seconds'],'watched_inputs_stable':d['source_sha256_before']==d['source_sha256_after'],'current_accepted':out.parent.name in ['lifecycle','verified']})
(B/'runtime-summary.json').write_text(json.dumps(runs,indent=2),encoding='utf-8')
cp=subprocess.run(['git','-c','safe.directory='+str(Path.cwd()).replace('\\','/'),'diff','--check','--',*OWN],capture_output=True,text=True)
verify={'owned_files':len(OWN),'identity_only_files_have_identical_noncomment_code':identity,'existing_pheromone_core_functions_identical_ignoring_comments_docstrings':core,'git_diff_check_returncode':cp.returncode,'git_diff_check_output':cp.stdout+cp.stderr,'owned_hashes_match_after_snapshot':all(sha(Path(c['path']).read_bytes())==c['after_sha256'] for c in changes),'headset_tested':False,'complete_game_collision_playthrough':False}
(B/'verification.json').write_text(json.dumps(verify,indent=2),encoding='utf-8')
print(json.dumps({'changes':len(changes),'verification':verify,'runs':runs},indent=2))
