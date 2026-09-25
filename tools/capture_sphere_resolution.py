"""Capture the production Existing sphere comparison plate in a private, minimal Godot project."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-09-23-sphere-visible-construction/figures'
FILES = [
    'commons/artifacts/triangle_construction_plate/triangle_construction_plate.gd',
    'commons/font/static/Roboto-Regular.ttf',
    'commons/font/static/Roboto-Light.ttf',
    'commons/font/JetBrainsMono-Medium.ttf',
    'commons/primitives/shared/grid_material_factory.gd',
    'commons/primitives/shared/mesh_inspection.gd',
    'commons/resourses/shaders/SimpleGrid.gdshader',
    'commons/resourses/shaders/ParametricGrid.gdshader',
    'tools/captures/sphere_resolution_layout.gd',
    'tools/captures/sphere_resolution_study.gd',
]+[f'commons/primitives/godotmeshes/sphere_{kind}.{ext}' for kind in ['high','mid','low'] for ext in ['gd','tscn']]

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix='ada-sphere-comparison-'))
    hashes = {}
    for name in FILES:
        dest = workspace / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
        hashes[name] = hashlib.sha256(dest.read_bytes()).hexdigest()
    source = ROOT / 'commons/maps/Primitives_Ignorance/map_data.json'
    registry_path = ROOT / 'commons/artifacts/registry/primitives.json'
    map_data = json.loads(source.read_text(encoding='utf-8'))
    registry = json.loads(registry_path.read_text(encoding='utf-8'))['artifacts']
    reference=[]
    for token in ['sphere_high','sphere_mid','sphere_low']:
        configs=[]
        placements=[]
        for z,row in enumerate(map_data['layers']['interactables']):
            for x,value in enumerate(row):
                if value.split(':')[0].split('#')[0]!=token:continue
                config={part.split(':',1)[0]:part.split(':',1)[1] for part in value.split('#')[1:] if ':' in part}
                configs.append(config);placements.append({'cell':[x,z],'token':value})
        assert len(configs)==2 and [c['inspection_edges'] for c in configs]==['1','0']
        assert all(c['inspection']=='1' for c in configs)
        reference.append({'token':token,'scene':registry[token]['scene'],'configs':configs,'placements':placements})
    (workspace/'reference.json').write_text(json.dumps(reference),encoding='utf-8')
    for path in [source,registry_path]:hashes[path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    (workspace / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Sphere comparison capture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
    godot = Path(os.environ.get('GODOT_EXE', str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')))
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = dict(cwd=workspace, capture_output=True, text=True, encoding='utf-8', errors='replace', startupinfo=startup)
    result = subprocess.run([str(godot), '--headless', '--path', str(workspace), '--editor', '--import'], timeout=60, **common)
    (OUT/'import.log').write_text(result.stdout+result.stderr, encoding='utf-8')
    if result.returncode or 'SCRIPT ERROR' in result.stdout+result.stderr:
        print((result.stdout+result.stderr)[-4500:]); return 1
    result = subprocess.run([str(godot), '--path', str(workspace), '--rendering-method', 'gl_compatibility', '--resolution', '128x128', '--position', '-10000,-10000', '--script', 'res://tools/captures/sphere_resolution_study.gd', '--', OUT.as_posix()], timeout=60, **common)
    log=result.stdout+result.stderr
    (OUT/'capture.log').write_text(log, encoding='utf-8')
    print(log[-3500:])
    (OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':str(godot),'isolated_project':str(workspace),'same_artifact_scenes_and_configs_as_museum':True,'layout':'Six existing artifacts arranged for equal-scale orthographic comparison. No new museum artifact.', 'placements':reference},indent=2)+'\n', encoding='utf-8')
    return result.returncode or int('SCRIPT ERROR' in log)
if __name__ == '__main__':
    raise SystemExit(main())
