"""Publish finite-map captures and bounded native/package evidence."""
from pathlib import Path
import hashlib
import html
import json

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
checks = json.loads((HERE / 'checks.json').read_text(encoding='utf-8'))
process = json.loads((HERE / 'process.json').read_text(encoding='utf-8'))
package = json.loads((HERE / 'package-receipt.json').read_text(encoding='utf-8'))
assert checks['passed'] and process['clean_exit'] and package['passed']
native_count = len(checks['checks'])
package_count = len(package['native']['checks'])
log = (HERE / 'stdout.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR:' not in log and 'Parse Error:' not in log
sources = sorted((ROOT / 'commons/museum_runner').rglob('*.gd'))
sources += sorted((ROOT / 'commons/museum_runner').rglob('*.tscn'))
sources += [ROOT / path for path in ['commons/museum_runner/README.md',
    'tools/test_museum_runner.py', 'tools/test_museum_runner_package.py',
    'tools/probes/museum_runner_levels.gd', 'tools/probes/museum_runner_xr_input.gd',
    'tools/probes/museum_runner_package_probe.gd']]
hashes = {}
for source in sources:
    relative = source.relative_to(ROOT).as_posix()
    hashes[relative] = hashlib.sha256(source.read_bytes()).hexdigest()
    target = HERE / 'sources' / (relative + '.txt')
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(source.read_bytes())
delivery_path = HERE / 'quest-build.json'
delivery = json.loads(delivery_path.read_text(encoding='utf-8')) if delivery_path.exists() else {
    'status': 'Quest build is being prepared. The new level flow has not yet been played on the headset.'}
receipt = {'revision': '2026-10-18-level-checkpoints-1', 'native_checks': native_count,
    'package_runtime_checks': package_count, 'package_checks': len(package['checks']),
    'native_passed': checks['passed'], 'package_passed': package['passed'],
    'sources': hashes, 'quest_delivery': delivery, 'physical_level_playtest': False,
    'scope': 'Native Godot and compiled Windows PCK using Android exclusions. Finish-boundary tests use controlled positions; they are not full human playthroughs.',
    'renderer_warnings': {'null_material': log.count('Parameter "material" is null.'),
        'leaked_texture': log.count('leaked 349524 bytes.'),
        'objectdb': 'ObjectDB instances leaked' in log}}
(HERE / 'receipt.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
report = f'''# Museum Runner — four maps and saved progress

18 October 2026. Revision `2026-10-18-level-checkpoints-1`.

The runner now loads four separate map scenes inside the shared XR viewing rig:
Point / Line (108 m), Face / Body (144 m), Transformation (144 m), and Array / Colour (180 m).
Each has its own seed, visual family, starting speed and finish gate. The black sphere and
centred view remain consistent. Head tracking and the existing shooting controls are retained.

Before: the visual families rotated through one endless course. Only the best score was saved.
Now: reaching a finish wins the map and saves the next map plus cumulative earned score.
Press A/X or Space to continue. A collision stops the attempt; retry restores the saved
start of the current map, its layout and banked score. Pickups from a failed attempt do
not accumulate in the checkpoint. Closing on a win screen preserves the next map.

After the fourth map, completion is saved and A/X returns to the museum. There is no
automatic wrap to map one. Checkpoints are at map starts, not at individual obstacles.

## Save behaviour

`campaign.gd` reads/writes the runner's existing `user://museum-runner/best.cfg`.
Legacy best-only files retain the record and start at map one. Stable map IDs identify
the next map. Unknown or invalid checkpoint data falls back to the first map without
discarding a valid best score. Museum progression is separate.

A temporary file is written before replacing the checkpoint. Advancement happens only
after a successful write. A write failure leaves the finish reached and offers Retry save.
An unfinished attempt can set a best-score record, but cannot advance its saved map or score.

## Verification

**{native_count}/{native_count} native assertions and {package_count}/{package_count} compiled-package runtime assertions passed.**
The package harness also passes {len(package['checks'])} packaging/provenance checks.
Tests cover the existing steering, shooting and collision behaviour, plus finish/save,
duplicate finish protection, checkpoint retry, fresh-instance reload, save migration,
invalid records, a real failed file replacement and retry, collision on the finish tick,
scene cleanup, unchanged XR origin, each map and final completion.

Images are real Godot test captures. The finish checks position the runner near each
boundary; they do not claim a human playthrough or a verified difficulty curve.
The native harness still emits renderer teardown warnings (null materials, texture
release and ObjectDB); counts are in receipt.json and full output is retained. No GDScript
parse/runtime error appears in the final native run.

## Quest

{delivery['status']}

Physical steering was confirmed on the preceding build. The new level transitions,
checkpoint persistence and map pacing have not yet had a human Quest playthrough.
See `quest-build.json` when available; installation alone does not establish that test.

## Files

- `commons/museum_runner/game.gd`: level flow, finish detection, checkpoint UI.
- `commons/museum_runner/campaign.gd`: migration and persistent checkpoints.
- `commons/museum_runner/runner_map.gd`, `maps/*.tscn`: the four maps and finish gate.
- `tools/probes/museum_runner_levels.gd`: shared native and packaged level tests.

Run `python tools/test_museum_runner.py --render` and `python tools/test_museum_runner_package.py`.
'''
(HERE / 'REPORT.md').write_text(report, encoding='utf-8')
page = (HERE / 'template.html').read_text(encoding='utf-8')
page = page.replace('__NATIVE__', str(native_count)).replace('__PACKAGE__', str(package_count))
page = page.replace('__DELIVERY__', html.escape(delivery['status']))
(HERE / 'index.html').write_text(page, encoding='utf-8')
print(HERE / 'index.html')
