extends SceneTree
## Headless checks for the Families study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## This study has a class with a name. Godot lists named classes when it
## imports a project, so a fresh copy needs one import before this runs:
##   godot --headless --path . --xr-mode off --import
## Headless draws no frames, so what the eye gets is measured by sheet.gd; here
## we check what the family is made of (the class, its two fields and their
## types, what build() makes, how many triangles each member lists), what
## set() does with a text, a decimal, a wrong type and a wrong name, what the
## supplied sheet does and does not do, the marble over a member, the steps of
## the process strip, and that the earlier studies still run.
## The last checks before the sheet's are of the guest in guests/: the body this
## chapter hands to the room, which has to stand on its own.

var checks := []
var measured := {}
var GlobeScript: Script

const ROW_AT := Vector3(-1.8, 0, 0.9)       # where Sheet and Family stand in the room
const SPACING := 1.2
const VALUES := [4, 8, 16, 64]
const LISTED := [24, 80, 288, 4224]         # triangles each member lists
const WITH_AREA := [16, 64, 256, 4096]      # of those, the ones that are not slivers at a pole
const PAINT := Color(0.45, 0.38, 0.3)
const ORANGE := Color(0.62, 0.34, 0.12)     # the cube part's own material
const LIGHT := Color(0.62, 0.55, 0.4)       # the chessboard's two colours
const DARK := Color(0.08, 0.16, 0.2)
const TILE := Vector2i(320, 240)
const GUTTER := 4

## A second small class, for one check: a field that is a text.
class Worded extends Node:
	var word: String = "smooth"
	var whole: int = 7
	var yes: bool = true

const CheckGuest := preload("res://check_guest.gd")
const GUEST := "res://guests/family/"           # the body this chapter hands to the room
const PLACE := 0.8                              # half the width of a place in the room

## Godot hands every message to a Logger. This one keeps the errors, and the lines printed, while the guest runs.
class Catcher extends Logger:
	var errors: Array[String] = []
	var lines: Array[String] = []
	var lock := Mutex.new()   # messages can come from other threads

	func _log_error(_function: String, file: String, line: int, code: String, rationale: String, _editor_notify: bool, error_type: int, _script_backtraces: Array[ScriptBacktrace]) -> void:
		if error_type == ERROR_TYPE_WARNING:
			return
		lock.lock()
		errors.append("%s (%s:%d)" % [rationale if rationale != "" else code, file, line])
		lock.unlock()

	func _log_message(message: String, _error: bool) -> void:
		lock.lock()
		lines.append(message.strip_edges(false, true))
		lock.unlock()

var last_sign := 0   # when the last check was written, in milliseconds

func _initialize() -> void:
	run.call_deferred()
	give_up.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print(("PASS " if passed else "FAIL ") + label)
	last_sign = Time.get_ticks_msec()

## A script error inside a check stops run() where it stands, and nothing would
## ever call quit(). So: a minute with no new check, and we stop and say so.
func give_up() -> void:
	last_sign = Time.get_ticks_msec()
	while Time.get_ticks_msec() - last_sign < 60000:
		await process_frame
	check("verify.gd ran to its end (it did not: a check stopped on a script error; see the lines above)", false)
	finish()

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

func listed(mesh: Mesh) -> int:
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() / 3

func with_area(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var corners: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var index: PackedInt32Array = arrays[Mesh.ARRAY_INDEX]
	var count := 0
	for t in index.size() / 3:
		var a := corners[index[t * 3]]
		if (corners[index[t * 3 + 1]] - a).cross(corners[index[t * 3 + 2]] - a).length_squared() > 1e-16:
			count += 1
	return count

func is_globe(node: Node) -> bool:
	return node.get_script() == GlobeScript

## One study. `setup` is a dictionary of Family's variables to set before it is
## built; null takes the script off Family, for the steps built by hand.
func open(setup: Variant) -> Node3D:
	var study: Node3D = load("res://family.tscn").instantiate()
	var family: Node3D = study.get_node("Family")
	if setup == null:
		family.set_script(null)
	else:
		for key: String in setup:
			family.set(key, setup[key])
	root.add_child(study)
	await frames(2)
	await physics_frame
	study.set_process(false)
	study.get_node("B").set_process(false)
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

## What a step of the strip claims: bodies, how many are of the class, their
## triangles, how many different bodies, and what the plates say.
func counted(study: Node3D) -> Array:
	var family: Node3D = study.get_node("Family")
	var counts := []
	var of_the_class := 0
	var different := []
	for body: MeshInstance3D in family.get_children():
		var count := listed(body.mesh)
		counts.append(count)
		if is_globe(body):
			of_the_class += 1
		if not different.has(count):
			different.append(count)
	var titles := []
	for plate: Label3D in study.get_node("Sheet").plates:
		titles.append(plate.text)
	return [family.get_child_count(), of_the_class, counts, different.size(), titles]

func fields(study: Node3D, name: String) -> Array:
	var out := []
	for member in study.get_node("Family").get_children():
		out.append(member.get(name))
	return out

func press(action: String, study: Node) -> void:
	await process_frame
	Input.action_press(action)
	study._process(0)
	Input.action_release(action)
	await process_frame

func last_line(study: Node) -> String:
	study._process(0)
	return study.get_node("Record").text.split("\n")[-1]

func outward(cube: MeshInstance3D) -> int:
	var vs: PackedVector3Array = (cube.mesh as ArrayMesh).surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var count := 0
	for t in vs.size() / 3:
		var plane := Plane(vs[t * 3], vs[t * 3 + 1], vs[t * 3 + 2])
		if plane.normal.dot((vs[t * 3] + vs[t * 3 + 1] + vs[t * 3 + 2]) / 3.0) > 0.0:
			count += 1
	return count

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
	var scene: Resource = load(GUEST + "family.tscn")
	var guest: Node = null
	if scene is PackedScene and (scene as PackedScene).can_instantiate():
		guest = (scene as PackedScene).instantiate()
	check("the guest scene loads: guests/family/family.tscn, and its first node is a Node3D", guest is Node3D)
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
	var class_text := FileAccess.get_file_as_string("res://globe.gd")
	var guest_text := FileAccess.get_file_as_string(GUEST + "globe.gd")
	var members: Array[Node] = guest.find_children("*", "MeshInstance3D", true, false)
	var member: MeshInstance3D = members[0] if members.size() == 1 else null
	var one: bool = member != null and member.get_script() == load(GUEST + "globe.gd") and member.get_script() != GlobeScript
	var numbers: bool = one and member.segments == 8 and member.rings == 4 and listed(member.mesh) == 80 and with_area(member.mesh) == 64
	var painted: bool = one and member.material_override is StandardMaterial3D and member.material_override.albedo_color.to_html(false) == "c6ff3d" and is_equal_approx(member.material_override.roughness, 0.8)
	var shapes: Array[Node] = guest.find_children("*", "CollisionShape3D", true, false)
	var bodied: bool = shapes.size() == 1 and shapes[0].get_parent() is StaticBody3D and shapes[0].shape is ConcavePolygonShape3D
	check("the guest is one member of the family: its globe.gd is the lesson's globe.gd without the first line, 'class_name Globe'; one body of that class with 8 segments and 4 rings, 80 triangles listed and 64 with area, in BODY c6ff3d, with one collider made from its mesh; it said '%s'" % [catcher.lines],
		class_text.begins_with("class_name Globe\n") and guest_text == class_text.trim_prefix("class_name Globe\n")
		and numbers and painted and bodied and catcher.lines == ["Globe, 8, 4: 80 triangles"])
	var box := box_of(guest as Node3D)
	var top := first_under(Vector3(0.0, 2.0, 0.0))
	check("the guest stands on the ground at its own origin and fits on a place, 1.6 m wide and deep: its box runs from (%.3f, %.3f, %.3f) to (%.3f, %.3f, %.3f), and a ray straight down over its middle stops on it at %.2f m" % [
		box.position.x, box.position.y, box.position.z, box.end.x, box.end.y, box.end.z, top],
		absf(box.position.y) < 0.001 and box.position.x >= -PLACE and box.position.z >= -PLACE and box.end.x <= PLACE and box.end.z <= PLACE
		and near(box.get_center(), Vector3(0, 0.5, 0), 0.001) and absf(top - 1.0) < 0.001)
	measured["guest"] = {"scene": GUEST + "family.tscn", "segments": member.segments if one else 0, "rings": member.rings if one else 0, "said": catcher.lines,
		"box": [[snappedf(box.position.x, 0.001), snappedf(box.position.y, 0.001), snappedf(box.position.z, 0.001)], [snappedf(box.end.x, 0.001), snappedf(box.end.y, 0.001), snappedf(box.end.z, 0.001)]]}
	guest.free()
	await process_frame

func run() -> void:
	# The named class has to be listed before anything that says Globe can load.
	var named := {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		named[entry["class"]] = entry
	if not named.has("Globe"):
		print("Godot has not listed this project's named classes yet. Run this once, then run verify.gd again:")
		print("  godot --headless --path . --xr-mode off --import")
		quit(1)
		return
	GlobeScript = load("res://globe.gd")

	# The project and the Input Map: the nine actions of the earlier studies, unchanged.
	check("the project is named 'Families' and its main scene is family.tscn",
		ProjectSettings.get_setting("application/config/name") == "Families"
		and ProjectSettings.get_setting("application/run/main_scene") == "res://family.tscn")
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
	check("line.tscn, trace.tscn and plane.tscn still run on their own: '1.50 m', '1 kept', 'open', and none of them has a Sheet or a Family",
		lines.get_node("Readout").text == "1.50 m" and trace_study.get_node("Record").text.begins_with("1 kept")
		and plane_study.get_node("Record").text.contains("open") and not plane_study.has_node("Sheet") and not plane_study.has_node("Family"))
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
		old_body.get_child_count() == 4 and below(old_body) == 25 and old_body.get_node("CubePivot/Cube").scene_file_path == "res://parts/cube_part.tscn")
	body_study.free()
	var chess_study: Node3D = load("res://chessboard.tscn").instantiate()
	root.add_child(chess_study)
	await frames(2)
	var board: Node3D = chess_study.get_node("Chessboard")
	var lights := 0
	var darks := 0
	var ghosts := []
	for i in board.cubes.size():
		var cube: MeshInstance3D = board.cubes[i]
		if cube.material_override.albedo_color.is_equal_approx(LIGHT):
			lights += 1
		if cube.material_override.albedo_color.is_equal_approx(DARK):
			darks += 1
		if cube.get_node("Body/CollisionShape3D").disabled:
			ghosts.append(i)
	check("chessboard.tscn still runs on its own: 64 cubes, 64 materials, 32 light and 32 dark, one ghost at cell (5, 5); it has no Sheet and no Family",
		board.cubes.size() == 64 and board.count_materials() == 64 and lights == 32 and darks == 32 and ghosts == [5 * 8 + 5]
		and not chess_study.has_node("Sheet") and not chess_study.has_node("Family"))
	chess_study.free()
	await process_frame

	# The class.
	var source := FileAccess.get_file_as_string("res://globe.gd")
	var first: MeshInstance3D = GlobeScript.new()
	check("globe.gd begins 'class_name Globe' and 'extends MeshInstance3D'; Godot lists Globe as a class whose base is MeshInstance3D; a new member is a MeshInstance3D",
		source.begins_with("class_name Globe\nextends MeshInstance3D\n") and named["Globe"]["base"] == "MeshInstance3D"
		and named["Globe"]["path"] == "res://globe.gd" and first is MeshInstance3D and first.get_class() == "MeshInstance3D")
	var listing := {}
	for property: Dictionary in first.get_property_list():
		if property["name"] == "segments" or property["name"] == "rings":
			listing[property["name"]] = property
	var exported := listing.size() == 2
	for name: String in listing:
		exported = exported and listing[name]["type"] == TYPE_INT and listing[name]["hint"] == PROPERTY_HINT_RANGE and (listing[name]["usage"] & PROPERTY_USAGE_EDITOR) != 0
	check("its two fields are exported whole numbers with a range: segments 16, from 4 to 64, and rings 8, from 1 to 32",
		exported and first.segments == 16 and first.rings == 8 and Array(listing["segments"]["hint_string"].split_floats(",")) == [4.0, 64.0]
		and Array(listing["rings"]["hint_string"].split_floats(",")) == [1.0, 32.0])
	var before_entering: Mesh = first.mesh
	var bench := Node3D.new()
	bench.name = "Bench"
	root.add_child(bench)
	bench.add_child(first)
	var sphere := first.mesh as SphereMesh
	check("a member has no mesh until it enters the room; then _ready() calls build(): a SphereMesh of 16 segments and 8 rings, 1 m across",
		before_entering == null and sphere != null and sphere.radial_segments == 16 and sphere.rings == 8
		and is_equal_approx(sphere.radius, 0.5) and is_equal_approx(sphere.height, 1.0))
	check("triangles() counts what the mesh lists: 288 for the member of 16, three corner numbers for each; 256 of them have area, 32 are slivers at the two poles",
		first.triangles() == 288 and first.triangles() == listed(first.mesh) and with_area(first.mesh) == 256
		and first.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX].size() == 864)
	var counts := []
	var areas := []
	var formula := true
	for n: int in VALUES:
		var member: MeshInstance3D = GlobeScript.new()
		member.segments = n
		member.rings = n / 2
		bench.add_child(member)
		counts.append(member.triangles())
		areas.append(with_area(member.mesh))
		formula = formula and member.triangles() == 2 * n * (n / 2 + 1) and with_area(member.mesh) == 2 * n * (n / 2)
	check("the four members list %d, %d, %d and %d triangles: 2 x segments x (rings + 1); %d, %d, %d and %d have area: 2 x segments x rings" % (counts + areas),
		counts == LISTED and areas == WITH_AREA and formula)
	measured["triangles_listed"] = counts
	measured["triangles_with_area"] = areas
	var late: MeshInstance3D = GlobeScript.new()
	bench.add_child(late)
	late.segments = 4
	late.rings = 2
	var said: int = late.segments
	var had: int = late.triangles()
	late.build()
	check("fields set AFTER add_child() change the field and not the body: the field says %d, the mesh still lists %d triangles; build() again and it lists %d" % [said, had, late.triangles()],
		said == 4 and had == 288 and late.triangles() == 24)
	var wild: MeshInstance3D = GlobeScript.new()
	wild.set("segments", 640)
	wild.set("rings", 0)
	var took := [wild.segments, wild.rings]
	bench.add_child(wild)
	var tall: MeshInstance3D = GlobeScript.new()
	tall.segments = 2
	tall.rings = 320
	bench.add_child(tall)
	var guarded: bool = wild.segments == 64 and tall.rings == 32
	check("@export_range binds the Inspector, not code: set() gave the fields %d and %d; build() is where the class decides: it built %d segments and %d ring; asked for 2 and 320 it built %d and %d" % [took[0], took[1], wild.segments, wild.rings, tall.segments, tall.rings],
		took == [640, 0] and wild.segments == 64 and wild.rings == 1 and tall.segments == 4 and tall.rings == 32
		and (wild.mesh as SphereMesh).radial_segments == 64 and (tall.mesh as SphereMesh).rings == 32)
	var plain := SphereMesh.new()
	plain.radial_segments = 2
	check("Godot's own SphereMesh has a floor too, and says nothing: asked for 2 segments it holds %d" % plain.radial_segments, plain.radial_segments == 4)

	# What set() does with a text, a decimal, a wrong type and a wrong name.
	var probe: MeshInstance3D = GlobeScript.new()
	probe.set("segments", "4")
	var from_text: int = probe.segments
	probe.set("segments", " 64")
	var from_spaced: int = probe.segments
	check("set() does NOT refuse a text on a typed int: set(\"segments\", \"4\") makes it %d and \" 64\" makes it %d. The course outline expected a silent refusal" % [from_text, from_spaced],
		from_text == 4 and from_spaced == 64 and typeof(probe.segments) == TYPE_INT)
	var turned := []
	for value: Variant in ["sixteen", "", 3.5, true, "4 8 16 64"]:
		probe.segments = 16
		probe.set("segments", value)
		turned.append(probe.segments)
	check("set() converts what it can and says nothing: \"sixteen\" becomes %d, an empty text %d, 3.5 becomes %d, true becomes %d, and \"4 8 16 64\" becomes %d" % turned,
		turned == [0, 0, 3, 1, 481664])
	var kept := []
	for value: Variant in [Vector3(4, 4, 4), [4], null]:
		probe.segments = 16
		probe.set("segments", value)
		kept.append(probe.segments)
	check("set() refuses what it cannot convert and says nothing: after a Vector3, a list and null the field is still %d, %d and %d" % kept, kept == [16, 16, 16])
	probe.segments = 16
	probe.set("radial_segments", 4)
	check("set() with a name the class does not have does nothing and says nothing: segments is still %d, and get(\"radial_segments\") is null" % probe.segments,
		probe.segments == 16 and probe.get("radial_segments") == null)
	probe.free()
	var worded := Worded.new()
	worded.set("word", 16)
	worded.set("yes", "false")
	worded.set("whole", "7 segments")
	check("the other direction IS refused: a field typed String keeps '%s' when set() hands it the number 16, and a field typed bool keeps %s when handed the text \"false\"" % [worded.word, worded.yes],
		worded.word == "smooth" and worded.yes == true and worded.whole == 7)
	worded.free()
	@warning_ignore("integer_division")
	var halves := [7 / 2, 5 / 2, 64 / 2]
	check("a whole number divided by a whole number is a whole number: 7 / 2 is %d, 5 / 2 is %d, 64 / 2 is %d; 7 / 2.0 is 3.5; int(\"16\") + 1 is 17 and str(16) + \"1\" is \"161\"" % halves,
		halves == [3, 2, 32] and is_equal_approx(7 / 2.0, 3.5) and int("16") + 1 == 17 and str(16) + "1" == "161")
	bench.free()
	await process_frame

	# The supplied sheet.
	var sheet_scene: Node3D = load("res://sweep_sheet.tscn").instantiate()
	root.add_child(sheet_scene)
	var loose: MeshInstance3D = GlobeScript.new()
	loose.segments = 8
	loose.rings = 4
	var painted: MeshInstance3D = GlobeScript.new()
	var own := StandardMaterial3D.new()
	painted.material_override = own
	root.add_child(painted)
	var mesh_before: Mesh = painted.mesh
	sheet_scene.hang(loose, "first")
	sheet_scene.hang(painted, "second")
	check("sweep_sheet.tscn is a Node3D named Sheet running sweep_sheet.gd, with a Paper under it, a spacing of 1.2 m and one paint",
		sheet_scene.name == "Sheet" and sheet_scene.get_script().resource_path == "res://sweep_sheet.gd" and sheet_scene.has_node("Paper")
		and is_equal_approx(sheet_scene.spacing, SPACING) and (sheet_scene.paint as StandardMaterial3D).albedo_color.is_equal_approx(PAINT))
	check("hang() stands each member on the ground, 1.2 m from the last: the first at (0, 0.5, 0), the second at (1.2, 0.5, 0); a member nobody added stands with the sheet",
		near(loose.global_position, Vector3(0, 0.5, 0)) and near(painted.global_position, Vector3(SPACING, 0.5, 0)) and loose.get_parent() == sheet_scene
		and painted.get_parent() == root and sheet_scene.hung == [loose, painted])
	check("hang() writes the title on a plate at the member's feet and gives the sheet's paint to a member that has none; it leaves a member's own material, its fields and its mesh alone",
		sheet_scene.plates.size() == 2 and sheet_scene.plates[0].text == "first" and sheet_scene.plates[1].text == "second"
		and near(sheet_scene.plates[1].position, Vector3(SPACING, 0.02, 0.8)) and loose.material_override == sheet_scene.paint
		and painted.material_override == own and painted.mesh == mesh_before and loose.segments == 8 and loose.rings == 4 and loose.triangles() == 80)
	sheet_scene.free()
	painted.free()
	await process_frame

	# The study: family.tscn.
	var study := await open({})
	var family: Node3D = study.get_node("Family")
	var sheet: Node3D = study.get_node("Sheet")
	var marble: RigidBody3D = study.get_node("Marble")
	var b: Node3D = study.get_node("B")
	check("family.tscn inherits plane.tscn: the root runs plane.gd, with A, B, Segment, Strip, Record, Face, Marble and Under; no Cube, no Organism, no Body, no Chessboard",
		study.get_script().resource_path == "res://plane.gd" and study.has_node("A") and study.has_node("Segment") and study.has_node("Strip")
		and study.has_node("Record") and study.has_node("Face") and study.has_node("Under") and marble.get_script().resource_path == "res://marble.gd"
		and b.get_script().resource_path == "res://mover.gd" and not study.has_node("Cube") and not study.has_node("Organism")
		and not study.has_node("Body") and not study.has_node("Chessboard"))
	check("it adds two nodes at (-1.8, 0, 0.9): Sheet, an instance of sweep_sheet.tscn, and Family, a plain Node3D running family.gd; the marble waits at (3.2, 0.1, 1.2), clear of the sheet",
		sheet.scene_file_path == "res://sweep_sheet.tscn" and near(sheet.position, ROW_AT) and family.get_class() == "Node3D" and near(family.position, ROW_AT)
		and family.get_script().resource_path == "res://family.gd" and near(marble.position, Vector3(3.2, 0.1, 1.2)))
	var texts := {}
	for property: Dictionary in family.get_property_list():
		if property["name"] == "axis" or property["name"] == "values":
			texts[property["name"]] = property
	check("Family has two exported text fields: axis is \"%s\" and values is \"%s\"" % [family.axis, family.values],
		texts.size() == 2 and texts["axis"]["type"] == TYPE_STRING and texts["values"]["type"] == TYPE_STRING
		and (texts["axis"]["usage"] & PROPERTY_USAGE_EDITOR) != 0 and family.axis == "segments" and family.values == "4, 8, 16, 64")
	var all_globes := family.get_child_count() == 4
	var in_a_row := true
	var meshes := []
	for i in family.get_child_count():
		var member: MeshInstance3D = family.get_child(i)
		all_globes = all_globes and is_globe(member)
		in_a_row = in_a_row and near(member.global_position, ROW_AT + Vector3(i * SPACING, 0.5, 0)) and sheet.hung[i] == member
		if not meshes.has(member.mesh):
			meshes.append(member.mesh)
	check("the finished study: four members of the class under Family, with %s segments and %s rings, half of that; they list %s triangles" % [fields(study, "segments"), fields(study, "rings"), counted(study)[2]],
		all_globes and fields(study, "segments") == VALUES and fields(study, "rings") == [2, 4, 8, 32] and counted(study)[2] == LISTED)
	var one_paint := true
	for member: MeshInstance3D in family.get_children():
		one_paint = one_paint and member.material_override == sheet.paint
	check("they stand in a row on the sheet, 1.2 m apart, from (-1.8, 0.5, 0.9) to (1.8, 0.5, 0.9); the plates at their feet read 4, 8, 16 and 64; four meshes, one paint",
		in_a_row and counted(study)[4] == ["4", "8", "16", "64"] and meshes.size() == 4 and one_paint)
	measured["family"] = {"members": family.get_child_count(), "segments": fields(study, "segments"), "rings": fields(study, "rings"), "triangles": counted(study)[2], "plates": counted(study)[4]}

	# Walk the sheet: a member is there for the eye and not for a body.
	b.position.z = 0.9
	await press("drop", study)
	var through := await settle(marble)
	var reads := last_line(study)
	var third: MeshInstance3D = family.get_child(2)
	check("B walked 0.9 m towards us stands over the member of 16; M: the marble falls through the member to the ground and lies inside it, %.2f m from its middle: '%s'" % [(through - third.global_position).length(), reads],
		absf(through.y - 0.1) < 0.02 and reads == "marble at 0.10 m" and (through - third.global_position).length() < 0.5)
	var rests := []
	for member: MeshInstance3D in family.get_children():
		member.create_trimesh_collision()
	await physics_frame
	for member: MeshInstance3D in family.get_children():
		marble.drop(member.global_position + Vector3(0, 1.62, 0))
		rests.append(snappedf((await settle(marble)).y, 0.01))
	check("with a body from create_trimesh_collision(), the marble dropped over the middle rests on top of every member, at %.2f, %.2f, %.2f and %.2f m: on the point of the member of 4 as well" % rests,
		rests == [1.1, 1.1, 1.1, 1.1])
	measured["marble"] = {"through_a_member_m": snappedf(through.y, 0.001), "on_top_with_a_body_m": rests}
	await close(study)

	# Carry one member: the class makes the same body anywhere.
	study = await open({})
	var on_the_sheet: MeshInstance3D = study.get_node("Family").get_child(1)
	var carried: MeshInstance3D = GlobeScript.new()
	carried.segments = 8
	carried.rings = 4
	root.add_child(carried)
	check("a member carried by its numbers: Globe.new() with 8 and 4, added anywhere, has the same corners and the same triangles as the member of 8 on the sheet",
		carried.mesh != on_the_sheet.mesh and carried.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] == on_the_sheet.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
		and carried.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] == on_the_sheet.mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX] and carried.triangles() == 80)
	carried.free()
	await close(study)

	# The planted fault and its relatives, through family.gd as it is shipped.
	study = await open({"axis": "radial_segments"})
	check("the planted fault: with axis \"radial_segments\", a name the class does not have, four members come back alike: %s segments, %s triangles; the plates, which read back, say %s" % [fields(study, "segments"), counted(study)[2], counted(study)[4]],
		fields(study, "segments") == [16, 16, 16, 16] and counted(study)[2] == [288, 288, 288, 288] and counted(study)[3] == 1
		and counted(study)[4] == ["<null>", "<null>", "<null>", "<null>"])
	await close(study)
	study = await open({"axis": "rings", "values": "1, 2, 8, 32"})
	check("sweeping rings with the half rule still in the script gives four alike again, %s triangles, and the plates say so: %s" % [counted(study)[2], counted(study)[4]],
		counted(study)[3] == 1 and counted(study)[4] == ["8", "8", "8", "8"])
	await close(study)
	study = await open({"values": "4,8,16,64"})
	var tight: Array = counted(study)[2]
	await close(study)
	var no_commas := [0, [], []]
	if guarded:   # without the two lines in build() this would ask Godot for a sphere of 481664 segments
		study = await open({"values": "4 8 16 64"})
		no_commas = [counted(study)[0], fields(study, "segments"), counted(study)[2]]
		await close(study)
	study = await open({"values": ""})
	var nothing := [counted(study)[0], fields(study, "segments"), counted(study)[2]]
	await close(study)
	study = await open({"values": "4, 8, sixteen, 64"})
	var worded_out := [fields(study, "segments"), counted(study)[2]]
	await close(study)
	check("the text field: \"4,8,16,64\" builds %s; \"4 8 16 64\", with no commas, is ONE word, 481664, and the class builds %d member of %s segments; an empty text builds %d member of %s, with %s triangles; \"sixteen\" builds one of %d segments and %d triangles: 0 and 0, raised by the class to 4 and 1, the octahedron" % [
		tight, no_commas[0], no_commas[1], nothing[0], nothing[1], nothing[2], worded_out[0][2], worded_out[1][2]],
		tight == LISTED and no_commas == [1, [64], [4224]] and nothing == [1, [4], [16]] and worded_out == [[4, 8, 4, 64], [24, 80, 16, 4224]])

	# The process strip, step by step, as sheet.gd photographs it.
	var strip := []
	study = await open(null)
	family = study.get_node("Family")
	var written := SphereMesh.new()
	written.radial_segments = 16
	written.rings = 8
	var body := MeshInstance3D.new()
	body.mesh = written
	family.add_child(body)
	body.position = Vector3(0, 0.5, 0)
	strip.append(counted(study))
	var written_arrays := written.surface_get_arrays(0)
	var written_at := body.global_position
	await close(study)
	check("strip 1, a sphere written out: 1 body, not of the class, 288 triangles, no plate", strip[0] == [1, 0, [288], 1, []])
	study = await open(null)
	family = study.get_node("Family")
	var member: MeshInstance3D = GlobeScript.new()
	family.add_child(member)
	member.position = Vector3(0, 0.5, 0)
	strip.append(counted(study))
	var class_arrays := member.mesh.surface_get_arrays(0)
	check("strip 2, the same as a class: 1 body, of the class; the same corners, the same triangles, the same place: the picture cannot tell",
		strip[1] == [1, 1, [288], 1, []] and class_arrays[Mesh.ARRAY_VERTEX] == written_arrays[Mesh.ARRAY_VERTEX]
		and class_arrays[Mesh.ARRAY_INDEX] == written_arrays[Mesh.ARRAY_INDEX] and near(member.global_position, written_at))
	await close(study)
	study = await open(null)
	family = study.get_node("Family")
	var by_hand := []
	var place := 0
	for n: int in VALUES:
		member = GlobeScript.new()
		member.segments = n
		member.rings = n / 2
		family.add_child(member)
		member.position = Vector3(place * 1.2, 0.5, 0)
		by_hand.append(member.global_position)
		place += 1
	strip.append(counted(study))
	await close(study)
	check("strip 3, a row of four: 4 bodies of the class, 24, 80, 288 and 4224 triangles, four different bodies, no plate", strip[2] == [4, 4, LISTED, 4, []])
	study = await open(null)
	family = study.get_node("Family")
	var same_places := true
	for i in VALUES.size():
		member = GlobeScript.new()
		member.segments = VALUES[i]
		member.rings = VALUES[i] / 2
		family.add_child(member)
		study.get_node("Sheet").hang(member, str(VALUES[i]))
		same_places = same_places and near(member.global_position, by_hand[i]) and member.material_override == study.get_node("Sheet").paint
	strip.append(counted(study))
	await close(study)
	check("strip 4, hung and named: the same four bodies in the same four places, now painted, with 4 plates: 4, 8, 16, 64",
		strip[3] == [4, 4, LISTED, 4, ["4", "8", "16", "64"]] and same_places)
	study = await open(null)
	family = study.get_node("Family")
	for word: String in "4, 8, 16, 64".split(","):
		var title := word.strip_edges()
		member = GlobeScript.new()
		member.set("radial_segments", title)
		member.rings = member.segments / 2
		family.add_child(member)
		study.get_node("Sheet").hang(member, title)
	strip.append(counted(study))
	await close(study)
	check("strip 5, the axis by name, with the wrong name: 4 bodies, 288 triangles each, ONE body four times, under plates that read 4, 8, 16, 64",
		strip[4] == [4, 4, [288, 288, 288, 288], 1, ["4", "8", "16", "64"]])
	study = await open({})
	strip.append(counted(study))
	await close(study)
	check("strip 6, the right name: four different bodies again under the same four plates", strip[5] == [4, 4, LISTED, 4, ["4", "8", "16", "64"]])
	measured["strip"] = strip

	# process.png and sheet.png, read back tile by tile.
	var picture := Image.load_from_file(ProjectSettings.globalize_path("res://process.png"))
	var bytes := FileAccess.get_file_as_bytes("res://process.png").size()
	check("process.png is there: 6 tiles of 320 x 240 with a band of names under them, %d bytes" % bytes,
		picture != null and picture.get_width() == 6 * TILE.x + 5 * GUTTER and picture.get_height() > TILE.y and bytes < 300000)
	if picture != null:
		var tiles := []
		for i in 6:
			tiles.append(picture.get_region(Rect2i(i * (TILE.x + GUTTER), 0, TILE.x, TILE.y)))
		var shares := []
		for i in range(1, 6):
			shares.append(differ_pct(tiles[i], tiles[i - 1]))
		check("in process.png 'the same, as a class' differs from 'a sphere, written out' on %.2f%% of the tile; every later tile differs from the one before: %.2f, %.2f, %.2f and %.2f%%" % shares,
			shares[0] == 0.0 and shares[1] > 1.0 and shares[2] > 1.0 and shares[3] > 1.0 and shares[4] > 1.0)
		measured["process_png"] = {"bytes": bytes, "tile_differs_from_the_one_before_pct": shares}
	var sheet_picture := Image.load_from_file(ProjectSettings.globalize_path("res://sheet.png"))
	var sheet_bytes := FileAccess.get_file_as_bytes("res://sheet.png").size()
	check("sheet.png is there: the four members in four columns and three rows (from the side, from above, faceted), %d bytes" % sheet_bytes,
		sheet_picture != null and sheet_picture.get_width() == 4 * TILE.x + 3 * GUTTER and sheet_picture.get_height() > 3 * TILE.y and sheet_bytes < 300000)

	# The guest handed to the room.
	await guest_checks()

	# The sheet's record, if it has been rendered.
	if FileAccess.file_exists("res://sheet.json"):
		var record: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://sheet.json"))
		measured["sheet"] = record
		sheet_checks(record, strip)

	finish()

func finish() -> void:
	var passed := checks.all(func(c): return c.passed)
	var report := {"passed": passed, "godot": Engine.get_version_info().string, "measured": measured, "checks": checks}
	FileAccess.open("res://verification.json", FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	print("Families study: ", checks.size(), " checks; passed=", passed)
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

func pct(record: Dictionary, table: String, key: String, field := "differ_pct") -> float:
	return record.get(table, {}).get(key, {}).get(field, -1.0)

func sheet_checks(record: Dictionary, strip: Array) -> void:
	var members: Dictionary = record.get("members", {})
	var same := true
	for i in VALUES.size():
		var entry: Dictionary = members.get(str(VALUES[i]), {})
		same = same and int(entry.get("segments", 0)) == VALUES[i] and int(entry.get("rings", 0)) == VALUES[i] / 2
		same = same and int(entry.get("triangles", 0)) == LISTED[i] and int(entry.get("triangles_with_area", 0)) == WITH_AREA[i]
	check("sheet.json: with a window the four members are the four of the headless run: the same segments, rings and triangles", same)
	var views := ["level", "above", "turned", "faceted"]
	var closest_ok := true
	var numbers := []
	for view: String in views:
		closest_ok = closest_ok and record.get("closest_pair_" + view, "") == "16 vs 64"
		numbers.append(pct(record, "pairs_" + view, "16 vs 64"))
	check("sheet.json: the closest pair is 16 and 64 from all four standpoints: they differ on %.2f%% of the still from the side, %.2f%% from above, %.2f%% turned half a segment, %.2f%% faceted" % numbers, closest_ok)
	var four_ok := true
	for view: String in views:
		var nearest_to_four := minf(pct(record, "pairs_" + view, "4 vs 8"), minf(pct(record, "pairs_" + view, "4 vs 16"), pct(record, "pairs_" + view, "4 vs 64")))
		four_ok = four_ok and str(record.get("farthest_pair_" + view, "")).begins_with("4 vs") and nearest_to_four > pct(record, "pairs_" + view, "8 vs 64")
	check("sheet.json: the member of 4 stands apart from all four standpoints: its nearest sibling, 8, is farther from it (%.2f%% from the side) than 8 is from 64 (%.2f%%); 8 and 16 differ on %.2f%%" % [
		pct(record, "pairs_level", "4 vs 8"), pct(record, "pairs_level", "8 vs 64"), pct(record, "pairs_level", "8 vs 16")],
		four_ok and pct(record, "pairs_level", "4 vs 8") > 2.0 * pct(record, "pairs_level", "8 vs 16"))
	var rim_ok := true
	for view: String in ["level", "above", "turned"]:
		rim_ok = rim_ok and pct(record, "pairs_" + view, "16 vs 64", "rim_pct") > 0.8 * pct(record, "pairs_" + view, "16 vs 64")
	check("sheet.json: with smooth normals 16 and 64 differ on the rim and hardly inside: from the side %.2f%% of the still is rim, a band of %.2f pixels, and %.2f%% inside" % [
		pct(record, "pairs_level", "16 vs 64", "rim_pct"), pct(record, "pairs_level", "16 vs 64", "rim_px"), pct(record, "pairs_level", "16 vs 64", "inside_pct")], rim_ok)
	check("sheet.json: lit flat, the same two differ on %.2f%% of the still, %.2f%% of it inside the outline: the rim is the same %.2f%%; the smooth normals hid the rest" % [
		pct(record, "pairs_faceted", "16 vs 64"), pct(record, "pairs_faceted", "16 vs 64", "inside_pct"), pct(record, "pairs_faceted", "16 vs 64", "rim_pct")],
		pct(record, "pairs_faceted", "16 vs 64") > 4.0 * pct(record, "pairs_level", "16 vs 64")
		and pct(record, "pairs_faceted", "16 vs 64", "rim_pct") == pct(record, "pairs_level", "16 vs 64", "rim_pct")
		and pct(record, "pairs_faceted", "16 vs 64", "inside_pct") > 3.0 * pct(record, "pairs_faceted", "16 vs 64", "rim_pct"))
	var series := [4, 6, 8, 12, 16, 24, 32, 48]
	var falling := true
	var line := []
	for i in series.size():
		line.append(pct(record, "against_64_level", str(series[i])))
		if i > 0:
			falling = falling and line[i] < line[i - 1]
	check("sheet.json: against 64, from the side, the difference falls at every step and has no step of its own at 16: %.2f, %.2f, %.2f, %.2f, %.2f, %.2f, %.2f and %.2f%% for 4, 6, 8, 12, 16, 24, 32 and 48 segments" % line,
		falling and line[4] < 1.0 and line[7] < 0.1 and line[0] > 10.0)
	var misses_16: float = members.get("16", {}).get("outline_above", {}).get("misses_the_circle_by_pct", -1.0)
	var misses_64: float = members.get("64", {}).get("outline_above", {}).get("misses_the_circle_by_pct", -1.0)
	check("sheet.json: seen from above, the outline of 16 segments misses the circle by %.2f%% of the radius; the arithmetic says 1 - cos(11.25 degrees), 1.92%%; the member of 64 reads %.2f%%, about a pixel, which is as fine as this measure goes" % [misses_16, misses_64],
		misses_16 > 1.5 and misses_16 < 2.6 and misses_64 < 0.8 and is_equal_approx(snappedf(100.0 * (1.0 - cos(deg_to_rad(11.25))), 0.01), 1.92))
	var far: Dictionary = record.get("from_four_distances", {})
	var bands := []
	for distance: String in ["1.5 m", "2.0 m", "4.0 m", "8.0 m"]:
		bands.append(far.get(distance, {}).get("16 vs 64", {}).get("rim_px", -1.0))
	check("sheet.json: the rim between 16 and 64 is a band of %.2f pixels from 1.5 m, %.2f from 2 m, %.2f from 4 m and %.2f from 8 m: under one pixel only at 8 m" % bands,
		bands[1] > 2.0 and bands[2] > 1.0 and bands[3] < 1.0 and bands[3] > 0.0)
	var octahedron: Dictionary = record.get("octahedron", {})
	var nearer := int(octahedron.get("triangles", 0)) == 16 and int(octahedron.get("triangles_with_area", 0)) == 8
	for view: String in ["level", "above", "turned"]:
		nearer = nearer and octahedron.get("against_4_" + view, {}).get("differ_pct", 99.0) < pct(record, "pairs_" + view, "4 vs 8")
	check("sheet.json: the octahedron is 4 segments and ONE ring, 8 triangles with area; the member of 4 has two rings and 16. It differs from the octahedron on %.2f%% of the still from the side and %.2f%% from above: nearer than its sibling of 8 (%.2f%% and %.2f%%), and not the same body" % [
		octahedron.get("against_4_level", {}).get("differ_pct", -1.0), octahedron.get("against_4_above", {}).get("differ_pct", -1.0),
		pct(record, "pairs_level", "4 vs 8"), pct(record, "pairs_above", "4 vs 8")],
		nearer and octahedron.get("against_4_level", {}).get("differ_pct", 0.0) > 4.0)
	var nobody := int(record.get("primitives_drawn_with_nobody", -1))
	var with_4 := int(members.get("4", {}).get("primitives_drawn", -1))
	var with_64 := int(members.get("64", {}).get("primitives_drawn", -1))
	check("sheet.json: the renderer drew %d primitives with nobody on the sheet, %d with the member of 4 and %d with the member of 64: every listed triangle, slivers and all" % [nobody, with_4, with_64],
		nobody >= 0 and with_4 - nobody == 24 and with_64 - nobody == 4224)
	var steps: Array = record.get("strip", [])
	var counts_ok := steps.size() == 6
	if counts_ok:
		for i in 6:
			var got := [int(steps[i]["bodies"]), int(steps[i]["of_the_class"]), steps[i]["triangles"].map(func(v): return int(v)), int(steps[i]["different_bodies"]), steps[i]["plates"]]
			counts_ok = counts_ok and got == strip[i]
	check("sheet.json: with a window the strip's six steps counted what they count headless", counts_ok)
	check("sheet.json: 'the same, as a class' changed the picture on %.2f%% of the tile; the step that changed it most was '%s'" % [steps[1]["differs_from_step_before_pct"] if counts_ok else -1.0, record.get("strip_step_that_changed_most", "")],
		counts_ok and steps[1]["differs_from_step_before_pct"] == 0.0 and steps[4]["differs_from_step_before_pct"] > 1.0 and steps[5]["differs_from_step_before_pct"] > 1.0)
