"""Serial isolated museum captures for the 12 September visual review."""
from pathlib import Path
import subprocess,sys,json,hashlib,datetime,re
ROOT=Path(__file__).resolve().parent.parent
BASE=ROOT/'ada_run/visual_review_20260912'
HALLS=[('WaveFunctions_Intro','intro'),('WaveFunctions_Pendulum','pendulum'),('WaveFunctions_Sine_Space','sine_space'),('WaveFunctions_Effect_Sound','effect_sound'),('WaveFunctions_AirMusic','air_music'),('WaveFunctions_Synthesis_Lab','synthesis_lab'),('Random_Definition','random_definition'),('Random_Entropy','entropy'),('Random_Remove','remove'),('Random_Walk','walk'),('Random_Gaussian','gaussian'),('Random_Mushrooms','mushrooms')]
def stamp():return datetime.datetime.now().astimezone().isoformat(timespec='seconds')
def dump(p,d):p.parent.mkdir(parents=True,exist_ok=True);p.write_text(json.dumps(d,indent=2),encoding='utf-8')
def main():
 BASE.mkdir(parents=True,exist_ok=True)
 # Read the current hand through an isolated snapshot; any flush stays in this capture batch.
 (BASE/'necklace_hand.json').write_bytes((ROOT/'ada_run/necklace_hand.json').read_bytes())
 results=[]
 for name,stem in HALLS:
  existing=BASE/name/'capture.json'
  if existing.exists():results.append(json.loads(existing.read_text()));continue
  q=subprocess.run(['powershell.exe','-NoProfile','-Command',"$ErrorActionPreference='Stop'; $p=@(Get-CimInstance Win32_Process -Filter \"Name LIKE 'Godot%'\"); ConvertTo-Json -InputObject $p -Depth 2 -Compress"],capture_output=True,text=True,creationflags=subprocess.CREATE_NO_WINDOW)
  try: active=json.loads(q.stdout) if q.returncode==0 else None
  except ValueError:active=None
  if active is None or active:
   dump(BASE/'blocked.json',{'at':stamp(),'next':name,'query_exit':q.returncode,'active_processes':active,'error':q.stderr})
   print('PAUSED before',name,': Godot occupied or inventory unavailable.',flush=True);break
  folder=BASE/name;folder.mkdir(parents=True,exist_ok=True)
  live=ROOT/f'commons/testing/probe_wcn_{stem}_live.gd'
  lane='live' if live.exists() else 'bare'
  src=live if live.exists() else ROOT/f'commons/testing/probe_wcn_{stem}.gd'
  script=src.read_text(encoding='utf-8-sig')
  script=script.replace('res://ada_run/waves_chance_noise/','res://ada_run/visual_review_20260912/').replace('res://ada_run/necklace_hand.json','res://ada_run/visual_review_20260912/necklace_hand.json')
  path=BASE/'probes'/src.name;path.parent.mkdir(exist_ok=True);path.write_text(script,encoding='utf-8')
  rel='res://'+path.relative_to(ROOT).as_posix()
  scene=path.with_suffix('.tscn')
  scene.write_text('[gd_scene load_steps=2 format=3]\n[ext_resource type="Script" path="'+rel+'" id="1"]\n[node name="VisualCapture" type="Node"]\nscript = ExtResource("1")\n',encoding='utf-8')
  engine=folder/'engine.log'; log=folder/'runner.log'
  # All expected report names are taken from the actual probe's JSON output expression.
  filenames=re.findall(r'"(probe_[a-z_]+\.json)"',script)
  expected=folder/(filenames[-1] if filenames else 'result.json')
  args=[str(ROOT/'tools/godot_watchdog.py'),'--expect='+str(expected),'--grace=180','--stall=30','--','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--rendering-method','gl_compatibility','--position','4000,4000','--resolution','1280x720','--path',str(ROOT),'--xr-mode','off','--log-file',str(engine)]
  args+=['res://'+scene.relative_to(ROOT).as_posix()] if lane=='live' else ['--script',rel]
  args+=['--','--capture']
  before=stamp();source_hash=hashlib.sha256(src.read_bytes()).hexdigest();map_hash=hashlib.sha256((ROOT/'commons/maps'/name/'map_data.json').read_bytes()).hexdigest()
  print('CAPTURING',name,lane,flush=True)
  with log.open('w',encoding='utf-8') as f:
   r=subprocess.run([sys.executable]+args,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
  rec={'map':name,'lane':lane,'started':before,'finished':stamp(),'exit':r.returncode,'source':str(src.relative_to(ROOT)),'source_sha256':source_hash,'map_sha256':map_hash,'source_changed_during_run':source_hash!=hashlib.sha256(src.read_bytes()).hexdigest(),'map_changed_during_run':map_hash!=hashlib.sha256((ROOT/'commons/maps'/name/'map_data.json').read_bytes()).hexdigest(),'images':[p.name for p in sorted(folder.glob('*.png'))],'reports':[p.name for p in folder.glob('probe*.json')]}
  dump(existing,rec);results.append(rec);dump(BASE/'manifest.json',results)
  print('DONE',name,'exit',r.returncode,'images',len(rec['images']),flush=True)
 dump(BASE/'manifest.json',results)
if __name__=='__main__':main()
