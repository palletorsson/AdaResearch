from pathlib import Path
import json, subprocess
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
out=HERE/'regression'
out.mkdir(parents=True,exist_ok=True)
prefix='res://'+out.relative_to(ROOT).as_posix()+'/'
script=(ROOT/'commons/testing/test_instrument_console.gd').read_text(encoding='utf-8')
script=script.replace('res://doc/reports/interfaces-2026-09-20/console-finish/',prefix)
(out/'test.gd').write_text(script,encoding='utf-8')
cmd=[r'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off',
     '--audio-driver','Dummy','--resolution','1600x1200','--rendering-method','mobile',
     '--log-file',str(out/'engine.log'),'--script',prefix+'test.gd']
with (out/'run.log').open('w',encoding='utf-8') as log:
    result=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=100,creationflags=subprocess.CREATE_NO_WINDOW)
assert result.returncode==0,result.returncode
data=json.loads((out/'instrument-checks.json').read_text(encoding='utf-8'))
assert not data['failures'],data
assert 'SCRIPT ERROR' not in (out/'run.log').read_text(encoding='utf-8',errors='replace')
print(data)
