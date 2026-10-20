"""Verify the shared cliff slabs and unchanged floor-fall contract in Godot."""
from pathlib import Path
import json, os, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-19-void-cliff-landings'
OUT.mkdir(parents=True, exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], cwd=ROOT, check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
# No new external assets: refresh the shared architecture in the resolved stage.
for source in (ROOT/'commons/void').iterdir():
    if source.suffix in {'.gd', '.json', '.tscn', '.gdshader'}:
        shutil.copy2(source, stage/source.relative_to(ROOT))
for name in ['void_cliff_probe.gd', 'void_cliff_capture.gd']:
    shutil.copy2(ROOT/'tools/probes'/name, stage/'tools/probes'/name)
godot = os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
runs = [('cliffs', 'void_cliff_probe.gd'), ('fall-regression', 'void_fall_probe.gd')]
if '--capture' in sys.argv: runs.append(('capture', 'void_cliff_capture.gd'))
for label, script in runs:
    log_path = OUT/(label+'.log')
    with log_path.open('w', encoding='utf-8') as log:
        result = subprocess.run([godot, '--no-window' if label=='capture' else '--headless', '--path', str(stage),
            '--rendering-method', 'mobile', '--xr-mode', 'off', '--fixed-fps', '60', '--script',
            'res://tools/probes/'+script, '--', '--out='+str(OUT)], stdout=log, stderr=subprocess.STDOUT,
            timeout=240, creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    text = log_path.read_text(encoding='utf-8', errors='replace')
    assert result.returncode == 0 and 'SCRIPT ERROR' not in text and '\nERROR:' not in text, text[-9000:]
    print(label+': passed', flush=True)
for name in ['cliff-checks.json', 'checks.json']:
    receipt = json.loads((OUT/name).read_text(encoding='utf-8'))
    assert receipt['passed'], receipt
    print(f"{name}: {len(receipt['checks'])} checks", flush=True)
