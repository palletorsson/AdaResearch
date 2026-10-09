from pathlib import Path
import json
import shutil
import subprocess
import sys

HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
tag=sys.argv[1] if len(sys.argv)>1 else 'after'
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
spec=HERE/('baseline-spec.json' if tag=='baseline' else 'after-spec.json')
sys.argv=[str(original),'Boolean_Works','--sequence','boolean_surfaces','--spec',str(spec)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
base=base.replace('\tmuseum.set("_player", null)','\tmuseum.set("_player", null)\n\tawait investigate_burrow(nodes, walker, report, origin)')
base+='\n'+(HERE/'burrow_checks.gd').read_text(encoding='utf-8')
probe=HERE/'probe_burrow.gd';probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot/Boolean_Works'
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(tag+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix()]
with (HERE/(tag+'-process.log')).open('w',encoding='utf-8') as log:
    p=subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=140,creationflags=subprocess.CREATE_NO_WINDOW)
if not (run/'report.json').exists(): raise SystemExit(p.returncode or 1)
shutil.copy2(run/'report.json',HERE/(tag+'-runtime.json'))
r=json.loads((run/'report.json').read_text())
for shot in r['shots']:
    src=ROOT/shot.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(json.dumps({'exit':p.returncode,'burrow':r.get('burrow'),'failures':r['failures']}))
raise SystemExit(p.returncode)
