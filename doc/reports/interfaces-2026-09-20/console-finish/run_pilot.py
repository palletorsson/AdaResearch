"""Capture the live QFEP hall in private output folders; never replace its live bake."""
from pathlib import Path
import json, subprocess, sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
variant = sys.argv[1]
assert variant in ('before', 'after')
run = HERE / variant / 'runtime'
run.mkdir(parents=True, exist_ok=True)
tool = ROOT / 'tools/run_encounter_probe.py'
prepare = tool.read_text(encoding='utf-8').split('    engine = os.environ')[0]
prepare = prepare.replace("run = ROOT / 'ada_run/encounter_pilot' / args.room", 'run = Path(' + repr(str(run)) + ')')
prepare += "    return 0\n\nif __name__ == '__main__':\n    main()\n"
review = ROOT / 'doc/book/iterations/2026-09-20-qfep-introduction-review'
spec = json.loads((review/'QFEP_Introduction-spec.json').read_text())
spec['shots'] = [
    {'tag':'approach','from':[6.5,1.65,2.5],'look_at':[6.5,1.28,4.65],'fov':63,'values':[.4,.2,.5,.5],'keep':True},
    {'tag':'controls','from':[6.5,1.65,3.2],'look_at':[6.5,.95,4.5],'fov':42,'values':[.6,.6,.5,.5]},
]
(HERE/'spec.json').write_text(json.dumps(spec),encoding='utf-8')
sys.argv = [str(tool),'QFEP_Introduction','--sequence','qfeplaboratory','--spec',str(HERE/'spec.json')]
exec(compile(prepare,str(tool),'exec'),{'__name__':'__main__','__file__':str(tool)})
probe = (review/'probe_QFEP_Introduction.gd').read_text(encoding='utf-8')
insert = '''
	for frame in 8: await process_frame
	var panel: Node3D = bench._plate_root.panel()
	var plate: MeshInstance3D = panel.get_node("Tilt/Chrome/BackPanel")
	report["console"] = {"panel_scale": arr(panel.scale), "plate_size": arr(plate.mesh.size), "controls": []}
	for item in panel._items:
		var control: Node3D = item.node
		report.console.controls.append({"label":item.label,"scale":arr(control.global_basis.get_scale()),"centre":arr(control.global_position-origin)})
	report["console"]["head_size"] = arr(bench._plate_root.get_node("Body/Head").size)
'''
anchor = '\tawait physics_frame\n\tvar space :='
assert anchor in probe
probe = probe.replace(anchor,insert + anchor)
(HERE/'capture_console.gd').write_text(probe,encoding='utf-8')
prefix = 'res://' + run.relative_to(ROOT).as_posix() + '/'
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--resolution','1800x1200','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(run/'engine.log'),'--script','res://'+(HERE/'capture_console.gd').relative_to(ROOT).as_posix(),'--',prefix+'spec.json','--em-no-costume']
with (run/'process.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(cmd,stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
print('Godot exit',result.returncode)
if (run/'report.json').exists():
    report=json.loads((run/'report.json').read_text(encoding='utf-8'))
    print(json.dumps({k:report.get(k) for k in ('failures','checks','console','shots')},ensure_ascii=True))
else:
    print((run/'process.log').read_text(encoding='utf-8',errors='replace')[-4000:])
raise SystemExit(result.returncode)
