from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
room=sys.argv[1]
if room=='Russell_Paradox':
 spec={'required':'russell_paradox_workbench','shots':[
  {'tag':'russell-approach','from':[6.5,1.7,0.9],'look_at':[6.5,1.2,4.0],'fov':70},
  {'tag':'russell-unrestricted','from':[6.05,1.65,1.85],'look_at':[6.05,1.34,3.5],'fov':58,'cell':4,'answer':True},
  {'tag':'russell-restricted','from':[6.05,1.65,1.85],'look_at':[6.05,1.34,3.5],'fov':58,'cell':5,'answer':False}],
  'rays':[{'tag':'side obstruction','x':5.5,'z':2.1}, {'tag':'left edge','x':5.15,'z':2.2}, {'tag':'right edge','x':5.8,'z':2.2},{'tag':'centre obstruction','x':6.5,'z':9.15}],
  'walks':[{'tag':'approach membership buttons','from':[6.5,.1,.5],'to':[6.5,.1,2.7],'seconds':5},
           {'tag':'side of workbench','from':[5.8,.1,1.5],'to':[5.8,.1,3.5],'seconds':4},
           {'tag':'centre passage through ring','from':[6.5,.1,7.3],'to':[6.5,.1,10.3],'seconds':5}]}
else:
 spec={'required':'godel_sentence_machine','shots':[
  {'tag':'godel-illustration','from':[6.5,1.70,10.6],'look_at':[6.5,1.0,8.5],'fov':62},
  {'tag':'godel-sorter','from':[8.5,1.70,7.2],'look_at':[8.5,1.0,5.5],'fov':65}], 'walks':[]}
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
state='\n\t\t\tvar specimen: Node = nodes.get(spec.required)\n\t\t\tif row.has("cell") and specimen != null:\n\t\t\t\tspecimen._slider.set_normalized_value(float(row.cell)/5.0)\n\t\t\t\tspecimen._slider.slider_moved.emit(float(row.cell)/5.0)\n\t\t\t\tspecimen._process(0.2)\n\t\t\t\tspecimen._test_membership(bool(row.answer))\n\t\t\t\tfor i in 30: await process_frame\n\t\t\t\treport.get_or_add("membership_states",[]).append({"cell":row.cell,"display":specimen._readout_verdict.text,"result":specimen._last_result})\n'
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
