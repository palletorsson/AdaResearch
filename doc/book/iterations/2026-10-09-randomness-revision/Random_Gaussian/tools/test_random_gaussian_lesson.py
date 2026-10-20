"""Extract printed files, run source edits, reject faults in accounting."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Gaussian'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    raw=(ROOT/'commons/maps/Random_Gaussian/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'08_values_and_bins.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('''# Predictions before execution

Gaussian uses two uniform draws; uniform uses one. Batch retains raw values. Counts sum to N, and only occupied bins draw bars. Rebinning or redrawing cannot advance the RNG; returning to ten bins restores counts. The raw fixture [-0.2,0,0.05,0.49,0.5,0.99,1,1.3] gives [4,4] in two bins with two clips; raw values remain. One belongs to the last bin. A full or negative batch draws nothing. Doubling deviation doubles raw offsets from the mean, before display clipping. A150 cap gives100 then50. Forty bins change only the partition. Replay needs the same seed, law, parameters, amount and engine version. Moving the point without its trigger draws nothing. Deliberate extra RNG on rebin, wrapping the last endpoint, retaining old counts and storing only clipped values must fail.
''',encoding='utf8')
    code=blocks['08_values_and_bins.gd']
    versions=[('printed',code,True,''),('double-deviation',code.replace('deviation := 0.15','deviation := 0.30'),True,''),('smaller-budget',code.replace('sample_limit := 300','sample_limit := 150'),True,''),('forty-bins',code.replace('rebin(20 if bin_count == 10 else 10)','rebin(40 if bin_count == 10 else 10)'),True,''),('redraw-consumes',code.replace('func rebin(n: int) -> void:','func rebin(n: int) -> void:\n    rng.randf()'),False,'rebin cannot advance generator or change clipped total'),('last-bin-wraps',code.replace('mini(int(value * bin_count), bin_count - 1)','int(value * bin_count) % bin_count'),False,'two-bin fixture counts boundaries and endpoints'),('old-counts',code.replace('counts.fill(0)','pass # forgot zeroing'),False,'return to10 restores the original counts'),('raw-lost',code.replace('values.append(sample_value())','values.append(clampf(sample_value(), 0.0, 1.0))'),False,'wide Gaussian keeps out-of-display raw values')]
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_gaussian_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-4000:]
        assert not [l for l in log.splitlines() if l.startswith('ERROR:') and 'Unrecognized UID' not in l],log[-4000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text())
        assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'08_values_and_bins.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
