"""Execute the printed source, and require three deliberate conceptual faults to fail."""
from pathlib import Path
import json, re, subprocess

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-08-wave-propagation-between-points'
ENGINE = 'C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe'

def run(source, name):
    report = OUT/(name+'.json')
    if report.exists(): report.unlink()
    with (OUT/(name+'.log')).open('w',encoding='utf8') as log:
        result = subprocess.run([ENGINE,'--headless','--path',str(ROOT),'--xr-mode','off',
            '--script','res://tools/probes/wavefunctions_neighbours_student.gd','--',
            '--lesson=res://'+source.relative_to(ROOT).as_posix(),
            '--report=res://'+report.relative_to(ROOT).as_posix()],cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=45)
    text=(OUT/(name+'.log')).read_text(encoding='utf8')
    assert 'SCRIPT ERROR' not in text, text[-2500:]
    assert report.exists(),text[-2500:]
    data=json.loads(report.read_text(encoding='utf8'))
    return result.returncode,data

def main():
    tutorial=(ROOT/'commons/maps/WaveFunctions_3D_Wave_Propagation/tutorial.md').read_text(encoding='utf8')
    blocks=dict(re.findall(r'<!-- student-code:([^ ]+) -->\s*```gdscript\n(.*?)\n```',tutorial,re.S))
    dest=OUT/'extracted'; dest.mkdir(exist_ok=True)
    for name,source in blocks.items(): (dest/name).write_text(source+'\n',encoding='utf8')
    original=ROOT/'doc/book/studies/wavefunctions-lineage/05_neighbour_motion.gd'
    assert blocks['05_neighbour_motion.gd']==original.read_text(encoding='utf8').rstrip()
    status,data=run(dest/'05_neighbour_motion.gd','student-test')
    assert status==0 and data['passed'],data['failures']
    print('Printed study:',len(data['checks']),'checks passed')
    mutations={
        'missing-coupling':('coupling * (displacement[j] - displacement[i])', '0.0'),
        'shared-next-state':('.duplicate()', ''),
        'skipped-neighbour':('[i - 1, i + 1]', '[i - 2, i + 2]')
    }
    results=[]
    for name,(before,after) in mutations.items():
        source=blocks['05_neighbour_motion.gd']
        assert before in source
        file=dest/(name+'.gd'); file.write_text(source.replace(before,after)+'\n',encoding='utf8')
        status,data=run(file,name)
        assert status!=0 and not data['passed'],name
        results.append({'fault':name,'rejected':True,'failures':data['failures']})
        print(name,': rejected by',len(data['failures']),'checks')
    (OUT/'mutation-tests.json').write_text(json.dumps(results,indent=2),encoding='utf8')

if __name__=='__main__': main()
