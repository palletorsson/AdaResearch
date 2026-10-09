"""Exercise the restaged cave/maze in a private copy of the live museum."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/PG_Caves_Mazes'
PREFIX = 'res://' + HERE.relative_to(ROOT).as_posix() + '/'
base = (ROOT / 'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
setup = r'''
	var desk: Node3D = nodes.get("pg_workshop_console")
	check(desk != null and desk.ready_for_input, "workshop binds both moved artifacts")
	if desk != null and desk.ready_for_input:
		check(desk.model.grid_size==Vector3i(10,10,10) and is_equal_approx(desk.model.cube_size,1), "cave retains its full-scale ten-cell lesson")
		check(desk.other.maze_width==9 and desk.other.maze_height==9 and is_equal_approx(desk.other.cell_size,1.5), "maze retains its nine-by-nine 1.5 m cells")
		check(desk.works.caverandomwalk.global_position.is_equal_approx(origin+Vector3(19.5,0.5,11.5)), "cave is centered on the entry approach")
		check(desk.works.maze_generation.global_position.is_equal_approx(origin+Vector3(22.5,0,19.5)), "maze is beyond the comparison court")
		check(not desk.trace.visible and not desk.other.generation_complete, "opening has a hidden trace and unfinished maze")
		await press(desk,"TRACE")
		check(desk.trace.visible and desk.trace.multimesh.instance_count==desk.model.carve_history.size(), "TRACE shows a dot for each carving record")
		check(desk.model.is_ancestor_of(desk.trace), "trace follows the relocated cave rather than its old world position")
		await press(desk,"CAVE SEED")
		check(desk.model.seed==1338 and desk.model.carve_history.size()>0, "seed control still regenerates the moved cave")
		# Return to the documented opening seed for clearance and matched captures.
		desk.model.seed=1337
		desk.model.regenerate()
		await process_frame
		desk._build_trace()
		await process_frame
		await press(desk,"MAZE STEP")
		check(desk.step_count==1 and desk.other.generation_stack.size()==1, "first maze step stores the starting cell")
		await press(desk,"FINISH")
		check(desk.other.generation_complete and maze_route(desk.other), "finished maze has a connected array route")
		await press(desk,"RESET")
		check(desk.step_count==0 and not desk.other.generation_complete, "reset restores the unfinished maze")
		check(is_instance_valid(nodes.get("binary_space_partitioning")), "BSP comparison remains present")
		report["carving_centres"]=desk.model.carve_history.size()
	report["review_checks"]=checks
	report["review_scope"]="Real museum placements and button signals, controlled CharacterBody approach and aisle segments. Maze connectivity is an array check. No headset, exhaustive cave traversal or learner acceptance."
'''
helpers = r'''

var checks: Array = []
func check(ok: bool, title: String) -> void:
	checks.append({"check":title,"passed":ok})
	if not ok: failures.append(title)

func press(desk: Node3D, id: String) -> void:
	var b: Node = desk.buttons[id].get_node("InteractableAreaButton")
	b.emit_signal("button_pressed",b)
	await create_timer(0.15).timeout

func maze_route(maze: Node3D) -> bool:
	var goal:=Vector2i(maze.maze_width-2,maze.maze_height-1)
	var todo: Array[Vector2i]=[Vector2i(1,0)]
	var seen: Dictionary={Vector2i(1,0):true}
	while not todo.is_empty():
		var p: Vector2i=todo.pop_front()
		if p==goal:return true
		for d in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var q: Vector2i=p+d
			if q.x<0 or q.y<0 or q.x>=maze.maze_width or q.y>=maze.maze_height or seen.has(q) or maze.maze[q.y][q.x]:continue
			seen[q]=true;todo.append(q)
	return false
'''
needle = '\tawait physics_frame\n\tvar space :='
assert base.count(needle) == 1
(HERE/'probe_review.gd').write_text(base.replace(needle, setup+'\n'+needle)+helpers, encoding='utf-8')
shutil.copy2(ROOT/'ada_run/em_plan.json', RUN/'plan.json')
spec = json.loads((RUN/'spec.json').read_text())
spec['rays'] = [{'tag': name, 'x': x, 'z': z, 'top': 0} for name,x,z in [
    ('left approach',13,5),('left aisle',13,18),('comparison court',19.5,18),('onward aisle',19.5,35),('exit approach',19.5,45)]]
spec['walks'] = [
    {'tag':'enter cave mouth', 'from':[19.5,.1,4.3], 'to':[20,0,7.5], 'seconds':3},
    {'tag':'entry to left approach', 'from':[19.5,.1,5], 'to':[13,0,5], 'seconds':4},
    {'tag':'around cave to comparison court', 'from':[13,.1,5], 'to':[13,0,18], 'seconds':8},
    {'tag':'across comparison court', 'from':[13,.1,18], 'to':[19.5,0,18], 'seconds':4},
    {'tag':'court to exit', 'from':[19.5,.1,18], 'to':[19.5,0,46], 'seconds':16},
]
# Same viewpoint and opening seed as before; a fixed eye shows the new approach.
spec['shots'] += [{'tag':'cave-mouth','from':[20,1.7,4.5],'look_at':[20,1.7,9],'fov':75}]
(HERE/'review-spec.json').write_text(json.dumps(spec,indent=2),encoding='utf-8')
manifest = {}
for path in [ROOT/'commons/scenes/endless_museum.gd', ROOT/'commons/maps/PG_Caves_Mazes/map_data.json',
             ROOT/'commons/artifacts/timing_machines/pg_workshop.gd', RUN/'plan.json',
             RUN/'museum_snapshot.gd', RUN/'control.json', RUN/'necklace_hand.json', RUN/'em_overrides.json',
             HERE/'probe_review.gd', HERE/'review-spec.json',
             *list((ROOT/'algorithms/proceduralgeneration/growth_systems/caverandomwalk').glob('*.gd')),
             *list((ROOT/'algorithms/proceduralgeneration/procedural_logic/mazegeneration').glob('*.gd'))]:
    manifest[path.relative_to(ROOT).as_posix()] = hashlib.sha256(path.read_bytes()).hexdigest()
(HERE/'runtime-inputs.json').write_text(json.dumps(manifest,indent=2))
report = RUN/'report.json'
if report.exists():report.unlink()
cmd = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),'--xr-mode','off',
       '--no-window','--rendering-method','gl_compatibility','--audio-driver','Dummy',
       '--log-file',str(HERE/'engine.log'),'--script',PREFIX+'probe_review.gd','--',PREFIX+'review-spec.json']
with (HERE/'process.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(cmd,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,timeout=150,creationflags=subprocess.CREATE_NO_WINDOW)
print('Review exit:',result.returncode)
print((HERE/'process.log').read_text(encoding='utf-8',errors='replace')[-1500:])
if report.exists():shutil.copy2(report,HERE/'review-report.json')
if result.returncode==0:
    for name in ['entrance.png','court.png','cave-mouth.png']:shutil.copy2(RUN/name,HERE/('after-'+name))
raise SystemExit(result.returncode)
