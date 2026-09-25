"""Capture the production Polyhedra boundary plate in a private, minimal Godot project."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-09-23-polyhedra-two-boundaries/figures'
FILES = [
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd',
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.tscn',
    'commons/font/static/Roboto-Regular.ttf',
    'commons/font/static/Roboto-Light.ttf',
    'commons/font/JetBrainsMono-Medium.ttf',
    'commons/artifacts/polyhedra_boundary_plate/polyhedra_boundary_plate.gd',
    'commons/artifacts/polyhedra_boundary_plate/polyhedra_boundary_plate.tscn',
    'tools/captures/polyhedra_boundary_plate.gd',
]
def main():
    OUT.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix='ada-polyhedra-plate-'))
    hashes = {}
    for name in FILES:
        dest = workspace / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
        hashes[name] = hashlib.sha256(dest.read_bytes()).hexdigest()
    source = ROOT / 'commons/primitives/trihedron/grab_trihedron.gd'
    scene = ROOT / 'commons/primitives/trihedron/grab_trihedron.tscn'
    text = source.read_text(encoding='utf-8')
    # Read the shipped shape; verify its default script branch still matches it.
    coords = re.search(r'points = PackedVector3Array\(([^)]+)\)',scene.read_text(encoding='utf-8'))[1]
    numbers = [float(v.strip()) for v in coords.split(',')]
    vertices = [numbers[i:i+3] for i in range(0,len(numbers),3)]
    assert vertices == [[0,.6,0],[-.6,-.6,-.6],[.6,-.6,-.6],[0,-.6,.6]]
    for expression in ['Vector3(0, s, 0)','Vector3(-s, -s, -s)','Vector3(s, -s, -s)','Vector3(0, -s, s)']:
        assert expression in text.split('func _create_trihedron_vertices()')[1].split('func _corner_vertices()')[0]
    faces_text = text.split('func _create_trihedron_faces()')[1].split('\nfunc ')[0]
    faces = [[int(i) for i in v] for v in re.findall(r'\[(\d),\s*(\d),\s*(\d)\]',faces_text)]
    assert len(faces)==3
    (workspace/'reference.json').write_text(json.dumps({'vertices':vertices,'faces':faces}),encoding='utf-8')
    for p in [source,scene]:hashes[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    (workspace / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Polyhedra illustration capture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
    godot = Path(os.environ.get('GODOT_EXE', str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')))
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = dict(cwd=workspace, capture_output=True, text=True, encoding='utf-8', errors='replace', startupinfo=startup)
    result = subprocess.run([str(godot), '--headless', '--path', str(workspace), '--editor', '--import'], timeout=60, **common)
    (OUT/'import.log').write_text(result.stdout+result.stderr, encoding='utf-8')
    if result.returncode or 'SCRIPT ERROR' in result.stdout+result.stderr:
        print((result.stdout+result.stderr)[-4500:]); return 1
    result = subprocess.run([str(godot), '--path', str(workspace), '--rendering-method', 'gl_compatibility', '--resolution', '128x128', '--position', '-10000,-10000', '--script', 'res://tools/captures/polyhedra_boundary_plate.gd', '--', OUT.as_posix()], timeout=60, **common)
    log=result.stdout+result.stderr
    (OUT/'capture.log').write_text(log, encoding='utf-8')
    print(log[-3500:])
    (OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':str(godot),'isolated_project':str(workspace),'same_scene_as_museum':True,'book_mount_hidden':True},indent=2)+'\n', encoding='utf-8')
    return result.returncode or int('SCRIPT ERROR' in log)
if __name__ == '__main__':
    raise SystemExit(main())
