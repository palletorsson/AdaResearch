"""Actual source/imported assets, isolated user:// saves for native trial tools."""
from pathlib import Path
import os, re, shutil, subprocess, tempfile
ROOT=Path(__file__).resolve().parents[1]
def stage_runtime():
    os.environ["ADA_SOURCE_PROJECT"]=str(ROOT)
    work=ROOT/'ada_run/void-trial-runtime';work.mkdir(parents=True,exist_ok=True)
    (work/'.gdignore').touch()
    stage=Path(tempfile.mkdtemp(prefix='run-',dir=work))
    for source in ROOT.iterdir():
        if source.name in {'.godot','.git','project.godot','override.cfg','ada_run'} or source.is_reserved():continue
        target=stage/source.name
        if source.is_dir():subprocess.run(['cmd','/c','mklink','/J',str(target),str(source)],check=True,capture_output=True)
        else:shutil.copy2(source,target)
    (stage/'.godot').mkdir()
    for name in ['global_script_class_cache.cfg','uid_cache.bin','scene_groups_cache.cfg','extension_list.cfg']:
        source=ROOT/'.godot'/name
        if source.exists():shutil.copy2(source,stage/'.godot'/name)
    subprocess.run(['cmd','/c','mklink','/J',str(stage/'.godot/imported'),str(ROOT/'.godot/imported')],check=True,capture_output=True)
    config=(ROOT/'project.godot').read_text(encoding='utf8')
    config=re.sub(r'config/name="[^"]+"','config/name="Ada Void Trial Test"',config,count=1)
    (stage/'project.godot').write_text(config,encoding='utf8')
    return stage
