from pathlib import Path
import json, shutil, subprocess, sys
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-formfinding-build-and-investigate'
NAMES=['Descent','Catenary','Relaxation','Equilibrium','Annealing','Forge']
def main():
    phase=sys.argv[1] if len(sys.argv)>1 else 'before'
    names=sys.argv[2:] or NAMES
    results=[]
    for name in names:
        room='FormFinding_'+name
        dest=OUT/phase/room
        dest.mkdir(parents=True,exist_ok=True)
        cmd=[sys.executable,'-X','utf8','tools/run_encounter_probe.py',room,'--sequence','formfinding','--probe','tools/probes/formfinding_lessons_museum.gd','--render']
        if phase=='after':
            config=json.loads((OUT/'halls.json').read_text(encoding='utf8'))
            row=next(x for x in config if x['map']==room)
            spec=dest/'spec.json'
            spec.write_text(json.dumps({'lesson':'res://doc/book/studies/formfinding-lineage/'+row['script'],'bay':row['bay']}),encoding='utf8')
            cmd+=['--spec',str(spec)]
        run=subprocess.run(cmd,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf8')
        print(run.stdout[-1200:],flush=True)
        folder=ROOT/'ada_run/encounter_pilot'/room
        for p in folder.iterdir():
            if p.suffix=='.png' or p.name in ['report.json','engine.log','source_manifest.json']:shutil.copy2(p,dest/p.name)
        result={'map':room,'exit':run.returncode,'passed':False}
        if (dest/'report.json').exists():result['passed']=json.loads((dest/'report.json').read_text(encoding='utf8'))['passed'] and run.returncode==0
        results.append(result)
        (OUT/(phase+'-capture-status.json')).write_text(json.dumps(results,indent=2),encoding='utf8')
    return 0 if all(x['passed'] for x in results) else 1
if __name__=='__main__':raise SystemExit(main())
