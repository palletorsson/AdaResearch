"""Extract the printed neighbour study, execute edits, reject deliberate faults."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Space_Geometry'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
def main():
    raw=(ROOT/'commons/maps/Random_Space_Geometry/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',raw,re.S))
    assert set(blocks)=={'10_neighbours_share.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('# Predictions before execution\n\n64 matched row-ordered addresses,128 columns, one Perlin layer. Each independent height is the next uniform RNG draw; field lookup uses integer addresses and nominal signed-to-unsigned mapping. Frequency0.1/0.3 changes only field records, consumes no RNG, and returning restores them. Physical spacing changes only display positions. Seeds42/43 change both fields. Query order does not consume a field. Shared height scale: value0 marker.01, value1 height.65; both bottoms at.9. 112 nonwrapping adjacent edges. Checkerboard32zeros32ones gives gap1; halfplane same histogram gives1/14; constant0.37 gives gap0 with height0.2405. Replay undoes fixtures. Three point actions in translated rotated frame. No draw on moving or dropping. Detect spending a draw during field sample, wrong signed mapping, row wrapping and world-frame controls. No claim that Perlin always has lower gap or identical marginal distribution.\n',encoding='utf8')
    code=blocks['10_neighbours_share.gd']
    versions=[
        ('printed',code,True,''),
        ('higher-frequency',code.replace('frequency := 0.1','frequency := 0.3'),True,''),
        ('wider-grid',code.replace('cell_gap := 0.16','cell_gap := 0.20'),True,''),
        ('another-seed',code.replace('sample_seed := 42','sample_seed := 43'),True,''),
        ('field-consumes',code.replace('func sample_field() -> void:','func sample_field() -> void:\n    rng.randf()'),False,'frequency keeps independent values and RNG state'),
        ('wrong-range',code.replace('(noise.get_noise_2d(at.x, at.y) + 1.0) * 0.5','noise.get_noise_2d(at.x, at.y)'),False,'field record matches declared signed to unsigned map'),
        ('row-wrap',code.replace('if at.x < SIDE - 1:', 'if i < records.size() - 1:'),False,'same histogram split grid has gap one fourteenth'),
        ('world-zones',code.replace('to_local(point.global_position).x','point.global_position.x'),False,'trigger frequency follows rotated local frame')
    ]
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_geometry_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
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
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'10_neighbours_share.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
