"""Native prefab collision/placement checks and Godot screenshots; no layout edits."""
from pathlib import Path
import hashlib,json,os,shutil,subprocess,sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-19-void-barricade-and-fence'
OUT.mkdir(parents=True,exist_ok=True)
rooms=ROOT/'commons/void/rooms.json'
before=hashlib.sha256(rooms.read_bytes()).hexdigest()
# Exercise the same schema/catalog validation used by editor saves, in memory.
candidate=json.loads(rooms.read_text(encoding='utf-8'))
for i,kind in enumerate(('striped_barricade','chainlink_panel')):
    candidate['floors'][7]['props'].append({'id':'probe-'+kind,'kind':kind,'position':[i*5,5.4],'facing':90,'scale':1})
validation=subprocess.run([sys.executable,str(ROOT/'tools/validate_void_rooms.py'),'--stdin','--editor'],input=json.dumps(candidate),text=True,capture_output=True,check=True)
assert json.loads(validation.stdout)['valid'],validation.stdout
if '--staged' not in sys.argv:
    subprocess.run([sys.executable,str(ROOT/'tools/test_void_game.py'),'--reuse','--stage-only','--out='+str(OUT)],check=True)
stage=Path((ROOT/'ada_run/void-game-test/latest.txt').read_text().strip())/'source'
for p in (ROOT/'commons/artifacts/construction_site').iterdir():
    if p.suffix in ['.gd','.tscn']:shutil.copy2(p,stage/p.relative_to(ROOT))
shutil.copy2(ROOT/'tools/probes/void_barriers_probe.gd',stage/'tools/probes/void_barriers_probe.gd')
capture='--capture' in sys.argv
display=['--no-window','--rendering-method','mobile'] if capture else ['--headless']
with (OUT/'engine.log').open('w',encoding='utf-8') as log:
    result=subprocess.run([os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),*display,
        '--path',str(stage),'--fixed-fps','60','--xr-mode','off','--script','res://tools/probes/void_barriers_probe.gd',
        '--','--out='+str(OUT),*(['--capture'] if capture else [])],stdout=log,stderr=log,timeout=180,
        creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
text=(OUT/'engine.log').read_text(encoding='utf-8',errors='replace')
assert result.returncode==0 and 'SCRIPT ERROR' not in text and '\nERROR:' not in text,text[-10000:]
receipt=json.loads((OUT/'checks.json').read_text())
assert receipt['passed'],receipt
assert hashlib.sha256(rooms.read_bytes()).hexdigest()==before,'Shared layout changed during probe'
print(f'{len(receipt["checks"])} checks passed; shared layout unchanged.',flush=True)
