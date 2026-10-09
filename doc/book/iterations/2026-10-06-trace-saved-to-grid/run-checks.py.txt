from pathlib import Path
import os,json,re,shutil,tempfile,subprocess
from build import HERE,ROOT,OLD,read,write,save,sha
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
def main():
    work=Path(tempfile.mkdtemp(prefix='ada-saved-trace-'))
    shutil.copytree(ROOT/'addons/godot-xr-tools',work/'addons/godot-xr-tools')
    write(work/'project.godot','''config_version=5
[application]
config/name="'''+work.name+'''"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
''')
    for part,main_name,hall,names in [('trace','trace.gd','Point_Trace',['trace.gd','point_body.gd','line_skin.gd','trace_archive.gd']),('grid','grid.gd','Point_Line_Grid',['grid.gd','line_skin.gd','trace_archive.gd'])]:
        lesson=(ROOT/f'commons/maps/{hall}/tutorial.md').read_text()
        for name in names:
            blocks=re.findall(r'<!-- student-code:'+re.escape(name)+r' -->\s*```gdscript\n(.*?)^```',lesson,re.M|re.S)
            assert len(blocks)==1 and blocks[0]==(HERE/part/name).read_text(),name
            shutil.copyfile(HERE/part/name,work/name)
        incoming=(HERE/part/'incoming.gd').read_text()
        for op in read(HERE/part/'operations.json'):
            a=op.get('anchor',op.get('before')); b=a+op['text'] if op['kind']=='insert_after' else op['after']
            assert incoming.count(a)==1
            incoming=incoming.replace(a,b,1)
        assert incoming==(HERE/part/main_name).read_text()
    shutil.copyfile(HERE/'trace/incoming.gd',work/'incoming.gd')
    for name in ['verify_trace.gd','verify_handoff.gd']:shutil.copyfile(HERE/name,work/name)
    for p in (HERE/'trace/variants').glob('*.gd'):shutil.copyfile(p,work/p.name)
    shutil.copyfile(HERE/'grid/flat_y.gd',work/'flat_y.gd')
    trace=(work/'trace.gd').read_text();grid=(work/'grid.gd').read_text()
    write(work/'gate_removed.gd',trace.replace('if (local_position - last).length() >= MIN_SEGMENT_DISTANCE:','if true:'))
    write(work/'wrong_neighbours.gd',trace.replace('var a := positions[i - 1]','var a := positions[0]'))
    write(work/'mutated_source.gd',grid.replace('    _place_on_grid()\n','    positions[0] = Vector3(8,8,8)\n    _place_on_grid()\n',1))
    write(work/'collapsed_edges.gd',grid.replace('Vector3(addresses[i])','Vector3(addresses[i - 1])'))
    sources=[ROOT/'commons/maps/Point_Trace/tutorial.md',ROOT/'commons/maps/Point_Line_Grid/tutorial.md',OLD/'lines/line.gd',OLD/'lines/report-runtime.json']
    sources += [p for p in HERE.rglob('*') if p.is_file() and 'before' not in p.parts and '__pycache__' not in p.parts and p.suffix in ['.gd','.py','.md','.json'] and p.name not in ['report-runtime.json','contract.json','next-input.json','publication.json']]
    pins={p.relative_to(ROOT).as_posix():sha(p) for p in sources}
    deps={p.relative_to(ROOT).as_posix():sha(p) for p in (ROOT/'addons/godot-xr-tools').rglob('*') if p.is_file() and p.suffix in ['.gd','.tscn','.tres','.gdshader']}
    common=[ENGINE,'--headless','--path',str(work),'--xr-mode','off','--audio-driver','Dummy']
    stages=[('import',['--editor','--import','--quit'],0)]
    for script,modes in [('verify_trace.gd',[('positive',0),('gate_removed',1),('wrong_neighbours',1)]),('verify_handoff.gd',[('produce',0),('consume',0),('flat_y',0),('mutated_source',1),('collapsed_edges',1),('empty',0)])]:
        for mode,exit in modes:stages.append((mode,['--script','res://'+script,'--',str(work/(mode+'.json')),mode],exit))
    runs=[]
    for name,args,wanted in stages:
        r=subprocess.run(common+args,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
        write(HERE/'logs'/f'{name}.log',r.stdout)
        error='SCRIPT ERROR:' in r.stdout or 'ERROR:' in r.stdout
        runs.append({'stage':name,'exit_code':r.returncode,'expected_exit_code':wanted,'script_or_engine_error':error})
        print(name,r.returncode,'expected',wanted,flush=True)
        if r.returncode!=wanted or error:
            print(r.stdout[-6000:],flush=True); print('PROJECT',work,flush=True);return 1
    def result(mode):return read(work/(mode+'.json'))
    good=all(sha(ROOT/p)==h for p,h in {**pins,**deps}.items())
    for part,main_name,positive_modes,negative_modes in [('trace','trace.gd',['positive','produce'],['gate_removed','wrong_neighbours']),('grid','grid.gd',['produce','consume','flat_y','empty'],['mutated_source','collapsed_edges'])]:
        checks=[dict(c,id=mode+'/'+c['id']) for mode in positive_modes for c in result(mode)['checks']]
        negatives=[{'name':mode,'expected_failure_detected':not result(mode)['passed'] and bool(result(mode)['failure_ids']),'expected_failure_ids':result(mode)['failure_ids'],'normal_contract_result':result(mode)} for mode in negative_modes]
        # The ordinary contract must fail specifically for the deliberate fault.
        required={'mutated_source':'load/record','collapsed_edges':'pitch/4/geometry','gate_removed':'pause/no_growth','wrong_neighbours':'route/point_3/neighbour_endpoints'}
        for n in negatives:assert required[n['name']] in n['expected_failure_ids'],n
        helpers=['point_body.gd','line_skin.gd','trace_archive.gd'] if part=='trace' else ['line_skin.gd','trace_archive.gd']
        next={'incoming':{'path':(HERE/part/main_name).relative_to(ROOT).as_posix(),'sha256':sha(HERE/part/main_name)},'carry':'Saved local positions and original segment sculpture in the same museum project.'}
        save(HERE/part/'next-input.json',next)
        contract={'incoming':{'sha256':sha(HERE/part/'incoming.gd')},'operations':read(HERE/part/'operations.json'),'given_files':[{'path':n,'sha256':sha(HERE/part/n)} for n in helpers],'sources':[{'path':p,'sha256':h} for p,h in pins.items()],'checks':[{'id':c['id'],'kind':'native'} for c in checks],'evidence_inputs':list(pins)}
        save(HERE/part/'contract.json',contract)
        inputs={**pins,(HERE/part/'contract.json').relative_to(ROOT).as_posix():sha(HERE/part/'contract.json'),(HERE/part/'next-input.json').relative_to(ROOT).as_posix():sha(HERE/part/'next-input.json')}
        report={'passed':good and all(c['passed'] for c in checks) and all(n['expected_failure_detected'] for n in negatives),'checks':checks,'negative_control':negatives[0],'negative_controls':negatives,'inputs':inputs,'dependencies':deps,'learner_source_sha256':sha(HERE/part/main_name),'incoming_sha256':sha(HERE/part/'incoming.gd'),'scope':'Exact printed code in native Godot 4.6. Real XRTools with synthetic controller input saves the actual held-point trace on release; a separate engine process loads the saved sculpture in Grid. Original geometry/data/file preservation, independent copy resources, pitch comparison, absent-save behaviour and flat-Y exercise are asserted. No headset or human learning claim.','runs':runs,'private_project':str(work)}
        save(HERE/part/'report-runtime.json',report)
        print(part,report['passed'],len(checks),'checks',flush=True)
    print('PROJECT',work)
    return 0
if __name__=='__main__':raise SystemExit(main())
