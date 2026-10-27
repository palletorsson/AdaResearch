from pathlib import Path
import os,subprocess,sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/close-flashlights'
OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf8')
job=sys.argv[1] if len(sys.argv)>1 else 'probe'
assert job in ('probe','export')
lock=acquire_native_slot('close flashlights '+job)
stage=stage_runtime()
target=ROOT.parent/'ada_encyclopedia/public/void-models' if job=='export' else OUT
script='export_close_flashlights' if job=='export' else 'close_flashlights_probe'
with (OUT/(job+'.log')).open('w',encoding='utf8') as log:
    result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--position','-3000,-3000','--resolution','1280x800','--script','res://tools/probes/'+script+'.gd','--','--no-bridges','--out='+str(target),*sys.argv[2:]],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=240,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
print(job,'exit',result.returncode)
print((OUT/(job+'.log')).read_text(encoding='utf8',errors='replace')[-3500:])
sys.exit(result.returncode)
