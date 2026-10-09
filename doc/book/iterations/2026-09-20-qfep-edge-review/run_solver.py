from pathlib import Path
import subprocess,json,time,sys
sys.stdout.reconfigure(encoding='utf-8')
r=Path.cwd();h=r/'doc/book/iterations/2026-09-20-qfep-edge-review';t=time.monotonic()
with (h/'solver-engine.log').open('w',encoding='utf-8') as out:
 c=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(r),'--xr-mode','off','--log-file',str(h/'solver-godot.log'),'--script','res://doc/book/iterations/2026-09-20-qfep-edge-review/check_solver.gd'],stdout=out,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW).returncode
print('exit',c,'seconds',round(time.monotonic()-t,2));print((h/'solver-engine.log').read_text(encoding='utf-8',errors='replace')[-2300:])
(h/'solver-process-result.json').write_text(json.dumps({'exit':c,'seconds':round(time.monotonic()-t,2)}),encoding='utf-8')
