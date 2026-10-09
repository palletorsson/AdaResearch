from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3];room='QFEP_Introduction'
spec={'required':'qfep_balance_workbench','shots':[
 {'tag':'balance-kept-a','from':[6.5,1.65,2.5],'look_at':[6.5,1.28,4.65],'fov':63,'values':[.4,.2,.5,.5],'keep':True},
 {'tag':'balance-current-b','from':[6.5,1.65,2.5],'look_at':[6.5,1.28,4.65],'fov':63,'values':[.6,.6,.5,.5]},
 {'tag':'balance-zero-low','from':[6.5,1.65,2.5],'look_at':[6.5,1.28,4.65],'fov':63,'values':[.4,.1,0,.5],'keep':True},
 {'tag':'balance-zero-high','from':[6.5,1.65,2.5],'look_at':[6.5,1.28,4.65],'fov':63,'values':[.4,.9,0,.5]},
 {'tag':'balance-hall','from':[6.5,1.65,.8],'look_at':[6.5,1.5,7.5],'fov':86}],
 'walks':[{'tag':'entrance to workbench','from':[6.5,.1,.7],'to':[6.5,.1,3.7],'seconds':4},
 {'tag':'left edge of control row','from':[4.7,.1,2.7],'to':[5.5,.1,3.7],'seconds':3},
 {'tag':'right passage','from':[8,.1,3],'to':[8,.1,9],'seconds':6},
 {'tag':'formula approach','from':[6.5,.1,6.3],'to':[6.5,.1,7.5],'seconds':3},
 {'tag':'exit','from':[6.5,.1,9.5],'to':[6.5,.1,11.5],'seconds':3}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition='''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var bench: Node3D = nodes.get("qfep_balance_workbench")
	if bench == null:
		push_error("Missing balance workbench")
		quit(1)
		return
	check(report, bench.comparison and bench._keep_button != null, "Map enables KEEP comparison")
	check(report, bench._sliders.size() == 4, "Four independently readable controls")
	for values in [[0.4,0.2,0.5,0.5],[0.6,0.6,0.5,0.5],[0,0,0,0],[1,1,1,1],[0,1,1,0]]:
		set_knobs(bench,values)
		var expected: float = values[0]-values[2]*values[1]+values[3]*0.3
		check(report, absf(bench._qfe-expected)<.00001, "Control polling computes "+str(values))
	set_knobs(bench,[.4,.2,.5,.5])
	bench._keep_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, absf(bench._kept_qfe-.45)<.00001 and bench._kept_outline.visible, "Physical KEEP button retains total and outline")
	var held: Array = bench._kept.duplicate()
	set_knobs(bench,[.6,.6,.5,.5])
	check(report, bench._kept == held and absf(bench._qfe-bench._kept_qfe)<.00001, "Different tuple reaches same total without replacing kept tuple")
	check(report, absf(bench._F-bench._kept[0])>.1 and absf(bench._E-bench._kept[1])>.3, "Equal total conceals distinct F and E values")
	set_knobs(bench,[.4,.1,0,.5]); var first: float = bench._qfe
	set_knobs(bench,[.4,.9,0,.5])
	check(report, absf(bench._qfe-first)<.00001, "E has no effect on total when lambda is zero")
	set_knobs(bench,[.4,.1,.5,.5]); first = bench._qfe
	set_knobs(bench,[.4,.9,.5,.5])
	check(report, absf((bench._qfe-first)+.4)<.00001, "Restoring lambda restores E contribution")
	check(report, bench._readout_lines.has("Nearest project reference:") and bench._phase_screen.title == "PROJECT REFERENCE", "Both reference readouts name authored comparison")
	check(report, bench._readout_lines.has("All four controls: 0 to 1") and bench._readout_lines.has("Delta E = 0.30 (fixed, not measured)"), "Domains and constant are explicit on instrument")
	bench._sliders[3].set_normalized_value(1.0); bench._process(.2)
	check(report, absf(bench._phi-1.0)<.00001, "Workbench phi remains normalised 0 to 1")
	var external := Node3D.new(); external.name = "ExternalLabels"; bench.add_child(external)
	bench.apply_grid_config({"settling":"order","comparison":"on"})
	check(report, is_instance_valid(external) and external.get_parent()==bench, "Configuration rebuild preserves external children")
	check(report, bench._kept == held and bench._kept_outline.visible, "Retained reading survives rebuild")
	bench._keep_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, absf(bench._kept[0]-bench._F)<.00001, "KEEP remains connected after rebuild")
	bench.apply_grid_config({"comparison":"off"})
	check(report, bench._keep_button == null and bench._kept_outline == null, "Default mode omits optional comparison")
	bench.apply_grid_config({"comparison":"on","settling":"edge"})
	check(report, bench._keep_button != null and bench._sliders.size()==4, "Comparison can be re-enabled without duplicate sliders")
	check(report, nodes.has("lambda_slider") and nodes.has("phi_slider") and nodes.has("qfep_formula_3d"), "Secondary formula and rails retained")
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\treport["capture_note"] = "Collision-test walker hidden for photographs."\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tif row.has("values"): set_knobs(bench, row["values"])\n\t\t\tif row.get("keep", false): bench._keep_button.get_node("InteractableAreaButton").button_pressed.emit(null)\n\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"values":[bench._F,bench._E,bench._lambda,bench._phi],"qfe":bench._qfe,"kept":bench._kept.duplicate(),"kept_qfe":bench._kept_qfe,"readout":bench._readout_lines.duplicate()})')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func set_knobs(bench: Node, values: Array) -> void:
	for i in 4: bench._sliders[i].set_normalized_value(float(values[i]))
	bench._process(0.25)
'''
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=130,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-30:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('runtime.json' if f=='report.json' else f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'],'checks',len(data['checks']))
raise SystemExit(code)

