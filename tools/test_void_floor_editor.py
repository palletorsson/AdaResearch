"""Exercise native editor and shared save validation without editing production rooms."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, tempfile
from void_editor_io import commit
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-18-void-curated-route'
OUT.mkdir(exist_ok=True,parents=True)
GODOT='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
work=ROOT/'ada_run/void-floor-editor-test'
work.mkdir(exist_ok=True); (work/'.gdignore').touch()
stage=Path(tempfile.mkdtemp(dir=work,prefix='run-'))
(work/'latest.txt').write_text(str(stage))
shutil.copytree(ROOT/'addons/void_floor_editor',stage/'addons/void_floor_editor')
(stage/'commons/void').mkdir(parents=True)
for name in ['rooms.json','layout.json','catalog.json','line_parts.json']:
    shutil.copy2(ROOT/'commons/void'/name,stage/'commons/void'/name)
shutil.copy2(ROOT/'tools/probes/void_floor_editor_probe.gd',stage/'probe.gd')
(stage/'project.godot').write_text('''config_version=5
[application]
config/name="Void Floor Editor Test"
[editor_plugins]
enabled=PackedStringArray("res://addons/void_floor_editor/plugin.cfg")
[display]
window/size/viewport_width=1500
window/size/viewport_height=800
[rendering]
renderer/rendering_method="gl_compatibility"
''')
checks=[]
def expect(label, value):
    assert value, label
    checks.append({'check':label,'passed':value})
raw=(ROOT/'commons/void/rooms.json').read_bytes(); revision=hashlib.sha256(raw).hexdigest()
target=stage/'rooms-target.json';target.write_bytes(raw)
draft=stage/'draft.json';draft.write_bytes(raw)
expect('Valid draft accepted',commit(draft,None)['ok'])
expect('Matching revision saves',commit(draft,revision,target)['ok'])
expect('Save creates recoverable backup',bool(list((stage/'.editor-backups').glob('*.json'))))
target.write_bytes(raw+b' ')
expect('Concurrent edit rejects stale save',not commit(draft,revision,target)['ok'])
expect('Concurrent edit left intact',target.read_bytes()==raw+b' ')
bad=json.loads(raw);bad['floors'][3]['walls'].append({'id':'blocked','from':[-12,0],'to':[-8,0],'height':2})
draft.write_text(json.dumps(bad));expect('Shaft obstruction rejected',not commit(draft,None)['ok'])
for label,args in [('editor-import',['--headless','--editor','--import']),('native-editor',['--no-window','--script','res://probe.gd','--','--out='+str(OUT),'--capture'])]:
    proc=subprocess.run([GODOT,'--path',str(stage),*args],capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
    (OUT/(label+'.log')).write_text(proc.stdout+proc.stderr,encoding='utf-8')
    errors='SCRIPT ERROR' in proc.stderr or 'ERROR:' in proc.stderr or 'SCRIPT ERROR' in proc.stdout
    if proc.returncode or errors:
        print(proc.stdout[-5000:]+proc.stderr[-5000:]);raise SystemExit(1)
    print(label+': passed',flush=True)
expect('Production layout never changed', (ROOT/'commons/void/rooms.json').read_bytes()==raw)
(OUT/'editor-save-checks.json').write_text(json.dumps({'passed':True,'checks':checks},indent=2))
print(str(stage))
