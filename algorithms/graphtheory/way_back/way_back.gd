extends Node3D
## A WAY BACK (floor GT_Connectivity; the pass, 2026-11-13)
##
## The hall shows two rings joined by one arrow and says: getting across is easy to imagine, now try to return. A
## strongly connected group is a set of places where every one can reach every other AND be reached back. This is
## that sentence for a body, with gravity as the arrow:
##   a WEDGE is walked both ways;  a DROP of a metre is walked one way - a body steps off and cannot climb back.
## Three places stand in a row, each a metre lower than the last: ONE (a platform 2 m up, reached from the hall floor
## by a ramp of wedges), TWO (1 m up), THREE (a court at floor level). All of it is built from the spatial lab's
## prefabs through the lab's own adapter (Palle, 2026-11-13: real prefabs, fun connections): one-metre building cubes
## for the platforms, walkable wedges for every way up, the blue DO NOT CROSS barrier for every edge that is not a
## connection, planks let into the cubes where a drop begins.
##
## `mutuality` is the axis, the lesson's own word (tarjan_algorithm on this floor stands at `split`):
##   none    ONE -> TWO -> THREE by drops only: no place has a way back, and THREE has no way out
##   split   a wedge joins THREE and TWO: two groups (FLOOR + ONE, TWO + THREE) and one arrow between them
##   total   a second wedge returns from TWO to ONE: one group, everything reaches everything
## The return is built from inside: standing still on the plate in THREE builds the way up, on the plate in TWO the
## return - a body that has dropped in has to make its own way back. Each place lies on a mat in the colour of its
## group, so adding one wedge is seen to change who belongs with whom. When nobody has stood in the work for twenty
## seconds it goes back to the value its row gave it.
##
## Bench first (tools/probes/way_back_bench.py): the groups at each value, and from every place where a body can go
## and come back, and where it can go with no way back. `connections()` below is that table; the test walks it.
const Prefab := preload("res://commons/modular/lab_input.gd")
const DWELL := 0.8                       # seconds a body stands still with its middle on a plate before the plate answers
const EMPTY_SECONDS := 20.0
const PLACES := ["FLOOR", "ONE", "TWO", "THREE"]
const TOP := {"ONE": 2.0, "TWO": 1.0, "THREE": 0.0}
const MIDDLE := {"ONE": Vector3(-3.0, 2.0, 0.0), "TWO": Vector3(0.0, 1.0, 0.0), "THREE": Vector3(3.0, 0.0, 0.0)}
const COLOURS := [Color("f5a9b8"), Color("5bcefa"), Color("f2d45c"), Color("b7e4c7")]

@export_enum("none", "split", "total") var mutuality := "split"

var _given := "split"
var _up: Node3D                         # the wedge between THREE and TWO: in the tree at split and total
var _return: Node3D                     # the wedge from TWO back to ONE: in the tree at total
var _mats := {}
var _signs := {}
var _board: Label3D
var _plates: Array = []
var _inside := {}                       # place -> how many bodies its sensor holds
var _place := "FLOOR"
var _trail: Array[String] = ["FLOOR"]
var _empty_for := 0.0
var _parts := 0
var _build_ms := 0


func _ready() -> void:
	if has_meta("config_mutuality"): _take({"mutuality": get_meta("config_mutuality")})
	_given = mutuality
	var began := Time.get_ticks_msec()
	_build_once()
	_build_ms = Time.get_ticks_msec() - began
	_set_ways()


func _take(config_data: Dictionary) -> void:
	if config_data.has("mutuality") and str(config_data["mutuality"]) in ["none", "split", "total"]: mutuality = str(config_data["mutuality"])


func apply_grid_config(config_data: Dictionary) -> void:
	var before := mutuality
	_take(config_data)
	_given = mutuality
	if is_inside_tree() and _up != null and mutuality != before: _set_ways()


func _process(delta: float) -> void:
	for plate in _plates:
		var area: Area3D = plate["area"]
		var someone := false
		var still := false
		for b in area.get_overlapping_bodies():
			if b is CharacterBody3D:
				var off: Vector3 = (b as CharacterBody3D).global_position - area.global_position
				if Vector2(off.x, off.z).length() > 0.3: continue      # its middle is not on the plate: a body stopped by a fence beside one is not standing on it
				someone = true
				var v: Vector3 = (b as CharacterBody3D).velocity
				if Vector2(v.x, v.z).length() < 0.3: still = true
		if not someone:
			plate["time"] = 0.0
			plate["off"] = float(plate["off"]) + delta
			if float(plate["off"]) > 0.3: plate["done"] = false
			continue
		plate["off"] = 0.0
		plate["time"] = float(plate["time"]) + delta if still else 0.0
		if float(plate["time"]) >= DWELL and not bool(plate["done"]):
			plate["done"] = true
			_pressed(str(plate["what"]))
	# nobody in the work: after a while it is again what its row says
	if _place == "FLOOR" and mutuality != _given:
		_empty_for += delta
		if _empty_for >= EMPTY_SECONDS:
			mutuality = _given
			_set_ways()
	else:
		_empty_for = 0.0


func _pressed(what: String) -> void:
	if what == "up": mutuality = "split" if mutuality == "none" else "none"
	else: mutuality = "total" if mutuality != "total" else "split"
	_set_ways()


## ---- what a body can do here ----

## The connections that stand, as [from, to]: a wedge gives both directions, a drop one.
func connections() -> Array:
	var out := [["FLOOR", "ONE"], ["ONE", "FLOOR"], ["ONE", "TWO"], ["TWO", "THREE"]]
	if mutuality != "none": out.append(["THREE", "TWO"])
	if mutuality == "total": out.append(["TWO", "ONE"])
	return out


func reach() -> Dictionary:
	var can := {}
	for p in PLACES: can[p] = [p]
	var grew := true
	while grew:
		grew = false
		for edge in connections():
			for p in PLACES:
				if (can[p] as Array).has(edge[0]) and not (can[p] as Array).has(edge[1]):
					(can[p] as Array).append(edge[1])
					grew = true
	return can


## The groups: places that reach each other both ways.
func groups() -> Array:
	var can := reach()
	var out := []
	for p in PLACES:
		var g := []
		for q in PLACES:
			if (can[p] as Array).has(q) and (can[q] as Array).has(p): g.append(q)
		if not out.has(g): out.append(g)
	return out


func _in_tree(node: Node3D, wanted: bool) -> void:
	if wanted and node.get_parent() == null: add_child(node)
	elif not wanted and node.get_parent() != null: remove_child(node)


func _set_ways() -> void:
	_in_tree(_up, mutuality != "none")
	_in_tree(_return, mutuality == "total")
	_empty_for = 0.0
	_show()


func _exit_tree() -> void:
	for node in [_up, _return]:
		if is_instance_valid(node) and node.get_parent() == null: node.free()


## ---- building, once ----

func _part(parent: Node3D, token: String, at: Vector3, yaw_degrees: float = 0.0, fit: Vector3 = Vector3.ZERO, solid: bool = true) -> Node3D:
	var part: Node3D = Prefab.new()
	part.set("token", token)
	if fit != Vector3.ZERO:
		part.set("fit_box", fit)
		at.y += fit.y * 0.5
	part.position = at
	part.rotation_degrees.y = yaw_degrees
	parent.add_child(part)
	if not solid:
		for body in part.find_children("*", "CollisionObject3D", true, false):
			(body as CollisionObject3D).collision_layer = 0
			(body as CollisionObject3D).collision_mask = 0
	_parts += 1
	return part


func _fence(parent: Node3D, a: Vector3, b: Vector3) -> void:
	var length: float = a.distance_to(b)
	var n: int = maxi(1, roundi(length / 2.2))
	var along: Vector3 = (b - a) / float(n)
	var yaw: float = 0.0 if absf(along.x) > absf(along.z) else 90.0
	for k in n:
		_part(parent, "do_not_cross_barrier", a + along * (float(k) + 0.5), yaw, Vector3(along.length() - 0.04, 1.1, 0.45))


func _flat(colour: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = colour
	m.roughness = rough
	return m


func _build_once() -> void:
	var ground := Node3D.new()
	ground.name = "Places"
	add_child(ground)
	# the platforms: one-metre building cubes, ONE two high, TWO one high
	for x in [-4.0, -3.0, -2.0]:
		for z in [-1.0, 0.0, 1.0]:
			for y in [0.0, 1.0]: _part(ground, "construction_cube", Vector3(x, y, z))
	for x in [-1.0, 0.0, 1.0]:
		for z in [-1.0, 0.0, 1.0]: _part(ground, "construction_cube", Vector3(x, 0.0, z))
	# the ramp from the hall floor to ONE: two lanes of wedges, the upper pair on cubes
	for x in [-3.5, -2.5]:
		_part(ground, "wp", Vector3(x, 0.0, 4.5), 180)
		_part(ground, "wp", Vector3(x, 1.0, 2.5), 180)
		for z in [2.0, 3.0]: _part(ground, "construction_cube", Vector3(x, 0.0, z))
	for x in [-4.3, -1.7]: _part(ground, "traffic_pyramid_5", Vector3(x, 0.0, 5.3), 0, Vector3.ZERO, false)
	# every edge that is not a connection: the blue barrier
	_fence(ground, Vector3(-4.5, 2.0, -1.5), Vector3(-1.5, 2.0, -1.5))
	_fence(ground, Vector3(-4.5, 2.0, -1.5), Vector3(-4.5, 2.0, 1.5))
	_fence(ground, Vector3(-1.5, 1.0, -1.5), Vector3(1.5, 1.0, -1.5))
	_fence(ground, Vector3(-1.5, 1.0, 1.5), Vector3(1.5, 1.0, 1.5))
	_fence(ground, Vector3(1.5, 0.0, -1.5), Vector3(4.5, 0.0, -1.5))
	_fence(ground, Vector3(1.5, 0.0, 1.5), Vector3(4.5, 0.0, 1.5))
	_fence(ground, Vector3(4.5, 0.0, -1.5), Vector3(4.5, 0.0, 1.5))
	# where a drop begins: three planks let into the cubes, reaching half a metre out over the place below
	for edge in [[-1.5, 2.0], [1.5, 1.0]]:
		for z in [-0.25, 0.0, 0.25]:
			_part(ground, "timber_plank_2m", Vector3(float(edge[0]) - 0.5, float(edge[1]) + 0.014 - 0.06, z), 0, Vector3.ZERO, false)
	# the two ways back, each in its own holder
	_up = Node3D.new()
	_up.name = "WayUp"
	add_child(_up)
	_part(_up, "wp", Vector3(2.5, 0.0, -1.0), -90)        # low in THREE at x 3.5, a metre up at TWO's edge
	_return = Node3D.new()
	_return.name = "Return"
	add_child(_return)
	_part(_return, "wp", Vector3(-0.5, 1.0, 1.0), -90)    # low on TWO at x 0.5, two metres up at ONE's edge
	# each place: a mat that takes its group's colour, a name over it, a sensor
	for name in ["ONE", "TWO", "THREE"]:
		var middle: Vector3 = MIDDLE[name]
		_mats[name] = _mat(ground, middle + Vector3(0, 0.006, 0), Vector2(2.6, 2.6))
		_signs[name] = _sign(ground, middle + Vector3(0, 2.3, 0))
		var sensor := Area3D.new()
		sensor.name = "Place_" + name
		sensor.collision_layer = 0
		sensor.collision_mask = 0xFFFFFFFF
		var room := BoxShape3D.new()
		room.size = Vector3(2.96, 2.2, 2.96)
		var shape := CollisionShape3D.new()
		shape.shape = room
		shape.position = Vector3(0, 1.1, 0)
		sensor.add_child(shape)
		sensor.position = middle
		ground.add_child(sensor)
		sensor.body_entered.connect(_on_place.bind(name, 1))
		sensor.body_exited.connect(_on_place.bind(name, -1))
	_mats["FLOOR"] = _mat(ground, Vector3(-3.0, 0.006, 6.1), Vector2(2.0, 0.9))
	_signs["FLOOR"] = _sign(ground, Vector3(-3.0, 1.9, 6.1))
	# the plates, inside: a body that has dropped in builds its own way back
	_plate(ground, "up", Vector3(3.5, 0.0, 0.6))
	_plate(ground, "return", Vector3(0.95, 1.0, 0.95))
	# the board: beside the foot of the ramp, turned to the arrival
	var stand := Node3D.new()
	stand.name = "Board"
	stand.position = Vector3(-0.2, 0, 5.2)
	ground.add_child(stand)
	var panel := MeshInstance3D.new()
	var face := BoxMesh.new()
	face.size = Vector3(3.2, 1.0, 0.05)
	panel.mesh = face
	panel.material_override = _flat(Color(0.11, 0.115, 0.13), 0.85)
	panel.position = Vector3(0, 0.66, 0)
	panel.rotation.x = -0.5
	stand.add_child(panel)
	_board = Label3D.new()
	_board.pixel_size = 0.0021
	_board.font_size = 30
	_board.line_spacing = 2.0
	_board.modulate = Color(0.88, 0.94, 1.0)
	_board.outline_size = 4
	_board.outline_modulate = Color(0, 0, 0, 1)
	_board.width = 1440
	_board.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_board.position = Vector3(0, 0.035, 0.03)
	panel.add_child(_board)


func _mat(parent: Node3D, at: Vector3, size: Vector2) -> MeshInstance3D:
	var mat := MeshInstance3D.new()
	var sheet := BoxMesh.new()
	sheet.size = Vector3(size.x, 0.012, size.y)
	mat.mesh = sheet
	mat.position = at
	mat.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mat)
	return mat


func _sign(parent: Node3D, at: Vector3) -> Label3D:
	var sign_post := Label3D.new()
	sign_post.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	sign_post.pixel_size = 0.0032
	sign_post.font_size = 40
	sign_post.outline_size = 8
	sign_post.outline_modulate = Color(0, 0, 0, 1)
	sign_post.position = at
	parent.add_child(sign_post)
	return sign_post


func _plate(parent: Node3D, what: String, at: Vector3) -> void:
	var area := Area3D.new()
	area.name = "Plate_" + what
	area.collision_layer = 0
	area.collision_mask = 0xFFFFFFFF
	area.position = at
	var reach_shape := CollisionShape3D.new()
	var room := BoxShape3D.new()
	room.size = Vector3(0.7, 1.2, 0.7)
	reach_shape.shape = room
	reach_shape.position = Vector3(0, 0.6, 0)
	area.add_child(reach_shape)
	var slab := MeshInstance3D.new()
	var tile := BoxMesh.new()
	tile.size = Vector3(0.8, 0.014, 0.8)
	slab.mesh = tile
	slab.material_override = _flat(Color(0.96, 0.96, 0.98), 0.6)
	slab.position = Vector3(0, 0.014, 0)
	slab.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	area.add_child(slab)
	var text := Label3D.new()
	text.pixel_size = 0.002
	text.font_size = 36
	text.modulate = Color(0.1, 0.1, 0.12)
	text.outline_size = 0
	text.rotation_degrees = Vector3(-90, 0, 0)
	text.position = Vector3(0, 0.026, 0)
	area.add_child(text)
	parent.add_child(area)
	_plates.append({"area": area, "what": what, "time": 0.0, "done": false, "off": 0.0, "words": text})


## ---- where the body is ----

func _on_place(body: Node, name: String, change: int) -> void:
	if not body is CharacterBody3D: return
	_inside[name] = maxi(0, int(_inside.get(name, 0)) + change)
	var now := "FLOOR"
	for p in ["ONE", "TWO", "THREE"]:
		if int(_inside.get(p, 0)) > 0:
			now = p
			break
	if now != _place:
		_place = now
		_trail.append(now)
		if _trail.size() > 40: _trail.pop_front()
		_show()


func _show() -> void:
	var found := groups()
	var can := reach()
	for g in found.size():
		for p in found[g]:
			if _mats.has(p): (_mats[p] as MeshInstance3D).material_override = _flat(COLOURS[g % COLOURS.size()], 0.6)
			if _signs.has(p):
				var others := (found[g] as Array).duplicate()
				others.erase(p)
				(_signs[p] as Label3D).text = "%s\n%s" % [p, "alone: no way back to it" if others.is_empty() else "one group with " + " + ".join(others)]
				(_signs[p] as Label3D).modulate = COLOURS[g % COLOURS.size()].lightened(0.25)
	for plate in _plates:
		var words: Label3D = plate["words"]
		if str(plate["what"]) == "up": words.text = "BUILD A\nWAY UP" if mutuality == "none" else "TAKE THE\nWAY UP AWAY"
		else: words.text = "BUILD THE\nRETURN" if mutuality != "total" else "TAKE THE\nRETURN AWAY"
	if _board == null: return
	var back := []
	var gone := []
	for q in PLACES:
		if q == _place or not (can[_place] as Array).has(q): continue
		if (can[q] as Array).has(_place): back.append(q)
		else: gone.append(q)
	var lines := PackedStringArray(["A WAY BACK"])
	lines.append("A wedge is walked both ways. A drop is walked one way. Places that reach each other both ways are one group, and lie on one colour.")
	lines.append("Now: %d groups.  You stand on %s." % [found.size(), _place])
	lines.append("From here, there and back: %s.   There, with no way back: %s." % [", ".join(back) if not back.is_empty() else "nowhere", ", ".join(gone) if not gone.is_empty() else "nowhere"])
	lines.append("Dropped in? Stand still on the white plate in THREE or in TWO: it builds a way back.")
	_board.text = "\n".join(lines)


## ---- for a test ----

func state() -> Dictionary:
	return {"mutuality": mutuality, "given": _given, "groups": groups(), "connections": connections(), "place": _place, "trail": _trail.duplicate(), "way_up_stands": _up.get_parent() != null,
		"return_stands": _return.get_parent() != null, "prefab_parts": _parts, "build_ms": _build_ms}


func middle_of(place: String) -> Vector3:
	return to_global(MIDDLE[place]) if MIDDLE.has(place) else to_global(Vector3(-3.0, 0.0, 6.4))


func plate_at(what: String) -> Vector3:
	return to_global(Vector3(3.5, 0.0, 0.6) if what == "up" else Vector3(0.95, 1.0, 0.95))
