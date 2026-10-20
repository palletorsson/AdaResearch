from pathlib import Path
import re,json,hashlib,subprocess,shutil,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-morphogenesis-who-connected-the-controls';S=R/'doc/book/studies/soft-bodies-through-the-hands/Topology_Entropy_Morphogenesis'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps'/S.name/'tutorial.md').read_text(encoding='utf8'),re.S)
assert len(blocks)==2
for folder in ['printed','variation','fault-cut','fault-coupled','fault-seed','fault-recipient']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  if name=='recipe.gd':
   if folder=='variation':source=source.replace('CUT_SPAN := 0.15','CUT_SPAN := 0.30')
   if folder=='fault-cut':source=source.replace('CUT_SPAN * (2.0 * t - 1.0)','CUT_SPAN * t')
   if folder=='fault-coupled':source=source.replace('var n := s if choice == 0 or choice == 2 else 0.3','var n := s')
   if folder=='fault-seed':source=source.replace('generator.noise.seed = 1337','generator.noise.seed = 1337 + side')
   if folder=='fault-recipient':source=source.replace('assign(generators[1], recipe(preview, mode))','assign(generators[0], recipe(preview, mode))')
  (O/folder/name).write_bytes((source+'\n').encode())
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
assert (S/'point_body.gd').read_bytes()==(S.parent/'ProceduralGeneration_Reaction_Diffusion_Systems/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps({name:hashlib.sha256((S/name).read_bytes()).hexdigest() for name,_ in blocks},indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--rendering-method','gl_compatibility','--path',str(R),'--xr-mode','off','--script','res://tools/probes/morphogenesis_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-35:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
r=json.loads(receipt.read_text());assert r['passed'],r['failures'];print(len(r['checks']),'code checks passed')
