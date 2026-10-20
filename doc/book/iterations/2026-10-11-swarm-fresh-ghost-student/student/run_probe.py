"""Repeat with Python. Godot remains the execution engine; no editor or imports."""
from pathlib import Path
import subprocess, datetime, json, hashlib, sys
sys.stdout.reconfigure(encoding='utf-8')
base=Path(__file__).resolve().parent
project=base.parents[4]
godot=Path('C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe')
stamp=datetime.datetime.now(datetime.timezone.utc).strftime('%Y%m%dT%H%M%SZ')
logs=base/'logs'; logs.mkdir(exist_ok=True)
cmd=[str(godot),'--headless','--path',str(project),'--xr-mode','off','--script','res://'+(base/'probe.gd').relative_to(project).as_posix(),'--','--no-bridges']
metadata={'started_utc':stamp,'command':cmd,'prediction_sha256':hashlib.sha256((base/'PREDICTIONS.md').read_bytes()).hexdigest(),'probe_sha256':hashlib.sha256((base/'probe.gd').read_bytes()).hexdigest()}
with (logs/f'{stamp}.log').open('w',encoding='utf-8') as out:
    try:
        r=subprocess.run(cmd,stdout=out,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW,timeout=100)
        metadata['exit_code']=r.returncode
    except subprocess.TimeoutExpired:
        metadata['timeout_seconds']=100
(logs/f'{stamp}.json').write_text(json.dumps(metadata,indent=2),encoding='utf-8')
print(json.dumps(metadata,indent=2))
print((logs/f'{stamp}.log').read_text(encoding='utf-8')[-16000:])
