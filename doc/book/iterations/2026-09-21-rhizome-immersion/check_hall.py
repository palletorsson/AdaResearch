from pathlib import Path
import json, math, subprocess, sys, shutil

sys.stdout.reconfigure(encoding='utf-8')
H=Path(__file__).resolve().parent
R=H.parents[3]
room='SpeculativeComputation_Rhizome_Network'
points=[[0,0,-14],[-4,0,-8],[4,0,-8],[-8,0,-2],[0,0,-3],[8,0,-2],[-5,0,5],[4,0,5],[0,0,14],[-11,1.3,4],[-9,2.8,11],[-3,3.7,8],[2,3.7,1],[10,3.7,-6],[11,1,-11]]
route=[0,1,4,2,0,1,3,6,7,4,1,3,9,10,11,12,13,14,2,5,7,8]
walks=[]
previous=[15.5,.05,1]
for n in route:
    p=points[n]; target=[15.5+p[0],.05+p[1],18.5+p[2]]
    walks.append(dict(tag=f'passage-{len(walks)}-to-{n}',**{'from':previous,'to':target},seconds=math.ceil(math.dist(previous,target)/2)+2,height_tolerance=.3))
    previous=target
walks.append(dict(tag='museum exit',**{'from':previous,'to':[15.5,.05,35.7]},seconds=4))
spec=dict(walks=walks,shots=[
    dict(tag='museum-outside',**{'from':[29,13,1],'look_at':[15,2,18]},fov=66),
    dict(tag='museum-entry',**{'from':[15.5,1.7,3],'look_at':[15.5,1.6,10]},fov=82),
    dict(tag='museum-junction',**{'from':[15.5,1.7,15.5],'look_at':[19.5,1.7,23.5]},fov=90),
    dict(tag='museum-upper',**{'from':[12.5,5.4,26.5],'look_at':[17.5,5.3,19.5]},fov=78)
])
(H/'museum-spec.json').write_text(json.dumps(spec),encoding='utf-8')
original=R/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(H/'museum-spec.json')]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(R/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
base=base.replace('func run() -> void:', 'func run() -> void:\n\tOS.low_processor_usage_mode = false')
base=base.replace('\tawait physics_frame\n\tvar space :=','''
	var cave: Node3D = nodes.get("rhizome_cave_demo")
	if cave == null or cave.get_node_or_null("InhabitableRhizome") == null:
		failures.append("Inhabitable cave was not placed")
	else:
		var build_start := Time.get_ticks_msec()
		while not cave.get_node("InhabitableRhizome").ready_to_walk and Time.get_ticks_msec()-build_start < 15000:
			await process_frame
		if not cave.get_node("InhabitableRhizome").ready_to_walk: failures.append("Passage geometry did not load")
	await physics_frame
	var space :=''')
base=base.replace('\tfor row in spec.get("walks", []):','\tEngine.time_scale = 4.0\n\tfor row in spec.get("walks", []):')
base=base.replace('\t\twalker.global_position = origin + vec(row["from"])','\t\tif report.walks.is_empty(): walker.global_position = origin + vec(row["from"])')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tEngine.time_scale = 1.0\n\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('no continuous gameplay, headset or learner acceptance.','continuous controlled walk; no headset or learner acceptance.')
(H/'probe_museum.gd').write_text(base,encoding='utf-8')
run=R/'ada_run/encounter_pilot'/room
cmd=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(R),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(H/'museum-engine.log'),'--script','res://'+(H/'probe_museum.gd').relative_to(R).as_posix(),'--','res://'+(run/'spec.json').relative_to(R).as_posix(),'--em-no-costume']
with (H/'museum-process.log').open('w',encoding='utf-8') as f:
    p=subprocess.Popen(cmd,stdout=f,stderr=subprocess.STDOUT,creationflags=subprocess.CREATE_NO_WINDOW)
    try: code=p.wait(timeout=200)
    except subprocess.TimeoutExpired: p.kill();p.wait();code=124
print('Museum exit',code)
if (run/'report.json').exists():
    report=json.loads((run/'report.json').read_text(encoding='utf-8'))
    shutil.copy2(run/'report.json',H/'museum-runtime.json')
    shutil.copy2(run/'source_manifest.json',H/'source-manifest.json')
    for name in report['shots']:
        p=R/name.removeprefix('res://'); shutil.copy2(p,H/p.name)
    print('Failures',report['failures'])
else:
    print((H/'museum-process.log').read_text(encoding='utf-8',errors='replace')[-2500:])
raise SystemExit(code)
