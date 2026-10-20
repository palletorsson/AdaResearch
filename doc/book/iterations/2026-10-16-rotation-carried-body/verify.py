"""Apply only the printed edits to Translation, then test the reconstructed scenes."""
import hashlib
import json
import re
import shutil
import subprocess
import tempfile
from prepare import HERE, ROOT, PRIOR, CANONICAL, put, sha, block, function

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
    'orbit': [('var offset := Vector3.ZERO','var offset := Vector3(2, 0, 0)')],
    'vertical': [('var offset := Vector3.ZERO','var offset := Vector3(2, 0, 0)'),('var axis := Vector3.UP','var axis := Vector3.FORWARD')],
    'slow': [('var offset := Vector3.ZERO','var offset := Vector3(2, 0, 0)'),('var axis := Vector3.UP','var axis := Vector3.FORWARD'),('var duration := 8.0','var duration := 16.0')],
    'axis_length': [('var offset := Vector3.ZERO','var offset := Vector3(2, 0, 0)'),('var axis := Vector3.UP','var axis := Vector3(0, 4, 0)')],
}
FAULTS = {
    'keeps_world_instead_of_local': ('travel.reparent(pivot, false)','travel.reparent(pivot, true)','base/30/initial_centre'),
    'degrees_as_radians': ('deg_to_rad(360.0 * value)','360.0 * value','base/30/quarter_direction'),
    'turn_stops_after_one': ('deg_to_rad(360.0 * value)','deg_to_rad(360.0 * clampf(value, 0.0, 1.0))','base/30/continues'),
    'mark_outside_body': ('mark.reparent(travel, false)','mark.reparent(pivot, false)','base/30/mark_parent'),
    'accumulated_angle_added_again': ('pivot.basis = Basis(axis.normalized(), angle)','pivot.basis = pivot.basis * Basis(axis.normalized(), angle)','base/30/quarter_direction'),
}
SCENE = '[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="lesson.gd" id="Lesson"]\n\n[node name="TransformStudy" type="Node3D"]\nscript = ExtResource("Lesson")\n'

def replace_once(source, old, new):
    assert old and source.count(old) == 1, 'Missing or ambiguous edit anchor'
    return source.replace(old,new)

def assemble():
    # The predecessor is the previously tested output, not another hand-written fixture.
    previous = json.loads((PRIOR / 'verification.json').read_text(encoding='utf-8'))
    for path, digest in previous['inputs'].items():
        assert sha(ROOT/path)==digest, 'Predecessor evidence is stale: '+path
    incoming = (HERE/'incoming/lesson.gd').read_text(encoding='utf-8')
    assert incoming == (PRIOR/'assembled/complete/lesson.gd').read_text(encoding='utf-8')
    assert incoming == block((ROOT/'commons/maps/Trans_Translation/tutorial.md').read_text(encoding='utf-8'))
    helper = (HERE/'incoming/box_body.gd').read_text(encoding='utf-8')
    assert helper == (PRIOR/'assembled/complete/box_body.gd').read_text(encoding='utf-8')
    tutorial = CANONICAL.read_text(encoding='utf-8')
    assert tutorial == (HERE/'tutorial.md').read_text(encoding='utf-8')
    manifest=json.loads((HERE/'edits.json').read_text(encoding='utf-8'))
    source=incoming
    edits=[]
    rejected=[]
    states={'incoming':incoming}
    for op in manifest['operations']:
        assert op['instruction'] in tutorial
        pieces = re.findall(r'<!-- student-edit:'+re.escape(op['id'])+r' -->\s*```gdscript\n(.*?)^```',tutorial,re.M|re.S)
        assert len(pieces)==1
        new=pieces[0]
        assert hashlib.sha256(new.encode()).hexdigest()==op['expected_sha256']
        for kind,bad in [('missing',source.replace(op['old'],'')),('ambiguous',source+'\n'+op['old'])]:
            try: replace_once(bad,op['old'],new)
            except AssertionError: rejected.append(op['id']+'/'+kind)
            else: raise AssertionError('Bad anchor accepted')
        put(HERE/'steps'/op['id']/'lesson.gd',source)
        line=source[:source.index(op['old'])].count('\n')+1
        source=replace_once(source,op['old'],new+op['old'] if op['mode']=='before' else new)
        edits.append(dict(id=op['id'],file=op['file'],instruction=op['instruction'],incoming_line=line))
        if op['id']=='turn-the-frame': states['turn']=source
    states['complete']=source
    for state,script in states.items():
        assert script==(HERE/state/'lesson.gd').read_text(encoding='utf-8')
        assert helper==(HERE/state/'box_body.gd').read_text(encoding='utf-8')
        assert function(script,'box')==function(incoming,'box'), 'Inherited placement function changed'
        assert function(script,'_process')==function(incoming,'_process'), 'Inherited clock changed'
        assert script.count('func _ready()')==1 and '$' not in script
        put(HERE/'assembled'/state/'lesson.gd',script)
        put(HERE/'assembled'/state/'box_body.gd',helper)
        put(HERE/state/'study.tscn',SCENE)
    assert source==block(tutorial)
    report=dict(passed=True,printed_edits=len(edits),edits=edits,rejected_bad_anchors=rejected,
                inherited_box_function_unchanged=True,inherited_process_function_unchanged=True,inherited_box_body_sha256=hashlib.sha256(helper.encode()).hexdigest(),
                predecessor_receipt_sha256=sha(PRIOR/'verification.json'))
    put(HERE/'assembly-report.json',json.dumps(report,indent=2)+'\n')
    return states,helper,report

def main():
    states,helper,assembly=assemble()
    work=__import__('pathlib').Path(tempfile.mkdtemp(prefix='ada-rotation-continuation-'))
    config='config_version=5\n[application]\nconfig/name="Ada Rotation continuation tests"\nconfig/features=PackedStringArray("4.6")\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
    put(work/'project.godot',config)
    put(HERE/'native-project.godot',config)
    shutil.copyfile(HERE/'verify.gd',work/'verify.gd')
    for group in ['normal',*FAULTS]:
        for state,script in states.items():
            variants={'base':[],**VARIANTS} if state=='complete' else {'base':[]}
            for variant,changes in variants.items():
                source=script
                for old,new in changes: source=replace_once(source,old,new)
                if group!='normal' and state=='complete':
                    old,new,_=FAULTS[group]
                    source=replace_once(source,old,new)
                dest=work/group/state/variant
                for name,value in [('lesson.gd',source),('box_body.gd',helper),('study.tscn',SCENE)]:
                    put(dest/name,value)
                    if group=='normal' and state=='complete' and variant!='base': put(HERE/'variants'/variant/name,value)
    common=[ENGINE,'--headless','--path',str(work),'--xr-mode','off','--audio-driver','Dummy']
    def run(name,args,expected):
        p=subprocess.run(common+args,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
        log=p.stdout+p.stderr
        put(HERE/'logs'/(name+'.log'),log)
        print(name,p.returncode,log[-700:],flush=True)
        assert p.returncode==expected and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log,log
    run('import',['--editor','--import','--quit'],0)
    results={}
    for group in ['normal',*FAULTS]:
        report=work/(group+'.json')
        run(group,['--script','res://verify.gd','--',group,str(report)],0 if group=='normal' else 1)
        results[group]=json.loads(report.read_text(encoding='utf-8'))
        if group!='normal': assert FAULTS[group][2] in results[group]['failure_ids']
        put(HERE/(group+'-report.json'),json.dumps(results[group],indent=2)+'\n')
    before=json.loads((HERE/'before.json').read_text(encoding='utf-8'))
    preserved={path:sha(ROOT/path)==digest for path,digest in before.items() if path.endswith('/final.md') or path=='commons/maps/Trans_Translation/tutorial.md'}
    assert all(preserved.values())
    inputs=[ROOT/'commons/maps/Trans_Rotation/final.md',CANONICAL,HERE/'tutorial.md',HERE/'edits.json',HERE/'verify.py',HERE/'verify.gd',HERE/'native-project.godot',PRIOR/'verification.json',ROOT/'commons/maps/Trans_Translation/tutorial.md']
    inputs += [p for folder in ['incoming','turn','complete','assembled','variants'] for p in (HERE/folder).rglob('*') if p.suffix in ['.gd','.tscn']]
    receipt=dict(passed=True,engine='Godot 4.6 stable',native_assertions=len(results['normal']['checks']),exercise_variants=3,additional_axis_variant=1,
        faults={name:dict(detected=True,required_failure=f[2]) for name,f in FAULTS.items()},assembly=assembly,
        inputs={p.relative_to(ROOT).as_posix():sha(p) for p in inputs},preserved=preserved,test_project=str(work),
        scope='Printed edits applied to the tested Translation state; exact match with full files. Native scene execution, source variants, real process callback, pivot and mark hierarchy, centre/orbit, degrees/radians, shape and local/world invariance. Visual study only: no rider physics or headset/learner claim.')
    put(HERE/'verification.json',json.dumps(receipt,indent=2)+'\n')
    print('PASS',receipt['native_assertions'],'assertions; 3 exercise variants + 1 axis case; 5 behaviour faults; 8 bad anchors rejected.')

if __name__=='__main__': main()
