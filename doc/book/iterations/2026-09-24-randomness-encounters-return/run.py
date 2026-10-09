from pathlib import Path
import subprocess,os,json,hashlib,sys
sys.stdout.reconfigure(encoding="utf-8")
ROOT=Path(__file__).resolve().parents[4]
OUT=Path(__file__).resolve().parent
si=subprocess.STARTUPINFO();si.dwFlags |= subprocess.STARTF_USESHOWWINDOW;si.wShowWindow=0
exe='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
with (OUT/'native.log').open('w',encoding='utf-8') as log:
 p=subprocess.Popen([exe,'--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--rendering-method','gl_compatibility','--position','4000,4000','--resolution','1440x900','--script','res://doc/book/iterations/2026-09-24-randomness-encounters-return/probe.gd'],stdout=log,stderr=subprocess.STDOUT,startupinfo=si,creationflags=subprocess.CREATE_NO_WINDOW)
 print('Owned test PID',p.pid,flush=True)
 try:code=p.wait(timeout=120)
 except subprocess.TimeoutExpired:p.terminate();p.wait(timeout=10);code=124
s=(OUT/'native.log').read_text(encoding='utf-8',errors='replace')
print(s[-7000:])
raise SystemExit(code)
