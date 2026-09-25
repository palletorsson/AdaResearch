"""Capture the production Triangle plate in a private, minimal Godot project."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-09-23-triangle-illustration/figures'
FILES = [
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd',
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.tscn',
    'commons/font/static/Roboto-Regular.ttf',
    'commons/font/static/Roboto-Light.ttf',
    'commons/font/JetBrainsMono-Medium.ttf',
    'tools/captures/triangle_construction_plate.gd',
]
def main():
    OUT.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix='ada-triangle-plate-'))
    hashes = {}
    for name in FILES:
        dest = workspace / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
        hashes[name] = hashlib.sha256(dest.read_bytes()).hexdigest()
    (workspace / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Triangle illustration capture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
    godot = Path(os.environ.get('GODOT_EXE', str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')))
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = dict(cwd=workspace, capture_output=True, text=True, encoding='utf-8', errors='replace', startupinfo=startup)
    result = subprocess.run([str(godot), '--headless', '--path', str(workspace), '--editor', '--import'], timeout=60, **common)
    (OUT/'import.log').write_text(result.stdout+result.stderr, encoding='utf-8')
    if result.returncode or 'SCRIPT ERROR' in result.stdout+result.stderr:
        print((result.stdout+result.stderr)[-4500:]); return 1
    result = subprocess.run([str(godot), '--path', str(workspace), '--rendering-method', 'gl_compatibility', '--resolution', '128x128', '--position', '-10000,-10000', '--script', 'res://tools/captures/triangle_construction_plate.gd', '--', OUT.as_posix()], timeout=60, **common)
    log=result.stdout+result.stderr
    (OUT/'capture.log').write_text(log, encoding='utf-8')
    print(log[-3500:])
    (OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':str(godot),'isolated_project':str(workspace),'same_scene_as_museum':True,'book_mount_hidden':True},indent=2)+'\n', encoding='utf-8')
    return result.returncode or int('SCRIPT ERROR' in log)
if __name__ == '__main__':
    raise SystemExit(main())
