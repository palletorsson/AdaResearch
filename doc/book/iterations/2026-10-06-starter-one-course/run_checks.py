from pathlib import Path
import json
import subprocess
import tempfile
import zipfile
import shutil
import hashlib
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
FLAGS = subprocess.CREATE_NO_WINDOW

def main():
    packager = ROOT / 'doc/book/iterations/2026-10-03-ada-xr-starter/build.py'
    subprocess.run([sys.executable, '-X', 'utf8', str(packager)], check=True)
    work = Path(tempfile.mkdtemp(prefix='ada-starter-roundtrip-'))
    with zipfile.ZipFile(packager.parent / 'ada-xr-starter.zip') as archive:
        archive.extractall(work)
    project = work / 'ada-xr-starter'
    cfg = project / 'project.godot'
    cfg.write_text(cfg.read_text(encoding='utf-8').replace(
        'config/name="Ada — a place to begin"', 'config/name="' + work.name + '"'), encoding='utf-8')
    shutil.copy2(HERE / 'verify.gd', project / 'verify.gd')
    (HERE / 'test-project.txt').write_text(str(project), encoding='utf-8')
    command = [ENGINE, '--headless', '--path', str(project), '--xr-mode', 'off', '--audio-driver', 'Dummy']
    runs = []
    for mode in ['import', 'produce', 'close-held', 'consume', 'checks']:
        args = ['--editor', '--import', '--quit'] if mode == 'import' else [
            '--script', 'res://verify.gd', '--', str(HERE / (mode + '.json')), mode]
        result = subprocess.run(command + args, capture_output=True, text=True,
            encoding='utf-8', errors='replace', timeout=100, creationflags=FLAGS)
        log = result.stdout + result.stderr
        (HERE / (mode + '.log')).write_text(log, encoding='utf-8')
        runs.append({'stage': mode, 'exit': result.returncode})
        print(mode, result.returncode, flush=True)
        if result.returncode != 0 or 'SCRIPT ERROR:' in log or 'Parse Error:' in log:
            print(log[-7000:], flush=True)
            return 1
    evidence = [json.loads((HERE / (name + '.json')).read_text()) for name in ['produce','close-held','consume','checks']]
    manifest = json.loads((project / 'LESSONS.json').read_text())
    for row in manifest['lessons']:
        for name, digest in {**row['files_sha256'], **row['exercises_sha256']}.items():
            assert hashlib.sha256((project / 'lessons' / row['hall'] / name).read_bytes()).hexdigest() == digest
    faults = []
    cases = [
        ('pickup-jump', 'prepared/desktop_grab.gd', 'var picked_up_ranged := false',
         'var picked_up_ranged := true', 'close-held', 'desktop/no_pickup_spur'),
        ('ignored-displacement', 'lessons/Point_Lines/line_reversed.gd',
         'line.show_segment(a, displacement, distance)',
         'line.show_segment(a, b - a, distance)', 'checks', 'lines/reversal_visibly_misses_b'),
    ]
    # Reproduce the old immediate-save-on-cleanup failure without weakening a lesson assertion.
    archive_file = project / 'lessons/Point_Trace/trace_archive.gd'
    code = archive_file.read_text(encoding='utf-8')
    start, end = code.index('static func keep_on_release'), code.index('static func save_drawing')
    cases.append(('cleanup-save', 'lessons/Point_Trace/trace_archive.gd', code[start:end],
        'static func keep_on_release(point: Node3D, trail: Node3D, positions: Array[Vector3]) -> void:\n'
        '    point.dropped.connect(func(_body): save_drawing(trail, positions))\n\n',
        'close-held', 'close/adapter_cleanup_does_not_save'))
    for name, relative, before, after, mode, wanted in cases:
        path = project / relative
        original_bytes = path.read_bytes()
        original = original_bytes.decode('utf-8')
        assert original.count(before) == 1, name
        path.write_text(original.replace(before, after), encoding='utf-8')
        try:
            report_path = HERE / ('fault-' + name + '.json')
            r = subprocess.run(command + ['--script', 'res://verify.gd', '--', str(report_path), mode],
                capture_output=True, text=True, encoding='utf-8', errors='replace', timeout=100, creationflags=FLAGS)
            log = r.stdout + r.stderr
            (HERE / ('fault-' + name + '.log')).write_text(log, encoding='utf-8')
            result = json.loads(report_path.read_text())
            assert r.returncode == 1 and wanted in result['failures'] and 'SCRIPT ERROR:' not in log, (name,log)
            faults.append({'fault': name, 'caught_by': wanted})
            print('CAUGHT', name, flush=True)
        finally:
            path.write_bytes(original_bytes)
    # Leave the capture fixture with an intentionally saved, healthy trace again.
    for mode in ['produce','close-held','consume']:
        r = subprocess.run(command + ['--script','res://verify.gd','--',str(HERE/(mode+'.json')),mode],
            capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=100,creationflags=FLAGS)
        assert r.returncode == 0 and 'SCRIPT ERROR:' not in r.stdout+r.stderr, r.stdout+r.stderr
    evidence = [json.loads((HERE / (name + '.json')).read_text()) for name in ['produce','close-held','consume','checks']]
    summary = {'passed': all(r['passed'] for r in evidence), 'checks': sum(len(r['checks']) for r in evidence),
        'runs': runs, 'negative_controls': faults, 'scope': 'Clean ZIP, native Godot, real pickup code with synthetic input. No physical headset claim.',
        'zip_sha256': hashlib.sha256((packager.parent / 'ada-xr-starter.zip').read_bytes()).hexdigest(),
        'lessons': manifest, 'test_project': str(project)}
    (HERE / 'verification.json').write_text(json.dumps(summary, indent=2), encoding='utf-8')
    print('PASS', summary['checks'], 'native checks;', len(manifest['lessons']), 'lessons match their printed source.', flush=True)
    return 0

if __name__ == '__main__':
    raise SystemExit(main())
