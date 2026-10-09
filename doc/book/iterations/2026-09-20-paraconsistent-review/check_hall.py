from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='SpeculativeComputation_Paraconsistent_Engineering'
headless='--headless' in sys.argv
camera={'from':[4.5,1.7,1.7],'look_at':[4.5,1.0,4.5],'fov':65}
spec={'required':'merge_conflict_visualizer','shots':[
 dict(camera,tag='merge-junction',merge='junction',marker=True),
 dict(camera,tag='merge-overlap',merge='overlap',marker=False),
 dict(camera,tag='merge-resolved',merge='resolved',marker=False),
 dict(camera,tag='merge-fork',merge='fork',marker=True),
 dict(camera,tag='merge-overlap-lit',merge='overlap',marker=True),
 {'from':[5.9,1.6,3.6],'look_at':[4.5,1.1,4.5],'fov':65,'tag':'merge-side','merge':'overlap','marker':False}],
 'walks':[
 {'tag':'arrival','from':[6.5,.1,.7],'to':[6.5,.1,1.8],'seconds':2},
 {'tag':'study approach','from':[6.5,.1,1.8],'to':[4.5,.1,2.8],'seconds':3},
 {'tag':'controls','from':[4.5,.1,2.8],'to':[4.5,.1,3.0],'seconds':2},
 {'tag':'east view','from':[4.5,.1,3.0],'to':[5.9,.1,3.0],'seconds':3},
 {'tag':'around branches','from':[5.9,.1,3.0],'to':[5.9,.1,5.3],'seconds':3},
 {'tag':'behind study','from':[5.9,.1,5.3],'to':[3.8,.1,5.3],'seconds':3},
]}

path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition=(HERE/'probe_checks.gd.txt').read_text(encoding='utf-8')
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','''
		for row in spec.get("shots", []):
			press_merge(study,str(row.merge))
			study.apply_grid_config({"marker_visible":bool(row.marker)})
			await process_frame
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"merge":study.merge,"marker":study.marker_visible,"branches":branches(study).size()})
''')
base=base.replace('var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}', 'var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}\n\t\tvar blockers: Array=[]\n\t\tfor c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})\n\t\tout["blockers"]=blockers')
base=base.replace('\tfor row in spec.get("walks", []):', '\tvar exit_route: Array=exit_path(hall,origin)\n\tcheck(report,not exit_route.is_empty(),"A body-sized route reaches the exit")\n\tfor i in range(exit_route.size()-1):\n\t\tspec.walks.append({"tag":"exit segment %d" % i,"from":arr(exit_route[i]),"to":arr(exit_route[i+1]),"seconds":1.0})\n\tfor row in spec.get("walks", []):')
base+=(HERE/'exit_path.gd.txt').read_text(encoding='utf-8')
base+=''' 
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func press_merge(s: Node, value: String) -> void:
	var i: int=["junction","overlap","resolved","fork"].find(value)
	s._panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func branches(s: Node) -> Array:
	return s.find_children("*","MeshInstance3D",true,false).filter(func(n): return n.has_meta("merge_branch"))
func branch_poses(s: Node) -> Array:
	return branches(s).map(func(n):return n.global_transform)
'''
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off',*(['--headless'] if headless else ['--no-window','--rendering-method','mobile']),'--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
began=time.monotonic()
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
(HERE/'process-result.json').write_text(json.dumps({'exit':code,'elapsed_seconds':round(time.monotonic()-began,2)}),encoding='utf-8')
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-20:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('runtime.json' if f=='report.json' else f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'],'checks',len(data['checks']))
raise SystemExit(code)
