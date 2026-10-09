"""Run authored contracts and isolated Godot encounters; never edits content."""
import argparse
from datetime import datetime, timezone
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import time
import unittest
import uuid

ROOT = Path(__file__).resolve().parents[2]
HERE = Path(__file__).resolve().parent
KNOWN_STARTUP = ('Unrecognized UID: "uid://rwex60pqapc".',
                 'Failed to read the root certificate store.')

def resolve_godot(explicit):
    candidates = [explicit, os.environ.get('GODOT_EXE'), shutil.which('godot'),
                  shutil.which('godot4'), str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')]
    return next((str(Path(p).resolve()) for p in candidates if p and Path(p).is_file()), None)

def runtime_result(exit_code, report_path, output, minimum):
    """A zero exit code alone is not evidence that a test ran."""
    problems = []
    if exit_code != 0:
        problems.append(f'Godot exit code {exit_code}')
    report = {}
    try:
        report = json.loads(report_path.read_text(encoding='utf-8'))
        if not isinstance(report, dict):
            raise ValueError('Report must be an object')
        count = report.get('checks')
        failures = report.get('failures')
        if type(count) is not int or count < minimum:
            problems.append(f'Expected at least {minimum} checks; got {count!r}')
        if not isinstance(failures, list):
            problems.append('Missing failures list')
        elif failures:
            problems.extend(str(f) for f in failures)
    except (OSError, ValueError) as error:
        problems.append(f'Missing or invalid fresh test report: {error}')
    notices = [line.strip() for line in output.splitlines()
               if re.match(r'^(SCRIPT ERROR|ERROR|WARNING):', line)]
    for line in notices:
        if line.startswith(('SCRIPT ERROR:', 'ERROR:')) and not any(k in line for k in KNOWN_STARTUP):
            problems.append(line)
    return {'status': 'fail' if problems else 'pass', 'checks': report.get('checks', 0),
            'problems': problems, 'engine_notices': notices}

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--only', help='Run one case ID (use --list)')
    parser.add_argument('--list', action='store_true')
    parser.add_argument('--static-only', action='store_true', help='Godot checks are explicitly skipped')
    parser.add_argument('--godot', help='Godot executable; alternatively set GODOT_EXE')
    parser.add_argument('--timeout', type=float, default=90, help='Seconds allowed per Godot case')
    args = parser.parse_args()
    cases = json.loads((HERE/'suite.json').read_text())['cases']
    if args.list:
        print('\n'.join(c['id'] for c in cases))
        return 0
    if args.only:
        cases = [c for c in cases if c['id'] == args.only]
        if not cases: parser.error('Unknown case ID')
    if args.timeout <= 0: parser.error('--timeout must be positive')
    godot = resolve_godot(args.godot)
    run_id = datetime.now(timezone.utc).strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:8]
    folder = ROOT/'ada_run/test-results/museum'/run_id
    folder.mkdir(parents=True)
    results = []
    for case in cases:
        case_id = case['id']
        if not re.fullmatch(r'[a-z0-9-]+', case_id): raise ValueError('Invalid case ID')
        stream = io.StringIO()
        tests = unittest.defaultTestLoader.loadTestsFromName(case['static'])
        outcome = unittest.TextTestRunner(stream=stream, verbosity=2).run(tests)
        static_status = 'pass' if outcome.wasSuccessful() and outcome.testsRun > 0 and not outcome.skipped else 'fail'
        (folder/f'{case_id}-static.log').write_text(stream.getvalue(), encoding='utf-8')
        result = {'id': case_id, 'static': {'status': static_status, 'checks': outcome.testsRun},
                  'manual': [{'check': text, 'status': 'not-run'} for text in case['manual']]}
        if args.static_only:
            result['runtime'] = {'status': 'skipped', 'reason': '--static-only'}
        elif not godot:
            result['runtime'] = {'status': 'fail', 'problems': ['Godot not found. Set GODOT_EXE or --godot.']}
        else:
            scene = (ROOT/case['scene']).resolve()
            if not scene.is_relative_to(ROOT) or scene.suffix != '.tscn' or not scene.is_file():
                raise ValueError(f'Invalid test scene: {scene}')
            report_path = folder/f'{case_id}-runtime.json'
            assert not report_path.exists()
            command = [godot, '--headless', '--path', str(ROOT), '--audio-driver', 'Dummy',
                       '--xr-mode', 'off', '--log-file', str(folder/f'{case_id}-engine.log'),
                       'res://' + scene.relative_to(ROOT).as_posix(), '--', '--report=' + str(report_path)]
            start = time.monotonic()
            try:
                process = subprocess.run(command, cwd=ROOT, capture_output=True, timeout=args.timeout,
                    text=True, encoding='utf-8', errors='replace',
                    creationflags=subprocess.CREATE_NO_WINDOW if os.name == 'nt' else 0)
                output = process.stdout + process.stderr
                result['runtime'] = runtime_result(process.returncode, report_path, output, case['minimum_checks'])
            except subprocess.TimeoutExpired as error:
                # subprocess.run terminates only the process it started.
                stdout = error.stdout or b''
                stderr = error.stderr or b''
                output = (stdout + stderr).decode('utf-8', errors='replace')
                result['runtime'] = {'status': 'fail', 'problems': [f'Timeout after {args.timeout}s']}
            except OSError as error:
                output = str(error)
                result['runtime'] = {'status': 'fail', 'problems': [str(error)]}
            result['runtime']['seconds'] = round(time.monotonic() - start, 2)
            (folder/f'{case_id}-console.log').write_text(output, encoding='utf-8')
        results.append(result)
        print(f"{case_id}: authored checks {static_status.upper()}, Godot {result['runtime']['status'].upper()}", flush=True)
    failed = any(r['static']['status'] != 'pass' or r['runtime']['status'] == 'fail' for r in results)
    report = {'run_id': run_id, 'automated_status': 'fail' if failed else 'partial' if args.static_only else 'pass',
              'godot': godot, 'manual_status': 'not-run', 'results': results}
    (folder/'report.json').write_text(json.dumps(report, indent=2), encoding='utf-8')
    summary = [f"# Museum tests: {report['automated_status'].upper()}", '',
               'Manual scene and headset checks have not run.', '',
               '| Case | Authored checks | Godot |', '|---|---|---|']
    for r in results:
        summary.append(f"| {r['id']} | {r['static']['status']} ({r['static']['checks']}) | {r['runtime']['status']} |")
        for problem in r['runtime'].get('problems', []): summary.append(f"\n{r['id']}: {problem}")
    summary += ['', '## Manual checks still required', '']
    for r in results:
        summary += [f"- [ ] {r['id']}: {m['check']}" for m in r['manual']]
    (folder/'report.md').write_text('\n'.join(summary)+'\n', encoding='utf-8')
    print(f'Report: {folder / "report.md"}')
    return 1 if failed else 0

if __name__ == '__main__':
    raise SystemExit(main())
