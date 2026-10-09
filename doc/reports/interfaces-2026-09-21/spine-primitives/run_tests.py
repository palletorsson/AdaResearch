from pathlib import Path
import subprocess, sys
sys.stdout.reconfigure(encoding="utf-8")
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent/'after'
OUT.mkdir(parents=True,exist_ok=True)
failed=False
for name in ['probe_trace_data_panel','probe_grid_lines_discovery']:
    with (OUT/(name+'.log')).open('w',encoding='utf-8') as log:
        try:
            result=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://commons/testing/'+name+'.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
            failed=failed or result.returncode!=0
        except subprocess.TimeoutExpired: failed=True
    content=(OUT/(name+'.log')).read_text(encoding='utf-8',errors='replace')
    failed=failed or 'SCRIPT ERROR' in content
    print(name,content[-2000:])
sys.exit(1 if failed else 0)
