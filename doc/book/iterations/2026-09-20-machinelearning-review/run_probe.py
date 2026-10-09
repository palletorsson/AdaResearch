from pathlib import Path
import subprocess, sys
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
name=sys.argv[1] if len(sys.argv)>1 else 'models'
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--headless','--xr-mode','off','--audio-driver','Dummy','--log-file',str(HERE/(name+'-engine.log')),'--script','res://'+(HERE/('probe_'+name+'.gd')).relative_to(ROOT).as_posix()]
with (HERE/(name+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
text=(HERE/(name+'-process.log')).read_text(encoding='utf-8',errors='replace')
print('\n'.join(line for line in text.splitlines() if any(s in line for s in ['Error','ERROR','ML_','SWARM_','at:'])))
print('exit',code)
raise SystemExit(code)
