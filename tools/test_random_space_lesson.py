"""Extract and execute the printed study, real edits, and deliberately faulty edits."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Space'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    text=(ROOT/'commons/maps/Random_Space/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
    assert set(blocks)=={'13_fields_add.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    code=blocks['13_fields_add.gd']
    quarter=code.replace('    redraw()\n\nfunc picture','    for i in range(raw.size()):\n        raw[i] *= 0.25\n    redraw()\n\nfunc picture')
    assert quarter!=code
    versions=[('printed',code,True,''),('seed43',code.replace('sample_seed := 42','sample_seed := 43'),True,''),('lac3',code.replace('lacunarity := 2.0','lacunarity := 3.0'),True,''),('weight07',code.replace('persistence := 0.5','persistence := 0.7'),True,''),('resolution64',code.replace('SIDE := 32','SIDE := 64'),True,''),('quarter-sum',quarter,True,''),('reroll-offsets',code.replace('func sample_fields() -> void:','func sample_fields() -> void:\n    offsets[0] = Vector2(rng.randf_range(-100,100),rng.randf_range(-100,100))'),False,'parameter sampling spends no random draws'),('last-only',code.replace('raw.append(total)','raw.append(parts.back().back())'),False,'every cell in one through four layers agrees with source sum'),('integer-address',code.replace('Vector2(float(x) / SIDE, float(y) / SIDE)','Vector2(x / SIDE, y / SIDE)'),False,'every cell in one through four layers agrees with source sum'),('world-zones',code.replace('to_local(point.global_position).x','point.global_position.x'),False,'OCT action uses the local coordinate frame')]
    (OUT/'predictions.md').write_text('Before execution: all8 offsets match source. One through4layers match source _fbm at every sample; initial terms retained; no draws for parameter edits. One layer ignores LAC/PER. Raw sum is sum of stored weighted parts. Pixel stretch leaves raw untouched, keeps positive-rescale contrast and guards constants. Fixed bound3 contains4layers atPER<=.7. Replay restores offsets/current settings; seed43 different. Resolution64 includes32grid at evenindices. Quarter-sum edit changes only completed sum; fixed contrast changes, stretched contrast stays. Point local actions, release/move inert. Four faulty programs must be rejected.\n',encoding='utf8')
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_space_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        if name=='quarter-sum':args.append('--quarter-sum')
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-4000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text());assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures'],'observations':data['observations']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'13_fields_add.gd').relative_to(ROOT).as_posix(),'quarter':'res://'+(dest/'quarter-sum.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
