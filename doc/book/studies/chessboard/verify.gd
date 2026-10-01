extends SceneTree
## Headless checks for the Chessboard study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## It takes about a minute: the gap is measured with real drops of the marble,
## and a headless run keeps real time. Add --fixed-fps 60 and it takes seconds,
## with the same numbers.
## Headless draws no frames, so what the eye gets is measured by sheet.gd; here
## we check what the floor is made of (which scene each cube comes from, where
## each index puts it, how many materials and colliders it has), what the
## numbers in TUTORIAL.md claim (the four rules cell by cell, the marble on a
## solid cell and through the ghost, the gap that lets the marble pass), the
## steps of the process strip, and that the earlier studies still run.
## The last checks before the sheet's are of the guest in guests/: the body this
## chapter hands to the room, which has to stand on its own.

var checks := []
var measured := {}

const BOARD_AT := Vector3(-1.75, 0, -2.0)   # where Chessboard stands in the room
const N := 8
const SPACING := 0.5
const WIDTH := 0.5                          # the cube's edge
const RADIUS := 0.1                         # the marble's
const LIGHT := Color(0.62, 0.55, 0.4)
const DARK := Color(0.08, 0.16, 0.2)
const ORANGE := Color(0.62, 0.34, 0.12)     # the cube part's own material
const NAMES := ["every cell alike", "(x + z) % 2 chessboard", "x % 3 stripes", "hue from x + z"]
const GHOST := Vector2i(5, 5)
const TILE := Vector2i(320, 240)
const GUTTER := 4
const CheckGuest := preload("res://check_guest.gd")
const GUEST := "res://guests/chessboard/"       # the body this chapter hands to the room
const PLACE := 0.8                              # half the width of a place in the room

## Godot hands every message to a Logger. This one keeps the errors while the guest runs.
class Catcher extends Logger:
	var errors: Array[String] = []
	var lock := Mutex.new()   # messages can come from other threads

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		lock.lock()
		errors.append("%s (%s:%d)" % [rationale if rationale != "" else code, file, line])
		lock.unlock()

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print(("PASS " if passed else "FAIL ") + label)

func frames(count: int) -> void:
	for i in count:
		await process_frame

func settle(marble: RigidBody3D) -> Vector3:
	for i in 600:
		await physics_frame
		if i > 60 and marble.sleeping:
			break
	return marble.global_position

func near(a: Vector3, b: Vector3, slack := 0.0005) -> bool:
	return (a - b).length() < slack

func below(node: Node) -> int:
	return node.find_children("*", "", true, false).size()

## One study. `setup` is a dictionary of the board's variables to set before it
## is built; null takes the script off the board, for the steps built by hand.
func open(setup: Variant) -> Node3D:
	var study: Node3D = load("res://chessboard.tscn").instantiate()
	var board: Node3D = study.get_node("Chessboard")
	if setup == null:
		board.set_script(null)
	else:
		for key: String in setup:
			board.set(key, setup[key])
	root.add_child(study)
	await frames(2)
	await physics_frame
	study.set_process(false)
	study.get_node("B").set_process(false)
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

func cube_at(board: Node3D, x: int, z: int) -> MeshInstance3D:
	return board.get_child(z * N + x)

func shape_of(cube: Node) -> CollisionShape3D:
	return cube.get_node("Body/CollisionShape3D")

func materials(board: Node3D) -> Array:
	var seen := []
	for cube: MeshInstance3D in board.get_children():
		if not seen.has(cube.material_override):
			seen.append(cube.material_override)
	return seen

func colours(board: Node3D) -> Array:
	var seen := []
	for cube: MeshInstance3D in board.get_children():
		if not seen.has(cube.material_override.albedo_color):
			seen.append(cube.material_override.albedo_color)
	return seen

func colliders(board: Node3D) -> int:
	var enabled := 0
	for cube in board.get_children():
		if not shape_of(cube).disabled:
			enabled += 1
	return enabled

func count_colour(board: Node3D, colour: Color) -> int:
	var count := 0
	for cube: MeshInstance3D in board.get_children():
		if cube.material_override.albedo_color.is_equal_approx(colour):
			count += 1
	return count

func far_corner(board: Node3D) -> Vector3:
	var far := Vector3.ZERO
	for cube: Node3D in board.get_children():
		far = far.max(cube.position)
	return far

## What a step of the strip claims: cubes, nodes, materials, colours, colliders.
func counted(board: Node3D) -> Array:
	return [board.get_child_count(), below(board), materials(board).size(), colours(board).size(), colliders(board)]

func outward(cube: MeshInstance3D) -> int:
	var vs: PackedVector3Array = (cube.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var count := 0
	for t in vs.size() / 3:
		var plane := Plane(vs[t * 3], vs[t * 3 + 1], vs[t * 3 + 2])
		if plane.normal.dot((vs[t * 3] + vs[t * 3 + 1] + vs[t * 3 + 2]) / 3.0) > 0.0:
			count += 1
	return count

func ray_down(over: Vector3, marble: RigidBody3D) -> Array:
	var query := PhysicsRayQueryParameters3D.create(Vector3(over.x, 6.0, over.z), Vector3(over.x, -1.0, over.z))
	query.exclude = [marble.get_rid()]
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return ["nothing", 0.0]
	return [str(hit.collider.get_path()), hit.position.y]

func press(action: String, study: Node) -> void:
	await process_frame
	Input.action_press(action)
	study._process(0)
	Input.action_release(action)
	await process_frame

func last_line(study: Node) -> String:
	study._process(0)
	return study.get_node("Record").text.split("\n")[-1]

## One drop over the gap between cube 3 and cube 4 of row 4, as the lesson does it.
func trial(spacing: float, height: float) -> float:
	var study := await open({"spacing": spacing, "ghost_x": -1})
	var board: Node3D = study.get_node("Chessboard")
	var marble: RigidBody3D = study.get_node("Marble")
	marble.drop(board.to_global(Vector3(3.5 * spacing, height, 4 * spacing)))
	var at := await settle(marble)
	await close(study)
	return at.y

func passed_through(y: float) -> bool:
	return y < 0.15

## Widening: from a spacing that holds the marble, upward in steps, to the first that lets it pass.
func widen(from_mm: int, step_mm: int, height: float) -> int:
	var mm := from_mm
	while mm < 800 and not passed_through(await trial(mm / 1000.0, height)):
		mm += step_mm
	return mm

## Narrowing: from a spacing that lets it pass, downward in steps, to the last that still does.
func narrow(from_mm: int, step_mm: int, height: float) -> int:
	var mm := from_mm
	while mm > 500 and passed_through(await trial(mm / 1000.0, height)):
		mm -= step_mm
	return mm + step_mm

## Between a spacing that holds and one that passes, the first millimetre that passes.
func first_pass_mm(holds_mm: int, passes_mm: int, height: float) -> int:
	var low := holds_mm
	var high := passes_mm
	while high - low > 1:
		var middle := (low + high) / 2
		if passed_through(await trial(middle / 1000.0, height)):
			high = middle
		else:
			low = middle
	return high

## The box around every mesh of a body, in the room.
func box_of(body: Node3D) -> AABB:
	var box := AABB()
	var first := true
	var meshes: Array[Node] = body.find_children("*", "MeshInstance3D", true, false)
	meshes.append(body)
	for node in meshes:
		var mesh_node := node as MeshInstance3D
		if mesh_node == null or mesh_node.mesh == null:
			continue
		var own: AABB = mesh_node.global_transform * mesh_node.mesh.get_aabb()
		box = own if first else box.merge(own)
		first = false
	return box

## What a ray straight down from 2 m meets first: the height, or -1.0 for nothing.
func first_under(over: Vector3) -> float:
	var query := PhysicsRayQueryParameters3D.create(over, Vector3(over.x, -1.0, over.z))
	var hit := root.get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return -1.0
	return hit.position.y

## The guest: the one body this chapter hands to the room. The room copies its
## folder alone, so it has to load, run and stand on its own.
func guest_checks() -> void:
	var scene: Resource = load(GUEST + "chessboard.tscn")
	var guest: Node = null
	if scene is PackedScene and (scene as PackedScene).can_instantiate():
		guest = (scene as PackedScene).instantiate()
	check("the guest scene loads: guests/chessboard/chessboard.tscn, and its first node is a Node3D", guest is Node3D)
	var needs := CheckGuest.outside(GUEST)
	check("the guest names nothing outside its folder: %s" % [needs], needs.is_empty())
	var declared := CheckGuest.class_names(GUEST)
	check("the guest declares no class_name: %s" % [declared], declared.is_empty())
	if not guest is Node3D:
		check("the guest runs two frames and Godot logs no error (it did not load)", false)
		return
	var catcher := Catcher.new()
	OS.add_logger(catcher)
	root.add_child(guest)
	await frames(2)
	await physics_frame
	OS.remove_logger(catcher)
	check("the guest runs two frames and Godot logs no error: %s" % [catcher.errors], catcher.errors.is_empty())
	var board: Node3D = guest.get_node("Floor")
	var placed := board.get_child_count() == 16
	var from_folder := true
	var lime := 0
	var cyan := 0
	var seen := []
	for i in board.get_child_count():
		var cube: MeshInstance3D = board.get_child(i)
		@warning_ignore("integer_division")
		var cell := Vector2i(i % 4, i / 4)
		placed = placed and near(cube.global_position, Vector3((cell.x - 1.5) * 0.3, 0.15, (cell.y - 1.5) * 0.3)) and near(cube.get_aabb().size, Vector3(0.3, 0.3, 0.3))
		from_folder = from_folder and cube.scene_file_path == GUEST + "cube_part.tscn"
		var colour: String = cube.material_override.albedo_color.to_html(false)
		if colour == "c6ff3d" and (cell.x + cell.y) % 2 == 0:
			lime += 1
		if colour == "22d9ff" and (cell.x + cell.y) % 2 == 1:
			cyan += 1
		if not seen.has(cube.material_override):
			seen.append(cube.material_override)
	check("the guest is a small floor of cubes, four by four: 16 instances of the guest's own cube part, 0.3 m on an edge and 0.3 m apart, each with a material of its own, 8 in BODY c6ff3d where x + z is even and 8 in SECOND 22d9ff where it is odd",
		placed and from_folder and lime == 8 and cyan == 8 and seen.size() == 16)
	var ghost := Vector2i(board.ghost_x, board.ghost_z)
	var solid := 0
	var open_cells := []
	for z in 4:
		for x in 4:
			var top := first_under(Vector3((x - 1.5) * 0.3, 2.0, (z - 1.5) * 0.3))
			if absf(top - 0.3) < 0.001:
				solid += 1
			else:
				open_cells.append(Vector2i(x, z))
	check("one of the sixteen is a ghost: a ray straight down stops on 15 cells at 0.30 m and meets nothing over cell (%d, %d), which has its mesh and its colour" % [ghost.x, ghost.y],
		solid == 15 and open_cells == [ghost] and colliders(board) == 15 and (board.get_child(ghost.y * 4 + ghost.x) as MeshInstance3D).mesh != null)
	var box := box_of(guest as Node3D)
	check("the guest stands on the ground at its own origin and fits on a place, 1.6 m wide and deep: its box runs from (%.2f, %.2f, %.2f) to (%.2f, %.2f, %.2f)" % [
		box.position.x, box.position.y, box.position.z, box.end.x, box.end.y, box.end.z],
		absf(box.position.y) < 0.001 and box.position.x >= -PLACE and box.position.z >= -PLACE and box.end.x <= PLACE and box.end.z <= PLACE
		and near(box.get_center(), Vector3(0, 0.15, 0), 0.001))
	measured["guest"] = {"scene": GUEST + "chessboard.tscn", "cubes": board.get_child_count(), "ghost": [ghost.x, ghost.y],
		"box": [[snappedf(box.position.x, 0.001), snappedf(box.position.y, 0.001), snappedf(box.position.z, 0.001)], [snappedf(box.end.x, 0.001), snappedf(box.end.y, 0.001), snappedf(box.end.z, 0.001)]]}
	guest.free()
	await process_frame

func run() -> void:
	# The project and the Input Map: the nine actions of the earlier studies, unchanged.
	check("the project is named 'The Chessboard' and its main scene is chessboard.tscn",
		ProjectSettings.get_setting("application/config/name") == "The Chessboard"
		and ProjectSettings.get_setting("application/run/main_scene") == "res://chessboard.tscn")
	var wanted := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
		"pause": [KEY_SPACE], "close": [KEY_ENTER], "fill": [KEY_F], "drop": [KEY_M], "look": [KEY_V],
	}
	var actions_ok := true
	for action: String in wanted:
		var bound := []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					bound.append(event.physical_keycode)
		actions_ok = actions_ok and bound == wanted[action]
	check("the nine actions exist with their keys: A/D/W/S and the arrows, Space, Enter, F, M, V", actions_ok)

	# The earlier studies still run on their own.
	var lines: Node3D = load("res://line.tscn").instantiate()
	root.add_child(lines)
	await frames(2)
	var trace_study: Node3D = load("res://trace.tscn").instantiate()
	root.add_child(trace_study)
	await frames(2)
	var plane_study: Node3D = load("res://plane.tscn").instantiate()
	root.add_child(plane_study)
	await frames(2)
	check("line.tscn, trace.tscn and plane.tscn still run on their own: '1.50 m', '1 kept', 'open', and none of them has a Chessboard",
		lines.get_node("Readout").text == "1.50 m" and trace_study.get_node("Record").text.begins_with("1 kept")
		and plane_study.get_node("Record").text.contains("open") and not plane_study.has_node("Chessboard"))
	lines.free()
	trace_study.free()
	plane_study.free()
	var cube_study: Node3D = load("res://cube.tscn").instantiate()
	root.add_child(cube_study)
	await frames(2)
	var old_cube: MeshInstance3D = cube_study.get_node("Cube")
	check("cube.tscn still runs on its own: its Cube is an instance of the cube part at (1.05, 1.37, 0.6), 12 outward triangles, orange",
		old_cube.scene_file_path == "res://parts/cube_part.tscn" and old_cube.position.is_equal_approx(Vector3(1.05, 1.37, 0.6))
		and outward(old_cube) == 12 and old_cube.material_override.albedo_color.is_equal_approx(ORANGE))
	cube_study.free()
	var organism_study: Node3D = load("res://organism.tscn").instantiate()
	root.add_child(organism_study)
	organism_study.get_node("Organism").set_process(false)
	await frames(2)
	var organism: Node3D = organism_study.get_node("Organism")
	var lattice: Node3D = organism.get_node("Lattice")
	var lattice_meshes := []
	var lattice_cells := 0
	for child in lattice.get_children():
		if child is MeshInstance3D:
			lattice_cells += 1
			if not lattice_meshes.has(child.mesh):
				lattice_meshes.append(child.mesh)
	check("the organism's lattice is the same idea: %d cells from a loop inside a loop, sharing %d mesh with its one material" % [lattice_cells, lattice_meshes.size()],
		lattice_cells == 88 and lattice_meshes.size() == 1 and lattice.columns == 8 and lattice.rows == 11)
	while organism.angle < TAU:
		organism._process(1.0 / 60.0)
	check("organism.tscn still runs on its own: one whole turn of the limb still takes 33 cells: '%s'" % lattice.get_node("Count").text,
		lattice.lost.size() == 33 and lattice.get_node("Count").text == "55 of 88 cells")
	organism_study.free()
	var body_study: Node3D = load("res://body.tscn").instantiate()
	root.add_child(body_study)
	body_study.get_node("Body").set_process(false)
	await frames(2)
	var old_body: Node3D = body_study.get_node("Body")
	check("body.tscn still runs on its own: four pivots under the root, 25 nodes below it, the cube part among them",
		old_body.get_child_count() == 4 and below(old_body) == 25 and old_body.get_node("CubePivot/Cube").scene_file_path == "res://parts/cube_part.tscn"
		and not body_study.has_node("Chessboard"))
	body_study.free()
	await process_frame

	# The part this chapter repeats.
	var scene: PackedScene = load("res://parts/cube_part.tscn")
	var bench := Node3D.new()
	bench.name = "Bench"
	root.add_child(bench)
	var first: MeshInstance3D = scene.instantiate()
	var second: MeshInstance3D = scene.instantiate()
	bench.add_child(first)
	bench.add_child(second)
	await frames(2)
	check("the cube part is unchanged: it runs cube.gd, 12 outward triangles, 0.5 m on every edge, a Body with a shape of 12 triangles",
		first.get_script().resource_path == "res://cube.gd" and outward(first) == 12 and first.mesh.get_aabb().size.is_equal_approx(Vector3.ONE * WIDTH)
		and shape_of(first).shape is ConcavePolygonShape3D and (shape_of(first).shape as ConcavePolygonShape3D).get_faces().size() == 36)
	check("two instances are two nodes with two meshes and two shapes, and ONE material: the part's own, saved in its scene file",
		first != second and first.mesh != second.mesh and shape_of(first).shape != shape_of(second).shape
		and first.material_override == second.material_override and first.material_override.resource_path.begins_with("res://parts/cube_part.tscn::"))
	bench.free()
	await process_frame

	# The study: chessboard.tscn.
	var study := await open({})
	var board: Node3D = study.get_node("Chessboard")
	var marble: RigidBody3D = study.get_node("Marble")
	var b: Node3D = study.get_node("B")
	check("chessboard.tscn inherits plane.tscn: the root runs plane.gd, with A, B, Segment, Strip, Record, Face, Marble and Under; no Cube, no Organism, no Body",
		study.get_script().resource_path == "res://plane.gd" and study.has_node("A") and study.has_node("Segment") and study.has_node("Strip")
		and study.has_node("Record") and study.has_node("Face") and study.has_node("Under") and marble.get_script().resource_path == "res://marble.gd"
		and b.get_script().resource_path == "res://mover.gd" and not study.has_node("Cube") and not study.has_node("Organism") and not study.has_node("Body"))
	check("Chessboard is a plain Node3D on the ground at (-1.75, 0, -2) and runs chessboard.gd; it holds no node of its own in the scene file; the marble waits at (2.6, 0.1, 1.2), clear of the floor",
		board.get_class() == "Node3D" and near(board.position, BOARD_AT) and board.get_script().resource_path == "res://chessboard.gd"
		and board.find_children("*", "", true, true).is_empty() and near(marble.position, Vector3(2.6, 0.1, 1.2)))
	var all_parts: bool = board.get_child_count() == N * N and board.cubes.size() == N * N
	var placed := true
	for z in N:
		for x in N:
			var cube := cube_at(board, x, z)
			all_parts = all_parts and cube.scene_file_path == "res://parts/cube_part.tscn" and cube == board.cubes[z * N + x]
			placed = placed and near(cube.position, Vector3(x * SPACING, 0.25, z * SPACING))
	check("the floor is 64 instances of the cube part, kept in `cubes` in the order they were made; 192 nodes hang below the board", all_parts and below(board) == 192)
	check("index to position: the cube made at (x, z) stands at (x * 0.5, 0.25, z * 0.5) from the board, for all 64; x runs first: cube 1 is at x = 0.5, cube 8 starts the next row at z = 0.5",
		placed and near(board.cubes[1].position, Vector3(0.5, 0.25, 0)) and near(board.cubes[8].position, Vector3(0, 0.25, 0.5)) and near(board.cubes[63].position, Vector3(3.5, 0.25, 3.5)))
	var low := Vector3.ONE * 99.0
	var high := Vector3.ONE * -99.0
	for cube: MeshInstance3D in board.cubes:
		low = low.min(cube.to_global(Vector3.ONE * -0.25))
		high = high.max(cube.to_global(Vector3.ONE * 0.25))
	check("the floor is 4 m by 4 m and 0.5 m high: from (-2, 0, -2.25) to (2, 0.5, 1.75) in the room; A stands over cell (2, 4) and B over cell (5, 4)",
		near(low, Vector3(-2, 0, -2.25)) and near(high, Vector3(2, 0.5, 1.75)) and near(board.to_local(b.position), Vector3(2.5, 1.12, 2.0))
		and near(board.to_local(study.get_node("A").position), Vector3(1.0, 1.12, 2.0)))
	measured["floor"] = {"cubes": board.get_child_count(), "nodes_below_board": below(board), "materials": materials(board).size(), "colliders": colliders(board)}

	# The finished floor: the chessboard, one material a cube, one ghost.
	check("the finished floor is the chessboard: 64 materials made in code, 2 colours, 32 cells light and 32 dark; count_materials() says 64",
		materials(board).size() == 64 and board.count_materials() == 64 and colours(board).size() == 2
		and count_colour(board, LIGHT) == 32 and count_colour(board, DARK) == 32 and cube_at(board, 0, 0).material_override.albedo_color.is_equal_approx(LIGHT))
	var meshes := []
	var shapes := []
	var triangles := 0
	for cube: MeshInstance3D in board.cubes:
		if not meshes.has(cube.mesh):
			meshes.append(cube.mesh)
		if not shapes.has(shape_of(cube).shape):
			shapes.append(shape_of(cube).shape)
		triangles += (cube.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size() / 3
	check("what the floor adds: 192 nodes, 64 meshes of 12 triangles (768 in all), 64 shapes and 64 materials: nothing is shared but the scene file",
		meshes.size() == 64 and shapes.size() == 64 and triangles == 768 and below(board) == 192)
	measured["floor"]["meshes"] = meshes.size()
	measured["floor"]["shapes"] = shapes.size()
	measured["floor"]["triangles"] = triangles
	var ghost := cube_at(board, GHOST.x, GHOST.y)
	var disabled := []
	for z in N:
		for x in N:
			if shape_of(cube_at(board, x, z)).disabled:
				disabled.append(Vector2i(x, z))
	check("one cell is a ghost: the collider of cube (5, 5) is disabled and no other; it keeps its mesh, its shape and its colour, so the eye cannot find it",
		disabled == [GHOST] and colliders(board) == 63 and outward(ghost) == 12 and shape_of(ghost).shape != null
		and ghost.material_override.albedo_color.is_equal_approx(LIGHT) and ghost.visible)
	await physics_frame
	await physics_frame
	var over_solid := ray_down(cube_at(board, 5, 4).global_position, marble)
	var over_ghost := ray_down(ghost.global_position, marble)
	check("a ray sent down over cell (5, 4) meets that cube's Body at 0.5 m; over the ghost it meets the ground under the floor, at %.2f m" % over_ghost[1],
		over_solid[0] == str(cube_at(board, 5, 4).get_node("Body").get_path()) and absf(over_solid[1] - 0.5) < 0.001
		and over_ghost[0].ends_with("FloorBody") and absf(over_ghost[1]) < 0.001)
	await press("drop", study)
	var on_solid := await settle(marble)
	var solid_reads := last_line(study)
	check("M with B over cell (5, 4): the marble falls from one metre above B and rests on the cell: '%s'" % solid_reads,
		absf(on_solid.y - (0.5 + RADIUS)) < 0.02 and solid_reads == "marble at 0.60 m")
	b.position.z = 0.5
	await press("drop", study)
	var in_ghost := await settle(marble)
	var ghost_reads := last_line(study)
	check("B walked 0.5 m towards us, over cell (5, 5): the marble falls through the ghost to the ground and lies inside the cube: '%s'" % ghost_reads,
		absf(in_ghost.y - RADIUS) < 0.02 and ghost_reads == "marble at 0.10 m" and absf(in_ghost.x - 0.75) < 0.05 and absf(in_ghost.z - 0.5) < 0.05)
	measured["marble"] = {"on_a_solid_cell_m": snappedf(on_solid.y, 0.001), "through_the_ghost_m": snappedf(in_ghost.y, 0.001)}
	await close(study)

	# The lesson's first steps, built by hand on a bare board.
	study = await open(null)
	board = study.get_node("Chessboard")
	var one: MeshInstance3D = scene.instantiate()
	board.add_child(one)
	one.position = Vector3(0, 0.25, 0)
	check("one cube: 1 child, 3 nodes; it stands at (-1.75, 0.25, -2) in the room, on the ground, in the far left corner",
		counted(board) == [1, 3, 1, 1, 1] and near(one.global_position, Vector3(-1.75, 0.25, -2.0)))
	for x in range(1, N):
		var cube: MeshInstance3D = scene.instantiate()
		board.add_child(cube)
		cube.position = Vector3(x * SPACING, 0.25, 0)
	check("one loop, a row: 8 cubes, 24 nodes, the last at x = 3.5; still one material", counted(board) == [8, 24, 1, 1, 8] and near(far_corner(board), Vector3(3.5, 0.25, 0)))
	for z in range(1, N):
		for x in range(N):
			var cube: MeshInstance3D = scene.instantiate()
			board.add_child(cube)
			cube.position = Vector3(x * SPACING, 0.25, z * SPACING)
	check("the loop inside the loop, the floor: 64 cubes, 192 nodes, the last at (3.5, 0.25, 3.5); with no material code all 64 wear ONE material, the part's orange",
		counted(board) == [64, 192, 1, 1, 64] and near(far_corner(board), Vector3(3.5, 0.25, 3.5)) and colours(board)[0].is_equal_approx(ORANGE))
	# Shared against unique, measured.
	(board.get_child(0) as MeshInstance3D).material_override.albedo_color = DARK
	var stranger: MeshInstance3D = scene.instantiate()
	check("the part's material is shared: one cube's colour changed, and all 64 read the new colour; so does a cube instanced afterwards",
		count_colour(board, DARK) == 64 and stranger.material_override.albedo_color.is_equal_approx(DARK))
	stranger.free()
	(board.get_child(0) as MeshInstance3D).material_override.albedo_color = ORANGE
	var shared := StandardMaterial3D.new()
	shared.albedo_color = LIGHT
	for cube: MeshInstance3D in board.get_children():
		cube.material_override = shared
	var before := count_colour(board, LIGHT)
	(board.get_child(0) as MeshInstance3D).material_override.albedo_color = DARK
	check("one material made in code and given to every cube: 1 material; its colour changed once through cube 0, and all 64 changed",
		before == 64 and materials(board).size() == 1 and count_colour(board, DARK) == 64)
	for cube: MeshInstance3D in board.get_children():
		var own := StandardMaterial3D.new()
		own.albedo_color = LIGHT
		cube.material_override = own
	(board.get_child(0) as MeshInstance3D).material_override.albedo_color = DARK
	check("one material made for each cube: 64 materials; the same line changes cube 0 and no other: 1 dark, 63 light",
		materials(board).size() == 64 and count_colour(board, DARK) == 1 and count_colour(board, LIGHT) == 63)
	for cube: MeshInstance3D in board.get_children():
		cube.material_override = shared
	for cube: MeshInstance3D in board.get_children():
		cube.material_override = cube.material_override.duplicate()
	check("duplicate() gives each cube a copy of what it had: 64 materials again, one colour", materials(board).size() == 64 and colours(board).size() == 1)
	measured["materials"] = {"the_parts_own": 1, "one_made_before_the_loops": 1, "one_made_in_the_inner_loop": 64}
	await close(study)
	var fresh: MeshInstance3D = scene.instantiate()
	check("the part's material is orange again for whoever instances it next", fresh.material_override.albedo_color.is_equal_approx(ORANGE))
	fresh.free()

	# The four rules, cell by cell.
	var built := []
	var per_rule := true
	var rule_colours := []
	for r in NAMES.size():
		study = await open({"rhythm": r, "ghost_x": -1})
		board = study.get_node("Chessboard")
		var grid := []
		for z in N:
			for x in N:
				var colour: Color = cube_at(board, x, z).material_override.albedo_color
				grid.append(colour)
				per_rule = per_rule and colour.is_equal_approx(board.colour_of(x, z))
		built.append(grid)
		rule_colours.append(colours(board).size())
		per_rule = per_rule and materials(board).size() == 64 and colliders(board) == 64 and board.get_child_count() == 64
		await close(study)
	check("each value of `rhythm` builds the same 64 cubes with 64 materials and 64 colliders, and every cube wears what colour_of(x, z) returns; %d, %d, %d and %d colours" % rule_colours,
		per_rule and rule_colours == [1, 2, 2, 15])
	var alike_ok := true
	var chess_ok := true
	var stripes_ok := true
	var hue_ok := true
	var neighbours := 0
	var dark_stripes := 0
	for z in N:
		for x in N:
			var i := z * N + x
			alike_ok = alike_ok and built[0][i].is_equal_approx(LIGHT)
			chess_ok = chess_ok and built[1][i].is_equal_approx(LIGHT if (x + z) % 2 == 0 else DARK)
			if x + 1 < N and not built[1][i].is_equal_approx(built[1][i + 1]):
				neighbours += 1
			if z + 1 < N and not built[1][i].is_equal_approx(built[1][i + N]):
				neighbours += 1
			stripes_ok = stripes_ok and built[2][i].is_equal_approx(DARK if x % 3 == 0 else LIGHT) and built[2][i].is_equal_approx(built[2][x])
			if built[2][i].is_equal_approx(DARK):
				dark_stripes += 1
			hue_ok = hue_ok and built[3][i].is_equal_approx(Color.from_hsv((x + z) / 16.0, 0.8, 0.6))
	check("0 every cell alike: all 64 are the light colour", alike_ok)
	check("1 chessboard: light where (x + z) % 2 is 0, dark where it is 1; all 112 pairs of side-by-side cells differ", chess_ok and neighbours == 112)
	check("2 stripes: dark where x % 3 is 0: columns 0, 3 and 6, 24 cells dark and 40 light; z does not enter the rule", stripes_ok and dark_stripes == 24)
	check("3 hue: Color.from_hsv(float(x + z) / (2 * n), 0.8, 0.6): 15 values of x + z, from 0 to 14, so 15 colours; a hue step is 1/16 of the circle", hue_ok)
	# The planted mistake: the same expression in whole numbers.
	var whole := []
	var with_float := []
	for z in N:
		for x in N:
			@warning_ignore("integer_division")
			var hue := (x + z) / (2 * N)
			if not whole.has(hue):
				whole.append(hue)
			var repaired := float(x + z) / (2 * N)
			if not with_float.has(repaired):
				with_float.append(repaired)
	check("the planted mistake: (x + z) / (2 * n) in whole numbers is 0 for every cell, so every cell is Color.from_hsv(0, 0.8, 0.6), red (0.6, 0.12, 0.12); with float() there are 15 values, up to 0.875",
		whole == [0] and with_float.size() == 15 and is_equal_approx(with_float.max(), 0.875) and Color.from_hsv(0, 0.8, 0.6).is_equal_approx(Color(0.6, 0.12, 0.12)))
	# Which rules have a direction: swap x and z, and turn the floor half round.
	var swapped := []
	var turned := []
	for r in NAMES.size():
		var s := 0
		var t := 0
		for z in N:
			for x in N:
				if not built[r][z * N + x].is_equal_approx(built[r][x * N + z]):
					s += 1
				if not built[r][z * N + x].is_equal_approx(built[r][(N - 1 - z) * N + (N - 1 - x)]):
					t += 1
		swapped.append(s)
		turned.append(t)
	check("swap x and z and %d, %d, %d and %d cells change colour; turn the floor half round and %d, %d, %d and %d do: the stripes and the hue ramp both have a direction, the other two have none" % (swapped + turned),
		swapped == [0, 0, 30, 0] and turned == [0, 0, 48, 56])
	measured["cells_changed_by_swapping_x_and_z"] = swapped
	measured["cells_changed_by_a_half_turn"] = turned
	# Equal steps of hue are not equal steps of light.
	var brightness := []
	for k in 15:
		brightness.append(snappedf(Color.from_hsv(k / 16.0, 0.8, 0.6).get_luminance(), 0.001))
	var yellow := Color.from_hsv(1.0 / 6.0, 0.8, 0.6).get_luminance()
	var blue := Color.from_hsv(2.0 / 3.0, 0.8, 0.6).get_luminance()
	check("equal steps of hue are not equal steps of light: the 15 bands' luminance runs from %.3f (band %d) to %.3f (band %d); pure yellow has %.3f and pure blue %.3f, %.1f times less" % [
		brightness.min(), brightness.find(brightness.min()), brightness.max(), brightness.find(brightness.max()), yellow, blue, yellow / blue],
		brightness.find(brightness.max()) == 3 and brightness.find(brightness.min()) == 11 and yellow / blue > 3.0)
	measured["hue_band_luminance"] = brightness
	measured["yellow_over_blue_luminance"] = snappedf(yellow / blue, 0.01)

	# A gap you can see and cannot pass.
	study = await open({})
	marble = study.get_node("Marble")
	var diameter: float = 2.0 * (marble.get_node("CollisionShape3D").shape as SphereShape3D).radius
	await close(study)
	var held := await trial(0.55, 2.0)
	var through := await trial(0.75, 2.0)
	check("the gap is g = s - w with w = 0.5 m, and the marble is d = %.1f m across, so g = d at s = 0.70; at s = 0.55 the marble rests on the two cubes (%.2f m), at s = 0.75 it lies on the ground (%.2f m)" % [diameter, held, through],
		is_equal_approx(diameter, 0.2) and held > 0.5 and passed_through(through))
	var fast_up := await widen(650, 10, 2.0)
	var fast_down := await narrow(710, 10, 2.0)
	var fast := await first_pass_mm(fast_up - 10, fast_up, 2.0)
	var stuck := await trial(0.65, 2.0)
	check("dropped from 2 m: widening, the first spacing that passes is 0.%d; narrowing, the last that passes is 0.%d; to the millimetre it is 0.%d, a gap of %.3f m, %.3f m less than the marble; at s = 0.65 the marble is neither on top nor through: it ends at %.2f m" % [
		fast_up, fast_down, fast, fast / 1000.0 - WIDTH, WIDTH + diameter - fast / 1000.0, stuck],
		fast_up == fast_down and fast >= 660 and fast < 700 and stuck > 0.15 and stuck < 0.5)
	var slow_up := await widen(680, 10, 0.75)
	var slow_down := await narrow(720, 10, 0.75)
	var slow := await first_pass_mm(slow_up - 10, slow_up, 0.75)
	check("let go at 0.75 m: widening and narrowing agree again, at 0.%d; to the millimetre the first spacing that passes is 0.%d: g = d, as predicted, within %d mm" % [slow_up, slow, absi(slow - 700) + 1],
		slow_up == slow_down and slow >= 695 and slow <= 705)
	measured["gap"] = {
		"cube_width_m": WIDTH, "marble_diameter_m": diameter, "predicted_first_passing_spacing_m": WIDTH + diameter,
		"dropped_from_2_m": {"widening_first_pass_m": fast_up / 1000.0, "narrowing_last_pass_m": fast_down / 1000.0, "first_pass_to_the_mm_m": fast / 1000.0, "rest_height_at_0_65_m": snappedf(stuck, 0.001)},
		"let_go_at_0_75_m": {"widening_first_pass_m": slow_up / 1000.0, "narrowing_last_pass_m": slow_down / 1000.0, "first_pass_to_the_mm_m": slow / 1000.0},
		"rest_height_at_0_55_m": snappedf(held, 0.001), "rest_height_at_0_75_m": snappedf(through, 0.001),
		"physics_ticks_per_second": Engine.physics_ticks_per_second,
	}

	# The process strip, step by step, as sheet.gd photographs it.
	study = await open(null)
	board = study.get_node("Chessboard")
	var strip_counts := []
	for z in N:
		for x in N:
			if (z == 0 and x == 1) or (z == 1 and x == 0):
				strip_counts.append(counted(board))
			var cube: MeshInstance3D = scene.instantiate()
			board.add_child(cube)
			cube.position = Vector3(x * SPACING, 0.25, z * SPACING)
	strip_counts.append(counted(board))
	await close(study)
	check("strip 1 to 3, one cube, a row, the floor: 1, 8 and 64 cubes; 3, 24 and 192 nodes; 1, 8 and 64 colliders; one material and one colour throughout",
		strip_counts == [[1, 3, 1, 1, 1], [8, 24, 1, 1, 8], [64, 192, 1, 1, 64]])
	var corners := []
	for setup: Dictionary in [{"rhythm": 1, "ghost_x": -1}, {"rhythm": 3, "ghost_x": -1}, {"rhythm": 3}, {"rhythm": 3, "spacing": 0.6}]:
		study = await open(setup)
		board = study.get_node("Chessboard")
		strip_counts.append(counted(board))
		corners.append(far_corner(board))
		await close(study)
	check("strip 4, two colours: still 64 cubes; 64 materials where there was 1, and 2 colours", strip_counts[3] == [64, 192, 64, 2, 64])
	check("strip 5, hue by index: 64 materials still, and 15 colours where there were 2", strip_counts[4] == [64, 192, 64, 15, 64])
	check("strip 6, a ghost cell: 63 colliders where there were 64; cubes, nodes, materials and colours as before", strip_counts[5] == [64, 192, 64, 15, 63])
	check("strip 7, spacing opened to 0.6: nothing is added or removed; the far corner cube goes from (3.5, 3.5) to (4.2, 4.2), seven times the change",
		strip_counts[6] == [64, 192, 64, 15, 63] and near(corners[2], Vector3(3.5, 0.25, 3.5)) and near(corners[3], Vector3(4.2, 0.25, 4.2)))
	measured["strip"] = strip_counts

	# process.png and sheet.png, read back tile by tile.
	var strip := Image.load_from_file(ProjectSettings.globalize_path("res://process.png"))
	var bytes := FileAccess.get_file_as_bytes("res://process.png").size()
	check("process.png is there: 7 tiles of 320 x 240 with a band of names under them, %d bytes" % bytes,
		strip != null and strip.get_width() == 7 * TILE.x + 6 * GUTTER and strip.get_height() > TILE.y and bytes < 300000)
	if strip != null:
		var tiles := []
		for i in 7:
			tiles.append(strip.get_region(Rect2i(i * (TILE.x + GUTTER), 0, TILE.x, TILE.y)))
		var shares := []
		for i in range(1, 7):
			shares.append(differ_pct(tiles[i], tiles[i - 1]))
		check("in process.png every tile differs from the one before it (%.2f, %.2f, %.2f, %.2f%% of the tile), except 'a ghost cell', which differs from 'hue by index' on %.2f%%; opening the spacing then changes %.2f%%" % shares,
			shares[0] > 1.0 and shares[1] > 1.0 and shares[2] > 1.0 and shares[3] > 1.0 and shares[4] == 0.0 and shares[5] > 1.0)
		measured["process_png"] = {"bytes": bytes, "tile_differs_from_the_one_before_pct": shares}
	var four := Image.load_from_file(ProjectSettings.globalize_path("res://sheet.png"))
	check("sheet.png is there: the four values of `rhythm` side by side, 4 tiles of 320 x 240, %d bytes" % FileAccess.get_file_as_bytes("res://sheet.png").size(),
		four != null and four.get_width() == 4 * TILE.x + 3 * GUTTER and FileAccess.get_file_as_bytes("res://sheet.png").size() < 300000)

	# The guest handed to the room.
	await guest_checks()

	# The sheet's record, if it has been rendered.
	if FileAccess.file_exists("res://sheet.json"):
		var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sheet.json"))
		measured["sheet"] = sheet
		sheet_checks(sheet)

	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Chessboard study: ", checks.size(), " checks; passed=", passed)
	quit(0 if passed else 1)

func changed(p: Color, q: Color) -> bool:
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.1

func differ_pct(a: Image, b: Image) -> float:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			if changed(a.get_pixel(x, y), b.get_pixel(x, y)):
				count += 1
	return snappedf(100.0 * count / float(a.get_width() * a.get_height()), 0.01)

func sheet_checks(sheet: Dictionary) -> void:
	var same := true
	var colours_ok := true
	for v in 4:
		var entry: Dictionary = sheet.get(str(v), {})
		same = (same and int(entry.get("cubes", 0)) == 64 and int(entry.get("materials", 0)) == 64
			and entry.get("floor_share_above_pct", -1.0) == sheet.get("0", {}).get("floor_share_above_pct", -2.0)
			and entry.get("floor_share_top_pct", -1.0) == sheet.get("0", {}).get("floor_share_top_pct", -2.0))
		colours_ok = colours_ok and int(entry.get("colours", 0)) == [1, 2, 2, 15][v]
	var share_above: float = sheet.get("0", {}).get("floor_share_above_pct", 0.0)
	var share_top: float = sheet.get("0", {}).get("floor_share_top_pct", 0.0)
	check("sheet.json: the four floors are the same 64 cubes with 64 materials, on the same %.2f%% of the frame from above and %.2f%% from the top; they show 1, 2, 2 and 15 colours" % [share_above, share_top],
		same and colours_ok and share_above > 20.0 and share_top > 30.0)
	var above: Dictionary = sheet.get("pairs_above_pct", {})
	var top: Dictionary = sheet.get("pairs_top_pct", {})
	check("sheet.json: cell by cell the closest pair is 'every cell alike' and the stripes, from above (%.2f%% of the frame) and from the top (%.2f%%): 24 of 64 cells, three eighths of the floor" % [above.get("0 vs 2", 0.0), top.get("0 vs 2", 0.0)],
		sheet.get("closest_pair_above", "") == "0 vs 2" and sheet.get("closest_pair_top", "") == "0 vs 2"
		and absf(above.get("0 vs 2", 0.0) / share_above - 0.375) < 0.02 and absf(top.get("0 vs 2", 0.0) / share_top - 0.375) < 0.02)
	check("sheet.json: the chessboard and the stripes are not the closest pair: they differ on %.2f%% of the frame from above, about half the floor, like 'every cell alike' and the chessboard (%.2f%%)" % [above.get("1 vs 2", 0.0), above.get("0 vs 1", 0.0)],
		above.get("1 vs 2", 0.0) > above.get("0 vs 2", 100.0) * 1.2 and absf(above.get("1 vs 2", 0.0) / share_above - 0.5) < 0.04
		and absf(above.get("0 vs 1", 0.0) / share_above - 0.5) < 0.04 and top.get("1 vs 2", 0.0) > top.get("0 vs 2", 100.0) * 1.2)
	var whole_floor := true
	for key: String in ["0 vs 3", "1 vs 3", "2 vs 3"]:
		whole_floor = whole_floor and absf(above.get(key, 0.0) - share_above) < 0.6 and absf(top.get(key, 0.0) - share_top) < 0.6
	check("sheet.json: the hue ramp differs from each of the other three on the whole floor: %.2f%% of the frame from above" % above.get("0 vs 3", 0.0), whole_floor)
	var tones: Dictionary = sheet.get("tones_apart_above", {})
	check("sheet.json: by average colour the order turns round: the chessboard and the stripes are the closest pair, %.2f apart from above, and 'every cell alike' and the chessboard the farthest, %.2f" % [tones.get("1 vs 2", 0.0), tones.get("0 vs 1", 0.0)],
		sheet.get("closest_tone_above", "") == "1 vs 2" and sheet.get("closest_tone_top", "") == "1 vs 2" and tones.size() == 6 and tones.values().max() == tones.get("0 vs 1", 0.0))
	var strip: Array = sheet.get("strip", [])
	var wanted := [[1, 3, 1, 1, 1], [8, 24, 1, 1, 8], [64, 192, 1, 1, 64], [64, 192, 64, 2, 64], [64, 192, 64, 15, 64], [64, 192, 64, 15, 63], [64, 192, 64, 15, 63]]
	var counts_ok := strip.size() == 7
	if counts_ok:
		for i in 7:
			var got := [int(strip[i]["cubes"]), int(strip[i]["nodes_below_board"]), int(strip[i]["materials"]), int(strip[i]["colours"]), int(strip[i]["colliders"])]
			counts_ok = counts_ok and got == wanted[i]
	check("sheet.json: with a window the strip's seven steps counted what they count headless: 1, 8, 64 cubes; 1, 1, 1, 64 materials; 2, then 15 colours; 64, then 63 colliders", counts_ok)
	check("sheet.json: the step that changed the picture most was '%s'; 'a ghost cell' changed it on %.2f%% of the tile" % [sheet.get("strip_step_that_changed_most", ""), strip[5]["differs_from_step_before_pct"] if counts_ok else -1.0],
		counts_ok and strip[5]["differs_from_step_before_pct"] == 0.0 and sheet.get("strip_step_that_changed_most", "") == "7 spacing opened")
	var calls := []
	if counts_ok:
		for i in 7:
			calls.append(int(strip[i]["draw_calls"]))
	var empty_calls := int(sheet.get("empty", {}).get("draw_calls", -1))
	check("sheet.json: what the floor costs to draw, from the strip's camera with the light's shadow on: %d draw calls without it, %d with one cube, %d with a row, %d with the floor: 5 a cube; one material or 64, the count is the same" % [
		empty_calls, calls[0] if counts_ok else -1, calls[1] if counts_ok else -1, calls[2] if counts_ok else -1],
		counts_ok and calls[0] - empty_calls == 5 and calls[1] - empty_calls == 40 and calls[2] - empty_calls == 320 and calls[3] == calls[2] and calls[4] == calls[2])
	var top_empty := int(sheet.get("empty_top", {}).get("draw_calls", -1))
	var top_floor := int(sheet.get("1", {}).get("drawn_top", {}).get("draw_calls", -1))
	check("sheet.json: from the top camera, with no shadow, the floor costs 1 draw call a cube: %d without it, %d with it" % [top_empty, top_floor], top_empty >= 0 and top_floor - top_empty == 64)
	var bands: Dictionary = sheet.get("3", {}).get("bands_top", {})
	var steps: Array = bands.get("step_to_next", [])
	check("sheet.json: equal steps of hue are unequal steps on the screen: from the top the smallest step between two bands is %.1f, between bands 2 and 3, either side of yellow, and the largest %.1f; the blue bands stand %.1f and %.1f apart" % [
		steps.min() if steps.size() == 14 else -1.0, steps.max() if steps.size() == 14 else -1.0, steps[10] if steps.size() == 14 else -1.0, steps[11] if steps.size() == 14 else -1.0],
		steps.size() == 14 and int(bands.get("smallest_step_from_band", -1)) == 2 and steps.max() > 1.2 * steps.min() and steps[10] > steps[2] and steps[11] > steps[2])
