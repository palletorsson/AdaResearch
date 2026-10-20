"""Extract the printed population study, execute edits, reject deliberate faults."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Mushrooms'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
def main():
    raw=(ROOT/'commons/maps/Random_Mushrooms/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'09_a_population_kept.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('''# Predictions before execution

Each slot samples kind, yaw and scale in that order. Twelve records; six retains the first six. Fixed grid addresses, no randomly chosen positions. SIZE changes only node scales; records, node identity and RNG stay. REPLAY recreates all values under seed42 even when SIZE off; NEXT SEED adds1. Scale1 retains recipe dimensions. Widening .7..1.3 to.4..1.6 doubles offsets from1 and leaves kind/yaw/position fixed. Rebuild must consume no draw. Empty/negative counts draw nothing; counts above12 are bounded. Known two-body fixture tan-stem.15 at scales.7/1.3 gives.105/.195; unit scale equalizes them but not tan/red stem dimensions. Adding a third recipe permits a tallbody without promising a draw will choose it. Point actions use table-local frame. No movement/release sampling. Deliberate redraw, lost scale, fixed stem and world-frame selection must be detected.
''',encoding='utf8')
    code=blocks['09_a_population_kept.gd']
    third=code.replace('Color(0.8, 0.2, 0.2)}','Color(0.8, 0.2, 0.2)},\n    {"cap": 0.12, "stem": 0.35, "colour": Color(0.9, 0.9, 0.8)}')
    versions=[('printed',code,True,''),('wider-range',code.replace('size_low := 0.7','size_low := 0.4').replace('size_high := 1.3','size_high := 1.6'),True,''),('six-bodies',code.replace('count := 12','count := 6'),True,''),('third-recipe',third,True,''),('size-consumes',code.replace('func toggle_size() -> void:','func toggle_size() -> void:\n    rng.randf()'),False,'SIZE keeps records and generator'),('scale-lost',code.replace('"size": size','"size": 1.0'),False,'records preserve named kind turn and sampled scale'),('fixed-stem',code.replace('stem.height = recipe.stem','stem.height = 0.15'),False,'different recipes at scale one remain unequal'),('world-zones',code.replace('to_local(point.global_position).x','point.global_position.x'),False,'trigger SIZE follows rotated local frame')]
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_mushrooms_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
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
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'09_a_population_kept.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
