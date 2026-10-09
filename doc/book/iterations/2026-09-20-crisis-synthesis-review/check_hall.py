from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='Crisis_Synthesis'
spec={'required':'qfep_formula_3d','shots':[
 {'tag':'synthesis-formula-f','from':[9.5,1.65,2.0],'look_at':[9.5,1.5,5.5],'fov':70,'term':'F','weights':[0.15,-0.7]},
 {'tag':'synthesis-formula-phi','from':[9.5,1.65,2.0],'look_at':[9.5,1.5,5.5],'fov':70,'term':'phi','weights':[0.8,0.8]},
 {'tag':'synthesis-period-two','from':[4.0,1.65,6.3],'look_at':[4.5,1.6,10.5],'fov':67,'r':3.2},
 {'tag':'synthesis-period-three','from':[4.0,1.65,6.3],'look_at':[4.5,1.6,10.5],'fov':67,'r':3.83},
 {'tag':'synthesis-atrium','from':[13.5,1.65,11.8],'look_at':[13.5,1.2,14.5],'fov':76},
 {'tag':'synthesis-returns','from':[9.5,1.65,17.8],'look_at':[9.5,1.3,21.5],'fov':98}],
 'walks':[{'tag':'entry to controls','from':[9.5,.1,.8],'to':[9.5,.1,3.8],'seconds':4},
 {'tag':'formula approach','from':[9.5,.1,3.8],'to':[9.5,.1,4.8],'seconds':3},
 {'tag':'logistic control approach','from':[2.85,.1,7.7],'to':[2.85,.1,9.7],'seconds':3},
 {'tag':'atrium threshold','from':[13.5,.1,10],'to':[13.5,.1,12.8],'seconds':4},
 {'tag':'main aisle','from':[9.5,.1,7],'to':[9.5,.1,19],'seconds':9},
 {'tag':'exit approach','from':[10,.1,19.5],'to':[10,.1,23.5],'seconds':4}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','foundationscrisis','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition='''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var formula: Node3D = nodes.get("qfep_formula_3d")
	var logistic: Node3D = nodes.get("bifurcation_diagram")
	var study: Node3D = formula.get_node_or_null("ReadingStudy")
	if study == null or logistic == null:
		push_error("Missing reading apparatus")
		quit(1)
		return
	check(report, study.lambda_control == nodes.get("lambda_slider") and study.phi_control == nodes.get("phi_slider"), "Only this hall's two sliders are bound")
	check(report, formula.reading_study and logistic.visitor_control, "Map config enables both studies")
	for term in ["F","lambda","phi"]:
		study.get_node("Read_"+term+"/InteractableAreaButton").button_pressed.emit(null)
		check(report, formula.highlighted_term == term and study._label.text.contains(study.EXPLANATIONS[term]), "Physical button selects "+term)
	for weights in [[0.15,-0.7],[0.8,0.8]]:
		set_weights(study, weights)
		check(report, absf(study._lambda-weights[0]) < .0001 and absf(study._phi-weights[1]) < .0001, "XR slider signals update formula reading "+str(weights))
	check(report, logistic._control_slider != null, "Independent r control exists")
	for sample in [[2.9,1],[3.2,2],[3.5,4],[3.83,3],[3.7,0],[4.0,1]]:
		set_logistic(logistic, sample[0])
		check(report, absf(logistic.current_r-sample[0]) < .00001, "Physical slider signal sets r="+str(sample[0]))
		check(report, logistic.selected_samples.size() == 128 and logistic.sampled_period(logistic.selected_samples) == sample[1], "Finite orbit sample at r="+str(sample[0])+" has expected short repeat "+str(sample[1]))
	var held_r: float = logistic.current_r
	set_weights(study, [0.4,0.3])
	check(report, logistic.current_r == held_r, "Formula weights do not secretly drive r")
	var old_study: Node3D = study
	formula.apply_grid_config({"reading_study":"on"})
	logistic.apply_grid_config({"visitor_control":"on"})
	check(report, formula.get_node("ReadingStudy") == old_study and logistic.get_node("RControl") == logistic._r_control, "Repeated config does not duplicate controls")
	check(report, nodes.get("goedel_atrium").room_size == 6.0, "Atrium fits its six metre bay")
	check(report, nodes.get("florensky_sphere").hold_both, "Returning sphere keeps both readings")
	check(report, nodes.has("russell_paradox_workbench") and nodes.has("russell_set_box") and nodes.has("godel_statement_plaque") and nodes.has("escher_staircase"), "Existing comparison works retained")
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\treport["capture_note"] = "Collision-test walker hidden for photographs."\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tif row.has("weights"): set_weights(study, row.weights)\n\t\t\tif row.has("term"): study.get_node("Read_"+row.term+"/InteractableAreaButton").button_pressed.emit(null)\n\t\t\tif row.has("r"): set_logistic(logistic, float(row.r))\n\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"formula":study._label.text,"logistic":logistic._sample_label.text})')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func set_weights(study: Node, values: Array) -> void:
	study.lambda_control._slider.slider_moved.emit(float(values[0])*study.lambda_control.rail_length)
	study.phi_control._slider.slider_moved.emit((float(values[1])+1.0)*0.5*study.phi_control.rail_length)

func set_logistic(logistic: Node, value: float) -> void:
	logistic._control_slider.set_normalized_value((value-logistic.r_min)/(logistic.r_max-logistic.r_min))
	logistic._control_slider.slider_moved.emit(0.0)
'''
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=130,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-35:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('runtime.json' if f=='report.json' else f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'],'checks',len(data['checks']))
raise SystemExit(code)

