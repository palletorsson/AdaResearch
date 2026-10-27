"""Serial main-tower CA diagnostics and curation checks."""
import argparse,json,os,subprocess,sys
from pathlib import Path
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
from void_log_diagnostics import split_errors
ROOT=Path(__file__).resolve().parents[1];OUT=ROOT/'ada_run/ca-curation';OUT.mkdir(exist_ok=True)
p=argparse.ArgumentParser();p.add_argument('--probe',default='ca_spine_baseline');p.add_argument('--headless',action='store_true');p.add_argument('--draft',action='store_true');p.add_argument('--draft-file');p.add_argument('--out');p.add_argument('--floors',default='103,104,105,106,107,108,109,110');p.add_argument('--mode',choices=['desktop','xr','both'],default='both');args=p.parse_args()
if args.out:OUT=Path(args.out).resolve();OUT.mkdir(parents=True,exist_ok=True)
assert args.probe.isidentifier();sys.stdout.reconfigure(encoding='utf-8')
slot=acquire_native_slot('Main CA '+args.probe);stage=stage_runtime()
flags=['--headless'] if args.headless else ['--windowed','--position','-3000,-3000','--resolution','1440x900']
logfile=OUT/(args.probe+'.log')
with logfile.open('w',encoding='utf-8') as stream:
    extra=['--void-draft='+str(OUT/'draft-rooms.json')] if args.draft else []
    if args.draft_file:extra=['--void-draft='+str(Path(args.draft_file).resolve())]
    extra+=['--floors='+args.floors,'--mode='+args.mode]
    r=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),*flags,'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--path',str(stage),'--script',f'res://tools/probes/{args.probe}.gd','--','--no-bridges','--void-start-floor='+args.floors.split(',')[0],'--out='+str(OUT),*extra],stdout=stream,stderr=subprocess.STDOUT,timeout=900,creationflags=subprocess.CREATE_NO_WINDOW)
log=logfile.read_text(encoding='utf-8',errors='replace');errors,shutdown=split_errors(log,'CA_ACTIVE_RESULT ' if args.probe=='ca_spine_active' else 'CA_BASELINE_RESULT ',allow_shutdown=r.returncode==0)
(OUT/(args.probe+'-engine.json')).write_text(json.dumps(dict(engine_exit=r.returncode,errors=errors,shutdown=shutdown),indent=2)+'\n',encoding='utf-8')
print(log[-4000:]);assert r.returncode==0 and not errors,(r.returncode,errors[:5])
