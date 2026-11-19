"""Refresh just the new route models using the ordinary C: publication pipeline."""
import json, subprocess, sys
from pathlib import Path
from void_native_slot import acquire_native_slot

ROOT=Path(__file__).resolve().parents[1]
rooms=json.loads((ROOT/'commons/void/rooms.json').read_text(encoding='utf8'))
routes=[(i,a['id']) for i,f in enumerate(rooms['floors']) for a in f['artifacts'] if a['artifact']=='sequence_descent']
start_batch=int(next((a.split('=',1)[1] for a in sys.argv if a.startswith('--start-batch=')), '0'))
if not 0 <= start_batch < (len(routes)+2)//3:
    raise ValueError('Start batch is outside the installed route list')
out=ROOT/'ada_run/sequence-descents/publication';out.mkdir(parents=True,exist_ok=True)
with acquire_native_slot('Publish sequence descents'):
    for start in range(0,len(routes),3):
        if start//3 < start_batch: continue
        batch=routes[start:start+3]
        target=out/('batch-'+str(start//3));target.mkdir(exist_ok=True)
        cmd=[sys.executable,str(ROOT/'tools/export_void_floors.py'),','.join(str(i) for i,_ in batch),str(target),
             '--preview-items='+json.dumps([name for _,name in batch])]
        print('Publishing floors '+','.join(str(i) for i,_ in batch),flush=True)
        with (target/'publish.log').open('w',encoding='utf8') as log:
            result=subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=300)
        if result.returncode:
            print((target/'publish.log').read_text(encoding='utf8',errors='replace')[-6000:])
            raise SystemExit(result.returncode)
print('Published all '+str(len(routes))+' route previews.',flush=True)
