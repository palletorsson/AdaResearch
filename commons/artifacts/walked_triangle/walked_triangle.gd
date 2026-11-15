extends Node3D
## THE WALKED TRIANGLE (floor NonEuclidean_Spaces; the pass, 2026-11-15)
##
## The hall asks what counts as straight. Its bench keeps three coordinate pairs and reads them twice: on a plane
## the pairs place points and the angles add to 180 degrees; on a sphere the same pairs name directions from the
## centre, the sides follow great circles, and the total rises. "Neither operation bends the museum around you."
## This one does: a PLAYGROUND form of the same record, and the body is its third corner.
##
## A dome stands on the floor: the cap of a sphere six metres in radius, 6.4 m across and 0.9 m high at its middle,
## shallow enough to walk. Two cones stand on it; they are corners A and B. Step onto the dome and you are corner C.
## The three sides are drawn on the surface as the straightest paths that stay on it; the board gives the three
## angles and their sum, which is more than 180 and grows as the triangle does. A plank runs through the dome from
## cone to cone: the shorter way between them, which has left the space the triangle lives in.
##
## North of the dome lies the same record read as a PLANE: a mat with the same three pairs as points, straight tape
## between them, and its own sum - 180, wherever you stand on the dome. What travels between the two is the record
## of three pairs. The distances and the angles do not.
##
## The model is the tutorial's own (doc/book/studies/noneuclid-lineage/surface_triangle.gd): its corner(), edge()
## and measure(), one instance read as sphere and one as plane, sharing the pairs. The body's place on the dome is
## turned into a pair by the chart the model itself uses (a pair p names the direction (p.x, 1, p.y)).
##
## `reading` is the axis: both = the dome and the mat; sphere = the dome alone; plane = the mat alone, with a ball
## carried over the mat by a body walking the floor beside it (the bench's PLANE).
##
## The dome is a mesh of its own with a collider cut from the same triangles - there is no prefab of a walkable
## cap; the cones, the plank and the balls are the tower's prefabs through prefab_city.gd.
const City := preload("res://algorithms/graphtheory/prefab_city.gd")
const Triangle := preload("res://doc/book/studies/noneuclid-lineage/surface_triangle.gd")
const R := 6.0
const CAP := 0.5585                     # the cap's half-angle, radians (32 degrees): the slope at the rim
const A := Vector2(-0.3, -0.2)
const B := Vector2(0.3, -0.2)
const REST := Vector2(0.0, 0.34)
const MAT_AT := Vector3(0, 0, -5.4)
const MAT_SCALE := 2.4
const SPHERE_INK := Color("d8432e")
const PLANE_INK := Color("3f6fd0")

@export_enum("both", "sphere", "plane") var reading := "both"

var _city = City.new()
var _curved = Triangle.new()
var _flat = Triangle.new()
var _centre := Vector3.ZERO
var _rim := 0.0
var _dome: Node3D
var _mat: Node3D
var _segments: Array[MeshInstance3D] = []
var _corner_tags: Array[Label3D] = []
var _flat_strips: Array[MeshInstance3D] = []
var _flat_balls: Array[Node3D] = []
var _flat_tag: Label3D
var _board: Label3D
var _body: CharacterBody3D
var _on_dome := false
var _pair := REST
var _drawn := Vector2(99, 99)
var _most := 180.0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_reading"): _take({"reading": get_meta("config_reading")})
	var began := Time.get_ticks_msec()
	_centre = Vector3(0, -R * cos(CAP), 0)
	_rim = R * sin(CAP)
	_curved.spherical = true
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_apply()
	_set_pair(REST)


func _take(config_data: Dictionary) -> void:
	if config_data.has("reading") and str(config_data["reading"]) in ["both", "sphere", "plane"]: reading = str(config_data["reading"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := reading
	_take(config_data)
	if is_inside_tree() and _board != null and reading != before:
		_apply()
		_drawn = Vector2(99, 99)
		_set_pair(_pair)


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _exit_tree() -> void:
	for node in [_dome, _mat]:
		if is_instance_valid(node) and node.get_parent() == null: node.free()


func _apply() -> void:
	_in_tree(_dome, reading != "plane")
	_in_tree(_mat, reading != "sphere")


## ---- the record: the tutorial's own model, read twice ----

## A place on the dome (local x, z) as the pair the model's chart gives it.
func pair_at(x: float, z: float) -> Vector2:
	var up: float = sqrt(maxf(0.01, R * R - x * x - z * z))
	return Vector2(x / up, z / up)


## A pair as a point on the dome's surface, local.
func on_dome(p: Vector2) -> Vector3:
	return _centre + (_curved.corner(p) as Vector3) * R


func _set_pair(p: Vector2) -> void:
	_pair = p
	if p.distance_to(_drawn) < 0.004: return
	_drawn = p
	var pairs: Array[Vector2] = [A, B, p]
	_curved.points = pairs
	_flat.points = pairs.duplicate()
	var sphere: Dictionary = _curved.measure()
	var plane: Dictionary = _flat.measure()
	if reading != "plane":
		for i in 3:
			var samples: Array = _curved.edge(i, 16)
			for k in 16:
				var from: Vector3 = _centre + (samples[k] as Vector3) * (R + 0.025)
				var to: Vector3 = _centre + (samples[k + 1] as Vector3) * (R + 0.025)
				var piece := _segments[i * 16 + k]
				piece.position = (from + to) * 0.5
				piece.basis = Basis(Quaternion(Vector3.UP, (to - from).normalized())).scaled(Vector3(1, from.distance_to(to), 1))
			_corner_tags[i].position = on_dome(pairs[i]) + Vector3(0, 0.95 if i < 2 else 2.05, 0)
			_corner_tags[i].text = ("%s  %.0f°" % [["A", "B", "C"][i], float(sphere["angles"][i])]) if bool(sphere.get("valid", false)) else ["A", "B", "C"][i]
	if reading != "sphere":
		for i in 3:
			var from: Vector2 = pairs[i] * MAT_SCALE
			var to: Vector2 = pairs[(i + 1) % 3] * MAT_SCALE
			var strip := _flat_strips[i]
			strip.position = Vector3((from.x + to.x) * 0.5, 0.012, (from.y + to.y) * 0.5)
			strip.scale = Vector3(1, 1, maxf(0.02, from.distance_to(to)))
			strip.rotation.y = atan2(to.x - from.x, to.y - from.y)
			_flat_balls[i].position = Vector3(from.x, 0, from.y)
		_flat_tag.text = "the same three pairs, read as a plane:  %.0f°" % float(plane.get("sum", 0.0)) if bool(plane.get("valid", false)) else "three in a row: no triangle, no reading"
	if bool(sphere.get("valid", false)): _most = maxf(_most, float(sphere["sum"]))
	_tell(sphere, plane)


func _physics_process(_delta: float) -> void:
	var here := _body != null and is_instance_valid(_body)
	if not here:
		if _on_dome:
			_on_dome = false
			_set_pair(REST)
		return
	var p := to_local(_body.global_position)
	if reading == "plane":
		# beside the mat: the body's place on the floor south of it carries the third point
		var near: bool = absf(p.x) < 2.6 and p.z > MAT_AT.z + 1.9 and p.z < MAT_AT.z + 5.0
		_on_dome = near
		if near: _set_pair(Vector2(p.x / MAT_SCALE, (p.z - MAT_AT.z - 3.4) / MAT_SCALE))
		return
	var on: bool = Vector2(p.x, p.z).length() < _rim - 0.15 and p.y > -0.2
	if on:
		_on_dome = true
		_set_pair(pair_at(p.x, p.z))
	elif _on_dome:
		_on_dome = false
		_set_pair(REST)


func _tell(sphere: Dictionary, plane: Dictionary) -> void:
	if _board == null: return
	var lines := PackedStringArray(["THE WALKED TRIANGLE"])
	lines.append("What counts as straight? On this dome a side is the straightest path that stays on the surface. The two cones are corners A and B. Step onto the dome: you are corner C.")
	if reading == "plane":
		lines.append("Here the three pairs are read as a plane. Walk beside the mat: the pink ball is carried with you, and the sum stays %.0f°." % float(plane.get("sum", 180.0)))
	elif bool(sphere.get("valid", false)):
		var angles: Array = sphere["angles"]
		lines.append("%s  A %.0f°  +  B %.0f°  +  C %.0f°  =  %.1f°.  That is %.1f° more than a plane allows, and it grows as the triangle does: walk away from the cones." % [
			"You are C." if _on_dome else "At rest:", float(angles[0]), float(angles[1]), float(angles[2]), float(sphere["sum"]), float(sphere["sum"]) - 180.0])
	else:
		lines.append("You stand in line with A and B: three in a row is no triangle, and the reading is withheld.")
	if reading == "both":
		lines.append("North of the dome the same three pairs are read as a plane: %s. The record of three pairs travels between the two. The angles do not." % ("%.0f°" % float(plane["sum"]) if bool(plane.get("valid", false)) else "no triangle"))
	if reading != "plane":
		lines.append("The plank through the dome is the shorter way from A to B. It has left the space this triangle lives in.")
	_board.text = "\n".join(lines)


## ---- building, once ----

func _tube(parent: Node3D, colour: Color, radius: float) -> MeshInstance3D:
	var piece := MeshInstance3D.new()
	var rod := CylinderMesh.new()
	rod.top_radius = radius
	rod.bottom_radius = radius
	rod.height = 1.0
	rod.radial_segments = 6
	rod.rings = 1
	piece.mesh = rod
	piece.material_override = _city.flat(colour, 0.5)
	piece.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(piece)
	return piece


func _build_once() -> void:
	# the dome: a cap of the sphere, walkable
	_dome = Node3D.new()
	_dome.name = "Dome"
	add_child(_dome)
	var tool := SurfaceTool.new()
	tool.begin(Mesh.PRIMITIVE_TRIANGLES)
	var rings := 14
	var around := 48
	for i in rings:
		for j in around:
			var quad := []
			for corner in [[i, j], [i + 1, j], [i + 1, j + 1], [i, j + 1]]:
				var theta: float = CAP * float(corner[0]) / float(rings)
				var phi: float = TAU * float(corner[1]) / float(around)
				quad.append(Vector3(sin(theta) * cos(phi), cos(theta), sin(theta) * sin(phi)))
			for index in [0, 2, 1, 0, 3, 2]:
				var unit: Vector3 = quad[index]
				tool.set_normal(unit)
				tool.add_vertex(_centre + unit * R)
	var cap: ArrayMesh = tool.commit()
	var skin := MeshInstance3D.new()
	skin.mesh = cap
	var paint: StandardMaterial3D = _city.flat(Color("e7e1d3"), 0.9)
	paint.cull_mode = BaseMaterial3D.CULL_DISABLED
	skin.material_override = paint
	_dome.add_child(skin)
	var solid := StaticBody3D.new()
	var shape := CollisionShape3D.new()
	var surface: ConcavePolygonShape3D = cap.create_trimesh_shape()
	surface.backface_collision = true          # a body meets the cap from above whichever way its triangles wind
	shape.shape = surface
	solid.add_child(shape)
	_dome.add_child(solid)
	var edge := MeshInstance3D.new()
	var ring := TorusMesh.new()
	ring.inner_radius = _rim - 0.05
	ring.outer_radius = _rim + 0.03
	edge.mesh = ring
	edge.scale = Vector3(1, 0.05, 1)
	edge.material_override = _city.flat(Color("3a3d45"), 0.6)
	edge.position = Vector3(0, 0.008, 0)
	_dome.add_child(edge)
	for i in 48: _segments.append(_tube(_dome, SPHERE_INK, 0.022))
	for i in 3:
		var tag: Label3D = _city.sign_post(_dome, Vector3.ZERO)
		tag.pixel_size = 0.004
		tag.modulate = Color(1.0, 0.86, 0.82)
		_corner_tags.append(tag)
	for pair in [A, B]:
		var foot := on_dome(pair)
		_city.part(_dome, "traffic_pyramid_5", foot - Vector3(0, 0.03, 0), 0, Vector3(0.4, 0.62, 0.4), false)
	# the chord: a plank through the dome from A to B, its ends showing
	var from := on_dome(A) + Vector3(0, 0.12, 0)
	var to := on_dome(B) + Vector3(0, 0.12, 0)
	var chord: Node3D = _city.part(_dome, "timber_plank_4m", (from + to) * 0.5 - Vector3(0, 0.1, 0), 0, Vector3(from.distance_to(to) + 0.5, 0.06, 0.2), false)
	chord.name = "Chord"
	# the same record read as a plane, north of the dome
	_mat = Node3D.new()
	_mat.name = "Plane"
	_mat.position = MAT_AT
	add_child(_mat)
	_city.sheet(_mat, Vector3(0, 0.004, 0), Vector2(3.4, 3.0), Color("23262e"))
	for i in 3:
		var strip := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.07, 0.008, 1.0)
		strip.mesh = box
		strip.material_override = _city.flat(PLANE_INK, 0.6)
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		_mat.add_child(strip)
		_flat_strips.append(strip)
		var holder := Node3D.new()
		_mat.add_child(holder)
		var ball: Node3D = _city.part(holder, "trace_point_ball", Vector3.ZERO, 0, Vector3(0.24, 0.24, 0.24), false)
		if i == 2:
			var pink: StandardMaterial3D = _city.flat(Color("ff5fa8"), 0.4)
			for mesh in ball.find_children("*", "MeshInstance3D", true, false): (mesh as MeshInstance3D).material_override = pink
		_flat_balls.append(holder)
	_flat_tag = _city.floor_words(_mat, Vector3(0, 0.014, 1.75), "", 32, PLANE_INK.lightened(0.45))
	# the body, and the board east of the dome turned to the arrival
	var ground := Node3D.new()
	ground.name = "Ground"
	add_child(ground)
	var sensor := Area3D.new()
	sensor.name = "Reach"
	sensor.collision_layer = 0
	sensor.collision_mask = 0xFFFFFFFF
	var room := BoxShape3D.new()
	room.size = Vector3(10.0, 3.4, 14.0)
	var area := CollisionShape3D.new()
	area.shape = room
	area.position = Vector3(0, 1.7, -1.5)
	sensor.add_child(area)
	ground.add_child(sensor)
	sensor.body_entered.connect(func(b: Node) -> void:
		if b is CharacterBody3D: _body = b)
	sensor.body_exited.connect(func(b: Node) -> void:
		if b == _body: _body = null)
	_board = _city.board(ground, Vector3(1.9, 0, _rim + 0.9), 3.3, 1.2)


## ---- for a test ----

func state() -> Dictionary:
	var sphere: Dictionary = _curved.measure()
	var plane: Dictionary = _flat.measure()
	return {"reading": reading, "on_dome": _on_dome, "pair": [snappedf(_pair.x, 0.001), snappedf(_pair.y, 0.001)], "sphere_sum": snappedf(float(sphere.get("sum", 0.0)), 0.01), "sphere_valid": bool(sphere.get("valid", false)),
		"plane_sum": snappedf(float(plane.get("sum", 0.0)), 0.01), "angles": sphere.get("angles", []), "most": snappedf(_most, 0.01), "rim": snappedf(_rim, 0.01), "top": snappedf(R * (1.0 - cos(CAP)), 0.01),
		"prefab_parts": int(_city.parts), "build_ms": _build_ms}


func dome_point(x: float, z: float) -> Vector3:
	return to_global(Vector3(x, 0, z))
