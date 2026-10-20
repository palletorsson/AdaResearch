"""Publish the installed P3 study and test the code printed in its companion."""
from pathlib import Path
import hashlib
import html
import json
import re
import shutil
import subprocess
import markdown

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-09-samples-and-disagreement'
RUN = ROOT / 'ada_run/encounter_pilot/Randomness_Examples_of_Randomness/uncertainty-budget'
ART = ROOT / 'algorithms/randomness/monte_carlo_dartboard'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

core = (ART / 'sample_run.gd').read_text(encoding='utf-8').strip()
check_code = '''extends SceneTree
const SampleRun = preload("res://sample_run.gd")

func _initialize() -> void:
\tvar run = SampleRun.new(1847)
\tassert(is_nan(run.estimate()))
\tassert(SampleRun.in_circle(Vector2(1, .5)))
\tassert(not SampleRun.in_circle(Vector2.ONE))
\tfor i in 100:
\t\trun.next_sample()
\tvar saved: Dictionary = run.snapshot()
\tassert(saved.total == 100)
\tassert(is_equal_approx(run.estimate(), 4.0 * run.inside / 100))
\trun.reset(1847)
\tfor i in 100:
\t\trun.next_sample()
\tassert(run.points == saved.points)
\tvar state: int = run.rng.state
\tvar rows: Array = run.compare_seeds(1847, 500)
\tassert(rows.size() == 8 and rows[7].seed == 1854)
\tassert(run.rng.state == state and run.points == saved.points)
\tprint("SAMPLE COMPANION: 8 assertions passed")
\tquit()
'''
companion = '''# Keep the run

**Optional sampling companion · Randomness_Examples_of_Randomness · 9 October 2026**

At the existing dartboard, press REPLAY, then FILL. Turn BUDGET from 500 to 2000 and fill again. The dial restarts the same seed: the first 500 samples recur before the new ones arrive. Now press NEXT SEED and FILL. The rule and budget stay fixed; the sampled positions change. Press 8 SEEDS to compare eight runs without disturbing yours.

**Learning elements:** local random stream; retained sample list; circle membership; count and ratio; replay; sample budget; variability across seeds.

This companion inspects the installed estimator. The museum board, markers, dial and buttons are supplied. The code below is its complete sampling core, with a small executable check. It creates data, not another board. The hall's [main tutorial](../../../../commons/maps/Randomness_Examples_of_Randomness/tutorial.md) separately reconstructs a small learner board with the carried PointBody. Its scene and interaction code are not prerequisites for running this core.

Two uniform draws place a sample inside the unit square. The circle has centre (0.5, 0.5) and radius 0.5. Squared distance at most 0.25 means inside, including the boundary. Its area is π/4 of the square, so `4.0 * inside / total` estimates π. Before any samples, there is no estimate; `NAN` records that absence. The display shows a dash.

The seed chooses a repeatable local stream in this engine build. Reset must rewind that stream as well as clear the points. `snapshot()` copies the list so replay cannot erase the saved record. Comparing seeds constructs separate samplers; it neither consumes nor reseeds the current run or the museum's global generator. Repeatability across future engine versions is not promised.

Save this first file as **sample_run.gd** in a small Godot project's root. It is the same core used by the installed artifact.

```gdscript
CORE
```

`next_sample()` adds one record. `estimate()` reads every retained record's classification. The 8000-sample cap bounds this study; callers must stop before the next sample would exceed it. `compare_seeds()` repeats the same operation under each seed and returns signed differences from Godot's `PI` constant. It supplies no confidence interval.

Save **sample_check.gd** beside it. Run with the Godot executable: `godot --headless --path <project-folder> --script res://sample_check.gd`. No `.tscn`, scene-path lookup, headset or add-on is required for this data check. Return to the existing museum for the spatial interaction.

```gdscript
CHECK
```

The check asks whether a known boundary is included, an empty run has no estimate, the ratio uses the count, replay recovers the same positions, and comparison preserves the active run. It does not assert that every new sample improves the estimate: that would be the wrong contract.

**Try independently:** use seed 1850, keep a snapshot at 200 samples, then continue to 500. Reset and draw 500 again. Check that the first 200 positions match the saved list. Compare the two estimates; either can be closer to π in an individual run. Explain why unchanged sample order and improved accuracy are different claims.

**Back at the board:** all samples contribute to the count, but only the newest 300 markers stay visible. The console states both quantities. A display budget is not a sample budget. What travels onward is a retained record and a declared interpretation of it.
'''.replace('CORE', core).replace('CHECK', check_code.strip())
OUT.mkdir(parents=True, exist_ok=True)
(OUT / 'sampler.md').write_text(companion, encoding='utf-8')

# Reconstruct from the printed fences, not from a second hidden implementation.
temp = ROOT / 'ada_run/sample_budget_printed'
temp.mkdir(parents=True, exist_ok=True)
(temp / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Sample companion"\n', encoding='utf-8')
blocks = re.findall(r'```gdscript\n(.*?)\n```', (OUT / 'sampler.md').read_text(encoding='utf-8'), re.S)
assert len(blocks) == 2
for name, block in zip(['sample_run.gd', 'sample_check.gd'], blocks):
    (temp / name).write_text(block + '\n', encoding='utf-8')
probe = (ROOT / 'tools/probes/sample_budget_test.gd').read_text(encoding='utf-8')
(temp / 'full_check.gd').write_text(probe.replace('res://algorithms/randomness/monte_carlo_dartboard/sample_run.gd', 'res://sample_run.gd'), encoding='utf-8')
results = {}
for name, script in [('printed', 'full_check.gd'), ('printed-smoke', 'sample_check.gd')]:
    report = OUT / 'validation' / (name + '.json')
    if report.exists():
        report.unlink()
    log = OUT / 'validation' / (name + '.log')
    command = [ENGINE, '--headless', '--path', str(temp), '--script', 'res://' + script, '--', str(report)]
    with log.open('w', encoding='utf-8') as stream:
        process = subprocess.Popen(command, stdout=stream, stderr=subprocess.STDOUT, creationflags=subprocess.CREATE_NO_WINDOW)
        try:
            code = process.wait(timeout=30)
        except subprocess.TimeoutExpired:
            process.kill(); process.wait(); raise
    output = log.read_text(encoding='utf-8', errors='replace')
    assert code == 0 and 'SCRIPT ERROR' not in output and 'Parse Error' not in output, output
    if name == 'printed':
        data = json.loads(report.read_text())
        assert data['passed'] and len(data['checks']) == 24
        results[name] = {'passed': True, 'checks': 24}
    else:
        assert 'SAMPLE COMPANION: 8 assertions passed' in output
        results[name] = {'passed': True, 'assertions': 8}
(OUT / 'validation/printed-results.json').write_text(json.dumps(results, indent=2), encoding='utf-8')

museum = json.loads((RUN / 'report.json').read_text())
assert museum['passed'] and len(museum['checks']) == 25 and not museum['failures']
native_log = (RUN / 'stdout.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR' not in native_log and 'Parse Error' not in native_log
(OUT / 'museum').mkdir(exist_ok=True)
for name in ['report.json', 'stdout.log', 'visitor.png', 'raised.png', 'overhead.png', 'controls.png', 'seed-comparison.png', 'budget-8000.png']:
    shutil.copy2(RUN / name, OUT / 'museum' / name)

sources = [ART / name for name in ['sample_run.gd', 'sample_console.gd', 'monte_carlo_dartboard.gd', 'monte_carlo_dartboard.tscn']]
sources += [ROOT / name for name in ['commons/maps/Randomness_Examples_of_Randomness/map_data.json', 'tools/probes/sample_budget_test.gd', 'tools/probes/sample_budget_room.gd', 'tools/test_sample_budget.py', 'tools/run_encounter_probe.py']]
manifest = []
for path in sources:
    dest = OUT / 'source' / path.relative_to(ROOT)
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(path, dest)
    manifest.append({'path': path.relative_to(ROOT).as_posix(), 'sha256': hashlib.sha256(path.read_bytes()).hexdigest()})
(OUT / 'source-manifest.json').write_text(json.dumps(manifest, indent=2), encoding='utf-8')

style = '''*{box-sizing:border-box}body{margin:0;background:#f4f0e8;color:#232d30;font:19px/1.65 Georgia,serif}header,main,footer{max-width:1240px;margin:auto;padding:32px}header{padding-top:64px}h1{font-size:clamp(38px,6vw,76px);line-height:1.04;max-width:1000px}h2{margin-top:2.4em;line-height:1.2}p,li{max-width:78ch}a{color:#8e335a;text-underline-offset:4px}nav,figcaption,.eyebrow{font:14px/1.5 system-ui}nav{display:flex;gap:22px;flex-wrap:wrap}.eyebrow{letter-spacing:.09em;text-transform:uppercase}img{display:block;max-width:100%;height:auto;border:1px solid #cbc4b7}figure{margin:32px 0}figcaption{color:#596363;padding-top:10px}pre{background:#17262b;color:#f6f1e7;padding:24px;overflow:auto;font:14px/1.65 Consolas,monospace}code{font-size:.85em}pre code{font-size:inherit}table{border-collapse:collapse;display:block;overflow:auto;font:15px/1.5 system-ui}td,th{padding:14px;text-align:left;border-bottom:1px solid #c5c8c0}footer{border-top:1px solid #c5c8c0}.pair{display:grid;grid-template-columns:1fr 1fr;gap:22px}@media(max-width:750px){.pair{display:block}header,main,footer{padding:22px}}'''
nav = '<nav><a href="index.html">Museum report</a><a href="sampler.html">Runnable sampler</a><a href="sampler.md">Sampler Markdown</a><a href="../../course/uncertainty-plan/index.html">Sequence plan</a></nav>'
for name, title, source in [('index.html', 'Spend samples, keep the disagreement', 'REPORT.md'), ('sampler.html', 'Keep the run', 'sampler.md')]:
    body = markdown.markdown((OUT / source).read_text(encoding='utf-8'), extensions=['fenced_code', 'tables'])
    page = f'<!doctype html><html lang="en"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>{html.escape(title)}</title><style>{style}</style></head><body><header><div class="eyebrow">Endless Museum · 9 October 2026 · uncertainty P3</div>{nav}</header><main>{body}</main><footer>Native Godot captures. Desktop pointer and simulated XRTools controller tested; physical headset and independent learner review remain open.</footer></body></html>'
    (OUT / name).write_text(page, encoding='utf-8')
links = 0
(OUT / 'validation.json').write_text('{}', encoding='utf-8')
for path in OUT.glob('*.html'):
    for ref in re.findall(r'(?:href|src)="([^"]+)"', path.read_text(encoding='utf-8')):
        if ref.startswith(('http:', 'https:', '#')):
            continue
        assert (path.parent / ref.split('#')[0]).exists(), (path, ref)
        links += 1
receipt = {'date': '2026-10-09', 'core_checks': 24, 'rejected_faults': 2, 'printed_core_checks': 24, 'printed_smoke_assertions': 8, 'museum_checks': 25, 'supported_route_samples': 50, 'local_links': links, 'source_manifest': 'source-manifest.json', 'images': 'Byte copies of native room probe captures; principal views visually inspected.', 'scope': 'Optional installed Monte Carlo study and printed data core. Main hall tutorial is separately authored/tested. No physical headset, Quest, performance budget or independent learner certification.'}
(OUT / 'validation.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
print(json.dumps(receipt, indent=2))
