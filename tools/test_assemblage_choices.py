from pathlib import Path
import hashlib,json,re,subprocess
R=Path(__file__).resolve().parents[1];O=R/'doc/book/iterations/2026-10-09-assemblage-the-choices-remain';S=R/'doc/book/studies/lsystems-through-the-hands/Assemblage_Same_Desire'
blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',(R/'commons/maps/Assemblage_Same_Desire/tutorial.md').read_text(encoding='utf-8'),re.S)
assert len(blocks)==3
hashes={}
for folder in ['printed','variation','wrong_alias','wrong_redraw']:
    (O/folder).mkdir(exist_ok=True)
    for name,code in blocks:
        data=(code+'\n').encode();assert data==(S/name).read_bytes() and '$' not in code
        if folder=='printed':hashes[name]=hashlib.sha256(data).hexdigest()
        if folder=='variation' and name=='sheet.gd':code=code.replace('0.9 if a else 0.3','0.3 if a else 0.9')
        if folder=='wrong_alias' and name=='sheet.gd':code=code.replace('data.duplicate(true)','data.duplicate()')
        if folder=='wrong_redraw' and name=='assemblage.gd':code=code.replace('model.data.alphabet=Sheet.ALPHABETS[(i+1)%Sheet.ALPHABETS.size()]','model.data.alphabet=Sheet.ALPHABETS[(i+1)%Sheet.ALPHABETS.size()]\n\t\t\tmodel.new_sheet(int(model.data.seed)+1)')
        (O/folder/name).write_bytes((code+'\n').encode())
assert (S/'point_body.gd').read_bytes()==(S.parent/'LSystems_Living/point_body.gd').read_bytes()
(O/'printed-hashes.json').write_bytes(json.dumps(hashes,indent=2).encode())
receipt=O/'checks.json'
if receipt.exists():receipt.unlink()
with (O/'stdout.log').open('w') as log:
    p=subprocess.run(['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--headless','--path',str(R),'--xr-mode','off','--audio-driver','Dummy','--log-file',str(O/'engine.log'),'--script','res://tools/probes/assemblage_choices_lesson.gd'],stdout=log,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
errors=[l for l in (O/'engine.log').read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in l or 'Parse Error' in l]
assert p.returncode==0 and not errors and receipt.exists(),(p.returncode,errors)
d=json.loads(receipt.read_text());assert d['passed'],d['failures']
print(json.dumps({'passed':True,'checks':len(d['checks']),'source_comparisons':d['source_comparisons'],'initial_A':d['initial_A']}))
