"""Reconstruct the eight printed ML lessons and retain one dated route receipt."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys
from datetime import datetime, timezone

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-11-ml-whole-route'
HALLS = [
    ('ML_Evolution', 'evolution', '2026-10-11-evolution-what-keeps-a-body', 'ml-environment', 'finite'),
    ('ML_Gradient_Landscape', 'gradient', '2026-10-11-gradient-a-line-and-a-loss', 'ml-gradient', 'huber'),
    ('ML_Classification', 'classification', '2026-10-11-classification-a-group-without-a-name', 'ml-classification', 'means'),
    ('ML_Neural_Networks', 'network', '2026-10-11-networks-what-a-weight-keeps', 'ml-network', 'fitted'),
    ('ML_Perception', 'pose', '2026-10-11-perception-teach-a-sphere', 'ml-lineage', 'response'),
    ('ML_Sequence_Memory', 'sequence', '2026-10-11-memory-both-hands', 'ml-lineage', 'replay'),
    ('ML_Generative', 'generative', '2026-10-11-generative-a-phrase-varied', 'ml-lineage', 'generated'),
    ('ML_Synthesis', 'synthesis', '2026-10-11-synthesis-an-intention-kept', 'ml-lineage', 'checks'),
]

def handoff():
    (OUT/'handoff-fixtures').mkdir(parents=True, exist_ok=True)
    (OUT/'handoff-tests.json').unlink(missing_ok=True)
    with (OUT/'handoff-engine.log').open('w', encoding='utf-8') as log:
        result = subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--xr-mode', 'off', '--audio-driver', 'Dummy', '--path', str(ROOT), '--script', 'res://tools/probes/ml_sequence_handoff_test.gd', '--', '--no-bridges'], stdout=log, stderr=subprocess.STDOUT, timeout=75, creationflags=0x08000000)
    lines = (OUT/'handoff-engine.log').read_text(encoding='utf-8', errors='replace')
    print('\n'.join(line for line in lines.splitlines() if 'HANDOFF ' in line or 'SCRIPT ERROR' in line or 'Parse Error' in line), flush=True)
    receipt = json.loads((OUT/'handoff-tests.json').read_text(encoding='utf-8')) if (OUT/'handoff-tests.json').exists() else {}
    assert result.returncode == 0 and receipt.get('passed') and 'SCRIPT ERROR' not in lines, 'See handoff-engine.log'

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    receipt = {'time': datetime.now(timezone.utc).isoformat(), 'method': 'Author-informed exact-print reconstruction; synthetic fixtures, not a blind student or a human VR evaluation.', 'lessons': []}
    for hall, suffix, report, study, picture in HALLS:
        run = subprocess.run([sys.executable, str(ROOT/f'tools/test_ml_{suffix}_lesson.py')], cwd=ROOT, capture_output=True, text=True, encoding='utf-8', errors='replace')
        target = OUT / 'evidence' / hall
        target.mkdir(parents=True, exist_ok=True)
        (target/'runner.log').write_text(run.stdout+run.stderr, encoding='utf-8')
        prior = ROOT / 'doc/book/iterations' / report
        test = json.loads((prior/'tests.json').read_text(encoding='utf-8')) if (prior/'tests.json').exists() else {}
        assert run.returncode == 0 and test.get('passed'), (hall, run.stdout[-2500:], run.stderr)
        for name in ['tests.json', 'reconstruction.json', 'tests-engine.log']:
            shutil.copy2(prior/name, target/name)
        exact = OUT / 'learner' / hall
        exact.mkdir(parents=True, exist_ok=True)
        sources = {}
        for path in (prior/'learner/printed').glob('*.gd'):
            assert path.read_text(encoding='utf-8') == (ROOT/'doc/book/studies'/study/path.name).read_text(encoding='utf-8'), (hall, path.name)
            shutil.copy2(path, exact/path.name)
            sources[path.name] = hashlib.sha256(path.read_bytes()).hexdigest()
        receipt['lessons'].append({'hall':hall, 'checks':len(test['checks']), 'passed':True, 'exact_files':sources})
        print(hall, len(test['checks']), 'PASS', flush=True)
    first = [OUT/'learner'/row[0]/'point_body.gd' for row in HALLS[:4]]
    last = [OUT/'learner'/row[0]/'point_body.gd' for row in HALLS[4:]]
    assert len({p.read_bytes() for p in first}) == 1
    assert len({p.read_bytes() for p in last}) == 1
    receipt['class_lineage'] = 'First four share one unchanged PointBody. Perception explicitly revises radius/collision/desktop handling; last four carry that exact revision.'
    receipt['passed'] = True
    receipt['total_checks'] = sum(row['checks'] for row in receipt['lessons'])
    (OUT/'sequence-tests.json').write_text(json.dumps(receipt, indent=2), encoding='utf-8')
    print('ALL PRINTED LESSONS:', receipt['total_checks'], 'PASS', flush=True)
    handoff()

if __name__ == '__main__':
    sys.stdout.reconfigure(encoding='utf-8')
    handoff() if '--handoff-only' in sys.argv else main()
