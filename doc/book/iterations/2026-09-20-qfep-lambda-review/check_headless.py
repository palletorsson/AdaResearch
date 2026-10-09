from pathlib import Path
import json, subprocess, sys, shutil, time
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_Lambda_Spectrum'
camera={'from':[9.55,1.65,5.0],'look_at':[8.7,1.2,14.0],'fov':92}
spec={'required':'lambda_hall','shots':[
 dict(camera,tag='recommendation-left',recommendation=.2),
 dict(camera,tag='recommendation-right',recommendation=.8),
 dict(camera,tag='recommendation-return',recommendation=.35),
 {'tag':'lambda-console','from':[8.5,1.65,2.0],'look_at':[8.5,1.0,5],'fov':80,'recommendation':.35},
 {'tag':'lambda-gallery','from':[8.5,2.1,1.0],'look_at':[8.5,1.4,13],'fov':90,'recommendation':.35}],
 'walks':[{'tag':'entrance','from':[8.5,.1,.6],'to':[8.5,.1,2.5],'seconds':3},
 {'tag':'console approach','from':[8.5,.1,2.5],'to':[8.5,.1,4.0],'seconds':2},
 {'tag':'study entry','from':[9.55,.1,3],'to':[9.55,.1,6],'seconds':4},
 {'tag':'through original passage','from':[9.55,.1,6],'to':[9.55,.1,17],'seconds':12},
 {'tag':'study departure','from':[9.55,.1,17],'to':[9.55,.1,20],'seconds':4},
 {'tag':'exit','from':[8.5,.1,20],'to':[8.5,.1,23.5],'seconds':4}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition='''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var study: Node3D = nodes.get("lambda_hall")
	if study == null:
		push_error("Missing lambda study")
		quit(1)
		return
	check(report, study.recommendation_control and study._slider!=null and study._reset_button!=null, "Map enables slider and RETURN")
	study.set_process(false)
	var original_spectrum: Dictionary = spectrum_snapshot(study)
	var floor_transform: Transform3D = study.get_node("FloorBody").transform
	var console_id: int = study._console.get_instance_id()
	study.apply_grid_config({"recommendation_control":"on","recommendation_position":.35})
	check(report, study._console.get_instance_id()==console_id, "Repeated configuration does not rebuild the active console")
	var hand_point := origin + Vector3(8.5,1.1,4.0)
	check(report, study._slider.global_position.distance_to(hand_point)<.7 and study._reset_button.global_position.distance_to(hand_point)<.7, "Slider and RETURN are within 0.7m of the selected standing reach point")

	for value in [.2,.35,.8,.6,.2]:
		move_light(study,value)
		check(report, spectrum_snapshot(study)==original_spectrum, "Moving recommendation preserves geometry, colours and instantaneous motion state at "+str(value))
		check(report, absf(study._recommendation.position.x-(value-.5)*study.hall_width)<.00001, "Lit strip reaches requested coordinate "+str(value))
		check(report, study._route_labels[0].text.contains("%.2f" % value) and study._route_readout.text.contains("%.2f" % value), "Both labels and console report selected recommendation "+str(value))
	check(report, study._console.get_instance_id()==console_id and study.get_node("FloorBody").transform==floor_transform, "Moving recommendation preserves floor and live controls")
	study._reset_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, absf(study.recommendation_position-study.lambda_value)<.00001 and spectrum_snapshot(study)==original_spectrum, "RETURN restores authored recommendation without resetting structure")
	study.apply_grid_config({"recommendation_position":-1})
	check(report, absf(study.recommendation_position-.2)<.00001, "Configuration clamps recommendation at low bound")
	study.apply_grid_config({"recommendation_position":2})
	check(report, absf(study.recommendation_position-.8)<.00001, "Configuration clamps recommendation at high bound")
	var old_time: float = study._time
	var drift: Transform3D = study._drifters[0].node.transform
	study._process(1.0)
	check(report, study._time>old_time and study._drifters[0].node.transform!=drift, "Animation continues independently after a recommendation change")
	var now: Dictionary = spectrum_snapshot(study)
	move_light(study,.35)
	check(report, spectrum_snapshot(study)==now, "Moving light does not rewind animated state")
	var plain = load("res://commons/artifacts/lambda_hall/lambda_hall.tscn").instantiate()
	root.add_child(plain)
	check(report, not plain.recommendation_control and plain._console==null, "Default placements have no added console")
	var external := Node3D.new()
	plain.add_child(external)
	plain.apply_grid_config({"lambda":.6})
	check(report, absf(plain._recommendation.position.x-.7)<.00001 and external.get_parent()==plain, "Legacy lambda config retains its route behaviour and external children")
	plain.queue_free()
	check(report, absf(study._console.position.y-.95)<.00001, "Control surface has reachable authored height")
	var positions: Array = []
	for label in study._route_labels: positions.append(label.position)
	check(report, positions.size()==2 and not study._route_labels[0].text.contains("life"), "Route labels explicitly name a suggestion")
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tmove_light(study,float(row.recommendation))\n\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"recommendation":study.recommendation_position,"structure_lambda":study.lambda_value,"time":study._time})')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func move_light(study: Node, value: float) -> void:
	study._slider.set_normalized_value(inverse_lerp(.2,.8,value))
	study._slider.slider_moved.emit(study._slider.get_normalized_value())

func spectrum_snapshot(study: Node) -> Dictionary:
	var state := {}
	for child in study.get_children():
		if child is MultiMeshInstance3D:
			state[child.name] = {"id":child.get_instance_id(),"buffer":child.multimesh.buffer.duplicate(),"transform":child.transform,"emission":child.material_override.emission,"energy":child.material_override.emission_energy_multiplier}
	var drifters: Array = []
	for drift in study._drifters: drifters.append({"id":drift.node.get_instance_id(),"transform":drift.node.transform,"base":drift.base})
	state["drifters"] = drifters
	return state
'''
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--headless','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-headless-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
began=time.monotonic()
with (HERE/(room+'-headless-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=180,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
(HERE/'headless-process-result.json').write_text(json.dumps({'exit':code,'elapsed_seconds':round(time.monotonic()-began,2)}),encoding='utf-8')
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-headless-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-20:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('headless-runtime.json' if f=='report.json' else 'headless-'+f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'],'checks',len(data['checks']))
raise SystemExit(code)
