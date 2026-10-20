"""Run exact printed files, five source edits and four faults against source rules."""
from pathlib import Path
import hashlib,json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-revision/Random_Pheromone'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def main():
    text=(ROOT/'commons/maps/Random_Pheromone/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
    assert set(blocks)=={'12_a_visit_guides.gd','point_body.gd'}
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        (dest/name).write_text(code+'\n',encoding='utf8')
        assert code==(ROOT/'doc/book/studies/randomness-lineage'/name).read_text(encoding='utf8').rstrip()
    (OUT/'predictions.md').write_text('Before execution: one walker,64 scent and visit addresses, two views. Initialpathone/visitszero; eachstep decays then deposits at departure then chooses/moves. Compare100steps perpolicy against actual production methods reduced to8x8,border0,sensor1,singlewalker; retainactualrandf plus optionalrandi draworder. Same timestep and batchgroups match. Strictblankties +X,invalidsensedtargets skipped; random8directions clamped including staying. Visits do not guide; fade preserves visits/path/RNG. No decay =>60 scent after100departures. Additionalfade20 erasesdeposits butkeepsvisits. Limit256 stops everyoperation. Fourlocalpointzones, noidle/move/drop steps. Detect wrong ties, visits usedas scent, fadingvisits andworldcontrols.\n',encoding='utf8')
    code=blocks['12_a_visit_guides.gd']
    versions=[('printed',code,True,''),('seed43',code.replace('sample_seed := 42','sample_seed := 43'),True,''),('guided-only',code.replace('guidance := 0.4','guidance := 1.0'),True,''),('unguided',code.replace('guidance := 0.4','guidance := 0.0'),True,''),('no-decay',code.replace('decay_rate := 0.2','decay_rate := 0.0'),True,''),('erase-scent',code.replace('        path.append(at)','        path.append(at)\n        fade(20.0)\n        # visits and path are deliberately retained'),True,''),('last-tie',code.replace('scent > best','scent >= best'),False,'strict empty tie goes to first positiveX'),('read-visits',code.replace('var scent := field[index(target)]','var scent := float(visits[index(target)])'),False,'attract reads strongest scent not visit height'),('erase-visits',code.replace('func fade(seconds: float) -> void:','func fade(seconds: float) -> void:\n    visits.fill(0)'),False,'fading erases scent but keeps visits path and RNG'),('world-zones',code.replace('to_local(point.global_position).x','point.global_position.x'),False,'STEP action uses local frame')]
    results=[]
    for name,variant,expected,fault in versions:
        path=dest/(name+'.gd');path.write_text(variant+'\n',encoding='utf8')
        receipt=OUT/(name+'.json')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/random_pheromone_student.gd','--','--lesson=res://'+path.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        if name=='erase-scent':args.append('--extra-fade')
        with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
            run=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
        log=(OUT/(name+'.log')).read_text(encoding='utf8')
        assert 'SCRIPT ERROR' not in log and 'Parse Error' not in log,log[-4000:]
        assert receipt.exists(),log[-4000:]
        data=json.loads(receipt.read_text());assert data['passed']==expected and (run.returncode==0)==expected,data
        if fault:assert fault in data['failures'],data
        results.append({'version':name,'passed':data['passed'],'expected_pass':expected,'checks':len(data['checks']),'failures':data['failures'],'observations':data['observations']})
        print(name,len(data['checks']),data['passed'],flush=True)
    (OUT/'tests.json').write_text(json.dumps({'results':results,'printed_sha256':{n:hashlib.sha256((dest/n).read_bytes()).hexdigest() for n in blocks}},indent=2),encoding='utf8')
    (OUT/'museum-spec.json').write_text(json.dumps({'lesson':'res://'+(dest/'12_a_visit_guides.gd').relative_to(ROOT).as_posix()}),encoding='utf8')
if __name__=='__main__':main()
