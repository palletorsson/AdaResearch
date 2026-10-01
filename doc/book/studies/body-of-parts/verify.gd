extends SceneTree
## Headless checks for the Body of Parts study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## Headless draws no frames, so what the eye gets is measured by sheet.gd; here
## we check what the body is made of (which scene each part comes from, who is
## whose parent at each value of `parenting`), what the numbers in TUTORIAL.md
## claim (where the parts are at rest and after a turn, worked out by hand), the
## steps of the process strip, and that the earlier studies still run now that
## their branches are instances of the part scenes.
## The last checks before the sheet's are of the guest in guests/: the body this
## chapter hands to the room, which has to stand on its own.
## One ERROR is printed on purpose: the planted mistake. The line before it says so.

var checks := []
var measured := {}

const ROOT_AT := Vector3(0, 0, 0.9)             # where Body stands in the room
const AT := {                                   # where each pivot stands, in the body's numbers
	"point": Vector3(-0.8, 0.075, 0.0), "plane": Vector3(-0.2, 0.02, 0.0),
	"cube": Vector3(0.55, 0.25, 0.0), "limb": Vector3(0.55, 0.25, 0.25),
}
const WALK_MIDDLE := Vector3(1.2, 1.12, 0.45)   # the middle of the saved walk, in its own numbers
const SHIFT := Vector3(-0.25, 0, 0)             # the offset of value 2
const KINDS := ["point", "plane", "cube", "limb"]
const NAMES := ["flat", "a chain", "a chain with offset pivots", "two chains from one hip"]
const TOE := Vector3(0, -0.13, 0.9)             # the toe, seen from the limb's own origin
const RADIUS := 0.1                             # the marble's radius
const TILE := Vector2i(320, 240)
const GUTTER := 4
const CheckGuest := preload("res://check_guest.gd")
const GUEST := "res://guests/body-of-parts/"    # the body this chapter hands to the room
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
	for i in 300:
		await physics_frame
		if i > 30 and marble.sleeping:
			break
	return marble.position

func key_names(codes: Array) -> String:
	return ", ".join(codes.map(func(c): return OS.get_keycode_string(c)))

func near(a: Vector3, b: Vector3, slack := 0.0005) -> bool:
	return (a - b).length() < slack

func rounded(v: Vector3) -> Array:
	return [snappedf(v.x, 0.001), snappedf(v.y, 0.001), snappedf(v.z, 0.001)]

func child_names(node: Node) -> Array:
	return node.get_children().map(func(c): return str(c.name))

func below(node: Node) -> int:
	return node.find_children("*", "", true, false).size()

func part(body: Node, name: String) -> Node3D:
	return body.find_child(name, true, false)

## One study with the body built from one value of `parenting`. The body does
## not run by itself: this script sets its pose or calls its _process.
func open(value: int) -> Node3D:
	var study: Node3D = load("res://body.tscn").instantiate()
	study.get_node("Body").parenting = value
	root.add_child(study)
	study.get_node("Body").set_process(false)
	await frames(2)
	await physics_frame
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

## Every node below the body with where it is in the room.
func snapshot(body: Node) -> Dictionary:
	var result := {}
	for node: Node in body.find_children("*", "", true, false):
		if node is Node3D:
			result[str(body.get_path_to(node))] = (node as Node3D).global_transform
	return result

func moved(before: Dictionary, after: Dictionary) -> Array:
	var result := []
	for path: String in before:
		if not (before[path] as Transform3D).is_equal_approx(after[path]):
			result.append(path)
	result.sort()
	return result

## Every node below the body with where it is in the room, named so that the
## name does not depend on the parenting: a pivot by its own name, any other
## node by its path from its part.
func in_the_room(body: Node) -> Dictionary:
	var result := {}
	for pivot: Node3D in body.pivots:
		result[str(pivot.name)] = pivot.global_transform
		var whole: Node3D = pivot.get_child(0)
		result[str(whole.name)] = whole.global_transform
		for node: Node in whole.find_children("*", "", true, false):
			result[str(whole.name) + "/" + str(whole.get_path_to(node))] = (node as Node3D).global_transform
	return result

## A node and everything below it, as paths from the body.
func branch(body: Node, node: Node) -> Array:
	var result := [str(body.get_path_to(node))]
	for child: Node in node.find_children("*", "", true, false):
		if child is Node3D:
			result.append(str(body.get_path_to(child)))
	result.sort()
	return result

## Seven places on the body, in the room, as the lesson's numbers put them at rest.
func rest_places() -> Dictionary:
	return {
		"point": ["point", ROOT_AT + AT["point"]],
		"plane middle": ["plane", ROOT_AT + AT["plane"]],
		"plane corner": ["plane", ROOT_AT + AT["plane"] + Vector3(-0.45, 0, -0.45)],
		"cube": ["cube", ROOT_AT + AT["cube"]],
		"cube corner 6": ["cube", ROOT_AT + AT["cube"] + Vector3(0.25, 0.25, 0.25)],
		"hip": ["limb", ROOT_AT + AT["limb"]],
		"toe": ["limb", ROOT_AT + AT["limb"] + TOE],
	}

## The same seven places read from the nodes.
func places(body: Node) -> Dictionary:
	var plane := part(body, "Plane")
	var cube := part(body, "Cube")
	var limb := part(body, "Limb")
	return {
		"point": part(body, "Point").global_position,
		"plane middle": plane.to_global(WALK_MIDDLE),
		"plane corner": plane.to_global(Vector3(0.75, 1.12, 0.0)),
		"cube": cube.global_position,
		"cube corner 6": cube.to_global(Vector3(0.25, 0.25, 0.25)),
		"hip": limb.global_position,
		"toe": part(body, "Toe").global_position,
	}

func pivot_rest(kind: String, value: int) -> Vector3:
	return ROOT_AT + AT[kind] + (SHIFT if value == 2 else Vector3.ZERO)

## The pivots that command a part, its own first, then its parent's, up to the root.
func commanders(kind: String, value: int) -> Array:
	if value == 0:
		return [kind]
	if value == 3:
		return {"plane": ["plane"], "point": ["point", "plane"], "cube": ["cube"], "limb": ["limb", "cube"]}[kind]
	var list := []
	for i in range(KINDS.find(kind), -1, -1):
		list.append(KINDS[i])
	return list

## A turn by `a` about the upright line through `centre`: +z goes towards +x.
func turn_about(p: Vector3, centre: Vector3, a: float) -> Vector3:
	var d := p - centre
	return centre + Vector3(d.x * cos(a) + d.z * sin(a), d.y, -d.x * sin(a) + d.z * cos(a))

## Where a place ends when every pivot is turned by `a`, worked out by hand.
func by_hand(place: Array, value: int, a: float) -> Vector3:
	var p: Vector3 = place[1]
	for kind: String in commanders(place[0], value):
		p = turn_about(p, pivot_rest(kind, value), a)
	return p

func turn_pivots(body: Node, degrees: float) -> void:
	for pivot: Node3D in body.pivots:
		pivot.rotation.y = deg_to_rad(degrees)

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

## Lowest point on the ground, and inside the dark square of a place.
func on_a_place(box: AABB) -> bool:
	return (absf(box.position.y) < 0.001 and box.position.x >= -PLACE and box.position.z >= -PLACE
		and box.end.x <= PLACE and box.end.z <= PLACE)

## The guest: the one body this chapter hands to the room. The room copies its
## folder alone, so it has to load, run and stand on its own.
func guest_checks() -> void:
	var scene: Resource = load(GUEST + "body-of-parts.tscn")
	var guest: Node = null
	if scene is PackedScene and (scene as PackedScene).can_instantiate():
		guest = (scene as PackedScene).instantiate()
	check("the guest scene loads: guests/body-of-parts/body-of-parts.tscn, and its first node is a Node3D", guest is Node3D)
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
	OS.remove_logger(catcher)
	check("the guest runs two frames and Godot logs no error: %s" % [catcher.errors], catcher.errors.is_empty())
	guest.set_process(false)
	var colours := {}
	var from_folder := true
	for pivot: Node3D in guest.pivots:
		var whole: Node3D = pivot.get_child(0)
		from_folder = from_folder and whole.scene_file_path.begins_with(GUEST)
		colours[str(whole.name)] = (whole as MeshInstance3D).material_override.albedo_color.to_html(false)
	var bars := 0
	for bar: MeshInstance3D in guest.find_children("Bar", "MeshInstance3D", true, false):
		if bar.material_override.albedo_color.to_html(false) == "ff8b1f":
			bars += 1
	check("the guest is the body of parts: four pivots under one root and 25 nodes below it, every part a scene of the guest's own folder, each in one colour of the look: the point BONE, the plane SECOND, the cube BODY, the limb and its three bars THIRD: %s" % [colours],
		guest.get_child_count() == 4 and below(guest) == 25 and from_folder and bars == 3 and colours.size() == 4
		and colours.get("Point") == "f4efe6" and colours.get("Plane") == "22d9ff" and colours.get("Cube") == "c6ff3d" and colours.get("Limb") == "ff8b1f")
	for pivot: Node3D in guest.pivots:
		pivot.rotation.y = 0.0
	guest.angle = 0.0
	var rest_box := box_of(guest as Node3D)
	for i in 72:
		guest._process(1.0 / 60.0)
	var turned_box := box_of(guest as Node3D)
	check("the guest stands on the ground at its own origin and fits on a place, 1.6 m wide and deep: at rest its box runs from %s to %s, and with every pivot turned 30 degrees from %s to %s" % [
		rounded(rest_box.position), rounded(rest_box.end), rounded(turned_box.position), rounded(turned_box.end)],
		on_a_place(rest_box) and on_a_place(turned_box) and is_equal_approx(guest.angle, deg_to_rad(30.0)))
	measured["guest"] = {"scene": GUEST + "body-of-parts.tscn", "box_at_rest": [rounded(rest_box.position), rounded(rest_box.end)],
		"box_turned": [rounded(turned_box.position), rounded(turned_box.end)], "colours": colours}
	guest.free()
	await process_frame

func run() -> void:
	# The project and the Input Map: the nine actions of the earlier studies, unchanged.
	check("the project is named 'A Body of Parts' and its main scene is body.tscn",
		ProjectSettings.get_setting("application/config/name") == "A Body of Parts"
		and ProjectSettings.get_setting("application/run/main_scene") == "res://body.tscn")
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

	# The four part scenes.
	var scenes := {}
	var loaded := true
	for kind: String in KINDS:
		scenes[kind] = load("res://parts/" + kind + "_part.tscn")
		loaded = loaded and scenes[kind] is PackedScene
	check("each of the four part scenes loads as a PackedScene: point, plane, cube, limb", loaded)
	var loose: Node3D = scenes["cube"].instantiate()
	var twin: Node3D = scenes["cube"].instantiate()
	check("instantiate() gives a new node every time: two instances of the cube part are two nodes",
		loose != twin and loose.name == "Cube" and twin.name == "Cube" and loose.scene_file_path == "res://parts/cube_part.tscn")
	check("an instance that was never added is not in the tree, and its _ready() has not run: the cube has no mesh yet",
		not loose.is_inside_tree() and loose.get_parent() == null and (loose as MeshInstance3D).mesh == null)
	loose.free()
	twin.free()
	var bench := Node3D.new()
	bench.name = "Bench"
	root.add_child(bench)
	var parts := {}
	for kind: String in KINDS:
		parts[kind] = scenes[kind].instantiate()
		bench.add_child(parts[kind])
	await frames(2)
	check("added to the tree, each part is one child of its parent, named Point, Plane, Cube and Limb", child_names(bench) == ["Point", "Plane", "Cube", "Limb"])
	check("the parts bring 1, 3, 3 and 14 nodes: the point alone; the plane and the cube with a Body and a shape; the limb with thirteen nodes below it",
		below(parts["point"]) == 0 and below(parts["plane"]) == 2 and below(parts["cube"]) == 2 and below(parts["limb"]) == 13)
	var point_mesh: Mesh = (parts["point"] as MeshInstance3D).mesh
	check("the point part is the sphere of the earlier studies: 0.075 m in radius, no script", point_mesh is SphereMesh
		and is_equal_approx((point_mesh as SphereMesh).radius, 0.075) and parts["point"].get_script() == null)
	var cube_part: MeshInstance3D = parts["cube"]
	check("the cube part runs cube.gd, unchanged: 8 corners, 12 outward triangles, 0.5 m on every edge, a Body with a shape",
		cube_part.get_script().resource_path == "res://cube.gd" and cube_part.corners.size() == 8 and outward(cube_part) == 12
		and cube_part.mesh.get_aabb().size.is_equal_approx(Vector3(0.5, 0.5, 0.5))
		and cube_part.get_node("Body/CollisionShape3D").shape is ConcavePolygonShape3D)
	var limb_part: Node3D = parts["limb"]
	var bars: Array = [limb_part.get_node("Upper/Bar"), limb_part.get_node("Upper/Lower/Bar"), limb_part.get_node("Upper/Lower/Foot/Bar")]
	var bars_ok := true
	for bar: MeshInstance3D in bars:
		bars_ok = (bars_ok and bar.scene_file_path == "res://parts/cube_part.tscn" and bar.get_script().resource_path == "res://cube.gd"
			and bar.scale.is_equal_approx(Vector3(0.16, 0.16, 0.6)) and outward(bar) == 12 and bar.owner == limb_part)
	check("the limb part is a scene made of scenes: its three bars are instances of the cube part, each scaled (0.16, 0.16, 0.6)", bars_ok)
	check("the limb's chain is Limb > Upper > Lower > Foot > Toe, with no joint scaled; the toe hangs at (0, -0.13, 0.9) from the hip",
		limb_part.get_node("Upper/Lower/Foot/Toe") != null and limb_part.get_node("Upper").scale.is_equal_approx(Vector3.ONE)
		and limb_part.get_node("Upper/Lower").scale.is_equal_approx(Vector3.ONE)
		and near(limb_part.to_local(limb_part.get_node("Upper/Lower/Foot/Toe").global_position), TOE))
	check("who owns whom: Upper's owner is the Limb, a bar's Body's owner is the Bar, and a part added by code has no owner",
		limb_part.get_node("Upper").owner == limb_part and limb_part.get_node("Upper/Bar/Body").owner == limb_part.get_node("Upper/Bar")
		and limb_part.owner == null)
	var plane_part: MeshInstance3D = parts["plane"]
	var walk: ArrayMesh = plane_part.mesh
	var walk_vs: PackedVector3Array = walk.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var walk_ns: PackedVector3Array = walk.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]
	var with_area := 0
	var facing_up := 0
	var area := 0.0
	for t in walk_vs.size() / 3:
		var size := 0.5 * (walk_vs[t * 3 + 1] - walk_vs[t * 3]).cross(walk_vs[t * 3 + 2] - walk_vs[t * 3]).length()
		area += size
		if size > 0.000001:
			with_area += 1
			if walk_ns[t * 3].dot(Vector3.UP) > 0.999 and Plane(walk_vs[t * 3], walk_vs[t * 3 + 1], walk_vs[t * 3 + 2]).normal.dot(Vector3.UP) > 0.999:
				facing_up += 1
	check("the plane part's mesh is the saved walk, parts/walk.tres: 28 triangles, %d of them with area, each of those clockwise from above with its normal up; %.2f square metres" % [with_area, area],
		walk.resource_path == "res://parts/walk.tres" and walk_vs.size() == 84 and with_area == 16 and facing_up == 16 and absf(area - 0.80) < 0.01)
	measured["walk"] = {"triangles": walk_vs.size() / 3, "with_area": with_area, "square_metres": snappedf(area, 0.001)}
	var box := plane_part.get_aabb()
	check("the walk keeps its own numbers: it begins at (0.75, 1.12, 0) and is 0.9 m wide and 0.9 m deep, so its middle is (1.2, 1.12, 0.45)",
		near(box.position, Vector3(0.75, 1.12, 0.0)) and near(box.size, Vector3(0.9, 0.0, 0.9), 0.001) and near(box.get_center(), WALK_MIDDLE, 0.001))
	var plane_shape: Shape3D = plane_part.get_node("Body/CollisionShape3D").shape
	check("plane_part.gd gives the plane its body from the mesh: a shape of 28 triangles, solid from both sides",
		plane_shape is ConcavePolygonShape3D and (plane_shape as ConcavePolygonShape3D).get_faces().size() == 84
		and (plane_shape as ConcavePolygonShape3D).backface_collision)
	bench.free()
	await process_frame

	# The saved walk is the walk Plane's recorder makes: D, S, A, W, closed and filled.
	var plane_study: Node3D = load("res://plane.tscn").instantiate()
	root.add_child(plane_study)
	await frames(2)
	check("plane.tscn still runs on its own: open, no face, no cube",
		plane_study.get_node("Record").text.contains("open") and plane_study.get_node("Face").mesh == null and not plane_study.has_node("Cube"))
	plane_study.set_process(false)
	var walker: Node3D = plane_study.get_node("B")
	walker.set_process(false)
	var at := walker.position
	var legs := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(-1, 0, 0), Vector3(0, 0, -1)]
	for k in 4:
		for i in (40 if k == 3 else 45):
			at += legs[k] * 0.02
			walker.position = at
			plane_study._process(1.0 / 60.0)
	await press("close", plane_study)
	await press("fill", plane_study)
	var walked: PackedVector3Array = plane_study.get_node("Face").mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var same_walk := walked.size() == walk_vs.size()
	if same_walk:
		for i in walked.size():
			same_walk = same_walk and walked[i].is_equal_approx(walk_vs[i])
	check("walk.tres is what plane.gd builds from a walk of D, S, A, W, 0.9 m each: %s" % plane_study.status(),
		same_walk and plane_study.status() == "closed, 3.51 m around, 28 triangles")
	plane_study.free()

	# The earlier studies still run, now that their branches are instances of the parts.
	var lines: Node3D = load("res://line.tscn").instantiate()
	root.add_child(lines)
	await frames(2)
	check("line.tscn still runs on its own: readout 1.50 m; its A is an instance of the point part",
		lines.get_node("Readout").text == "1.50 m" and lines.get_node("A").scene_file_path == "res://parts/point_part.tscn")
	lines.free()
	var trace_study: Node3D = load("res://trace.tscn").instantiate()
	root.add_child(trace_study)
	await frames(2)
	check("trace.tscn still runs on its own: 1 kept", trace_study.get_node("Record").text.begins_with("1 kept"))
	trace_study.free()
	var cube_study: Node3D = load("res://cube.tscn").instantiate()
	root.add_child(cube_study)
	await frames(2)
	var old_cube: MeshInstance3D = cube_study.get_node("Cube")
	check("cube.tscn still runs on its own: its Cube is an instance of the cube part at (1.05, 1.37, 0.6), 12 outward triangles",
		old_cube.scene_file_path == "res://parts/cube_part.tscn" and old_cube.position.is_equal_approx(Vector3(1.05, 1.37, 0.6)) and outward(old_cube) == 12)
	cube_study.free()
	var organism_study: Node3D = load("res://organism.tscn").instantiate()
	root.add_child(organism_study)
	organism_study.get_node("Organism").set_process(false)
	await frames(2)
	var organism: Node3D = organism_study.get_node("Organism")
	var hip: Node3D = organism.get_node("Hip")
	check("organism.tscn still runs on its own: its Hip is an instance of the limb part at (-0.9, 1.12, 0.8), thirteen nodes below it",
		hip.scene_file_path == "res://parts/limb_part.tscn" and near(hip.global_position, Vector3(-0.9, 1.12, 0.8)) and below(hip) == 13
		and organism.get_script().resource_path == "res://organism.gd")
	while organism.angle < TAU:
		organism._process(1.0 / 60.0)
	check("and one whole turn of that limb still takes 33 cells: '%s'" % organism.get_node("Lattice/Count").text,
		organism.get_node("Lattice").lost.size() == 33 and organism.get_node("Lattice/Count").text == "55 of 88 cells")
	organism_study.free()
	await process_frame

	# The study: body.tscn.
	var study := await open(0)
	var body: Node3D = study.get_node("Body")
	var marble: RigidBody3D = study.get_node("Marble")
	var b: Node3D = study.get_node("B")
	check("body.tscn inherits plane.tscn: the root runs plane.gd, with A, B, Segment, Strip, Record, Face, Marble and Under; no Cube and no Organism of the old kind",
		study.get_script().resource_path == "res://plane.gd" and study.has_node("A") and study.has_node("Segment") and study.has_node("Strip")
		and study.has_node("Record") and study.has_node("Face") and study.has_node("Under") and marble.get_script().resource_path == "res://marble.gd"
		and b.get_script().resource_path == "res://mover.gd" and not study.has_node("Cube") and not study.has_node("Organism"))
	check("Body is a plain Node3D on the floor at (0, 0, 0.9) and runs body.gd; it holds no node of its own in the scene file: all it has, the script added",
		body.get_class() == "Node3D" and near(body.position, ROOT_AT) and body.get_script().resource_path == "res://body.gd"
		and body.find_children("*", "", true, true).is_empty() and below(body) == 25)

	# Flat: four pivots under the root, each with its part.
	check("flat: the root has four children, the pivots, and each pivot has one child, its part",
		child_names(body) == ["PointPivot", "PlanePivot", "CubePivot", "LimbPivot"] and child_names(body.get_node("PointPivot")) == ["Point"]
		and child_names(body.get_node("PlanePivot")) == ["Plane"] and child_names(body.get_node("CubePivot")) == ["Cube"]
		and child_names(body.get_node("LimbPivot")) == ["Limb"])
	var empty := true
	for pivot: Node3D in body.pivots:
		empty = empty and pivot.get_class() == "Node3D" and pivot.get_script() == null and pivot.owner == null
	check("a pivot is an empty Node3D made by Node3D.new(): no mesh, no script, no owner; the body keeps the four in `pivots`", empty and body.pivots.size() == 4)
	check("25 nodes hang below the root: 4 pivots and the 21 nodes the parts bring", below(body) == 25)
	var rest := rest_places()
	var here := places(body)
	var rest_ok := true
	for key: String in rest:
		rest_ok = rest_ok and near(here[key], rest[key][1])
	check("at rest the parts are where the lesson puts them: the point at (-0.8, 0.075, 0.9), the plane's middle at (-0.2, 0.02, 0.9), the cube at (0.55, 0.25, 0.9), the hip at (0.55, 0.25, 1.15), the toe at (0.55, 0.12, 2.05)", rest_ok)
	check("the plane's node stands at (-1.4, -1.1, 0.45), under the floor: its position is minus the walk's middle, and its pivot carries the middle to its place",
		near(part(body, "Plane").position, -WALK_MIDDLE) and near(part(body, "Plane").global_position, Vector3(-1.4, -1.1, 0.45))
		and near(body.get_node("PlanePivot").global_position, ROOT_AT + AT["plane"]))
	measured["rest"] = {"point": rounded(here["point"]), "plane_middle": rounded(here["plane middle"]), "cube": rounded(here["cube"]), "hip": rounded(here["hip"]), "toe": rounded(here["toe"])}

	# Move the root: every part follows.
	var before := snapshot(body)
	var positions := {}
	for path: String in before:
		positions[path] = (body.get_node(path) as Node3D).position
	body.position.x += 0.5
	var after := snapshot(body)
	var all_moved := true
	var nothing_local := true
	for path: String in before:
		all_moved = all_moved and near((after[path] as Transform3D).origin - (before[path] as Transform3D).origin, Vector3(0.5, 0, 0))
		nothing_local = nothing_local and (body.get_node(path) as Node3D).position.is_equal_approx(positions[path])
	check("the root moved 0.5 m along x: each of the 25 nodes below it is 0.5 m further along x in the room, and no `position` below the root changed",
		all_moved and nothing_local and before.size() == 25)
	body.position = ROOT_AT

	# Turn one part: only what hangs below it follows.
	before = snapshot(body)
	var knee: Node3D = body.get_node("LimbPivot/Limb/Upper/Lower")
	knee.rotation.y = deg_to_rad(30.0)
	check("the knee turned 30 degrees: the only nodes that moved are Lower and the eight below it; the toe is at (0.85, 0.12, 1.97)",
		moved(before, snapshot(body)) == branch(body, knee) and branch(body, knee).size() == 9
		and near(part(body, "Toe").global_position, Vector3(0.85, 0.12, 1.969615)))
	knee.rotation.y = 0.0
	before = snapshot(body)
	body.get_node("CubePivot").rotation.y = deg_to_rad(30.0)
	check("flat, the cube's pivot turned 30 degrees: the pivot, the cube and its Body moved, and the limb beside it did not",
		moved(before, snapshot(body)) == branch(body, body.get_node("CubePivot")) and near(part(body, "Toe").global_position, rest["toe"][1]))
	body.get_node("CubePivot").rotation.y = 0.0

	# A pivot against the part's own origin.
	var plane: Node3D = part(body, "Plane")
	body.get_node("PlanePivot").rotation.y = deg_to_rad(30.0)
	var on_pivot := plane.to_global(WALK_MIDDLE)
	body.get_node("PlanePivot").rotation.y = 0.0
	var loose_plane: Node3D = scenes["plane"].instantiate()
	body.add_child(loose_plane)
	var raw_middle := loose_plane.to_global(WALK_MIDDLE)
	loose_plane.rotation.y = deg_to_rad(30.0)
	var swung := loose_plane.to_global(WALK_MIDDLE)
	check("a plane instanced without a pivot arrives where it was walked: its middle 1.12 m up, at (1.2, 1.12, 1.35)", near(raw_middle, Vector3(1.2, 1.12, 1.35)))
	check("turned 30 degrees on its own origin its middle swings %.2f m, to (1.264, 1.12, 0.69); turned on its pivot the middle stays at (-0.2, 0.02, 0.9)" % (swung - raw_middle).length(),
		near(swung, Vector3(1.26423, 1.12, 0.689711)) and near(on_pivot, ROOT_AT + AT["plane"]) and absf((swung - raw_middle).length() - 0.663) < 0.001)
	measured["plane_swing_m"] = snappedf((swung - raw_middle).length(), 0.001)
	body.remove_child(loose_plane)
	loose_plane.free()

	# The bodies come with the parts.
	await physics_frame
	await physics_frame
	var on_cube := ray_down(rest["cube"][1], marble)
	var on_plane := ray_down(Vector3(-0.4, 0, 0.9), marble)
	var on_limb := ray_down(Vector3(0.55, 0, 1.6), marble)
	check("each part brought its body: a ray sent down meets the cube's at 0.5 m, the plane's at 0.02 m and a bar's at 0.29 m",
		on_cube[0].ends_with("CubePivot/Cube/Body") and absf(on_cube[1] - 0.5) < 0.001 and on_plane[0].ends_with("PlanePivot/Plane/Body")
		and absf(on_plane[1] - 0.02) < 0.001 and on_limb[0].ends_with("Lower/Bar/Body") and absf(on_limb[1] - 0.29) < 0.001)

	# Scale the root.
	turn_pivots(body, 30.0)
	var limb: Node3D = part(body, "Limb")
	var cube: Node3D = part(body, "Cube")
	var apart: float = (part(body, "Point").global_position - cube.global_position).length()
	var square := rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z))
	body.scale = Vector3(2, 2, 2)
	var apart_2: float = (part(body, "Point").global_position - cube.global_position).length()
	check("the root scaled (2, 2, 2): the cube is 1 m on an edge and stands at (1.1, 0.5, 0.9); the point and the cube are %.3f m apart, where they were %.3f" % [apart_2, apart],
		near(cube.global_position, Vector3(1.1, 0.5, 0.9)) and absf(apart - 1.3613) < 0.001 and absf(apart_2 - 2.0 * apart) < 0.001
		and absf((cube.to_global(Vector3(0.25, 0.25, 0.25)) - cube.to_global(Vector3(-0.25, 0.25, 0.25))).length() - 1.0) < 0.001
		and cube.scale.is_equal_approx(Vector3.ONE))
	var even := rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z))
	body.scale = Vector3(4, 4, 4)
	var even_4 := rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z))
	check("an even scale keeps the angles: with every pivot at 30 degrees the limb's x and z axes stand at %.1f degrees at scale 1, 2 and 4" % even,
		absf(square - 90.0) < 0.01 and absf(even - 90.0) < 0.01 and absf(even_4 - 90.0) < 0.01)
	body.scale = Vector3(1, 1, 2)
	var sheared := rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z))
	check("the root stretched to (1, 1, 2): the turned limb shears: its x and z axes stand at %.1f degrees, %.3f and %.3f long; the cube's stand at %.1f" % [
		sheared, limb.global_basis.x.length(), limb.global_basis.z.length(), rad_to_deg(cube.global_basis.x.angle_to(cube.global_basis.z))],
		absf(sheared - 123.0) < 0.05 and absf(limb.global_basis.x.length() - 1.323) < 0.001 and absf(limb.global_basis.z.length() - 1.803) < 0.001
		and absf(rad_to_deg(cube.global_basis.x.angle_to(cube.global_basis.z)) - 123.0) < 0.05 and limb.scale.is_equal_approx(Vector3.ONE))
	measured["shear_limb_axes_degrees"] = snappedf(sheared, 0.01)
	turn_pivots(body, 0.0)
	check("the same stretch with nothing turned shears nothing: the axes stand at %.1f degrees" % rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z)),
		absf(rad_to_deg(limb.global_basis.x.angle_to(limb.global_basis.z)) - 90.0) < 0.01)
	body.scale = Vector3.ONE

	# The planted mistake: a node that has a parent cannot be added again.
	var point_pivot: Node3D = body.get_node("PointPivot")
	var plane_pivot: Node3D = body.get_node("PlanePivot")
	print("The next ERROR is expected: point_pivot.add_child(plane_pivot), and the plane's pivot already has a parent.")
	point_pivot.add_child(plane_pivot)
	point_pivot.rotation.y = deg_to_rad(30.0)
	check("add_child() of a pivot that already has a parent changes nothing: the root still has four children, the plane's pivot is still the root's, and it does not follow the point's turn",
		body.get_child_count() == 4 and plane_pivot.get_parent() == body and point_pivot.get_child_count() == 1
		and near(part(body, "Plane").to_global(WALK_MIDDLE), rest["plane middle"][1]))
	point_pivot.rotation.y = 0.0
	plane_pivot.reparent(point_pivot)
	check("reparent() moves it: the root has three children, the plane's pivot is the point's child, its position reads (0.6, -0.055, 0) and it has not moved in the room",
		body.get_child_count() == 3 and plane_pivot.get_parent() == point_pivot and near(plane_pivot.position, Vector3(0.6, -0.055, 0.0))
		and near(plane_pivot.global_position, ROOT_AT + AT["plane"]))
	await close(study)

	# The argument: four ways to parent the same four parts.
	var trees := [
		{"Body": ["PointPivot", "PlanePivot", "CubePivot", "LimbPivot"], "PointPivot": ["Point"], "PlanePivot": ["Plane"], "CubePivot": ["Cube"], "LimbPivot": ["Limb"]},
		{"Body": ["PointPivot"], "PointPivot": ["Point", "PlanePivot"], "PlanePivot": ["Plane", "CubePivot"], "CubePivot": ["Cube", "LimbPivot"], "LimbPivot": ["Limb"]},
		{"Body": ["PointPivot"], "PointPivot": ["Point", "PlanePivot"], "PlanePivot": ["Plane", "CubePivot"], "CubePivot": ["Cube", "LimbPivot"], "LimbPivot": ["Limb"]},
		{"Body": ["PlanePivot", "CubePivot"], "PlanePivot": ["Plane", "PointPivot"], "PointPivot": ["Point"], "CubePivot": ["Cube", "LimbPivot"], "LimbPivot": ["Limb"]},
	]
	var rest_all := []
	var root_all := []
	var toes := []
	var travel := []
	for v in 4:
		study = await open(v)
		body = study.get_node("Body")
		var tree_ok := true
		for node_name: String in trees[v]:
			var node: Node = body if node_name == "Body" else body.find_child(node_name, true, false)
			tree_ok = tree_ok and child_names(node) == trees[v][node_name]
		check("parenting %d, %s: the root has %d %s, and the tree is the one the lesson draws; 25 nodes below the root" % [
			v, NAMES[v], body.get_child_count(), "child" if body.get_child_count() == 1 else "children"],
			tree_ok and body.get_child_count() == [4, 1, 1, 2][v] and below(body) == 25 and body.pivots.size() == 4)
		var pivots_ok := true
		for kind: String in KINDS:
			var pivot: Node3D = body.find_child(kind.capitalize() + "Pivot", true, false)
			pivots_ok = pivots_ok and near(pivot.global_position, pivot_rest(kind, v))
		check("parenting %d: every pivot stands %s" % [v, "0.25 m to the left of its part's middle" if v == 2 else "at its part's middle"], pivots_ok)
		rest_all.append(places(body))
		body.rotation.y = deg_to_rad(30.0)
		root_all.append(places(body))
		body.rotation.y = 0.0
		turn_pivots(body, 30.0)
		here = places(body)
		var hand_ok := true
		for key: String in rest:
			hand_ok = hand_ok and near(here[key], by_hand(rest[key], v, deg_to_rad(30.0)))
		toes.append(here["toe"])
		travel.append((here["toe"] - rest["toe"][1]).length())
		check("parenting %d: with every pivot at 30 degrees seven places on the body are where the turns worked out by hand put them; the toe is at (%.3f, %.3f, %.3f), %.2f m from where it rested" % [
			v, here["toe"].x, here["toe"].y, here["toe"].z, travel[v]], hand_ok)
		# One second of the body's own _process.
		turn_pivots(body, 0.0)
		var rates_ok := true
		for rate in [30, 60, 90, 144]:
			body.angle = 0.0
			for i in rate:
				body._process(1.0 / rate)
			rates_ok = rates_ok and absf(rad_to_deg(body.angle) - 30.0) < 0.001 and near(part(body, "Toe").global_position, toes[v], 0.001)
			for i in rate:
				body._process(1.0 / rate)
			rates_ok = rates_ok and is_equal_approx(body.angle, body.limit) and near(part(body, "Toe").global_position, toes[v])
		check("parenting %d: one second of _process at 30, 60, 90 and 144 frames a second turns every pivot 30 degrees and puts the toe there; a second later nothing has moved" % v, rates_ok)
		await close(study)
	var same_rest := true
	var same_root := true
	for v in range(1, 4):
		for key: String in rest:
			same_rest = same_rest and near(rest_all[v][key], rest_all[0][key]) and near(rest_all[v][key], rest[key][1])
			same_root = same_root and near(root_all[v][key], root_all[0][key])
	check("at rest the four values put every part in the same place: only the tree differs", same_rest)
	check("with the root turned 30 degrees they still agree, place for place: the toe is at (1.051, 0.12, 1.621) in all four", same_root and near(root_all[0]["toe"], Vector3(1.051314, 0.12, 1.620929)))
	check("with every pivot turned 30 degrees the four toes are the lesson's: (1.0, 1.929), (1.124, -0.5), (0.749, -0.716) and (1.454, 1.567) in x and z",
		near(toes[0], Vector3(1.0, 0.12, 1.929), 0.001) and near(toes[1], Vector3(1.124, 0.12, -0.5), 0.001)
		and near(toes[2], Vector3(0.749, 0.12, -0.716), 0.001) and near(toes[3], Vector3(1.454, 0.12, 1.567), 0.001))
	check("the toe travels %.2f m flat, %.2f m in the chain, %.2f m with offset pivots and %.2f m in two chains: the chain swings its last part more than five times as far" % travel,
		absf(travel[0] - 0.47) < 0.01 and absf(travel[1] - 2.61) < 0.01 and absf(travel[2] - 2.77) < 0.01 and absf(travel[3] - 1.02) < 0.01 and travel[1] > 5.0 * travel[0])
	measured["toe_with_every_pivot_at_30"] = toes.map(func(t): return rounded(t))
	measured["toe_travel_m"] = travel.map(func(t): return snappedf(t, 0.001))

	# Carry the root: the body follows B.
	study = await open(0)
	body = study.get_node("Body")
	b = study.get_node("B")
	marble = study.get_node("Marble")
	b.set_process(false)
	turn_pivots(body, 30.0)
	var x := 0.75
	while x > -0.74:
		b.position.x = x
		body.position = b.position
		x -= 0.02
	await physics_frame
	await physics_frame
	here = places(body)
	var carried := true
	for key: String in rest:
		carried = carried and near(here[key], by_hand(rest[key], 0, deg_to_rad(30.0)) - ROOT_AT + b.position)
	check("the root set to B's position and B walked to x = -0.73, the pivots at 30 degrees: the body is picked up to 1.12 m and every part comes with it; the toe is at (0.27, 1.24, 1.03), still (1.0, 0.12, 1.03) from the root",
		carried and near(body.position, Vector3(-0.73, 1.12, 0.0)) and near(here["toe"], Vector3(0.27, 1.24, 1.029423)) and near(part(body, "Cube").position, Vector3.ZERO))
	marble.drop(b.position + Vector3.UP)
	var landed := await settle(marble)
	check("a marble dropped from one metre above B lands on the carried plane: %.3f m" % landed.y, absf(landed.y - (1.14 + RADIUS)) < 0.02)
	var carried_top := ray_down(part(body, "Cube").global_position, marble)
	check("the bodies are carried too: a ray sent down over the carried cube meets its Body at %.2f m" % carried_top[1],
		carried_top[0].ends_with("CubePivot/Cube/Body") and absf(carried_top[1] - 1.62) < 0.001)
	body.scale = Vector3.ONE * 4.0
	await physics_frame
	await physics_frame
	var top := ray_down(part(body, "Cube").global_position, marble)
	check("scaled by four while carried, as the hall scales its room: the cube is 2 m on an edge, its top at %.2f m, and the toe is (4.0, 0.48, 4.12) from the root: four times its place at scale 1" % top[1],
		absf(top[1] - 3.12) < 0.001 and near(part(body, "Toe").global_position - body.global_position, Vector3(4.0, 0.48, 4.117691))
		and absf((part(body, "Cube").to_global(Vector3(0.25, 0.25, 0.25)) - part(body, "Cube").to_global(Vector3(-0.25, 0.25, 0.25))).length() - 2.0) < 0.001)
	await close(study)

	# The process strip, step by step, as sheet.gd photographs it.
	study = await open(0)
	body = study.get_node("Body")
	for child in body.get_children():
		body.remove_child(child)
		child.free()
	var counts := []
	var point: Node3D = scenes["point"].instantiate()
	body.add_child(point)
	point.position = AT["point"]
	counts.append([body.get_child_count(), below(body)])
	check("strip 1, point: the root has 1 child, 1 node below it, at (-0.8, 0.075, 0.9)", counts[0] == [1, 1] and near(point.global_position, ROOT_AT + AT["point"]))
	plane = scenes["plane"].instantiate()
	body.add_child(plane)
	counts.append([body.get_child_count(), below(body)])
	check("strip 2, + plane: 2 children, 4 nodes; the plane's middle is where it was walked, 1.12 m up, at (1.2, 1.12, 1.35)",
		counts[1] == [2, 4] and near(plane.to_global(WALK_MIDDLE), Vector3(1.2, 1.12, 1.35)))
	cube = scenes["cube"].instantiate()
	body.add_child(cube)
	cube.position = AT["cube"]
	counts.append([body.get_child_count(), below(body)])
	check("strip 3, + cube: 3 children, 7 nodes; the cube stands on the floor, its middle at 0.25 m", counts[2] == [3, 7] and near(cube.global_position, ROOT_AT + AT["cube"]))
	limb = scenes["limb"].instantiate()
	body.add_child(limb)
	limb.position = AT["limb"]
	counts.append([body.get_child_count(), below(body)])
	check("strip 4, + limb: 4 children, 21 nodes; the toe is at (0.55, 0.12, 2.05)", counts[3] == [4, 21] and near(part(body, "Toe").global_position, rest["toe"][1]))
	await close(study)
	study = await open(0)
	body = study.get_node("Body")
	var flat := in_the_room(body)
	check("strip 5, pivots set: still 4 children, now the pivots; 25 nodes; the plane's middle has come down to (-0.2, 0.02, 0.9)",
		body.get_child_count() == 4 and below(body) == 25 and near(part(body, "Plane").to_global(WALK_MIDDLE), ROOT_AT + AT["plane"]))
	await close(study)
	study = await open(1)
	body = study.get_node("Body")
	var chained := in_the_room(body)
	var unmoved := chained.size() == 25 and flat.size() == 25
	for key: String in flat:
		unmoved = unmoved and chained.has(key) and (chained[key] as Transform3D).is_equal_approx(flat[key])
	check("strip 6, a chain: 1 child, 25 nodes; every node is where it was in the room: the operation moved nothing", body.get_child_count() == 1 and below(body) == 25 and unmoved)
	turn_pivots(body, 30.0)
	check("strip 7, every pivot turned: still 1 child, 25 nodes; the toe has gone to (1.124, 0.12, -0.5)",
		body.get_child_count() == 1 and below(body) == 25 and near(part(body, "Toe").global_position, Vector3(1.124038, 0.12, -0.499519)))
	await close(study)

	# process.png, read back tile by tile.
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
		check("in process.png every tile differs from the one before it (%.2f, %.2f, %.2f, %.2f%% of the tile), except 'a chain', which differs from 'pivots set' on %.2f%%; the turn then changes %.2f%%" % [
			shares[0], shares[1], shares[2], shares[3], shares[4], shares[5]],
			shares[0] > 1.0 and shares[1] > 1.0 and shares[2] > 1.0 and shares[3] > 1.0 and shares[4] == 0.0 and shares[5] > 1.0)
		measured["process_png"] = {"bytes": bytes, "tile_differs_from_the_one_before_pct": shares}

	# The guest handed to the room.
	await guest_checks()

	# The sheet's record, if it has been rendered.
	if FileAccess.file_exists("res://sheet.json"):
		var sheet: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sheet.json"))
		measured["sheet"] = sheet
		sheet_checks(sheet, toes)

	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Body of Parts study: ", checks.size(), " checks; passed=", passed)
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

func sheet_checks(sheet: Dictionary, toes: Array) -> void:
	var still := true
	for pose: String in ["rest", "root"]:
		for view: String in ["above", "top"]:
			var table: Dictionary = sheet.get("pairs_%s_%s_pct" % [pose, view], {"none": 100.0})
			still = still and table.size() == 6 and table.values().max() == 0.0
	check("sheet.json: at rest, and with the root turned 30 degrees, no two values differ on a single pixel, from above or from the top: 0.00% for all six pairs", still)
	var above: Dictionary = sheet.get("pairs_pivots_above_pct", {"none": 0.0})
	var top: Dictionary = sheet.get("pairs_pivots_top_pct", {"none": 0.0})
	check("sheet.json: with every pivot turned 30 degrees every pair differs: on %.2f%% of the frame at least from the top, %.2f%% from above" % [top.values().min(), above.values().min()],
		top.size() == 6 and above.size() == 6 and top.values().min() > 0.3 and above.values().min() > 0.3)
	check("sheet.json: the closest pair then is flat and two chains, from above and from the top; the farthest is the chain with offset pivots and two chains",
		sheet.get("closest_pair_pivots_above", "") == "0 vs 3" and sheet.get("closest_pair_pivots_top", "") == "0 vs 3"
		and sheet.get("farthest_pair_pivots_above", "") == "2 vs 3" and sheet.get("farthest_pair_pivots_top", "") == "2 vs 3")
	check("sheet.json: the chain and the chain with offset pivots are not the farthest pair: %.2f%% from the top against %.2f%% for the farthest" % [top.get("1 vs 2", 0.0), top.values().max()],
		top.get("1 vs 2", 100.0) < top.get("0 vs 1", 0.0) and top.get("1 vs 2", 100.0) < top.values().max())
	var toes_ok := true
	var trees_ok := true
	for v in 4:
		var entry: Dictionary = sheet.get(str(v), {})
		var at: Array = entry.get("pivots", {}).get("toe", [9, 9, 9])
		toes_ok = toes_ok and absf(at[0] - toes[v].x) < 0.002 and absf(at[1] - toes[v].y) < 0.002 and absf(at[2] - toes[v].z) < 0.002
		trees_ok = trees_ok and int(entry.get("root_children", 0)) == [4, 1, 1, 2][v] and int(entry.get("nodes_below_root", 0)) == 25
	check("sheet.json: with a window the four toes are where they are headless, and the root has 4, 1, 1 and 2 children", toes_ok and trees_ok)
	check("sheet.json: the root scaled (2, 2, 2) keeps the limb's axes at 90 degrees; stretched to (1, 1, 2) they stand at 123 degrees, and the still changes",
		absf(sheet.get("scaled_2", {}).get("limb_x_to_z_degrees", 0.0) - 90.0) < 0.05
		and absf(sheet.get("stretched_z", {}).get("limb_x_to_z_degrees", 0.0) - 123.0) < 0.05
		and sheet.get("stretched_z", {}).get("differs_from_unscaled_pct", 0.0) > 1.0)
	var strip: Array = sheet.get("strip", [])
	var counts_ok := strip.size() == 7
	var wanted := [[1, 1], [2, 4], [3, 7], [4, 21], [4, 25], [1, 25], [1, 25]]
	if counts_ok:
		for i in 7:
			counts_ok = counts_ok and int(strip[i]["root_children"]) == wanted[i][0] and int(strip[i]["nodes_below_root"]) == wanted[i][1]
	check("sheet.json: the strip's seven steps counted 1, 2, 3, 4, 4, 1, 1 children of the root and 1, 4, 7, 21, 25, 25, 25 nodes below it", counts_ok)
	check("sheet.json: the step that changed the picture most was '%s'; 'a chain' changed it on %.2f%% of the tile" % [sheet.get("strip_step_that_changed_most", ""), strip[5]["differs_from_step_before_pct"] if counts_ok else -1.0],
		counts_ok and strip[5]["differs_from_step_before_pct"] == 0.0 and sheet.get("strip_step_that_changed_most", "") in ["5 pivots set", "7 every pivot turned"])
