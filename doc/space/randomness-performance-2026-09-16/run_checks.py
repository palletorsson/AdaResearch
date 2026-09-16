import pathlib
import subprocess
OUT=pathlib.Path(__file__).resolve().parent
ROOT=OUT.parents[2]
for name in ['test_projectile_cleanup','test_demo_sun','stream_probe']:
    with (OUT/(name+'.log')).open('w',encoding='utf-8') as log:
        try:
            r=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--xr-mode','off',
                '--path',str(ROOT),'--log-file',str(OUT/(name+'-godot.log')),'--script',
                'res://doc/space/randomness-performance-2026-09-16/'+name+'.gd'],stdout=log,stderr=log,
                timeout=100,creationflags=subprocess.CREATE_NO_WINDOW)
            print(name,r.returncode,flush=True)
        except subprocess.TimeoutExpired:print(name,'TIMEOUT',flush=True)
