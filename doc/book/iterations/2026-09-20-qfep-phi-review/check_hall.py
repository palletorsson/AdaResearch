from pathlib import Path
import json, subprocess, sys, shutil, time
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_Phi_Term'
headless='--headless' in sys.argv
camera={'from':[6.25,1.65,2.9],'look_at':[6.25,1.35,4.5],'fov':65}
spec={'required':'phi_slider','shots':[
 dict(camera,tag='phi-negative',phi=-.7,reveal=False),
 dict(camera,tag='phi-positive',phi=.7,reveal=False),
 dict(camera,tag='phi-earlier-labels',phi=.7,reveal=True),
 {'tag':'phi-pattern','from':[8.5,1.7,5.9],'look_at':[8.5,1.05,7.5],'fov':65,'phi':0,'reveal':False},
 {'tag':'phi-gallery','from':[6.5,1.8,1],'look_at':[6.5,1.1,8],'fov':85,'phi':0,'reveal':False}],
 'walks':[{'tag':'entry','from':[6.5,.1,.6],'to':[6.5,.1,2.5],'seconds':3},
 {'tag':'rail approach','from':[6.25,.1,2.5],'to':[6.25,.1,3.5],'seconds':2},
 {'tag':'beside rail','from':[5,.1,2.5],'to':[5,.1,6],'seconds':5},
 {'tag':'pattern approach','from':[8.5,.1,5],'to':[8.5,.1,6.5],'seconds':2},
 {'tag':'side circulation','from':[10.5,.1,5],'to':[10.5,.1,10.3],'seconds':7},
 {'tag':'exit','from':[6.5,.1,10.3],'to':[6.5,.1,11.6],'seconds':2}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition=r'''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var study: Node3D = nodes.get("phi_slider")
	var pattern: Node3D = nodes.get("transforming_pattern")
	if study == null or pattern == null:
		push_error("Missing Phi study or independent pattern")
		quit(1)
		return
	check(report, study.sign_study and study._reading_button != null, "Hall enables sign study and reading button")
	check(report, not study.is_in_group("qfep_phi_controllers"), "Study stays outside global PHI aggregation")
	check(report, study._scale_labels[0].text=="NEGATIVE" and study._scale_labels[1].text=="ZERO" and study._scale_labels[2].text=="POSITIVE", "Signed marks arrive before interpretation")
	check(report, not study._labels_revealed and not study._interpretation.text.contains("EMBRACE"), "Earlier interpretation initially hidden")
	pattern.set_process(false)
	pattern._time=2.0
	pattern._process(0.0)
	var original_pattern: Array = pattern_snapshot(pattern)
	var control_id: int = study._study.get_instance_id()
	for value in [-.7,0.0,.7,-.2,.2]:
		move_phi(study,value)
		var pm: ParticleProcessMaterial = study._particles.process_material
		check(report, absf(study.phi-value)<.00001 and study._label.text.contains("%.2f" % value), "XR rail sets signed value "+str(value))
		check(report, pm.direction==Vector3.UP*signf(value) and is_equal_approx(pm.initial_velocity_max,absf(value)*.2) and pm.gravity==Vector3.ZERO, "Symmetric directional feedback at "+str(value))
		check(report, study._particles.emitting != is_zero_approx(value), "Only nonzero weights emit new particles at "+str(value))
		check(report, pattern_snapshot(pattern)==original_pattern, "PHI leaves independent pattern unchanged at "+str(value))
	check(report, study._particles.position.y - .2 * study._particles.lifetime - .05 > -.05, "Full downward trail stays above plinth at maximum magnitude")
	study._reading_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, study._labels_revealed and study._interpretation.text.contains("EARLIER PROJECT READING") and study._interpretation.text.contains("EMBRACE"), "Button reveals attributed earlier interpretation")
	check(report, is_equal_approx(study.phi,.2) and pattern_snapshot(pattern)==original_pattern, "Reading button changes neither parameter nor pattern")
	study._reading_button.get_node("InteractableAreaButton").button_pressed.emit(null)
	check(report, not study._labels_revealed, "Second press hides interpretation")
	study.apply_grid_config({"sign_study":"on"})
	check(report, control_id==study._study.get_instance_id(), "Repeated config preserves live controls")
	move_phi(study,0)
	pattern._process(1.0)
	check(report, pattern_snapshot(pattern)!=original_pattern and pattern._time>2.0, "Pattern keeps moving while PHI is zero")
	pattern._time=2.0
	move_phi(study,-.7)
	pattern._process(1.0)
	var negative_pattern: Array = pattern_snapshot(pattern)
	pattern._time=2.0
	move_phi(study,.7)
	pattern._process(1.0)
	check(report, pattern_snapshot(pattern)==negative_pattern, "Same wave step has identical result under opposite PHI weights")
	var reach := origin+Vector3(6.25,1.1,3.9)
	check(report, study._handle.global_position.distance_to(reach)<.7 and study._reading_button.global_position.distance_to(reach)<.7, "Handle and reading button within selected 0.7m standing reach")
	check(report, is_equal_approx(study.global_position.y-origin.y,1.1), "Rail mounted at 1.1m")
	var plain = load("res://commons/interfaces/qfep/phi_slider.tscn").instantiate()
	root.add_child(plain)
	check(report, not plain.sign_study and plain._study==null and plain._scale_labels[0].text=="RESIST" and plain.is_in_group("qfep_phi_controllers"), "Legacy placement retains original labels and group")
	plain.apply_grid_config({"sign_study":"on"})
	check(report, plain.sign_study and not plain.is_in_group("qfep_phi_controllers"), "Late opt-in removes global registration")
	plain.apply_grid_config({"sign_study":"off"})
	check(report, plain._study==null and plain.is_in_group("qfep_phi_controllers") and plain._scale_labels[0].text=="RESIST", "Opt-out restores original controls without freeing external nodes")
	plain.queue_free()
	pattern._time=2.0
	pattern._process(0.0)
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):\n\t\t\tmove_phi(study,float(row.phi))\n\t\t\tstudy._labels_revealed=bool(row.reveal)\n\t\t\tstudy._update_reading()\n\t\t\tstudy._particles.restart()\n\t\t\tawait create_timer(2.1).timeout\n\t\t\treport.get_or_add("captured_states", []).append({"shot":row.tag,"phi":study.phi,"revealed":study._labels_revealed,"pattern_time":pattern._time})')
base+=r'''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func move_phi(study: Node, value: float) -> void:
	study._slider.slider_moved.emit((value+1.0)*0.5*study.rail_length)

func pattern_snapshot(pattern: Node) -> Array:
	var result: Array = []
	for i in range(pattern._cells.size()):
		result.append([pattern._cells[i].transform,pattern._materials[i].albedo_color,pattern._materials[i].emission,pattern._materials[i].emission_energy_multiplier])
	return result
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
