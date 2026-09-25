"""Capture the production Melencolia court in a private, minimal Godot project."""
from pathlib import Path
import hashlib, json, os, re, shutil, subprocess, tempfile
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'doc/book/iterations/2026-09-23-melencolia-one-arrangement/figures'
FILES = [
    'commons/font/static/Roboto-Regular.ttf',
    'commons/font/static/Roboto-Light.ttf',
    'tools/captures/melencolia_court.gd',
    'commons/primitives/shared/grid_material_factory.gd',
    'commons/primitives/shared/primitive_mesh_builder.gd',
    'commons/primitives/shared/solid_primitive_finish.gd',
    'commons/resourses/shaders/SimpleGrid.gdshader',
    'commons/resourses/shaders/ParametricGrid.gdshader',
    'commons/resourses/shaders/Grid.gdshader',
]+[f'commons/primitives/pyramid/{name}.{ext}' for name in ['pyramid','pyramidlong'] for ext in ['gd','tscn']]+[f'commons/primitives/cubes/cube_scene.{ext}' for ext in ['gd','tscn']]

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    workspace = Path(tempfile.mkdtemp(prefix='ada-melencolia-court-'))
    hashes = {}
    for name in FILES:
        dest = workspace / name
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(ROOT / name, dest)
        hashes[name] = hashlib.sha256(dest.read_bytes()).hexdigest()
    map_path=ROOT/'commons/maps/Primitives_Melencolia/map_data.json'
    report_path=ROOT/'ada_run/encounter_pilot/Primitives_Melencolia/report.json'
    m=json.loads(map_path.read_text(encoding='utf-8-sig'))
    report=json.loads(report_path.read_text(encoding='utf-8'))
    registry=json.loads((ROOT/'commons/artifacts/registry/primitives.json').read_text(encoding='utf-8-sig'))['artifacts']
    placements=[]
    for z,row in enumerate(m['layers']['interactables']):
        for x,value in enumerate(row):
            token=value.split('#')[0].split(':')[0]
            if token not in ['pyramid','pyramidlong','cube_scene']:continue
            parts=value.split('#')[0].split(':')
            config={a.split(':',1)[0]:a.split(':',1)[1] for a in value.split('#')[1:]}
            scale=float(parts[3]) if len(parts)>3 else 1.0
            offset=[float(a) for a in config.get('offset','0,0,0').split(',')]
            position=[x+0.5+offset[0],float(m['layers']['structure'][z][x])-1+offset[1],z+0.5+offset[2]]
            actual=next(a for a in report['artifacts'] if a['token']==token and a['cell']==[x,z])
            assert all(abs(a-b)<0.0001 for a,b in zip(position,actual['position']))
            placements.append(dict(token=token,cell=[x,z],scene=registry[token]['scene'],config=config,scale=scale,rotation=float(parts[1]),position=position,bounds_position=actual['bounds_position'],bounds_size=actual['bounds_size']))
    assert len(placements)==9
    (workspace/'reference.json').write_text(json.dumps({'placements':placements}),encoding='utf-8')
    for path in [map_path,report_path,ROOT/'commons/artifacts/registry/primitives.json']:
        hashes[path.relative_to(ROOT).as_posix()]=hashlib.sha256(path.read_bytes()).hexdigest()
    (workspace / 'project.godot').write_text('config_version=5\n[application]\nconfig/name="Melencolia court capture"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n', encoding='utf-8')
    godot = Path(os.environ.get('GODOT_EXE', str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')))
    startup = subprocess.STARTUPINFO()
    startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
    startup.wShowWindow = 0
    common = dict(cwd=workspace, capture_output=True, text=True, encoding='utf-8', errors='replace', startupinfo=startup)
    result = subprocess.run([str(godot), '--headless', '--path', str(workspace), '--editor', '--import'], timeout=60, **common)
    (OUT/'import.log').write_text(result.stdout+result.stderr, encoding='utf-8')
    if result.returncode or 'SCRIPT ERROR' in result.stdout+result.stderr:
        print((result.stdout+result.stderr)[-4500:]); return 1
    result = subprocess.run([str(godot), '--path', str(workspace), '--rendering-method', 'gl_compatibility', '--resolution', '128x128', '--position', '-10000,-10000', '--script', 'res://tools/captures/melencolia_court.gd', '--', OUT.as_posix()], timeout=60, **common)
    log=result.stdout+result.stderr
    (OUT/'capture.log').write_text(log, encoding='utf-8')
    print(log[-3500:])
    (OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':str(godot),'isolated_project':str(workspace),'same_artifact_scenes_and_configs_as_museum':True,'book_arrangement':'Three camera views of the same court; plain deck finish and matched lighting.', 'placements':placements},indent=2)+'\n', encoding='utf-8')
    return result.returncode or int('SCRIPT ERROR' in log)
if __name__ == '__main__':
    raise SystemExit(main())
