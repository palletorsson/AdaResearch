extends SceneTree
## Headless checks for the Collage study. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; exit code 0 when every check passes.
## This study has classes with names and one imported file. Godot lists named
## classes and imports files when it imports a project, so a fresh copy needs
## one import before this runs:
##   godot --headless --path . --xr-mode off --import
## Headless draws no frames, so what the eye gets is measured by sheet.gd; here
## we check what the three bodies are made of (the class Solid and the hall's
## own solid, the drafted answer as it came back, the file found.gltf and what
## Godot's import makes of it, the class Found that gives it a unit and an
## origin), the planted fault, the finished study, the marble, the steps of the
## process strip, and that the earlier studies still run.

var checks := []
var measured := {}
var SolidScript: Script
var FoundScript: Script
var GlobeScript: Script
var DraftedScript: Script

const ROW_AT := Vector3(-1.8, 0, 0.9)       # where Sheet and Collage stand in the room
const SPACING := 1.2
const VALUES := ["by hand", "drafted", "found"]
const PAINT := Color(0.45, 0.38, 0.3)
const ORANGE := Color(0.62, 0.34, 0.12)     # the cube part's own material
const LIGHT := Color(0.62, 0.55, 0.4)       # the chessboard's two colours
const DARK := Color(0.08, 0.16, 0.2)
const TILE := Vector2i(320, 240)
const GUTTER := 4
const BOX := Vector3(0.789, 0.989, 0.789)   # the solid, in metres
const FOUND_TRIANGLES := 5851
const FOUND_CORNERS := 2993
const DRAFTED_MD5 := "e8ab9850ada3b58906faa554c2468312"         # the answer as it came back, line ends as \n

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

## The meshes of a body: the body itself if it is a mesh node, or the mesh
## nodes anywhere below it if it came from a file.
func parts(body: Node3D) -> Array:
	if body is MeshInstance3D:
		return [body]
	return body.find_children("*", "MeshInstance3D", true, false)

func listed(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	if arrays[Mesh.ARRAY_INDEX] == null:
		return arrays[Mesh.ARRAY_VERTEX].size() / 3
	return arrays[Mesh.ARRAY_INDEX].size() / 3

func corner_at(arrays: Array, i: int) -> Vector3:
	if arrays[Mesh.ARRAY_INDEX] == null:
		return arrays[Mesh.ARRAY_VERTEX][i]
	return arrays[Mesh.ARRAY_VERTEX][arrays[Mesh.ARRAY_INDEX][i]]

func with_area(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var count := 0
	for t in listed(mesh):
		var a := corner_at(arrays, t * 3)
		if (corner_at(arrays, t * 3 + 1) - a).cross(corner_at(arrays, t * 3 + 2) - a).length_squared() > 1e-16:
			count += 1
	return count

## Triangles whose front, the side their corners run clockwise from, faces away from the middle.
func outward(mesh: Mesh) -> int:
	var arrays := mesh.surface_get_arrays(0)
	var count := 0
	for t in listed(mesh):
		var a := corner_at(arrays, t * 3)
		var b := corner_at(arrays, t * 3 + 1)
		var c := corner_at(arrays, t * 3 + 2)
		if (b - a).cross(c - a).length_squared() > 1e-16 and Plane(a, b, c).normal.dot((a + b + c) / 3.0) > 0.0:
			count += 1
	return count

func different(points: PackedVector3Array, slack := 0.0001) -> Array[Vector3]:
	var seen: Array[Vector3] = []
	for v: Vector3 in points:
		var known := false
		for o in seen:
			if o.distance_to(v) < slack:
				known = true
				break
		if not known:
			seen.append(v)
	return seen

func corners_of(mesh: Mesh) -> Array[Vector3]:
	return different(mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX])

## How far the farthest point of `a` is from its nearest point of `b`.
func apart(a: Array[Vector3], b: Array[Vector3]) -> float:
	var worst := 0.0
	for v in a:
		var nearest := 1.0e9
		for o in b:
			nearest = minf(nearest, o.distance_to(v))
		worst = maxf(worst, nearest)
	return worst

## The flat faces of a mesh: triangles grouped by the direction they face.
## Returns for each face the numbers of its corners (in `corners`), in order around it.
func faces_of(mesh: Mesh, corners: Array[Vector3]) -> Array:
	var arrays := mesh.surface_get_arrays(0)
	var groups := {}
	for t in listed(mesh):
		var a := corner_at(arrays, t * 3)
		var b := corner_at(arrays, t * 3 + 1)
		var c := corner_at(arrays, t * 3 + 2)
		if (b - a).cross(c - a).length_squared() < 1e-16:
			continue
		var facing := Plane(a, b, c).normal
		for known: Vector3 in groups:
			if known.distance_to(facing) < 0.01:
				facing = known
		if not groups.has(facing):
			groups[facing] = []
		for p: Vector3 in [a, b, c]:
			for k in corners.size():
				if corners[k].distance_to(p) < 0.0001 and not groups[facing].has(k):
					groups[facing].append(k)
	var out := []
	for facing: Vector3 in groups:
		var ring: Array = groups[facing]
		var middle := Vector3.ZERO
		for k: int in ring:
			middle += corners[k]
		middle /= ring.size()
		var first: Vector3 = (corners[ring[0]] - middle).normalized()
		var side: Vector3 = facing.cross(first).normalized()
		ring.sort_custom(func(p: int, q: int) -> bool:
			return atan2((corners[p] - middle).dot(side), (corners[p] - middle).dot(first)) < atan2((corners[q] - middle).dot(side), (corners[q] - middle).dot(first)))
		out.append(ring)
	return out

func edges_of(faces: Array) -> int:
	var seen := {}
	for ring: Array in faces:
		for i in ring.size():
			var p: int = ring[i]
			var q: int = ring[(i + 1) % ring.size()]
			seen[Vector2i(mini(p, q), maxi(p, q))] = true
	return seen.size()

func sharpest_deg(faces: Array, corners: Array[Vector3], with_corners: int) -> float:
	var least := 360.0
	for ring: Array in faces:
		if ring.size() != with_corners:
			continue
		for i in ring.size():
			var here := corners[ring[i]]
			var before := corners[ring[(i + ring.size() - 1) % ring.size()]]
			var after := corners[ring[(i + 1) % ring.size()]]
			least = minf(least, rad_to_deg((before - here).angle_to(after - here)))
	return least

## The solid as the hall's own script builds it (commons/scenes/demos/durer/
## DurerPolyhedron.gd in the Ada project): a cube stretched along its diagonal
## for a face angle of 72 degrees, the diagonal upright, clipped at 0.38 of the
## height of the edges that leave each end. Here for a cube of 0.5 m.
func hall_corners() -> Array[Vector3]:
	var diagonal := Vector3.ONE.normalized()
	var cosine := cos(deg_to_rad(72.0))
	var stretch := sqrt((1.0 + 2.0 * cosine) / (1.0 - cosine))
	var align := Quaternion(diagonal, Vector3.UP)
	var cube := []
	var placed: Array[Vector3] = []
	for x in [-1, 1]:
		for y in [-1, 1]:
			for z in [-1, 1]:
				var v := Vector3(x, y, z)
				cube.append(v)
				placed.append(align * (v + diagonal * (stretch - 1.0) * v.dot(diagonal)) * 0.25)
	var limit := (stretch * sqrt(3.0) - 0.38 * (2.0 * stretch / sqrt(3.0))) * 0.25
	var out: Array[Vector3] = []
	for i in 8:
		if absf(placed[i].y) <= limit:
			out.append(placed[i])
		for j in range(i + 1, 8):
			if (cube[i] - cube[j]).length() > 2.01:
				continue   # not an edge of the cube
			for level: float in [limit, -limit]:
				if (placed[i].y - level) * (placed[j].y - level) < 0.0:
					out.append(placed[i].lerp(placed[j], (level - placed[i].y) / (placed[j].y - placed[i].y)))
	measured["hall_stretch_for_72_degrees"] = stretch
	return out

## The box of a body in the room, in metres, from its corners where they stand.
func box_of(body: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for part: MeshInstance3D in parts(body):
		for v: Vector3 in part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
			var at := part.global_transform * v
			box = AABB(at, Vector3.ZERO) if first else box.expand(at)
			first = false
	return box

func round3(v: Vector3) -> Vector3:
	return v.snappedf(0.001)

## A field read by its name: the number it holds, or not-a-number if the class has no such field.
func num(node: Object, field: String) -> float:
	var value: Variant = node.get(field)
	return float(value) if value is float or value is int else NAN

## Two lists alike: numbers with decimals to the millimetre, everything else exactly.
func alike(got: Array, want: Array) -> bool:
	if got.size() != want.size():
		return false
	for i in got.size():
		if got[i] is Array and want[i] is Array:
			if not alike(got[i], want[i]):
				return false
		elif (got[i] is float or got[i] is int) and (want[i] is float or want[i] is int):
			if absf(got[i] - want[i]) > 0.0015:
				return false
		elif got[i] != want[i]:
			return false
	return true

## One study. `setup` is a dictionary of Collage's variables to set before it is
## built; null takes the script off Collage, for the steps built by hand.
func open(setup: Variant) -> Node3D:
	var study: Node3D = load("res://collage.tscn").instantiate()
	var collage: Node3D = study.get_node("Collage")
	if setup == null:
		collage.set_script(null)
	else:
		for key: String in setup:
			collage.set(key, setup[key])
	root.add_child(study)
	await frames(2)
	await physics_frame
	study.set_process(false)
	study.get_node("B").set_process(false)
	return study

func close(study: Node3D) -> void:
	study.free()
	await process_frame

## What a step of the strip claims: the bodies under Collage, the triangles with
## area of each, the corners and the height of the first, how high the last one
## stands, where its lowest point is, how far its middle is from its plate,
## and what the plates say.
func counted(study: Node3D) -> Array:
	var collage: Node3D = study.get_node("Collage")
	var sheet: Node3D = study.get_node("Sheet")
	var made := collage.get_children()
	var counts := []
	for body: Node3D in made:
		counts.append(with_area(parts(body)[0].mesh))
	var titles := []
	for plate: Label3D in sheet.plates:
		titles.append(plate.text)
	var first: MeshInstance3D = parts(made[0])[0]
	var last := box_of(made[-1])
	var plate_at: Vector3 = sheet.to_global(Vector3((made.size() - 1) * sheet.spacing, 0.0, 0.0))
	var middle := last.get_center()
	return [made.size(), counts, titles, corners_of(first.mesh).size(), snappedf(box_of(made[0]).size.y, 0.001),
		snappedf(last.size.y, 0.001), snappedf(last.position.y, 0.001), snappedf(Vector2(middle.x - plate_at.x, middle.z - plate_at.z).length(), 0.001)]

func press(action: String, study: Node) -> void:
	await process_frame
	Input.action_press(action)
	study._process(0)
	Input.action_release(action)
	await process_frame

func last_line(study: Node) -> String:
	study._process(0)
	return study.get_node("Record").text.split("\n")[-1]

func exported(node: Object, names: Array) -> Dictionary:
	var out := {}
	for property: Dictionary in node.get_property_list():
		if names.has(property["name"]) and (property["usage"] & PROPERTY_USAGE_EDITOR) != 0 and (property["usage"] & PROPERTY_USAGE_SCRIPT_VARIABLE) != 0:
			out[property["name"]] = property
	return out

func run() -> void:
	# The named classes and the imported file have to be there before anything can load.
	var named := {}
	for entry: Dictionary in ProjectSettings.get_global_class_list():
		named[entry["class"]] = entry
	if not named.has("Solid") or not named.has("Found") or not named.has("Globe") or not ResourceLoader.exists("res://found.gltf"):
		print("Godot has not listed this project's named classes or imported found.gltf yet. Run this once, then run verify.gd again:")
		print("  godot --headless --path . --xr-mode off --import")
		quit(1)
		return
	SolidScript = load("res://solid.gd")
	FoundScript = load("res://found.gd")
	GlobeScript = load("res://globe.gd")
	DraftedScript = load("res://drafted_solid.gd")

	# The project and the Input Map: the nine actions of the earlier studies, unchanged.
	check("the project is named 'Collage' and its main scene is collage.tscn",
		ProjectSettings.get_setting("application/config/name") == "Collage"
		and ProjectSettings.get_setting("application/run/main_scene") == "res://collage.tscn")
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
	check("line.tscn, trace.tscn and plane.tscn still run on their own: '1.50 m', '1 kept', 'open', and none of them has a Sheet or a Collage",
		lines.get_node("Readout").text == "1.50 m" and trace_study.get_node("Record").text.begins_with("1 kept")
		and plane_study.get_node("Record").text.contains("open") and not plane_study.has_node("Sheet") and not plane_study.has_node("Collage"))
	lines.free()
	trace_study.free()
	plane_study.free()
	var cube_study: Node3D = load("res://cube.tscn").instantiate()
	root.add_child(cube_study)
	await frames(2)
	var old_cube: MeshInstance3D = cube_study.get_node("Cube")
	check("cube.tscn still runs on its own: its Cube is an instance of the cube part at (1.05, 1.37, 0.6), 12 outward triangles, orange",
		old_cube.scene_file_path == "res://parts/cube_part.tscn" and old_cube.position.is_equal_approx(Vector3(1.05, 1.37, 0.6))
		and outward(old_cube.mesh) == 12 and old_cube.material_override.albedo_color.is_equal_approx(ORANGE))
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
	check("chessboard.tscn still runs on its own: 64 cubes, 64 materials, 32 light and 32 dark, one ghost at cell (5, 5)",
		board.cubes.size() == 64 and board.count_materials() == 64 and lights == 32 and darks == 32 and ghosts == [5 * 8 + 5])
	chess_study.free()
	var family_study: Node3D = load("res://family.tscn").instantiate()
	root.add_child(family_study)
	await frames(2)
	var globes := []
	var all_globes := true
	for member: MeshInstance3D in family_study.get_node("Family").get_children():
		globes.append(member.triangles())
		all_globes = all_globes and member.get_script() == GlobeScript
	var globe_plates := []
	for plate: Label3D in family_study.get_node("Sheet").plates:
		globe_plates.append(plate.text)
	check("family.tscn still runs on its own: four members of the class Globe, %s triangles, under plates %s; it has no Collage" % [globes, globe_plates],
		all_globes and globes == [24, 80, 288, 4224] and globe_plates == ["4", "8", "16", "64"] and not family_study.has_node("Collage"))
	family_study.free()
	await process_frame

	# The class Solid.
	var source := FileAccess.get_file_as_string("res://solid.gd")
	var first: MeshInstance3D = SolidScript.new()
	check("solid.gd begins 'class_name Solid' and 'extends MeshInstance3D'; Godot lists Solid as a class whose base is MeshInstance3D",
		source.begins_with("class_name Solid\nextends MeshInstance3D\n") and named["Solid"]["base"] == "MeshInstance3D"
		and named["Solid"]["path"] == "res://solid.gd" and first is MeshInstance3D)
	var fields := exported(first, ["stretch", "cut"])
	var ranged := fields.size() == 2
	for name: String in fields:
		ranged = ranged and fields[name]["type"] == TYPE_FLOAT and fields[name]["hint"] == PROPERTY_HINT_RANGE
	check("its two fields are exported numbers with decimals and a range: stretch %s, from 1 to 2, and cut %s, from 0 to 0.5" % [num(first, "stretch"), num(first, "cut")],
		ranged and is_equal_approx(num(first, "stretch"), 1.53) and is_equal_approx(num(first, "cut"), 0.38)
		and Array(fields["stretch"]["hint_string"].split_floats(",")) == [1.0, 2.0] and Array(fields["cut"]["hint_string"].split_floats(",")) == [0.0, 0.5])
	var before_entering: Mesh = first.mesh
	var bench := Node3D.new()
	bench.name = "Bench"
	root.add_child(bench)
	bench.add_child(first)
	var ours := corners_of(first.mesh)
	var our_arrays := first.mesh.surface_get_arrays(0)
	var our_normals := different(our_arrays[Mesh.ARRAY_NORMAL], 0.001)
	check("a member has no mesh until it enters the room; then build() makes one: %d triangles, all with area, all facing outward; %d corners listed, three for each triangle, and no list of corner numbers" % [first.triangles(), our_arrays[Mesh.ARRAY_VERTEX].size()],
		before_entering == null and first.triangles() == 20 and listed(first.mesh) == 20 and with_area(first.mesh) == 20 and outward(first.mesh) == 20
		and our_arrays[Mesh.ARRAY_VERTEX].size() == 60 and our_arrays[Mesh.ARRAY_INDEX] == null)
	var our_faces := faces_of(first.mesh, ours)
	var fives := 0
	var threes := 0
	for ring: Array in our_faces:
		if ring.size() == 5:
			fives += 1
		if ring.size() == 3:
			threes += 1
	var edges := edges_of(our_faces)
	check("it is a closed solid of %d corners, %d edges and %d flat faces, %d with five corners and %d with three: %d - %d + %d = 2; every face is lit flat: %d directions for %d faces" % [
		ours.size(), edges, our_faces.size(), fives, threes, ours.size(), edges, our_faces.size(), our_normals.size(), our_faces.size()],
		ours.size() == 12 and edges == 18 and our_faces.size() == 8 and fives == 6 and threes == 2 and ours.size() - edges + our_faces.size() == 2 and our_normals.size() == 8)
	var size := first.get_aabb().size
	var sharpest := sharpest_deg(our_faces, ours, 5)
	check("it stands %.3f m high in a box %.3f m wide and deep, its middle at the node's origin; the sharpest corner of a five-cornered face is %.2f degrees" % [size.y, size.x, sharpest],
		near(round3(size), BOX) and near(first.get_aabb().get_center(), Vector3.ZERO, 0.001) and absf(sharpest - 72.0) < 0.05)
	var theirs := hall_corners()
	var gap := maxf(apart(ours, theirs), apart(theirs, ours))
	check("it is the hall's solid: the %d corners of DurerPolyhedron.gd's construction, for a cube of 0.5 m, lie within %.2f mm of ours. The hall works its stretch out from 72 degrees, %.4f; ours is that number to two decimals" % [theirs.size(), gap * 1000.0, measured["hall_stretch_for_72_degrees"]],
		theirs.size() == 12 and gap < 0.0002 and absf(measured["hall_stretch_for_72_degrees"] - 1.53) < 0.001)
	measured["solid"] = {"triangles": first.triangles(), "corners": ours.size(), "edges": edges, "faces": our_faces.size(), "box_m": [size.x, size.y, size.z], "sharpest_face_corner_deg": sharpest, "mm_from_the_halls": gap * 1000.0}
	var uncut: MeshInstance3D = SolidScript.new()
	uncut.set("cut", 0.0)
	bench.add_child(uncut)
	var plain: MeshInstance3D = SolidScript.new()
	plain.set("stretch", 1.0)
	plain.set("cut", 0.0)
	bench.add_child(plain)
	check("the two fields are the two operations: with cut 0 the member is the pulled cube on its point, %d corners, %.3f m high, %d of its %d listed triangles with area; with stretch 1 as well it is the cube of Point Cube on a corner, %.3f m high" % [
		corners_of(uncut.mesh).size(), uncut.get_aabb().size.y, with_area(uncut.mesh), uncut.triangles(), plain.get_aabb().size.y],
		corners_of(uncut.mesh).size() == 8 and absf(uncut.get_aabb().size.y - 1.325) < 0.001 and with_area(uncut.mesh) == 12 and uncut.triangles() == 20
		and absf(plain.get_aabb().size.y - 0.5 * sqrt(3.0)) < 0.001 and corners_of(plain.mesh).size() == 8)
	var wild: MeshInstance3D = SolidScript.new()
	wild.set("stretch", 3.0)
	wild.set("cut", 0.9)
	bench.add_child(wild)
	check("build() is where the class decides: asked for a stretch of 3 and a cut of 0.9, the fields say %s and %s and the member stands %.3f m high" % [num(wild, "stretch"), num(wild, "cut"), wild.get_aabb().size.y],
		is_equal_approx(num(wild, "stretch"), 2.0) and is_equal_approx(num(wild, "cut"), 0.5) and wild.triangles() == 20 and outward(wild.mesh) == 20)

	# The drafted answer, as it came back.
	var answer := FileAccess.get_file_as_string("res://drafted_solid.gd").replace("\r", "")
	var drafted: MeshInstance3D = DraftedScript.new()
	check("drafted_solid.gd is the answer as it came back, unedited (md5 %s); it extends MeshInstance3D and has no class_name" % answer.md5_text(),
		answer.md5_text() == DRAFTED_MD5 and answer.begins_with("extends MeshInstance3D\n") and not answer.contains("class_name") and drafted is MeshInstance3D)
	var drafted_fields := exported(drafted, ["stretch", "cut"])
	var no_mesh_yet: bool = drafted.mesh == null
	bench.add_child(drafted)
	var drafted_arrays := drafted.mesh.surface_get_arrays(0)
	check("it kept the second line: two exported fields, stretch %s and cut %s, with no range; build() runs from _ready(); triangles() says %d" % [num(drafted, "stretch"), num(drafted, "cut"), drafted.triangles()],
		drafted_fields.size() == 2 and drafted_fields["stretch"]["type"] == TYPE_FLOAT and drafted_fields["cut"]["type"] == TYPE_FLOAT
		and drafted_fields["stretch"]["hint"] == PROPERTY_HINT_NONE and is_equal_approx(num(drafted, "stretch"), 1.53) and is_equal_approx(num(drafted, "cut"), 0.38)
		and no_mesh_yet and drafted.triangles() == 20 and drafted.has_method("build"))
	var its := corners_of(drafted.mesh)
	var between := maxf(apart(ours, its), apart(its, ours))
	check("it passes the third line: its box is %s m, all %d of its triangles face outward, and nothing was printed" % [round3(drafted.get_aabb().size), outward(drafted.mesh)],
		near(round3(drafted.get_aabb().size), BOX) and outward(drafted.mesh) == 20 and with_area(drafted.mesh) == 20)
	check("it is the same body as ours: its %d corners lie within %.4f mm of ours. It is written down another way: %d corners listed and a list of %d corner numbers, where ours lists %d corners and no numbers" % [
		its.size(), between * 1000.0, drafted_arrays[Mesh.ARRAY_VERTEX].size(), drafted_arrays[Mesh.ARRAY_INDEX].size(), our_arrays[Mesh.ARRAY_VERTEX].size()],
		its.size() == 12 and between < 0.00001 and drafted_arrays[Mesh.ARRAY_VERTEX].size() == 36 and drafted_arrays[Mesh.ARRAY_INDEX].size() == 60)
	var far: MeshInstance3D = DraftedScript.new()
	far.set("stretch", 3.0)
	far.set("cut", 0.9)
	bench.add_child(far)
	var deep: MeshInstance3D = DraftedScript.new()
	deep.set("cut", 0.9)
	bench.add_child(deep)
	var bare: MeshInstance3D = DraftedScript.new()
	bare.set("cut", 0.0)
	bench.add_child(bare)
	var ours_deep: MeshInstance3D = SolidScript.new()
	ours_deep.set("cut", 0.9)
	bench.add_child(ours_deep)
	check("the two part where the three lines were silent: asked for a cut of 0.9, ours says %s and stands %.3f m, the drafted one says %s and stands %.3f m; asked for a stretch of 3 it says %s; with cut 0 it lists %d triangles where ours lists %d" % [
		num(ours_deep, "cut"), ours_deep.get_aabb().size.y, num(deep, "cut"), deep.get_aabb().size.y, num(far, "stretch"), bare.triangles(), uncut.triangles()],
		is_equal_approx(num(ours_deep, "cut"), 0.5) and absf(ours_deep.get_aabb().size.y - 0.883) < 0.001 and is_equal_approx(num(deep, "cut"), 0.9) and absf(deep.get_aabb().size.y - 0.530) < 0.001
		and is_equal_approx(num(far, "stretch"), 3.0) and bare.triangles() == 18 and uncut.triangles() == 20 and outward(deep.mesh) == 20)
	measured["drafted"] = {"md5": answer.md5_text(), "triangles": drafted.triangles(), "corners_listed": drafted_arrays[Mesh.ARRAY_VERTEX].size(), "mm_from_ours": between * 1000.0,
		"cut_0.9": {"ours_says": num(ours_deep, "cut"), "ours_height_m": ours_deep.get_aabb().size.y, "drafted_says": num(deep, "cut"), "drafted_height_m": deep.get_aabb().size.y}}
	bench.free()
	await process_frame

	# The found body: the file.
	var text := FileAccess.get_file_as_string("res://found.gltf")
	var gltf: Dictionary = JSON.parse_string(text)
	var low: Array = gltf["accessors"][0]["min"]
	var high: Array = gltf["accessors"][0]["max"]
	check("found.gltf is one text file of %d bytes that says what it is: '%s'" % [text.length(), gltf["asset"]["generator"]],
		text.length() < 300000 and str(gltf["asset"]["generator"]).contains("stand-in") and str(gltf["asset"]["generator"]).contains("not scanned")
		and gltf["meshes"].size() == 1 and gltf["nodes"].size() == 1 and gltf["materials"].size() == 1 and gltf["materials"][0]["doubleSided"] == false)
	check("its numbers are centimetres: the corners it lists reach from (%.1f, %.1f, %.1f) to (%.1f, %.1f, %.1f), %.1f high, around a point that is not its own middle" % [low[0], low[1], low[2], high[0], high[1], high[2], high[1] - low[1]],
		absf(high[1] - low[1] - 99.04) < 0.01 and absf(low[1] - 4.3) < 0.001 and absf((low[0] + high[0]) / 2.0 - 37.0) < 0.2 and absf((low[2] + high[2]) / 2.0 + 21.8) < 0.2)
	var import_text := FileAccess.get_file_as_string("res://found.gltf.import")
	check("Godot imported it with the settings it chooses by itself: root scale 1.0, no root type, nothing extra for single nodes; this kit ships no .import file",
		import_text.contains("nodes/root_scale=1.0") and import_text.contains("nodes/root_type=\"\"") and import_text.contains("_subresources={}"))
	var scene: PackedScene = load("res://found.gltf")
	var raw: Node3D = scene.instantiate()
	root.add_child(raw)
	var raw_part: MeshInstance3D = raw.get_child(0)
	var raw_box := raw_part.get_aabb()
	var raw_arrays := raw_part.mesh.surface_get_arrays(0)
	check("what Godot makes of it: a Node3D named '%s' with %d child, a MeshInstance3D named '%s' with an ArrayMesh of %d surface; neither is moved, turned or scaled" % [raw.name, raw.get_child_count(), raw_part.name, raw_part.mesh.get_surface_count()],
		raw.get_class() == "Node3D" and raw.name == "scan" and raw.get_child_count() == 1 and raw_part.name == "scan_mesh" and raw_part.mesh is ArrayMesh
		and raw_part.mesh.get_surface_count() == 1 and raw.transform == Transform3D.IDENTITY and raw_part.transform == Transform3D.IDENTITY)
	check("it arrives 100 times too large: its box is %s, 99 METRES high, its lowest point 4.3 m above its own origin and its middle 43 m to one side" % raw_box,
		absf(raw_box.size.y - 99.039) < 0.01 and absf(raw_box.position.y - 4.3) < 0.001 and absf(raw_box.size.x - 75.615) < 0.01 and absf(raw_box.size.z - 75.027) < 0.01
		and absf(Vector2(raw_box.get_center().x, raw_box.get_center().z).length() - 42.95) < 0.1)
	check("many triangles: %d corners and a list of %d corner numbers, %d triangles, all with area: %d times the %d of the solid by hand" % [
		raw_arrays[Mesh.ARRAY_VERTEX].size(), raw_arrays[Mesh.ARRAY_INDEX].size(), listed(raw_part.mesh), roundi(listed(raw_part.mesh) / 20.0), 20],
		raw_arrays[Mesh.ARRAY_VERTEX].size() == FOUND_CORNERS and listed(raw_part.mesh) == FOUND_TRIANGLES and with_area(raw_part.mesh) == FOUND_TRIANGLES and roundi(FOUND_TRIANGLES / 20.0) == 293)
	var index: PackedInt32Array = raw_arrays[Mesh.ARRAY_INDEX]
	var uses := {}
	for t in index.size() / 3:
		for k in 3:
			var p := index[t * 3 + k]
			var q := index[t * 3 + (k + 1) % 3]
			var edge := Vector2i(mini(p, q), maxi(p, q))
			uses[edge] = uses.get(edge, 0) + 1
	var open_edges := []
	for edge: Vector2i in uses:
		if uses[edge] == 1:
			open_edges.append(edge)
	var loop_of := {}
	for edge: Vector2i in open_edges:
		for p: int in [edge.x, edge.y]:
			if not loop_of.has(p):
				loop_of[p] = p
	var changed := true
	while changed:
		changed = false
		for edge: Vector2i in open_edges:
			var least: int = mini(loop_of[edge.x], loop_of[edge.y])
			if loop_of[edge.x] != least or loop_of[edge.y] != least:
				loop_of[edge.x] = least
				loop_of[edge.y] = least
				changed = true
	var loops := {}
	var corners_3d: PackedVector3Array = raw_arrays[Mesh.ARRAY_VERTEX]
	for p: int in loop_of:
		if not loops.has(loop_of[p]):
			loops[loop_of[p]] = []
		loops[loop_of[p]].append(corners_3d[p].y)
	var loop_heights := []
	for key: int in loops:
		var sum := 0.0
		for y: float in loops[key]:
			sum += y
		loop_heights.append(snappedf(sum / loops[key].size() - raw_box.position.y, 0.1))
	loop_heights.sort()
	var material := raw_part.mesh.surface_get_material(0) as StandardMaterial3D
	check("holes and no inside: %d of its edges belong to one triangle only, in %d rings, one around its foot and one on top (on average %s units above its lowest point); its material '%s' is drawn from one side" % [
		open_edges.size(), loops.size(), loop_heights, material.resource_name if material else "none"],
		open_edges.size() > 50 and loops.size() == 2 and loop_heights[0] < 3.0 and loop_heights[1] > 90.0 and material != null
		and material.resource_name == "scan_paper" and material.cull_mode == BaseMaterial3D.CULL_BACK and raw_part.material_override == null)
	measured["found_file"] = {"bytes": text.length(), "triangles": listed(raw_part.mesh), "corners": raw_arrays[Mesh.ARRAY_VERTEX].size(), "box_as_it_arrives": str(raw_box), "open_edges": open_edges.size(), "open_rings": loops.size()}
	raw.free()

	# The class Found.
	var found_source := FileAccess.get_file_as_string("res://found.gd")
	var guest: Node3D = FoundScript.new()
	var guest_fields := exported(guest, ["file", "unit"])
	check("found.gd begins 'class_name Found' and 'extends Node3D'; its two exported fields are a text and a number: file '%s' and unit %s" % [guest.get("file"), num(guest, "unit")],
		found_source.begins_with("class_name Found\nextends Node3D\n") and named["Found"]["base"] == "Node3D" and guest_fields.size() == 2
		and guest_fields["file"]["type"] == TYPE_STRING and guest_fields["unit"]["type"] == TYPE_FLOAT and str(guest.get("file")) == "res://found.gltf" and is_equal_approx(num(guest, "unit"), 0.01))
	var nothing_yet: bool = guest.get_child_count() == 0 and guest.get("part") == null
	root.add_child(guest)
	var guest_box := box_of(guest)
	var guest_foot := Vector3(guest_box.get_center().x, guest_box.position.y, guest_box.get_center().z)
	check("a Found holds nothing until it enters the room; then build() brings the file in, gives it its unit and moves the middle of its foot to the node's origin: it stands %.3f m high in a box %.3f by %.3f m, its foot %.1f mm from the origin; triangles() says %d" % [
		guest_box.size.y, guest_box.size.x, guest_box.size.z, guest_foot.length() * 1000.0, guest.triangles()],
		nothing_yet and guest.get_child_count() == 1 and guest.get("part") is MeshInstance3D and near(guest.get_child(0).scale, Vector3.ONE * 0.01, 0.00001)
		and absf(guest_box.size.y - 0.990) < 0.001 and absf(guest_box.size.x - 0.756) < 0.001 and absf(guest_box.size.z - 0.750) < 0.001
		and guest_foot.length() < 0.0005 and guest.triangles() == FOUND_TRIANGLES)
	measured["found"] = {"height_m": guest_box.size.y, "width_m": guest_box.size.x, "depth_m": guest_box.size.z, "triangles": guest.triangles()}
	guest.free()
	var giant: Node3D = FoundScript.new()
	giant.set("unit", 1.0)
	root.add_child(giant)
	check("the unit is the whole repair of the size: with unit 1.0 the same body stands %.2f m high on the same spot" % box_of(giant).size.y,
		absf(box_of(giant).size.y - 99.039) < 0.01 and absf(box_of(giant).position.y) < 0.001)
	giant.free()
	await process_frame

	# The supplied sheet, with a body that is a mesh and a body that is not.
	var sheet_scene: Node3D = load("res://sweep_sheet.tscn").instantiate()
	root.add_child(sheet_scene)
	var mesh_member: MeshInstance3D = SolidScript.new()
	var file_member: Node3D = FoundScript.new()
	sheet_scene.hang(mesh_member, "first")
	sheet_scene.hang(file_member, "second")
	check("the sheet stands a mesh on its foot and paints it; a body from a file it stands where the body's own origin is and leaves in its own material: the first at %s, the second at %s" % [round3(mesh_member.global_position), round3(file_member.global_position)],
		near(mesh_member.global_position, Vector3(0, 0.495, 0), 0.001) and mesh_member.material_override == sheet_scene.paint
		and near(file_member.global_position, Vector3(SPACING, 0, 0)) and parts(file_member)[0].material_override == null and absf(box_of(file_member).position.y) < 0.001)
	sheet_scene.free()
	await process_frame

	# The study: collage.tscn.
	var study := await open({})
	var collage: Node3D = study.get_node("Collage")
	var sheet: Node3D = study.get_node("Sheet")
	var marble: RigidBody3D = study.get_node("Marble")
	var b: Node3D = study.get_node("B")
	check("collage.tscn inherits plane.tscn: the root runs plane.gd, with A, B, Segment, Strip, Record, Face, Marble and Under; no Cube, no Organism, no Body, no Chessboard, no Family",
		study.get_script().resource_path == "res://plane.gd" and study.has_node("A") and study.has_node("Segment") and study.has_node("Strip")
		and study.has_node("Record") and study.has_node("Face") and study.has_node("Under") and marble.get_script().resource_path == "res://marble.gd"
		and b.get_script().resource_path == "res://mover.gd" and not study.has_node("Cube") and not study.has_node("Organism")
		and not study.has_node("Body") and not study.has_node("Chessboard") and not study.has_node("Family"))
	check("it adds two nodes at (-1.8, 0, 0.9): Sheet, an instance of sweep_sheet.tscn, and Collage, a plain Node3D running collage.gd; the marble waits at (3.2, 0.1, 1.2)",
		sheet.scene_file_path == "res://sweep_sheet.tscn" and near(sheet.position, ROW_AT) and collage.get_class() == "Node3D" and near(collage.position, ROW_AT)
		and collage.get_script().resource_path == "res://collage.gd" and near(marble.position, Vector3(3.2, 0.1, 1.2)))
	var axis := exported(collage, ["made"])
	check("Collage has one exported text field, the axis: made is \"%s\"" % collage.get("made"),
		axis.size() == 1 and axis["made"]["type"] == TYPE_STRING and str(collage.get("made")) == "by hand, drafted, found")
	var kinds := [collage.get_child(0).get_script() == SolidScript, collage.get_child(1).get_script() == DraftedScript, collage.get_child(2).get_script() == FoundScript]
	var c := counted(study)
	check("the finished study: three bodies under Collage, one of the class Solid, one from the drafted script, one of the class Found; they have %s triangles with area under plates %s" % [c[1], c[2]],
		collage.get_child_count() == 3 and kinds == [true, true, true] and c[1] == [20, 20, FOUND_TRIANGLES] and c[2] == VALUES)
	var standing := true
	var heights := []
	for i in 3:
		var body: Node3D = collage.get_child(i)
		var box := box_of(body)
		heights.append(snappedf(box.size.y, 0.001))
		standing = standing and absf(box.position.y) < 0.001 and absf(box.get_center().x - (ROW_AT.x + i * SPACING)) < 0.001 and absf(box.get_center().z - ROW_AT.z) < 0.001 and sheet.hung[i] == body
	var two_painted: bool = collage.get_child(0).material_override == sheet.paint and collage.get_child(1).material_override == sheet.paint
	check("they stand in a row on the sheet, 1.2 m apart, each with its lowest point on the ground and its middle over its place; they are %s m high; the sheet painted the two made bodies, the found one wears the material its file brought" % [heights],
		standing and alike(heights, [0.989, 0.989, 0.99]) and two_painted and parts(collage.get_child(2))[0].material_override == null
		and (parts(collage.get_child(2))[0].get_active_material(0) as StandardMaterial3D).resource_name == "scan_paper")
	measured["study"] = {"bodies": c[0], "triangles": c[1], "plates": c[2], "heights_m": heights}

	# Walk the sheet: a body is there for the eye and not for a body, made or found.
	b.position.z = 0.9
	await press("drop", study)
	var through := await settle(marble)
	var reads := last_line(study)
	var found_at: Vector3 = collage.get_child(2).global_position
	check("B walked 0.9 m towards us stands over the found body, %.2f m from its middle; M: the marble falls through it to the ground and lies under it: '%s'" % [Vector2(b.position.x - found_at.x, b.position.z - found_at.z).length(), reads],
		absf(through.y - 0.1) < 0.02 and reads == "marble at 0.10 m" and Vector2(through.x - found_at.x, through.z - found_at.z).length() < 0.3)
	b.position.x = -1.8
	await press("drop", study)
	var through_ours := await settle(marble)
	check("it falls through the solid by hand as well: '%s'. For the marble neither body is there" % last_line(study),
		absf(through_ours.y - 0.1) < 0.02 and Vector2(through_ours.x + 1.8, through_ours.z - 0.9).length() < 0.3)
	collage.get_child(0).create_trimesh_collision()
	parts(collage.get_child(2))[0].create_trimesh_collision()
	await physics_frame
	marble.drop(collage.get_child(0).global_position + Vector3(0, 1.2, 0))
	var on_ours := await settle(marble)
	marble.drop(collage.get_child(2).global_position + Vector3(0, 1.7, 0))
	var on_found := await settle(marble)
	check("with a body from create_trimesh_collision() the marble rests on top of the solid by hand, at %.2f m; dropped over the middle of the found body it does not stay: it rolls off, and after ten seconds it is at %.2f m, %.2f m from the body" % [
		on_ours.y, on_found.y, Vector2(on_found.x - found_at.x, on_found.z - found_at.z).length()],
		absf(on_ours.y - 1.08) < 0.02 and Vector2(on_ours.x + 1.8, on_ours.z - 0.9).length() < 0.05 and on_found.y < 0.5 and Vector2(on_found.x - found_at.x, on_found.z - found_at.z).length() > 0.5)
	measured["marble"] = {"through_the_found_body_m": snappedf(through.y, 0.001), "through_the_solid_by_hand_m": snappedf(through_ours.y, 0.001), "on_the_solid_by_hand_with_a_body_m": snappedf(on_ours.y, 0.001), "over_the_found_body_with_a_body_m": snappedf(on_found.y, 0.001)}
	await close(study)

	# The axis: the words decide who stands, in which order; a word nobody answers to leaves no body and no plate.
	study = await open({"made": "found, by hand"})
	var swapped := counted(study)
	await close(study)
	study = await open({"made": "by hand, sculpted, found"})
	var sculpted := counted(study)
	await close(study)
	check("the axis is a text: \"found, by hand\" stands %s under %s; with \"sculpted\" as the second of three words, nobody was made that way and the loop goes on: %d bodies, plates %s" % [swapped[1], swapped[2], sculpted[0], sculpted[2]],
		swapped[1] == [FOUND_TRIANGLES, 20] and swapped[2] == ["found", "by hand"] and sculpted[0] == 2 and sculpted[2] == ["by hand", "found"])

	# The planted fault and the process strip, step by step, as sheet.gd photographs it.
	var strip := []
	study = await open(null)
	collage = study.get_node("Collage")
	var solid: MeshInstance3D = SolidScript.new()
	solid.set("cut", 0.0)
	collage.add_child(solid)
	solid.quaternion = Quaternion(Vector3.UP, Vector3.ONE.normalized())
	study.get_node("Sheet").hang(solid, "by hand")
	solid.global_position.y -= box_of(solid).position.y
	strip.append(counted(study))
	var pulled := box_of(solid)
	var on_axis := 0
	for v: Vector3 in corners_of(solid.mesh):
		var at := solid.global_transform * v - solid.global_position
		if Vector2(at.x, at.z).length() < 0.001:
			on_axis += 1
	await close(study)
	check("strip 1, the cube pulled along its diagonal: 1 body, 8 corners, 12 triangles with area, in a box %s m, none of its corners over its middle: it leans" % round3(pulled.size),
		alike(strip[0], [1, [12], ["by hand"], 8, 0.765, 0.765, 0.0, strip[0][7]]) and near(round3(pulled.size), Vector3(0.765, 0.765, 0.765)) and on_axis == 0)
	study = await open(null)
	collage = study.get_node("Collage")
	solid = SolidScript.new()
	solid.set("cut", 0.0)
	collage.add_child(solid)
	study.get_node("Sheet").hang(solid, "by hand")
	strip.append(counted(study))
	on_axis = 0
	for v: Vector3 in corners_of(solid.mesh):
		if Vector2(v.x, v.z).length() < 0.001:
			on_axis += 1
	await close(study)
	check("strip 2, stood on its diagonal: the same 8 corners and 12 triangles, now %.3f m high, the two ends of the diagonal over each other" % strip[1][4],
		alike(strip[1], [1, [12], ["by hand"], 8, 1.325, 1.325, 0.0, 0.0]) and on_axis == 2)
	study = await open({"made": "by hand"})
	strip.append(counted(study))
	await close(study)
	check("strip 3, two corners cut: 12 corners, 20 triangles with area, %.3f m high: the solid" % strip[2][4], alike(strip[2], [1, [20], ["by hand"], 12, 0.989, 0.989, 0.0, 0.0]))
	study = await open({"made": "by hand, drafted"})
	strip.append(counted(study))
	await close(study)
	check("strip 4, a drafted answer: 2 bodies, 20 and 20 triangles, the second %.3f m high on its own plate" % strip[3][5], alike(strip[3], [2, [20, 20], ["by hand", "drafted"], 12, 0.989, 0.989, 0.0, 0.0]))
	study = await open({"made": "by hand, drafted"})
	collage = study.get_node("Collage")
	var arrived := Node3D.new()
	arrived.add_child(load("res://found.gltf").instantiate())
	collage.add_child(arrived)
	study.get_node("Sheet").hang(arrived, "found")
	strip.append(counted(study))
	var camera: Camera3D = study.get_node("Camera3D")
	var in_view := 0
	var arrived_part: MeshInstance3D = parts(arrived)[0]
	for v: Vector3 in arrived_part.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]:
		if camera.is_position_in_frustum(arrived_part.global_transform * v):
			in_view += 1
	var from_camera := (box_of(arrived).get_center() - camera.global_position).length()
	await close(study)
	check("strip 5, the planted fault: the found body as its file gives it. 3 bodies and 3 plates, %d triangles, and the body is %.2f m high, its lowest point %.2f m above the ground, its middle %.2f m from its plate; %d of its %d corners are in the camera's view" % [
		strip[4][1][2], strip[4][5], strip[4][6], strip[4][7], in_view, FOUND_CORNERS],
		alike(strip[4], [3, [20, 20, FOUND_TRIANGLES], VALUES, 12, 0.989, 99.039, 4.3, 42.951]) and in_view == 0)
	measured["planted_fault"] = {"height_m": strip[4][5], "lowest_point_m": strip[4][6], "middle_from_its_plate_m": strip[4][7], "corners_in_the_cameras_view": in_view, "middle_from_the_camera_m": snappedf(from_camera, 0.01)}
	study = await open({})
	strip.append(counted(study))
	await close(study)
	check("strip 6, its unit and its origin: the same 3 bodies and %d triangles; the found one now %.3f m high, on the ground, over its plate" % [strip[5][1][2], strip[5][5]],
		alike(strip[5], [3, [20, 20, FOUND_TRIANGLES], VALUES, 12, 0.989, 0.99, 0.0, 0.0]))
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
		check("in process.png every tile differs from the one before: %.2f, %.2f, %.2f, %.2f and %.2f%% of the tile. The fourth of these is the found body arriving: a plate, and no body" % shares,
			shares[0] > 1.0 and shares[1] > 1.0 and shares[2] > 1.0 and shares[3] > 0.05 and shares[3] < 1.0 and shares[4] > 1.0)
		measured["process_png"] = {"bytes": bytes, "tile_differs_from_the_one_before_pct": shares}
	var sheet_picture := Image.load_from_file(ProjectSettings.globalize_path("res://sheet.png"))
	var sheet_bytes := FileAccess.get_file_as_bytes("res://sheet.png").size()
	check("sheet.png is there: the three bodies in three columns and three rows (from the side, from above, faceted), %d bytes" % sheet_bytes,
		sheet_picture != null and sheet_picture.get_width() == 3 * TILE.x + 2 * GUTTER and sheet_picture.get_height() > 3 * TILE.y and sheet_bytes < 300000)

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
	print("Collage study: ", checks.size(), " checks; passed=", passed)
	quit(0 if passed else 1)

func changed_colour(p: Color, q: Color) -> bool:
	return absf(p.r - q.r) + absf(p.g - q.g) + absf(p.b - q.b) > 0.1

func differ_pct(a: Image, b: Image) -> float:
	var count := 0
	for y in a.get_height():
		for x in a.get_width():
			if changed_colour(a.get_pixel(x, y), b.get_pixel(x, y)):
				count += 1
	return snappedf(100.0 * count / float(a.get_width() * a.get_height()), 0.01)

func pct(record: Dictionary, table: String, key: String, field := "differ_pct") -> float:
	return record.get(table, {}).get(key, {}).get(field, -1.0)

func sheet_checks(record: Dictionary, strip: Array) -> void:
	var members: Dictionary = record.get("members", {})
	var by_hand: Dictionary = members.get("by hand", {})
	var drafted: Dictionary = members.get("drafted", {})
	var found: Dictionary = members.get("found", {})
	check("sheet.json: with a window the three bodies are the three of the headless run: %d, %d and %d triangles" % [by_hand.get("triangles", 0), drafted.get("triangles", 0), found.get("triangles", 0)],
		int(by_hand.get("triangles", 0)) == 20 and int(drafted.get("triangles", 0)) == 20 and int(found.get("triangles", 0)) == FOUND_TRIANGLES
		and int(found.get("triangles_with_area", 0)) == FOUND_TRIANGLES and int(by_hand.get("corners_listed", 0)) == 60 and int(drafted.get("corners_listed", 0)) == 36)
	var views := ["level", "above", "faceted"]
	var closest_ok := true
	var same := []
	var other := []
	for view: String in views:
		closest_ok = closest_ok and record.get("closest_pair_" + view, "") == "by hand vs drafted"
		same.append(pct(record, "pairs_" + view, "by hand vs drafted"))
		other.append(pct(record, "pairs_" + view, "by hand vs found"))
	check("sheet.json: the closest pair is by hand and drafted from all three standpoints: they differ on %.2f%%, %.2f%% and %.2f%% of the still. The two pictures are one picture" % same,
		closest_ok and same == [0.0, 0.0, 0.0])
	check("sheet.json: the found body is the odd one from all three: against the one by hand it differs on %.2f%% of the still from the side, %.2f%% from above, %.2f%% faceted" % other,
		other[0] > 1.0 and other[1] > 1.0 and other[2] > 1.0 and pct(record, "pairs_level", "drafted vs found") == other[0])
	var outline: float = pct(record, "pairs_level", "by hand vs found", "outline_pct")
	var covers: float = by_hand.get("covers_pct_level", -1.0)
	check("sheet.json: by its outline it is near: %.2f%% of the still, a band of %.2f pixels, where the body covers %.2f%%; from above, where its hole shows, %.2f%%. By its triangles it is %d times the other two" % [
		outline, pct(record, "pairs_level", "by hand vs found", "outline_px"), covers, pct(record, "pairs_above", "by hand vs found", "outline_pct"), roundi(FOUND_TRIANGLES / 20.0)],
		outline > 0.2 and outline < covers / 10.0 and pct(record, "pairs_above", "by hand vs found", "outline_pct") > outline and covers > 15.0)
	var own: Dictionary = record.get("found_in_its_own_material_vs_by_hand", {})
	check("sheet.json: in the material its file brought, the found body differs from the one by hand on %.2f%% of the still: every pixel of the body. In the sheet's paint, %.2f%%" % [own.get("differ_pct", -1.0), other[0]],
		own.get("differ_pct", 0.0) > 5.0 * other[0] and found.get("painted_by_the_sheet", true) == false and by_hand.get("painted_by_the_sheet", false) == true)
	var nobody := int(record.get("primitives_drawn_with_nobody", -1))
	var drawn: Dictionary = found.get("primitives_drawn_from", {})
	check("sheet.json: the renderer drew %d primitives with nobody on the sheet, %d with the solid by hand, %d with the drafted one and %d with the found body, from 2 m; with the found body from 2, 4, 8 and 16 m: %s" % [
		nobody, by_hand.get("primitives_drawn", -1), drafted.get("primitives_drawn", -1), found.get("primitives_drawn", -1), drawn],
		nobody >= 0 and int(by_hand.get("primitives_drawn", -1)) - nobody == 20 and int(drafted.get("primitives_drawn", -1)) - nobody == 20
		and int(found.get("primitives_drawn", -1)) - nobody == FOUND_TRIANGLES and drawn.size() == 4)
	var asked: Dictionary = record.get("cut_0.9_asked_of_both", {})
	check("sheet.json: a cut of 0.9 asked of both made bodies: by hand says %.2f, drafted says %.2f, and the two differ on %.2f%% of the still" % [
		asked.get("by hand", {}).get("cut_field_says", -1.0), asked.get("drafted", {}).get("cut_field_says", -1.0), asked.get("differ", {}).get("differ_pct", -1.0)],
		is_equal_approx(asked.get("by hand", {}).get("cut_field_says", -1.0), 0.5) and is_equal_approx(asked.get("drafted", {}).get("cut_field_says", -1.0), 0.9)
		and asked.get("differ", {}).get("differ_pct", 0.0) > 5.0)
	var steps: Array = record.get("strip", [])
	var counts_ok := steps.size() == 6
	if counts_ok:
		for i in 6:
			var got := [int(steps[i]["bodies"]), steps[i]["triangles"].map(func(v): return int(v)), steps[i]["plates"], int(steps[i]["first_corners"]), steps[i]["first_height_m"],
				steps[i]["last_height_m"], steps[i]["last_lowest_point_m"], steps[i]["last_middle_from_its_plate_m"]]
			counts_ok = counts_ok and alike(got, strip[i])
	check("sheet.json: with a window the strip's six steps counted what they count headless", counts_ok)
	check("sheet.json: the found body arriving changed the picture on %.2f%% of the tile, a plate and no body; the step that changed it most was '%s'" % [steps[4]["differs_from_step_before_pct"] if counts_ok else -1.0, record.get("strip_step_that_changed_most", "")],
		counts_ok and steps[4]["differs_from_step_before_pct"] < 1.0 and steps[4]["differs_from_step_before_pct"] > 0.05 and steps[5]["differs_from_step_before_pct"] > 1.0
		and steps[1]["differs_from_step_before_pct"] > 1.0 and steps[2]["differs_from_step_before_pct"] > 1.0)
