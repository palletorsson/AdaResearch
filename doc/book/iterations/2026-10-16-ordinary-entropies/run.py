from pathlib import Path
import subprocess
ROOT=Path(__file__).resolve().parents[4]
HERE=Path(__file__).resolve().parent
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--no-window','--rendering-method','gl_compatibility','--script','res://'+(HERE/'verify.gd').relative_to(ROOT).as_posix(),'--','--no-bridges']
with (HERE/'verification.log').open('w',encoding='utf8') as log:
    result=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
output=(HERE/'verification.log').read_text(encoding='utf8',errors='replace')
print(output[-6500:])
print('Godot process exit:',result.returncode)
raise SystemExit(result.returncode)
