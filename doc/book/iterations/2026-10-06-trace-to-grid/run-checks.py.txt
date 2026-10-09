"""Native behavioural evidence for the exact printed Trace -> Grid continuation."""
from pathlib import Path
import hashlib
import json
import os
import re
import shutil
import subprocess
import tempfile
from prepare import HERE, ROOT, PREVIOUS, CANONICAL, compose, sha, save, write

ENGINE=Path(os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'))
EXTENSIONS={'.gd','.tscn','.tres','.gdshader'}
def read(p):return json.loads(p.read_text(encoding='utf-8-sig'))
def rel(p):return p.relative_to(ROOT).as_posix()
def deps(root):return {p.relative_to(root).as_posix():sha(p) for p in (root/'addons/godot-xr-tools').rglob('*') if p.is_file() and p.suffix in EXTENSIONS}
def replace_once(code,a,b):
    assert code.count(a)==1,a
    return code.replace(a,b,1)

def main():
    lesson=CANONICAL.read_text(encoding='utf-8')
    for name in ['grid.gd','point_body.gd','line_skin.gd']:
        blocks=re.findall(r'<!-- student-code:'+re.escape(name)+r' -->\s*```gdscript\n(.*?)^```',lesson,re.M|re.S)
        assert len(blocks)==1 and blocks[0]==(HERE/name).read_text(encoding='utf-8'),name
    prior=read(PREVIOUS/'report-runtime.json')
    assert prior['passed'] and prior['learner_source_sha256']==sha(PREVIOUS/'trace.gd')
    assert (HERE/'incoming.gd').read_bytes()==(PREVIOUS/'trace.gd').read_bytes()
    incoming=(HERE/'incoming.gd').read_text(encoding='utf-8')
    code=(HERE/'grid.gd').read_text(encoding='utf-8')
    operations=read(HERE/'operations.json')
    assert compose(incoming,operations)==code
    for n in ['point_body.gd','line_skin.gd']:assert (HERE/n).read_bytes()==(PREVIOUS/n).read_bytes()
    variant=replace_once(code,'roundi(p.y / grid_step)','0')
    write(HERE/'variants/flat_y.gd',variant)
    save(HERE/'exercise-variants.json',{'flat_y':{'path':rel(HERE/'variants/flat_y.gd'),'sha256':sha(HERE/'variants/flat_y.gd'),'edit':{'before':'roundi(p.y / grid_step)','after':'0'}}})
    save(HERE/'next-input.json',{'incoming':{'path':rel(HERE/'grid.gd'),'sha256':sha(HERE/'grid.gd')},'given_files':[{'path':rel(HERE/n),'sha256':sha(HERE/n)} for n in ['point_body.gd','line_skin.gd']], 'carry':'Same PointBody and station-local source trace; independent address and snapped-position arrays, equal ordered entries; two pitches in one live station. No file or cross-hall transport.'})
    sources=[CANONICAL,ROOT/'commons/maps/Point_Trace/tutorial.md',PREVIOUS/'trace.gd',PREVIOUS/'report-runtime.json',PREVIOUS/'point_body.gd',PREVIOUS/'line_skin.gd']
    evidence=[HERE/n for n in ['prepare.py','run_checks.py','verify.gd','operations.json','grid.gd','point_body.gd','line_skin.gd','incoming.gd','assembled.gd','expected.gd','tutorial.md','next-input.json','exercise-variants.json','variants/flat_y.gd']]
    pins={rel(p):sha(p) for p in sources+evidence}
    dependencies=deps(ROOT)
    work=Path(tempfile.mkdtemp(prefix='ada-trace-grid-'))
    shutil.copytree(ROOT/'addons/godot-xr-tools',work/'addons/godot-xr-tools')
    assert dependencies==deps(work)
    project='''config_version=5
[application]
config/name="Trace to Grid learner check"
config/features=PackedStringArray("4.6")
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[rendering]
renderer/rendering_method="gl_compatibility"
'''
    write(work/'project.godot',project)
    for name in ['grid.gd','incoming.gd','point_body.gd','line_skin.gd','verify.gd']:shutil.copyfile(HERE/name,work/name)
    shutil.copyfile(HERE/'variants/flat_y.gd',work/'flat_y.gd')
    write(work/'mutated_source.gd',replace_once(code,'        snapped_positions.append(Vector3(address) * grid_step)','        snapped_positions.append(Vector3(address) * grid_step)\n    positions.assign(snapped_positions)'))
    write(work/'wrong_frame.gd',replace_once(code,'    for p in positions:\n','    for p in positions:\n        p = to_global(p)\n'))
    write(work/'truncated.gd',code.replace('roundi(p.','int(p.'))
    native={p.name:sha(p) for p in work.glob('*.gd')}
    expected_failures={'mutated_source':['quant/0.25/2/source_kept'],'wrong_frame':['quant/0.25/2/addresses','frame/local_snapshot'],'truncated':['quant/0.25/2/addresses']}
    flags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0
    common=[str(ENGINE),'--headless','--path',str(work),'--xr-mode','off','--audio-driver','Dummy']
    stages=[('import',['--editor','--import','--quit'],0)]+[(name,['--script','res://verify.gd','--',str(work/(name+'.json')),name],0 if name=='positive' else 1) for name in ['positive',*expected_failures]]
    runs=[]
    for name,args,expected in stages:
        result=subprocess.run(common+args,cwd=work,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf-8',errors='replace',timeout=60,creationflags=flags)
        write(HERE/'logs'/f'{name}.log',result.stdout)
        error='SCRIPT ERROR:' in result.stdout or 'ERROR:' in result.stdout
        runs.append({'stage':name,'exit_code':result.returncode,'expected_exit_code':expected,'script_or_engine_error':error})
        print(name,result.returncode,'expected',expected,flush=True)
        if result.returncode!=expected or error:
            print(result.stdout[-9000:],flush=True)
            break
    def result_for(name):return read(work/(name+'.json')) if (work/(name+'.json')).exists() else {'passed':False,'checks':[],'failure_ids':[]}
    positive=result_for('positive')
    negatives=[]
    for name,wanted in expected_failures.items():
        result=result_for(name)
        negatives.append({'name':name,'expected_failure_ids':wanted,'normal_contract_result':result,'expected_failure_detected':not result['passed'] and set(wanted).issubset(result['failure_ids'])})
    ids=[c['id'] for c in positive['checks']]
    complete=len(ids)>=60 and len(ids)==len(set(ids)) and all(id in ids for id in ['xr/pickup','action/same_record','action/desktop_pitch','action/xr_pitch','resume/history','frame/local_snapshot','flat/frame','edge/empty','edge/single'])
    unchanged=pins=={rel(p):sha(p) for p in sources+evidence} and deps(ROOT)==dependencies and deps(work)==dependencies and native=={p.name:sha(p) for p in work.glob('*.gd')}
    passed=bool(positive['passed'] and complete and unchanged and len(runs)==len(stages) and all(n['expected_failure_detected'] for n in negatives) and all(r['exit_code']==r['expected_exit_code'] and not r['script_or_engine_error'] for r in runs))
    scope='Native Godot 4.6 runs the exact printed Grid code, unchanged PointBody/LineSkin and the full flat-Y exercise. Assertions cover manual coordinate oracles, source preservation, local frames, geometry, same-record pitch switching, actual XRTools overlap/grab-driver/action/release with synthetic controller input, and desktop named action. No headset comfort, human learning, cross-hall transport or production museum behaviour is certified.'
    contract={'incoming':{'path':rel(HERE/'incoming.gd'),'sha256':sha(PREVIOUS/'trace.gd')},'operations':operations,'given_files':[{'path':n,'sha256':sha(HERE/n)} for n in ['point_body.gd','line_skin.gd']], 'sources':[{'path':rel(p),'sha256':sha(p)} for p in sources+[HERE/'tutorial.md']], 'checks':[{'id':c['id'],'kind':'native','expect':c['description']} for c in positive['checks']],'evidence_inputs':list(pins),'host':'Existing unit-scale PointStudy in the prepared project; this continuation creates all lesson objects. Same-station source reuse, no scene transfer.'}
    save(HERE/'contract.json',contract)
    report={'passed':passed,'scope':scope,'learner_source_sha256':sha(HERE/'grid.gd'),'incoming_sha256':sha(PREVIOUS/'trace.gd'),'checks':positive['checks'],'positive':positive,'negative_control':negatives[0],'negative_controls':negatives,'inputs':{**pins,rel(HERE/'contract.json'):sha(HERE/'contract.json')},'dependencies':dependencies,'source_and_test_inputs_unchanged':unchanged,'all_declared_checks_present':complete,'continuation_composes_exactly':True,'runs':runs,'private_project':str(work),'engine':str(ENGINE),'native_copy_sha256':native}
    save(HERE/'report-runtime.json',report)
    print('PASSED',passed,'CHECKS',len(ids),'CONTROLS',[n['expected_failure_detected'] for n in negatives],flush=True)
    print('FAILURES',positive['failure_ids'],flush=True)
    print('PROJECT',work,flush=True)
    return 0 if passed else 1

if __name__=='__main__':raise SystemExit(main())
