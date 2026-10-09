from pathlib import Path
import json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-beats-a-difference-in-time'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def run(source,name):
    report=OUT/(name+'.json')
    if report.exists():report.unlink()
    with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
        p=subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/wavefunctions_beats_student.gd','--','--lesson=res://'+source.relative_to(ROOT).as_posix(),'--report=res://'+report.relative_to(ROOT).as_posix()],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
    log=(OUT/(name+'.log')).read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log,log[-5000:]
    assert report.exists(),log[-5000:]
    return p.returncode,json.loads(report.read_text())

def main():
    tutorial=(ROOT/'commons/maps/WaveFunctions_TrigWalkingPath/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S))
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        assert code==(ROOT/'doc/book/studies/wavefunctions-lineage'/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
    status,data=run(dest/'11_two_cycles.gd','student-test')
    assert status==0 and data['passed'],data['failures']
    print('Printed program:',len(data['checks']),'checks passed',flush=True)
    mutations={
        'unsigned-inputs':('Vector3(a, b, a + b)','Vector3(a, b, absf(a) + absf(b))'),
        'hidden-gain':('value *= 0.5','value *= 1.0'),
        'no-restart':('    elapsed = 0.0\n    draw_state()','    elapsed = elapsed\n    draw_state()')
    }
    results=[]
    for name,(before,after) in mutations.items():
        code=blocks['11_two_cycles.gd'];assert before in code
        source=dest/(name+'.gd');source.write_text(code.replace(before,after)+'\n',encoding='utf8')
        status,data=run(source,name)
        assert status!=0 and not data['passed'],name
        results.append({'fault':name,'rejected':True,'failures':data['failures']})
        print(name,'rejected',flush=True)
    (OUT/'mutation-tests.json').write_text(json.dumps(results,indent=2),encoding='utf8')

if __name__=='__main__':main()
