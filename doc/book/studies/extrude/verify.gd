extends "res://supplied/verify_tools.gd"
## Headless checks of the Extrude kit. From this folder:
##   godot --headless --path . --xr-mode off --script res://verify.gd
## Writes verification.json beside this file; the exit code is the number of
## checks that failed. No import step is needed: nothing here has a class_name.
## Headless draws no frames, so what the eye gets is measured by sheet.gd.
## It takes about a minute, because the walker walks in real time; add
## --fixed-fps 60 and it takes a few seconds.

const Look := preload("res://supplied/look.gd")
const CheckGuest := preload("res://supplied/check_guest.gd")
const Grammar := preload("res://borrowed/grammar_extrude.gd")
const KEYS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_forward": [KEY_W, KEY_UP], "move_backward": [KEY_S, KEY_DOWN],
	"pause": [KEY_SPACE], "drop": [KEY_M], "look": [KEY_V], "jump": [KEY_J], "switch_camera": [KEY_C],
}
const SUPPLIED := ["base.tscn", "base_look.gd", "check_guest.gd", "look.gd", "marble.gd", "marble.tscn", "mover.gd", "segment.gd", "sheet_tools.gd",
	"sweep_sheet.gd", "sweep_sheet.tscn", "trace_strip.gd", "verify_tools.gd", "walker.gd", "walker.tscn"]
## The legs of the walk the kit ships: which actions are held, for how many steps of the physics.
const LEGS := [
	[["move_right"], 54], [["move_right", "move_backward"], 30], [["move_backward"], 36],
	[["move_left", "move_backward"], 18], [["move_left"], 60], [["move_left", "move_forward"], 24], [["move_forward"], 42],
]
const HEIGHT := 0.8

var maker: Node3D      # extrude.gd, not in the scene: for its walk and its function
var planted := 0       # the errors this file causes on purpose

func run() -> void:
	project()
	maker = load("res://extrude.gd").new()
	the_walk()
	the_solid()
	the_taper()
	smooth_by_default()
	the_borrowed_extrude()
	await the_scene()
	await the_marble()
	await the_walker()
	await the_other_way_round()
	a_step_past_the_end()
	await the_spire_in_the_scene()
	await the_recorder()
	await the_guest()
	await the_room_task()
	check(errors.size() == planted and warnings.is_empty(), "from the first check to the last Godot logged no warning and no error but the one this file plants: %s %s" % [errors, warnings])
	maker.free()

# ---------------------------------------------------------------- helpers

func text_of(path: String) -> String:
	return FileAccess.get_file_as_string(path)

func vertices_of(mesh: ArrayMesh) -> PackedVector3Array:
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]

func normals_of(mesh: ArrayMesh) -> PackedVector3Array:
	return mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL]

func flat(v: Vector3) -> Vector2:
	return Vector2(v.x, v.z)

## The normal of a triangle as Godot's renderer reads its winding: the side
## from which its corners run clockwise is the front.
func front_of(a: Vector3, b: Vector3, c: Vector3) -> Vector3:
	return (c - a).cross(b - a).normalized()

## The area a list of corners on the floor encloses: positive when they run
## clockwise seen from above.
func area_of(points: Array) -> float:
	var twice := 0.0
	for i in range(points.size()):
		twice += points[i - 1].x * points[i].z - points[i].x * points[i - 1].z
	return twice / 2.0

## How many triangles carry a normal that is not their own front (to 0.01),
## leaving out triangles with no area.
func not_flat(mesh: ArrayMesh) -> int:
	var v := vertices_of(mesh)
	var n := normals_of(mesh)
	var wrong := 0
	for i in range(0, v.size(), 3):
		if (v[i + 2] - v[i]).cross(v[i + 1] - v[i]).length() < 0.000001:
			continue
		var front := front_of(v[i], v[i + 1], v[i + 2])
		for k in 3:
			if (n[i + k] - front).length() > 0.01:
				wrong += 1
				break
	return wrong

## The volume the triangles enclose, in cubic metres: positive when every
## triangle shows its front to the outside.
func volume_of(mesh: ArrayMesh) -> float:
	var v := vertices_of(mesh)
	var six := 0.0
	for i in range(0, v.size(), 3):
		six += v[i].dot(v[i + 2].cross(v[i + 1]))
	return six / 6.0

## Edges that are not shared by exactly two triangles running opposite ways:
## none means the surface is closed and wound one way throughout.
func open_edges(mesh: ArrayMesh) -> int:
	var v := vertices_of(mesh)
	var seen := {}
	for i in range(0, v.size(), 3):
		if (v[i + 2] - v[i]).cross(v[i + 1] - v[i]).length() < 0.000001:
			continue
		for k in 3:
			var a := "%.4f,%.4f,%.4f" % [v[i + k].x, v[i + k].y, v[i + k].z]
			var b := "%.4f,%.4f,%.4f" % [v[i + (k + 1) % 3].x, v[i + (k + 1) % 3].y, v[i + (k + 1) % 3].z]
			seen[a + ">" + b] = seen.get(a + ">" + b, 0) + 1
	var open := 0
	for edge: String in seen:
		var ends := edge.split(">")
		if seen[edge] != 1 or seen.get(ends[1] + ">" + ends[0], 0) != 1:
			open += 1
	return open

func places(mesh: ArrayMesh) -> int:
	var seen := {}
	for v in vertices_of(mesh):
		seen["%.4f,%.4f,%.4f" % [v.x, v.y, v.z]] = true
	return seen.size()

func scene_with(settings: Dictionary, path := "res://extrude.tscn") -> Node3D:
	var scene: Node3D = load(path).instantiate()
	for key: String in settings:
		scene.set(key, settings[key])
		if scene.get(key) != settings[key]:
			check(false, "the scene took %s = %s (it holds %s)" % [key, settings[key], scene.get(key)])
	root.add_child(scene)
	await frames(3)
	return scene

func close(node: Node) -> void:
	node.free()
	await frames(2)

# ---------------------------------------------------------------- the project

func project() -> void:
	check(ProjectSettings.get_setting("application/config/name") == "Extrude" and ProjectSettings.get_setting("application/run/main_scene") == "res://extrude.tscn"
		and ProjectSettings.get_setting("rendering/renderer/rendering_method") == "gl_compatibility",
		"the project is named Extrude, its main scene is extrude.tscn, its renderer Compatibility")
	var keys_ok := true
	for action: String in KEYS:
		var got := []
		if InputMap.has_action(action):
			for event: InputEvent in InputMap.action_get_events(action):
				got.append((event as InputEventKey).physical_keycode)
		keys_ok = keys_ok and got == KEYS[action]
	check(keys_ok, "the Input Map has the base's nine actions on their keys")
	var found := []
	var named_there := []
	for file in DirAccess.get_files_at("res://supplied"):
		if file.ends_with(".uid"):     # the editor writes one beside every script it has seen
			continue
		found.append(file)
		if file.ends_with(".gd") and RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of("res://supplied/" + file)) != null:
			named_there.append(file)
	check(found == SUPPLIED and named_there.is_empty(), "supplied/ holds the kit base's 15 files and none declares a class_name: %s" % [found])
	check(ProjectSettings.get_global_class_list().is_empty(), "the project lists no named class: nothing needs an import")
	var spaced := []
	var named := []
	for folder: String in ["res://", "res://supplied/", "res://borrowed/", "res://guests/extrude/"]:
		for file in DirAccess.get_files_at(folder):
			if not file.ends_with(".gd"):
				continue
			if RegEx.create_from_string("(?m)^ +\\S").search(text_of(folder + file)) != null:
				spaced.append(file)
			if RegEx.create_from_string("(?m)^\\s*class_name\\s").search(text_of(folder + file)) != null:
				named.append(file)
	check(spaced.is_empty() and named.is_empty(), "every script is indented with tabs and none declares a class_name: %s %s" % [spaced, named])

# ---------------------------------------------------------------- the function

func the_walk() -> void:
	var walk: Array = maker.walk
	var on_floor := true
	var inside := true
	for corner: Vector3 in walk:
		on_floor = on_floor and corner.y == 0.0
		inside = inside and absf(corner.x) <= 0.8 and absf(corner.z) <= 0.8
	var area := area_of(walk)
	check(walk.size() == 8 and on_floor and inside and area > 0.0,
		"the shipped walk has 8 corners on the floor, inside the square of 1.6 m, clockwise seen from above: it encloses %.3f m2" % area)
	var centre: Vector3 = maker.centre_of(walk)
	check(near(centre, Vector3(0.0, 0.0, 0.07), 0.001), "centre_of(walk), the mean of its corners, is %s" % [centre.snappedf(0.001)])
	measured["walk"] = {"corners": walk.size(), "area_m2": snappedf(area, 0.001), "centre": [snappedf(centre.x, 0.001), snappedf(centre.y, 0.001), snappedf(centre.z, 0.001)]}

func the_solid() -> void:
	var walk: Array = maker.walk
	var mesh: ArrayMesh = maker.extrude(walk, HEIGHT, 1.0)
	var v := vertices_of(mesh)
	var n := normals_of(mesh)
	check(mesh is ArrayMesh and v.size() == 84, "extrude(walk, 0.8, 1.0) returns a mesh of 28 triangles, 84 vertices: 6 for each of 8 walls, 18 for each cap (it has %d)" % v.size())
	var centre: Vector3 = maker.centre_of(walk)
	var walls_out := true
	for i in range(0, 48, 3):
		var middle := (v[i] + v[i + 1] + v[i + 2]) / 3.0
		walls_out = walls_out and absf(n[i].y) < 0.001 and n[i].dot(middle - centre - Vector3.UP * middle.y) > 0.0
	check(walls_out, "every wall's normal is level and points away from the middle: the first is %s" % [n[0].snappedf(0.001)])
	var caps := true
	for i in range(48, 66):
		caps = caps and near(n[i], Vector3.UP, 0.001) and is_equal_approx(v[i].y, HEIGHT)
	for i in range(66, 84):
		caps = caps and near(n[i], Vector3.DOWN, 0.001) and v[i].y == 0.0
	check(caps, "the top is a fan at 0.8 m whose normals point straight up, the bottom the same fan on the floor with its normals straight down: %s and %s" % [n[48].snappedf(0.001), n[66].snappedf(0.001)])
	check(not_flat(mesh) == 0, "hard edges: every triangle carries its own front as the normal of all three corners (%d do not)" % not_flat(mesh))
	check(open_edges(mesh) == 0, "the solid is closed: every edge is shared by two triangles that run along it in opposite ways (%d edges are not)" % open_edges(mesh))
	var volume := volume_of(mesh)
	var area := area_of(walk)
	check(absf(volume - area * HEIGHT) < 0.0005, "its fronts face out and it holds %.4f m3: the walk's area times the height, %.4f" % [volume, area * HEIGHT])
	check(places(mesh) == 16, "its 84 vertices stand in %d places: the walk's 8 corners, twice" % places(mesh))
	var indexed := SurfaceTool.new()
	indexed.begin(Mesh.PRIMITIVE_TRIANGLES)
	indexed.set_smooth_group(-1)
	for corner in v:
		indexed.add_vertex(corner)
	indexed.generate_normals()
	var raw: PackedVector3Array = indexed.commit_to_arrays()[Mesh.ARRAY_NORMAL]
	var bottom_normals := {}       # the bottom's normals as SurfaceTool made them, bit for bit
	for i in range(66, 84):
		bottom_normals[var_to_bytes(raw[i])] = true
	indexed.index()
	var shared := vertices_of(indexed.commit()).size()
	check(shared == 59 and bottom_normals.size() == 3, "with index(), which lets triangles share a vertex that has one place and one normal, 84 become %d: 4 for each wall, 8 for the top, and 19 for the bottom, where SurfaceTool's normals differ in the sign of a zero. No wall shares a vertex with a cap or with the next wall" % shared)
	measured["prism_indexed"] = {"vertices": shared, "bottom_normals_that_differ_in_bits": bottom_normals.size()}
	var box := mesh.get_aabb()
	check(near(box.position, Vector3(-0.59, 0.0, -0.4), 0.001) and near(box.size, Vector3(1.19, 0.8, 0.93), 0.001), "it is %.2f m wide, %.2f m high and %.2f m deep, and stands on the floor" % [box.size.x, box.size.y, box.size.z])
	measured["prism"] = {"vertices": v.size(), "triangles": v.size() / 3, "places": places(mesh), "volume_m3": snappedf(volume, 0.0001), "first_wall_normal": str(n[0].snappedf(0.001)),
		"top_first_normal_as_surface_tool_made_it": str(raw[48]), "top_first_normal_read_back_from_the_mesh": str(n[48])}

func the_taper() -> void:
	var walk: Array = maker.walk
	var centre: Vector3 = maker.centre_of(walk)
	var base := area_of(walk)
	var ok := true
	var record := {}
	for taper: float in [1.0, 0.6, 0.2, 0.0]:
		var mesh: ArrayMesh = maker.extrude(walk, HEIGHT, taper)
		var v := vertices_of(mesh)
		var upper := []
		for i in 8:
			upper.append(v[i * 6 + 2])      # the third vertex of each wall is upper[i]
		var scaled := true
		for i in 8:
			scaled = scaled and near(upper[i], centre + (walk[i] - centre) * taper + Vector3.UP * HEIGHT, 0.0001)
		var top := area_of(upper)
		var volume := volume_of(mesh)
		var expected := HEIGHT / 3.0 * (base + top + sqrt(base * top))
		ok = ok and scaled and absf(top - base * taper * taper) < 0.0005 and absf(volume - expected) < 0.0005 and not_flat(mesh) == 0 and open_edges(mesh) == 0
		record["%.1f" % taper] = {"top_area_m2": snappedf(top, 0.0001), "volume_m3": snappedf(volume, 0.0001)}
	check(ok, "taper scales the upper outline toward centre_of(walk): at 1.0, 0.6, 0.2 and 0.0 the top has %s m2 and the solid holds %s m3; each is closed, flat-shaded and wound outward" % [
		[record["1.0"]["top_area_m2"], record["0.6"]["top_area_m2"], record["0.2"]["top_area_m2"], record["0.0"]["top_area_m2"]],
		[record["1.0"]["volume_m3"], record["0.6"]["volume_m3"], record["0.2"]["volume_m3"], record["0.0"]["volume_m3"]]])
	var pyramid: ArrayMesh = maker.extrude(walk, HEIGHT, 0.0)
	var with_area := 0
	var pv := vertices_of(pyramid)
	for i in range(0, pv.size(), 3):
		if (pv[i + 2] - pv[i]).cross(pv[i + 1] - pv[i]).length() > 0.000001:
			with_area += 1
	check(places(pyramid) == 9 and with_area == 14 and absf(record["0.0"]["volume_m3"] * 3.0 - record["1.0"]["volume_m3"]) < 0.001,
		"at taper 0 the 8 upper corners are one point: 9 places, and 14 of the 28 triangles have an area; the pyramid holds a third of the prism")
	measured["taper"] = record
	measured["pyramid"] = {"places": places(pyramid), "triangles_with_area": with_area}

## The planted bug, as Godot does it: the same triangles without
## set_smooth_group(-1) come back with normals averaged over every corner
## that shares a place.
func smooth_by_default() -> void:
	var walk: Array = maker.walk
	var before := errors.size() + warnings.size()
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for corner in vertices_of(maker.extrude(walk, HEIGHT, 1.0)):
		surface.add_vertex(corner)
	surface.generate_normals()
	var smooth := surface.commit()
	var n := normals_of(smooth)
	check(n[48].y < 0.95 and not_flat(smooth) == 28 and errors.size() + warnings.size() == before,
		"left at SurfaceTool's default smooth group, generate_normals() averages the normals of corners in one place: the top's first normal is %s, none of the 28 triangles keeps its own front, and Godot logs nothing" % [n[48].snappedf(0.001)])
	measured["smooth_by_default"] = {"top_first_normal_as_printed": str(n[48]), "top_first_normal": str(n[48].snappedf(0.001)), "first_wall_normal": str(n[0].snappedf(0.001)), "triangles_not_flat": not_flat(smooth)}

# ---------------------------------------------------------------- the borrowed part

func the_borrowed_extrude() -> void:
	var walk: Array = maker.walk
	var prism: ArrayMesh = maker.extrude(walk, HEIGHT, 1.0)
	var data := Grammar.read(prism)
	var chosen := Grammar.facing_up(data["vertices"], data["faces"])
	var at_top := true
	for index: int in chosen:
		for corner: int in data["faces"][index]:
			at_top = at_top and is_equal_approx(data["vertices"][corner].y, HEIGHT)
	check(data["vertices"].size() == 16 and data["faces"].size() == 28 and chosen.size() == 6 and at_top,
		"grammar_extrude: read() welds the prism into 16 corners and 28 triangles, and \"facing up\" is the 6 triangles of the top cap, not the bottom")
	var spire: ArrayMesh = Grammar.extrude_up(prism, 0.5, 0.3)
	var v := vertices_of(spire)
	var tops := 0
	for i in range(0, v.size(), 3):
		if is_equal_approx(v[i].y, 1.3) and is_equal_approx(v[i + 1].y, 1.3) and is_equal_approx(v[i + 2].y, 1.3):
			tops += 1
	check(v.size() == 192 and tops == 6 and is_equal_approx(spire.get_aabb().size.y, 1.3),
		"extrude_up(prism, 0.5, 0.3) returns 64 triangles, 1.30 m high, with %d tops at 1.30 m: one spire for each triangle of the cap's fan, not one for the cap" % tops)
	# each top is its cap triangle scaled to 0.3 about that triangle's own middle
	var own_middle := true
	var pv := vertices_of(prism)
	for i in range(48, 66, 3):
		var middle := (pv[i] + pv[i + 1] + pv[i + 2]) / 3.0
		for corner: Vector3 in [pv[i], pv[i + 1], pv[i + 2]]:
			var target := middle + (corner - middle) * 0.3 + Vector3.UP * 0.5
			var found := false
			for candidate in v:
				found = found or near(candidate, target, 0.0001)
			own_middle = own_middle and found
	check(own_middle and not_flat(spire) == 0 and open_edges(spire) == 0 and volume_of(spire) > volume_of(prism),
		"each top is its triangle scaled to 0.3 about its own middle and lifted 0.5 m; the result is closed, flat-shaded, wound outward, and holds %.4f m3" % volume_of(spire))
	var record := {}
	for taper: float in [1.0, 0.6, 0.2, 0.0]:
		var solid: ArrayMesh = maker.extrude(walk, HEIGHT, taper)
		var read := Grammar.read(solid)
		var up_faces := Grammar.facing_up(read["vertices"], read["faces"])
		var up := up_faces.size()
		var of_the_cap := 0
		var too_small := 0
		var too_thin := 0
		for index: int in up_faces:
			var face: PackedInt32Array = read["faces"][index]
			var a: Vector3 = read["vertices"][face[0]]
			var b: Vector3 = read["vertices"][face[1]]
			var c: Vector3 = read["vertices"][face[2]]
			if is_equal_approx(a.y, HEIGHT) and is_equal_approx(b.y, HEIGHT) and is_equal_approx(c.y, HEIGHT):
				of_the_cap += 1
			var edges := [(b - a).length(), (c - b).length(), (a - c).length()]
			if (b - a).cross(c - a).length() * 0.5 < Grammar.MIN_AREA:
				too_small += 1
			elif edges.min() / edges.max() < Grammar.MIN_ASPECT:
				too_thin += 1
		var after := vertices_of(Grammar.extrude_up(solid, 0.5, 0.3)).size() / 3
		record["%.1f" % taper] = {"triangles_read": read["faces"].size(), "facing_up": up, "of_them_in_the_cap": of_the_cap, "left_under_0.01_m2": too_small, "left_as_too_thin": too_thin,
			"pushed_out": (after - read["faces"].size()) / 6, "triangles_after": after}
	# The numbers the project's own MeshData.from_array_mesh() and ExtrudeFaceOp gave
	# for these four solids, turned over, in a scratch project on 1 October 2026.
	var real := {"1.0": [28, 6, 64], "0.6": [28, 6, 64], "0.2": [28, 16, 82], "0.0": [14, 7, 56]}
	var same := true
	for key: String in real:
		same = same and [record[key]["triangles_read"], record[key]["facing_up"], record[key]["triangles_after"]] == real[key]
	check(same, "at taper 1.0, 0.6, 0.2 and 0.0 it reads, chooses and returns as many triangles as the project's own code did: %s" % [record])
	measured["borrowed_extrude"] = record
	measured["spire"] = {"vertices": v.size(), "triangles": v.size() / 3, "tops": tops, "volume_m3": snappedf(volume_of(spire), 0.0001)}

# ---------------------------------------------------------------- the scene

func the_scene() -> void:
	var before := errors.size() + warnings.size()
	var lines := printed.size()
	var scene := await scene_with({})
	await frames(180)
	check(errors.size() + warnings.size() == before, "extrude.tscn ran 180 frames with no error and no warning: %s" % [errors.slice(before)])
	check(printed.slice(lines).has("8 corners walked, 84 vertices in the mesh, 0.80 m high"), "it prints: 8 corners walked, 84 vertices in the mesh, 0.80 m high")
	var solid: MeshInstance3D = scene.get_node("Solid")
	check(solid.mesh != null and vertices_of(solid.mesh) == vertices_of(maker.extrude(maker.walk, HEIGHT, 1.0)) and solid.material_override is StandardMaterial3D
		and solid.material_override.albedo_color.is_equal_approx(Look.BODY), "Solid holds the mesh extrude() returns, painted BODY")
	var segments := []
	for child in scene.get_children():
		if child is MeshInstance3D and child.mesh is CylinderMesh:
			segments.append(child)
	var on_edges := segments.size() == 8
	if on_edges:
		for i in 8:
			var a: Vector3 = maker.walk[i - 1]
			var b: Vector3 = maker.walk[i]
			on_edges = on_edges and near(segments[i].position, (a + b) / 2.0) and is_equal_approx((segments[i].mesh as CylinderMesh).height, (b - a).length())
	check(on_edges, "8 segments lie on the walk's 8 edges; the first joins the last corner to the first, so the outline is closed")
	var shape: Shape3D = scene.get_node("Solid/Body/Shape").shape
	check(shape is ConcavePolygonShape3D and (shape as ConcavePolygonShape3D).get_faces().size() == 84 and not (shape as ConcavePolygonShape3D).backface_collision,
		"Solid/Body/Shape holds a collider made from the mesh: a ConcavePolygonShape3D of 28 triangles")
	await close(scene)
	scene = await scene_with({"height": 0.3, "taper": 0.6})
	var low: ArrayMesh = scene.get_node("Solid").mesh
	check(is_equal_approx(low.get_aabb().size.y, 0.3) and vertices_of(low) == vertices_of(maker.extrude(maker.walk, 0.3, 0.6)), "height and taper are exported and used: set to 0.3 and 0.6 the solid is 0.30 m high with the smaller top")
	await close(scene)

func the_marble() -> void:
	var record := {}
	var centre: Vector3 = maker.centre_of(maker.walk)
	for taper: float in [1.0, 0.6, 0.2, 0.0]:
		var scene := await scene_with({"taper": taper})
		var marble: RigidBody3D = scene.get_node("Marble")
		await press("drop")
		var rest := await settle(marble)
		await frames(2)
		var away := flat(rest - centre).length()
		record["%.1f" % taper] = {"rests_at_m": snappedf(rest.y, 0.001), "from_the_middle_m": snappedf(away, 0.001)}
		if taper == 1.0:
			check(absf(rest.y - 0.9) < 0.01 and away < 0.01 and scene.get_node("Readout").text.ends_with("marble at 0.90 m"),
				"taper 1.0: M drops the marble over the middle of the walk and it rests on the cap, at %.3f m; the readout says marble at 0.90 m" % rest.y)
		elif taper == 0.0:
			check(absf(rest.y - 0.9) < 0.01 and away < 0.01, "taper 0.0: dropped exactly over the point it stays on the point, at %.3f m" % rest.y)
			marble.drop(centre + Vector3(0.01, HEIGHT + 1.0, 0.0))
			await physics_frames(240)
			var aside: Vector3 = marble.global_position
			check(aside.y < 0.5, "dropped 1 cm to the side it rolls off the pyramid: four seconds later it is at %.2f m, %.2f m from the middle" % [aside.y, flat(aside - centre).length()])
			record["0.0, 1 cm aside"] = {"after_4_s_at_m": snappedf(aside.y, 0.01), "from_the_middle_m": snappedf(flat(aside - centre).length(), 0.01)}
		else:
			check(absf(rest.y - 0.9) < 0.01, "taper %.1f: it rests on the cap, at %.3f m, %.2f m from where it landed" % [taper, rest.y, away])
		await close(scene)
	# Without the collider the marble meets nothing.
	var bare := await scene_with({})
	bare.get_node("Solid/Body/Shape").shape = null
	await press("drop")
	var through := await settle(bare.get_node("Marble"))
	check(absf(through.y - 0.1) < 0.01, "with the collider's shape taken away the marble falls through the mesh to the floor: %.3f m" % through.y)
	record["no collider"] = {"rests_at_m": snappedf(through.y, 0.001)}
	await close(bare)
	measured["marble"] = record

func the_walker() -> void:
	var record := {}
	for trial: Array in [[0.8, 1.0], [0.3, 1.0], [0.3, 0.0]]:
		var scene := await scene_with({"height": trial[0], "taper": trial[1]})
		var walker: CharacterBody3D = scene.get_node("Walker")
		await physics_frames(20)
		var how := await walk(walker, [Vector3(-2.6, 0.0, 0.07), Vector3(0.0, 0.0, 0.07)])
		var at: Vector3 = walker.global_position
		record["height %.1f, taper %.1f" % trial] = {"walk_ended": how, "x": snappedf(at.x, 0.01), "feet_at_m": snappedf(at.y, 0.01)}
		if trial[0] == 0.8:
			check(how == "blocked" and absf(at.y) < 0.01 and absf(at.x + 0.9) < 0.05, "the walker sent at the solid of 0.8 m is stopped by its wall: \"%s\" at x %.2f, 0.3 m from the face, its feet on the floor" % [how, at.x])
		elif trial[1] == 1.0:
			check(how == "arrived" and absf(at.y - 0.3) < 0.01, "at 0.3 m it steps up and stands on top of the walk: \"%s\", its feet at %.2f m" % [how, at.y])
		else:
			check(how == "arrived" and at.y > 0.25, "a pyramid of 0.3 m it walks up, to the point: \"%s\", its feet at %.2f m" % [how, at.y])
		await close(scene)
	measured["walker"] = record

## The lesson's Try: the same corners in the other order. Nothing is logged.
func the_other_way_round() -> void:
	var before := errors.size() + warnings.size()
	var scene: Node3D = load("res://extrude.tscn").instantiate()
	scene.walk.reverse()
	root.add_child(scene)
	await frames(3)
	var mesh: ArrayMesh = scene.get_node("Solid").mesh
	var n := normals_of(mesh)
	await press("drop")
	var rest := await settle(scene.get_node("Marble"))
	await frames(2)
	check(volume_of(mesh) < 0.0 and near(n[48], Vector3.DOWN, 0.001) and absf(rest.y - 0.1) < 0.01 and scene.get_node("Readout").text.ends_with("marble at 0.10 m") and errors.size() + warnings.size() == before,
		"the walk in the other order: every front faces in (the top's normal is %s), the marble falls through the top to the floor inside, %.3f m, and Godot logs nothing" % [n[48].snappedf(0.001), rest.y])
	var walker: CharacterBody3D = scene.get_node("Walker")
	var how := await walk(walker, [Vector3(-2.6, 0.0, 0.07), Vector3(0.0, 0.0, 0.07)])
	check(how == "blocked" and absf(walker.global_position.x + 0.9) < 0.05, "the walker is stopped by the inside-out wall all the same: \"%s\" at x %.2f" % [how, walker.global_position.x])
	measured["the_other_way_round"] = {"top_normal": str(n[48].snappedf(0.001)), "volume_m3": snappedf(volume_of(mesh), 0.0001), "marble_rests_at_m": snappedf(rest.y, 0.001), "walker": how}
	await close(scene)

## The lesson's Try: walk[i + 1] in the loop over every corner. This one is loud.
func a_step_past_the_end() -> void:
	var walk_line := ""
	for line in text_of("res://extrude.gd").split("
"):
		if line.begins_with("var walk"):
			walk_line = line
	var trial := GDScript.new()
	trial.source_code = "extends RefCounted
" + walk_line + "
func edges() -> int:
	var count := 0
	for i in range(walk.size()):
		if walk[i] != walk[i + 1]:
			count += 1
	return count
"
	trial.reload()
	var before := errors.size()
	var counter: RefCounted = trial.new()
	counter.edges()
	var said := errors.slice(before)
	planted += said.size()
	check(said.size() == 1 and said[0].contains("Out of bounds get index '8' (on base: 'Array[Vector3]')"), "walk[i + 1] at the last corner stops the function with: %s" % [said])
	measured["a_step_past_the_end"] = said

func the_spire_in_the_scene() -> void:
	var lines := printed.size()
	var scene := await scene_with({"spire": true})
	var mesh: ArrayMesh = scene.get_node("Solid").mesh
	var shape: ConcavePolygonShape3D = scene.get_node("Solid/Body/Shape").shape
	check(printed.slice(lines).has("8 corners walked, 192 vertices in the mesh, 1.30 m high") and shape.get_faces().size() == 192 and vertices_of(mesh).size() == 192,
		"with spire ticked the solid is handed on: 8 corners walked, 192 vertices in the mesh, 1.30 m high; the collider is made from the new mesh")
	await press("drop")
	var rest := await settle(scene.get_node("Marble"))
	check(rest.y > 0.05, "the marble dropped on the spires comes to rest at %.2f m, %.2f m from the middle" % [rest.y, flat(rest - maker.centre_of(maker.walk)).length()])
	measured["spire"]["marble_rests_at_m"] = snappedf(rest.y, 0.01)
	await close(scene)

# ---------------------------------------------------------------- the recorder

func legs(order: Array) -> void:
	for leg: Array in order:
		for action: String in leg[0]:
			Input.action_press(action)
		await physics_frames(leg[1])
		for action: String in leg[0]:
			Input.action_release(action)
		await frames(3)

func the_recorder() -> void:
	var scene: Node3D = load("res://borrowed/walk.tscn").instantiate()
	root.add_child(scene)
	await frames(5)
	var lines := printed.size()
	await legs(LEGS)
	await press("pause")
	await frames(2)
	var outline: Array = scene.outline
	var close_to: bool = outline.size() == maker.walk.size()
	if close_to:
		for i in outline.size():
			close_to = close_to and (outline[i] - maker.walk[i]).length() < 0.05
	var line: String = printed[-1] if printed.size() > lines else ""
	check(close_to and line.begins_with("var walk: Array[Vector3] = [Vector3(") and line.ends_with(")]") and line.count("Vector3(") == 8,
		"walk.tscn: the seven legs of our walk, held as actions, then Space: it prints one line of code with 8 corners, each within 5 cm of the walk the kit ships")
	check(not scene.open and scene.area_of(outline) > 0.0 and scene.get_node("Readout").text.begins_with("closed: 8 corners"), "the walk is closed, clockwise, and the readout says so: %.2f m2" % scene.area_of(outline))
	measured["recorder"] = {"line": line}
	# Space again, and a loop walked the other way round.
	scene.get_node("Hand").position = Vector3(-0.4, 0.05, -0.4)
	await frames(2)
	await press("pause")
	var back := [[["move_backward"], 42], [["move_right", "move_backward"], 24], [["move_right"], 48], [["move_right", "move_forward"], 18], [["move_forward"], 36], [["move_left", "move_forward"], 12]]
	await legs(back)
	var kept: Array = scene.kept.duplicate()
	await press("pause")
	await frames(2)
	check(area_of(kept) < 0.0 and scene.area_of(scene.outline) > 0.0 and scene.outline.size() >= 6,
		"walked the other way round the kept corners run counter-clockwise (%.2f m2) and the printed walk is clockwise all the same (%.2f m2)" % [area_of(kept), scene.area_of(scene.outline)])
	var turned: ArrayMesh = maker.extrude(scene.outline, HEIGHT, 1.0)
	check(open_edges(turned) == 0 and volume_of(turned) > 0.0, "and extrude() of it is a closed solid with its fronts outward")
	# A straight run walked in two goes, and the edge of the square.
	scene.get_node("Hand").position = Vector3(-0.4, 0.05, -0.4)
	await frames(2)
	await press("pause")
	await legs([[["move_right"], 20], [["move_right"], 20], [["move_backward"], 30], [["move_left"], 240]])
	var hand: Vector3 = scene.get_node("Hand").position
	await press("pause")
	await frames(2)
	check(is_equal_approx(hand.x, -0.75) and scene.outline.size() == 4, "a straight run walked in two goes is one edge, and the Hand stops at the edge of the square, 0.75 m from the middle: %d corners" % scene.outline.size())
	await close(scene)

# ---------------------------------------------------------------- the guest

func the_guest() -> void:
	var needs := CheckGuest.outside("res://guests/extrude/")
	check(needs.is_empty(), "the guest names nothing outside its folder: %s" % [needs])
	check(CheckGuest.class_names("res://guests/extrude/").is_empty(), "the guest declares no class_name")
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var guest: Node3D = load("res://guests/extrude/extrude.tscn").instantiate()
	base.add_child(guest)
	await frames(3)
	var solid: MeshInstance3D = guest.get_node("Solid")
	var box := solid.mesh.get_aabb()
	check(guest is Node3D and is_zero_approx(box.position.y) and box.position.x >= -0.8 and box.end.x <= 0.8 and box.position.z >= -0.8 and box.end.z <= 0.8,
		"the guest's first node is a Node3D; its solid stands on the ground at its origin and fits the place: %.2f m wide, %.2f m deep, %.2f m high" % [box.size.x, box.size.z, box.size.y])
	check(vertices_of(solid.mesh) == vertices_of(maker.extrude(guest.walk, guest.height, guest.taper)) and normals_of(solid.mesh) == normals_of(maker.extrude(guest.walk, guest.height, guest.taper))
		and solid.material_override.albedo_color.is_equal_approx(Look.BODY),
		"the guest's own copy of extrude() gives the mesh the kit's extrude() gives for its walk, height %.2f and taper %.2f; it is painted BODY" % [guest.height, guest.taper])
	var plate: Label3D = guest.get_node("Plate")
	check(plate.text == "height 0.80 m\ntaper 0.80" and plate.modulate == Look.INK and plate.outline_modulate == Look.SHADE and absf(plate.position.z) <= 0.8,
		"its height and taper are written on it, in INK with a SHADE edge: %s" % plate.text.replace("\n", ", "))
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(2.0, 0.1, 1.0)
	base.add_child(marble)
	marble.drop(guest.centre_of(guest.walk) + Vector3.UP * 1.8)
	var rest := await settle(marble)
	check(absf(rest.y - 0.9) < 0.01, "a marble dropped over the guest rests on top of it, at %.3f m: it has a collider" % rest.y)
	measured["guest"] = {"wide_m": snappedf(box.size.x, 0.01), "deep_m": snappedf(box.size.z, 0.01), "high_m": snappedf(box.size.y, 0.01), "marble_rests_at_m": snappedf(rest.y, 0.001)}
	await close(base)

## "In your room", as far as the kit can do it alone: the guest with another
## walk, height and taper, and a rider on its lid. The lesson's rider is the
## room's example guest, a box of 0.5 m; a box of that size stands in for it here.
func the_room_task() -> void:
	var base: Node3D = load("res://supplied/base.tscn").instantiate()
	root.add_child(base)
	var guest: Node3D = load("res://guests/extrude/extrude.tscn").instantiate()
	var own: Array = [Vector3(0.52, 0, -0.38), Vector3(0.64, 0, -0.26), Vector3(0.64, 0, 0.22), Vector3(0.47, 0, 0.39), Vector3(-0.17, 0, 0.39), Vector3(-0.4, 0, 0.16), Vector3(-0.4, 0, -0.4)]
	guest.walk.assign(own)
	guest.height = 1.0
	guest.taper = 0.7
	base.add_child(guest)
	await frames(3)
	var rider := StaticBody3D.new()
	var collider := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.5, 0.5, 0.5)
	collider.shape = box
	collider.position.y = 0.25
	rider.add_child(collider)
	rider.position = guest.centre_of(guest.walk) + Vector3.UP * guest.height
	guest.add_child(rider)
	var marble: RigidBody3D = load("res://supplied/marble.tscn").instantiate()
	marble.position = Vector3(2.0, 0.1, 1.0)
	base.add_child(marble)
	await frames(2)
	marble.drop(rider.global_position + Vector3.UP * 2.0)
	var rest := await settle(marble)
	var solid: MeshInstance3D = guest.get_node("Solid")
	check(guest.walk.size() == 7 and is_equal_approx(solid.mesh.get_aabb().size.y, 1.0) and guest.get_node("Plate").text == "height 1.00 m
taper 0.70"
		and is_equal_approx(rider.global_position.y, 1.0) and absf(rest.y - 1.6) < 0.01 and open_edges(solid.mesh) == 0 and volume_of(solid.mesh) > 0.0,
		"the guest with a walk of 7 corners, height 1.0 and taper 0.7: a closed plinth 1.00 m high whose plate says so; a rider put at centre_of(walk) + UP * height stands with its feet at %.2f m, and a marble dropped over a rider of 0.5 m rests at %.3f m" % [rider.global_position.y, rest.y])
	measured["room_task"] = {"rider_feet_at_m": snappedf(rider.global_position.y, 0.01), "marble_on_a_rider_of_half_a_metre_m": snappedf(rest.y, 0.001)}
	# Not made by this run: what the room itself did, in a scratch copy of my-room.
	measured["in_a_scratch_copy_of_my_room_on_2026-10-01"] = {
		"guest_trial": {"place": 2, "walk_ended": "blocked", "metres_from_the_middle_of_the_place": 0.8, "feet_at_m": 0.0, "checks": "8 of 8"},
		"with_the_lessons_three_rider_lines": {"rider": "res://guests/example/example.tscn", "rider_feet_at_m": 1.0, "marble_on_the_rider_m": 1.598, "walker": "blocked, 0.67 m from the middle of the place"},
	}
	await close(base)
