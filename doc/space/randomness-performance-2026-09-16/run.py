import json
import pathlib
import subprocess
import sys

OUT = pathlib.Path(__file__).resolve().parent
ROOT = OUT.parents[2]
GODOT = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
names = [v for v in sys.argv[1:] if not v.startswith('--')] or [r['map'] for r in json.loads((OUT.parent/'randomness-staging-2026-09-16/manifest.json').read_text(encoding='utf-8'))]
engine_args = ['--rendering-method','mobile'] if '--mobile' in sys.argv else []
probe_args = ['--quick'] if '--quick' in sys.argv else []
for name in names:
    with (OUT/(name+'-process.log')).open('w',encoding='utf-8') as log:
        try:
            result = subprocess.run([GODOT,'--path',str(ROOT),'--xr-mode','off','--resolution','1280x800',
                '--log-file',str(OUT/(name+'-godot.log')),'--script',
                'res://doc/space/randomness-performance-2026-09-16/profile.gd',*engine_args,'--','--map='+name,*probe_args],
                stdout=log,stderr=log,timeout=100,creationflags=subprocess.CREATE_NO_WINDOW)
            print(name,'exit',result.returncode,flush=True)
        except subprocess.TimeoutExpired:
            print(name,'TIMEOUT',flush=True)
