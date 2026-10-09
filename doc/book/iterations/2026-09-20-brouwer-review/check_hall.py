from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
room='Brouwer_Intuitionism'
spec={'required':'brouwer_choice_sequence','shots':[
 {'tag':'brouwer-empty','from':[6.5,1.65,1.35],'look_at':[6.5,1.18,3.45],'fov':62,'prefix':[]},
 {'tag':'brouwer-chosen','from':[6.5,1.65,1.35],'look_at':[6.5,1.18,3.45],'fov':62,'prefix':[0,1,1,0,1]},
 {'tag':'brouwer-overview','from':[5.35,1.70,4.75],'look_at':[6.5,1.25,10.5],'fov':72},
 {'tag':'cantor-four','from':[9.5,1.65,5.50],'look_at':[9.5,1.25,7.55],'fov':60,'n':4},
 {'tag':'cantor-sixteen','from':[9.5,1.65,5.50],'look_at':[9.5,1.25,7.55],'fov':60,'n':16}],
 'walks':[{'tag':'approach choices','from':[6.5,.1,.5],'to':[6.5,.1,2.25],'seconds':4},
          {'tag':'central passage beside choice bench','from':[5.35,.1,1.5],'to':[5.35,.1,14.4],'seconds':10},
          {'tag':'witness bay','from':[5.35,.1,5.0],'to':[3.5,.1,5.0],'seconds':4},
          {'tag':'Cantor approach','from':[9.5,.1,5.0],'to':[9.5,.1,6.25],'seconds':4},
          {'tag':'exit approach','from':[6.5,.1,12.5],'to':[6.5,.1,14.5],'seconds':4}]}
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
state='\n\t\t\tif row.has("prefix"):\n\t\t\t\tvar choice: Node=nodes.get("brouwer_choice_sequence")\n\t\t\t\tchoice.get_node("ResetChoices/InteractableAreaButton").button_pressed.emit(null)\n\t\t\t\tfor value in row.prefix: choice.get_node("Choose%d/InteractableAreaButton" % int(value)).button_pressed.emit(null)\n\t\t\t\treport.get_or_add("choice_states",[]).append({"terms":choice.terms.duplicate(),"display":choice._choice_status.text})\n\t\t\tif row.has("n"):\n\t\t\t\tvar bench: Node=nodes.get("cantor_diagonal_workbench")\n\t\t\t\tbench._slider.set_normalized_value(bench._normalized_for_n(int(row.n)))\n\t\t\t\tbench._slider.slider_moved.emit(0.0)\n\t\t\t\tbench._process(1.0)\n\t\t\t\treport.get_or_add("diagonal_states",[]).append({"N":bench._n,"d":Array(bench._d),"readout":bench._plate_readout.text})\n'
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
