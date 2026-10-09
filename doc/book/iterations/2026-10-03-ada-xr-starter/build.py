"""Package the authored starter with Ada's pinned XR Tools copy, without caches."""
from pathlib import Path
import hashlib
import json
import shutil
import stat
import zipfile
import sys

ROOT = Path(__file__).resolve().parents[4]
OUT = Path(__file__).resolve().parent
STUDY = ROOT / 'doc/book/studies/ada-xr-starter'
VENDOR = ROOT / 'addons/godot-xr-tools'

def sha(path):
    return hashlib.sha256(path.read_bytes()).hexdigest()

def copy(source, target):
    if target.exists():
        target.chmod(target.stat().st_mode | stat.S_IWRITE)
    shutil.copyfile(source, target)

def prepare():
    destination = STUDY / 'addons/godot-xr-tools'
    manifest = {}
    for source in sorted(VENDOR.rglob('*')):
        if not source.is_file() or source.suffix in {'.import', '.tmp'} or '.godot' in source.parts or 'blend' in source.parts:
            continue
        relative = source.relative_to(VENDOR)
        target = destination / relative
        target.parent.mkdir(parents=True, exist_ok=True)
        copy(source, target)
        manifest['addons/godot-xr-tools/' + relative.as_posix()] = sha(source)
    copy(ROOT / 'openxr_action_map.tres', STUDY / 'openxr_action_map.tres')
    manifest['openxr_action_map.tres'] = sha(STUDY / 'openxr_action_map.tres')
    (STUDY / 'studies').mkdir(exist_ok=True)
    copy(ROOT / 'doc/book/studies/point-zero/hello_world.gd', STUDY / 'studies/hello_world.gd')
    sys.path.insert(0, str(ROOT / 'tools'))
    from build_student_starter import sync_lessons
    sync_lessons()
    # Transformation review drafts are not silently promoted into this package.
    for name in ['tutorial.md', 'tutorial-sine.md', 'tutorial-museum.md']:
        copy(ROOT / 'commons/maps/Trans_Pre' / name,
             STUDY / 'studies/trans_pre' / ('TUTORIAL.md' if name == 'tutorial.md' else name))
    for filename in ['gallery.gd', 'resolution_totem.gd', 'resolution_totem.tscn', 'resolution_colonnade.tscn']:
        copy(ROOT / 'commons/artifacts/resolution_colonnade' / filename,
             STUDY / 'studies/resolution_colonnade' / filename)
    copy(ROOT / 'LICENSE', STUDY / 'LICENSE')
    (STUDY / 'DEPENDENCIES.json').write_text(json.dumps({
        'godot': '4.6-stable', 'xr_tools': '4.5.1 (Ada vendored copy)',
        'source': 'addons/godot-xr-tools in AdaResearch_46',
        'files_sha256': manifest,
    }, indent=2) + '\n', encoding='utf-8')

def package():
    files = [p for p in sorted(STUDY.rglob('*')) if p.is_file()
             and '.godot' not in p.parts and p.name != '.gitignore'
             and p.suffix not in {'.import', '.tmp'} and 'blend' not in p.parts
             and ('studies' not in p.relative_to(STUDY).parts
                  or p.relative_to(STUDY).as_posix() == 'studies/hello_world.gd'
                  or p.relative_to(STUDY).as_posix().startswith(('studies/trans_pre/', 'studies/resolution_colonnade/')))]
    with zipfile.ZipFile(OUT / 'ada-xr-starter.zip', 'w', zipfile.ZIP_DEFLATED) as z:
        for path in files:
            z.write(path, 'ada-xr-starter/' + path.relative_to(STUDY).as_posix())
    with zipfile.ZipFile(OUT / 'ada-xr-starter.zip') as z:
        assert z.testzip() is None
        for path in files:
            assert z.read('ada-xr-starter/' + path.relative_to(STUDY).as_posix()) == path.read_bytes()
    print(json.dumps({'files': len(files), 'zip_bytes': (OUT / 'ada-xr-starter.zip').stat().st_size}))

if __name__ == '__main__':
    prepare()
    package()
