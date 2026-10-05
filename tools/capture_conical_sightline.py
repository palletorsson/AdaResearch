"""Reproducible native Godot images and behaviour checks for the conical study."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, sys, tempfile

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-01-matta-clark-one-cut/figures'
OUT.mkdir(parents=True, exist_ok=True)
workspace = Path(tempfile.mkdtemp(prefix='ada-conical-sightline-'))
sources = list((ROOT/'commons/artifacts/conical_sightline').glob('*.gd'))+list((ROOT/'commons/artifacts/conical_sightline').glob('*.tscn'))+[ROOT/'tools/captures/conical_sightline.gd']
hashes = {}
for source in sources:
    rel = source.relative_to(ROOT)
    dest = workspace/rel
    dest.parent.mkdir(parents=True,exist_ok=True)
    shutil.copy2(source,dest)
    hashes[rel.as_posix()] = hashlib.sha256(source.read_bytes()).hexdigest()
(workspace/'project.godot').write_text('config_version=5\n[application]\nconfig/name="'+workspace.name+'"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n',encoding='utf-8')
godot = str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe')
startup = subprocess.STARTUPINFO()
startup.dwFlags |= subprocess.STARTF_USESHOWWINDOW
startup.wShowWindow = 0
for label,cmd in [
    ('import',[godot,'--headless','--path',str(workspace),'--editor','--import']),
    ('render',[godot,'--path',str(workspace),'--rendering-method','gl_compatibility','--resolution','128x128',
               '--position','-10000,-10000','--script','res://tools/captures/conical_sightline.gd','--',OUT.as_posix()])]:
    result = subprocess.run(cmd,capture_output=True,text=True,encoding='utf-8',errors='replace',startupinfo=startup,timeout=60)
    log = result.stdout+result.stderr
    (OUT/(label+'.log')).write_text(log,encoding='utf-8')
    print(log[-4500:])
    if result.returncode or 'SCRIPT ERROR' in log or 'ERROR:' in log: sys.exit(result.returncode or 1)
(OUT/'provenance.json').write_text(json.dumps({'source_files':hashes,'godot':godot,'isolated_project':str(workspace),
    'scope':'Native Godot study, not yet installed in the museum; no edited screenshot pixels.'},indent=2)+'\n',encoding='utf-8')
