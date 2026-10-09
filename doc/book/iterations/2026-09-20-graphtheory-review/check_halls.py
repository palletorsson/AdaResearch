from pathlib import Path
import json, subprocess, sys, shutil

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
room = sys.argv[1]
targets = {
 'GT_Matching': ('edmonds_algorithm', {'from':[7.5,2.7,4.1], 'look_at':[7.5,1.0,9.5], 'fov':65}, [7.5,.1,3.5], [7.5,.1,6.4]),
 'GT_Spanning_Trees': ('mst_visualization', {'from':[8,2.1,4], 'look_at':[8.3,2.05,9.5], 'fov':65}, [2,.1,2], [2,.1,14]),
 'GT_Flow': ('push_relabel_algorithm', {'from':[6.6,2.3,6], 'look_at':[4.5,1.2,4.5], 'fov':75}, [6.5,.1,1.5], [6.5,.1,5]),
}
token, shot, start, end = targets[room]
spec = {'required': token, 'shots':[dict(shot,tag=room)], 'walks':[{'tag':'approach or perimeter','from':start,'to':end,'seconds':9}]}
if room == 'GT_Matching':
 spec['shots']=[dict(shot,tag='matching-cycle-first',spokes=False),dict(shot,tag='matching-spokes-first',spokes=True)]
 spec['walks'].append({'tag':'pass beside graph','from':[3,.1,5],'to':[3,.1,14],'seconds':8})

path=HERE/(room+'-spec.json');path.write_text(json.dumps(spec),encoding='utf-8')
original=ROOT/'tools/run_encounter_probe.py'
prepare=original.read_text(encoding='utf-8').split('    engine = os.environ')[0]+"    return 0\n\nif __name__ == '__main__':\n    main()\n"
sys.argv=[str(original),room,'--sequence','graphtheory','--spec',str(path)]
exec(compile(prepare,str(original),'exec'),{'__name__':'__main__','__file__':str(original)})
base=(ROOT/'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
needle='\tawait physics_frame\n\tvar space :='
addition='\n\tif not nodes.has(spec.required): failures.append("Missing primary " + str(spec.required))\n\treport["required_present"] = nodes.has(spec.required)\n'
addition+='''
	var graph: Node3D = nodes.get(spec.required)
	var spheres: Array = []
	if spec.required == "mst_visualization": spheres = graph.vertex_meshes
	if spec.required == "push_relabel_algorithm": spheres = graph.node_spheres.values()
	var lowest: float = INF
	for sphere in spheres:
		lowest = minf(lowest, sphere.global_position.y - origin.y - sphere.mesh.radius * sphere.global_basis.get_scale().y)
	if not spheres.is_empty():
		report["lowest_vertex_bottom"] = lowest
		if lowest < 0.1: failures.append("Graph vertices too close to or below floor")
'''
base=base.replace(needle,addition+needle)
state = '''
			if row.has("spokes"):
				var specimen: Node = nodes.get("edmonds_algorithm")
				if specimen != null:
					specimen.set_process(false)
					specimen._spokes_first = bool(row.spokes)
					specimen._lesson_reset()
					for tick in specimen.edges.size() + 1: specimen._lesson_step()
					report.get_or_add("matching_states", []).append({"spokes_first":row.spokes,"pairs":specimen.matching_size,"vertices":specimen.vertices.size(),"edges":specimen.edges.size()})
'''
base=base.replace('\t\tfor row in spec.get("shots", []):', '\t\tfor row in spec.get("shots", []):'+state)

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
