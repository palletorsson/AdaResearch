"""Real Godot assertions and two deliberately broken copies of the sampling core."""
from pathlib import Path
import json
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-samples-and-disagreement/validation'
TEMP=ROOT/'ada_run/sample_budget_tests'
OUT.mkdir(parents=True,exist_ok=True);TEMP.mkdir(parents=True,exist_ok=True)
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def run(script,name):
    report=OUT/(name+'.json')
    if report.exists():report.unlink()
    log=OUT/(name+'.log')
    cmd=[ENGINE,'--path',str(ROOT),'--headless','--xr-mode','off','--audio-driver','Dummy',
         '--script','res://'+script.relative_to(ROOT).as_posix(),'--',str(report)]
    with log.open('w',encoding='utf-8') as stream:
        process=subprocess.Popen(cmd,cwd=ROOT,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        try:code=process.wait(timeout=60)
        except subprocess.TimeoutExpired:process.kill();process.wait();code=124
    data=json.loads(report.read_text()) if report.exists() else {}
    errors=[line for line in log.read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in line or 'Parse Error' in line]
    return {'exit':code,'passed':code==0 and data.get('passed',False) and not errors,
            'checks':len(data.get('checks',[])), 'failures':[c['name'] for c in data.get('checks',[]) if not c['passed']], 'errors':errors}

if __name__=='__main__':
    core=(ROOT/'algorithms/randomness/monte_carlo_dartboard/sample_run.gd').read_text()
    probe=(ROOT/'tools/probes/sample_budget_test.gd').read_text()
    results={'core':run(ROOT/'tools/probes/sample_budget_test.gd','core')}
    for name,old,new in [('boundary-excluded','<= .25','< .25'),('replay-not-rewound','rng.seed = run_seed','if points.is_empty(): rng.seed = run_seed')]:
        assert old in core
        source=TEMP/(name+'.gd');source.write_text(core.replace(old,new),encoding='utf-8')
        test=TEMP/(name+'-test.gd');test.write_text(probe.replace('res://algorithms/randomness/monte_carlo_dartboard/sample_run.gd','res://'+source.relative_to(ROOT).as_posix()),encoding='utf-8')
        results[name]=run(test,name)
    (OUT/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(json.dumps(results,indent=2))
    assert results['core']['passed']
    assert results['boundary-excluded']['exit']==1 and not results['boundary-excluded']['errors']
    assert 'reset rewinds the exact prefix' in results['replay-not-rewound']['failures']
