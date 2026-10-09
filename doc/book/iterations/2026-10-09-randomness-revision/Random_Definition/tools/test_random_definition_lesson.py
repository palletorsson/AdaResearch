"""Extract the printed lesson, run edits and reject relevant broken variants."""
from pathlib import Path
import hashlib,json,re,subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Definition'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def run(source,name,mode='rgb'):
    target=OUT/(name+'.json')
    if target.exists():target.unlink()
    with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
        result=subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_definition_student.gd','--',
            '--lesson=res://'+source.relative_to(ROOT).as_posix(),'--report=res://'+target.relative_to(ROOT).as_posix(),'--mode='+mode],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
    logs=(OUT/(name+'.log')).read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in logs and 'Parse Error' not in logs,logs[-4000:]
    assert target.exists(),logs[-4000:]
    return result.returncode,json.loads(target.read_text())

def main():
    OUT.mkdir(exist_ok=True,parents=True)
    text=(ROOT/'commons/maps/Random_Definition/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
    assert set(blocks)=={'01_seed_picture.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    predictions='''# Predictions saved before execution\n\nRGB: identical procedures give equal panels, 48 draws each. One discard changes only the right panel: first colour uses draws 2,3,4, and generator ends after 49 draws. Replay must preserve the selected difference; waiting must not advance the study RNG.\n\nEdited assignments: gray and red/blue swap retain the same draw counts. Transfer: side=2, seed=731, shifted right uses 13 draws; original instance stays unchanged.\n\nFaults: resetting inside the cube loop destroys stream progression; discarding after colouring fails the shifted assignment even when the final draw count is correct.\n'''
    if not (OUT/'predictions.md').exists():(OUT/'predictions.md').write_text(predictions,encoding='utf8')
    source=blocks['01_seed_picture.gd']
    results=[]
    for name,code,mode,expected_pass in [
        ('printed',source,'rgb',True),
        ('grayscale',source.replace('Color(a, b, c)','Color(a, a, a)'),'gray',True),
        ('swapped',source.replace('Color(a, b, c)','Color(c, b, a)'),'swap',True),
        ('reset-each-cube',source.replace('for cube in cubes:\n','for cube in cubes:\n        rng.seed = seed_value\n'),'rgb',False),
        ('discard-after',source.replace('    if skip:\n        rng.randf()\n','').replace('    return colours','    if skip:\n        rng.randf()\n    return colours'),'rgb',False)]:
        path=dest/(name+'.gd');path.write_text(code+'\n',encoding='utf8')
        rc,data=run(path,name,mode)
        if expected_pass:assert rc==0 and data['passed'],data['failures']
        else:
            assert rc!=0 and not data['passed'],name
            assert 'all shifted cells match the independently grouped stream' in data['failures']
        results.append({'version':name,'expected_pass':expected_pass,'exit':rc,'checks':len(data['checks']),'passed':data['passed'],'failures':data['failures']})
        print(name,len(data['checks']),data['passed'])
    (OUT/'tests.json').write_text(json.dumps({'results':results,'files':{name:hashlib.sha256((dest/name).read_bytes()).hexdigest() for name in blocks},'scope':'Author-informed reconstruction; assertion counts are not learner outcomes.'},indent=2),encoding='utf8')

if __name__=='__main__':main()
