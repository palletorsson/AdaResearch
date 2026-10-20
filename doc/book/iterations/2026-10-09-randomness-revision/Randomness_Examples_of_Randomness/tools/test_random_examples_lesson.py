"""Run the exact printed files, three source edits and four relevant faults."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Randomness_Examples_of_Randomness'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    text=(ROOT/'commons/maps/Randomness_Examples_of_Randomness/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
    assert set(blocks)=={'11_a_draw_estimates.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('Before execution: empty count displays --, consumes no draws. Two draws per position, unit-circle verdict, float ratio, one mark and one history dot per sample. Replay restores seed and empties dynamic nodes; 256 cap spends no draws. Batch32 matches sixteen batches16 and one-by-one prefix. Seed43 differs. Span.2 confines samples to central strip; original factor4 lacks original-area justification. Supplied inherited point actions use transformed local X; motion/drop alone do nothing. Instances independent. Reject missing rewind, integer ratio, wrong circle radius and world-coordinate controls. No requirement that the ratio improves monotonically or is close to pi.\n',encoding='utf8')
    code=blocks['11_a_draw_estimates.gd']
    versions=[('printed',code,True,''),('batch32',code.replace('BATCH := 16','BATCH := 32'),True,''),('seed43',code.replace('sample_seed := 42','sample_seed := 43'),True,''),('biased-strip',code.replace('x_span := 1.0','x_span := 0.2'),True,''),('no-rewind',code.replace('rng.seed = sample_seed','pass # omitted rewind'),False,'replay rewinds its private generator'),('integer-ratio',code.replace('4.0 * inside / samples.size()','float(4 * (inside / samples.size()))'),False,'circle verdict and every floating ratio agree with independent tally'),('wrong-radius',code.replace('p.length_squared() <= 1.0','p.length_squared() <= 0.25'),False,'circle verdict and every floating ratio agree with independent tally'),('world-zones',code.replace('to_local(point.global_position).x','point.global_position.x'),False,'one action follows transformed local frame')]
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_examples_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
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
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'11_a_draw_estimates.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
