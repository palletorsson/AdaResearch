"""Freeze and execute a fresh reader's files; never repair their first submission."""
from pathlib import Path
import argparse
import hashlib
import json
import os
import re
import shutil
import subprocess

R = Path(__file__).resolve().parents[1]
O = R / 'doc/book/iterations/2026-10-08-fractals-ghost-student'
def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def dump(path, value): path.write_text(json.dumps(value, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

def freeze():
    attempt = O / 'attempt'
    saved = O / 'submission-before-run.json'
    assert (attempt / 'review-before.md').exists(), 'Wait for the completed first submission.'
    if not saved.exists():
        records = {p.relative_to(attempt).as_posix(): sha(p) for p in attempt.rglob('*') if p.is_file()}
        assert any('prediction' in k for k in records), 'Predictions must precede execution.'
        dump(saved, records)
        shutil.copytree(attempt, O / 'first-submission')
    records = json.loads(saved.read_text(encoding='utf-8'))
    assert all(sha(attempt / name) == digest for name, digest in records.items()), 'First submission changed.'
    packet = json.loads((O / 'packet-sha256.json').read_text(encoding='utf-8'))
    assert all(sha(O / 'packet' / name) == digest for name, digest in packet.items()), 'Packet changed.'
    text = (O / 'packet/tutorial.md').read_text(encoding='utf-8')
    chunks = re.split(r'<a id="([^"]+)"></a>', text)
    files = []
    for i in range(1, len(chunks), 2):
        hall, part = chunks[i:i+2]
        for name, body in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```', part, re.S):
            path = attempt / 'reconstructed' / hall / name
            assert path.read_text(encoding='utf-8') == body + '\n', (hall, name)
            files.append({'hall': hall, 'file': name, 'sha256': sha(path)})
    assert len(files) == 16
    dump(O / 'reconstruction-parity.json', {'passed': True, 'count': len(files), 'files': files})
    return records

def run(probe, label):
    records = freeze()
    logs = O / 'logs'
    logs.mkdir(exist_ok=True)
    engine = logs / (label + '-engine.log')
    with (logs / (label + '-stdout.log')).open('w', encoding='utf-8') as out:
        result = subprocess.run([
            'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--headless', '--path', str(R),
            '--xr-mode', 'off', '--audio-driver', 'Dummy', '--log-file', str(engine), '--script', probe,
        ], cwd=R, stdout=out, stderr=subprocess.STDOUT, timeout=90,
            creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
    lines = engine.read_text(encoding='utf-8', errors='replace').splitlines()
    errors = [s for s in lines if 'SCRIPT ERROR' in s or 'Parse Error' in s]
    unchanged = all(sha(O / 'attempt' / name) == digest for name, digest in records.items())
    receipt = {'exit_code': result.returncode, 'script_errors': errors, 'first_submission_unchanged': unchanged, 'probe': probe}
    dump(O / (label + '-execution.json'), receipt)
    print(json.dumps(receipt))
    assert result.returncode == 0 and not errors and unchanged

if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--probe', default='res://tools/probes/fractals_ghost_core.gd')
    parser.add_argument('--label', default='core')
    args = parser.parse_args()
    run(args.probe, args.label)
