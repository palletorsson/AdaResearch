from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
room='Escher_Impossible'
spec={'required':'escher_staircase','shots':[
 {'tag':'escher-approach','from':[6.5,1.70,0.9],'look_at':[6.5,1.15,3.5],'fov':65},
 {'tag':'escher-return','from':[5.85,1.70,1.75],'look_at':[6.5,1.20,3.6],'fov':62,'form':'none','steps':16},
 {'tag':'escher-drop','from':[5.85,1.70,1.75],'look_at':[6.5,1.20,3.6],'fov':62,'form':'hairline','steps':16},
 {'tag':'escher-gap','from':[5.85,1.70,1.75],'look_at':[6.5,1.20,3.6],'fov':62,'form':'gap','steps':12},
 {'tag':'penrose-aligned','from':[3.5,1.6,6.25],'look_at':[3.5,1.88867,7.5],'fov':60},
 {'tag':'penrose-aside','from':[2.95,1.6,6.25],'look_at':[3.5,1.88867,7.5],'fov':60}],
 'walks':[{'tag':'approach study','from':[6.5,.1,.5],'to':[6.5,.1,2.1],'seconds':4},
          {'tag':'pass study on left','from':[4.5,.1,1.5],'to':[4.5,.1,5.5],'seconds':5},
          {'tag':'viewpoint approach','from':[3.5,.1,4.5],'to':[3.5,.1,6.25],'seconds':4},
          {'tag':'rear connection','from':[4.5,.1,10.5],'to':[7.5,.1,10.5],'seconds':5},
          {'tag':'exit approach','from':[6.5,.1,10.5],'to':[6.5,.1,12.5],'seconds':4}]}
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','foundationscrisis','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
needle='\tawait physics_frame\n\tvar space :='
addition='\n\tif not nodes.has(spec.required): failures.append("Missing primary " + str(spec.required))\n\treport["required_present"] = nodes.has(spec.required)\n'
base=base.replace(needle,addition+needle)
# The collision-test walker is not the capture camera's body. Hide its costume
# for photographs only, after the unchanged movement checks.
base=base.replace('\tif DisplayServer.get_name() != \"headless\":', '\tif is_instance_valid(walker): walker.hide()\n\treport[\"capture_note\"] = \"Collision-test walker hidden during photographs; museum artifacts unchanged.\"\n\tif DisplayServer.get_name() != \"headless\":')
state='\n\t\t\tvar specimen: Node = nodes.get(spec.required)\n\t\t\tif row.has("form") and specimen != null:\n\t\t\t\tspecimen.apply_grid_config({"seam":row.form})\n\t\t\t\tspecimen.reset()\n\t\t\t\tspecimen._study.reset_measurements()\n\t\t\t\tfor i in int(row.steps): specimen._study.get_node("STEP/InteractableAreaButton").button_pressed.emit(null)\n\t\t\t\treport.get_or_add("study_states",[]).append({"form":row.form,"display":specimen._study.screen.text,"up":specimen._study.ascent,"down":specimen._study.descent})\n'
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):'+state)
base=base.replace('walker.move_and_slide()', 'walker.move_and_slide()\n\t\t\tif walker.get_slide_collision_count() > 0:\n\t\t\t\tfor ci in walker.get_slide_collision_count():\n\t\t\t\t\tvar hit := walker.get_slide_collision(ci)\n\t\t\t\t\tif absf(hit.get_normal().y) < 0.5: report.get_or_add("blocking_colliders",{})[str(hit.get_collider().get_path())] = {"position":arr(hit.get_position()-origin),"normal":arr(hit.get_normal())}')
probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix(),'--em-no-costume']
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=130,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-20:]));raise SystemExit(code or 1)
for f in ['report.json','source_manifest.json']:shutil.copy2(run/f,HERE/(room+'-'+('runtime.json' if f=='report.json' else f)))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room,'exit',code,'failures',data['failures'])
for art in data['artifacts']:
 if art['token']==spec['required']:print(json.dumps(art,ensure_ascii=True))
raise SystemExit(code)
