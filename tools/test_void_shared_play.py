"""Check desktop and XR adapters against the same native tower and game rules."""
from pathlib import Path
import json, os, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-19-void-shared-play'
OUT.mkdir(parents=True, exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
godot=os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
cases=[('parity','void_shared_play_probe.gd','parity-checks.json'),
       ('spider','void_spider_probe.gd','spider-checks.json'),
       ('tower','void_spider_tower_probe.gd','tower-checks.json'),
       ('fall','void_fall_probe.gd','checks.json'),
       ('landing','void_corner_landings_probe.gd','landing-checks.json'),
       ('rig','void_museum_rig_probe.gd','rig-checks.json'),
       ('avatar','void_avatar_probe.gd','checks.json')]
selected=next((a.split('=',1)[1] for a in sys.argv if a.startswith('--case=')),None)
if selected: cases=[c for c in cases if c[0] in selected.split(',')]
for source in (ROOT/'commons/void').glob('*.gd'):
    shutil.copy2(source,stage/'commons/void'/source.name)
for label,probe,receipt in cases:
    shutil.copy2(ROOT/'tools/probes'/probe,stage/'tools/probes'/probe)
    folder=OUT/label;folder.mkdir(exist_ok=True)
    result_file=folder/receipt
    if result_file.exists(): result_file.unlink()
    with (folder/'engine.log').open('w',encoding='utf-8') as log:
        # Headless DisplayServer cannot capture a mouse. Exercise the actual
        # capture guard with a native window backend for mouse-input cases.
        display=['--no-window','--rendering-method','mobile'] if label in ['parity','tower'] else ['--headless']
        result=subprocess.run([godot,*display,'--fixed-fps','60','--path',str(stage),'--xr-mode','off',
            '--script','res://tools/probes/'+probe,'--','--out='+str(folder)],stdout=log,stderr=log,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    text=(folder/'engine.log').read_text(encoding='utf-8',errors='replace')
    if result.returncode or 'SCRIPT ERROR' in text or '\nERROR:' in text:
        raise SystemExit(text[-16000:])
    data=json.loads(result_file.read_text())
    assert data['passed'],data
    print(f'{label}: {len(data["checks"])} checks passed',flush=True)
