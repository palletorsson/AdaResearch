"""Compare inherited geometry, then exercise the real museum desk and approach."""
from pathlib import Path
import hashlib
import json
import shutil
import subprocess

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]
RUN = ROOT / 'ada_run/encounter_pilot/Fractal_KochSierpinski'
base = (ROOT / 'tools/probes/museum_encounter.gd').read_text(encoding='utf-8')
setup = '''
	var player_camera: Camera3D = museum.get("_cam")
	if player_camera != null:
		for timer in player_camera.find_children("*", "Timer", true, false): timer.stop()
	var outcomes: Array = []
	var inherited = load("res://doc/book/iterations/2026-09-19-fractals-review/before/algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd")
	var current = load("res://algorithms/cellularautomata/sierpinski_pyramid/SierpinskiPyramid.gd")
	for recipe in [{"tick":"once","packing":"dust"},{"tick":"fine","packing":"contact"},{"tick":"dense","packing":"open"}]:
		var old = inherited.new()
		var updated = current.new()
		old.apply_grid_config(recipe)
		updated.apply_grid_config(recipe)
		old.generate()
		updated.generate()
		var same: bool = leaves(old) == leaves(updated)
		outcomes.append({"check":"default leaf positions, scales and order match frozen original", "recipe":recipe, "passed":same, "count":leaves(updated).size()})
		old.free()
		updated.free()
	var specimen: Node3D = nodes.get("sierpinski_pyramid") as Node3D
	if specimen == null or not specimen.has_node("PyramidComparison"):
		failures.append("Pyramid comparison missing")
	else:
		var desk: Node3D = specimen.get_node("PyramidComparison")
		var original: Array = leaves(specimen)
		outcomes.append({"check":"starts with inherited depth-three construction", "passed": specimen.extra_crown and specimen.depth == 3 and specimen.leaf_count == 216 and original.size() == 216})
		desk.buttons["RULE"].emit_signal("pressed")
		outcomes.append({"check":"RULE reveals 216 instances and six calls", "passed": desk.readout.text.contains("216 leaf") and desk.readout.text.contains("6 calls")})
		desk.buttons["RULE"].emit_signal("pressed")
		await capture_state(origin, folder, "six-calls")
		desk.buttons["COMPARE"].emit_signal("pressed")
		await process_frame
		await process_frame
		var reduced: Array = leaves(specimen)
		var subset: bool = true
		var remaining := original.duplicate()
		for item in reduced:
			var found: int = remaining.find(item)
			if found < 0: subset = false
			else: remaining.remove_at(found)
		outcomes.append({"check":"COMPARE retains 125 original leaf instances at the same positions and scale", "passed": not specimen.extra_crown and specimen.depth == 3 and specimen.leaf_count == 125 and reduced.size() == 125 and subset})
		await capture_state(origin, folder, "five-calls")
		desk.buttons["RULE"].emit_signal("pressed")
		outcomes.append({"check":"RULE reveals five calls and 125 instances", "passed": desk.readout.text.contains("125 leaf") and desk.readout.text.contains("5 calls")})
		await capture_state(origin, folder, "five-rule")
		desk.buttons["RESET"].emit_signal("pressed")
		await process_frame
		await process_frame
		outcomes.append({"check":"RESET restores original geometry and retains the same live desk", "passed": leaves(specimen) == original and specimen.get_node("PyramidComparison") == desk and not desk.show_rule})
		var pos: Vector3 = desk.buttons["COMPARE"].global_position - origin
		outcomes.append({"check":"desk floor and standing button height", "passed": absf(desk.global_position.y-origin.y)<0.005 and pos.y>1.0 and pos.y<1.2, "button_position":arr(pos)})
	for outcome in outcomes:
		if not outcome.passed: failures.append(str(outcome.check))
	report["controls"] = outcomes
	report["interaction_scope"] = "Real button signals, rendered state changes and controlled desktop walking; no headset hands, comfort or learner check."
'''
helpers = '''

func leaves(host: Node) -> Array:
	var result: Array = []
	for child in host.get_children():
		if child is Node3D and not child.get_meta("pyramid_study", false) and not child.is_queued_for_deletion():
			result.append([child.position, child.scale])
	return result

func capture_state(origin: Vector3, folder: String, tag: String) -> void:
	var camera := Camera3D.new()
	root.add_child(camera)
	camera.global_position = origin + Vector3(8.8,1.7,22.8)
	camera.look_at(origin + Vector3(6.5,1.35,25.5))
	camera.fov = 65
	camera.current = true
	await create_timer(0.4).timeout
	await RenderingServer.frame_post_draw
	if root.get_camera_3d() != camera: failures.append("state camera replaced")
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+tag+".png"))
	camera.queue_free()
'''
needle = '\tawait physics_frame\n\tvar space :='
assert base.count(needle) == 1
source = base.replace(needle, setup + '\n' + needle).replace('folder + "report.json"', 'folder + "controls-report.json"') + helpers
(HERE / 'probe_controls.gd').write_text(source, encoding='utf-8')
spec = json.loads((RUN / 'spec.json').read_text(encoding='utf-8'))
spec['walks'] = [
    {'tag':'enter comparison gallery', 'from':[9.5,0.05,19.5], 'to':[7.4,0,22.3], 'seconds':3},
    {'tag':'reach front of controls', 'from':[7.4,0.05,22.3], 'to':[6.5,0,22.65], 'seconds':2},
    {'tag':'walk around right of specimen', 'from':[8.2,0.05,23.5], 'to':[8.2,0,26.5], 'seconds':3},
    {'tag':'continue to exit', 'from':[8.2,0.05,26.5], 'to':[9.5,0,27.5], 'seconds':2},
]
(HERE/'controls-spec.json').write_text(json.dumps(spec,indent=2)+'\n',encoding='utf-8')
command = ['C:/Users/palle/Desktop/Godot_v4.6-stable_win64.exe','--path',str(ROOT),
           '--xr-mode','off','--no-window','--rendering-method','gl_compatibility',
           '--audio-driver','Dummy','--log-file',str(HERE/'controls-engine.log'),
           '--script','res://doc/book/iterations/2026-09-19-fractals-review/probe_controls.gd',
           '--','res://doc/book/iterations/2026-09-19-fractals-review/controls-spec.json']
museum = ROOT/'commons/scenes/endless_museum.gd'
before = hashlib.sha256(museum.read_bytes()).hexdigest()
with (HERE/'controls-process.log').open('w',encoding='utf-8') as log:
    result = subprocess.run(command,cwd=ROOT,stdout=log,stderr=subprocess.STDOUT,
                            timeout=120,creationflags=subprocess.CREATE_NO_WINDOW)
assert before == hashlib.sha256(museum.read_bytes()).hexdigest()
print('Controls exit:', result.returncode)
print((HERE/'controls-process.log').read_text(encoding='utf-8')[-1200:])
if result.returncode == 0:
    for name in ['six-calls.png','five-calls.png','five-rule.png','desk.png','pyramid.png','controls-report.json','source_manifest.json']:
        shutil.copy2(RUN/name,HERE/name)
raise SystemExit(result.returncode)
