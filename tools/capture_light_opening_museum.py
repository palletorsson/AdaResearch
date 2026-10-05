"""Capture the actual museum in a private runtime project and user-data directory.

Resource directories are junctions; engine caches and runtime state are private.
Never imports/edits the linked resources or touches an existing Godot process.
"""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, sys, tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-02-light-an-opening/figures'
work = Path(tempfile.mkdtemp(prefix='ada-light-museum-'))
OUT.mkdir(parents=True, exist_ok=True)
for source in ROOT.iterdir():
    if source.is_dir() and not source.name.startswith('.') and source.name not in ('ada_run', 'node_modules', 'doc', 'tools'):
        # Junctions are created as paths, not shell-built commands.
        command = "New-Item -ItemType Junction -Path '"+str(work/source.name).replace("'","''")+"' -Target '"+str(source).replace("'","''")+"' | Out-Null"
        subprocess.run(['powershell','-NoProfile','-Command',command], check=True, creationflags=subprocess.CREATE_NO_WINDOW)
for name in ('icon.png','default_bus_layout.tres'):
    if (ROOT/name).exists(): shutil.copy2(ROOT/name, work/name)
(work/'.godot').mkdir()
for name in ('global_script_class_cache.cfg','uid_cache.bin'):
    shutil.copy2(ROOT/'.godot'/name, work/'.godot'/name)
subprocess.run(['powershell','-NoProfile','-Command',
    "New-Item -ItemType Junction -Path '"+str(work/'.godot/imported')+"' -Target '"+str(ROOT/'.godot/imported')+"' | Out-Null"], check=True, creationflags=subprocess.CREATE_NO_WINDOW)
project = (ROOT/'project.godot').read_text(encoding='utf-8-sig')
project = project.replace('config/name="Ada Research Zero One"', 'config/name="'+work.name+'"')
project = project.replace('buses/default_bus_layout="uid://rwex60pqapc"', 'buses/default_bus_layout="res://default_bus_layout.tres"')
(work/'project.godot').write_text(project, encoding='utf-8')
state = work/'ada_run/light-opening-museum'
state.mkdir(parents=True)
shutil.copy2(ROOT/'ada_run/em_plan.json', work/'ada_run/em_plan.json')
if (ROOT/'ada_run/necklace_hand.json').exists(): shutil.copy2(ROOT/'ada_run/necklace_hand.json', state/'hand.json')
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
engine = str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')
cmd = [sys.executable,str(ROOT/'tools/godot_watchdog.py'),'--expect='+str(state/'report.json'),'--grace=100','--',
       engine,'--path',str(work),'--xr-mode','off','--rendering-method','gl_compatibility',
       '--position','-10000,-10000','--resolution','1800x1200','--log-file',str(OUT/'godot.log'),
       '--script','res://commons/testing/capture_light_opening_museum.gd']
with (OUT/'museum-engine.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,startupinfo=startup,timeout=120)
for name in ('pink-threshold.png','threshold-from-side.png','light-well-rose.png','light-well-violet.png','light-well-landing.png','white-room-rose.png','white-room-blue.png','report.json'):
    if (state/name).exists(): shutil.copy2(state/name,OUT/name)
print('Private project:', work)
print('Engine exit:',result.returncode)
logtext = (OUT/'museum-engine.log').read_text(encoding='utf-8',errors='replace')
if (OUT/'godot.log').exists(): logtext += (OUT/'godot.log').read_text(encoding='utf-8', errors='replace')
lines = [line for line in logtext.splitlines() if any(tag in line for tag in ('[light-museum]','ERROR','watchdog:'))]
print('\n'.join(lines[-25:]))
if result.returncode == 0 and (state/'report.json').exists():
    sources = ['commons/maps/Color_Flashlight/map_data.json', 'commons/maps/sequences/color.json',
        'commons/artifacts/colour_light_rooms/colour_light_rooms.gd',
        'commons/artifacts/colour_light_rooms/colour_light_rooms.tscn',
        'commons/scenes/endless_museum.gd','commons/testing/capture_light_opening_museum.gd','ada_run/em_plan.json']
    (OUT/'provenance.json').write_text(json.dumps({'godot':engine,'private_project':str(work),
        'source_files':{p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in sources},
        'scope':'Actual museum assembly. Private runtime state, frozen for stills; distance culling follows capture eye. No headset test.'},indent=2)+'\n',encoding='utf-8')
sys.exit(result.returncode if result.returncode else (0 if (state/'report.json').exists() else 1))
