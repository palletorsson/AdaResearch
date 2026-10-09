from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='SpeculativeComputation_Rhizome_Network'
headless='--headless' in sys.argv
spec={'required':'rhizome_grower','shots':[{'tag':'rhizome-'+mode,'mode':mode} for mode in ['one','one-cut','three','three-cut','side','replay']],
'walks':[
{'tag':'entry','from':[6.5,.1,.7],'to':[6.5,.1,2.8],'seconds':3},
{'tag':'controls','from':[6.5,.1,2.8],'to':[5.5,.1,3.9],'seconds':3},
{'tag':'left approach','from':[5.5,.1,3.9],'to':[3.4,.1,4.0],'seconds':3},
{'tag':'along exhibit','from':[3.4,.1,4.0],'to':[3.4,.1,7.9],'seconds':4},
{'tag':'exit approach','from':[3.4,.1,7.9],'to':[6.5,.1,8.4],'seconds':3},
{'tag':'exit throat','from':[6.5,.1,8.4],'to':[6.5,.1,10.5],'seconds':3},
{'tag':'exit','from':[6.5,.1,10.5],'to':[6.5,.1,11.65],'seconds':3}]}

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
			prepare_view(study,str(row.mode))
			await process_frame
			row["from"]=arr(study.to_global(Vector3(0,2.05,3.3))-origin)
			row["look_at"]=arr(study.to_global(Vector3(0,1.2,0))-origin)
			row["fov"]=64
			if row.mode=="side":
				row["from"]=arr(study.to_global(Vector3(2.7,2.1,2.7))-origin)
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"counts":counts(study),"selected":study._selected,"positions":study._positions.map(func(v): return arr(v)),"active":study._active.duplicate(),"degrees":study._degrees.duplicate(),"readout":study._readout.text,"detail":study._detail.text})
''')
base=base.replace('var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}', 'var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}\n\t\tvar blockers: Array=[]\n\t\tfor c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})\n\t\tout["blockers"]=blockers')
base+=''' 
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func press(s: Node, i: int) -> void:
	s._controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func counts(s: Node) -> Array:
	return [s._node_total,s._active.count(true),s._visible_edges,s._components,s.links_per_node]
func seed_study(s: Node) -> void:
	s.apply_grid_config({"interactive":true,"spread":.85,"sample_seed":47,"max_nodes":40,"links_per_node":1})
	s._paused=true
	for i in range(22): s._grow_shoot()
	s._selected=s._degrees.find(s._degrees.max())
	s._refresh_graph()
func prepare_view(s: Node, mode: String) -> void:
	if mode=="one": seed_study(s)
	if mode=="one-cut": press(s,4)
	if mode=="three":
		press(s,4)
		press(s,2)
	if mode=="three-cut": press(s,4)
	if mode=="side": press(s,4)
	if mode=="replay": press(s,5)
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
