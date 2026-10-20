"""Extract the printed student program and run positive and negative cases."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Cubes'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    raw=(ROOT/'commons/maps/Random_Cubes/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'05_a_continuing_die.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('# Predictions before execution\n\n[6,6,3] must retain three events, total15, closed true, limited false. A later result changes nothing. Five sixes reach30 with limited true and closed false. A non-six in the last place closes normally. Changing the continuation predicate to >=5 changes [6,5,2] from [6,5],total11 to [6,5,2],total13. A3-place cap leaves three sixes unfinished at18. Replay restores the generator before any draw. Terminal and invalid requests must not consume randomness. Geometry and joins retain each contribution. Faults use0..5, overwrite the total, conflate cap and closure, or consume a draw despite closure. All must be detected.\n',encoding='utf8')
    code=blocks['05_a_continuing_die.gd']
    versions=[('printed',code,'six',True,''),('five-or-six',code.replace('return face == 6','return face >= 5'),'five',True,''),('three-place-limit',code.replace('var max_draws := 5','var max_draws := 3'),'six',True,''),('zero-based-die',code.replace('rng.randi_range(1, 6)','rng.randi_range(0, 5)'),'six',False,'each accepted point action makes one correctly bounded draw'),('overwrite-total',code.replace('total += face','total = face'),'six',False,'supplied six six three accumulates fifteen'),('cap-is-closed',code.replace('closed = not continues(face)','closed = not continues(face) or history.size() >= max_draws'),'six',False,'all sixes reach an unfinished limit not closure'),('draw-after-stop',code.replace('if closed or limited:\n        return 0','if closed or limited:\n        rng.randi_range(1, 6) # incorrect extra request\n        return 0'),'six',False,'terminal press makes no draw and changes no record')]
    results=[]
    for name,variant,mode,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_cubes_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix(),'--mode='+mode],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-4000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text())
        assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures'],'first_history':data['first_history']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    example=json.loads((OUT/'printed.json').read_text())['example_seed']
    limit=json.loads((OUT/'printed.json').read_text())['limit_seed']
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'05_a_continuing_die.gd').relative_to(ROOT).as_posix(),'short':'res://'+(dest/'three-place-limit.gd').relative_to(ROOT).as_posix(),'example_seed':example,'limit_seed':limit}),encoding='utf8')

if __name__=='__main__':main()
