from pathlib import Path
import json,re,subprocess
ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-air-music-after-contact'
ENGINE='C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def run(source,name):
    report=OUT/(name+'.json')
    if report.exists():report.unlink()
    with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
        p=subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off','--audio-driver','Dummy','--script','res://tools/probes/wavefunctions_air_music_student.gd','--','--lesson=res://'+source.relative_to(ROOT).as_posix(),'--report=res://'+report.relative_to(ROOT).as_posix()],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45,creationflags=subprocess.CREATE_NO_WINDOW)
    log=(OUT/(name+'.log')).read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in log,log[-5000:]
    assert report.exists(),log[-5000:]
    return p.returncode,json.loads(report.read_text())

def main():
    tutorial=(ROOT/'commons/maps/WaveFunctions_AirMusic/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S))
    dest=OUT/'extracted';dest.mkdir(exist_ok=True)
    for name,code in blocks.items():
        assert code==(ROOT/'doc/book/studies/wavefunctions-lineage'/name).read_text(encoding='utf8').rstrip()
        (dest/name).write_text(code+'\n',encoding='utf8')
    status,data=run(dest/'09_contact_voices.gd','student-test')
    assert status==0 and data['passed'],data['failures']
    print('Printed program:',len(data['checks']),'checks passed',flush=True)
    mutations={
        'second-stops-first':('    players[index].play()','    for player in players:\n        player.stop()\n    players[index].play()'),
        'all-bodies-accepted':('if body != point:','if body == null:'),
        'shared-age':('samples[i], ages[i] + offset','samples[i], ages[0] + offset')
    }
    results=[]
    for name,(before,after) in mutations.items():
        code=blocks['09_contact_voices.gd'];assert before in code
        source=dest/(name+'.gd');source.write_text(code.replace(before,after)+'\n',encoding='utf8')
        status,data=run(source,name)
        assert status!=0 and not data['passed'],name
        results.append({'fault':name,'rejected':True,'failures':data['failures']})
        print(name,'rejected',flush=True)
    (OUT/'mutation-tests.json').write_text(json.dumps(results,indent=2),encoding='utf8')

if __name__=='__main__':main()
