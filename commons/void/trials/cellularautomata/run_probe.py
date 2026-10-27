"""Cellular Automata transfer trial: run probe.gd in the actual Void with isolated saves.

Coordinator-run only (the transfer rules forbid parallel Godot). Mirrors
tools/test_noise_trial.py: stages a throwaway project, runs the probe headless
(`--capture` for Mobile screenshots), checks the engine log, and verifies the
original texts and the curated tower are unchanged afterwards.

    python commons/void/trials/cellularautomata/run_probe.py [--capture] [--verbose]
"""
from pathlib import Path
import hashlib, json, os, subprocess, sys
ROOT = Path(__file__).resolve().parents[4]
sys.path.insert(0, str(ROOT / 'tools'))
from void_trial_runtime import stage_runtime  # noqa: E402
sys.stdout.reconfigure(encoding='utf8')
capture = '--capture' in sys.argv
OUT = ROOT / 'doc/book/iterations/2026-10-21-void-cellularautomata-transfer' / ('images' if capture else 'tests')
OUT.mkdir(parents=True, exist_ok=True)
GUARDED = ['commons/void/rooms.json', 'commons/void/layout.json', 'commons/void/catalog.json',
           'commons/void/trials/playable.json', 'commons/void/trials/transformation/rooms.json',
           'commons/maps/CA_Introduction/map_data.json', 'commons/maps/CA_Introduction/final.md',
           'commons/maps/CA_Introduction/tutorial.md', 'commons/maps/CA_ElementaryRules/map_data.json',
           'commons/maps/CA_ElementaryRules/final.md', 'commons/maps/CA_ElementaryRules/tutorial.md']
before = {n: hashlib.sha256((ROOT / n).read_bytes()).hexdigest() for n in GUARDED}
stage = stage_runtime()
args = [os.environ.get('GODOT_EXE', 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),
        '--no-window' if capture else '--headless', '--path', str(stage), '--rendering-method', 'mobile',
        '--xr-mode', 'off', '--fixed-fps', '60',
        '--script', 'res://commons/void/trials/cellularautomata/probe.gd', '--', '--no-bridges', '--out=' + str(OUT)]
if capture: args.append('--capture')
if '--verbose' in sys.argv: args.insert(1, '--verbose')
with (OUT / 'engine.log').open('w', encoding='utf-8') as log:
    result = subprocess.run(args, stdout=log, stderr=subprocess.STDOUT, timeout=600,
                            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
log = (OUT / 'engine.log').read_text(encoding='utf-8', errors='replace')
after = {n: hashlib.sha256((ROOT / n).read_bytes()).hexdigest() for n in before}
assert before == after, 'Shared Void files or the original CA texts changed during the run'
report = json.loads((OUT / 'checks.json').read_text()) if (OUT / 'checks.json').exists() else {}
assert result.returncode == 0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log, (report.get('failed'), log[-9000:])
assert report['passed'], report['failed']
print(f"{len(report['checks'])} checks passed. Shared Void files and the original CA texts are unchanged. Bounds in {OUT / 'measure.json'}")
