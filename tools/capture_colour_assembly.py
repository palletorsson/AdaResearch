"""Native companion gallery captures; no museum map is modified by this runner."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess
import sys
import tempfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-10-02-gillick-room-to-gather/figures'
OUT.mkdir(parents=True, exist_ok=True)
workspace = Path(tempfile.mkdtemp(prefix='ada-colour-assembly-'))
sources = sorted((ROOT / 'commons/artifacts/colour_assembly').glob('*.gd'))
sources += sorted((ROOT / 'commons/artifacts/colour_assembly').glob('*.tscn'))
sources += [ROOT / 'tools/captures/colour_assembly.gd']
hashes = {}
for source in sources:
    rel = source.relative_to(ROOT)
    dest = workspace / rel
    dest.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(source, dest)
    hashes[rel.as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
(workspace / 'project.godot').write_text(
    'config_version=5\n[application]\nconfig/name="' + workspace.name +
    '"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
godot = str(Path.home() / 'Desktop/Godot_v4.6-stable_win64.exe')
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
for label, command in [
    ('import', [godot, '--headless', '--path', str(workspace), '--editor', '--import']),
    ('render', [godot, '--path', str(workspace), '--rendering-method', 'gl_compatibility',
                '--resolution', '128x128', '--position', '-10000,-10000', '--script',
                'res://tools/captures/colour_assembly.gd', '--', OUT.as_posix()])
]:
    result = subprocess.run(command, capture_output=True, text=True, encoding='utf-8',
                            errors='replace', startupinfo=startup, timeout=60)
    log = result.stdout + result.stderr
    (OUT / (label + '.log')).write_text(log, encoding='utf-8')
    print(log[-6500:])
    if result.returncode or 'SCRIPT ERROR' in log or 'ERROR:' in log:
        sys.exit(result.returncode or 1)
report = json.loads((OUT / 'verification.json').read_text(encoding='utf-8'))
if not report['checks'] or not all(c['pass'] for c in report['checks']):
    sys.exit(1)
(OUT / 'provenance.json').write_text(json.dumps({
    'source_files': hashes, 'godot': godot, 'isolated_project': str(workspace),
    'scope': 'Native Godot companion gallery, not installed in the museum. Unedited viewport captures.'
}, indent=2) + '\n', encoding='utf-8')
with zipfile.ZipFile(OUT.parent / 'colour-assembly-study.zip', 'w', zipfile.ZIP_DEFLATED) as archive:
    archive.writestr('project.godot', '''config_version=5
[application]
config/name="Ada - Room to gather"
run/main_scene="res://commons/artifacts/colour_assembly/study.tscn"
[display]
window/size/viewport_width=1600
window/size/viewport_height=1000
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    for source in sources:
        if 'commons' in source.relative_to(ROOT).parts:
            archive.write(source, source.relative_to(ROOT).as_posix())
    archive.writestr('README.txt', 'Ada: Room to gather. Original study informed by Liam Gillick.\n'
        'Godot 4.6: import project.godot and run. Choose layout and colour separately.\n'
        'Walk uses WASD and mouse. Esc releases the pointer.\n'
        'Return to the edge before changing layout. Reset returns to the initial comparison.\n'
        'Desktop companion; not a tracked-hand or installed museum scene.\n'
        'Reference: https://liamgillick.info/Somewhere-Specific-in-Mind-Liam-Gillick-and-Suzanne-Cotter\n')
