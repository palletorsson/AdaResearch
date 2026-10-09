from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
room='Florensky_Paraconsistent'
spec={'required':'both_true_gate','shots':[
 {'tag':'florensky-both','from':[5.8,1.65,1.8],'look_at':[6.1,1.4,4.5],'fov':75,'reports':[True,True]},
 {'tag':'florensky-open','from':[5.8,1.65,1.8],'look_at':[6.1,1.4,4.5],'fov':75,'reports':[True,False]},
 {'tag':'florensky-console','from':[4.85,1.6,2.45],'look_at':[4.85,1.32,3.85],'fov':56,'reports':[True,True]},
 {'tag':'florensky-sphere','from':[6.5,1.65,6.6],'look_at':[6.5,1.48,8.5],'fov':58},
 {'tag':'florensky-comparisons','from':[6.5,1.65,9.6],'look_at':[6.5,1.15,12.5],'fov':95}],
 'walks':[{'tag':'through threshold with both reports','from':[6.5,.1,2.0],'to':[6.5,.1,6.0],'seconds':4,'reports':[True,True]},
          {'tag':'through threshold with closed report','from':[6.5,.1,2.0],'to':[6.5,.1,6.0],'seconds':4,'reports':[False,True]},
          {'tag':'console approach','from':[4.85,.1,1.5],'to':[4.85,.1,3.0],'seconds':3},
          {'tag':'aisle beside sphere','from':[5.2,.1,6.0],'to':[5.2,.1,13.5],'seconds':6},
          {'tag':'rear comparisons','from':[3.5,.1,11.2],'to':[9.5,.1,11.2],'seconds':5},
          {'tag':'exit approach','from':[6.5,.1,12.5],'to':[6.5,.1,15.5],'seconds':4}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','foundationscrisis','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition='''
	report["required_present"] = nodes.has(spec.required)
	if not nodes.has(spec.required): failures.append("Missing primary " + str(spec.required))
	report["checks"] = []
	var gate: Node3D = nodes.get("both_true_gate")
	var sphere: Node3D = nodes.get("florensky_sphere")
	if gate == null or sphere == null:
		push_error("Missing report gate or sphere")
		quit(1)
		return
	check(report, gate.report_controls, "Museum token enables the report controls")
	check(report, gate.report_state() == {"P":true,"not_P":true,"Q":false}, "Initial conflicting reports supply no Q")
	for combination in [[false,false],[true,false],[true,true],[false,true]]:
		set_reports(gate, combination)
		var state: Dictionary = gate.report_state()
		check(report, state.P == combination[0] and state.not_P == combination[1], "Physical button signals select " + str(combination))
		check(report, not state.Q and gate._report_readout.text.contains("NO SUPPORT"), "Q has no support in " + str(combination))
		check(report, gate._leaf_open.visible == combination[0] and gate._leaf_shut.visible == combination[1], "Ghost leaves follow reports " + str(combination))
	check(report, gate.get_node("FrameCollision").get_child_count() == 3, "Only two jambs and lintel supply frame collision")
	check(report, gate._leaf_open.find_children("*", "CollisionShape3D", true, false).is_empty() and gate._leaf_shut.find_children("*", "CollisionShape3D", true, false).is_empty(), "Reports do not obstruct the body")
	check(report, absf(gate._leaf_open.scale.x * gate.FRAME_W - 1.716) < .001 and absf(gate._leaf_open.scale.y * gate.FRAME_H - 2.392) < .001, "Opening is 1.716 m wide and 2.392 m high")
	var foreign := Node3D.new(); foreign.name = "ExternalLabelOwner"; gate.add_child(foreign)
	var original_emissive: bool = gate.emissive
	gate.apply_grid_config({"report_controls":"on", "emissive":not gate.emissive})
	check(report, is_instance_valid(foreign) and foreign.get_parent() == gate, "Configuration rebuild preserves external children")
	gate.apply_grid_config({"report_controls":"on", "emissive":original_emissive})
	await process_frame
	await process_frame
	set_reports(gate, [true,true])
	check(report, gate.report_state().P and gate.report_state().not_P, "Rebuilt controls remain connected")
	check(report, sphere.hold_both, "Museum token holds both sphere readings")
	sphere.observe(); sphere.cycle_state(); sphere.set_state(0); sphere._process(10.0)
	check(report, sphere.current_state == 2 and not sphere._is_observed, "Observation and cycle cannot collapse the held study")
	check(report, sphere._state_text == "A AND not-A", "Sphere label does not alternate BOTH and NEITHER")
	check(report, sphere._sphere.material_override.cull_mode == BaseMaterial3D.CULL_DISABLED, "Sphere renders both faces of the mesh")
	check(report, nodes.has("schrodinger_box") and nodes.has("superposition_display"), "Both secondary quantum comparisons retained")
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tfor row in spec.get("walks", []):','\tfor row in spec.get("walks", []):\n\t\tif row.has("reports"): set_reports(gate, row.reports)')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\treport["capture_note"] = "Collision-test walker hidden for photographs; museum artifacts unchanged."\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tif row.has("reports"):\n\t\t\t\tset_reports(gate, row.reports)\n\t\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"reports":gate.report_state(),"caption":gate._report_readout.text})')
base+='''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func set_reports(gate: Node, values: Array) -> void:
	gate.get_node("ClearReports/InteractableAreaButton").button_pressed.emit(null)
	if values[0]: gate.get_node("ReportOpen/InteractableAreaButton").button_pressed.emit(null)
	if values[1]: gate.get_node("ReportClosed/InteractableAreaButton").button_pressed.emit(null)
'''
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=130,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-25:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('runtime.json' if f=='report.json' else f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'],'checks',len(data['checks']))
raise SystemExit(code)
