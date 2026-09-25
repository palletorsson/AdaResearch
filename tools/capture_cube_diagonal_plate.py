"""Capture the production Cube diagonal plate in a private, minimal Godot project."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-09-23-cube-hidden-diagonal/figures'
FILES = [
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd',
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.tscn',
    'commons/font/static/Roboto-Regular.ttf',
    'commons/font/static/Roboto-Light.ttf',
    'commons/font/JetBrainsMono-Medium.ttf',
    'commons/artifacts/cube_diagonal_plate/cube_diagonal_plate.gd',
    'commons/artifacts/cube_diagonal_plate/cube_diagonal_plate.tscn',
    'tools/captures/cube_diagonal_plate.gd',
]
def main():
    OUT.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix='ada-cube-plate-'))
    hashes = {}
    for name in FILES:
        dest = workspace / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
        hashes[name] = hashlib.sha256(dest.read_bytes()).hexdigest()
    source = ROOT / 'commons/primitives/animatedcubebuilder/animatedcubebuilder.gd'
    text = source.read_text(encoding='utf-8')
    vertex_text = text.split('var vertices = [')[1].split(']')[0]
    vertices = [[float(v.strip()) for v in xyz.split(',')] for xyz in re.findall(r'Vector3\(([^)]+)\)',vertex_text)]
    face_text = text.split('var triangles = [')[1].split('# Visual components')[0]
    faces = [[int(v) for v in xyz] for xyz in re.findall(r'\[(\d),\s*(\d),\s*(\d)\]',face_text)]
    assert len(vertices)==8 and len(faces)==12
    assert faces[4:6]==[[4,5,7],[5,6,7]]
    (workspace/'reference.json').write_text(json.dumps({'vertices':vertices,'faces':faces[4:6]}),encoding='utf-8')
    hashes[source.relative_to(ROOT).as_posix()]=hashlib.sha256(source.read_bytes()).hexdigest()
    (workspace / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Cube illustration capture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
    godot = Path(os.environ.get('GODOT_EXE', str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')))
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = dict(cwd=workspace, capture_output=True, text=True, encoding='utf-8', errors='replace', startupinfo=startup)
    result = subprocess.run([str(godot), '--headless', '--path', str(workspace), '--editor', '--import'], timeout=60, **common)
    (OUT/'import.log').write_text(result.stdout+result.stderr, encoding='utf-8')
    if result.returncode or 'SCRIPT ERROR' in result.stdout+result.stderr:
        print((result.stdout+result.stderr)[-4500:]); return 1
    result = subprocess.run([str(godot), '--path', str(workspace), '--rendering-method', 'gl_compatibility', '--resolution', '128x128', '--position', '-10000,-10000', '--script', 'res://tools/captures/cube_diagonal_plate.gd', '--', OUT.as_posix()], timeout=60, **common)
    log=result.stdout+result.stderr
    (OUT/'capture.log').write_text(log, encoding='utf-8')
    print(log[-3500:])
    (OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':str(godot),'isolated_project':str(workspace),'same_scene_as_museum':True,'book_mount_hidden':True},indent=2)+'\n', encoding='utf-8')
    return result.returncode or int('SCRIPT ERROR' in log)
if __name__ == '__main__':
    raise SystemExit(main())
