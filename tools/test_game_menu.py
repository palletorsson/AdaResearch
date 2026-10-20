"""Boot the real staging menu, click it with mouse input, enter and return.

Mirror the project with junctions to its actual sources/imported assets. Only
the app name differs, isolating user:// saves from the user's real progress.
"""
import argparse
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-desktop-game-menu'
WORK = ROOT / 'ada_run/menu-integration-test'
GODOT = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
sys.stdout.reconfigure(encoding='utf-8')
parser = argparse.ArgumentParser()
parser.add_argument('routes', nargs='*', default=['void', 'runner', 'shadow', 'ladder', 'arena', 'museum', 'sequences', 'maps'])
parser.add_argument('--headless', action='store_true')
parser.add_argument('--verbose', action='store_true')
parser.add_argument('--out', type=Path, default=OUT)
args = parser.parse_args()
OUT = args.out
OUT.mkdir(parents=True, exist_ok=True)
WORK.mkdir(parents=True, exist_ok=True)
(WORK/'.gdignore').touch()
stage = Path(tempfile.mkdtemp(prefix='run-', dir=WORK))
for source in ROOT.iterdir():
    if source.name in {'.godot', '.git', 'project.godot', 'override.cfg'} or source.is_reserved():
        continue
    target = stage/source.name
    if source.is_dir():
        # Junction creation only. No moves or recursive deletes.
        subprocess.run(['cmd','/c','mklink','/J',str(target),str(source)],check=True,capture_output=True)
    else:
        shutil.copy2(source,target)
(stage/'.godot').mkdir()
for name in ['global_script_class_cache.cfg','uid_cache.bin','scene_groups_cache.cfg','extension_list.cfg']:
    if (ROOT/'.godot'/name).exists(): shutil.copy2(ROOT/'.godot'/name,stage/'.godot'/name)
subprocess.run(['cmd','/c','mklink','/J',str(stage/'.godot/imported'),str(ROOT/'.godot/imported')],check=True,capture_output=True)
config = (ROOT/'project.godot').read_text(encoding='utf-8')
config = re.sub(r'config/name="[^"]+"', 'config/name="Ada Menu Integration Test"', config, count=1)
(stage/'project.godot').write_text(config,encoding='utf-8')
results = []
for route in args.routes:
    report = OUT/f'{route}.json'
    if report.exists(): report.unlink()
    command = [GODOT,'--path',str(stage),'--xr-mode','off','--resolution','1600x1000',
               '--script','res://tools/probes/game_menu_route.gd']
    command += ['--headless'] if args.headless else ['--no-window','--rendering-method','forward_plus']
    if args.verbose: command.append('--verbose')
    command += ['--','--desktop','--no-bridges','--route='+route,'--out='+str(OUT),
                '--runner-save=user://runner-test.cfg','--shadow-save=user://shadow-test.json']
    print('Testing',route,flush=True)
    with (OUT/f'{route}.log').open('w',encoding='utf-8') as log:
        p = subprocess.Popen(command,cwd=stage,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        try: code = p.wait(timeout=150)
        except subprocess.TimeoutExpired:
            p.kill(); p.wait(); code = 124
    result = json.loads(report.read_text(encoding='utf-8')) if report.exists() else {'passed':False,'error':'no result'}
    result['exit_code'] = code
    text = (OUT/f'{route}.log').read_text(encoding='utf-8',errors='replace')
    result['engine_errors'] = [line for line in text.splitlines() if line.startswith(('ERROR:','SCRIPT ERROR:'))]
    result['navigation_passed'] = result['passed']
    result['shutdown_clean'] = code == 0 and not result['engine_errors']
    result['passed'] = result['navigation_passed'] and result['shutdown_clean']
    result['route'] = route
    results.append(result)
    print(route, 'navigation PASS' if result['navigation_passed'] else 'navigation FAIL','exit',code,'engine errors',len(result['engine_errors']),flush=True)
    if not result['navigation_passed']: print(text[-5500:],flush=True)
    (OUT/'run.json').write_text(json.dumps({'stage':str(stage),'results':results},indent=2),encoding='utf-8')
raise SystemExit(0 if all(r['passed'] and r['exit_code']==0 for r in results) else 1)
