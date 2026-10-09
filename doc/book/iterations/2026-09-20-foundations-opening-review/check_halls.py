from pathlib import Path
import json, subprocess, sys, shutil
HERE=Path(__file__).resolve().parent
ROOT=HERE.parents[3]
room=sys.argv[1]
if room=='Euclid_Parallel':
 spec={'required':'euclid_postulates_plaque','shots':[
  {'tag':'euclid-colonnade','from':[5.5,2.0,3.7],'look_at':[5.5,1.5,9.0],'fov':68},
  {'tag':'euclid-fifth','from':[5.5,1.75,5.7],'look_at':[5.5,1.60,7.5],'fov':62,'fifth':True}],
  'walks':[{'tag':'approach plaque','from':[5.5,.1,1.5],'to':[5.5,.1,5.9],'seconds':6},
           {'tag':'pass beside plaque','from':[4.5,.1,6.5],'to':[4.5,.1,12.5],'seconds':7}]}
else:
 spec={'required':'triangle_curvature_workbench','shots':[
  {'tag':'curvature-'+model,'from':[11.5,1.70,1.05],'look_at':[11.5,1.22,3.05],'fov':62,'model':model}
  for model in ['plane','sphere','disk']],
  'walks':[{'tag':'entrance to bench','from':[8.5,.1,1.5],'to':[11.5,.1,1.5],'seconds':6}]}
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
state='''
			var specimen: Node = nodes.get(spec.required)
			if row.has("model") and specimen != null:
				specimen.apply_grid_config({"model":row.model})
				report.get_or_add("model_states",[]).append({"model":row.model,"display":specimen._plate_readout.text})
			if row.get("fifth",false) and specimen != null:
				specimen.current_postulate=4
'''
base=base.replace('\t\tfor row in spec.get("shots", []):','\t\tfor row in spec.get("shots", []):'+state)
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
