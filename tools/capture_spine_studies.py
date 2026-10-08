"""Capture all installed studies with actual museum assembly in private projects."""
from pathlib import Path
import json, os, shutil, subprocess, sys, tempfile
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-02-studies-in-the-spine/figures';OUT.mkdir(parents=True,exist_ok=True)
manifest=json.loads((ROOT/'doc/book/recent-studies.json').read_text(encoding='utf-8'))
work=Path(tempfile.mkdtemp(prefix='ada-study-spine-'))
def junction(dest,src):
    cmd="New-Item -ItemType Junction -Path '"+str(dest).replace("'","''")+"' -Target '"+str(src).replace("'","''")+"' | Out-Null"
    subprocess.run(['powershell','-NoProfile','-Command',cmd],check=True,creationflags=subprocess.CREATE_NO_WINDOW)
for src in ROOT.iterdir():
    if src.is_dir() and not src.name.startswith('.') and src.name not in ('ada_run','node_modules','doc','tools'): junction(work/src.name,src)
for name in ('icon.png','default_bus_layout.tres'):
    if (ROOT/name).exists(): shutil.copy2(ROOT/name,work/name)
(work/'.godot').mkdir()
for name in ('global_script_class_cache.cfg','uid_cache.bin'): shutil.copy2(ROOT/'.godot'/name,work/'.godot'/name)
junction(work/'.godot/imported',ROOT/'.godot/imported')
project=(ROOT/'project.godot').read_text(encoding='utf-8-sig').replace('config/name="Ada Research Zero One"','config/name="'+work.name+'"').replace('buses/default_bus_layout="uid://rwex60pqapc"','buses/default_bus_layout="res://default_bus_layout.tres"')
(work/'project.godot').write_text(project,encoding='utf-8')
state=work/'ada_run/study-integration';state.mkdir(parents=True)
shutil.copy2(ROOT/'commons/data/museum/em_plan.json',work/'commons/data/museum/em_plan.json')
if (ROOT/'ada_run/necklace_hand.json').exists(): shutil.copy2(ROOT/'ada_run/necklace_hand.json',state/'hand.json')
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=0
engine=str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')
done=[]
hall_filter=sys.argv[1:]
for study in manifest['studies']:
    hall=study['map']
    if hall in done or (hall_filter and hall not in hall_filter): continue
    done.append(hall)
    # The fixed, verified private-state file alone is replaced between runs.
    if (state/'report.json').exists(): (state/'report.json').unlink()
    cmd=[sys.executable,str(ROOT/'tools/godot_watchdog.py'),'--expect='+str(state/'report.json'),'--grace=75','--',engine,'--path',str(work),'--xr-mode','off','--rendering-method','gl_compatibility','--position','-10000,-10000','--resolution','1800x1200','--log-file',str(OUT/(hall+'-godot.log')),'--script','res://commons/testing/capture_spine_studies.gd','--',hall,study['sequence']]
    with (OUT/(hall+'-engine.log')).open('w',encoding='utf-8') as log:
        result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup,timeout=100)
    if (state/'report.json').exists():
        report=json.loads((state/'report.json').read_text(encoding='utf-8'))
        engine_log=(OUT/(hall+'-godot.log')).read_text(encoding='utf-8',errors='replace')
        script_errors=[line for line in engine_log.splitlines() if 'SCRIPT ERROR:' in line]
        report['checks'].append({'name':'no script errors during native run','passed':not script_errors})
        report['passed']=report['passed'] and not script_errors
        (OUT/(hall+'-report.json')).write_text(json.dumps(report,indent=2)+'\n',encoding='utf-8')
        print(hall,result.returncode,report['passed'],len(report['checks']),flush=True)
        if script_errors:
            print('\n'.join(script_errors)); sys.exit(1)
    else: print(hall,result.returncode,'NO REPORT',flush=True)
    for entry in manifest['studies']:
        p=state/(entry['id']+'.png')
        if entry['map']==hall and p.exists(): shutil.copy2(p,OUT/p.name)
    for detail in state.glob('tube-*.png'):
        if hall=='LSystems_Grammars_And_Curves': shutil.copy2(detail,OUT/detail.name)
    audio=state/'tube-patch-audio.wav'
    if hall=='LSystems_Grammars_And_Curves' and audio.exists(): shutil.copy2(audio,OUT/audio.name)
    camera_shot=state/'museum_witnesses-camera.png'
    for detail in state.glob('tension-*.png'):
        if hall=='SoftBodies_Cloth_Physics': shutil.copy2(detail,OUT/detail.name)
    for detail in state.glob('paired-time-*.png'):
        if hall=='Change_Choreography': shutil.copy2(detail,OUT/detail.name)
    if hall=='SpeculativeComputation_Situated_Computation' and camera_shot.exists(): shutil.copy2(camera_shot,OUT/camera_shot.name)
    if result.returncode:
        print('\n'.join(line for line in (OUT/(hall+'-engine.log')).read_text(encoding='utf-8',errors='replace').splitlines() if 'Error' in line or 'ERROR' in line or 'FAIL' in line)[-4500:])
        sys.exit(result.returncode)
print('Private project:',work)
