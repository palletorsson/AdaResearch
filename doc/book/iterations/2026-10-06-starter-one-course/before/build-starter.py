"""Package the authored starter with Ada's pinned XR Tools copy, without caches."""
from pathlib import Path
import hashlib
import json
import shutil
import stat
import zipfile

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
    tutorial = (ROOT / 'commons/maps/Point_One/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_one/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Point_Lines/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_lines/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Point_Trace/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_trace/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Point_Line_Grid/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_grid/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Point_Triangle_Context/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_triangle/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Primitives_Polythedra/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_polyhedra/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Point_Animatedcube/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/point_cube/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Primitives_Ignorance/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/primitive_rules/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    tutorial = (ROOT / 'commons/maps/Primitives_Portals/tutorial.md').read_text(encoding='utf-8')
    tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
    (STUDY / 'studies/primitive_portals/TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    for map_name, source_name, folder in [
        ('Primitives_Ignorance', 'tutorial-column.md', 'primitive_column'),
        ('Primitives_Melencolia', 'tutorial.md', 'primitive_composition'),
        ('Trans_Pre', 'tutorial.md', 'trans_pre'),
    ]:
        tutorial = (ROOT / 'commons/maps' / map_name / source_name).read_text(encoding='utf-8')
        tutorial = tutorial.replace('../../../doc/book/studies/ada-xr-starter/README.md', '../../README.md')
        (STUDY / 'studies' / folder / 'TUTORIAL.md').write_text(tutorial, encoding='utf-8')
    # Keep the in-project reading route and the production-source companion usable offline.
    rules = STUDY / 'studies/primitive_rules/TUTORIAL.md'
    rules.write_text(rules.read_text(encoding='utf-8').replace('(tutorial-column.md)', '(../primitive_column/TUTORIAL.md)'), encoding='utf-8')
    copy(ROOT / 'commons/maps/Primitives_Melencolia/tutorial-museum.md',
         STUDY / 'studies/primitive_composition/tutorial-museum.md')
    copy(ROOT / 'commons/maps/Trans_Pre/tutorial-sine.md',
         STUDY / 'studies/trans_pre/tutorial-sine.md')
    copy(ROOT / 'commons/maps/Trans_Pre/tutorial-museum.md',
         STUDY / 'studies/trans_pre/tutorial-museum.md')
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
             and p.suffix not in {'.import', '.tmp'} and 'blend' not in p.parts]
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
