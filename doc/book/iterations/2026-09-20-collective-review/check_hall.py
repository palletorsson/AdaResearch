from pathlib import Path
import json, subprocess, sys, shutil, time
sys.stdout.reconfigure(encoding='utf-8')
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; room='SpeculativeComputation_Collective_Knowledge'
headless='--headless' in sys.argv
spec={'required':'peer_production_tool','shots':[{'tag':'collective-order','mode':'order'},{'tag':'collective-sources','mode':'sources'},{'tag':'collective-dispute','mode':'dispute'},{'tag':'collective-revision','mode':'revision'},{'tag':'collective-side','mode':'side'},{'tag':'collective-version','mode':'version'}],
'walks':[
{'tag':'entry left of pier','from':[6,.1,.7],'to':[5,.1,2.4],'seconds':3},
{'tag':'workbench controls','from':[5,.1,2.4],'to':[6.5,.1,3.8],'seconds':3},
{'tag':'left side','from':[6.5,.1,3.8],'to':[4.25,.1,4.3],'seconds':3},
{'tag':'along table','from':[4.25,.1,4.3],'to':[4.25,.1,6.4],'seconds':3},
{'tag':'beyond pier','from':[4.25,.1,6.4],'to':[5.4,.1,8.2],'seconds':3},
{'tag':'exit approach','from':[5.4,.1,8.2],'to':[6.5,.1,10.4],'seconds':3},
{'tag':'exit','from':[6.5,.1,10.4],'to':[6.5,.1,12.65],'seconds':3}]}

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
			prepare_view(study,str(row.mode))
			await process_frame
			row["from"]=arr(study.to_global(Vector3(0,1.7,3.5))-origin)
			row["look_at"]=arr(study.to_global(Vector3(0,1.35,0))-origin)
			row["fov"]=64
			if row.mode=="side":
				row["from"]=arr(study.to_global(Vector3(2.5,1.7,2.6))-origin)
			report.get_or_add("captured_states",[]).append({"shot":row.tag,"counts":counts(study),"selected":study._selected,"record":str(study._records[study._selected]) if study._selected>=0 else "empty","readout":study._readout.text,"detail":study._detail.text})
''')
base=base.replace('var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}', 'var out := {"tag":row["tag"],"passed":passed,"end":arr(walker.global_position-origin),"target":row["to"]}\n\t\tvar blockers: Array=[]\n\t\tfor c in range(walker.get_slide_collision_count()): blockers.append({"path":str(walker.get_slide_collision(c).get_collider().get_path()),"position":arr(walker.get_slide_collision(c).get_position()),"normal":arr(walker.get_slide_collision(c).get_normal()),"shape":walker.get_slide_collision(c).get_collider_shape()})\n\t\tout["blockers"]=blockers')
base+=''' 
func check(report: Dictionary, ok: bool, message: String) -> void:
	(report.checks as Array).append({"ok":ok,"message":message})
	if not ok: failures.append(message)
func press(s: Node, i: int) -> void:
	s._controls.find_child("Btn_%d" % i,true,false).get_node("InteractableAreaButton").button_pressed.emit(null)
func counts(s: Node) -> Array:
	return [s._placed,s._edits,s._version_sources,s._ever_seen.size(),s._contributors,s._revisions,s._version]
func seed_study(s: Node) -> void:
	s.apply_grid_config({"interactive":true,"add_period":.7})
	s._paused=true
	for i in range(40): s._place_facet([0,1,0,2,3,0,4,5][i%8])
	s._selected=30
	s._refresh_marks()
	s._update_readout()
func prepare_view(s: Node, mode: String) -> void:
	if mode=="order": seed_study(s)
	if mode=="sources": press(s,1)
	if mode=="dispute": press(s,3)
	if mode=="revision": press(s,4)
	if mode=="version":
		press(s,5)
		for peer in [0,0,1]: s._place_facet(peer)
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
