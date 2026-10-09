from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='CriticalAlgorithms_Algorithmic_Bias_Visualization'
headless='--headless' in sys.argv
camera={'from':[4.5,2.6,3.2],'look_at':[4.5,1.25,6.5],'fov':86}
close={'from':[4.5,1.65,4.7],'look_at':[4.5,1.25,6.3],'fov':70}
spec={'required':'bias_from_inside','shots':[
 dict(camera,tag='bias-arrangement-a',blend=0,reading=False),
 dict(camera,tag='bias-arrangement-b',blend=1,reading=False),
 dict(close,tag='bias-close-a',blend=0,reading=False),
 dict(close,tag='bias-close-b',blend=1,reading=False),
 {'tag':'bias-reading','from':[4,1.8,4.7],'look_at':[4.1,1.35,6.2],'fov':76,'blend':.5,'reading':True},
 {'tag':'bias-gallery','from':[8.5,2.3,8.7],'look_at':[4.5,1.2,5.7],'fov':86,'blend':1,'reading':False}],
 'walks':[{'tag':'entry','from':[5.5,.1,.6],'to':[5.5,.1,2.5],'seconds':3},
 {'tag':'past cabinet and bench','from':[5.5,.1,2.5],'to':[5.5,.1,4.85],'seconds':3},
 {'tag':'control approach','from':[5.5,.1,4.85],'to':[4.5,.1,4.85],'seconds':2},
 {'tag':'leave control','from':[4.5,.1,4.85],'to':[2,.1,5.3],'seconds':3},
 {'tag':'circulate round study','from':[2,.1,5.3],'to':[2,.1,9.2],'seconds':3},
 {'tag':'south passage','from':[2,.1,9.2],'to':[6.5,.1,9.2],'seconds':4},
 {'tag':'exit','from':[6.5,.1,9.2],'to':[6.5,.1,10.6],'seconds':3}]}


path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','postfoundationscrisis','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
addition=(HERE/'probe_checks.gd.txt').read_text(encoding='utf-8')
base=base.replace('\tawait physics_frame\n\tvar space :=',addition+'\tawait physics_frame\n\tvar space :=')
base=base.replace('\tif DisplayServer.get_name() != "headless":','\tif is_instance_valid(walker): walker.hide()\n\tif DisplayServer.get_name() != "headless":')
base=base.replace('\t\tfor row in spec.get("shots", []):','''
		for row in spec.get("shots", []):
			move_handle(study,float(row.blend))
			study._reading.visible=bool(row.reading)
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"blend":study._perspective_blend,"warm_distance":pair_distance(study._marginalized_multimesh),"grey_distance":pair_distance(study._default_multimesh),"reading":study._reading.visible})
''')
base=base.replace('var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}', 'var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}\n\t\tvar blockers: Array=[]\n\t\tfor c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})\n\t\tout["blockers"]=blockers')
base+=''' 
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func move_handle(s: Node, value: float) -> void:
	s._slider.set_normalized_value(value)
	s._slider.slider_moved.emit(s._slider.get_node("SliderOrigin/InteractableSlider").slider_position)
func pair_distance(mm: MultiMeshInstance3D) -> float:
	return mm.multimesh.get_instance_transform(0).origin.distance_to(mm.multimesh.get_instance_transform(1).origin)
func read_button(s: Node) -> void:
	s._controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
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
