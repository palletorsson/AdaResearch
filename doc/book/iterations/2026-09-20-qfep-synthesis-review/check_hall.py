from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_Synthesis'
headless='--headless' in sys.argv
camera={'from':[3.5,1.65,1.7],'look_at':[3.5,1.50,3.5],'fov':50}
spec={'required':'queer_morphology_specimen','shots':[
 dict(camera,tag='synthesis-stiff',l=.1,p=.8,pulse=False),
 dict(camera,tag='synthesis-soft',l=.8,p=-.8,pulse=False),
 dict(camera,tag='synthesis-pulse',l=.5,p=0,pulse=True),
 dict(camera,tag='synthesis-steady',l=.5,p=0,pulse=False),
 {'tag':'synthesis-controls','from':[3.25,1.8,2.05],'look_at':[3.25,1.53,3.5],'fov':72,'l':.5,'p':0,'pulse':False},
 {'tag':'synthesis-gallery','from':[7.5,2.1,1.5],'look_at':[4.5,1.2,6.5],'fov':90,'l':.5,'p':0,'pulse':False}],
 'walks':[{'tag':'entry','from':[7.5,.1,.6],'to':[7.5,.1,2.5],'seconds':3},
 {'tag':'specimen approach','from':[7.5,.1,2.5],'to':[3.5,.1,2.5],'seconds':4},
 {'tag':'return to circulation','from':[3.5,.1,2.5],'to':[10.5,.1,2.5],'seconds':5},
 {'tag':'east passage','from':[10.5,.1,2.5],'to':[10.5,.1,11.5],'seconds':6},
 {'tag':'south passage','from':[10.5,.1,11.5],'to':[6.5,.1,11.5],'seconds':3},
 {'tag':'exit','from':[6.5,.1,11.5],'to':[6.5,.1,13.6],'seconds':3}]}

path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','qfeplaboratory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition=(HERE/'probe_checks.gd.txt').read_text(encoding='utf-8')
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):',r'''
		for row in spec.get("shots", []):
			move_handles(specimen,float(row.l),float(row.p))
			specimen.breathing_enabled=bool(row.pulse)
			specimen._breathing_time=PI/(2.0*lerpf(.5,2.0,specimen.lambda))
			specimen._update_pressure()
			specimen._update_state_label()
			for settle in range(120): await physics_frame
			var bounds_min := Vector3(INF,INF,INF)
			var bounds_max := Vector3(-INF,-INF,-INF)
			for point_index in range(specimen._soft_body.mesh.surface_get_array_len(0)):
				var point: Vector3=specimen.to_local(specimen._soft_body.get_point_transform(point_index))
				bounds_min=bounds_min.min(point)
				bounds_max=bounds_max.max(point)
			report.get_or_add("body_bounds",[]).append({"shot":row.tag,"min":arr(bounds_min),"max":arr(bounds_max)})
			check(report,bounds_min.is_finite() and bounds_max.is_finite() and bounds_min.y>=-.01 and bounds_max.y<=specimen.jar_height+.01 and maxf(absf(bounds_min.x),absf(bounds_max.x))<specimen.jar_radius+.01 and maxf(absf(bounds_min.z),absf(bounds_max.z))<specimen.jar_radius+.01,"Deformable mesh stays inside container at %s" % row.tag)
			report.get_or_add("captured_states", []).append({"shot":row.tag,"lambda":specimen.lambda,"phi":specimen.phi,"baseline":specimen._pressure_baseline,"pressure":specimen._soft_body.pressure_coefficient,"stiffness":specimen._soft_body.linear_stiffness,"damping":specimen._soft_body.damping_coefficient,"drag":specimen._soft_body.drag_coefficient,"pulse":specimen.breathing_enabled})
''')
base+=r'''
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func move_handles(s: Node, l: float, p: float) -> void:
	s._lambda_slider.set_normalized_value(l)
	s._lambda_slider.slider_moved.emit(0.0)
	s._phi_slider.set_normalized_value((p+1)*.5)
	s._phi_slider.slider_moved.emit(0.0)
func press(s: Node, index: int) -> void:
	s._control_panel.find_child("Btn_%d" % index,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
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
