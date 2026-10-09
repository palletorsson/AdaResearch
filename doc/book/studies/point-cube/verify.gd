extends SceneTree
## Headless checks for the Point Cube study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## Headless draws no frames, so what the eye gets is measured by sheet.gd instead;
## here we check what a cube is made of (corners, triples, the direction every
## triangle faces) and what a body can feel (the collider and a dropped marble).
## The run prints one SCRIPT ERROR and one ERROR on purpose: the first answer's
## own fault, and our loop's message about it. Each is announced first.
## The last checks before the sheet's are of the guest in guests/: the body this
## chapter hands to the room, which has to stand on its own.

var checks := []
var measured := {}

const RADIUS := 0.1                     # the marble's radius
const HEIGHT := 1.12                    # the height B walks at: the cube's bottom
const SIZE := 0.5                       # the cube's edge
const TOP := HEIGHT + SIZE              # 1.62
const AT := Vector3(1.05, 1.37, 0.6)    # where the Cube node stands: the cube's middle
const OVER := Vector3(0.1, 0.75, -0.1)  # the drop: above the top, away from its diagonal
const NAMES := ["my one face", "one-line draft", "three-line draft", "repaired"]
const REPAIRED := [
	[4, 7, 5], [5, 7, 6], [1, 2, 0], [0, 2, 3], [0, 3, 4], [4, 3, 7],
	[5, 6, 1], [1, 6, 2], [2, 6, 3], [3, 6, 7], [0, 4, 1], [1, 4, 5],
]
const CheckGuest := preload("res://check_guest.gd")
const GUEST := "res://guests/point-cube/"   # the body this chapter hands to the room
const PLACE := 0.8                          # half the width of a place in the room

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

## Let the marble fall and come to rest: up to four seconds of physics.
func settle(marble: RigidBody3D) -> Vector3:
	for i in 240:
		await physics_frame
		if i > 30 and marble.sleeping:
			break
	return marble.position

func key_names(codes: Array) -> String:
	return ", ".join(codes.map(func(c): return OS.get_keycode_string(c)))

## Press a named action for one call of the root's _process, then let the frame end.
func press(action: String, study: Node) -> void:
	await process_frame
	Input.action_press(action)
	study._process(0)
	Input.action_release(action)
	await process_frame

## One study with the cube built from one value of `draft`.
func open(value: int) -> Node3D:
	var study: Node3D = load("res://cube.tscn").instantiate()
	study.get_node("Cube").draft = value
	root.add_child(study)
	await frames(2)
	await physics_frame
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

func vertices_of(cube: MeshInstance3D) -> PackedVector3Array:
	if cube.mesh == null:
		return PackedVector3Array()
	return (cube.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func normals_of(cube: MeshInstance3D) -> PackedVector3Array:
	return (cube.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_NORMAL]

## Which way every triangle of the mesh faces. Godot draws the side from which the
## corners run clockwise, and Plane(a, b, c).normal points to that side. A triangle
## faces outward when that normal points away from the cube's middle, which is the
## Cube node's own origin: dot(normal, centroid - middle) > 0.
func facing(cube: MeshInstance3D) -> Dictionary:
	var vs := vertices_of(cube)
	var result := {"outward": 0, "inward": 0, "flat": 0, "inward_on": [], "toward": {}}
	for t in vs.size() / 3:
		var a := vs[t * 3]
		var b := vs[t * 3 + 1]
		var c := vs[t * 3 + 2]
		if (b - a).cross(c - a).length() < 0.000001:
			result["flat"] += 1
			continue
		var normal := Plane(a, b, c).normal
		var centroid := (a + b + c) / 3.0
		var key := str(normal.round())
		if normal.dot(centroid - Vector3.ZERO) > 0.0:
			result["outward"] += 1
			result["toward"][key] = result["toward"].get(key, 0) + 1
		else:
			result["inward"] += 1
			result["inward_on"].append(centroid)
	return result

func size_of(cube: MeshInstance3D) -> Vector3:
	return cube.mesh.get_aabb().size

## The guest: the one body this chapter hands to the room. The room copies its
## folder alone, so it has to load, run and stand on its own. It is checked far
## from where the studies stood.
func guest_checks() -> void:
	var scene: Resource = load(GUEST + "point-cube.tscn")
	var guest: Node = null
	if scene is PackedScene and (scene as PackedScene).can_instantiate():
		guest = (scene as PackedScene).instantiate()
	check("the guest scene loads: guests/point-cube/point-cube.tscn, and its first node is a Node3D", guest is Node3D)
	var needs := CheckGuest.outside(GUEST)
	check("the guest names nothing outside its folder: %s" % [needs], needs.is_empty())
	var declared := CheckGuest.class_names(GUEST)
	check("the guest declares no class_name: %s" % [declared], declared.is_empty())
	if not guest is Node3D:
		check("the guest runs two frames and Godot logs no error (it did not load)", false)
		return
	var at := Vector3(40, 0, 40)
	(guest as Node3D).position = at
	var catcher := Catcher.new()
	OS.add_logger(catcher)
	root.add_child(guest)
	await frames(2)
	await physics_frame
	OS.remove_logger(catcher)
	check("the guest runs two frames and Godot logs no error: %s" % [catcher.errors], catcher.errors.is_empty())
	var cube: MeshInstance3D = guest.get_node("Cube")
	if cube.mesh == null:
		check("the guest is the repaired cube (it has no mesh)", false)
		guest.free()
		return
	var f := facing(cube)
	var shape := cube.get_node("Body/CollisionShape3D").shape as ConcavePolygonShape3D
	check("the guest is the repaired cube: the guest's own script holds the repaired list, its 12 triangles all face outward, it is 0.5 m on every edge and painted BODY c6ff3d; its Body is a trimesh of the same 12 triangles, backface collision left off",
		cube.get_script().resource_path == GUEST + "point-cube.gd" and cube.triangles == REPAIRED
		and f["outward"] == 12 and f["inward"] == 0 and f["flat"] == 0 and size_of(cube).is_equal_approx(Vector3(SIZE, SIZE, SIZE))
		and cube.material_override.albedo_color.to_html(false) == "c6ff3d"
		and shape != null and shape.get_faces().size() == 36 and not shape.backface_collision)
	var box: AABB = cube.global_transform * cube.mesh.get_aabb()
	box.position -= at
	check("the guest stands on the ground at its own origin and fits on a place, 1.6 m wide and deep: its box runs from (%.2f, %.2f, %.2f) to (%.2f, %.2f, %.2f)" % [
		box.position.x, box.position.y, box.position.z, box.end.x, box.end.y, box.end.z],
		absf(box.position.y) < 0.001 and box.position.x >= -PLACE and box.position.z >= -PLACE and box.end.x <= PLACE and box.end.z <= PLACE
		and (box.get_center() - Vector3(0, SIZE / 2.0, 0)).length() < 0.001)
	var space := root.get_world_3d().direct_space_state
	var from_above: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0.1, 2, -0.1), at + Vector3(0.1, 0.25, -0.1)))
	var from_inside: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3(0.1, 0.25, -0.1), at + Vector3(0.1, 2, -0.1)))
	check("a ray from above meets the guest's top at 0.50 m, and a ray from its middle upward meets nothing: the body has the eye's side, as in the lesson",
		from_above.has("position") and absf(from_above["position"].y - SIZE) < 0.001 and from_inside.is_empty())
	measured["guest"] = {"scene": GUEST + "point-cube.tscn", "triangles_outward": f["outward"],
		"box": [[snappedf(box.position.x, 0.001), snappedf(box.position.y, 0.001), snappedf(box.position.z, 0.001)], [snappedf(box.end.x, 0.001), snappedf(box.end.y, 0.001), snappedf(box.end.z, 0.001)]]}
	guest.free()
	await process_frame

func run() -> void:
	# The Input Map: the nine actions of the Plane study, unchanged.
	var wanted := {
		"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT],
		"move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
		"pause": [KEY_SPACE], "close": [KEY_ENTER], "fill": [KEY_F], "drop": [KEY_M], "look": [KEY_V],
	}
	for action: String in wanted:
		var bound := []
		if InputMap.has_action(action):
			for event in InputMap.action_get_events(action):
				if event is InputEventKey:
					bound.append(event.physical_keycode)
		check("action %s exists, bound to %s" % [action, key_names(wanted[action])], bound == wanted[action])

	# The earlier studies are carried unchanged and still run on their own.
	var lines: Node3D = load("res://line.tscn").instantiate()
	root.add_child(lines)
	await frames(2)
	check("line.tscn still runs on its own: readout 1.50 m", lines.get_node("Readout").text == "1.50 m")
	lines.free()
	var trace_study: Node3D = load("res://trace.tscn").instantiate()
	root.add_child(trace_study)
	await frames(2)
	check("trace.tscn still runs on its own: 1 kept", trace_study.get_node("Record").text.begins_with("1 kept"))
	trace_study.free()
	var plane_study: Node3D = load("res://plane.tscn").instantiate()
	root.add_child(plane_study)
	await frames(2)
	check("plane.tscn still runs on its own: open, no face, no cube",
		plane_study.get_node("Record").text.contains("open") and plane_study.get_node("Face").mesh == null
		and not plane_study.has_node("Cube"))
	plane_study.free()

	# The scene inherits Plane and adds the cube and its body.
	var study := await open(3)
	var cube: MeshInstance3D = study.get_node("Cube")
	var shape_node: CollisionShape3D = cube.get_node("Body/CollisionShape3D")
	var marble: RigidBody3D = study.get_node("Marble")
	var b: Node3D = study.get_node("B")
	check("the root still runs plane.gd; A, B, Segment, Strip, Record, Face, FaceBody, Marble and Under are inherited",
		study.get_script().resource_path == "res://plane.gd" and study.has_node("A") and study.has_node("Segment")
		and study.has_node("Strip") and study.has_node("Record") and study.has_node("Face")
		and study.has_node("FaceBody/CollisionShape3D") and study.has_node("Under")
		and marble.get_script().resource_path == "res://marble.gd"
		and b.get_script().resource_path == "res://mover.gd")
	check("the plane is still to be walked: 1 kept, open, Face has no mesh",
		study.get_node("Record").text.begins_with("1 kept") and study.get_node("Record").text.contains("open")
		and study.get_node("Face").mesh == null)
	check("Cube is a MeshInstance3D running cube.gd, with a material and a Body of its own",
		cube.get_script().resource_path == "res://cube.gd" and cube.material_override != null
		and cube.get_node("Body") is StaticBody3D)
	var untouched: Node3D = load("res://cube.tscn").instantiate()
	check("Cube stands at (1.05, 1.37, 0.6); draft is 3, repaired, unless the Inspector says otherwise",
		cube.position.is_equal_approx(AT) and untouched.get_node("Cube").draft == 3)
	untouched.free()

	# The body: 8 corners, 12 triples, 36 indices.
	var corners: Array[Vector3] = cube.corners
	var triangles: Array = cube.triangles
	check("8 corners", corners.size() == 8)
	var combos := {}
	for corner in corners:
		combos[corner] = true
		if not (is_equal_approx(absf(corner.x), 0.25) and is_equal_approx(absf(corner.y), 0.25) and is_equal_approx(absf(corner.z), 0.25)):
			combos["bad"] = true
	check("the corners are the eight combinations of -0.25 and 0.25: a cube of 0.5 m around the node's origin",
		combos.size() == 8 and not combos.has("bad"))
	check("corner 0 is bottom back left and corner 6 is top front right, the hall's numbering",
		corners[0].is_equal_approx(Vector3(-0.25, -0.25, -0.25)) and corners[6].is_equal_approx(Vector3(0.25, 0.25, 0.25))
		and corners[4].is_equal_approx(Vector3(-0.25, -0.25, 0.25)) and corners[7].is_equal_approx(Vector3(-0.25, 0.25, 0.25)))
	check("12 triangles", triangles.size() == 12)
	var indices := []
	for triangle in triangles:
		indices.append_array(triangle)
	var uses := {}
	for index in indices:
		uses[index] = uses.get(index, 0) + 1
	check("36 indices, each from 0 to 7, every corner used (4, 5 or 6 times)",
		indices.size() == 36 and indices.min() == 0 and indices.max() == 7 and uses.size() == 8
		and uses.values().min() >= 4 and uses.values().max() <= 6)
	check("the triples are the repaired list, front face first", triangles == REPAIRED)
	var mesh := cube.mesh as ArrayMesh
	var vs := vertices_of(cube)
	check("the mesh is one surface of triangles with 36 vertices: 12 x 3 calls of add_vertex()",
		mesh != null and mesh.get_surface_count() == 1 and mesh.surface_get_primitive_type(0) == Mesh.PRIMITIVE_TRIANGLES
		and vs.size() == 36)
	var emitted := true
	for t in 12:
		for k in 3:
			emitted = emitted and vs[t * 3 + k].is_equal_approx(corners[triangles[t][k]])
	check("vertex 3t + k of the mesh is corners[triangles[t][k]]: the loop emits the list in order", emitted)
	var f := facing(cube)
	check("repaired: every one of the 12 triangles faces outward: dot(normal, centroid - middle) > 0",
		f["outward"] == 12 and f["inward"] == 0 and f["flat"] == 0)
	check("repaired: two triangles face each of the six directions",
		f["toward"].size() == 6 and f["toward"].values().min() == 2 and f["toward"].values().max() == 2)
	var shared := true
	for face in 6:
		var first: Array = triangles[face * 2]
		var second: Array = triangles[face * 2 + 1]
		var common := 0
		for index in first:
			if second.has(index):
				common += 1
		shared = shared and common == 2
	check("each face is two triples that share two corners: a diagonal", shared)
	var ns := normals_of(cube)
	var flat_normals := ns.size() == 36
	for t in 12:
		var plane := Plane(vs[t * 3], vs[t * 3 + 1], vs[t * 3 + 2])
		for k in 3:
			flat_normals = flat_normals and plane.normal.dot(ns[t * 3 + k]) > 0.999
	check("normals: one per vertex, each the direction its own triangle faces (flat, smooth group -1)", flat_normals)
	check("the cube is 0.5 m on every edge and stands at the height of the walk: from 1.12 m to 1.62 m",
		size_of(cube).is_equal_approx(Vector3(SIZE, SIZE, SIZE))
		and is_equal_approx(cube.position.y - SIZE / 2.0, HEIGHT) and is_equal_approx(cube.position.y + SIZE / 2.0, TOP))
	var shape := shape_node.shape as ConcavePolygonShape3D
	check("Body's shape is a trimesh of the same 12 triangles, backface collision left off: the body shares the eye's side",
		shape != null and shape.get_faces().size() == 36 and not shape.backface_collision)

	# The marble on the repaired cube.
	marble.drop(AT + OVER)
	var rest := await settle(marble)
	check("repaired: a marble dropped over the top rests ON it: %.3f m (top 1.62 + radius), still over the cube" % rest.y,
		absf(rest.y - (TOP + RADIUS)) < 0.02 and absf(rest.x - AT.x) < 0.25 and absf(rest.z - AT.z) < 0.25)
	measured["marble_on_repaired_m"] = snappedf(rest.y, 0.001)
	marble.drop(AT + Vector3(0, 0.75, 0))
	rest = await settle(marble)
	check("repaired: dropped over the middle of the top, it rests there too: %.3f m" % rest.y, absf(rest.y - (TOP + RADIUS)) < 0.02)
	marble.drop(AT + Vector3(0.6, 0.75, 0))
	rest = await settle(marble)
	check("dropped beside the cube, the marble falls past it to the floor: %.3f m" % rest.y, rest.y < 0.2)
	# The top is two triangles for a body too: its diagonal runs from corner 3 to corner 6.
	var seam := Vector3(-0.1, 0.75, -0.05)   # 3.5 cm from that diagonal
	marble.drop(AT + seam)
	rest = await settle(marble)
	check("repaired: dropped 3.5 cm from the top's diagonal, the marble rolls off the top and ends on the floor: %.3f m" % rest.y, rest.y < 0.2)
	shape.backface_collision = true
	await physics_frame
	marble.drop(AT + seam)
	rest = await settle(marble)
	check("the same drop with backface_collision on stays on the top: %.3f m" % rest.y, absf(rest.y - (TOP + RADIUS)) < 0.02)
	shape.backface_collision = false
	await physics_frame
	study.set_process(false)
	b.set_process(false)
	b.position = Vector3(AT.x + OVER.x, HEIGHT, AT.z + OVER.z)
	await press("drop", study)
	check("the drop key puts the marble one metre above B, with B under the cube",
		absf(marble.position.x - b.position.x) < 0.01 and absf(marble.position.z - b.position.z) < 0.01 and marble.position.y > HEIGHT + 0.9)
	rest = await settle(marble)
	check("and it comes to rest on the cube above B: %.3f m" % rest.y, absf(rest.y - (TOP + RADIUS)) < 0.02)

	# The cube on a walked plane: D, S, A, W around it, Enter, F.
	var loop: Array[Vector3] = [Vector3(0.75, HEIGHT, 0.0), Vector3(1.95, HEIGHT, 0.0), Vector3(1.95, HEIGHT, 1.2), Vector3(0.75, HEIGHT, 1.2)]
	study.trace = loop
	await press("close", study)
	await press("fill", study)
	var face: MeshInstance3D = study.get_node("Face")
	var inside := true
	for corner in corners:
		var p := cube.position + corner
		inside = inside and p.x > 0.75 and p.x < 1.95 and p.z > 0.0 and p.z < 1.2
	check("a walk D, S, A, W from B's start closes around the cube: the plane has 2 triangles and the cube's bottom lies on it at 1.12 m",
		study.closed and face.mesh != null and face.mesh.get_faces().size() == 6 and inside)
	marble.drop(AT + Vector3(0.45, 0.75, 0.0))
	rest = await settle(marble)
	check("beside the cube and inside the walk, the marble now rests on the plane: %.3f m" % rest.y, absf(rest.y - (HEIGHT + RADIUS)) < 0.02)
	await close(study)

	# The first answer, as it came back: drafted_cube.gd.
	var answer: MeshInstance3D = load("res://drafted_cube.gd").new()
	var drafted: Array = answer.triangles
	var drafted_corners: Array[Vector3] = answer.corners
	answer.free()
	check("first answer: the corners are ours, untouched (line 2 of the instruction was kept)", drafted_corners == corners)
	check("first answer: the two front triples are ours, untouched", drafted[0] == REPAIRED[0] and drafted[1] == REPAIRED[1])
	var differing := []
	for t in 12:
		if drafted[t] != REPAIRED[t]:
			differing.append(t)
	check("first answer: 12 triples, and four of them differ from the repair: 3, 8, 9 and 11", drafted.size() == 12 and differing == [3, 8, 9, 11])
	check("first answer, triple 3 is [0, 2, 8]: it asks for a ninth corner", drafted[3] == [0, 2, 8])
	check("first answer, triples 8 and 9 are the top face in the other order: [2, 3, 6] and [3, 7, 6]",
		drafted[8] == [2, 3, 6] and drafted[9] == [3, 7, 6])
	check("first answer, triple 11 is [1, 5, 5]: one corner twice", drafted[11] == [1, 5, 5])
	print("(expected below: one SCRIPT ERROR, 'Invalid access of index '8'', from the first answer run as it came back)")
	var raw_study: Node3D = load("res://cube.tscn").instantiate()
	raw_study.get_node("Cube").set_script(load("res://drafted_cube.gd"))
	root.add_child(raw_study)
	await frames(2)
	var raw_cube: MeshInstance3D = raw_study.get_node("Cube")
	check("first answer run as it came back: build() stops at triple 3, so there is no mesh and no collider",
		raw_cube.mesh == null and raw_cube.get_node("Body/CollisionShape3D").shape == null)
	await close(raw_study)

	# The second answer: drafted_vague.gd.
	answer = load("res://drafted_vague.gd").new()
	var vague: Array = answer.triangles
	var vague_corners: Array[Vector3] = answer.corners
	answer.free()
	var doubled := vague_corners.size() == 8
	for i in mini(8, vague_corners.size()):
		doubled = doubled and vague_corners[i].is_equal_approx(corners[i] * 2.0)
	check("second answer: 8 corners in the same order, each twice as far from the middle: a cube of 1 m", doubled)
	check("second answer: 12 triples, and our front triples are not among them",
		vague.size() == 12 and not vague.has(REPAIRED[0]) and not vague.has(REPAIRED[1]))

	# The axis: one fresh study for each value of `draft`.
	var ends := []
	for v in 4:
		if v == 2:
			print("(expected below: ERROR 'triangle 3 asks for a corner that is not there', our loop reading the first answer)")
		study = await open(v)
		cube = study.get_node("Cube")
		marble = study.get_node("Marble")
		f = facing(cube)
		vs = vertices_of(cube)
		var summary := "%d triangles: %d outward, %d inward, %d without area" % [vs.size() / 3, f["outward"], f["inward"], f["flat"]]
		if v == 0:
			var front := vs.size() == 6
			for vertex in vs:
				front = front and is_equal_approx(vertex.z, 0.25)
			check("draft 0 %s: %s; both are the front face" % [NAMES[v], summary], front and f["outward"] == 2 and f["toward"].get("(0.0, 0.0, 1.0)", 0) == 2)
		if v == 1:
			check("draft 1 %s: %s; a cube of 1 m" % [NAMES[v], summary],
				vs.size() == 36 and f["inward"] == 12 and f["outward"] == 0 and size_of(cube).is_equal_approx(Vector3(1, 1, 1)))
		if v == 2:
			check("draft 2 %s: %s; triple 3 was skipped by our loop" % [NAMES[v], summary],
				vs.size() == 33 and f["outward"] == 8 and f["inward"] == 2 and f["flat"] == 1 and size_of(cube).is_equal_approx(Vector3(SIZE, SIZE, SIZE)))
			check("draft 2: the two inward triangles are the top face (their middles lie at the top, y = 0.25), and no other face is inside out",
				f["inward_on"].size() == 2 and f["inward_on"].all(func(middle): return is_equal_approx(middle.y, 0.25)))
			check("draft 2: the back and the bottom each keep one triangle of two", f["toward"].get("(0.0, 0.0, -1.0)", 0) == 1 and f["toward"].get("(0.0, -1.0, 0.0)", 0) == 1)
		if v == 3:
			check("draft 3 %s: %s" % [NAMES[v], summary], vs.size() == 36 and f["outward"] == 12)
		marble.drop(AT + OVER)
		rest = await settle(marble)
		ends.append(rest)
		measured["marble_draft_%d" % v] = [snappedf(rest.x, 0.001), snappedf(rest.y, 0.001), snappedf(rest.z, 0.001)]
		if v == 2:
			# On a walked plane the marble goes through the cube and is caught under it.
			var around: Array[Vector3] = [Vector3(0.75, HEIGHT, 0.0), Vector3(1.95, HEIGHT, 0.0), Vector3(1.95, HEIGHT, 1.2), Vector3(0.75, HEIGHT, 1.2)]
			study.set_process(false)
			study.trace = around
			await press("close", study)
			await press("fill", study)
			marble.drop(AT + OVER)
			var caught := await settle(marble)
			check("draft 2 on a walked plane: the marble falls through the top and the bottom and rests on the plane inside the cube: %.3f m" % caught.y,
				absf(caught.y - (HEIGHT + RADIUS)) < 0.02 and absf(caught.x - AT.x) < 0.25 and absf(caught.z - AT.z) < 0.25)
			# The instrument can be blinded: a collider with a back holds a body on an inside-out face.
			(cube.get_node("Body/CollisionShape3D").shape as ConcavePolygonShape3D).backface_collision = true
			await physics_frame
			marble.drop(AT + OVER)
			var blind := await settle(marble)
			check("draft 2 with backface_collision switched on: the marble rests on the inside-out top at %.3f m, and no longer finds the fault" % blind.y,
				absf(blind.y - (TOP + RADIUS)) < 0.02)
		await close(study)
	check("draft 0: there is no top, and the marble falls to the floor: %.3f m" % ends[0].y, ends[0].y < 0.2)
	check("draft 1: the marble falls in and stays in: it rests at %.3f m, on the inside of the bottom, 0.87 m + radius" % ends[1].y,
		absf(ends[1].y - (AT.y - 0.5 + RADIUS)) < 0.02 and absf(ends[1].x - AT.x) < 0.5 and absf(ends[1].z - AT.z) < 0.5)
	check("draft 2: the marble falls through the top and out through the bottom, to the floor: %.3f m" % ends[2].y, ends[2].y < 0.2)
	check("draft 3: the marble rests on top: %.3f m" % ends[3].y, absf(ends[3].y - (TOP + RADIUS)) < 0.02)

	# The guest handed to the room.
	await guest_checks()

	# The sheet's record, if it has been rendered.
	if FileAccess.file_exists("res://sheet.json"):
		var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sheet.json"))
		for view in ["above", "below", "behind"]:
			measured["sheet_" + view] = {}
			for v in 4:
				measured["sheet_" + view][NAMES[v]] = sheet.get("%d_%s" % [v, view], {})
			measured["sheet_pairs_%s_pct" % view] = sheet.get("pairs_%s_pct" % view, {})
			measured["sheet_closest_pair_" + view] = sheet.get("closest_pair_" + view, "")
		sheet_checks(sheet)

	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Cube study: ", checks.size(), " checks; passed=", passed)
	quit(0 if passed else 1)

func sheet_checks(sheet: Dictionary) -> void:
	var share := func(value: int, view: String) -> float:
		return sheet.get("%d_%s" % [value, view], {}).get("cube_share_pct", -1.0)
	check("sheet.json: from above the closest pair is my one face and the three-line draft; from below and from behind it is the three-line draft and the repair",
		sheet.get("closest_pair_above", "") == "0 vs 2" and sheet.get("closest_pair_below", "") == "2 vs 3"
		and sheet.get("closest_pair_behind", "") == "2 vs 3")
	check("sheet.json: the three-line draft shows less cube than the repair from above, from below and from behind: a face or half a face is missing each time",
		share.call(2, "above") < share.call(3, "above") - 0.3 and share.call(2, "below") < share.call(3, "below") - 0.3
		and share.call(2, "behind") < share.call(3, "behind") - 0.3 and share.call(2, "above") > 0.0)
	check("sheet.json: the one-line draft covers more than three times the frame the repair covers, from every standpoint",
		share.call(1, "above") > 3.0 * share.call(3, "above") and share.call(1, "below") > 3.0 * share.call(3, "below")
		and share.call(1, "behind") > 3.0 * share.call(3, "behind"))
	check("sheet.json: my one face shows from above and from below and is absent from behind",
		share.call(0, "above") > 0.3 and share.call(0, "below") > 0.3 and share.call(0, "behind") < 0.1)
	check("sheet.json: the same face in the hall's order is absent from above and shows from behind",
		sheet.get("hall_face_above", {}).get("cube_share_pct", 100.0) < 0.1 and sheet.get("hall_face_behind", {}).get("cube_share_pct", 0.0) > 1.0)
	check("sheet.json: smooth normals change the repaired cube on more than 0.3% of the frame; on a plane they changed nothing",
		sheet.get("smooth_vs_flat_above_pct", 0.0) > 0.3)
	var ends := []
	for v in 4:
		ends.append(sheet.get("marble_%d" % v, {}).get("rest", [0, -1, 0])[1])
	check("sheet.json: with a window the marble ends where it ends headless: floor, inside, floor, on top",
		ends[0] < 0.2 and ends[0] > 0.0 and absf(ends[1] - 0.97) < 0.02 and ends[2] < 0.2 and ends[2] > 0.0 and absf(ends[3] - (TOP + RADIUS)) < 0.02)
	check("sheet.json: on a walked plane the cube shows from below as much as without one: the plane is not drawn from below",
		absf(sheet.get("on_plane_below", {}).get("cube_share_pct", -9.0) - share.call(3, "below")) < 0.2)
