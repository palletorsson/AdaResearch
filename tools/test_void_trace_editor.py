"""Save a Trace edit and a steel-beam copy through the shared writer, then load in Godot."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, urllib.request
from copy import deepcopy
from validate_void_rooms import ROOT, VOID, validate
from void_editor_io import commit

out=ROOT/'ada_run/void-trace-editor';out.mkdir(exist_ok=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
before=(VOID/'rooms.json').read_bytes();data=json.loads(before)
record=next(a for a in data['floors'][4]['artifacts'] if a['id']=='record')
record['config']={'parts':{'SamplingMonitor':{'position':[4.5,0,-3.8]},'ShadowPoint':{'position':[-12.5,1.05,1.8]},'OutlineBox1':{'rotation':[0,45,0]}}}
data['floors'][4]['copies']=[{'id':'steel-copy','artifact':'void_trace_descent','station':'SE','position':[16.5,6],'height':0,'facing':0,'scale':1,'config':{'only_parts':['Landing0Steel'],'parts':{'Landing0Steel':{'position':[0,.15,0],'rotation':[0,0,0]}},'editor_source':{'floor':4,'id':'descent'}}}]
for name, part, pos, x in [('shadow-copy','ShadowPoint',[0,1.05,0],-18),('outline-copy','OutlineBox0',[0,1.232,0],-16)]:
    data['floors'][4]['copies'].append({'id':name,'artifact':'void_trace_record','station':'SW','position':[x,5],'height':0,'facing':0,'scale':1,'config':{'only_parts':[part],'parts':{part:{'position':pos}},'editor_source':{'floor':4,'id':'record'}}})
assert not validate(data)
bad=deepcopy(data);bad['floors'][4]['copies'][0]['config']['only_parts']=['MissingBeam']
assert validate(bad), 'Unknown part must fail'
request=urllib.request.Request('http://localhost:3003/api/void-layout',json.dumps({'rooms':data,'validateOnly':True}).encode(),{'Content-Type':'application/json'})
assert json.load(urllib.request.urlopen(request))['valid']
draft=out/'draft.json';draft.write_text(json.dumps(data))
saved=out/'saved.json';saved.write_bytes(before)
assert commit(draft,hashlib.sha256(before).hexdigest(),saved)['ok']
assert json.loads(saved.read_text())==data
for rel in ['tools/probes/void_trace_probe.gd','commons/void/line_parts.json']:
    shutil.copy2(ROOT/rel,stage/rel)
shutil.copy2(saved,stage/'trace-editor-draft.json')
result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--headless','--path',str(stage),'--xr-mode','off','--script','res://tools/probes/void_trace_probe.gd','--','--editor','--void-draft=res://trace-editor-draft.json','--out='+str(out)],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=60,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
log=result.stdout+result.stderr;(out/'godot.log').write_text(log,encoding='utf-8')
assert result.returncode==0 and 'SCRIPT ERROR' not in log and '\nERROR:' not in log,log[-4000:]
assert json.loads((out/'editor-checks.json').read_text())['passed']
assert (VOID/'rooms.json').read_bytes()==before
(out/'receipt.json').write_text(json.dumps({'passed':True,'checks':['API validation accepts new part placement and copy','Unknown part rejected','Shared writer retains edited document','Godot loads monitor, steel, Shadow ball and outline edits/copies','Production layout unchanged']},indent=2))
print('5 Trace save checks + native Godot assertions passed; production layout unchanged.')
