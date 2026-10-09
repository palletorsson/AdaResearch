from pathlib import Path
import json, subprocess, sys, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
room = sys.argv[1]
targets = {
 'SwarmIntelligence_Ant_Colony_Optimization': ('AntColonyV2', {'from':[3,4,2], 'look_at':[8.5,.2,8.5], 'fov':78}, [1.6,.1,3], [1.6,.1,14]),
 'SwarmIntelligence_Swarm_Intelligence_Algorithms': ('ecosystem_simulation', {'from':[7,2.3,3.5], 'look_at':[6.5,1.3,6.5], 'fov':70}, [2,.1,3], [2,.1,10]),
 'SwarmIntelligence_Particle_Swarm_Optimization': ('fitness_landscape_politics', {'from':[4.5,2.6,2.0], 'look_at':[4.8,.55,4.8], 'fov':85}, [8,.1,4.5], [7.2,.1,4.5]),
 'SwarmIntelligence_Agent_Based_Modeling_ABM': ('ant_colony_optimization', {'from':[4.5,2.15,2.3], 'look_at':[4.5,2.0,4.5], 'fov':88}, [4.5,.1,2], [4.5,.1,3.1]),
}
token, shot, start, end = targets[room]
spec = {'required': token, 'shots':[dict(shot,tag=room)], 'walks':[]}
if start: spec['walks']=[{'tag':'gallery approach and passage','from':start,'to':end,'seconds':8}]
if 'Particle' in room:
 spec['shots']=[dict(shot, tag='pso-converge', objective=0), dict(shot, tag='pso-novelty', objective=2)]
path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','swarmintelligence','--spec',str(path)]
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
base=base.replace('\t\tfor row in spec.get("shots", []):','''\t\tfor row in spec.get("shots", []):
\t\t\tif row.has("objective"):
\t\t\t\tvar specimen: Node = nodes.get("fitness_landscape_politics")
\t\t\t\tif specimen != null:
\t\t\t\t\tspecimen.set_process(false)
\t\t\t\t\tspecimen._switch_landscape(int(row.objective))
\t\t\t\t\tspecimen._init_swarm()
\t\t\t\t\tfor tick in 180: specimen._update_swarm(1.0 / 60.0)
\t\t\t\t\tspecimen._color_terrain()
\t\t\t\t\tspecimen._update_multimesh()
\t\t\t\t\tspecimen._update_landscape_label()
''')
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
