from pathlib import Path
import shutil, json, hashlib

ROOT = Path(__file__).resolve().parent
REPO = ROOT.parents[4]
ORDER = json.loads((ROOT.parent/'packet/order.json').read_text())

def write(name, text):
    p=ROOT/name; p.parent.mkdir(parents=True, exist_ok=True); p.write_text(text, encoding='utf-8')
def change(hall, name, before, after):
    p=ROOT/hall/'variation'/name
    t=p.read_text(); assert before in t, (hall,before); p.write_text(t.replace(before,after,1),encoding='utf-8')

change('CA_Introduction','row.gd','var seeds: Array[int] = [16]','var seeds: Array[int] = [3, 5]')
change('CA_ElementaryRules','volume.gd','\t# Nine cells in a flat square; three more just above its middle row.\n\tfor z in range(2, 5):\n\t\tfor x in range(2, 5):\n\t\t\tcurrent[index(Vector3i(x, 3, z))] = 1\n\tfor x in range(2, 5):\n\t\tcurrent[index(Vector3i(x, 4, 3))] = 1', '\t# Student variation: a four-cell square wholly inside the shell.\n\tfor z in range(2, 4):\n\t\tfor x in range(2, 4):\n\t\t\tcurrent[index(Vector3i(x, 3, z))] = 1')
change('CA_GameOfLife','history.gd','return Vector3(0.85, 1.05 + x * 0.055, g * CELL)','return Vector3(0.85 + x * 0.012, 1.05 + x * 0.055, g * CELL)')
change('CA_BeyondBinary','life.gd','const SITE := Vector2i(10, 10)','const SITE := Vector2i(2, 2)')
change('CA_BeyondBinary','life.gd','var seeds: Array[Vector2i] = [Vector2i(7, 6), Vector2i(8, 7), Vector2i(6, 8), Vector2i(7, 8), Vector2i(8, 8)]','var seeds: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 2), Vector2i(2, 3), Vector2i(3, 3)]')
change('CA_ExpandingSpace','presence.gd','const RADIUS := 1.35','const RADIUS := 0.75')
change('CA_SoftRules','field.gd','\t\t\tu[index(site.x + dx, site.y + dy)] = 0.5\n\t\t\tv[index(site.x + dx, site.y + dy)] = 0.25','\t\t\tu[index(site.x + dx, site.y + dy)] = 0.7\n\t\t\tv[index(site.x + dx, site.y + dy)] = 0.1')
change('CA_SoftRules','exchange.gd','\tright.reset()\n\tinjections = 0','\tright.reset()\n\tleft.seed_at(Vector2i(5, 6))\n\tright.seed_at(Vector2i(5, 6))\n\tinjections = 0')
change('CA_AgentsCircuits','comparison.gd','var seed_sites: Array[int] = [16]','var seed_sites: Array[int] = [1, 4, 8]')
change('CA_EdgeOfChaos','paired.gd','var site := Vector3i(5, 5, 5)','var site := Vector3i(0, 5, 5)')
change('CA_EdgeOfChaos','paired.gd','var pull := 0.25','var pull := 0.5')
change('CA_EdgeOfChaos','paired.gd','var integer_storage := true','var integer_storage := false')

predictions = {
'CA_Introduction': 'Original: Rule 90 single 16 gives [15,17]; next [14,18]. Variation source seeds [3,5] gives [2,6], because cell 4 receives two true neighbours and cancels. Traversal cannot affect synchronous answers; original state must remain untouched. Saved rows must not alias the current array. Visible first row must match states.',
'CA_ElementaryRules': 'Original centre states/counts are (1,11),(2,14),(0,5), following the printed small seed. Variation is a 2x2 square at x=2,3 z=2,3 y=3. The nominated centre (3,3,3) has (1,3),(2,0),(0,0). No cell can see six active neighbours initially, so all four fade then the entire field is empty. A fading centre with seven neighbours must still empty. Outer shell remains empty.',
'CA_GameOfLife': 'Original seed 7 gives [6,7,8]. Variation changes only screen X from .85 to .85 + .012*x, producing a diagonal screen; a cell at x=7 is at X=.934. Deck and collision retain the original mapping. Occupied recorded cells have both meshes and deck support; recorded false cells and future cells do not. Reading row zero cannot rewind the current state; saved rows must remain copies.',
'CA_BeyondBinary': 'Original glider shifts (1,1) after four steps; fixed A is lit at 8 and dark at 12. Variation replaces seed with a block at (2,2),(3,2),(2,3),(3,3) and SITE=(2,2). Its states and lamp stay true for every tested step. Unlinking darkens globe/light without changing the state or clock; replay preserves link. A block tests survival plus lack of births, not the worked blinker.',
'CA_ExpandingSpace': 'Variation changes RADIUS to .75 simulation metres. A synthetic held path approaches cell (1,4), pauses for six committed steps .05 view metres above it, then withdraws for two steps. At paused time the target is .76 in both programs; W=(2,6) stays 1.0. Diagonal (2,5), distance sqrt(.6^2+.6^2+.25^2), is .76 with original radius 1.35 but 1.0 with .75. All neighbouring values stay >.5, so after withdrawal target=.84. Moving without stepping cannot alter state. Exact health .2 keeps support; .199 loses it. Transformed study must preserve local input.',
'CA_SoftRules': 'Original W first A=(.92,.02), B=(1,0). Variation adds same 3x3 seed centred (5,6) with U=.7,V=.1 to both resets. Untouched (3,6) has one changed axial neighbour: lapU=-.3, lapV=.1, so first A=(.952,.008), B=(1,0). Unchanged central seed still behaves as printed. Exchange enabled in both must give equal arrays. View changes only textures; valid held planting changes both fields without clock advance, invalid/unheld planting does nothing.',
'CA_AgentsCircuits': 'Original single seed gives [15,17], and at generation 16 the ring is empty. Variation source [1,4,8] gives [0,2,3,5,7,9] at generation one. Cube recipe remains 216 entries/transforms regardless of seed or step. The chosen feature is separation of the two outer tips from the four inner tips: its row intervals differ from the single-seed symmetry, while the sculpture remains fixed. Dark recorded zero cells remain drawn; future slots are hidden.',
'CA_EdgeOfChaos': 'Original integer centre difference is discarded after one update. Fractional centre control yields count=27 and peak=.75. Variation uses face site (0,5,5), fractional storage and pull=.5: after one step self plus 17 valid neighbours differ, so count=18, peak=.5. A face receiver (0,4,5) gets .5/17; an interior receiver (1,5,5) gets .5/26. Far face is unchanged. Slice selection cannot change arrays/time. Identical beginnings with shared forcing must remain identical. Display gain=2 after the variation first step; a bright difference pixel does not imply growth.'
}
write('PREDICTIONS.md','# Predictions written before Godot execution\n\nThese are AI reconstruction and transfer predictions, not human-learning evidence. No Godot execution or pre-existing probe was used to write them.\n\n'+'\n\n'.join('## '+h+'\n\n'+predictions[h] for h in ORDER)+'\n')
for h,p in predictions.items(): write(h+'/prediction.md',p+'\n')

shutil.copytree(REPO/'addons/godot-xr-tools',ROOT/'addons/godot-xr-tools',dirs_exist_ok=True)
write('project.godot','''config_version=5
[application]
config/name="Fresh CA student — isolated packet reconstruction"
run/main_scene="res://neutral.tscn"
[autoload]
XRToolsUserSettings="*res://addons/godot-xr-tools/user_settings/user_settings.gd"
XRToolsRumbleManager="*res://addons/godot-xr-tools/rumble/rumble_manager.gd"
[display]
window/size/viewport_width=1280
window/size/viewport_height=960
[rendering]
renderer/rendering_method="gl_compatibility"
environment/defaults/default_clear_color=Color(0.07, 0.09, 0.12, 1)
''')
write('neutral.tscn','''[gd_scene load_steps=2 format=3]
[ext_resource type="Script" path="res://runner.gd" id="1"]
[node name="NeutralHost" type="Node3D"]
script = ExtResource("1")
''')
write('runner.gd','''extends Node3D
var checks: Array = []
var observations: Dictionary = {}
var hall := ""
var variant := ""
var run_id := ""
var out_dir := ""
var study
var failed := false

func _ready() -> void:
	var args := OS.get_cmdline_user_args()
	for i in range(args.size() - 1):
		match args[i]:
			"--hall": hall = args[i+1]
			"--variant": variant = args[i+1]
			"--run-id": run_id = args[i+1]
	out_dir = "res://%s/%s/runs/%s" % [hall, variant, run_id]
	DirAccess.make_dir_recursive_absolute(out_dir)
	var camera := Camera3D.new()
	add_child(camera)
	camera.position = Vector3(3.5, 4.4, 6.6)
	camera.look_at(Vector3(0, 1.25, 0.4))
	camera.current = true
	camera.fov = 43
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-45, -30, 0)
	sun.light_energy = 1.2
	add_child(sun)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("263440")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color.WHITE
	env.environment.ambient_light_energy = 0.6
	add_child(env)
	var hosts := {"CA_Introduction":"row.gd", "CA_ElementaryRules":"volume.gd", "CA_GameOfLife":"history.gd", "CA_BeyondBinary":"life.gd", "CA_ExpandingSpace":"presence.gd", "CA_SoftRules":"exchange.gd", "CA_AgentsCircuits":"comparison.gd", "CA_EdgeOfChaos":"difference.gd"}
	var script = load("res://%s/%s/%s" % [hall, variant, hosts[hall]])
	check(script != null and script.can_instantiate(), "printed_host_loads")
	if failed: return
	study = script.new()
	study.name = "PointStudy"
	add_child(study)
	await settle()
	check(study.point != null, "printed_point_constructed")
	check(study.point is XRToolsPickable, "real_declared_xrtools_pickable")
	check(study.point.get_child_count() >= 2, "point_mesh_and_collision")
	var spec = load("res://tests/%s.gd" % hall).new()
	await spec.run(study, self, variant == "variation")
	await settle()
	await RenderingServer.frame_post_draw
	var shot := get_viewport().get_texture().get_image()
	check(shot.get_width() == 1280 and shot.get_height() == 960, "rendered_viewport_dimensions")
	var save_error := shot.save_png(out_dir + "/screenshot.png")
	check(save_error == OK, "screenshot_saved")
	finish()
	get_tree().quit(1 if failed else 0)

func settle() -> void:
	await get_tree().process_frame
	await get_tree().physics_frame
	await get_tree().process_frame

func check(condition: bool, label: String) -> void:
	checks.append({"name":label,"passed":condition})
	print("CHECK ", label, " ", "PASS" if condition else "FAIL")
	if not condition:
		failed = true
		push_error("STUDENT ASSERTION: " + label)
		finish()
		get_tree().quit(1)
	assert(condition, label)

func near(actual: float, expected: float, label: String, tolerance: float = 0.00001) -> void:
	check(absf(actual - expected) <= tolerance, label + " got=" + str(actual) + " expected=" + str(expected))

func active(row: Array) -> Array:
	var result: Array = []
	for i in row.size():
		if row[i]: result.append(i)
	return result

func observe(label: String, value) -> void:
	observations[label] = value

func finish() -> void:
	var file := FileAccess.open(out_dir + "/checks.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"hall":hall,"variant":variant,"checks":checks,"observations":observations,"passed":not failed}, "  "))
''')

tests={}
tests['CA_Introduction']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	var expected: Array = [2,6] if varied else [15,17]
	var original: Array = s.current.duplicate()
	var answer: Array = s.evolve(s.current)
	h.check(h.active(answer) == expected, "independent_first_row")
	h.check(s.current == original, "evolve_does_not_mutate_old")
	for bits in 8:
		h.check(s.answer(bool(bits & 4), bool(bits & 2), bool(bits & 1)) == (bool(bits & 4) != bool(bits & 1)), "ordered_truth_table_%d" % bits)
	s.step()
	h.check(s.generation == 1 and h.active(s.current) == expected, "step_state_and_clock")
	h.check(s.history[1] == original, "prior_row_retained")
	s.current[0] = not s.current[0]
	h.check(s.history[0][0] != s.current[0], "history_snapshot_not_alias")
	s.reset()
	s.step()
	for i in s.WIDTH:
		var expected_ink := Color("87dca5") if expected.has(i) else Color("243238")
		h.check(s.tiles.get_instance_color(i).is_equal_approx(expected_ink), "visible_cell_%d" % i)
	var before: Array = s.current.duplicate()
	s.point.on_desktop_grab(h)
	s.point.position.x = s.cell_x(31)
	s._physics_process(0.1)
	h.check(s.selected == 31 and s.current == before, "held_reader_moves_without_edit")
	h.near(s.marks[2].position.x, s.cell_x(0), "right_mark_wraps")
	s.point.on_desktop_drop(h)
	for i in 30: s.step()
	h.check(s.history.size() == 24 and s.generation == 31, "history_budget_does_not_stop_clock")
	s.reset()
	for i in 9: s.step()
	h.observe("first_active", expected)
'''
tests['CA_ElementaryRules']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	var states: Array = []
	var counts: Array = []
	for g in 3:
		states.append(s.current[s.index(s.CENTRE)])
		counts.append(s.active_neighbours(s.current, s.CENTRE))
		if g < 2: s.step()
	h.check(states == [1,2,0], "two_step_centre_states")
	h.check(counts == ([3,0,0] if varied else [11,14,5]), "two_step_neighbour_counts")
	h.check(s.next_state(0,7) == 1 and s.next_state(2,7) == 0, "fading_precedes_birth")
	for count in 27:
		h.check(s.next_state(2,count) == 0, "fading_always_empties_%d" % count)
	if varied: h.check(s.current.count(0) == 343, "four_cell_seed_becomes_entirely_empty")
	for z in 7:
		for y in 7:
			for x in 7:
				if x == 0 or x == 6 or y == 0 or y == 6 or z == 0 or z == 6:
					h.check(s.current[s.index(Vector3i(x,y,z))] == 0, "outer_shell_%d_%d_%d" % [x,y,z])
	s.reset()
	s.step()
	var centre: int = s.index(s.CENTRE)
	h.check(s.cells.get_instance_color(centre).is_equal_approx(Color("89d7a3")), "fading_visible_green")
	h.near(s.cells.get_instance_transform(centre).basis.determinant(), 1.0, "fading_still_visible")
	var old: Array = s.current.duplicate()
	s.evolve(s.current)
	h.check(s.current == old, "evolve_keeps_old")
	h.observe("states", states)
	h.observe("active_counts", counts)
'''
tests['CA_GameOfLife']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	s.step()
	h.check(h.active(s.current) == [6,7,8], "rule30_first_row")
	await h.settle()
	for pair in [[7,0,true],[6,0,false],[7,1,true],[7,2,false]]:
		var x: int = pair[0]
		var g: int = pair[1]
		var live: bool = pair[2]
		var i: int = g * s.WIDTH + x
		h.check((s.deck.get_instance_transform(i).basis.determinant() > 0) == live, "deck_occupancy_%d" % i)
		h.check((s.screen.get_instance_transform(i).basis.determinant() > 0) == live, "screen_occupancy_%d" % i)
		h.check(s.shapes[i].disabled == not live, "collision_occupancy_%d" % i)
		h.check(s.shapes[i].position == s.deck_position(x,g), "collision_mapping_%d" % i)
		h.near(s.screen.get_instance_transform(i).origin.x, .85 + x * .012 if varied else .85, "screen_mapping_%d" % i)
	s.current[0] = true
	h.check(not s.history[1][0], "saved_row_independent")
	s.replay()
	for j in 5: s.step()
	var current: Array = s.current.duplicate()
	s.select_row(0)
	h.check(s.current == current and s.history.size() == 6, "selection_not_rewind")
	s.select_row(23)
	h.check(s.selected == 0, "future_not_selectable")
	var expected: Array = s.next_row(current)
	s.step()
	h.check(s.current == expected, "append_from_latest_not_selected")
	for j in 30: s.step()
	h.check(s.history.size() == 24, "budget_holds_24_rows")
	var end: Array = s.current.duplicate()
	s.step()
	h.check(s.current == end, "budget_holds_state")
	s.replay()
	for j in 11: s.step()
	s.select_row(3)
	h.observe("screen_site7_x", s.screen_position(7,0).x)
'''
tests['CA_BeyondBinary']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	var original: Array = s.current.duplicate()
	var transforms: Array = []
	for i in s.current.size(): transforms.append(s.cells.get_instance_transform(i))
	for i in 4: s.step()
	if varied:
		h.check(s.current == original, "block_still_life")
	else:
		var shifted: Array[bool] = []
		shifted.resize(576)
		shifted.fill(false)
		for p in s.seeds: shifted[s.index(p.x+1,p.y+1)] = true
		h.check(s.current == shifted, "glider_translates_after_four")
	for i in 4: s.step()
	h.check(s.current[s.index(s.SITE.x,s.SITE.y)], "receiver_occupied_at_eight")
	h.near(s.lamp.light_energy, 1.2, "linked_lamp_lit")
	var state: Array = s.current.duplicate()
	var generation: int = s.generation
	s.toggle_link()
	h.check(s.current == state and s.generation == generation, "link_does_not_evolve")
	h.near(s.lamp.light_energy, 0.0, "unlinked_lamp_dark")
	h.near(s.lamp_finish.emission_energy_multiplier, 0.0, "unlinked_globe_dark")
	s.toggle_link()
	h.near(s.lamp.light_energy, 1.2, "reconnect_reads_current")
	for i in 4: s.step()
	h.check(s.current[s.index(s.SITE.x,s.SITE.y)] == varied, "receiver_at_twelve")
	for i in transforms.size(): h.check(s.cells.get_instance_transform(i) == transforms[i], "fixed_tile_%d" % i)
	s.toggle_link()
	s.replay()
	h.check(not s.linked and s.generation == 0, "replay_preserves_link")
	h.check(s.next_state(false,2) == false and s.next_state(true,2) == true, "birth_survival_distinct")
	h.check(s.index(-1,24) == 23, "periodic_boundary")
	s.toggle_link()
	for i in 8: s.step()
	h.observe("receiver_sequence_g8_g12", [true,varied])
'''
tests['CA_ExpandingSpace']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	var target := Vector2i(1,4)
	var diagonal := Vector2i(2,5)
	s.position = Vector3(.3,0,-.2)
	s.rotation.y = .37
	s.point.on_desktop_grab(h)
	s.point.global_position = s.to_global(s.view_position(target) + Vector3.UP * .05)
	h.check(s.input_position().is_equal_approx(s.cell_position(target) + Vector3.UP * .25), "world_local_simulation_conversion")
	var before: Dictionary = s.current.duplicate()
	await h.settle()
	h.check(s.current == before and s.ticks == 0, "pause_without_steps_keeps_state")
	for i in 6: s.step()
	h.near(s.current[target], .76, "six_held_steps_target")
	h.near(s.current[diagonal], 1.0 if varied else .76, "radius_changes_diagonal_reach")
	h.near(s.current[s.W], 1.0, "distant_w_keeps_support")
	s.point.on_desktop_drop(h)
	for i in 2: s.step()
	h.near(s.current[target], .84, "withdrawal_two_recovery_steps")
	h.check(s.current.size() == 80, "addresses_persist")
	s.current[target] = .2
	s.current[diagonal] = .199
	s.redraw()
	await h.settle()
	h.check(not s.supports[target].disabled and s.supports[diagonal].disabled, "support_threshold_distinguishes_point2")
	h.check(s.materials[diagonal].transparency == BaseMaterial3D.TRANSPARENCY_ALPHA, "depleted_receiver_transparent")
	var same_material := 0
	for child in s.get_children():
		if child is MeshInstance3D and child.material_override == s.materials[target]: same_material += 1
	h.check(same_material == 2, "floor_wall_share_material")
	s.chain = true
	s.reset()
	s.synchronous = true
	var forward: Dictionary = s.evolve(s.current, Vector3.ZERO, false)
	s.backwards = true
	h.check(s.evolve(s.current, Vector3.ZERO, false) == forward, "sync_order_independent")
	s.synchronous = false
	s.backwards = false
	var scan: Dictionary = s.evolve(s.current, Vector3.ZERO, false)
	h.near(scan[Vector2i(3,6)], .01, "forward_scan_transmits_new_threshold")
	s.backwards = true
	var reversed: Dictionary = s.evolve(s.current, Vector3.ZERO, false)
	h.near(reversed[Vector2i(3,6)], 0, "reverse_scan_waits")
	s.chain = false
	s.synchronous = true
	s.backwards = false
	s.reset()
	s.point.on_desktop_grab(h)
	s.point.global_position = s.to_global(s.view_position(target) + Vector3.UP * .05)
	for i in 21: s.step()
	s.point.on_desktop_drop(h)
	h.observe("target_after_withdrawal", .84)
	h.observe("diagonal_after_six", 1.0 if varied else .76)
'''
tests['CA_SoftRules']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	var site := Vector2i(3,6) if varied else s.W
	var i: int = s.left.index(site.x,site.y)
	h.near(s.left.u[i], 1.0, "witness_initial_u")
	h.near(s.left.v[i], 0.0, "witness_initial_v")
	s.advance(1)
	h.near(s.left.u[i], .952 if varied else .92, "exchange_first_u")
	h.near(s.left.v[i], .008 if varied else .02, "exchange_first_v")
	h.near(s.right.u[i], 1.0, "no_exchange_first_u")
	h.near(s.right.v[i], 0.0, "no_exchange_first_v")
	var before = s.left.v.duplicate()
	var old_pixel: Color = s.textures[0].get_image().get_pixel(site.x,site.y)
	s.show_u = true
	s.paint()
	h.check(s.left.v == before and s.left.ticks == 1, "palette_preserves_state_clock")
	h.check(not s.textures[0].get_image().get_pixel(site.x,site.y).is_equal_approx(old_pixel), "palette_changes_visible_texture")
	s.change_exchange()
	s.advance(3)
	h.check(s.left.u == s.right.u and s.left.v == s.right.v, "matched_exchange_complete_arrays_agree")
	var ticks: int = s.left.ticks
	s.point.on_desktop_grab(h)
	s.point.position = Vector3(-.85 + (8.5-16)*.04,1.08,.5 + (7.5-16)*.04)
	h.check(s.target_site() == Vector2i(8,7), "held_position_selects_address")
	s.plant()
	h.check(s.injections == 1 and s.left.ticks == ticks, "plant_does_not_step")
	i = s.left.index(8,7)
	h.near(s.left.v[i], .1 if varied else .25, "source_seed_concentration")
	h.near(s.right.v[i], s.left.v[i], "same_intervention_both_fields")
	s.point.position = Vector3(9,9,9)
	s.plant()
	h.check(s.injections == 1, "invalid_position_no_injection")
	s.point.on_desktop_drop(h)
	s.plant()
	h.check(s.injections == 1, "unheld_no_injection")
	var receivers: Array = [0,0]
	for child in s.get_children():
		if child is MeshInstance3D and child.material_override is StandardMaterial3D:
			for side in 2:
				if child.material_override.albedo_texture == s.textures[side]: receivers[side] += 1
	h.check(receivers == [2,2], "each_texture_has_two_receivers")
	s.right.exchange = false
	s.show_u = false
	s.reset()
	s.advance(100)
	h.observe("predicted_first_pair", [.952,.008] if varied else [.92,.02])
'''
tests['CA_AgentsCircuits']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	h.check(s.positions.size() == 216 and s.copies.instance_count == 216, "six_cubed_copy_entries")
	var positions: Array = s.positions.duplicate()
	var transforms: Array = []
	for i in s.copies.instance_count: transforms.append(s.copies.get_instance_transform(i))
	s.step()
	var expected: Array = [0,2,3,5,7,9] if varied else [15,17]
	h.check(h.active(s.history.back()) == expected, "independent_rule90_first_row")
	h.check(s.cells.get_instance_transform(32 + 16).basis.determinant() > .9, "recorded_zero_is_visible")
	h.near(s.cells.get_instance_transform(2*32).basis.determinant(), 0, "unrecorded_row_hidden")
	var old: Array = s.history[0].duplicate()
	for j in 15: s.step()
	h.check(h.active(s.history.back()).is_empty(), "all_rule90_seeds_die_at_16_on_32_ring")
	h.check(s.history[0] == old, "history_keeps_seed")
	s.change_seed()
	for j in 4: s.step()
	h.check(s.positions == positions, "cellular_change_keeps_copy_positions")
	for i in transforms.size(): h.check(s.copies.get_instance_transform(i) == transforms[i], "fixed_copy_%d" % i)
	var leaf: Array = s.methods.copy_positions(Vector3(2,3,4),2.0,0)
	h.check(leaf == [Vector3(2,3,4)], "recursive_base_case")
	s.seed_sites.assign([1,4,8] if varied else [16])
	s.reset()
	for j in 10: s.step()
	h.observe("first_active",expected)
'''
tests['CA_EdgeOfChaos']='''extends RefCounted
func run(s, h, varied: bool) -> void:
	var m = s.model
	h.check(m.report().count == 1, "exactly_one_initial_intervention")
	var before = m.b.duplicate()
	s.select_slice(6)
	h.check(m.b == before and m.tick == 0, "slice_only_changes_receiver")
	var low: Color = s.textures[2].get_image().get_pixel(5,5)
	h.check(low.is_equal_approx(Color("112c31")), "off_slice_difference_dark")
	s.select_slice(5)
	s.step()
	if varied:
		h.check(m.report().count == 18, "face_count18")
		h.near(m.report().maximum,.5,"face_peak_half")
		h.near(m.b[m.index(Vector3i(0,4,5))]-m.a[m.index(Vector3i(0,4,5))],.5/17.0,"face_receiver_own_degree")
		h.near(m.b[m.index(Vector3i(1,5,5))]-m.a[m.index(Vector3i(1,5,5))],.5/26.0,"interior_receiver_own_degree")
		h.near(m.b[m.index(Vector3i(10,5,5))]-m.a[m.index(Vector3i(10,5,5))],0,"no_far_face_wrap")
		h.near(s.gain,2.0,"gain_half_peak")
	else:
		h.check(m.report().count == 0 and m.a == m.b, "integer_erases_difference")
		m.integer_storage = false
		m.reset()
		s.step()
		h.check(m.report().count == 27,"fractional_centre_count27")
		h.near(m.report().maximum,.75,"fractional_centre_peak")
	var result: Dictionary = m.report()
	h.observe("first_fractional_count",result.count)
	h.observe("first_fractional_peak",result.maximum)
	var site: Vector3i = m.site
	var pixel: Color = s.textures[2].get_image().get_pixel(site.x,10-site.y)
	h.check(pixel.is_equal_approx(Color("ffd18e")), "gain_maps_peak_to_bright_pixel")
	h.near(s.frames[0].position.z,0,"selected_slice_frame")
	m.changed = false
	m.drive = 1.0
	m.reset()
	for j in 4: m.step()
	h.check(m.a == m.b,"matched_forcing_no_intervention_control")
	m.changed = true
	m.drive = 0
	m.pull = 0
	m.reset()
	for j in 4: m.step()
	h.check(m.report().count == 1,"zero_pull_keeps_one_site")
	h.near(m.report().maximum,1.0,"zero_pull_keeps_full_difference")
	m.pull = .5 if varied else .25
	m.reset()
	s.step()
'''
for hall,test in tests.items(): write('tests/'+hall+'.gd',test)
manifest={}
for hall in ORDER:
    manifest[hall]={}
    for variant in ('original','variation'):
        manifest[hall][variant]={p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/hall/variant).glob('*.gd')}
write('source_hashes_before_run.json',json.dumps(manifest,indent=2))
write('pre_run_manifest.json',json.dumps({'predictions_sha256':hashlib.sha256((ROOT/'PREDICTIONS.md').read_bytes()).hexdigest(),'tests_sha256':{p.name:hashlib.sha256(p.read_bytes()).hexdigest() for p in (ROOT/'tests').glob('*.gd')},'status':'Prepared before any Godot subprocess'},indent=2))
print('Prepared eight source variations, predictions, neutral host and eight assertion scripts.')
