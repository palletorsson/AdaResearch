"""Run the upgraded cube net inside an isolated, actual endless museum."""
from pathlib import Path
import json, os, shutil, subprocess, sys, tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-04-cube-another-one'
OUT.mkdir(parents=True, exist_ok=True)
work = Path(tempfile.mkdtemp(prefix='ada-cube-net-'))
def junction(dest, src):
    command = "New-Item -ItemType Junction -Path '"+str(dest).replace("'","''")+"' -Target '"+str(src).replace("'","''")+"' | Out-Null"
    subprocess.run(['powershell','-NoProfile','-Command',command],check=True,creationflags=subprocess.CREATE_NO_WINDOW)
for src in ROOT.iterdir():
    if src.is_dir() and not src.name.startswith('.') and src.name not in ('ada_run','node_modules','doc','tools'):
        junction(work/src.name,src)
for name in ('icon.png','default_bus_layout.tres'):
    if (ROOT/name).exists(): shutil.copy2(ROOT/name,work/name)
(work/'.godot').mkdir()
for name in ('global_script_class_cache.cfg','uid_cache.bin'):
    shutil.copy2(ROOT/'.godot'/name,work/'.godot'/name)
junction(work/'.godot/imported',ROOT/'.godot/imported')
project = (ROOT/'project.godot').read_text(encoding='utf-8-sig').replace('config/name="Ada Research Zero One"','config/name="'+work.name+'"').replace('buses/default_bus_layout="uid://rwex60pqapc"','buses/default_bus_layout="res://default_bus_layout.tres"')
(work/'project.godot').write_text(project,encoding='utf-8')
state = work/'ada_run/cube-net-cycle'; state.mkdir(parents=True)
shutil.copy2(ROOT/'ada_run/em_plan.json',work/'ada_run/em_plan.json')
startup = subprocess.STARTUPINFO(); startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW; startup.wShowWindow = 0
engine = os.environ.get('GODOT_EXE',str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe'))
cmd = [sys.executable,str(ROOT/'tools/godot_watchdog.py'),'--expect='+str(state/'report.json'),'--grace=95','--',engine,'--path',str(work),'--xr-mode','off','--rendering-method','gl_compatibility','--position','-10000,-10000','--resolution','1440x960','--log-file',str(OUT/'godot.log'),'--script','res://commons/testing/capture_cube_net_cycle.gd']
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup,timeout=120)
print('Private museum:',work)
if not (state/'report.json').exists():
    print((OUT/'godot.log').read_text(encoding='utf-8',errors='replace')[-3500:]); sys.exit(1)
report = json.loads((state/'report.json').read_text(encoding='utf-8'))
errors = [line for line in (OUT/'godot.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR:' in line]
report['checks'].append({'name':'no native script errors','passed':not errors})
report['passed'] = report['passed'] and not errors
(OUT/'evidence.json').write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
for shot in state.glob('*.png'): shutil.copy2(shot,OUT/shot.name)
print('Passed:',report['passed'],'Checks:',len(report['checks']))
if errors: print('\n'.join(errors))
if result.returncode or not report['passed']: sys.exit(1)
# Preserve measured intervals: the video plays the captured simulation in real time.
import imageio_ffmpeg
times = json.loads((state/'frame-times.json').read_text(encoding='utf-8'))
concat = state/'frames.ffconcat'
lines = ['ffconcat version 1.0']
for i, stamp in enumerate(times):
    lines += [f"file 'frames/frame_{i:04d}.png'",f'duration {times[i+1]-stamp if i+1<len(times) else 0.12:.5f}']
lines.append(f"file 'frames/frame_{len(times)-1:04d}.png'")
concat.write_text('\n'.join(lines)+'\n',encoding='utf-8')
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(),'-hide_banner','-loglevel','error','-y','-safe','0','-i','frames.ffconcat','-vf','fps=24,scale=1080:720','-c:v','libx264','-crf','23','-pix_fmt','yuv420p','-movflags','+faststart',str(OUT/'cycle.mp4')],cwd=state,check=True,creationflags=subprocess.CREATE_NO_WINDOW)
print('Native cycle video:',OUT/'cycle.mp4')
# Fast, separate floor fixture checks continued production beyond the cap.
stress_file = state/'collection-stress.json'
stress_cmd = [sys.executable,str(ROOT/'tools/godot_watchdog.py'),'--expect='+str(stress_file),'--grace=45','--',engine,'--headless','--fixed-fps','60','--path',str(work),'--xr-mode','off','--script','res://commons/testing/probe_cube_net_collection.gd','--log-file',str(OUT/'collection-stress.log')]
with (OUT/'collection-stress-engine.log').open('w',encoding='utf-8') as log:
    subprocess.run(stress_cmd,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup,timeout=60,check=True)
stress = json.loads(stress_file.read_text(encoding='utf-8'))
assert stress['passed'], stress
shutil.copy2(stress_file,OUT/'collection-stress.json')
print('Extended collection run:',stress)
