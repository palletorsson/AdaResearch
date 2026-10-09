from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_Edge_Of_Chaos'
headless='--headless' in sys.argv
camera={'from':[11.7,1.85,6.5],'look_at':[13.5,1.65,6.5],'fov':80}
spec={'required':'edge_of_chaos_unlocked','shots':[
 dict(camera,tag='edge-dt-coarse',dt=.3,seed=0),
 dict(camera,tag='edge-dt-finer',dt=.15,seed=0),
 dict(camera,tag='edge-new-seed',dt=.15,seed=1),
 {'tag':'edge-controls','from':[11.65,1.45,6.5],'look_at':[12.9,.96,6.5],'fov':70,'dt':.3,'seed':0},
 {'tag':'edge-secondary-pattern','from':[6.5,1.6,.8],'look_at':[6.5,1.2,2.5],'fov':65,'dt':.3,'seed':0},
 {'tag':'edge-gallery','from':[12.0,2.2,12.5],'look_at':[10.0,1.3,6.5],'fov':95,'dt':.3,'seed':0}],
 'walks':[{'tag':'entry','from':[7.5,.1,.6],'to':[7.5,.1,1.5],'seconds':2},
 {'tag':'north circulation','from':[7.5,.1,1.5],'to':[12,.1,1.5],'seconds':4},
 {'tag':'east approach','from':[12,.1,2],'to':[12,.1,4.5],'seconds':3},
 {'tag':'console approach','from':[11.5,.1,6.5],'to':[12,.1,6.5],'seconds':2},
 {'tag':'east circulation','from':[12,.1,8.5],'to':[12,.1,13.5],'seconds':4},
 {'tag':'south circulation','from':[12,.1,13.5],'to':[7.5,.1,13.5],'seconds':4},
 {'tag':'exit','from':[7.5,.1,13.5],'to':[7.5,.1,14.6],'seconds':2}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition=r'''
	report["required_present"] = nodes.has(spec.required)
	report["checks"] = []
	var study: Node3D = nodes.get("edge_of_chaos_unlocked")
	var secondary: Node3D = nodes.get("lambda_slider")
	if study == null or secondary == null:
		push_error("Missing Edge study or secondary slider")
		quit(1)
		return
	study.set_process(false)
	check(report, study.comparison_study and study._fine_display != null and study._dt_labels.size()==2, "Hall enables two independent field textures with step labels")
	check(report, study._study_buttons.size()==4 and study._study_sliders.size()==2, "Four buttons and two full-size sliders present")
	check(report, study._regime_label==null, "Comparison has no unmeasured frozen/edge/chaos classification")
	study.restart()
	var start: PackedFloat32Array = study._grid_b.duplicate()
	var seed_id: int = study.seed_value
	for i in range(10): study._advance_tick()
	press(study,0)
	check(report, study._grid_b==start and study._fine_b==start and study.model_time==0.0 and study.seed_value==seed_id, "RESTART repeats the same initial state in both fields")
	press(study,1)
	check(report, study.seed_value==seed_id+1 and study._grid_b!=start and study._fine_b==study._grid_b and study.model_time==0.0, "NEW SEED changes both starts together")
	var next_start: PackedFloat32Array = study._grid_b.duplicate()
	press(study,2)
	check(report, is_equal_approx(study.time_step,.15) and study._grid_b==next_start and study.model_time==0.0, "DT button selects .15/.075 and restarts current seed")
	press(study,2)
	check(report, is_equal_approx(study.time_step,.3) and study._grid_b==next_start, "Second DT press restores .3/.15")
	press(study,3)
	study._process(1.0)
	check(report, study._paused and study.model_time==0.0, "HOLD button stops model time")
	press(study,3)
	study._process(.1)
	check(report, not study._paused and study.model_time>0, "RUN button resumes integrated time")
	var secondary_value: float = secondary.lambda
	move_slider(study,0,.7)
	check(report, is_equal_approx(study.lambda,.7) and is_equal_approx(study._feed_rate,.059), "Actual LAMBDA slider callback updates coupled coefficients")
	check(report, is_equal_approx(secondary.lambda,secondary_value), "Secondary lambda slider remains independent")
	var saved: PackedFloat32Array = study._grid_b.duplicate()
	var saved_time: float = study.model_time
	move_slider(study,1,1.0)
	check(report, study.sim_steps==8 and study._grid_b==saved and study.model_time==saved_time, "SIM SPEED changes requested rate without changing timestep or instantaneous state")
	var controls_id: int = study._controls.get_instance_id()
	study.apply_grid_config({"comparison_study":"on"})
	check(report, study._controls.get_instance_id()==controls_id, "Repeated config preserves live controls")
	move_slider(study,0,.4)
	study.seed_value=0x5EED17
	study.restart()
	for i in range(200): study._advance_tick()
	study._update_texture()
	check(report, absf(study.model_time-60.0)<.00001 and not study.solver_fault and study.comparison_error()>0, "Paired fields reach equal model duration with measured nonzero difference")
	check(report, study._dt_labels[0].text=="DT 0.300" and study._dt_labels[1].text=="DT 0.150" and study._study_readout.text.contains("t 60.0"), "Visible readings agree with solver state")
	var reach := origin+Vector3(12.1,1.0,6.5)
	report["control_positions"] = []
	for control in study._study_buttons+study._study_sliders:
		var distance: float = control.global_position.distance_to(reach)
		report.control_positions.append({"position":arr(control.global_position-origin),"distance":distance})
		check(report, distance<.7, "Control within selected 0.7m reach: "+str(control.name))
	check(report, absf(study.global_position.y-origin.y)<.01, "Study sits on level floor")
	for tenure_name in ["unlocked", "clamped", "withheld", "frozen", "chaos"]:
		var legacy = load("res://commons/artifacts/edge_of_chaos_unlocked/edge_of_chaos_unlocked.tscn").instantiate()
		legacy.grid_size=16
		legacy.tenure=tenure_name
		legacy.position=Vector3(1000,0,0)
		root.add_child(legacy)
		legacy.set_process(false)
		check(report, not legacy.comparison_study and legacy._fine_display==null and not legacy.solver_fault, "Single-screen tenure builds with common solver: "+tenure_name)
		check(report, absf(legacy.model_time-(192.0 if tenure_name in ["frozen","chaos"] else 0.0))<.00001, "Only pole tenures preroll 192 model units: "+tenure_name)
		legacy.queue_free()
'''
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):',r'''
		for row in spec.get("shots", []):
			study.time_step=float(row.dt)
			study.seed_value=0x5EED17+int(row.seed)
			study.restart()
			for i in range(roundi(60.0/study.time_step)): study._advance_tick()
			study._update_texture()
			report.get_or_add("captured_states", []).append({"shot":row.tag,"lambda":study.lambda,"dt":study.time_step,"seed":study.seed_value,"model_time":study.model_time,"difference":study.comparison_error()})
''')
base+=r'''
func check(report: Dictionary, ok: bool, message: String) -> void:
	report.checks.append({"ok":ok,"message":message})
	if not ok: failures.append(message)

func press(study: Node, i: int) -> void:
	study._study_buttons[i].get_node("InteractableAreaButton").button_pressed.emit(null)

func move_slider(study: Node, i: int, v: float) -> void:
	study._study_sliders[i].set_normalized_value(v)
	study._study_sliders[i].slider_moved.emit(v)
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
