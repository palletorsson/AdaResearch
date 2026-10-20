"""Source parity and a scoped summary of fresh Tiling evidence."""
from prepare import HERE, ROOT, HALLS, blocks, put, sha
import json

def main():
    results=json.loads((HERE/'evidence/regression-results.json').read_text())
    transfer=json.loads((HERE/'evidence/transfer-run.json').read_text())
    assert results['all_passed'] and all(results['protected_unchanged'].values()) and transfer['passed']
    before=json.loads((HERE/'before-sources.json').read_text())
    preserved={p:d for p,d in before.items() if not (p in [f'commons/maps/{h}/tutorial.md' for h in HALLS] or p=='commons/maps/sequences/tiling.json' or p.startswith('doc/book/course/execution-plan/'))}
    assert all(sha(ROOT/p)==d for p,d in preserved.items())
    old=json.loads((HERE/'before/commons/maps/sequences/tiling.json').read_text())
    now=json.loads((ROOT/'commons/maps/sequences/tiling.json').read_text())
    def without_status(v):
        if isinstance(v,dict):return {k:without_status(x) for k,x in v.items() if k!='learning_objectives_status'}
        if isinstance(v,list):return [without_status(x) for x in v]
        return v
    assert without_status(old)==without_status(now)
    palette=blocks(ROOT/'commons/maps/Color_Grid_Pallet/tutorial.md')
    point=blocks(ROOT/'commons/maps/Color_Nails/tutorial.md')['point_body.gd']
    files=0; carried=[];inputs={}
    for h in HALLS:
        source=ROOT/'commons/maps'/h/'tutorial.md';current=blocks(source);prior=blocks(HERE/'before/commons/maps'/h/'tutorial.md')
        inputs[source.relative_to(ROOT).as_posix()]=sha(source)
        for name,code in current.items():
            assert (HERE/'evidence'/h/'learner/printed'/name).read_text(encoding='utf-8')==code+'\n',(h,name)
            if name!='grid_surface.gd':assert code==prior[name]
            put(HERE/h/name,code+'\n');files+=1
        if h!='Ribbon_Patterns_03':
            for name,expected in [('palette.gd',palette['palette.gd']),('grid_surface.gd',palette['grid_surface.gd']),('point_body.gd',point)]:
                assert current[name]==expected,(h,name)
                carried.append({'hall':h,'file':name,'matches_current_colour':True})
    assert blocks(ROOT/'commons/maps/Symmetry_Seventeen/tutorial.md')['04_surface_frame.gd']==blocks(ROOT/'commons/maps/Array_Patterns/tutorial.md')['04_surface_frame.gd']
    diagnostics={}
    for p in (HERE/'evidence').rglob('*.log'):
        lines=[x for x in p.read_text(encoding='utf-8',errors='replace').splitlines() if any(s in x for s in ['ERROR:','WARNING:'])]
        if lines:diagnostics[p.relative_to(HERE).as_posix()]=list(dict.fromkeys(lines))
    gpu=[]
    for r in results['results']:
        for case in r['results']:
            receipt=json.loads((HERE/'evidence'/r['hall']/case['receipt']).read_text())
            for group in receipt.get('gpu_samples',[]):gpu.append({'hall':r['hall'],'kind':case['kind'],'case':group['case'],'sample_count':len(group['samples'])})
    evidence={'passed':True,'halls':len(HALLS),'printed_file_occurrences':files,'native_assertions':results['checks'],'lesson_runs':results['runs'],'transfer_assertions':transfer['checks'],'gpu_cases':gpu,'reused_colour_files':carried,'inherited_surface_matches':True,'entry_programs_unchanged':True,'finals_unchanged':True,'museum_configs_unchanged':True,'sequence_order_unchanged':True,'inputs':inputs,'diagnostics':diagnostics,'limits':'Teacher-authored regressions and a previously authored transfer probe. No new blind learner study, headset session, runtime installation or mutation run. Existing optional loom and cutting encounters are preserved, not newly certified here.'}
    put(HERE/'sequence-verification.json',json.dumps(evidence,ensure_ascii=False,indent=2)+'\n')
    put(HERE/'preserved.json',json.dumps(preserved,indent=2)+'\n')
    print(json.dumps({k:evidence[k] for k in ['passed','halls','printed_file_occurrences','native_assertions','transfer_assertions','lesson_runs']}))

if __name__=='__main__':main()
