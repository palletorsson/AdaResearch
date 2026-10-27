"""Native floor-72 probe, serialized with the other Void jobs."""
import os,sys,subprocess
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-23-entropies-staging'/('before' if '--before' in sys.argv else 'native')
OUT.mkdir(parents=True,exist_ok=True)
slot=acquire_native_slot('Entropy Types staging');stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--resolution','1440x900','--rendering-method','mobile','--xr-mode','off','--path',str(stage),'--script','res://tools/probes/entropies_staging_probe.gd','--','--no-bridges','--void-start-floor=72','--out='+str(OUT)]
if '--before' not in sys.argv:args.append('--void-draft='+str(OUT.parent/'draft-rooms.json'))
if '--desktop-only' in sys.argv:args.append('--desktop-only')
with (OUT/'native.log').open('w',encoding='utf8') as log:
 result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=450,creationflags=subprocess.CREATE_NO_WINDOW)
log=(OUT/'native.log').read_text(encoding='utf8',errors='replace')
errors,shutdown=split_errors(log,'ENTROPIES_STAGING_RESULT',allow_shutdown=result.returncode==0)
print(log[-5000:]);assert result.returncode==0 and not errors and 'Parse Error' not in log,(errors,shutdown)
