"""Shared museum rig: idle drift, pointer switches, avatar, jump and landing."""
from pathlib import Path
import json, os, shutil, subprocess, sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-19-void-museum-player'
OUT.mkdir(parents=True, exist_ok=True)
if '--staged' not in sys.argv:
    subprocess.run([sys.executable, str(ROOT/'tools/test_void_game.py'), '--reuse', '--stage-only', '--out='+str(OUT)], check=True)
stage = Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
godot = os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
receipts = {}
cases = [('rig','void_museum_rig_probe.gd','rig-checks.json'),
         ('avatar','void_avatar_probe.gd','checks.json'),
         ('fall','void_fall_probe.gd','checks.json'),
         ('landing','void_corner_landings_probe.gd','landing-checks.json')]
if '--rig-only' in sys.argv: cases = cases[:1]
selected = next((a.split('=',1)[1] for a in sys.argv if a.startswith('--case=')),None)
if selected: cases = [c for c in cases if c[0] in selected.split(',')]
for label, probe, checks in cases:
    shutil.copy2(ROOT/'tools/probes'/probe, stage/'tools/probes'/probe)
    case_out = OUT/label
    case_out.mkdir(exist_ok=True)
    with (case_out/'engine.log').open('w',encoding='utf-8') as log:
        proc = subprocess.run([godot,'--headless','--fixed-fps','60','--path',str(stage),'--xr-mode','off',
            '--script','res://tools/probes/'+probe,'--','--out='+str(case_out)], stdout=log,stderr=log,timeout=180,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    text = (case_out/'engine.log').read_text(encoding='utf-8',errors='replace')
    assert proc.returncode == 0 and 'SCRIPT ERROR' not in text and '\nERROR:' not in text, text[-7500:]
    result = json.loads((case_out/checks).read_text())
    assert result['passed'], result
    receipts[label] = {'passed':True, 'assertions':len(result['checks']), 'shutdown_warning':'ObjectDB instances leaked' in text}
    (OUT/(label+'-receipt.json')).write_text(json.dumps(receipts[label],indent=2)+'\n',encoding='utf-8')
    print(f'{label}: {len(result["checks"])} checks passed', flush=True)
(OUT/'receipt.json').write_text(json.dumps(receipts,indent=2)+'\n',encoding='utf-8')
