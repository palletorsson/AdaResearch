from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_F_Term'
camera={'from':[4.5,1.65,2.6],'look_at':[4.2,1.60,5.25],'fov':64}
spec={'required':'shannon_workbench','shots':[
 dict(camera,tag='predict-low-zero',p=.1,prediction=0),
 dict(camera,tag='predict-high-zero',p=.9,prediction=0),
 dict(camera,tag='predict-high-one',p=.9,prediction=1),
 {'tag':'prediction-hall','from':[5.5,1.65,.8],'look_at':[5,1.2,8],'fov':85,'p':.9,'prediction':1}],
 'walks':[{'tag':'entrance','from':[5.5,.1,.6],'to':[5.5,.1,2.5],'seconds':3},
 {'tag':'controls','from':[4.5,.1,2.5],'to':[4.5,.1,3.8],'seconds':3},
 {'tag':'right passage','from':[6.5,.1,2.5],'to':[6.5,.1,7],'seconds':5},
 {'tag':'rear passage','from':[5.5,.1,7],'to':[5.5,.1,9.6],'seconds':3},
 {'tag':'exit','from':[5.5,.1,9.6],'to':[5.5,.1,11.5],'seconds':3}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition='''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var bench: Node3D = nodes.get("shannon_workbench")
	if bench == null:
		push_error("Missing Shannon workbench")
		quit(1)
		return
	check(report, bench.prediction_study and bench._prediction_buttons.size()==2, "Map enables two constant-prediction buttons")
	check(report, bench._draws.size()==256 and bench._error_marks.size()==256, "All 256 cells have error markers")
	var draws: PackedFloat32Array = bench._draws.duplicate()
	for p in [0.0,.1,.5,.9,1.0]:
		set_p(bench,p)
		var ones := 0
		for value in draws:
			if value < p: ones += 1
		for guess in [0,1]:
			press_guess(bench,guess)
			var r: Dictionary = bench.prediction_reading()
			var expected := ones if guess==0 else 256-ones
			var marks := 0
			for mark in bench._error_marks:
				if mark.visible: marks += 1
			check(report, r.observed_errors==expected and marks==expected and absf(r.expected_error-(p if guess==0 else 1.0-p))<.00001, "Expected and observed errors agree with cells, p="+str(p)+" guess="+str(guess))
	check(report, bench._draws==draws, "Changing source threshold and predictor preserves stored draws")
	set_p(bench,.1); press_guess(bench,0)
	var low: Dictionary = bench.prediction_reading()
	set_p(bench,.9)
	var high: Dictionary = bench.prediction_reading()
	check(report, absf(low.source_h-high.source_h)<.00001 and low.observed_errors<high.observed_errors, "Equal source entropy, different predictor fit")
	var colours: Array = []
	for mat in bench._grid_materials: colours.append(mat.albedo_color)
	press_guess(bench,1)
	check(report, bench.prediction_reading().observed_errors==256-high.observed_errors and absf(bench._p-.9)<.00001, "Changing guess complements errors while source stays fixed")
	var unchanged := true
	for i in colours.size(): unchanged = unchanged and colours[i]==bench._grid_materials[i].albedo_color
	check(report, unchanged and bench._draws==draws, "Prediction buttons preserve actual bit colours and draws")
	check(report, absf(bench._binary_entropy(.5)-1)<.00001 and bench._binary_entropy(0)==0 and bench._binary_entropy(1)==0, "Source H has correct peak and endpoints")
	check(report, not bench._plate_readout.text.contains("incompressible") and bench._plate_readout.text.contains("Source H"), "Readout distinguishes source entropy from finite encoding")
	bench.apply_grid_config({"evidence":"none"})
	check(report, bench.prediction_reading().sample_count==0 and bench._prediction_lines.has("Observed: no sample drawn"), "No-sample mode does not invent observed success")
	bench.apply_grid_config({"evidence":"anecdote"})
	check(report, bench._draws.size()==16 and bench._error_marks.size()==16, "Small evidence rebuild keeps prediction markers aligned")
	bench.apply_grid_config({"evidence":"sample","draw_seed":124})
	var actual := 0
	for value in bench._draws:
		if int(value<bench._p)!=bench._prediction: actual += 1
	check(report, bench._observed_errors==actual, "Seed changes refresh observed error readout")
	bench.apply_grid_config({"draw_seed":1234})
	check(report, bench._draws==draws, "Restoring seed restores original evidence")
	bench.apply_grid_config({"prediction_study":"off"})
	check(report, bench._error_marks.is_empty() and not bench._prediction_buttons[0].visible, "Prediction mode can be disabled")
	bench.apply_grid_config({"prediction_study":"on"})
	check(report, bench._error_marks.size()==256 and bench._prediction_buttons.size()==2, "Re-enabling does not duplicate controls")
	var plain = load("res://commons/artifacts/shannon_workbench/shannon_workbench.tscn").instantiate()
	root.add_child(plain)
	check(report, not plain.prediction_study and plain._prediction_buttons.is_empty(), "Other default placements remain single-control workbenches")
	plain.queue_free()
	check(report, nodes.has("snap_octahedron_puzzle") and nodes.has("snap_tetrahedron_puzzle") and nodes.has("crystal_cluster"), "Other existing comparisons instantiate")
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tset_p(bench,float(row.p))\n\t\t\tpress_guess(bench,int(row.prediction))\n\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"reading":bench.prediction_reading(),"lines":bench._prediction_lines.duplicate()})')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func set_p(bench: Node, p: float) -> void:
	bench._slider.set_normalized_value(p)
	bench._slider.slider_moved.emit(p)
	bench._process(.25)

func press_guess(bench: Node, guess: int) -> void:
	bench._prediction_buttons[guess].get_node("InteractableAreaButton").button_pressed.emit(null)
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
