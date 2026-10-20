"""Reconstruct the printed second Randomness lesson and test its boundaries."""
from pathlib import Path
import hashlib,json,re,subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Entropy'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    raw=(ROOT/'commons/maps/Random_Entropy/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'02_counts_and_neighbours.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    predictions=OUT/'predictions.md'
    if not predictions.exists():predictions.write_text('''# Predictions before running\n\nSorting a copy preserves the original list, counts and marginal H; no RNG request. Record16 cycles0123: counts4,4,4,4; H2; adjacent changes15 versus3 sorted. Allzero16: H0; only symbol0 bar visible, full0.7m height. Fixed-quarter bars0.175m. Unequal8,4,2,2 gives H1.75. Twelve cyclic entries in three categories: Hlog2(3), neighbour counts11 versus2. Palette changes cannot alter counts.\n\nReject aliasing original/copy, dividing counts by alphabet size, and requesting randomness merely to sort.\n''',encoding='utf8')
    source=blocks['02_counts_and_neighbours.gd']
    append='record.append(rng.randi_range(0, palette.size() - 1))'
    versions=[
        ('printed',source,'sampled',True,''),
        ('cycle',source.replace(append,'record.append(i % palette.size())'),'cycle',True,''),
        ('one-symbol',source.replace(append,'record.append(0)'),'single',True,''),
        ('alias-original',source.replace('shown = record.duplicate()','shown = record'),'sampled',False,'sorting preserves original order'),
        ('wrong-denominator',source.replace('float(count) / total','float(count) / counts.size()'),'sampled',False,'four equal shares give two bits'),
        ('draw-on-sort',source.replace('if sorted_view:\n        shown.sort()','if sorted_view:\n        rng.randf()\n        shown.sort()'),'sampled',False,'sorting makes no random requests')]
    results=[]
    for name,code,mode,expected_pass,fault in versions:
        path=dest/(name+'.gd');path.write_text(code+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            result=subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_entropy_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix(),'--mode='+mode],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        output=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in output and 'Parse Error' not in output,output[-4000:]
        assert receipt.exists(),output[-3000:]
        data=json.loads(receipt.read_text())
        assert data['passed']==expected_pass and (result.returncode==0)==expected_pass,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected_pass,'checks':len(data['checks']),'failures':data['failures']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{name:hashlib.sha256((dest/name).read_bytes()).hexdigest() for name in blocks}},indent=2),encoding='utf8')

if __name__=='__main__':main()
