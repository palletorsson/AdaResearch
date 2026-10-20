from pathlib import Path
import re,json,hashlib,subprocess
R=Path(__file__).resolve().parents[1]
O=R/'doc/book/iterations/2026-10-09-mirrored-a-copy-kept'
S=R/'doc/book/studies/procedural-generation-through-the-hands/PG_Mirrored_Patterns'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/PG_Mirrored_Patterns/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_alias','wrong_address','wrong_input']:
    (O/folder).mkdir(exist_ok=True)
    for name,source in blocks:
        assert (source+'\n').encode()==(S/name).read_bytes() and '$' not in source
        code=source
        if name=='reflection.gd':
            if folder=='variation':code=code.replace('INCLUDE_AXES := false','INCLUDE_AXES := true')
            if folder=='wrong_alias':code=code.replace('result = held.duplicate(true)','result = held')
            if folder=='wrong_address':code=code.replace('n - 1 - x','n - 2 - x')
            if folder=='wrong_input':code=code.replace('func reflect() -> void:\n\toriginal()', 'func reflect() -> void:\n\tpass')
        (O/folder/name).write_bytes((code+'\n').encode())
        if folder=='printed':hashes[name]=hashlib.sha256((code+'\n').encode()).hexdigest()
assert (S/'point_body.gd').read_bytes()==(S.parent/'PG_Sculpted_Forms/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_text(json.dumps(hashes,indent=2))
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w',encoding='utf-8') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/mirrored_copy_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_comparisons':d['source_comparisons'],'comparisons':d['source_comparisons']}))
