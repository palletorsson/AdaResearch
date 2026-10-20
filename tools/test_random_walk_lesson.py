"""Extract the printed walker; run three meaningful edits and deliberate faults."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Walk'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
def main():
    raw=(ROOT/'commons/maps/Random_Walk/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'07_a_point_keeps_steps.gd','point_body.gd','line_skin.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('# Predictions before execution\n\nOne draw gives a fixed-length XZ proposal, added to current position. Reflection at0.85 sends0.90 to0.80; clamping sends it to0.85. At a corner both axes fold. Accepted endpoints are joined by chords and can be closer than the proposal length.128 steps retain129 positions and128 segments; no draw after completion. Equal step counts replay only with same seed, start and rule. Clearing stored history must not steer the next step. Doubling the step doubles the first displacement before boundaries; changing cadence leaves equal-step paths unchanged. Held time draws nothing; release projects a local start; trigger+release restores the previous origin. Wrong assignment, absent boundary, missing last record and partial replay must fail.\n',encoding='utf8')
    code=blocks['07_a_point_keeps_steps.gd']
    versions=[('printed',code,False,True,''),('double-step',code.replace('step_size := 0.12','step_size := 0.24'),False,True,''),('slower-clock',code.replace('seconds_per_step := 0.25','seconds_per_step := 0.5'),False,True,''),('clamp-boundary',code.replace('reflect_endpoint(proposed)','Vector3(clampf(proposed.x, -HALF, HALF), HEIGHT, clampf(proposed.z, -HALF, HALF))'),True,True,''),('lost-position',code.replace('proposed = current + displacement','proposed = Vector3(0, HEIGHT, 0) + displacement'),False,False,'all128 steps accumulate then apply the declared boundary'),('no-boundary',code.replace('var accepted := reflect_endpoint(proposed)','var accepted := proposed'),False,False,'actual edge step uses reflection or the authored clamp edit'),('missing-endpoint',code.replace('positions.append(current)','pass # lost record'),False,False,'record includes start and every accepted endpoint'),('partial-replay',code.replace('rng.seed = seed_value','if positions.is_empty(): rng.seed = seed_value'),False,False,'same seed start and rule reproduce whole path')]
    results=[]
    for name,variant,clamp,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_walk_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        if clamp:args.append('--clamp')
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-3000:]
        assert not [line for line in log.splitlines() if line.startswith('ERROR:') and 'Unrecognized UID' not in line],log[-3000:]
        assert receipt.exists(),log[-3000:]
        data=json.loads(receipt.read_text())
        assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'07_a_point_keeps_steps.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
