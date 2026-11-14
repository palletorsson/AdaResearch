extends SceneTree
## THE SEVEN COLUMNS, WALKED (Boolean_Verbs, the boolean floor's north-west corner; 2026-11-14)
## "make these but carved sculptures using sine and randomness, what is inbetween a helix etc" (Palle). Seven columns
## (iso_prefab forms column_*, 4.5 m tall and 1.35 m across since Palle's "make them bigger") stand in a triangle on the west side slab, which now reaches the corner. Read in the running
## tower with its own walker:
##   - all seven mounted, drawn, with collision, each with its plaque; OUTDOOR: no inside's probe, the skin's colour
##     the vertices' own (its material's limb_mix 1), and the passes keep theirs (limb_mix 0.85, a probe)
##   - a body walks in from the north slab and weaves through the triangle and out again, past x -24 the whole way
##     (the side slab is inside the tower), never sent back to spawn
##   - a body walks out of the passes' sine pass, through its north mouth, into the triangle's base
##   - the north slab's west end has no rail or post across the way (its east end, the control, has them); the west
##     slab's beams all come down over the floor below
##   - a column stops a body that walks at it
##   - pictures: the triangle from the north slab, from the passes, from above; each column from 3.45 m; inside the grove
##
##   godot --path <stage> --script res://tools/probes/iso_columns_walk.gd -- --no-bridges --void-start-floor=<161> --out=<dir>
const PREFIX := "iso-column-"
const ORDER := ["column_sine", "column_sine_helix", "column_helix", "column_helix_chance", "column_chance", "column_sine_chance", "column_middle"]
var game: Node3D
var body: CharacterBody3D
var level := 0.0
var works := {}
var eye: SubViewport
var cam: Camera3D
var spawn := Vector3.ZERO


func _initialize() -> void:
	run.call_deferred()


func _shot(at: Vector3, target: Vector3, path: String, fov := 65.0) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.fov = fov
	var shown := body.visible
	body.visible = false
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)
	body.visible = shown


func _w(x: float, y: float, z: float) -> Vector3:
	return Vector3(x, level + y, z)


func _place(x: float, z: float) -> void:
	game.place_player(Vector3(x, level + 0.12, z))
	for i in 30: await physics_frame


## Walk a path of floor points without stopping between them. A body that does not move for 80 ticks has been stopped.
## Also returns the farthest west it went and whether it was ever sent back toward the spawn.
func _path(points: Array, speed: float = 0.6, near: float = 0.25, ticks_max: int = 3600) -> Dictionary:
	var still := 0
	var last := body.global_position
	var west := body.global_position.x
	var sent_back := false
	var i := 0
	for tick in ticks_max:
		if i >= points.size(): break
		var target: Vector3 = points[i]
		var flat := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if flat < (0.12 if i == points.size() - 1 else near):
			i += 1
			continue
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
		if body.global_position.distance_to(last) > 2.0: sent_back = true     # a jump, not a step: the boundary
		west = minf(west, body.global_position.x)
		if body.global_position.distance_to(last) < 0.002: still += 1
		else: still = 0
		last = body.global_position
		if still > 80: break
	body.drive = Vector2.ZERO
	for t in 12: await physics_frame
	return {"reached": i >= points.size(), "end": body.global_position, "west": snappedf(west, 0.01), "sent_back": sent_back,
		"next": i}


func _pts(xz: Array) -> Array:
	var out := []
	for p in xz: out.append(_w(float(p[0]), 0.0, float(p[1])))
	return out


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	var floor_index: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor_index]
	var checks := []
	var result := {"floor": floor_index, "map": str(record.map), "checks": checks, "passed": false}
	var ids := []
	for item in record.artifacts:
		if str(item.id).begins_with(PREFIX) or str(item.id) == "iso-passes": ids.append(str(item.id))
	for i in 2400:
		var all := true
		for id in ids:
			if not game.building.content.exhibits.has("%d/%s" % [floor_index, id]): all = false
		if all: break
		await physics_frame
	for id in ids:
		var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor_index, id])
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work != null and work.has_method("state"): works[str(work.form)] = work
	for i in 240: await physics_frame
	level = float(game.building.spec.levels[floor_index]) + game.building.global_position.y
	body = game.body
	spawn = body.global_position
	eye = SubViewport.new()
	eye.size = Vector2i(1600, 1000)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	eye.add_child(cam)
	cam.current = true

	# ---- mounted, drawn, outdoor ----
	var drawn := {}
	var outdoor_ok := true
	var plaques := 0
	for form in ORDER:
		if not works.has(form):
			outdoor_ok = false
			continue
		var w: Node3D = works[form]
		var s: Dictionary = w.state()
		drawn[form] = [int(s.triangles), int(s.collision_triangles)]
		var mesh_node: MeshInstance3D = w.find_child("IsoMesh", true, false)
		var mat: ShaderMaterial = mesh_node.material_override if mesh_node != null else null
		if mat == null or not is_equal_approx(float(mat.get_shader_parameter("limb_mix")), 1.0): outdoor_ok = false
		if w.find_child("IsoInterior", true, false) != null: outdoor_ok = false
		if w.find_child("IsoPlaque", true, false) != null: plaques += 1
	var passes_kept := false
	if works.has("passes"):
		var pm: MeshInstance3D = works["passes"].find_child("IsoMesh", true, false)
		var pmat: ShaderMaterial = pm.material_override if pm != null else null
		passes_kept = pmat != null and is_equal_approx(float(pmat.get_shader_parameter("limb_mix")), 0.85) and works["passes"].find_child("IsoInterior", true, false) != null
	checks.append({"check": "all seven columns mounted, drawn and with collision, each with its plaque",
		"ok": drawn.size() == 7 and drawn.values().all(func(v): return v[0] > 5000 and v[1] > 1000) and plaques == 7, "drawn": drawn, "plaques": plaques})
	# the rails found by their SHAPE: slab_extension names both side rails "SideRail", and Godot renames the second sibling
	# (@MeshInstance3D@N) - a search by name never sees the west one, and the check could not fail (a review caught it).
	# The east end's rail and posts are the control: the search must see them.
	var north_mount: Node = game.building.content.exhibits.get("%d/side-slab-north" % floor_index)
	var north: Node3D = north_mount.get_node_or_null("Artifact") if north_mount != null else null
	var ends := {"west_rail": 0, "west_posts": 0, "east_rail": 0, "east_posts": 0}
	if north != null:
		for m in north.find_children("*", "MeshInstance3D", true, false):
			var box := (m as MeshInstance3D).mesh as BoxMesh
			if box == null: continue
			var p: Vector3 = (m as MeshInstance3D).global_position
			var end := "west" if absf(p.x + 21.0) < 0.3 else ("east" if absf(p.x - 21.0) < 0.3 else "")
			if end == "": continue
			if box.size.is_equal_approx(Vector3(0.05, 0.05, 10.0)): ends[end + "_rail"] += 1
			elif box.size.is_equal_approx(Vector3(0.05, 1.0, 0.05)) and p.z > -18.8: ends[end + "_posts"] += 1
	checks.append({"check": "no side rail or post stands across the way from the north slab into the corner (its west end is open; its east end keeps them: the control)",
		"ok": north != null and ends.west_rail == 0 and ends.west_posts == 0 and ends.east_rail == 1 and ends.east_posts >= 3, "ends": ends})
	# the west slab's beams set their feet over the floor below (z -9..9), not in mid-air past the building's north end
	var west_mount: Node = game.building.content.exhibits.get("%d/side-slab-west" % floor_index)
	var west: Node3D = west_mount.get_node_or_null("Artifact") if west_mount != null else null
	var feet := []
	if west != null:
		for m in west.find_children("Beam_*", "MeshInstance3D", true, false):
			var rod := m as MeshInstance3D
			var half: float = (rod.mesh as CylinderMesh).height * 0.5
			var axis: Vector3 = rod.global_basis.y.normalized() * half
			var a: Vector3 = rod.global_position + axis
			var b: Vector3 = rod.global_position - axis
			feet.append(snappedf((a if a.y < b.y else b).z, 0.01))
	var outside := feet.filter(func(z): return z < -9.1 or z > 9.1)
	checks.append({"check": "the west slab's beams come down onto the floor below's edge, none in mid-air past the building's end",
		"ok": feet.size() >= 20 and outside.is_empty(), "beams": feet.size(), "feet_z_range": [feet.min() if not feet.is_empty() else 0, feet.max() if not feet.is_empty() else 0], "outside": outside})
	checks.append({"check": "OUTDOOR: no inside's probe, the skin's colour the vertices' own (limb_mix 1); the passes keep theirs (0.85, a probe)",
		"ok": outdoor_ok and passes_kept, "columns": outdoor_ok, "passes": passes_kept})
	if drawn.size() < 7:
		_finish(folder, result)
		return

	# ---- pictures, before anyone walks ----
	body.global_position = _w(-19.0, 0.2, 2.0)                     # out of every picture
	await _shot(_w(-18.4, 1.75, -11.4), _w(-25.0, 2.1, -13.6), folder.path_join("from_north_slab.png"), 68.0)
	await _shot(_w(-26.8, 1.7, -8.3), _w(-25.0, 2.2, -14.6), folder.path_join("from_passes.png"), 72.0)
	# from above the void west of the slab (no floor overhead there: the floor above has no west slab)
	await _shot(_w(-37.0, 6.2, -6.0), _w(-25.0, 1.2, -13.6), folder.path_join("from_above.png"), 58.0)
	await _shot(_w(-24.0, 1.6, -11.6), _w(-27.4, 2.4, -15.3), folder.path_join("in_the_grove.png"), 78.0)
	for form in ORDER:
		var w: Node3D = works[form]
		var c := w.global_position
		await _shot(c + Vector3(3.45, 2.3, 0.0), c + Vector3(0.0, 2.25, 0.0), folder.path_join("close_%s.png" % form), 76.0)
	var helix: Vector3 = works["column_helix"].global_position
	var sine: Vector3 = works["column_sine"].global_position
	await _shot(helix + Vector3(0.0, 2.3, 3.45), helix + Vector3(0.0, 2.25, 0.0), folder.path_join("side_column_helix.png"), 76.0)
	await _shot(sine + Vector3(0.0, 2.3, -3.45), sine + Vector3(0.0, 2.25, 0.0), folder.path_join("side_column_sine.png"), 76.0)
	# chance's one X: north-east of its axis, at eye height, where its lectern's reader stands
	var chance: Vector3 = works["column_chance"].global_position
	await _shot(chance + Vector3(0.62, 0.0, -0.79) * 3.2 + Vector3(0.0, 1.65, 0.0), chance + Vector3(0.0, 1.5, 0.0), folder.path_join("chance_crossing.png"), 60.0)

	# ---- a body weaves through the triangle, past x -24 all the way ----
	await _place(-18.4, -11.6)
	var weave := await _path(_pts([[-22.0, -12.3], [-24.0, -11.6], [-26.0, -11.6], [-29.3, -12.4], [-28.8, -16.4], [-23.2, -16.6], [-19.4, -16.6]]))
	checks.append({"check": "a body walks in from the north slab, weaves through the triangle (west to x -29.3) and out, never sent back",
		"ok": weave.reached and weave.west <= -29.3 + 0.25 and not weave.sent_back, "walk": weave})     # 0.25: the walker turns that near a waypoint
	# ---- out of the passes' sine pass, through its mouth in the north face (z -8), into the triangle's base ----
	await _place(-26.8, -6.5)
	var from_passes := await _path(_pts([[-26.8, -8.6], [-27.0, -10.4], [-27.0, -12.0]]))
	checks.append({"check": "a body walks out of the passes' sine pass, through its north mouth, between the sine and the half-sine-half-chance columns",
		"ok": from_passes.reached and not from_passes.sent_back, "walk": from_passes})
	# ---- a column stops a body ----
	var target: Vector3 = works["column_sine_chance"].global_position
	await _place(target.x, target.z + 2.0)
	var into := await _path(_pts([[target.x, target.z]]), 0.6, 0.25, 600)
	var gap := Vector2(into.end.x, into.end.z).distance_to(Vector2(target.x, target.z))
	checks.append({"check": "a column stops a body that walks at it (the body's centre stays outside 0.675 + its radius)",
		"ok": not into.reached and gap > 0.8, "stopped_at": snappedf(gap, 0.01)})
	result["passed"] = checks.all(func(c): return c.ok)
	_finish(folder, result)


func _finish(folder: String, result: Dictionary) -> void:
	var file := FileAccess.open(folder.path_join("columns.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[iso_columns_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
