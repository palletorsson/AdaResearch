"""Extract printed code, run student edits, and reject meaningful faults."""
from pathlib import Path
import hashlib, json, re, subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Randomness_10_PRINT_Algorithm'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'


def main():
    raw=(ROOT/'commons/maps/Randomness_10_PRINT_Algorithm/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'04_two_diagonals.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('# Predictions before execution\n\nThe 8×8 board makes64 draws and64 marks. At p=.5 the expected mean is32, not a fixed count. p=.3 gives mean19.2. A4×3 edit retains the first12 draws; rewrapping them3×4 changes neighbours without changing ordered choices. Cylinder centrelines must meet cell corners. Replay and bias retain the stream; redraw consumes nothing. p0 excludes every draw, p1 includes even an exact1. A new seed must replay but need not look different. Reject missing generator reset, reversed diagonal geometry and omission of the endpoint guard.\n',encoding='utf8')
    code=blocks['04_two_diagonals.gd']
    versions=[('printed',code,True,''),('bias-030',code.replace('var probability := 0.5','var probability := 0.3'),True,''),('four-by-three',code.replace('var columns := 8','var columns := 4').replace('var rows := 8','var rows := 3'),True,''),('no-seed-reset',code.replace('rng.seed = seed_value','pass # fault: never reset'),False,'one ordered random request per address'),('reversed-rods',code.replace('PI / 4 if marks[i] else -PI / 4','-PI / 4 if marks[i] else PI / 4'),False,'rotation joins cell corners with the declared diagonal'),('endpoint-gap',code.replace('probability >= 1.0 or sample < probability','sample < probability'),False,'unit threshold includes sample one')]
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/ten_print_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-4000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text())
        assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures'],'actual_backslashes':data['first_count']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'04_two_diagonals.gd').relative_to(ROOT).as_posix(),'bias':'res://'+(dest/'bias-030.gd').relative_to(ROOT).as_posix()}),encoding='utf8')


if __name__=='__main__':main()
