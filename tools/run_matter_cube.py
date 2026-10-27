"""Serialized targeted main-Cube inventory checks and real scene export."""
from pathlib import Path
import os,subprocess,sys,time
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'ada_run/matter-cube-inventory';OUT.mkdir(parents=True,exist_ok=True)
sys.stdout.reconfigure(encoding='utf-8')
job=sys.argv[1] if len(sys.argv)>1 else 'probe'
assert job in ['compile','probe','export','followup','supports']
slot=acquire_native_slot('matter cube '+job);stage=stage_runtime()
exe='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
if job=='compile':
    files=['commons/void/prefab_inventory.gd','commons/void/inventory_board.gd','commons/void/game.gd','commons/artifacts/matter_gates/matter_and.gd','tools/probes/matter_cube_probe.gd','tools/probes/matter_cube_export.gd']
    command=[exe,'--headless','--path',str(stage),'--xr-mode','off','--script','res://commons/testing/check_compile.gd','--','--files='+','.join('res://'+f for f in files)]
else:
    command=[exe,'--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--position','-3000,-3000','--resolution','1280x800','--script','res://tools/probes/matter_cube_'+job+'.gd','--','--out='+str(OUT),'--no-bridges','--void-start-floor=7',*sys.argv[2:]]
log=OUT/(job+'-'+str(time.time_ns())+'.log')
with log.open('w',encoding='utf-8') as stream:
    process=subprocess.Popen(command,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    started=time.monotonic()
    while process.poll() is None:
        time.sleep(.3)
        if 'SCRIPT ERROR' in log.read_text(encoding='utf-8',errors='replace') or time.monotonic()-started>420:
            process.terminate();process.wait(timeout=15);break
text=log.read_text(encoding='utf-8',errors='replace');print(text[-8000:])
if process.returncode==0 and job=='export':
    import json
    parts_file=ROOT/'commons/void/line_parts.json'
    parts=json.loads(parts_file.read_text(encoding='utf-8'))
    parts['matter_and']=json.loads((OUT/'part-defaults.json').read_text(encoding='utf-8'))
    temporary=parts_file.with_suffix('.json.tmp')
    temporary.write_text(json.dumps(parts,indent=2)+'\n',encoding='utf-8')
    for attempt in range(20):
        try:os.replace(temporary,parts_file);break
        except PermissionError:
            if attempt==19:raise
            time.sleep(.15)
raise SystemExit(process.returncode or (1 if 'SCRIPT ERROR' in text or any(l.startswith('ERROR:') for l in text.splitlines()) else 0))
