"""Verify the printed source edits against a cold copy of the shared starter."""
from pathlib import Path
import hashlib
import json
import subprocess
import tempfile
import zipfile
import sys
import imageio_ffmpeg

OUT = Path(__file__).resolve().parent
ROOT = OUT.parents[3]
STARTER = ROOT / 'doc/book/studies/ada-xr-starter'
GODOT = Path.home() / 'Desktop/Godot_v4.6-stable_win64.exe'
subprocess.run([sys.executable, str(OUT.parent / '2026-10-03-ada-xr-starter/build.py')], check=True)
destination = Path(tempfile.mkdtemp(prefix='ada-transformation-tutorial-'))
archive = OUT.parent / '2026-10-03-ada-xr-starter/ada-xr-starter.zip'
with zipfile.ZipFile(archive) as z:
    z.extractall(destination)
project = destination / 'ada-xr-starter'
frames = destination / 'frames'
frames.mkdir()
(OUT / 'last-run.json').write_text(json.dumps({'project': str(project), 'frames': str(frames)}, indent=2), encoding='utf-8')
subprocess.run([str(GODOT), '--headless', '--path', str(project), '--xr-mode', 'off', '--editor', '--import', '--log-file', str(OUT / 'import.log')], timeout=120, check=True, capture_output=True)
log = (OUT / 'import.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log, log[-5000:]
subprocess.run([str(GODOT), '--path', str(project), '--xr-mode', 'off', '--position', '4000,4000', '--resolution', '1280x800', '--log-file', str(OUT / 'verify.log'), '--script', str(OUT / 'verify.gd'), '--', str(OUT), str(frames)], timeout=240, check=True, capture_output=True)
log = (OUT / 'verify.log').read_text(encoding='utf-8', errors='replace')
assert 'SCRIPT ERROR' not in log and 'ERROR:' not in log, log
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
assert report['passed'] and all(c['passed'] for c in report['checks'])
assert len(list(frames.glob('*.png'))) == 240
subprocess.run([imageio_ffmpeg.get_ffmpeg_exe(), '-y', '-loglevel', 'error', '-framerate', '30', '-i', str(frames / '%04d.png'), '-c:v', 'libx264', '-crf', '20', '-pix_fmt', 'yuv420p', '-movflags', '+faststart', str(OUT / 'three-operations.mp4')], timeout=120, check=True)
matched = {}
for source in [STARTER / 'trans_pre.tscn', *sorted((STARTER / 'studies/trans_pre').glob('*'))]:
    if source.is_file():
        relative = source.relative_to(STARTER)
        assert source.read_bytes() == (project / relative).read_bytes(), relative
        matched[relative.as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
assert (ROOT / 'commons/maps/Trans_Pre/final.md').read_bytes() == (OUT / 'before/final.md').read_bytes()
assert (ROOT / 'commons/maps/Trans_Pre/tutorial-museum.md').read_bytes() == (OUT / 'before/tutorial.md').read_bytes()
(OUT / 'package-verification.json').write_text(json.dumps({'cold_import': True, 'checked_project': str(project), 'archive_sha256': hashlib.sha256(archive.read_bytes()).hexdigest(), 'matched_files': matched, 'native_checks': len(report['checks']), 'passed': True}, indent=2) + '\n', encoding='utf-8')
print(json.dumps({'passed': True, 'checks': len(report['checks']), 'video_seconds': 8, 'project': str(project)}))
