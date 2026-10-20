"""Exercise both production sticks in an artifact room and in The Void."""
from pathlib import Path
import json
import os
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-18-void-movement-room'
OUT.mkdir(parents=True, exist_ok=True)
command = [os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
           '--no-window' if '--capture' in sys.argv else '--headless', '--audio-driver','Dummy',
           '--path',str(ROOT),'--rendering-method','mobile','--xr-mode','off', '--max-fps','90',
           'res://tools/probes/void_motion_probe.tscn','--','--out='+str(OUT)]
if '--capture' in sys.argv: command.append('--capture')
if '--menu-only' not in sys.argv:
    with (OUT/'engine.log').open('w',encoding='utf-8') as log:
        result = subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=240,
                                creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    log = (OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
    assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, log[-7000:]
    receipt=json.loads((OUT/'checks.json').read_text())
    assert receipt['passed'],receipt
    print(f"{len(receipt['checks'])} checks passed; {len(receipt['trials'])} movement trials. {OUT}")

# Compare the existing headless menu's known cleanup message with the new route.
if '--menu' in sys.argv or '--menu-only' in sys.argv:
    menu_counts = []
    for name, flag in [('menu-baseline','--void-menu-only'),('menu-room','--void-motion-room')]:
        menu_command = [command[0],'--headless','--audio-driver','Dummy','--path',str(ROOT),
                        '--xr-mode','off','--script','res://tools/probes/void_menu_probe.gd',
                        '--','--no-bridges','--out='+str(OUT),flag]
        with (OUT/(name+'.log')).open('w',encoding='utf-8') as stream:
            run = subprocess.run(menu_command,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,timeout=80,
                                 creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
        text = (OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
        errors = [line for line in text.splitlines() if line.startswith('ERROR:')]
        assert run.returncode==0 and 'SCRIPT ERROR' not in text and all(line=='ERROR: Parameter "material" is null.' for line in errors),text[-6000:]
        menu_counts.append(len(errors))
    assert menu_counts[0]==menu_counts[1],menu_counts
    assert json.loads((OUT/'menu-checks.json').read_text())['passed']
    (OUT/'menu-baseline.json').write_text(json.dumps({'unchanged_material_cleanup_messages':menu_counts[0]}))
    print('Menu entry and room-to-tower staging route passed.')
