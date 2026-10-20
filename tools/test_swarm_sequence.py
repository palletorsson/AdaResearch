"""Run the seven printed lessons in spine order; preserve a fresh run receipt."""
from pathlib import Path
import datetime, hashlib, json, subprocess, sys

R = Path(__file__).resolve().parents[1]
O = R/'doc/book/iterations/2026-10-10-swarm-sequence-review'
JOBS = [
 ('physarum', '2026-10-10-swarm-a-trace-outside'),
 ('flow', '2026-10-10-flow-directions-already-here'),
 ('boids', '2026-10-10-boids-who-is-near'),
 ('abm', '2026-10-10-abm-what-the-point-carries'),
 ('aco', '2026-10-10-colony-two-trails-underfoot'),
 ('pso', '2026-10-10-pso-a-place-remembered'),
 ('account', '2026-10-10-swarm-who-keeps-the-count'),
]

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()
def now(): return datetime.datetime.now(datetime.timezone.utc).isoformat()
def save(data):
    (O/'sequence-checks.json').write_bytes((json.dumps(data,indent=2)+'\n').encode())

if __name__ == '__main__':
    O.mkdir(parents=True,exist_ok=True)
    seq=json.loads((R/'commons/maps/sequences/swarmintelligence.json').read_text(encoding='utf8'))['sequences']['swarmintelligence']['maps']
    assert len(seq)==len(JOBS)
    result={'started':now(),'completed':False,'passed':False,'halls':[],
      'scope':'Author-operated Godot reconstruction from the exact printed code, one independent edit and three executed faulty variants per hall. Synthetic XR, not a headset session or independent reader. Fresh native-room captures are not part of this run.'}
    save(result)
    body_hashes=[]
    for id,(key,report) in zip(seq,JOBS):
        began=now()
        cp=subprocess.run([sys.executable,str(R/'tools'/f'test_swarm_{key}.py')],cwd=R,capture_output=True,timeout=150)
        (O/f'{key}.log').write_bytes(cp.stdout+cp.stderr)
        receipt=R/'doc/book/iterations'/report/'checks.json'
        d=json.loads(receipt.read_text(encoding='utf8')) if receipt.exists() else {}
        p=R/'commons/maps'/id
        # Runner hashes normalized text: canonical prose is LF after our edits.
        tutorial_hash=hashlib.sha256((p/'tutorial.md').read_text(encoding='utf8').encode()).hexdigest()
        fresh=d.get('finished','')>=began and d.get('tutorial_sha256')==tutorial_hash
        passed=cp.returncode==0 and bool(d.get('passed')) and bool(d.get('completed')) and fresh
        target=O/'receipts'/f'{key}.json';target.parent.mkdir(exist_ok=True)
        if receipt.exists(): target.write_bytes(receipt.read_bytes())
        row={'hall':id,'key':key,'report':report,'started':began,'finished':now(),'passed':passed,
             'returncode':cp.returncode,'checks':len(d.get('checks',[])),
             'tutorial_sha256':sha(p/'tutorial.md'),'final_sha256':sha(p/'final.md'),
             'receipt':f'receipts/{key}.json','log':f'{key}.log'}
        body_hashes.append(sha(R/'doc/book/studies/swarm-through-the-hands'/id/'point_body.gd'))
        result['halls'].append(row);save(result)
        print(f'{key}: {row["checks"]} checks, '+('PASS' if passed else 'FAIL'),flush=True)
        if not passed:
            print((cp.stdout+cp.stderr).decode('utf8',errors='replace')[-4000:],flush=True)
            sys.exit(1)
    result.update(completed=True,passed=True,finished=now(),
        total_checks=sum(h['checks'] for h in result['halls']),
        same_pointbody_all_seven=len(set(body_hashes))==1,pointbody_sha256=body_hashes[0])
    assert result['same_pointbody_all_seven']
    save(result)
    print(f'{result["total_checks"]} checks passed; PointBody identical in all seven halls.',flush=True)
