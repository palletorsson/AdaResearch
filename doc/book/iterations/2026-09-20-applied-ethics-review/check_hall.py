from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='CriticalAlgorithms_Applied_Ethics'
headless='--headless' in sys.argv
camera={'from':[6.5,2.55,2.6],'look_at':[6.5,1.05,5.5],'fov':68}
spec={'required':'room_shape_demonstrator','shots':[
 dict(camera,tag='ethics-head',plan='head',palette='neutral'),
 dict(camera,tag='ethics-circle',plan='circle',palette='neutral'),
 dict(camera,tag='ethics-pair-neutral',plan='pair',palette='neutral'),
 dict(camera,tag='ethics-pair-colour',plan='pair',palette='authored'),
 dict(camera,tag='ethics-watch',plan='panopticon',palette='neutral'),
 dict(camera,tag='ethics-vacant',plan='vacant',palette='neutral')],
 'walks':[
 {'tag':'entry','from':[6.5,.1,.7],'to':[6.5,.1,3.65],'seconds':3},
 {'tag':'controls','from':[6.5,.1,3.65],'to':[6.5,.1,3.8],'seconds':2},
 {'tag':'east approach','from':[6.5,.1,3.8],'to':[9.0,.1,3.8],'seconds':3},
 {'tag':'around all model widths','from':[9.0,.1,3.8],'to':[9.0,.1,6.4],'seconds':3},
 {'tag':'behind models','from':[9.0,.1,6.4],'to':[4.5,.1,6.4],'seconds':4},
 {'tag':'towards lower gallery','from':[4.5,.1,6.4],'to':[4.5,.1,9.5],'seconds':4},
 {'tag':'exit approach','from':[4.5,.1,9.5],'to':[6.5,.1,9.5],'seconds':3},
 {'tag':'exit','from':[6.5,.1,9.5],'to':[6.5,.1,11.6],'seconds':3}]}

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
			press_plan(study,str(row.plan))
			press_palette(study,str(row.palette))
			await process_frame
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"plan":study.plan,"palette":study.palette,"chairs":chairs(study).size()})
''')
base=base.replace('var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}', 'var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}\n\t\tvar blockers: Array=[]\n\t\tfor c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})\n\t\tout["blockers"]=blockers')
base+=''' 
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func press_plan(s: Node, value: String) -> void:
	var i: int=["head","circle","pair","panopticon","vacant"].find(value)
	s._panel.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func press_palette(s: Node, value: String) -> void:
	s._panel.find_child("Btn_%d" % (5 if value=="neutral" else 6),true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func chairs(s: Node) -> Array:
	return s.find_children("*","MeshInstance3D",true,false).filter(func(n): return n.has_meta("room_shape_chair"))
func poses(s: Node) -> Array:
	return chairs(s).map(func(n):return n.global_transform)
func shades(s: Node) -> Array:
	var colours: Array=[]
	for c in chairs(s):
		var col: Color=c.material_override.albedo_color
		if not colours.has(col): colours.append(col)
	return colours
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
