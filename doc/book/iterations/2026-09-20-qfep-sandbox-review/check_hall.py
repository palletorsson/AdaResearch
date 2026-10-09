from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='QFEP_Sandbox'
headless='--headless' in sys.argv
# This section is combined with the existing private museum harness.
camera={'from':[7.2,2.0,3.6],'look_at':[7.4,1.35,8.4],'fov':68}
spec={'required':'qfep_reactor','shots':[
 dict(camera,tag='sandbox-cut',connected=False,l=.85,p=.7),
 dict(camera,tag='sandbox-connected',connected=True,l=.85,p=.7),
 dict(camera,tag='sandbox-held',connected=False,l=.15,p=-.7),
 dict(camera,tag='sandbox-reconnected',connected=True,l=.15,p=-.7),
 {'tag':'sandbox-controls','from':[7.5,1.5,4.95],'look_at':[7.5,1.05,6.1],'fov':65,'connected':True,'l':.15,'p':-.7},
 {'tag':'sandbox-gallery','from':[10.6,2.0,2.6],'look_at':[6.7,1.25,9.0],'fov':88,'connected':True,'l':.15,'p':-.7}],
 'walks':[{'tag':'entry','from':[7.5,.1,.6],'to':[7.5,.1,3.5],'seconds':3},
 {'tag':'lambda approach','from':[5.5,.1,3.5],'to':[5.5,.1,4.9],'seconds':2},
 {'tag':'phi approach','from':[8.25,.1,3.5],'to':[8.25,.1,4.9],'seconds':2},
 {'tag':'connection switch','from':[7.5,.1,3.5],'to':[7.5,.1,5.5],'seconds':3},
 {'tag':'past the experiment','from':[10.0,.1,4.5],'to':[10.0,.1,12.8],'seconds':6},
 {'tag':'south circulation','from':[10.0,.1,13.5],'to':[7.5,.1,13.5],'seconds':3},
 {'tag':'exit','from':[7.5,.1,13.5],'to':[7.5,.1,15.6],'seconds':3}]}

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
			if study.connected: study.toggle_connection()
			move_handles(l,p,float(row.l),float(row.p))
			if bool(row.connected): study.toggle_connection()
			study.repeat_response()
			reactor._process(.3)
			study._refresh()
			report.get_or_add("captured_states", []).append({"shot":row.tag,"connected":study.connected,"offered_lambda":l.lambda,"offered_phi":p.phi,"used_lambda":reactor.current_lambda,"used_phi":reactor.current_phi,"max_speed":reactor.particle_system.process_material.initial_velocity_max})
''')
base+=r'''
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func move_handles(l: Node, p: Node, a: float, b: float) -> void:
	l._slider.slider_moved.emit(a*l.rail_length)
	p._slider.slider_moved.emit((b+1)*.5*p.rail_length)
func press(study: Node, index: int) -> void:
	study.buttons[index].get_node("InteractableAreaButton").button_pressed.emit(null)
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
