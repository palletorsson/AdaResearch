from pathlib import Path
import re,json,hashlib,subprocess,shutil,datetime,sys
sys.stdout.reconfigure(encoding='utf8')
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-10-layout-the-same-connections';S=R/'doc/book/studies/graphs-through-the-hands/GT_Layout'
text=(R/'commons/maps/GT_Layout/tutorial.md').read_text(encoding='utf8')
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',text,re.S)
assert len(blocks)==4
hashes={}
for folder in ['printed','variation','fault-adjacency','fault-rods','fault-step']:
 (O/folder).mkdir(exist_ok=True)
 for name,source in blocks:
  assert source+'\n'==(S/name).read_text(encoding='utf8') and '$' not in source
  hashes[name]=hashlib.sha256((source+'\n').encode()).hexdigest()
  if name=='layout.gd':
   if folder=='variation':source=source.replace('var rest_length := 0.65','var rest_length := 0.9')
   if folder=='fault-adjacency':source=source.replace('\tvar current := forces(neighbours)','\tneighbours[0].clear()\n\tvar current := forces(neighbours)')
   if folder=='fault-step':source=source.replace('\tvar current := forces(neighbours)\n\tfor vertex in range(positions.size()):','\tfor vertex in range(positions.size()):\n\t\tvar current := forces(neighbours)')
  if name=='study.gd' and folder=='fault-rods':source=source.replace('rods[index].mesh.height = maxf(offset.length(), 0.001)','rods[index].mesh.height = 0.65')
  (O/folder/name).write_text(source+'\n',encoding='utf8')
 shutil.copyfile(S/'study.tscn',O/folder/'study.tscn')
for name in ['point_body.gd','traversal.gd']:assert (S/name).read_bytes()==(S.parent/'GT_Foundations'/name).read_bytes()
receipt=O/'checks.json'
if receipt.exists():shutil.copy2(receipt,O/'previous-checks.json');receipt.unlink()
started=datetime.datetime.now(datetime.timezone.utc).isoformat()
with (O/'code.log').open('w',encoding='utf8') as log:
 p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--script','res://tools/probes/graph_layout_student.gd','--','--no-bridges'],stdout=log,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
log=(O/'code.log').read_text(encoding='utf8',errors='replace');print('\n'.join(log.splitlines()[-42:]))
assert p.returncode==0 and receipt.exists() and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
d=json.loads(receipt.read_text());assert d['passed'] and d['completed'],d['failures']
d.update(started=started,finished=datetime.datetime.now(datetime.timezone.utc).isoformat(),printed_hashes=hashes,tutorial_sha256=hashlib.sha256(text.encode()).hexdigest(),carried_files_unchanged=True,fresh_engine_run=True)
receipt.write_text(json.dumps(d,indent=2)+'\n',encoding='utf8');print(len(d['checks']),'checks passed')
