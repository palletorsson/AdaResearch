"""Reconstruct canonical printed files; run author-operated ghost assertions."""
from pathlib import Path
import hashlib,json,re,subprocess,sys
from write_foundations_reconstruction import LESSONS
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-11-foundations-reconstruction'
PRINT=OUT/'learner'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
sys.stdout.reconfigure(encoding='utf-8',errors='replace')

def main():
    PRINT.mkdir(parents=True,exist_ok=True)
    files={};sources={}
    # Carried dependencies are reconstructed from their canonical earlier text.
    euclid=ROOT/'commons/maps/Euclid_Parallel/tutorial.md'
    for name,code in re.findall(r'<!-- student-code:([\w_]+\.gd) -->\s*```gdscript\n(.*?)\n```',euclid.read_text(encoding='utf-8'),re.S):
        if name in ['point_body.gd','line_skin.gd']:files[name]=code+'\n'
    assert set(files)=={'point_body.gd','line_skin.gd'}
    sources[str(euclid.relative_to(ROOT))]=hashlib.sha256(euclid.read_bytes()).hexdigest()
    for hall,*_ in LESSONS:
        p=ROOT/'commons/maps'/hall/'tutorial.md'
        sources[str(p.relative_to(ROOT))]=hashlib.sha256(p.read_bytes()).hexdigest()
        blocks=re.findall(r'<!-- student-code:([\w_]+\.gd) -->\s*```gdscript\n(.*?)\n```',p.read_text(encoding='utf-8'),re.S)
        assert len(blocks)==(3 if hall in ['Russell_Paradox','Godel_Incompleteness'] else 2),(hall,len(blocks))
        for name,code in blocks:
            assert name not in files,name
            files[name]=code+'\n'
    for name,code in files.items():
        assert code==(ROOT/'doc/book/studies/foundations-lineage'/name).read_text(encoding='utf-8'),name
        (PRINT/name).write_text(code,encoding='utf-8')
    (OUT/'reconstruction.json').write_text(json.dumps({'sources':sources,'files':{n:hashlib.sha256(c.encode()).hexdigest() for n,c in files.items()},'scope':'Exact printed source plus explicitly carried Euclid files; author-operated, not blind.'},indent=2))
    command=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/foundations_student.gd','--','--no-bridges']
    with (OUT/'ghost-engine.log').open('w',encoding='utf-8') as f:
        result=subprocess.run(command,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=75,creationflags=subprocess.CREATE_NO_WINDOW)
    log=(OUT/'ghost-engine.log').read_text(encoding='utf-8')
    print(log[-7500:])
    assert result.returncode==0 and 'SCRIPT ERROR' not in log
    report=json.loads((OUT/'ghost-results.json').read_text())
    assert report['passed']
    print(len(report['checks']),'ghost reconstruction checks PASS;',len(files),'printed/carried files')

if __name__=='__main__':main()
