from pathlib import Path
import json, subprocess, sys, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
room = sys.argv[1]
targets = {
 'ML_Classification': ('enhanced_kmeans', {'from':[7.5,3.0,1.1], 'look_at':[7.5,.4,4.8], 'fov':85}, [7.5,.1,1.0], [7.5,.1,1.3]),
 'ML_Gradient_Landscape': ('loss_function_comparator', {'from':[7.5,1.9,9.65], 'look_at':[6.5,1.1,8.5], 'fov':75}, [7.5,.1,10], [7.5,.1,8.5]),
 'ML_Sequence_Memory': ('lstms_vr', {'from':[6,2.0,3.0], 'look_at':[9.5,1.5,7.5], 'fov':85}, [2,.1,3], [2,.1,20]),
 'ML_Generative': ('generative_adversarial_networks_gans_vr', {'from':[9.5,3.0,4.0], 'look_at':[9.5,1.3,11.5], 'fov':90}, [2,.1,2], [2,.1,18]),
}
token, shot, start, end = targets[room]
spec = {'required': token, 'shots':[dict(shot,tag=room)], 'walks':[]}
if start: spec['walks']=[{'tag':'gallery approach and passage','from':start,'to':end,'seconds':10}]
if room == 'ML_Classification':
 spec['walks'].append({'tag':'pass beside the control stand','from':[5.5,.1,1.5],'to':[5.5,.1,6.5],'seconds':5})
 spec['shots']=[dict(shot,tag='kmeans-blobs',cohort='blobs'),dict(shot,tag='kmeans-rings',cohort='rings'),dict(shot,tag='kmeans-block',cohort='block')]

path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','machinelearning','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
needle='\tawait physics_frame\n\tvar space :='
addition='''
\tif not nodes.has(spec.required): failures.append("Missing primary " + str(spec.required))
\treport["required_present"] = nodes.has(spec.required)
\tif nodes.has("ecosystem_simulation"):
\t\tvar records: Array = []
\t\tfor label in nodes.ecosystem_simulation.find_children("*", "Label3D", true, false):
\t\t\tif label.text.begins_with("POPULATION SUPPORT"): records.append(label.text)
\t\treport["care_records"] = records
\t\tif records.is_empty(): failures.append("No visible care record")
'''
base=base.replace(needle,addition+needle)
base=base.replace('\t\tfor row in spec.get("shots", []):', '\t\tfor row in spec.get("shots", []):\n\t\t\tif row.has("cohort"):\n\t\t\t\tvar specimen: Node = nodes.get("enhanced_kmeans")\n\t\t\t\tif specimen != null:\n\t\t\t\t\tspecimen.set_process(false)\n\t\t\t\t\tspecimen.cohort = str(row.cohort)\n\t\t\t\t\tspecimen._lesson_reset()\n\t\t\t\t\tfor tick in 8: specimen._lesson_step()\n')

probe=HERE/('probe_'+room+'.gd');probe.write_text(base,encoding='utf-8')
run=ROOT/'ada_run/encounter_pilot'/room
command=['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off','--no-window','--rendering-method','mobile','--audio-driver','Dummy','--log-file',str(HERE/(room+'-engine.log')),'--script','res://'+probe.relative_to(ROOT).as_posix(),'--','res://'+(run/'spec.json').relative_to(ROOT).as_posix()]
with (HERE/(room+'-process.log')).open('w',encoding='utf-8') as log:
 try: code=subprocess.run(command,stdout=log,stderr=subprocess.STDOUT,timeout=130,creationflags=subprocess.CREATE_NO_WINDOW).returncode
 except subprocess.TimeoutExpired: code=124
if not (run/'report.json').exists():
 print('No report',room,code);print('\n'.join((HERE/(room+'-process.log')).read_text(encoding='utf-8',errors='replace').splitlines()[-20:]));raise SystemExit(code or 1)
shutil.copy2(run/'report.json',HERE/(room+'-runtime.json'))
data=json.loads((run/'report.json').read_text(encoding='utf-8'))
for p in data['shots']:
 src=ROOT/p.removeprefix('res://');shutil.copy2(src,HERE/src.name)
print(room, 'exit',code,'failures',data['failures'])
for art in data['artifacts']:
 if art['token']==token: print(json.dumps(art,ensure_ascii=True))
raise SystemExit(code)
