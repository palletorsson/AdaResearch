from pathlib import Path
import json, re, subprocess, sys
sys.stdout.reconfigure(encoding="utf-8")
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
variant=sys.argv[1] if len(sys.argv)>1 else 'after'
out=HERE/variant
out.mkdir(parents=True,exist_ok=True)
if variant=='before':
    for mode in ('smooth','snap','zero'):
        source=(out/f'joystick_{mode}.tscn.txt').read_text(encoding='utf-8')
        source=re.sub(r' uid="[^"]+"','',source)
        (out/f'joystick_{mode}.tscn').write_text(source,encoding='utf-8')
report=out/'checks.json'
if report.exists(): report.unlink()
cmd=[r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off',
     '--audio-driver','Dummy','--resolution','1600x1200','--rendering-method','mobile',
     '--log-file',str(out/'engine.log'),'--script','res://commons/testing/test_physical_joysticks.gd','--',variant]
with (out/'run.log').open('w',encoding='utf-8') as log:
    try: result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=100,creationflags=subprocess.CREATE_NO_WINDOW)
    except subprocess.TimeoutExpired:
        print((out/'run.log').read_text(encoding='utf-8',errors='replace')[-3500:]);sys.exit(124)
if report.exists():
    data=json.loads(report.read_text(encoding='utf-8'))
    print(len(data['checks']),'checks; failures:',data['failures'])
else: print((out/'run.log').read_text(encoding='utf-8',errors='replace')[-5000:])
sys.exit(result.returncode)
