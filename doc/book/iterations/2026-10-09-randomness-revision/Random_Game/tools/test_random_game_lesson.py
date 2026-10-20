from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Game'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
def main():
    text=(ROOT/'commons/maps/Random_Game/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
    assert set(blocks)=={'wait_cycle.gd','14_a_wait_kept.gd','point_body.gd'}
    for n,c in blocks.items():assert c==(ROOT/'doc/book/studies/randomness-lineage'/n).read_text(encoding='utf8').rstrip()
    model=blocks['wait_cycle.gd'];host=blocks['14_a_wait_kept.gd']
    versions=[('printed',model,host,True,''),('short-notice',model.replace('notice_ms := 1200','notice_ms := 300'),host,True,''),('seed43',model.replace('run_seed := 42','run_seed := 43'),host,True,''),('fixed-standing',model.replace('Vector2(2.4, 4.6)','Vector2(3.0, 3.0)'),host,True,''),('cue-retimes',model.replace('func cue_visible() -> bool:','func cue_visible() -> bool:\n    until_ms += 1'),host,False,'reading the cue cannot change the schedule'),('no-rewind',model.replace('    rng.seed = run_seed\n',''),host,False,'replay rewinds the complete schedule'),('lost-overshoot',model.replace('while target_ms >= until_ms:','if target_ms >= until_ms:'),host,False,'coarse and fine updates retain identical schedule'),('world-zones',model,host.replace('to_local(point.global_position).x','point.global_position.x'),False,'CUE action uses local point coordinates')]
    (OUT/'predictions.md').write_text('Expect four complete programs to preserve source draw parity and phase boundaries. Short notice changes only warning duration. Fixed standing consumes no random value, moving subsequent hidden draws earlier in the stream. Seed changes durations, not state order. Coarse/fine clock updates must agree; cue reads and toggles must not change deadlines. Replay restores clock/seed/height/support. Reject cue-retiming, missing seed reset, discarded elapsed time and world-space actions.\n',encoding='utf8')
    results=[]
    for name,m,h,expected,fault in versions:
        dest=OUT/'extracted'/name;dest.mkdir(parents=True,exist_ok=True)
        for n,c in {**blocks,'wait_cycle.gd':m,'14_a_wait_kept.gd':h}.items():(dest/n).write_text(c+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_game_student.gd','--','--lesson=res://'+(dest/'14_a_wait_kept.gd').relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:run=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8');assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-5000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text());assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures'],'observations':data['observations']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((OUT/'extracted/printed'/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(OUT/'extracted/printed/14_a_wait_kept.gd').relative_to(ROOT).as_posix(),'short_notice':'res://'+(OUT/'extracted/short-notice/14_a_wait_kept.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
