"""Fresh extraction and native regression, plus the existing cross-hall transfer probe."""
from prepare import HERE, ROOT, put
import json, os, subprocess, sys
sys.path.insert(0,str(ROOT/'tools'))
import test_tiling_ghost_student as suite

def main():
    suite.OUT=HERE/'evidence'
    suite.prepare()
    suite.run()
    folder=HERE/'evidence'
    report=folder/'transfer.json'; log=folder/'transfer.log'
    res=lambda p:'res://'+p.relative_to(ROOT).as_posix()
    cmd=[os.environ.get('GODOT_EXE','C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'),'--no-window','--rendering-method','gl_compatibility','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/tiling_ghost_transfer.gd','--','--base='+res(folder),'--report='+res(report)]
    with log.open('w',encoding='utf-8') as f:
        result=subprocess.run(cmd,cwd=ROOT,stdout=f,stderr=subprocess.STDOUT,timeout=80,creationflags=subprocess.CREATE_NO_WINDOW if os.name=='nt' else 0)
    data=json.loads(report.read_text());text=log.read_text(encoding='utf-8',errors='replace')
    passed=result.returncode==0 and data.get('passed',False) and 'SCRIPT ERROR:' not in text and 'Parse Error:' not in text
    put(folder/'transfer-run.json',json.dumps({'passed':passed,'exit':result.returncode,'checks':len(data.get('checks',[])),'scope':'Existing teacher-authored six-row transfer probe rerun against fresh printed files. Explicit data copy; not automatic inter-hall persistence.'},indent=2)+'\n')
    assert passed,data
    print('Transfer passed:',len(data['checks']))

if __name__=='__main__':main()
