from pathlib import Path
import shutil
import subprocess
import hashlib
import json

HERE = Path(__file__).resolve().parent
project = Path((HERE / 'test-project.txt').read_text(encoding='utf-8'))
shutil.copy2(HERE / 'render.gd', project / 'render.gd')
result = subprocess.run([
    'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe', '--path', str(project),
    '--xr-mode', 'off', '--audio-driver', 'Dummy', '--rendering-method', 'gl_compatibility',
    '--resolution', '1440x900', '--script', 'res://render.gd', '--', str(HERE)
], capture_output=True, text=True, encoding='utf-8', errors='replace',
    creationflags=subprocess.CREATE_NO_WINDOW, timeout=100)
log = result.stdout + result.stderr
(HERE / 'render.log').write_text(log, encoding='utf-8')
assert result.returncode == 0 and 'ERROR:' not in log, log
names = [line.removeprefix('CAPTURE ') for line in log.splitlines() if line.startswith('CAPTURE ')]
assert len(names) == 11
manifest = json.loads((project / 'LESSONS.json').read_text())
for row in manifest['lessons']:
    for name, digest in {**row['files_sha256'], **row['exercises_sha256']}.items():
        assert hashlib.sha256((project / 'lessons' / row['hall'] / name).read_bytes()).hexdigest() == digest
(HERE / 'captures.json').write_text(json.dumps({
    'source': 'Unpacked current starter, native Godot 4.6 Compatibility, RTX 3070',
    'input': 'Synthetic saved drawing and scripted views; not a headset capture',
    'shots': names, 'lesson_files_match_tested_download': True
}, indent=2), encoding='utf-8')
print('Captured', len(names), 'native views; source hashes match tested download.')
