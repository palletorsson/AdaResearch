"""Capture the live QFEP hall in private output folders; never replace its live bake."""
from pathlib import Path
import hashlib, json, shutil, subprocess, sys

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
review = ROOT / 'doc/book/iterations/2026-09-20-qfep-f-term-review'
spec = json.loads((review/'QFEP_F_Term-spec.json').read_text())
spec['shots'] = [
    {'tag':'approach','from':[4.5,1.65,2.6],'look_at':[4.2,1.6,5.25],'fov':64,'p':.9,'prediction':0},
    {'tag':'controls','from':[4.5,1.65,3.2],'look_at':[4.5,1.00,4.45],'fov':42,'p':.9,'prediction':1},
]
(HERE/'spec.json').write_text(json.dumps(spec),encoding='utf-8')
sys.argv = [str(tool),'QFEP_F_Term','--sequence','qfeplaboratory','--spec',str(HERE/'spec.json')]
exec(compile(prepare,str(tool),'exec'),{'__name__':'__main__','__file__':str(tool)})
if variant == 'after':
    # Other review work can refresh the shared plan during this task. Pin the
    # comparison to the first capture's plan without touching the live museum.
    pinned = HERE / 'before/runtime/plan.json'
    shutil.copy2(pinned, run / 'plan.json')
    manifest_path = run / 'source_manifest.json'
    manifest = json.loads(manifest_path.read_text(encoding='utf-8'))
    manifest['sources'].pop('ada_run/em_plan.json', None)
    manifest['sources'][pinned.relative_to(ROOT).as_posix()] = hashlib.sha256(pinned.read_bytes()).hexdigest()
    manifest['scope'] += ' Comparison plan pinned to the before capture.'
    manifest_path.write_text(json.dumps(manifest, indent=2), encoding='utf-8')
probe = (review/'probe_QFEP_F_Term.gd').read_text(encoding='utf-8')
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
