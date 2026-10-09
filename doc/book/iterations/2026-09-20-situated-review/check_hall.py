from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='SpeculativeComputation_Situated_Computation'
headless='--headless' in sys.argv
spec={'required':'situated_readout','shots':[
 {'tag':'situated-nw','station':'NW','address':'footnote'},
 {'tag':'situated-ne','station':'NE','address':'footnote'},
 {'tag':'situated-sw','station':'SW','address':'footnote'},
 {'tag':'situated-se','station':'SE','address':'footnote'},
 {'tag':'situated-covered','station':'SW','address':'erasure'},
 {'tag':'situated-witness','station':'SW','address':'witness'}],
 'walks':[
 {'tag':'entry','from':[5,.1,.7],'to':[5,.1,3.8],'seconds':3},
 {'tag':'NW controls','from':[5,.1,3.8],'to':[3.63,.1,2.5],'seconds':3},
 {'tag':'return from NW','from':[3.63,.1,2.5],'to':[5,.1,4.5],'seconds':3},
 {'tag':'NE controls','from':[5,.1,4.5],'to':[7.5,.1,3.63],'seconds':3},
 {'tag':'return from NE','from':[7.5,.1,3.63],'to':[5,.1,5],'seconds':3},
 {'tag':'SW controls','from':[5,.1,5],'to':[2.5,.1,6.37],'seconds':3},
 {'tag':'return from SW','from':[2.5,.1,6.37],'to':[5,.1,5.5],'seconds':3},
 {'tag':'SE controls','from':[5,.1,5.5],'to':[6.37,.1,7.5],'seconds':3},
 {'tag':'exit approach','from':[6.37,.1,7.5],'to':[5,.1,8.3],'seconds':3},
 {'tag':'exit','from':[5,.1,8.3],'to':[5,.1,9.65],'seconds':3}]}

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
			var station: Node3D=stations[row.station]
			press_address(station,str(row.address))
			await process_frame
			row["from"]=arr(station.to_global(Vector3(.15,1.6,2.0))-origin)
			row["look_at"]=arr(station.to_global(Vector3(.15,1.1,0))-origin)
			row["fov"]=62
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"station":row.station,"address":station.address,"fields":fields(station)})
''')
base=base.replace('var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}', 'var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}\n\t\tvar blockers: Array=[]\n\t\tfor c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})\n\t\tout["blockers"]=blockers')
base+=''' 
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func press_address(s: Node, value: String) -> void:
	var i: int=["footnote","erasure","witness"].find(value)
	s._controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func fields(s: Node) -> Array:
	return [s._subject_label.text,s._verdict_label.text,s._confidence_label.text,s._footer_label.text]
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
