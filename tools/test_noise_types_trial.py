"""Random_Noise_Types Void trial: original artifacts, seeded bench, glazed partitions, both drops.

Isolated user:// saves, real desktop and synthetic XR rigs. `--capture` renders Mobile
screenshots into the report folder; `--measure` dumps floor-local bounds for layout work.
"""
from pathlib import Path
import hashlib,json,os,subprocess,sys
from void_trial_runtime import stage_runtime
sys.stdout.reconfigure(encoding='utf8')
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-20-void-noise-types-trial'
capture='--capture' in sys.argv
measure='--measure' in sys.argv
dest=OUT/('measure' if measure else 'images' if capture else 'tests');dest.mkdir(parents=True,exist_ok=True)
stage=stage_runtime()
args=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window' if (capture or measure) else '--headless','--path',str(stage),'--rendering-method','mobile','--xr-mode','off','--fixed-fps','60','--script','res://tools/probes/noise_types_trial_probe.gd','--','--no-bridges','--out='+str(dest)]
if capture or measure:args.append('--capture')
if measure:args.append('--measure')
if '--verbose' in sys.argv:args.insert(1,'--verbose')
before={n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in ['commons/void/rooms.json','commons/void/layout.json','commons/void/trials/transformation/rooms.json','commons/maps/Random_Noise_Types/map_data.json','commons/maps/Random_Noise_Types/tutorial.md','commons/maps/Random_Noise_Types/final.md']}
with (dest/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(args,stdout=log,stderr=subprocess.STDOUT,timeout=420,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=(dest/'engine.log').read_text(encoding='utf-8',errors='replace')
after={n:hashlib.sha256((ROOT/n).read_bytes()).hexdigest() for n in before}
assert before==after,'Curated tower, Transformation trial or Random_Noise_Types texts changed during the run'
if measure:
    print((dest/'measure.json').read_text(encoding='utf8') if (dest/'measure.json').exists() else log[-6000:]);sys.exit(result.returncode)
report=json.loads((dest/'checks.json').read_text()) if (dest/'checks.json').exists() else {}
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,(report.get('failed'),log[-7000:])
assert report['passed'],report['failed']
print(f'{len(report["checks"])} checks passed. Curated tower, Transformation trial and the original texts are unchanged. {dest}')
