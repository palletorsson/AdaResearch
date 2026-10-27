"""Serial offscreen source checks, native captures and targeted editor exports."""
from pathlib import Path
import os,subprocess,sys,time,json
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime
ROOT=Path(__file__).resolve().parents[1]
sys.stdout.reconfigure(encoding='utf-8')
OUT=ROOT/'ada_run/primitives-kit';OUT.mkdir(parents=True,exist_ok=True)
job=sys.argv[1] if len(sys.argv)>1 else 'probe'
assert job in ['compile','probe','export']
slot=acquire_native_slot('primitive kit '+job);stage=stage_runtime()
exe='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
if job=='compile':
    files=['commons/artifacts/primitive_encounters/'+f+'.gd' for f in ['timber_finish','timber_panel','gravity_ball','poly_marker','melencolia_platform']]+['commons/artifacts/line_relations_gallery/line_body.gd','commons/void/lines_area.gd','commons/void/triangle_area.gd','commons/void/polyhedra_area.gd','commons/void/primitive_hall.gd','commons/void/set_dressing.gd','commons/artifacts/trace_ball_ramp/trace_ball_ramp.gd']+['tools/probes/primitive_kit_'+f+'.gd' for f in ['probe','frame','export']]
    command=[exe,'--headless','--path',str(stage),'--xr-mode','off','--script','res://commons/testing/check_compile.gd','--','--files='+','.join('res://'+f for f in files)]
else:
    command=[exe,'--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--position','-3000,-3000','--resolution','1280x800','--script','res://tools/probes/primitive_kit_'+job+'.gd','--','--out='+str(OUT)]
log=OUT/(job+'.log')
if log.exists():
    (OUT/'previous').mkdir(exist_ok=True);log.rename(OUT/'previous'/(job+'-'+str(time.time_ns())+'.log'))
with log.open('w',encoding='utf-8') as stream:
    process=subprocess.Popen(command,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    started=time.monotonic()
    while process.poll() is None:
        time.sleep(.3)
        if 'SCRIPT ERROR' in log.read_text(encoding='utf-8',errors='replace') or time.monotonic()-started>240:
            process.terminate();process.wait(timeout=15);break
text=log.read_text(encoding='utf-8',errors='replace');print(text[-7000:])
raise SystemExit(process.returncode or (1 if 'SCRIPT ERROR' in text or any(l.startswith('ERROR:') for l in text.splitlines()) else 0))
