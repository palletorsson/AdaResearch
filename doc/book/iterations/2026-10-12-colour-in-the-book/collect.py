"""Verify fresh evidence and exact printed-source correspondence for all eight halls."""
from prepare import HERE, ROOT, OLD, HALLS, put, sha
import json, re

def main():
    batches=[HERE/h/'verification.json' for h in HALLS[:3]]+[HERE/'verification.json']
    reports=[]
    for p in batches:
        r=json.loads(p.read_text()); assert r['passed']
        for n,digest in r['inputs'].items():
            f=ROOT/n if n.startswith('doc/') else p.parent/n
            assert sha(f)==digest,'Evidence drift: '+str(f)
        reports.append(r)
    sources={}; changes=[]; count=0
    for hall in HALLS:
        text=(HERE/hall/'tutorial.md').read_text(encoding='utf-8')
        blocks=re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)^```',text,re.M|re.S)
        assert len(blocks)==len({n for n,_ in blocks}) and blocks,hall
        for n,t in blocks:
            f=HERE/hall/n
            assert t==f.read_text(encoding='utf-8').rstrip()+'\n',(hall,n)
            sources[f.relative_to(ROOT).as_posix()]=sha(f);count+=1
            if sha(f)!=sha(OLD/hall/n):changes.append(hall+'/'+n)
        for n in ['tutorial.md','final.md']: sources[(HERE/hall/n).relative_to(ROOT).as_posix()]=sha(HERE/hall/n)
    assert changes==['Color_Grid_Pallet/grid_surface.gd','Color_Grid_Pallet/controls.gd','Color_Walls/controls.gd'],changes
    for h in ['Color_Pillar','Color_Paint']: assert sha(HERE/h/'point_body.gd')==sha(HERE/'Color_Nails/point_body.gd')
    assert sha(HERE/'Color_Grid_Pallet/palette.gd')==sha(HERE/'Color_Walls/palette.gd')
    for p in batches:sources[p.relative_to(ROOT).as_posix()]=sha(p)
    inputs=['collect.py','lineage.json']
    for n in inputs:sources[(HERE/n).relative_to(ROOT).as_posix()]=sha(HERE/n)
    diagnostics=[]
    for p in [HERE/'logs/import.log',HERE/'Color_Nails/logs/import.log']:
        diagnostics.extend([{'file':p.relative_to(ROOT).as_posix(),'message':line} for line in p.read_text(encoding='utf-8').splitlines() if 'Unicode parsing error' in line])
    result={'passed':True,'date':'2026-10-12','engine':'Godot 4.6 stable','halls':8,'printed_files':count,
        'native_assertions':sum(r.get('native_assertions',r.get('assertions',0)) for r in reports),
        'render_assertions':sum(r.get('render_assertions',0) for r in reports),
        'configurations_including_baselines':sum(len(r.get('variant_edits',{})) for r in reports[:3])+reports[3]['variants'],
        'faults_rejected':sum(r['faults_rejected'] for r in reports),'changed_student_files':changes,'inputs':sources,
        'import_diagnostics':diagnostics,'scope':'Fresh teacher-authored native and GPU checks of exact printed files; synthetic XR pickup and pointer input. No independent learner, physical headset or live-hall installation test.'}
    put(HERE/'sequence-verification.json',json.dumps(result,indent=2)+'\n')
    print({k:v for k,v in result.items() if k not in ['inputs','import_diagnostics']})

if __name__=='__main__': main()
