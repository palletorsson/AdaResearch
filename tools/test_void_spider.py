"""Run real creature/projectile, tower placement, and desktop/XR fall regressions."""
from pathlib import Path
import json, os, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-19-void-catalyst-spider'
OUT.mkdir(parents=True, exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
godot = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
cases = [('spider','void_spider_probe.gd','spider-checks.json'),
         ('tower','void_spider_tower_probe.gd','tower-checks.json'),
         ('fall','void_fall_probe.gd','checks.json'),
         ('landing','void_corner_landings_probe.gd','landing-checks.json')]
selected = next((a.split('=',1)[1] for a in sys.argv if a.startswith('--case=')), None)
if selected: cases = [c for c in cases if c[0] in selected.split(',')]
capture = '--capture' in sys.argv
if capture: cases = [c for c in cases if c[0]=='tower']
for label, probe, receipt in cases:
    shutil.copy2(ROOT/'tools/probes'/probe, stage/'tools/probes'/probe)
    for name in ['spider.gd','spider_gait.gd','health.gd','game.gd','player_rules.gd','walker.gd','desktop_hand.gd','catalog.json','rooms.json']:
        shutil.copy2(ROOT/'commons/void'/name, stage/'commons/void'/name)
    folder=OUT/(label+'-capture' if capture else label)
    folder.mkdir(exist_ok=True)
    with (folder/'engine.log').open('w',encoding='utf-8') as log:
        rendering=['--no-window','--rendering-method','mobile'] if capture or label=='tower' else ['--headless']
        result=subprocess.run([godot,*rendering,'--fixed-fps','60','--path',str(stage),'--xr-mode','off',
            '--script','res://tools/probes/'+probe,'--','--out='+str(folder),*(['--capture'] if capture else [])],stdout=log,stderr=log,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    text=(folder/'engine.log').read_text(encoding='utf-8',errors='replace')
    if result.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise SystemExit(text[-10000:])
    data=json.loads((folder/receipt).read_text())
    assert data['passed'], data
    print(f'{label}: {len(data["checks"])} checks passed',flush=True)
