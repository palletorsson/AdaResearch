"""Extract the printed comparison, test edits, and reject conceptual faults."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Rotate_Random_XYZ'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    raw=(ROOT/'commons/maps/Random_Rotate_Random_XYZ/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'06_turns_kept.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('# Predictions before execution\n\nThe first input gives equal poses; later inputs need not. Supplied +10,+10,-5 degrees leave latest=-5 and sum=15. Opposite turns cancel. Two half-turns leave a full stored turn but an identity orientation. Replay keeps record and RNG; playback never draws. Equal elapsed time at different frame partitions reads the same prefix, including a slow frame. Pause retains its partial interval; manual STEP clears it. Amplitude40 doubles amplitude20 samples at the same seed; changing Z to X retains those values but changes poses. A finite or empty record cannot overrun. Reject overwriting the sum, drawing during replay, reading one entry per slow frame, and changing position with angle.\n',encoding='utf8')
    code=blocks['06_turns_kept.gd']
    loop='for i in range(step_count):\n        turns.append(deg_to_rad(rng.randf_range(-limit_degrees, limit_degrees)))'
    versions=[('printed',code,False,True,''),
        ('double-amplitude',code.replace('limit_degrees := 20.0','limit_degrees := 40.0'),False,True,''),
        ('x-axis',code.replace('TURN_AXIS := Vector3.BACK','TURN_AXIS := Vector3.RIGHT'),False,True,''),
        ('supplied-record',code.replace(loop,'turns.assign([deg_to_rad(10.0), deg_to_rad(10.0), deg_to_rad(-5.0)])'),True,True,''),
        ('lost-history',code.replace('total += latest','total = latest'),False,False,'ten ten minus five leaves latest minus five and sum fifteen'),
        ('replay-draws',code.replace('func replay() -> void:\n','func replay() -> void:\n    rng.randf() # unintended draw\n'),False,False,'replay retains record and generator'),
        ('slow-frame-loses-steps',code.replace('while elapsed >= seconds_per_step','if elapsed >= seconds_per_step'),False,False,'one slow frame consumes every complete interval'),
        ('turn-moves-centre',code.replace('assigned.basis = Basis(TURN_AXIS, latest)','assigned.basis = Basis(TURN_AXIS, latest)\n    assigned.position.x = latest'),False,False,'rotation keeps centre mesh size and scale')]
    results=[]
    for name,variant,fixed,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_rotate_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        if fixed:args.append('--fixed')
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-4000:]
        assert not [line for line in log.splitlines() if line.startswith('ERROR:') and 'Unrecognized UID' not in line],log[-4000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text())
        assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'06_turns_kept.gd').relative_to(ROOT).as_posix()}),encoding='utf8')

if __name__=='__main__':main()
