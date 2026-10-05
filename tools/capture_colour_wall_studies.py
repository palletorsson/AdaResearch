"""Render and package the original Gillick wall studies in a private Godot project."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys, tempfile, zipfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-02-gillick-wall-relations/figures'
OUT.mkdir(parents=True, exist_ok=True)
workspace = Path(tempfile.mkdtemp(prefix='ada-colour-walls-'))
sources = []
for folder in ['colour_assembly','colour_wall_studies']:
    for pattern in ['*.gd','*.tscn']:
        sources += sorted((ROOT/'commons/artifacts'/folder).glob(pattern))
sources += [ROOT/'tools/captures/colour_wall_studies.gd']
hashes = {}
for source in sources:
    rel = source.relative_to(ROOT)
    dest = workspace/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,dest)
    hashes[rel.as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
project = '''config_version=5
[application]
config/name="Ada - Wall relations"
run/main_scene="res://commons/artifacts/colour_wall_studies/study.tscn"
[display]
window/size/viewport_width=1600
window/size/viewport_height=1000
[rendering]
renderer/rendering_method="gl_compatibility"
textures/default_filters/use_nearest_mipmap_filter=false
lights_and_shadows/positional_shadow/atlas_size=4096
'''
(workspace/'project.godot').write_text(project,encoding='utf-8')
godot = str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
for label, command in [
    ('import',[godot,'--headless','--path',str(workspace),'--editor','--import']),
    ('render',[godot,'--path',str(workspace),'--rendering-method','gl_compatibility','--resolution','128x128',
               '--position','-10000,-10000','--script','res://tools/captures/colour_wall_studies.gd','--',OUT.as_posix()])]:
    result = subprocess.run(command,capture_output=True,text=True,encoding='utf-8',errors='replace',startupinfo=startup,timeout=60)
    log = result.stdout+result.stderr
    (OUT/(label+'.log')).write_text(log,encoding='utf-8')
    print(log[-6000:])
    if result.returncode or 'SCRIPT ERROR' in log or 'ERROR:' in log: sys.exit(result.returncode or 1)
report = json.loads((OUT/'verification.json').read_text(encoding='utf-8'))
assert report['checks'] and all(c['pass'] for c in report['checks'])
(OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':godot,'isolated_project':str(workspace),
    'scope':'Original native wall companions. Not installed in museum; unedited viewport images.'},indent=2)+'\n',encoding='utf-8')
with zipfile.ZipFile(OUT.parent/'wall-relations-study.zip','w',zipfile.ZIP_DEFLATED) as archive:
    archive.writestr('project.godot',project)
    for source in sources:
        if source.relative_to(ROOT).parts[0] == 'commons': archive.write(source,source.relative_to(ROOT).as_posix())
    archive.writestr('README.txt','Ada - Wall relations. Original studies informed by Liam Gillick.\n'
        'Godot 4.6: import project.godot and run. Controls compare spacing, projection, omission and colour.\n'
        'Walk: WASD + mouse, Escape releases the pointer. Reset restores the initial state.\n'
        'Companion gallery, no headset interaction. The earlier colour_assembly viewer supplies the walking code.\n')
