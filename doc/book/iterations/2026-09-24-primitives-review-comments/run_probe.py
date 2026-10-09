import subprocess,sys
from pathlib import Path
root=Path.cwd(); out=root/'doc/book/iterations/2026-09-24-primitives-review-comments'
command=[str(Path.home()/'Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--path',str(root),'--xr-mode','off','--script','res://'+(out/'probe.gd').relative_to(root).as_posix()]
with (out/'runtime.log').open('w',encoding='utf-8') as log:
 p=subprocess.Popen(command,stdout=log,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
 try: code=p.wait(timeout=60)
 except subprocess.TimeoutExpired:p.kill();p.wait();code=124
print('Exit',code)
text=(out/'runtime.log').read_text(encoding='utf-8',errors='replace')
print('\n'.join(l for l in text.splitlines() if any(s in l for s in ['SCRIPT ERROR','Parse Error','REVIEW_PROBE','at:']))[-5000:])
sys.exit(code)
