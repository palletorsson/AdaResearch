from pathlib import Path
import json,hashlib,difflib,shutil,re
BASE=Path('doc/book/iterations/2026-09-19-wavefunctions-review/ending')
sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
halls=['WaveFunctions_AirMusic','Wavefunctions_Sky_Stairs','WaveFunctions_TrigWalkingPath','WaveFunctions_Synthesis_Lab']
sources=['algorithms/wavefunctions/resonance/ResonatingMetallophone.gd','algorithms/wavefunctions/resonance/ResonatingBar.gd','algorithms/wavefunctions/beat_frequency/beat_frequency_demo.gd','algorithms/wavefunctions/sine_cylinder_staircase/sine_cylinder_staircase.gd','algorithms/wavefunctions/oscillation_driver/TrigWalkingPath.gd','commons/artifacts/additive_wave_demo/additive_wave_demo.gd']
candidates=[Path(p) for p in sources]
for h in halls:
 candidates+=list((Path('commons/maps')/h).glob('*.md'))+[Path('commons/maps')/h/'map_data.json']
changes=[]
for p in candidates:
 if p.name=='final.md':continue
 before=BASE/'before-source'/p
 if not before.exists() or before.read_bytes()==p.read_bytes():continue
 after=BASE/'after-source'/p;after.parent.mkdir(parents=True,exist_ok=True);shutil.copy2(p,after)
 diff=BASE/'diffs'/Path(p.as_posix()+'.diff');diff.parent.mkdir(parents=True,exist_ok=True)
 diff.write_text(''.join(difflib.unified_diff(before.read_text(encoding='utf-8').splitlines(True),p.read_text(encoding='utf-8').splitlines(True),fromfile='before/'+p.as_posix(),tofile='after/'+p.as_posix())),encoding='utf-8')
 changes.append({'path':p.as_posix(),'owner':'root applied opt-in token; ending evidence' if p.as_posix()=='commons/maps/WaveFunctions_Synthesis_Lab/map_data.json' else 'ending','before_sha256':sha(before),'after_sha256':sha(p),'diff':diff.relative_to(BASE).as_posix()})
(BASE/'changes.json').write_text(json.dumps(changes,indent=2)+'\n',encoding='utf-8')
verification={'owned_live_hashes_match':all(sha(Path(c['path']))==c['after_sha256'] for c in changes),'maps':{},'archived_designs_preserved':{},'identity_edits_comment_only':{},'same_camera':{},'actual_museum_placed_cells':{}}
for h in halls:
 p=Path('commons/maps')/h/'map_data.json';old=json.loads((BASE/'before-source'/p).read_text(encoding='utf-8'));new=json.loads(p.read_text(encoding='utf-8'))
 tokens=lambda m:[{'cell':[x,z],'token':s} for z,row in enumerate(m['layers']['interactables'])for x,s in enumerate(row)if isinstance(s,str)and s.strip()]
 a,b=tokens(old),tokens(new);changed=[]
 for rowa,rowb in zip(a,b):
  if rowa!=rowb:changed.append({'before':rowa,'after':rowb})
 other_layers={k:v for k,v in old['layers'].items()if k!='interactables'}=={k:v for k,v in new['layers'].items()if k!='interactables'}
 verification['maps'][h]={'before_count':len(a),'after_count':len(b),'same_cells':[v['cell'] for v in a]==[v['cell']for v in b],'same_keys':[re.split('[:#]',v['token'])[0]for v in a]==[re.split('[:#]',v['token'])[0]for v in b],'changed_tokens':changed,'other_layers_unchanged':other_layers}
for h in halls[1:3]:
 for name in ['intent.md','summary.md','technical.md','tutorial.md','critical.md']:
  p=Path('commons/maps')/h/name
  verification['archived_designs_preserved'][p.as_posix()]=p.read_bytes().endswith((BASE/'before-source'/p).read_bytes())
for s in sources[:-1]:
 # Every changed line is a comment, including inline comment text.
 def code(p):return [line.split('#',1)[0].rstrip() for line in p.read_text(encoding='utf-8').splitlines() if line.split('#',1)[0].strip()]
 verification['identity_edits_comment_only'][s]=code(Path(s))==code(BASE/'before-source'/s)
runs=[]
for phase in ['before','after']:
 for name in ['focused','museum']:
  folder=BASE/phase/name;run=json.loads((folder/'run.json').read_text(encoding='utf-8'));data=json.loads((folder/(name+'.json')).read_text(encoding='utf-8'))
  checks=data['checks'];log=(folder/'process.log').read_text(encoding='utf-8');runs.append({'phase':phase,'kind':name,'checks':len(checks),'passed':sum(c['ok']for c in checks),'failures':[c['message']for c in checks if not c['ok']],'returncode':run['returncode'],'seconds':run['seconds'],'stable_watched_sources':run['source_sha256_before']==run['source_sha256_after'],'script_errors':log.count('SCRIPT ERROR'),'shader_cache_errors':log.count('Condition "f.is_null()"'),'log':(folder/'process.log').relative_to(BASE).as_posix(),'scope':'isolated source/control/PCM checks; Dummy audio, not listening' if name=='focused' else 'actual museum one bench, pointer events, fixed standing camera, approach capsule; not whole hall traversal'})
  if name=='museum':
   cells=[v for v in data['inventory']if len(v['cell'])==2];verification['actual_museum_placed_cells'][phase]={'count':len(cells),'keys_and_cells':[{k:v[k]for k in ['key','cell']}for v in cells]}
for name in ['arrival','first-alone','restored']:
 verification['same_camera'][name]=(BASE/'before/museum'/f'{name}-camera.json').read_bytes()==(BASE/'after/museum'/f'{name}-camera.json').read_bytes()
verification['same_loaded_museum']=json.loads((BASE/'before/museum/museum.json').read_text(encoding='utf-8'))['loaded_museum_sha256']==json.loads((BASE/'after/museum/museum.json').read_text(encoding='utf-8'))['loaded_museum_sha256']
(BASE/'verification.json').write_text(json.dumps(verification,indent=2)+'\n',encoding='utf-8')
(BASE/'runtime-summary.json').write_text(json.dumps({'runs':runs,'retained_failure':'before/focused exit1: name-based membrane lookup counted only first duplicated BridgeCollider name. Corrected probe counts direct concave-shape bodies after queued scene children are freed; after/focused verifies79. No production geometry changed.','headset_tested':False,'heard_by_person':False,'stair_full_ascent_tested':False,'museum_bench_gpu':'matched before/after images; all25 authored Synthesis placements observed in edit records'},indent=2)+'\n',encoding='utf-8')
print(json.dumps({'changed_paths':len(changes),'counts':[v['after_count']for v in verification['maps'].values()],'hashes_match':verification['owned_live_hashes_match'],'comment_only':all(verification['identity_edits_comment_only'].values()),'same_camera':all(verification['same_camera'].values()),'archived_designs_preserved':all(verification['archived_designs_preserved'].values()),'museum_authored_counts':{k:v['count']for k,v in verification['actual_museum_placed_cells'].items()}}))
