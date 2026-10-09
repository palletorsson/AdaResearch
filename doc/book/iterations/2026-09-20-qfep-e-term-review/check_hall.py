from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_E_Term'
camera={'from':[6.5,1.65,2.1],'look_at':[6.15,1.15,4.5],'fov':65}
spec={'required':'entropy_fan','shots':[
 dict(camera,tag='fan-one',state=1),dict(camera,tag='fan-open',state=2),
 dict(camera,tag='fan-pruned',state=3),dict(camera,tag='fan-reopened',state=2),
 {'tag':'possibility-hall','from':[6.5,1.65,1],'look_at':[6.5,1.25,8],'fov':85,'state':2}],
 'walks':[{'tag':'entrance','from':[6.5,.1,.6],'to':[6.5,.1,2.5],'seconds':3},
 {'tag':'controls','from':[6.5,.1,2.5],'to':[6.5,.1,3.05],'seconds':3},
 {'tag':'right passage','from':[8.5,.1,2.5],'to':[8.5,.1,8],'seconds':6},
 {'tag':'rear passage','from':[6.5,.1,8],'to':[6.5,.1,11],'seconds':4},
 {'tag':'exit','from':[6.5,.1,11],'to':[6.5,.1,13.5],'seconds':3}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition='''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var fan: Node3D = nodes.get("entropy_fan")
	if fan == null:
		push_error("Missing entropy fan")
		quit(1)
		return
	check(report, fan.visitor_control and fan._buttons.size()==4, "Map enables four physical prospect buttons")
	check(report, absf(fan._console.position.y-.95)<.00001 and absf(fan._fan_root.position.y-.65)<.00001, "Controls and raised fan use intended heights")
	for button in fan._buttons:
		var contact: Vector3 = button.get_node("InteractableAreaButton/CollisionShape3D").global_position
		check(report, contact.distance_to(Vector3(6.5,1.1,3.05))<.65, "Each button is within 0.65m of selected standing reach position")
	var external := Node3D.new()
	external.name = "ExternalFrameProbe"
	fan.add_child(external)
	var console_id: int = fan._console.get_instance_id()
	for state in [1,2,3,2]:
		press_state(fan,state)
		var r: Dictionary = fan.possibility_reading()
		var expected: int = 1 if state==1 else (27 if state==3 else 81)
		var leaves := 0
		var caps := 0
		for child in fan._fan_root.get_children():
			if child.has_meta("is_leaf"): leaves+=1
			if child.has_meta("is_closure"): caps+=1
		check(report, r.leaves==expected and leaves==expected, "Built leaves agree with selected prospect "+str(state))
		check(report, caps==(18 if state==3 else 0) and r.closures==caps and r.removed_leaves==(54 if state==3 else 0), "Closures and removed endings are distinct, prospect "+str(state))
		check(report, absf(r.entropy_nats-log(float(expected)))<.00001 and fan._readout.text.contains("Equal leaf weights") and fan._readout.text.contains("nats"), "Count and qualified entropy readout agree, prospect "+str(state))
		fan._process(10.0)
		check(report, fan._leaf_count==expected and fan._fan_root.rotation==Vector3.ZERO, "Selected prospect stays fixed over time "+str(state))
	check(report, fan._console.get_instance_id()==console_id and fan._buttons.size()==4 and external.get_parent()==fan, "Switching preserves emitting controls and external framing")
	press_state(fan,0)
	fan._process(fan.fan_period/4.0)
	check(report, fan.prospect=="breath" and fan._branch_now==2 and fan._leaf_count==16, "Cycle returns to automatic binary branching")
	fan._process(fan.fan_period/4.0)
	check(report, fan._branch_now==3 and fan._leaf_count==81, "Cycle reaches full ternary branching")
	fan._process(fan.fan_period/2.0)
	check(report, fan._branch_now==1 and fan._leaf_count==1, "Cycle returns to one ending")
	fan.apply_grid_config({"emissive":false})
	check(report, not fan.emissive and fan._console.get_instance_id()==console_id and external.get_parent()==fan, "Emission setting does not rebuild controls or external frame")
	press_state(fan,3)
	check(report, fan._leaf_count==27 and not fan.emissive, "Prospect rebuild preserves emission setting")
	fan.apply_grid_config({"emissive":true})
	fan.apply_grid_config({"visitor_control":"off"})
	check(report, fan._console==null and fan._buttons.is_empty() and absf(fan._fan_root.position.y-.16)<.00001, "Disabling removes controls and restores original height")
	fan.apply_grid_config({"visitor_control":"on"})
	check(report, fan._buttons.size()==4 and fan._console!=null and external.get_parent()==fan, "Re-enabling rebuilds one console without harming external frame")
	var plain = load("res://commons/artifacts/entropy_fan/entropy_fan.tscn").instantiate()
	root.add_child(plain)
	check(report, not plain.visitor_control and plain._buttons.is_empty() and plain.prospect=="breath", "Default placements retain automatic cycling without console")
	plain.queue_free()
	external.queue_free()
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tpress_state(fan,int(row.state))\n\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"reading":fan.possibility_reading(),"text":fan._readout.text})')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func press_state(fan: Node, state: int) -> void:
	fan._buttons[state].get_node("InteractableAreaButton").button_pressed.emit(null)
'''
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=130,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-20:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('runtime.json' if f=='report.json' else f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'],'checks',len(data['checks']))
raise SystemExit(code)
