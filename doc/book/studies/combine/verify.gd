extends "res://supplied/verify_tools.gd"
## Headless checks of the Combine kit: the borrowed parts, what a CSG combiner
## does in Godot 4.6 (and what it does in silence), the carved body baked and
## not baked under a walker and a marble, the four orders of the argument, the
## kept mesh and the guest. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so what the eye gets is measured by sheet.gd.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Member := preload("res://borrowed/member.gd")
const Tunnel := preload("res://borrowed/tunnel.gd")
const Scan := preload("res://borrowed/scan.gd")
const Combine := preload("res://combine.gd")

const UNION := CSGShape3D.OPERATION_UNION
const MINUS := CSGShape3D.OPERATION_SUBTRACTION
const INTERSECT := CSGShape3D.OPERATION_INTERSECTION
const FIRST_LINE := "((A union B) minus C) intersect S"

## A fresh base with nothing in it but what a check adds.
func world() -> Node3D:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	await frames(2)
	return base

func close(node: Node) -> void:
	node.free()
	await frames(1)

## The learner's script on a node of its own, in `base`, built and (if asked) baked.
func carved(base: Node3D, order := 0, baked := true, b_x := 0.2) -> Node3D:
	var node := Node3D.new()
	node.set_script(Combine)
	node.order = order
	node.baked = baked
	node.b_x = b_x
	base.add_child(node)
	await frames(3)
	return node

func walker_in(base: Node3D, at: Vector3) -> CharacterBody3D:
	var walker: CharacterBody3D = load("res://supplied/walker.tscn").instantiate()
	walker.position = at      # before add_child: a body is in the room from the step it is added
	base.add_child(walker)
	await physics_frames(20)
	return walker

## Where a marble dropped at `at` comes to rest.
func marble_at(base: Node3D, at: Vector3) -> Vector3:
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(3.5, 0.1, 2.0)
	base.add_child(marble)
	await frames(2)
	marble.drop(at)
	var lies := await settle(marble)
	marble.free()
	return lies

## One operand, as the learner's operand() and put() make it.
func operand(mesh: Mesh, verb: int, color: Color, at := Vector3.ZERO) -> CSGMesh3D:
	var shape := CSGMesh3D.new()
	shape.mesh = mesh
	shape.material = Look.paint(color)
	shape.operation = verb
	shape.position = at
	return shape

## A combiner in the room with these operands, in this order, worked out.
func combined(operands: Array) -> CSGCombiner3D:
	var carver := CSGCombiner3D.new()
	root.add_child(carver)
	for shape: CSGShape3D in operands:
		carver.add_child(shape)
	await frames(2)
	return carver

## The lesson's four operands, placed as combine.gd places them, with no verb yet.
func operands(closed := true) -> Dictionary:
	var a := operand(Member.make(16), UNION, Look.BODY, Vector3(-0.22, 1.2, 0.0))
	a.scale = Vector3(0.96, 4.2, 1.5)
	var b := operand(Member.make(4), UNION, Look.SECOND, Vector3(0.2, 1.2, 0.0))
	b.scale = Vector3(1.633, 4.2, 1.633)
	b.rotation.y = PI / 4.0
	var c := operand(Tunnel.make(24), MINUS, Look.THIRD, Vector3(0.0, 0.3, 0.0))
	var s := operand(Scan.make(closed), INTERSECT, Look.BONE)
	return {"a": a, "b": b, "c": c, "s": s}

func triangles(mesh: Mesh) -> int:
	if mesh == null:
		return 0
	@warning_ignore("integer_division")
	return mesh.get_faces().size() / 3

## The volume a closed mesh encloses, in cubic metres: the sum of the little
## pyramids from the origin to each triangle. Godot winds a triangle clockwise
## seen from outside, so the sum comes out negative and is turned round.
func volume(mesh: Mesh) -> float:
	if mesh == null:
		return 0.0
	var corners := mesh.get_faces()
	var sum := 0.0
	for i in range(0, corners.size(), 3):
		sum += corners[i].dot(corners[i + 1].cross(corners[i + 2])) / 6.0
	return -sum

## How many edges of a mesh belong to one triangle only. A closed skin has none.
func open_edges(mesh: Mesh) -> int:
	var corners := mesh.get_faces()
	var uses := {}
	for i in range(0, corners.size(), 3):
		if (corners[i + 1] - corners[i]).cross(corners[i + 2] - corners[i]).length() < 1e-9:
			continue          # a triangle with no area: two of its corners are one
		for k in 3:
			var from := corners[i + k].snappedf(0.00001)
			var to := corners[i + (k + 1) % 3].snappedf(0.00001)
			var edge := [from, to] if from < to else [to, from]
			uses[edge] = uses.get(edge, 0) + 1
	var open := 0
	for edge: Array in uses:
		if uses[edge] == 1:
			open += 1
	return open

## The corners of a mesh as a sorted list of places, each once, to a tenth of a millimetre.
func corner_set(mesh: Mesh) -> Array:
	var seen := {}
	for corner in mesh.get_faces():
		seen[corner.snappedf(0.0001)] = true
	var places := seen.keys()
	places.sort()
	return places

## The triangles of a mesh as a sorted list, each a sorted list of its three corners to a
## tenth of a millimetre: two meshes with the same list are the same triangles in any order.
func triangle_set(mesh: Mesh) -> Array:
	var corners := mesh.get_faces()
	var all := []
	for i in range(0, corners.size(), 3):
		var three := [corners[i].snappedf(0.0001), corners[i + 1].snappedf(0.0001), corners[i + 2].snappedf(0.0001)]
		three.sort()
		all.append(three)
	all.sort()
	return all

## How many triangles each surface of a mesh has, in the order of the surfaces.
func by_surface(mesh: Mesh) -> Array:
	var counts := []
	for surface in mesh.get_surface_count():
		@warning_ignore("integer_division")
		counts.append(mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size() / 3)
	return counts

## How many triangles of a mesh are smaller than one square centimetre, and the smallest, in cm2.
func slivers(mesh: Mesh) -> Array:
	var corners := mesh.get_faces()
	var small := 0
	var least := INF
	for i in range(0, corners.size(), 3):
		var area := (corners[i + 1] - corners[i]).cross(corners[i + 2] - corners[i]).length() / 2.0
		least = minf(least, area)
		if area < 0.0001:
			small += 1
	return [small, snappedf(least * 10000.0, 0.001)]

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func run() -> void:
	project()
	borrowed()
	await combiner()
	await silent_faults()
	await scene()
	await not_baked()
	await baked_body()
	await prototype_collider()
	await orders()
	await kept()
	await own_body()
	await guest()
	check(errors.is_empty(), "from the first check to the last Godot logged no error: %s" % [errors])

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Combine" and ProjectSettings.get_setting("application/run/main_scene") == "res://combine.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Combine, its main scene is combine.tscn, its renderer Compatibility")
	var supplied := []
	for file in DirAccess.get_files_at("res://supplied"):
		if not file.ends_with(".uid"):    # the editor writes one beside every script it has seen
			supplied.append(file)
	check(supplied == ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd", "sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"], "supplied/ holds the base's 15 files: %s" % [supplied])
	var named := []
	var spaced := []
	for folder: String in ["res://", "res://supplied/", "res://borrowed/", "res://guests/combine/"]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
	check(named.is_empty() and ProjectSettings.get_global_class_list().is_empty(), "no script of the kit declares a class_name, and the project lists no named class: nothing needs an import: %s" % [named])
	check(spaced.is_empty(), "every script is indented with tabs: %s" % [spaced])

func borrowed() -> void:
	var round := Member.make(16)
	var block := Member.make(4)
	check(round.radial_segments == 16 and round.rings == 8 and triangles(round) == 288 and block.radial_segments == 4 and block.rings == 2 and triangles(block) == 24,
		"member.gd (Families): make(16) is a SphereMesh of 16 segments and 8 rings listing %d triangles, make(4) one of 4 and 2 listing %d" % [triangles(round), triangles(block)])
	check(Member.make(2).radial_segments == 4 and Member.make(640).radial_segments == 64, "make() keeps the segments between 4 and 64, as the class Globe did")
	check(Tunnel.value(Vector3(0.0, 1.0, 0.0)) < 0.0 and Tunnel.value(Vector3(0.0, -0.01, 0.0)) > 0.0 and Tunnel.value(Vector3(0.41, 1.0, 0.0)) > 0.0
		and Tunnel.value(Vector3(0.0, 2.11, 0.0)) > 0.0 and Tunnel.value(Vector3(0.0, 1.0, 1.21)) > 0.0 and Tunnel.value(Vector3(0.39, 1.0, 1.19)) < 0.0,
		"tunnel.gd (Implicit bodies): value(p) is below 0 in the middle of the tunnel and above 0 under its floor, beyond its wall, over its top and past its end")
	var tube := Tunnel.make(24)
	var tube_box := tube.get_aabb()
	var tube_corners := tube.get_faces()
	var wall := 0             # triangles of the tunnel that are not in one of its two ends
	for i in range(0, tube_corners.size(), 3):
		if not (is_equal_approx(absf(tube_corners[i].z), 1.2) and is_equal_approx(tube_corners[i + 1].z, tube_corners[i].z) and is_equal_approx(tube_corners[i + 2].z, tube_corners[i].z)):
			wall += 1
	check(triangles(tube) == 96 and wall == 48 and open_edges(tube) == 0 and volume(tube) > 0.0, "make(24) asks along 24 spokes and returns a closed skin: %d triangles, %d of them its wall, %d open edges, %.3f m3 inside" % [triangles(tube), wall, open_edges(tube), volume(tube)])
	check(absf(tube_box.size.x - 0.8) < 0.001 and absf(tube_box.size.y - 2.1) < 0.001 and absf(tube_box.size.z - 2.4) < 0.001 and absf(tube_box.position.y) < 0.001,
		"the tunnel is %.2f m wide, %.2f m high and %.2f m long, and its floor is level at height %.3f" % [tube_box.size.x, tube_box.size.y, tube_box.size.z, tube_box.position.y])
	var shell := Scan.make(false)
	var whole := Scan.make(true)
	check(triangles(shell) == 340 and open_edges(shell) == 20, "scan.gd (Collage): make(false) is a shell: %d triangles and %d edges that belong to one triangle only, the rim of the foot" % [triangles(shell), open_edges(shell)])
	check(triangles(whole) == 360 and open_edges(whole) == 0 and volume(whole) > 0.0, "make(true) adds the foot: %d triangles, %d open edges, %.3f m3 inside" % [triangles(whole), open_edges(whole), volume(whole)])
	var scan_box := whole.get_aabb()
	check(scan_box.size.x <= 1.6 and scan_box.size.z <= 1.6 and absf(scan_box.size.y - 2.85) < 0.001 and absf(scan_box.position.y) < 0.001 and absf(scan_box.get_center().x) < 0.05 and absf(scan_box.get_center().z) < 0.05,
		"the scan stands on the ground at its origin, %.2f m high, %.2f m wide and %.2f m deep: inside a guest's 1.6 m" % [scan_box.size.y, scan_box.size.x, scan_box.size.z])
	measured["operands"] = {"A_member_16_triangles": triangles(round), "B_member_4_triangles": triangles(block), "C_tunnel_triangles": triangles(tube), "S_scan_triangles": triangles(whole),
		"S_shell_triangles": triangles(shell), "C_tunnel_wall_triangles": wall,
		"triangles_listed_after_each_operand": [triangles(round), triangles(round) + triangles(block), triangles(round) + triangles(block) + triangles(tube), triangles(round) + triangles(block) + triangles(tube) + triangles(whole)], "S_shell_open_edges": open_edges(shell), "C_tunnel_volume_m3": snappedf(volume(tube), 0.001), "S_scan_volume_m3": snappedf(volume(whole), 0.001)}

## What a combiner does with the lesson's operands, one verb after another.
func combiner() -> void:
	var parts := operands()
	var carver := CSGCombiner3D.new()
	root.add_child(carver)
	carver.add_child(parts["a"])
	var at_once := carver.bake_static_mesh()
	check(at_once == null, "asked in the frame its operand was added, bake_static_mesh() returns null: the combiner has not worked its result out yet")
	await frames(1)
	var chain := [triangles(carver.bake_static_mesh())]
	var small := [slivers(carver.bake_static_mesh())]
	check(chain[0] == 256, "one frame later it returns a mesh. A alone: 288 triangles listed, %d in the result (the 32 with no area at the poles are gone)" % chain[0])
	for key: String in ["b", "c", "s"]:
		carver.add_child(parts[key])
		await frames(2)
		chain.append(triangles(carver.bake_static_mesh()))
		small.append(slivers(carver.bake_static_mesh()))
	check(chain == [256, 296, 392, 574], "A, then union B, then minus C, then intersect S: the result has %s triangles" % [chain])
	var result := carver.bake_static_mesh()
	var by_colour := {}
	for surface in result.get_surface_count():
		var paint: StandardMaterial3D = result.surface_get_material(surface)
		@warning_ignore("integer_division")
		by_colour[paint.albedo_color.to_html(false)] = result.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX].size() / 3
	check(by_colour.size() == 4 and by_colour.get(Look.BODY.to_html(false)) == 172 and by_colour.get(Look.SECOND.to_html(false)) == 101 and by_colour.get(Look.THIRD.to_html(false)) == 81 and by_colour.get(Look.BONE.to_html(false)) == 220,
		"every face of the result wears the paint of the operand it came from: BODY, SECOND, THIRD and BONE on %s triangles" % [by_colour.values()])
	var shape := carver.bake_collision_shape()
	@warning_ignore("integer_division")
	var faces := shape.get_faces().size() / 3
	check(shape is ConcavePolygonShape3D and faces == chain[3], "bake_collision_shape() returns a ConcavePolygonShape3D of the same %d triangles" % faces)
	check(open_edges(result) == 0 and volume(result) > 0.0, "the result is a closed skin: %d open edges, %.3f m3 inside" % [open_edges(result), volume(result)])
	check(small[0][0] == 0 and small[3][0] > small[1][0], "the seams leave small triangles: under 1 cm2 there are %d, %d, %d and %d after the four verbs; the smallest of the result is %.3f cm2" % [small[0][0], small[1][0], small[2][0], small[3][0], small[3][1]])
	measured["chain"] = {"triangles_listed": 768, "triangles_after_A": chain[0], "after_union_B": chain[1], "after_minus_C": chain[2], "after_intersect_S": chain[3],
		"triangles_under_1_cm2": [small[0][0], small[1][0], small[2][0], small[3][0]], "smallest_triangle_cm2": small[3][1], "result_triangles_by_operand": by_colour,
		"result_volume_m3": snappedf(volume(result), 0.001), "collider_triangles": faces}
	carver.free()
	# Union can change places; subtraction cannot: the hall's bench, A - B and B - A.
	var volumes := []
	for pair: Array in [["a", "b", UNION], ["b", "a", UNION], ["a", "b", MINUS], ["b", "a", MINUS]]:
		parts = operands()
		parts["c"].free()
		parts["s"].free()
		parts[pair[0]].operation = UNION
		parts[pair[1]].operation = pair[2]
		var two := await combined([parts[pair[0]], parts[pair[1]]])
		volumes.append(volume(two.bake_static_mesh()))
		two.free()
	check(absf(volumes[0] - volumes[1]) < 0.0001 and absf(volumes[2] - volumes[3]) > 0.1, "A union B and B union A enclose the same %.3f m3; A minus B encloses %.3f m3 and B minus A %.3f m3" % [volumes[0], volumes[2], volumes[3]])
	measured["two_operands_m3"] = {"A_union_B": snappedf(volumes[0], 0.001), "B_union_A": snappedf(volumes[1], 0.001), "A_minus_B": snappedf(volumes[2], 0.001), "B_minus_A": snappedf(volumes[3], 0.001)}

## The lesson's two silences: a subtraction with nothing before it, and a shell.
func silent_faults() -> void:
	var before := errors.size() + warnings.size()
	var parts := operands()
	var first := await combined([parts["c"], parts["a"], parts["b"], parts["s"]])
	var no_tunnel := triangles(first.bake_static_mesh())
	var no_tunnel_volume := volume(first.bake_static_mesh())
	first.free()
	parts = operands()
	var without := await combined([parts["a"], parts["b"], parts["s"]])
	parts["c"].free()
	check(no_tunnel == triangles(without.bake_static_mesh()) and absf(no_tunnel_volume - volume(without.bake_static_mesh())) < 0.0001 and errors.size() + warnings.size() == before,
		"with the tunnel put first, minus has nothing to take from: the result is the body with no tunnel, %d triangles, the same as with no C at all, and Godot logged nothing" % no_tunnel)
	without.free()
	var results := {}
	for verb: int in [UNION, MINUS, INTERSECT]:
		parts = operands(false)
		parts["s"].operation = verb
		var open := await combined([parts["a"], parts["s"]])
		results[verb] = triangles(open.bake_static_mesh())
		open.free()
		parts["b"].free()
		parts["c"].free()
	check(results[INTERSECT] == 0 and errors.size() + warnings.size() == before, "A intersected with the scan as a shell, its foot open: the result has %d triangles, and Godot logged no error and no warning" % results[INTERSECT])
	check(results[UNION] == 256 and results[MINUS] == 256, "the shell united with A, or taken from A, changes nothing: %d and %d triangles, A alone. A shell has no inside, so the combiner treats it as nothing" % [results[UNION], results[MINUS]])
	parts = operands(false)
	var whole := await combined([parts["a"], parts["b"], parts["c"], parts["s"]])
	check(triangles(whole.bake_static_mesh()) == 0, "the lesson's body with Scan.make(false) for its last operand: %d triangles" % triangles(whole.bake_static_mesh()))
	whole.free()
	# The lesson's steps before the scan arrives: the same three operands in three orders.
	var steps := {}
	for line: Array in [["a", "b", "c"], ["a", "c", "b"], ["c", "a", "b"], ["a", "b"]]:
		parts = operands()
		var kids := []
		for key: String in parts:
			if not line.has(key):
				parts[key].free()
		for key: String in line:
			kids.append(parts[key])
		var three := await combined(kids)
		steps[" ".join(line)] = triangles(three.bake_static_mesh())
		three.free()
	check(steps["a b c"] == 392 and steps["c a b"] == steps["a b"] and steps["a c b"] != steps["a b c"] and errors.size() + warnings.size() == before,
		"child order is operand order: A, B, minus C gives %d triangles; A, minus C, B gives %d; minus C, A, B gives %d, which is A and B with no tunnel; and Godot logged nothing" % [steps["a b c"], steps["a c b"], steps["c a b"]])
	measured["silent"] = {"three_operands_by_child_order_triangles": steps, "triangles_listed_with_a_shell": 288 + 24 + 96 + triangles(Scan.make(false)),"tunnel_first_triangles": no_tunnel, "shell_intersect_triangles": results[INTERSECT], "shell_union_triangles": results[UNION], "shell_minus_triangles": results[MINUS]}

## The kit's own scene, as the learner runs it.
func scene() -> void:
	var before := errors.size()
	var lines := printed.size()
	var kit: Node3D = load("res://combine.tscn").instantiate()
	root.add_child(kit)
	await frames(180)
	var body: Node3D = kit.get_node("Carved")
	var walker: CharacterBody3D = kit.get_node("Walker")
	if walker.walking:
		await walker.walk_ended
		await frames(2)
	var said := printed.slice(lines)
	check(errors.size() == before, "combine.tscn ran more than 180 frames and Godot logged no error: %s" % [errors.slice(before)])
	check(said.has(FIRST_LINE + ": 768 triangles listed, 574 in the result"), "it printed the verbs and the two counts: %s" % [said])
	check(said.has("the walker arrived, its feet at 0.3 m"), "the walker walked into the tunnel on its autopilot and the scene printed: the walker arrived, its feet at 0.3 m")
	check(body.body is MeshInstance3D and triangles(body.body.mesh) == 574 and not is_instance_valid(body.carver), "Carved holds a MeshInstance3D of 574 triangles, and the combiner is gone")
	var solid: Node = body.body.get_child(0)
	check(solid is StaticBody3D and solid.get_child(0) is CollisionShape3D and solid.get_child(0).shape is ConcavePolygonShape3D, "the mesh has a StaticBody3D with a collider made from it")
	var box: AABB = body.body.mesh.get_aabb()
	check(absf(box.position.y) < 0.001 and absf(box.size.y - 2.85) < 0.001 and box.position.x >= -0.8 and box.end.x <= 0.8 and box.position.z >= -0.8 and box.end.z <= 0.8,
		"the body stands on the ground, %.2f m high, %.2f m wide and %.2f m deep: inside a guest's 1.6 m" % [box.size.y, box.size.x, box.size.z])
	measured["body"] = {"height_m": snappedf(box.size.y, 0.001), "width_m": snappedf(box.size.x, 0.001), "depth_m": snappedf(box.size.z, 0.001), "triangles_listed": body.listed, "triangles_built": body.built,
		"walker_feet_m": snappedf(walker.global_position.y, 0.001)}
	await close(kit)

## Before baking: a picture. Nothing in it for a body.
func not_baked() -> void:
	var base := await world()
	var body := await carved(base, 0, false)
	check(body.body == null and is_instance_valid(body.carver) and body.built == 574 and not body.carver.use_collision, "with `baked` false the combiner stays, 574 triangles to the eye, and no collider")
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var feet := walker.global_position.y
	check(how == "arrived" and absf(feet) < 0.01, "not baked: the walker walks in at the door and \"%s\" in the middle with its feet at %.2f m, 0.30 m under the floor of the hollow" % [how, feet])
	how = await walk(walker, [Vector3(1.5, 0.0, 0.0)])
	check(how == "arrived", "from there it walks out through the side wall: \"%s\" at x %.2f" % [how, walker.global_position.x])
	walker.stand_at(Vector3(0.0, 0.0, 0.0))
	walker.rotation.y = 0.0
	await physics_frames(10)
	await hold("move_right", 60)
	check(walker.global_position.x > 0.9, "and with move_right held for a second, as the D key gives it, it is %.2f m to the right of the middle: through the wall" % walker.global_position.x)
	walker.stand_at(Vector3(0.0, 0.3, 0.0))
	await physics_frames(60)
	var fell := walker.global_position.y
	check(absf(fell) < 0.01, "put on the floor of the hollow, at 0.30 m, it falls through it: a second later its feet are at %.2f m" % fell)
	walker.stand_at(Vector3(3.0, 0.0, 2.0))
	var lies := await marble_at(base, Vector3(0.0, 1.5, 0.2))
	check(absf(lies.y - 0.1) < 0.01, "a marble dropped in the hollow comes to rest at %.2f m: on the ground, under the floor" % lies.y)
	measured["not_baked"] = {"walker_in_the_middle_feet_m": snappedf(feet, 0.001), "put_on_the_floor_feet_m": snappedf(fell, 0.001), "marble_m": snappedf(lies.y, 0.001)}
	await close(base)

## After baking: the same picture, and a body can stand in it.
func baked_body() -> void:
	var base := await world()
	var body := await carved(base, 0, true)
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var feet := walker.global_position.y
	check(how == "arrived" and absf(feet - 0.3) < 0.01, "baked: the walker steps up at the door and \"%s\" in the hollow with its feet at %.2f m" % [how, feet])
	how = await walk(walker, [Vector3(1.5, 0.0, 0.0)])
	var right := walker.global_position.x
	check(how == "blocked" and right < 0.15, "walked at the right wall it is \"%s\", %.2f m from the middle" % [how, right])
	walker.stand_at(Vector3(0.0, 0.3, 0.0))
	await physics_frames(30)
	how = await walk(walker, [Vector3(-1.5, 0.0, 0.0)])
	var left := walker.global_position.x
	check(how == "blocked" and left > -0.15, "and at the left wall \"%s\", %.2f m from the middle" % [how, -left])
	walker.stand_at(Vector3(0.0, 0.3, 0.0))
	await physics_frames(60)
	check(absf(walker.global_position.y - 0.3) < 0.01, "put on the floor of the hollow it stays there: its feet at %.2f m a second later" % walker.global_position.y)
	walker.rotation.y = 0.0       # facing into the tunnel, as it stands after walking in
	await hold("move_right", 60)
	var by_key := walker.global_position.x
	await hold("move_left", 60)
	var by_key_left := walker.global_position.x
	walker.stand_at(Vector3(0.0, 0.3, 0.0))
	await physics_frames(10)
	await hold("move_backward", 60)      # two metres: the floor ends 2.5 m in front of the middle
	var backed := walker.global_position
	await hold("move_forward", 60)
	var again := walker.global_position
	check(by_key < 0.15 and by_key > 0.0 and by_key_left > -0.15 and by_key_left < 0.0 and backed.z > 0.9 and absf(backed.y) < 0.01 and absf(again.z) < 0.6 and absf(again.y - 0.3) < 0.01,
		"by the actions the keys give: move_right held for a second leaves it %.2f m right of the middle and move_left, after it, %.2f m left of it, at the walls; from the middle move_backward takes it out at the door and down to %.2f m; move_forward takes it in again and up to %.2f m" % [by_key, -by_key_left, backed.y, again.y])
	walker.stand_at(Vector3(0.0, 0.3, 0.0))
	await physics_frames(10)
	how = await walk(walker, [Vector3(0.0, 0.0, -2.2)])
	check(how == "arrived" and absf(walker.global_position.y) < 0.01, "it walks on through the tunnel and out at the back: \"%s\", its feet on the ground at %.2f m" % [how, walker.global_position.y])
	walker.stand_at(Vector3(2.5, 0.0, 0.0))
	await physics_frames(20)
	how = await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var outside := walker.global_position.x
	check(how == "blocked" and outside > 0.8, "walked at the body from the side it is \"%s\" by the outer wall, %.2f m from the middle" % [how, outside])
	walker.stand_at(Vector3(3.0, 0.0, 2.0))
	var lies := await marble_at(base, Vector3(0.0, 1.5, 0.2))
	check(absf(lies.y - 0.4) < 0.01, "a marble dropped in the hollow comes to rest at %.2f m: on the floor of the hollow" % lies.y)
	measured["baked"] = {"walker_in_the_hollow_feet_m": snappedf(feet, 0.001), "blocked_right_at_x_m": snappedf(right, 0.001), "blocked_left_at_x_m": snappedf(left, 0.001),
		"blocked_outside_at_x_m": snappedf(outside, 0.001), "marble_m": snappedf(lies.y, 0.001),
		"move_left_held_x_m": snappedf(by_key_left, 0.001), "move_right_held_x_m": snappedf(by_key, 0.001)}
	await close(base)

## use_collision on the combiner: a collider at once, for a prototype.
func prototype_collider() -> void:
	var base := await world()
	var body := await carved(base, 0, false)
	body.carver.use_collision = true
	await physics_frames(5)
	check(not body.carver is StaticBody3D, "with use_collision the combiner itself is the collider, and a CSGCombiner3D is not a StaticBody3D")
	var walker := await walker_in(base, Vector3(0.0, 0.3, 0.0))
	await physics_frames(40)
	var held := walker.global_position.y
	check(absf(held - 0.3) < 0.01, "use_collision: a walker put on the floor of the hollow stays there, its feet at %.2f m" % held)
	walker.stand_at(Vector3(0.0, 0.0, 2.2))
	await physics_frames(20)
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var at := walker.global_position
	check(how == "blocked" and at.y < 0.01 and at.z > 0.6, "but the supplied walker does not step in from outside: \"%s\" at the door, %.2f m in front of the middle, its feet at %.2f m. It steps only onto a StaticBody3D" % [how, at.z, at.y])
	walker.stand_at(Vector3(3.0, 0.0, 2.0))
	var lies := await marble_at(base, Vector3(0.0, 1.5, 0.2))
	check(absf(lies.y - 0.4) < 0.01, "the marble dropped in the hollow rests on its floor, at %.2f m" % lies.y)
	measured["use_collision"] = {"walker_put_in_feet_m": snappedf(held, 0.001), "walk_in": how, "stopped_at_z_m": snappedf(at.z, 0.001), "marble_m": snappedf(lies.y, 0.001)}
	await close(base)

## The argument: the same operands and verbs in four orders.
func orders() -> void:
	var rows := []
	for order in 4:
		var base := await world()
		var body := await carved(base, order, true)
		var mesh: Mesh = body.body.mesh
		var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
		var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
		var row := {"order": body.verbs(), "triangles": body.built, "volume_m3": snappedf(volume(mesh), 0.001), "open_edges": open_edges(mesh),
			"walk_to_the_middle": how, "feet_m": snappedf(walker.global_position.y, 0.01), "stopped_at_z_m": snappedf(walker.global_position.z, 0.01)}
		rows.append(row)
		print("order %d %s: %d triangles, %.3f m3, the walker %s with its feet at %.2f m" % [order, row["order"], row["triangles"], row["volume_m3"], how, row["feet_m"]])
		await close(base)
	check(rows[0]["triangles"] == 574 and rows[0]["walk_to_the_middle"] == "arrived" and absf(rows[0]["feet_m"] - 0.3) < 0.005, "(A union B) minus C: %d triangles, %.3f m3; the walker \"arrived\" in the hollow at 0.30 m" % [rows[0]["triangles"], rows[0]["volume_m3"]])
	check(rows[1]["walk_to_the_middle"] == "blocked" and absf(rows[1]["feet_m"]) < 0.005, "(A minus C) union B: %d triangles, %.3f m3; B stands in the tunnel and the walker is \"blocked\" at the door, %.2f m in front of the middle" % [rows[1]["triangles"], rows[1]["volume_m3"], rows[1]["stopped_at_z_m"]])
	check(rows[2]["walk_to_the_middle"] == "arrived" and absf(rows[2]["feet_m"] - 0.3) < 0.005, "(A intersect B) minus C: %d triangles, %.3f m3; the walker \"arrived\" on what is left of the floor, at %.2f m" % [rows[2]["triangles"], rows[2]["volume_m3"], rows[2]["feet_m"]])
	check(rows[3]["walk_to_the_middle"] == "arrived" and absf(rows[3]["feet_m"]) < 0.005, "A minus (B union C): %d triangles, %.3f m3; there is no floor in the middle and the walker \"arrived\" on the ground, at %.2f m" % [rows[3]["triangles"], rows[3]["volume_m3"], rows[3]["feet_m"]])
	var closed := true
	for row: Dictionary in rows:
		closed = closed and row["open_edges"] == 0
	check(closed, "all four results are closed skins")
	check(rows[1]["volume_m3"] > rows[0]["volume_m3"] and rows[0]["volume_m3"] > rows[3]["volume_m3"] and rows[3]["volume_m3"] > rows[2]["volume_m3"],
		"by volume: (A minus C) union B %.3f, (A union B) minus C %.3f, A minus (B union C) %.3f, (A intersect B) minus C %.3f m3" % [rows[1]["volume_m3"], rows[0]["volume_m3"], rows[3]["volume_m3"], rows[2]["volume_m3"]])
	check(rows[2]["volume_m3"] < 0.15 * rows[0]["volume_m3"], "the intersection keeps %.1f%% of the first order's volume" % (100.0 * rows[2]["volume_m3"] / rows[0]["volume_m3"]))
	measured["orders"] = rows
	var apart := {}
	var nearest := ""
	for i in 4:
		for j in range(i + 1, 4):
			var pair := "%s vs %s" % [Combine.ORDERS[i], Combine.ORDERS[j]]
			apart[pair] = snappedf(absf(rows[i]["volume_m3"] - rows[j]["volume_m3"]), 0.001)
			if nearest == "" or apart[pair] < apart[nearest]:
				nearest = pair
	measured["orders_apart_by_volume_m3"] = {"pairs": apart, "closest": nearest}
	# The outline's condition: with B clear of the tunnel the first two orders are one body.
	var clear := []
	for order in 2:
		var base := await world()
		var body := await carved(base, order, true, 0.95)
		clear.append([body.built, volume(body.body.mesh), corner_set(body.body.mesh), triangle_set(body.body.mesh), by_surface(body.body.mesh), body.body.mesh.get_faces()])
		await close(base)
	check(clear[0][0] == clear[1][0] and absf(clear[0][1] - clear[1][1]) < 0.000001 and clear[0][2] == clear[1][2] and clear[0][3] == clear[1][3],
		"with B moved to x 0.95, clear of the tunnel, the first two orders give the same body: %d and %d triangles, %.4f and %.4f m3, the same %d corners to a tenth of a millimetre and the same triangles; the surfaces come in the order of the children, %s and %s triangles" % [clear[0][0], clear[1][0], clear[0][1], clear[1][1], clear[0][2].size(), clear[0][4], clear[1][4]])
	measured["b_clear_of_the_tunnel"] = {"b_x": 0.95, "triangles": [clear[0][0], clear[1][0]], "volume_m3": [snappedf(clear[0][1], 0.0001), snappedf(clear[1][1], 0.0001)], "same_corners": clear[0][2] == clear[1][2],
		"same_triangles": clear[0][3] == clear[1][3], "triangles_by_surface": [clear[0][4], clear[1][4]], "corner_lists_equal_as_lists": clear[0][5] == clear[1][5]}

## keep(): the baked mesh as a file, with its verbs written on it.
func kept() -> void:
	var path := "user://carved_check.tres"
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
	var base := await world()
	var raw := await carved(base, 0, false)
	var lines := printed.size()
	raw.keep(path)
	check(not FileAccess.file_exists(path) and printed.slice(lines).has("nothing to keep: nothing is baked"), "keep() with nothing baked writes no file and says so")
	raw.free()
	var body := await carved(base, 0, true)
	body.keep(path)
	var back: Mesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	check(back is ArrayMesh and triangles(back) == 574 and back.get_surface_count() == 4 and back.get_meta("verbs", "") == FIRST_LINE and back.get_meta("listed", 0) == 768,
		"keep(path) writes the baked mesh as a file: read back it has %d triangles in %d surfaces, and carries the line \"%s\"" % [triangles(back), back.get_surface_count(), back.get_meta("verbs", "")])
	var text := text_of(path)
	check(not text.contains("res://") and not text.contains("CSG") and not text.contains("operation"), "the file names no operand, no verb and no other file: %d bytes of corners, triangles and four paints" % text.length())
	measured["kept"] = {"bytes": text.length(), "triangles": triangles(back), "surfaces": back.get_surface_count()}
	DirAccess.remove_absolute(path)
	await close(base)

## In your room: a body of our own, made with the knob the script has. B stands 10 cm further right.
func own_body() -> void:
	var path := "user://carved_own.tres"
	var base := await world()
	var body := await carved(base, 0, true, 0.3)
	body.keep(path)
	var back: Mesh = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var box: AABB = body.body.mesh.get_aabb()
	check(triangles(back) == body.built and body.built != 574 and how == "arrived" and absf(walker.global_position.y - 0.3) < 0.01 and box.position.x >= -0.8 and box.end.x <= 0.8,
		"with b_x at 0.3 the body is another body, %d triangles of %d listed; it is %.2f m wide, the walker \"%s\" in its hollow at %.2f m, and keep() writes it with its line" % [body.built, body.listed, box.size.x, how, walker.global_position.y])
	measured["own_body"] = {"b_x": 0.3, "triangles_listed": body.listed, "triangles": body.built, "width_m": snappedf(box.size.x, 0.001), "walker": how, "walker_feet_m": snappedf(walker.global_position.y, 0.001), "verbs": back.get_meta("verbs", "")}
	DirAccess.remove_absolute(path)
	await close(base)

## The body handed to the room.
func guest() -> void:
	var needs := CheckGuest.outside("res://guests/combine/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/combine/").is_empty(), "the guest declares no class_name")
	var files := []
	for file in DirAccess.get_files_at("res://guests/combine"):
		if not file.ends_with(".uid"):
			files.append(file)
	check(files == ["carved.tres", "carved_body.gd", "combine.tscn"], "guests/combine/ holds three files: %s" % [files])
	var before := errors.size()
	var base := await world()
	var guest: Node = load("res://guests/combine/combine.tscn").instantiate()
	base.add_child(guest)
	await frames(60)
	check(guest is Node3D and errors.size() == before, "the guest's first node is a Node3D, and it ran 60 frames with no error")
	var mesh: Mesh = load("res://guests/combine/carved.tres")
	var fresh := await carved(base, 0, true)
	fresh.position.x = 3.0
	check(triangles(mesh) == fresh.built and absf(volume(mesh) - volume(fresh.body.mesh)) < 0.0001 and mesh.get_meta("verbs", "") == fresh.verbs() and mesh.get_meta("listed", 0) == fresh.listed,
		"carved.tres is the body the kit's scene bakes now: %d triangles, %.3f m3, the same line of verbs" % [triangles(mesh), volume(mesh)])
	fresh.free()
	var box := AABB()
	var first := true
	var plate: Label3D = null
	for part: Node in guest.find_children("*", "GeometryInstance3D", true, false):
		var here: AABB = part.global_transform * part.get_aabb()
		box = here if first else box.merge(here)
		first = false
		if part is Label3D:
			plate = part
	check(absf(box.position.y) < 0.001 and box.position.x >= -0.8 and box.end.x <= 0.8 and box.position.z >= -0.8 and box.end.z <= 0.8,
		"with its plate the guest stands on the ground and is %.2f m wide and %.2f m deep: inside 1.6 m" % [box.size.x, box.size.z])
	check(plate != null and plate.text == FIRST_LINE + "\n768 triangles listed, 574 baked", "the verbs hang over the door as a text: %s" % [plate.text.replace("\n", " / ") if plate != null else "no plate"])
	var walker := await walker_in(base, Vector3(0.0, 0.0, 2.2))
	var how := await walk(walker, [Vector3(0.0, 0.0, 0.0)])
	var feet := walker.global_position.y
	check(how == "arrived" and absf(feet - 0.3) < 0.01, "the walker walks into the guest and \"%s\" in its hollow, its feet at %.2f m" % [how, feet])
	walker.stand_at(Vector3(3.0, 0.0, 2.0))
	var lies := await marble_at(base, Vector3(0.0, 1.5, 0.2))
	check(absf(lies.y - 0.4) < 0.01, "a marble dropped in the guest's hollow rests at %.2f m" % lies.y)
	measured["guest"] = {"width_m": snappedf(box.size.x, 0.001), "depth_m": snappedf(box.size.z, 0.001), "height_m": snappedf(box.size.y, 0.001), "plate_width_m": snappedf(plate.get_aabb().size.x, 0.001) if plate != null else 0.0,
		"walker": how, "walker_feet_m": snappedf(feet, 0.001), "marble_m": snappedf(lies.y, 0.001)}
	# A record, not a measurement of this script: the room's own trial of this guest,
	# run in a scratch copy of my-room on 1 October 2026 (the README has its lines).
	measured["room_trial_record"] = {"measured_by": "my-room/guest_trial.gd in a scratch copy of the room, not by verify.gd", "checks": 8, "failed": 0, "place": 2,
		"walk_ended": "arrived", "metres_from_the_middle_of_the_place": 0.08, "feet_at_m": 0.3}
	await close(base)
