from pathlib import Path
import subprocess,json,sys
sys.stdout.reconfigure(encoding="utf-8")
P=Path(__file__).resolve().parent;R=P.parents[3]
if (P/'native-checks.json').exists(): (P/'native-checks.json').unlink()
with (P/'native.log').open('w',encoding='utf-8') as log:
 p=subprocess.Popen(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--headless','--xr-mode','off','--audio-driver','Dummy','--fixed-fps','120','--script','res://'+(P/'probe.gd').relative_to(R).as_posix()],stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try: code=p.wait(timeout=100)
 except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('exit',code)
print((P/'native.log').read_text(encoding='utf-8',errors='replace')[-5000:])
report=json.loads((P/"native-checks.json").read_text(encoding="utf-8")) if (P/"native-checks.json").exists() else {}
raise SystemExit(code or (1 if "SCRIPT ERROR" in (P/"native.log").read_text(encoding="utf-8",errors="replace") or report.get("failures") or not report.get("checks") else 0))
