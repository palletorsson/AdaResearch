"""Offscreen native jobs serialized with the other Void tools."""
from pathlib import Path
import os, subprocess, sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/full-void-spine'
OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
job=sys.argv[1]
assert job in ('frame','probe','menu')
slot=acquire_native_slot('full Void spine '+job)
stage=stage_runtime()
(OUT/'stage.txt').write_text(str(stage),encoding='utf8')
args=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(stage),
      '--rendering-method','mobile','--xr-mode','off','--fixed-fps','60',
      '--position','-3000,-3000','--resolution','1280x800','--script',
      'res://tools/probes/'+('export_void_spine_frame.gd' if job=='frame' else 'void_spine_probe.gd'),
      '--','--no-bridges','--out='+str(ROOT.parent/'ada_encyclopedia/public/void-models' if job=='frame' else OUT)]
if job=='menu': args.extend(['--menu-only','--void-trial=cellularautomata'])
with (OUT/(job+'.log')).open('w',encoding='utf8') as log:
    result=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=360,
                          creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
print('job',job,'exit',result.returncode)
print((OUT/(job+'.log')).read_text(encoding='utf8',errors='replace')[-4500:])
sys.exit(result.returncode)
