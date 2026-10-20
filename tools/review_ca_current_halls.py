"""Fresh, isolated museum regressions; keep old receipts untouched."""
from pathlib import Path
import json, subprocess, sys, shutil

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-10-ca-current-pass'
PAIRS = [
    ('CA_Introduction', 'ca_row_museum'),
    ('CA_ElementaryRules', 'ca_states_room'),
    ('CA_GameOfLife', 'ca_history_room'),
    ('CA_BeyondBinary', 'ca_life_room'),
    ('CA_ExpandingSpace', 'ca_proximity_room'),
    ('CA_SoftRules', 'ca_exchange_room'),
    ('CA_AgentsCircuits', 'ca_comparison_room'),
    ('CA_EdgeOfChaos', 'ca_difference_room'),
]

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    O.mkdir(parents=True, exist_ok=True)
    results = []
    for hall, probe in PAIRS:
        cmd = [sys.executable, '-X', 'utf8', str(R/'tools/run_encounter_probe.py'), hall,
               '--sequence', 'cellularautomata', '--render', '--no-bridges',
               '--probe', str(R/'tools/probes'/(probe+'.gd')), '--output-tag', 'oct10-review']
        run = subprocess.run(cmd, cwd=R, capture_output=True, text=True, encoding='utf-8')
        source = R/'ada_run/encounter_pilot'/hall/'oct10-review'
        dest = O/'museum'/hall
        dest.mkdir(parents=True, exist_ok=True)
        for p in source.iterdir():
            if p.suffix in ['.png'] or p.name in ['report.json','engine.log','stdout.log','source_manifest.json','spec.json']:
                shutil.copy2(p, dest/p.name)
        log = (source/'engine.log').read_text(encoding='utf-8', errors='replace') if (source/'engine.log').exists() else ''
        data = json.loads((source/'report.json').read_text(encoding='utf-8')) if (source/'report.json').exists() else {}
        errors = [line for line in log.splitlines() if any(k in line for k in ['SCRIPT ERROR:', 'Parse Error:', 'SHADER ERROR:'])]
        diagnostics = sorted(set(line for line in log.splitlines() if line.startswith('ERROR:')))
        result = {'hall': hall, 'exit': run.returncode, 'checks': len(data.get('checks', [])),
                  'failures': data.get('failures', []), 'errors': errors, 'engine_diagnostics': diagnostics,
                  'passed': run.returncode == 0 and data.get('passed', False) and not errors}
        results.append(result)
        (O/'museum-runs.json').write_text(json.dumps(results, indent=2)+'\n', encoding='utf-8')
        print(json.dumps(result), flush=True)
    raise SystemExit(0 if all(r['passed'] for r in results) else 1)
