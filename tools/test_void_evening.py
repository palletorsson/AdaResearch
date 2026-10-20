"""Capture matched lighting views in the real tower, with Mobile and XR binding checks."""
from pathlib import Path
import json,os,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-void-evening'
OUT.mkdir(parents=True,exist_ok=True)
baseline='--baseline' in sys.argv
subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],cwd=ROOT,check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
shutil.copy2(ROOT/'tools/probes/void_evening_probe.gd',stage/'tools/probes/void_evening_probe.gd')
cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/void_evening_probe.gd','--','--out='+str(OUT)]
if baseline:cmd.append('--baseline')
logfile=OUT/('before.log' if baseline else 'engine.log')
with logfile.open('w',encoding='utf-8') as stream:
 result=subprocess.run(cmd,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=logfile.read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-6500:]
receipt=json.loads((OUT/('before-checks.json' if baseline else 'checks.json')).read_text())
assert receipt['passed'],receipt
print(f"{len(receipt['checks'])} lighting checks passed",flush=True)
if not baseline:
 from PIL import Image,ImageChops,ImageStat
 a=Image.open(OUT/'lights-on.png').convert('RGB')
 b=Image.open(OUT/'lights-off.png').convert('RGB')
 mean=ImageStat.Stat(ImageChops.difference(a,b)).mean
 assert sum(mean)>3, f'Work lights did not visibly illuminate the room: {mean}'
 (OUT/'light-contribution.json').write_text(json.dumps({'passed':True,'mean_absolute_rgb_difference':mean,'scope':'Same camera and evening environment; only actual WorkBeam lights hidden, emissive lenses unchanged.'},indent=2))
 print('Rendered work-light contribution verified')
