from pathlib import Path
import subprocess,sys
sys.stdout.reconfigure(encoding='utf-8')
root=Path(__file__).resolve().parents[4]
here=Path(__file__).parent
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(root),'--xr-mode','off','--log-file',str(here/'model-engine.log'),'--script','res://doc/book/iterations/2026-10-17-wedge-mouse-path/model_probe.gd','--','--no-bridges']
with (here/'model-stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.Popen(cmd,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    try:code=p.wait(timeout=100)
    except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('\n'.join((here/'model-stdout.log').read_text(encoding='utf-8',errors='replace').splitlines()[-25:]))
raise SystemExit(code)
