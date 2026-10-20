"""Extract current printed files and run the existing native lesson assertions."""
from concurrent.futures import ThreadPoolExecutor, as_completed
from pathlib import Path
import hashlib
import json
import re
import subprocess

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-randomness-review-ready'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
PROBES=['random_definition','random_entropy','random_remove','ten_print','random_cubes','random_rotate','random_walk','random_gaussian','random_mushrooms','random_geometry','random_examples','random_pheromone','random_space','random_game']


def main():
    maps=json.loads((ROOT/'commons/maps/sequences/randomness.json').read_text(encoding='utf-8-sig'))['sequences']['randomness']['maps']
    tasks=[]
    for m,probe in zip(maps,PROBES):
        text=(ROOT/'commons/maps'/m/'tutorial.md').read_text(encoding='utf-8')
        before=(OUT/'before'/m/'tutorial.md').read_text(encoding='utf-8-sig')
        assert re.findall(r'```gdscript\s*\n(.*?)```',before,re.S)==re.findall(r'```gdscript\s*\n(.*?)```',text,re.S),m
        blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',text,re.S))
        dest=OUT/'learner'/m;dest.mkdir(parents=True,exist_ok=True)
        for name,code in blocks.items():(dest/name).write_text(code+'\n',encoding='utf-8')
        entry=next(name for name in blocks if re.match(r'\d\d_',name))
        tasks.append((m,probe,dest/entry,{name:hashlib.sha256((dest/name).read_bytes()).hexdigest() for name in blocks}))
    (OUT/'tests').mkdir(exist_ok=True)
    def run(task):
        m,probe,source,hashes=task
        receipt=OUT/'tests'/(m+'.json');logfile=receipt.with_suffix('.log')
        if receipt.exists():receipt.unlink()
        args=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/'+probe+'_student.gd','--','--lesson=res://'+source.relative_to(ROOT).as_posix(),'--report=res://'+receipt.relative_to(ROOT).as_posix()]
        with logfile.open('w',encoding='utf-8') as log:
            result=subprocess.run(args,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
        log=logfile.read_text(encoding='utf-8')
        data=json.loads(receipt.read_text(encoding='utf-8')) if receipt.exists() else {}
        passed=result.returncode==0 and data.get('passed') is True and 'SCRIPT ERROR' not in log and 'Parse Error' not in log
        return {'map':m,'passed':passed,'exit':result.returncode,'checks':len(data.get('checks',[])),'failures':data.get('failures',[]),'printed_sha256':hashes,'probe':'tools/probes/'+probe+'_student.gd','log_messages':[l for l in log.splitlines() if l.startswith(('ERROR:','WARNING:'))]}
    results=[]
    with ThreadPoolExecutor(max_workers=2) as pool:
        futures=[pool.submit(run,t) for t in tasks]
        for future in as_completed(futures):
            r=future.result();results.append(r);print(r['map'],r['checks'],'PASS' if r['passed'] else 'FAIL',flush=True)
    results.sort(key=lambda r:maps.index(r['map']))
    (OUT/'tests.json').write_text(json.dumps({'results':results,'all_passed':all(r['passed'] for r in results),'total_checks':sum(r['checks'] for r in results),'scope':'Fresh current printed baseline per hall through existing native assertions. Earlier independent edits and mutation tests remain dated per-hall evidence. No fresh headset or independent human learner test.'},indent=2,ensure_ascii=False)+'\n',encoding='utf-8')
    assert all(r['passed'] for r in results),[r for r in results if not r['passed']]


if __name__=='__main__':main()
