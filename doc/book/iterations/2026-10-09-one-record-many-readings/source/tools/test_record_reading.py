"""Native assertions for the saved record, including two deliberate faulty cores."""
from pathlib import Path
import json,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-09-one-record-many-readings/validation'
TEMP=ROOT/'ada_run/record_reading_tests'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'
OUT.mkdir(parents=True,exist_ok=True);TEMP.mkdir(parents=True,exist_ok=True)
def run(script,name):
    report=OUT/(name+'.json');log=OUT/(name+'.log')
    if report.exists():report.unlink()
    command=[ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://'+script.relative_to(ROOT).as_posix(),'--',str(report)]
    with log.open('w',encoding='utf-8') as stream:
        process=subprocess.Popen(command,stdout=stream,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
        try:code=process.wait(timeout=45)
        except subprocess.TimeoutExpired:process.kill();process.wait();code=124
    data=json.loads(report.read_text()) if report.exists() else {}
    errors=[s for s in log.read_text(encoding='utf-8',errors='replace').splitlines() if 'SCRIPT ERROR' in s or 'Parse Error' in s]
    return {'exit':code,'passed':code==0 and data.get('passed',False) and not errors,'checks':len(data.get('checks',[])),'errors':errors,'failures':[c['name'] for c in data.get('checks',[]) if not c['passed']]}
if __name__=='__main__':
    probe=ROOT/'tools/probes/record_reading_core.gd'
    source=(ROOT/'commons/artifacts/camera_glitch_study/saved_record.gd').read_text()
    results={'core':run(probe,'core')}
    for name,old,new in [('signed-boundary','value < 128','value <= 128'),('ignored-layout','source.size() != width*height*3','source.size() != LENGTH')]:
        assert old in source
        target=TEMP/(name+'.gd');target.write_text(source.replace(old,new),encoding='utf-8')
        test=TEMP/(name+'-test.gd');test.write_text(probe.read_text().replace('res://commons/artifacts/camera_glitch_study/saved_record.gd','res://'+target.relative_to(ROOT).as_posix()),encoding='utf-8')
        results[name]=run(test,name)
    (OUT/'results.json').write_text(json.dumps(results,indent=2),encoding='utf-8')
    print(json.dumps(results,indent=2))
    assert results['core']['passed']
    assert all(results[n]['exit']==1 and not results[n]['errors'] for n in ['signed-boundary','ignored-layout'])
