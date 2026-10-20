from pathlib import Path
import hashlib
import json
import re
import shutil
import subprocess
import sys
import tempfile
import uuid
from prepare_texts import HERE, ROOT, HALLS

ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
VARIANTS = {
    'Tutorial_3D': {'base': [], 'spaced': [('lesson.gd','var spacing := 1.6','var spacing := 2.0')], 'choice': [('lesson.gd','Vector3i(1, 2, 0)','Vector3i(2, 1, 3)')]},
    'Tutorial_Tiling_Floor': {'base': [], 'exception': [('lesson.gd','var exception := false','var exception := true')], 'expanded': [('lesson.gd','var columns := 4','var columns := 8'),('lesson.gd','var rows := 4','var rows := 8')], 'columns': [('pattern_image.gd','(column + row) % 4','column % 4')]},
    'Tutorial_Tiling_Walls': {'base': [], 'turned': [('lesson.gd','var panel_turn := 0.0','var panel_turn := 90.0')], 'choice': [('lesson.gd','var panel_turn := 0.0','var panel_turn := 35.0')]},
    'Tutorial_Disco': {'base': [], 'moved': [('lesson.gd','[true, false, false, false, true, false, false, false]','[true, false, false, true, false, false, false, false]')], 'slow': [('lesson.gd','var bpm := 120.0','var bpm := 90.0')], 'choice': [('lesson.gd','[true, false, false, false, true, false, false, false]','[false, true, true, false, false, true, false, true]')]},
}
FAULTS = {
    'volume_axis': ('Tutorial_3D','lesson.gd','plane[x][z] if y == 0','plane[z][x] if y == 0','fault/plane_conversion'),
    'volume_binding': ('Tutorial_3D','lesson.gd','_on_body_entered.bind(x, y, z)','_on_body_entered.bind(x, z, y)','fault/physical_xyz'),
    'pattern_exception': ('Tutorial_Tiling_Floor','pattern_image.gd','if exception and Vector2i(column, row) == exception_cell:','if exception:','fault/exception_local'),
    'pattern_rule': ('Tutorial_Tiling_Floor','pattern_image.gd','(column + row) % 4','(column + row) % 2','fault/quarter_turn_range'),
    'wall_collision': ('Tutorial_Tiling_Walls','lesson.gd','panel.collision_layer = 1','panel.collision_layer = 0','fault/wall_is_solid'),
    'wall_load': ('Tutorial_Tiling_Walls','lesson.gd','assert(error == OK, "The saved pattern could not be read.")','assert(error == OK, "The saved pattern could not be read.")\n    image.fill(Color.BLACK)','fault/keeps_saved_pixels'),
    'disco_remainder': ('Tutorial_Disco','lesson.gd','score_elapsed -= ticks * duration','score_elapsed = 0.0','fault/elapsed_fraction'),
    'disco_coupled': ('Tutorial_Disco','lesson.gd','if score_running:','if floor_running:','fault/clocks_independent'),
    'disco_stall': ('Tutorial_Disco','lesson.gd','step = (step + ticks) % score.size()','step = (step + 1) % score.size()','fault/elapsed_visits'),
}

def put(path, text):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding='utf-8')

def sha(path): return hashlib.sha256(path.read_bytes()).hexdigest()

def run():
    sources = {}
    for hall in HALLS:
        text = (HERE/hall/'tutorial.md').read_text(encoding='utf-8')
        sources[hall] = dict(re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)^```', text, re.M|re.S))
        assert sources[hall]
        for name, code in sources[hall].items():
            assert code == (HERE/hall/name).read_text(encoding='utf-8')
            assert '$' not in code
    # Reuse the reviewed Array harness and its six causal faults unchanged.
    first = subprocess.run([sys.executable,'-X','utf8',str(HERE/'Array/run_checks.py')],capture_output=True,text=True,encoding='utf-8',timeout=240,creationflags=subprocess.CREATE_NO_WINDOW)
    put(HERE/'logs/array-suite.log',first.stdout+first.stderr)
    print(first.stdout[-1200:],flush=True)
    assert first.returncode == 0, first.stdout+first.stderr
    work = Path(tempfile.mkdtemp(prefix='ada-arrays-book-'))
    project = 'config_version=5\n[application]\nconfig/name="Ada Arrays book checks"\nconfig/features=PackedStringArray("4.6")\nconfig/use_custom_user_dir=true\nconfig/custom_user_dir_name="AdaArraysChecks/'+uuid.uuid4().hex+'"\n[rendering]\nrenderer/rendering_method="gl_compatibility"\n'
    put(work/'project.godot', project)
    put(HERE/'native-project.godot', project)
    shutil.copyfile(HERE/'verify.gd',work/'verify.gd')
    reference=ROOT/'commons/artifacts/regularity/tiling_pattern.gd'
    shutil.copyfile(reference,work/'reference_pattern.gd')
    for hall, variants in VARIANTS.items():
        for variant, edits in variants.items():
            codefiles=sources[hall].copy()
            for filename,old,new in edits:
                assert codefiles[filename].count(old)==1
                codefiles[filename]=codefiles[filename].replace(old,new)
            for filename,code in codefiles.items():
                put(work/hall/variant/filename,code)
                put(HERE/'variants'/hall/variant/filename,code)
    results={}
    def engine(label, directory, args, exit_code=0):
        result=subprocess.run([ENGINE,'--headless','--path',str(directory),'--xr-mode','off','--audio-driver','Dummy']+args,capture_output=True,text=True,encoding='utf-8',errors='replace',timeout=65,creationflags=subprocess.CREATE_NO_WINDOW)
        log=result.stdout+result.stderr
        put(HERE/'logs'/f'{label}.log',log)
        print(label,result.returncode,log[-550:],flush=True)
        assert result.returncode==exit_code and 'SCRIPT ERROR:' not in log and 'ERROR:' not in log and 'leaked' not in log,log
    engine('import',work,['--editor','--import','--quit'])
    for mode in ['normal','walls',*FAULTS]:
        directory=work
        if mode in FAULTS:
            directory=work/'faults'/mode
            put(directory/'project.godot',project)
            shutil.copyfile(HERE/'verify.gd',directory/'verify.gd')
            for hall in VARIANTS:
                for filename,code in sources[hall].items(): put(directory/hall/'base'/filename,code)
            hall,filename,old,new,_=FAULTS[mode]
            file=directory/hall/'base'/filename
            code=file.read_text(encoding='utf-8'); assert code.count(old)==1
            put(file,code.replace(old,new))
        dest=directory/(mode+'-report.json')
        engine(mode,directory,['--script','res://verify.gd','--',mode,str(dest)],0 if mode in ['normal','walls'] else 1)
        results[mode]=json.loads(dest.read_text())
        if mode in FAULTS: assert FAULTS[mode][-1] in results[mode]['failure_ids']
        put(HERE/(mode+'-report.json'),json.dumps(results[mode],indent=2)+'\n')
    array=json.loads((HERE/'Array/verification.json').read_text())
    files=[HERE/hall/name for hall,codefiles in sources.items() for name in codefiles]
    files += [HERE/hall/'tutorial.md' for hall in HALLS]+[HERE/'verify.gd',HERE/'run_checks.py',HERE/'Array/verify.gd',HERE/'Array/run_checks.py',HERE/'Array/build.py',reference]
    for hall in HALLS:
        canonical=ROOT/f'commons/maps/{hall}/tutorial.md'
        if canonical.exists():
            assert canonical.read_bytes()==(HERE/hall/'tutorial.md').read_bytes()
            files.append(canonical)
    report={'passed':True,'engine':'Godot 4.6 stable','assertions':array['assertions']+sum(len(results[k]['checks']) for k in ['normal','walls']),
        'hall_count':5,'printed_files':sum(len(x) for x in sources.values()),'configurations_including_baselines':8+sum(len(v) for v in VARIANTS.values()),
        'variants':VARIANTS,'faults_rejected':array['faults_rejected']+len(FAULTS),'new_faults':{k:{'mutation':v[:-1],'required_failure':v[-1],'detected':True} for k,v in FAULTS.items()},
        'array_evidence':'Array/verification.json','inputs':{p.relative_to(ROOT).as_posix():sha(p) for p in files},'test_project':str(work),
        'scope':'Exact seven printed files; native synthetic bodies, rotated/off-origin host, preserved addresses, copied plane data, image rule and exception, exact PNG saved by Floor then loaded by Walls in a separate engine process, real wall collision, floor/score clock independence, remainder and stalled-frame policy. Teacher-authored tests; no physical headset, full museum installation, human or independent AI student, or audio quality evaluation.'}
    put(HERE/'verification.json',json.dumps(report,indent=2)+'\n')
    print('PASS',report['assertions'],'checks;',report['faults_rejected'],'faults rejected.',flush=True)

if __name__=='__main__':run()
