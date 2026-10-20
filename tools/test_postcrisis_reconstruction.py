"""Extract only canonical printed code and explicitly named earlier files; run Godot."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
from write_postcrisis_tutorials import HALLS,KEYS,ROOT,STUDY,OUT
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
PATTERN=r'<!-- student-code:([\w_]+\.gd) -->\s*```gdscript\n(.*?)\n```'
def main():
    files={};sources={}
    for hall,names in [('Euclid_Parallel',['point_body.gd','line_skin.gd']),('Russell_Paradox',['bench.gd']),('Florensky_Paraconsistent',['reports.gd'])]:
        p=ROOT/'commons/maps'/hall/'tutorial.md';text=p.read_text(encoding='utf8')
        for name,code in re.findall(PATTERN,text,re.S):
            if name in names:files[name]=code+'\n'
        assert all(n in files for n in names),(hall,names)
        sources[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    lineage=[]
    for hall in HALLS:
        added=[]
        p=ROOT/'commons/maps'/hall/'tutorial.md'
        for name,code in re.findall(PATTERN,p.read_text(encoding='utf8'),re.S):
            assert name not in files,name
            files[name]=code+'\n'
            added.append(name)
        for name in added:
            for dependency in re.findall(r'(?:preload\(|extends\s+)"([^"\n]+\.gd)"', files[name]):
                if not dependency.startswith("res://"):
                    assert dependency in files, (hall,name,"hidden future dependency",dependency)
        lineage.append({"hall":hall,"new_files":added,"available_files":list(files)})
        sources[p.relative_to(ROOT).as_posix()]=hashlib.sha256(p.read_bytes()).hexdigest()
    learner=OUT/'learner';learner.mkdir(exist_ok=True)
    for name,code in files.items():
        assert (STUDY/name).read_text(encoding='utf8')==code,name
        (learner/name).write_text(code,encoding='utf8')
    record={'lineage':lineage,'sources':sources,'files':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()},'method':'Author-operated ghost student; exact printed files and declared earlier dependencies. Not an independent reader.'}
    (OUT/'reconstruction.json').write_text(json.dumps(record,indent=2))
    command=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/postcrisis_student.gd','--','--no-bridges']
    with (OUT/'ghost-engine.log').open('w',encoding='utf8') as f:
        run=subprocess.run(command,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=90,creationflags=subprocess.CREATE_NO_WINDOW)
    log=(OUT/'ghost-engine.log').read_text(encoding='utf8');print(log[-6500:])
    assert run.returncode==0 and 'SCRIPT ERROR' not in log,run.returncode
    result=json.loads((OUT/'ghost-results.json').read_text());assert result['passed']
    commands=[]
    for key in KEYS:
        command=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script',str(learner/'check.gd'),'--',str(learner/('assert_'+key+'.gd')),'--no-bridges']
        run=subprocess.run(command,cwd=ROOT,stdout=subprocess.PIPE,stderr=subprocess.STDOUT,text=True,encoding='utf8',timeout=60,creationflags=subprocess.CREATE_NO_WINDOW)
        passed=run.returncode==0 and 'SCRIPT ERROR' not in run.stdout and 'PASS' in run.stdout
        (OUT/('command-'+key+'.log')).write_text(run.stdout,encoding='utf8')
        commands.append({'lesson':key,'command':command,'passed':passed,'exit_code':run.returncode,'extracted_files':record['files']})
        assert passed,(key,run.stdout[-3000:])
    (OUT/'student-commands.json').write_text(json.dumps(commands,indent=2),encoding='utf8')
    print(len(files),'printed/carried files;',len(result['checks']),'assertions and interaction checks passed')
if __name__=='__main__':main()
