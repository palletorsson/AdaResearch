from run_checks import HERE, ENGINE, put, sha
from pathlib import Path
import subprocess, json, shutil

report=json.loads((HERE/'verification.json').read_text())
work=Path(report['test_project'])
shutil.copyfile(HERE/'render_check.gd',work/'render_check.gd')
startup=subprocess.STARTUPINFO();startup.dwFlags|=subprocess.STARTF_USESHOWWINDOW;startup.wShowWindow=subprocess.SW_HIDE
r=subprocess.run([ENGINE,'--path',str(work),'--rendering-method','gl_compatibility','--rendering-driver','opengl3','--xr-mode','off','--audio-driver','Dummy','--max-fps','120','--quit-after','2500','--script','res://render_check.gd','--',str(HERE)],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60,creationflags=subprocess.CREATE_NO_WINDOW,startupinfo=startup)
log=r.stdout+r.stderr
put(HERE/'logs/render.log',log)
print(log)
assert r.returncode==0 and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log
data=json.loads((HERE/'render-report.json').read_text())
assert data['passed']
report['render_assertions']=len(data['checks'])
report['renderer']=data['renderer']
report['inputs'].update({n:sha(HERE/n) for n in ['render_check.gd','run_render.py']})
report['images']={p.name:sha(p) for p in HERE.glob('*.png')}
put(HERE/'verification.json',json.dumps(report,indent=2))
