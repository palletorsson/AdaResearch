"""Serialize the focused native survey/check before the human desktop session."""
from pathlib import Path
import argparse,subprocess,sys
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
def main():
 sys.stdout.reconfigure(encoding='utf8')
 p=argparse.ArgumentParser();p.add_argument('--saved',action='store_true');a=p.parse_args()
 out=ROOT/'ada_run/transformation-lab/floor16-placement';out.mkdir(parents=True,exist_ok=True)
 name='saved' if a.saved else 'survey'
 with acquire_native_slot('Rotation full-floor portal '+name):
  stage=stage_runtime()
  with (out/(name+'.log')).open('w',encoding='utf8') as log:
   r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--no-window','--path',str(stage),'--rendering-method','gl_compatibility','--xr-mode','off','--resolution','1440x1000','--fixed-fps','60','--quit-after','3000','--script','res://tools/probes/transformation_portal_floor16.gd','--','--no-bridges','--pictures='+str(out),*(['--saved'] if a.saved else [])],stdout=log,stderr=subprocess.STDOUT,timeout=160,creationflags=subprocess.CREATE_NO_WINDOW)
 print((out/(name+'.log')).read_text(encoding='utf8')[-6500:]);assert r.returncode==0,r.returncode
if __name__=='__main__':main()
