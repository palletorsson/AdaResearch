"""Apply the narrow Void-only flight fix and regression while holding the native lock."""
import json
from pathlib import Path
import subprocess
import sys

sys.stdout.reconfigure(encoding='utf8')

ROOT = Path(__file__).resolve().parents[3]
sys.path.insert(0, str(ROOT / 'tools'))
from void_native_slot import acquire_native_slot
from void_trial_runtime import stage_runtime

batch = Path(__file__).resolve().parent
with acquire_native_slot('Codex batch25 flight residency fix + regression', timeout=55):
    path = ROOT / 'commons/void/floor_residency.gd'
    source = path.read_text(encoding='utf8')
    if 'state.flight_group=' not in source:
        edits = [
            ('\t\tif node is Node3D: state.visible=node.visible', '\t\tstate.flight_group=node.is_in_group("ada_museum_flight")\n\t\tif node is Node3D: state.visible=node.visible'),
            ('\t# Explicit modes also stop artifacts', '\t# Desktop and XR look up flight by group even when this floor is paused.\n\t# Withdraw inactive volumes and restore membership when their floor is live.\n\tif node.is_in_group("ada_museum_flight"): node.remove_from_group("ada_museum_flight")\n\t# Explicit modes also stop artifacts'),
            ('\t\tnode.process_mode=state.mode', '\t\tnode.process_mode=state.mode\n\t\tif state.get("flight_group",false): node.add_to_group("ada_museum_flight")'),
        ]
        for old, new in edits:
            assert source.count(old) == 1, old
            source = source.replace(old, new)
        path.write_text(source, encoding='utf8')
    stage = stage_runtime()
    with (batch / 'flight-residency-regression.log').open('w', encoding='utf8') as stream:
        result = subprocess.run([
            'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(stage),
            '--xr-mode', 'off', '--script', 'res://doc/void-transfer/2026-10-21-batch-25/check_flight_residency.gd',
            '--', '--no-bridges'], stdout=stream, stderr=subprocess.STDOUT, timeout=45, creationflags=subprocess.CREATE_NO_WINDOW)
    log = (batch / 'flight-residency-regression.log').read_text(encoding='utf8')
    errors = [line for line in log.splitlines() if 'SCRIPT ERROR' in line or line.startswith('ERROR:')]
    receipt = {'passed': result.returncode == 0 and not errors and 'FLIGHT_RESIDENCY_RESULT true' in log,
               'exit_code': result.returncode, 'errors': errors,
               'scope': 'actual flight lookup across live/hidden/preview, repeated refresh and freed-child restoration; headless, not locomotion'}
    (batch / 'flight-residency-regression.json').write_text(json.dumps(receipt, indent=2)+'\n', encoding='utf8')
    print(log[-5000:])
    assert receipt['passed'], receipt
