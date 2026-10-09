"""Package, cold-import, then verify the actual downloadable examples in Godot."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import zipfile
import sys

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
GODOT = Path.home() / 'Desktop/Godot_v4.6-stable_win64.exe'

subprocess.run([sys.executable, str(OUT.parent / '2026-10-03-ada-xr-starter/build.py')], check=True)
destination = Path(tempfile.mkdtemp(prefix='ada-closing-primitives-'))
archive = OUT.parent / '2026-10-03-ada-xr-starter/ada-xr-starter.zip'
with zipfile.ZipFile(archive) as z:
    z.extractall(destination)
project = destination / 'ada-xr-starter'
(OUT / 'last-run.json').write_text(json.dumps({'project': str(project)}, indent=2), encoding='utf-8')
subprocess.run([str(GODOT), '--headless', '--path', str(project), '--xr-mode', 'off', '--editor', '--import', '--log-file', str(OUT / 'import.log')], timeout=120, check=True, capture_output=True)
import_log = (OUT / 'import.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR' not in import_log and 'Parse Error' not in import_log, import_log[-5000:]
command = [sys.executable, str(ROOT / 'tools/godot_watchdog.py'), '--expect=' + str(OUT / 'verification.json'), '--grace=90', '--stall=30', '--', str(GODOT), '--path', str(project), '--xr-mode', 'off', '--position', '4000,4000', '--resolution', '1280x800', '--log-file', str(OUT / 'verify.log'), '--script', str(OUT / 'verify.gd'), '--', str(OUT)]
subprocess.run(command, timeout=150, check=True)
log = (OUT / 'verify.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log, log
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
matched = {}
for folder in ['primitive_column', 'primitive_composition']:
    for source in (STARTER / 'studies' / folder).iterdir():
        if source.is_file():
            relative = source.relative_to(STARTER)
            assert source.read_bytes() == (project / relative).read_bytes(), relative
            matched[relative.as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
for name in ['primitive_column.tscn', 'primitive_composition.tscn']:
    assert (STARTER / name).read_bytes() == (project / name).read_bytes()
(OUT / 'package-verification.json').write_text(json.dumps({'cold_import': True, 'checked_project': str(project), 'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'matched_files': matched, 'native_checks': len(report['checks']), 'passed': True}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'passed': True, 'checks': len(report['checks']), 'project': str(project)}))
